"""
    CubQMCLatticeG(integrand; abs_tol=0.01, rel_tol=0.0,
                   n_init=2^10, n_max=2^30, n_reps=16, alpha=0.01,
                   trace_iterations=false)

Guaranteed QMC cubature using replicated randomized lattice rules.

Pass `control_variates` (an integrand or vector of integrands sharing the main
integrand's discrete distribution and dimension) with their known
`control_variate_means` to apply linear control variates. Because this criterion
is replication-based, the coefficients β are fit once on a dedicated pilot draw
and frozen, so the R per-replicate means stay i.i.d. and the t-confidence
interval remains valid; each replicate's estimate becomes
`mean(y_r) − Σ β·(mean(g on r) − μ)`. The fitted coefficients are returned in
`result.data[:control_variate_beta]`.

Supports **resume** and optional **iteration logging** (`trace_iterations=true`).

# Example
```julia
dd = Lattice(3; randomize=true)
tm = Uniform(dd)
f = Genz(tm; kind=:oscillatory)
sc = CubQMCLatticeG(f; abs_tol=1e-4)
result = integrate(sc)
```
"""
mutable struct CubQMCLatticeG{I <: AbstractIntegrand} <: AbstractStoppingCriterion
    integrand::I
    abs_tol::Float64
    rel_tol::Float64
    n_init::Int
    n_max::Int
    n_reps::Int
    alpha::Float64
    trace_iterations::Bool
    cv_spec::Union{Nothing, _ControlVariateSpec}
end

function CubQMCLatticeG(
    integrand::AbstractIntegrand;
    abs_tol::Float64=0.01,
    rel_tol::Float64=0.0,
    n_init::Int=2^10,
    n_max::Int=2^30,
    n_reps::Int=16,
    alpha::Float64=0.01,
    trace_iterations::Bool=false,
    control_variates=nothing,
    control_variate_means=nothing,
)
    cv_spec = _make_control_variate_spec(integrand, control_variates, control_variate_means)
    return CubQMCLatticeG(
        integrand,
        abs_tol,
        rel_tol,
        n_init,
        n_max,
        n_reps,
        alpha,
        trace_iterations,
        cv_spec,
    )
end

function integrate(sc::CubQMCLatticeG; resume::Union{Nothing, Dict{Symbol, Any}}=nothing)
    R = sc.n_reps
    t_crit = quantile(TDist(R - 1), 1.0 - sc.alpha / 2.0)

    if resume !== nothing
        n_prev = haskey(resume, :n_per_rep) ? Int(resume[:n_per_rep]) : Int(resume[:n])
        n = 2 * n_prev
        prev_time = Float64(get(resume, :time_integrate, 0.0))
    else
        n = sc.n_init
        prev_time = 0.0
    end

    t_start = time()
    mu_hat = 0.0
    err = Inf
    n_iter = 0
    log = IterationLog()

    # Control variates: fit β once on a dedicated pilot draw and freeze it. A
    # frozen β is a constant w.r.t. the R replicate draws, so the per-replicate
    # means stay i.i.d. and the t-CI remains valid (β fit on the same samples it
    # adjusts would correlate them and understate the spread).
    cv = sc.cv_spec
    cv_beta = nothing
    if cv !== nothing
        dd_pilot = sc.integrand.true_measure.dd
        xu_pilot = _sample_uniform_points(dd_pilot, sc.n_init)
        y_pilot = evaluate_on_uniform(sc.integrand, xu_pilot)
        ycv_pilot = _control_variate_values(cv, xu_pilot)
        cv_beta = _fit_control_variate_beta(y_pilot, ycv_pilot)
    end

    while n <= sc.n_max
        n_iter += 1
        estimates = Vector{Float64}(undef, R)

        dd = sc.integrand.true_measure.dd
        # Batch the R replicates' transform + evaluate in GROUPS of `group_size`
        # rather than one `sample_and_evaluate` call per replicate. The same R
        # randomizations are drawn in the same order (gen_samples advances the
        # same RNG), so per-replicate means, mu_hat, and the error bound are
        # unchanged. Grouping does one large BLAS GEMM per group instead of R
        # tiny ones while bounding the dense-transform temporaries to
        # group_size*n rows.
        group_size = 4
        r0 = 1
        while r0 <= R
            g = min(group_size, R - r0 + 1)
            first = gen_samples(dd, n)
            first =
                ndims(first) == 3 ?
                reshape(first, size(first, 1) * size(first, 2), size(first, 3)) : first
            m = size(first, 1)
            x_group = Matrix{Float64}(undef, g * m, size(first, 2))
            @inbounds x_group[1:m, :] .= first
            @inbounds for k in 2:g
                xu = gen_samples(dd, n)
                xu = ndims(xu) == 3 ? reshape(xu, size(xu, 1) * size(xu, 2), size(xu, 3)) : xu
                x_group[((k - 1) * m + 1):(k * m), :] .= xu
            end
            y_group = evaluate(sc.integrand, transform(sc.integrand.true_measure, x_group))
            if cv === nothing
                @inbounds for k in 1:g
                    estimates[r0 + k - 1] = mean(@view y_group[((k - 1) * m + 1):(k * m)])
                end
            else
                # Adjusted per-replicate mean:
                #   mean(y_r) − Σ_j β_j (mean(g_j on replicate r) − μ_j)
                ycv_group = _control_variate_values(cv, x_group)
                @inbounds for k in 1:g
                    rows = ((k - 1) * m + 1):(k * m)
                    est = mean(@view y_group[rows])
                    for j in eachindex(cv.means)
                        est -= cv_beta[j] * (mean(@view ycv_group[rows, j]) - cv.means[j])
                    end
                    estimates[r0 + k - 1] = est
                end
            end
            r0 += g
        end

        mu_hat = mean(estimates)
        sigma_reps = std(estimates; corrected=true)
        err = t_crit * sigma_reps / sqrt(R)
        tol = max(sc.abs_tol, sc.rel_tol * abs(mu_hat))

        if sc.trace_iterations
            push!(
                log;
                n=n*R,
                solution=mu_hat,
                error_bound=err,
                tol=tol,
                elapsed=time() - t_start,
            )
        end

        err <= tol && break
        n = min(2n, sc.n_max + 1)
    end

    converged = err <= max(sc.abs_tol, sc.rel_tol * abs(mu_hat))
    if !converged
        @warn "CubQMCLatticeG: did not converge within n_max=$(sc.n_max)."
    end

    t_elapsed = time() - t_start
    n_per_rep = n > sc.n_max ? sc.n_max : n
    data = Dict{Symbol, Any}(
        :n => n_per_rep,
        :n_per_rep => n_per_rep,
        :n_total => n_per_rep * R,
        :n_reps => R,
        :error_bound => err,
        :n_iterations => n_iter,
        :converged => converged,
        :time_integrate => prev_time + t_elapsed,
    )
    if cv_beta !== nothing
        data[:control_variate_beta] = cv_beta
    end
    if sc.trace_iterations
        data[:iteration_log] = log
    end
    return QMCResult(mu_hat, data)
end

function Base.show(io::IO, sc::CubQMCLatticeG)
    print(io, "CubQMCLatticeG(abs_tol=$(sc.abs_tol), n_reps=$(sc.n_reps))")
end
