"""
    CubQMCLatticeG(integrand; abs_tol=0.01, rel_tol=0.0,
                   n_init=2^10, n_max=2^30, n_reps=16, alpha=0.01,
                   trace_iterations=false)

Guaranteed QMC cubature using replicated randomized lattice rules.

For vector-valued integrands (`QMC.d_indv(f) != ()`), returns a
[`QMCVecResult`](@ref) whose combined bounds are built through
`QMC.bound_fun(f, low, high)`.

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
```jldoctest
julia> using QMC

julia> k = Keister(Gaussian(Lattice(1; seed=7); covariance=0.5));

julia> sc = CubQMCLatticeG(k; abs_tol=1e-3, rel_tol=0.0);

julia> result = integrate(sc);

julia> round(result.solution; digits=8)
1.38035581

julia> isapprox(result.solution, 1.38037385; atol=5e-5) # QMCPy doctest reference
true
```

```jldoctest
julia> using QMC

julia> f = BoxIntegral(QMC.Uniform(Lattice(3; seed=11)); s=-1.0);

julia> abs_tol = 1e-3;

julia> sc = QMC.CubQMCLatticeG(f; abs_tol=abs_tol, rel_tol=0.0);

julia> solution = QMC.integrate(sc).solution;

julia> isapprox(solution, 1.18947477; atol=2e-4) # QMCPy doctest reference
true
```

```jldoctest
julia> using QMC

julia> dd = Lattice(2; randomize=true, seed=77);

julia> g = CustomFun(Uniform(dd), x -> x[:, 1].^2 .+ x[:, 2])
CustomFun(d=2)

julia> result = integrate(CubQMCLatticeG(g; abs_tol=1e-3, control_variates=g, control_variate_means=5 / 6));

julia> isapprox(result.solution, 5 / 6; atol=1e-10)
true

julia> result.data[:error_bound] < 1e-10
true
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

function _integrate_cubqmclatticeg_multi(
    sc::CubQMCLatticeG,
    resume::Union{Nothing, Dict{Symbol, Any}},
)
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
    f = sc.integrand
    ishape = d_indv(f)
    cshape = d_comb(f)
    m_indv = prod(ishape)
    dd = discrete_distribution(f)
    tm = true_measure(f)
    log = IterationLog()
    cv = sc.cv_spec
    cv_beta = nothing

    if cv !== nothing
        xu_pilot = _sample_uniform_points(dd, sc.n_init)
        y_pilot = reshape(evaluate_on_uniform(f, xu_pilot), size(xu_pilot, 1), m_indv)
        ycv_pilot = _control_variate_values(cv, xu_pilot)
        cv_beta = _fit_control_variate_beta(y_pilot, ycv_pilot)
    end

    solution_indv = zeros(Float64, m_indv)
    indv_low = zeros(Float64, m_indv)
    indv_high = zeros(Float64, m_indv)
    comb_low = zeros(Float64, prod(cshape))
    comb_high = zeros(Float64, prod(cshape))
    sol_comb = zeros(Float64, prod(cshape))
    comb_flags = falses(prod(cshape))
    err_comb = Inf
    converged = false
    n_iter = 0
    n_final = n

    while n <= sc.n_max
        n_iter += 1
        estimates = Matrix{Float64}(undef, R, m_indv)

        group_size = 4
        r0 = 1
        while r0 <= R
            g = min(group_size, R - r0 + 1)
            first = gen_samples(dd, n)
            first =
                ndims(first) == 3 ?
                reshape(first, size(first, 1) * size(first, 2), size(first, 3)) : first
            m_rows = size(first, 1)
            x_group = Matrix{Float64}(undef, g * m_rows, size(first, 2))
            @inbounds x_group[1:m_rows, :] .= first
            @inbounds for k in 2:g
                xu = gen_samples(dd, n)
                xu = ndims(xu) == 3 ? reshape(xu, size(xu, 1) * size(xu, 2), size(xu, 3)) : xu
                x_group[((k - 1) * m_rows + 1):(k * m_rows), :] .= xu
            end
            y_group = reshape(evaluate(f, transform(tm, x_group)), g * m_rows, m_indv)
            ycv_group = cv === nothing ? nothing : _control_variate_values(cv, x_group)
            @inbounds for k in 1:g
                rows = ((k - 1) * m_rows + 1):(k * m_rows)
                if cv === nothing
                    for j in 1:m_indv
                        estimates[r0 + k - 1, j] = mean(@view y_group[rows, j])
                    end
                else
                    cv_shift = vec(mean(@view ycv_group[rows, :]; dims=1)) .- cv.means
                    for j in 1:m_indv
                        est = mean(@view y_group[rows, j])
                        for ell in eachindex(cv.means)
                            est -= cv_beta[ell, j] * cv_shift[ell]
                        end
                        estimates[r0 + k - 1, j] = est
                    end
                end
            end
            r0 += g
        end

        @inbounds for j in 1:m_indv
            mu = mean(@view estimates[:, j])
            sigma_reps = std(@view estimates[:, j]; corrected=true)
            ci = t_crit * sigma_reps / sqrt(R)
            solution_indv[j] = mu
            indv_low[j] = mu - ci
            indv_high[j] = mu + ci
        end

        cl, ch = bound_fun(f, indv_low, indv_high)
        comb_low, comb_high, sol_comb, comb_flags, err_comb, tol_max =
            _combined_bounds_stats(sc.abs_tol, sc.rel_tol, cl, ch)
        converged = all(comb_flags)
        n_final = n

        if sc.trace_iterations
            push!(
                log;
                n=n * R,
                solution=sol_comb[1],
                error_bound=err_comb,
                tol=tol_max,
                elapsed=time() - t_start,
            )
        end

        converged && break
        n = min(2n, sc.n_max + 1)
    end

    if !converged
        @warn "CubQMCLatticeG: did not converge within n_max=$(sc.n_max)."
    end

    t_elapsed = time() - t_start
    n_total = n_final * R
    data = Dict{Symbol, Any}(
        :n => n_final,
        :n_per_rep => n_final,
        :n_total => n_total,
        :n_reps => R,
        :n_indv => Array{Int}(reshape(fill(n_total, m_indv), ishape)),
        :error_bound => err_comb,
        :n_iterations => n_iter,
        :converged => converged,
        :time_integrate => prev_time + t_elapsed,
        :solution_indv => Array{Float64}(reshape(copy(solution_indv), ishape)),
        :comb_bound_low => Array{Float64}(reshape(comb_low, cshape)),
        :comb_bound_high => Array{Float64}(reshape(comb_high, cshape)),
    )
    if sc.trace_iterations
        data[:iteration_log] = log
    end
    if cv_beta !== nothing
        data[:control_variate_beta] =
            Array{Float64}(reshape(vec(permutedims(cv_beta)), ishape..., length(cv.means)))
    end
    return QMCVecResult(Array{Float64}(reshape(sol_comb, cshape)), data)
end

function integrate(sc::CubQMCLatticeG; resume::Union{Nothing, Dict{Symbol, Any}}=nothing)
    if d_indv(sc.integrand) != ()
        return _integrate_cubqmclatticeg_multi(sc, resume)
    end
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
    f = sc.integrand
    tm = true_measure(f)
    dd = discrete_distribution(f)

    # Control variates: fit β once on a dedicated pilot draw and freeze it. A
    # frozen β is a constant w.r.t. the R replicate draws, so the per-replicate
    # means stay i.i.d. and the t-CI remains valid (β fit on the same samples it
    # adjusts would correlate them and understate the spread).
    cv = sc.cv_spec
    cv_beta = nothing
    if cv !== nothing
        xu_pilot = _sample_uniform_points(dd, sc.n_init)
        y_pilot = evaluate_on_uniform(f, xu_pilot)
        ycv_pilot = _control_variate_values(cv, xu_pilot)
        cv_beta = _fit_control_variate_beta(y_pilot, ycv_pilot)
    end

    while n <= sc.n_max
        n_iter += 1
        estimates = Vector{Float64}(undef, R)

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
            y_group = evaluate(f, transform(tm, x_group))
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
