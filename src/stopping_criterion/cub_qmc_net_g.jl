"""
    CubQMCNetG(integrand; abs_tol=0.01, rel_tol=0.0,
               n_init=2^10, n_max=2^30, n_reps=16, alpha=0.01,
               trace_iterations=false)

Guaranteed QMC cubature using replicated randomized digital nets.

Supports **resume** and optional **iteration logging** (`trace_iterations=true`).

# Example
```julia
dd = DigitalNetB2(3; randomize="LMS_DS")
tm = Uniform(dd)
f = Genz(tm; kind=:oscillatory)
sc = CubQMCNetG(f; abs_tol=1e-4)
result = integrate(sc)
```
"""
mutable struct CubQMCNetG{I <: AbstractIntegrand} <: AbstractStoppingCriterion
    integrand::I
    abs_tol::Float64
    rel_tol::Float64
    n_init::Int
    n_max::Int
    n_reps::Int
    alpha::Float64
    trace_iterations::Bool
end

function CubQMCNetG(
    integrand::AbstractIntegrand;
    abs_tol::Float64=0.01,
    rel_tol::Float64=0.0,
    n_init::Int=2^10,
    n_max::Int=2^30,
    n_reps::Int=16,
    alpha::Float64=0.01,
    trace_iterations::Bool=false,
)
    return CubQMCNetG(
        integrand,
        abs_tol,
        rel_tol,
        n_init,
        n_max,
        n_reps,
        alpha,
        trace_iterations,
    )
end

function integrate(sc::CubQMCNetG; resume::Union{Nothing, Dict{Symbol, Any}}=nothing)
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

    while n <= sc.n_max
        n_iter += 1
        estimates = Vector{Float64}(undef, R)

        dd = sc.integrand.true_measure.dd
        # Batch the R replicates' transform + evaluate in GROUPS of `group_size`
        # rather than all at once. Each group's points are still the same draws in
        # the same order (gen_samples advances the same RNG), so the per-replicate
        # means — and hence mu_hat and the error bound — are unchanged. Grouping
        # keeps one large BLAS GEMM per group (far better than R tiny ones) while
        # bounding the dense-transform temporaries (`z`, `y`) to group_size·n rows
        # instead of R·n: the full-stack version allocated R×-larger transform
        # buffers, which dominated memory for the GBM integrands.
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
            @inbounds for k in 1:g
                estimates[r0 + k - 1] = mean(@view y_group[((k - 1) * m + 1):(k * m)])
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
        @warn "CubQMCNetG: did not converge within n_max=$(sc.n_max)."
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
    if sc.trace_iterations
        data[:iteration_log] = log
    end
    return QMCResult(mu_hat, data)
end

function Base.show(io::IO, sc::CubQMCNetG)
    print(io, "CubQMCNetG(abs_tol=$(sc.abs_tol), n_reps=$(sc.n_reps))")
end
