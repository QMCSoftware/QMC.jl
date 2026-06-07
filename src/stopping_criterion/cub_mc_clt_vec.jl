"""
    CubMCCLTVec(integrand; abs_tol=0.01, rel_tol=0.0, n_init=256,
                n_max=2^30, alpha=0.01, trace_iterations=false)

Vectorized IID Monte Carlo stopping criterion based on the Central Limit
Theorem with doubling sample sizes.

Handles both **scalar** integrands (`d_indv == ()`, returning a `QMCResult`) and
**vector-valued / multi-output** integrands (`d_indv != ()`, returning a
[`QMCVecResult`](@ref)). For a multi-output integrand it tracks a per-output
running mean and CLT interval, combines them through the integrand's `bound_fun`
/ `combine_fun` (identity by default), and stops once **every** combined output's
half-width meets its tolerance — mirroring QMCPy's `CubMCCLTVec`.

Supports **resume**: pass the `data` dict from a previous `QMCResult` as
`resume` to continue integration from where it left off.

Set `trace_iterations=true` to record an `IterationLog` in `data[:iteration_log]`.

# Example
```julia
dd = IIDStdUniform(3)
tm = Gaussian(dd)
f = Keister(tm)
sc = CubMCCLTVec(f; abs_tol=0.01, trace_iterations=true)
result = integrate(sc)
show(result.data[:iteration_log])
```
"""
mutable struct CubMCCLTVec{I <: AbstractIntegrand} <: AbstractStoppingCriterion
    integrand::I
    abs_tol::Float64
    rel_tol::Float64
    n_init::Int
    n_max::Int
    alpha::Float64
    trace_iterations::Bool
end

function CubMCCLTVec(
    integrand::AbstractIntegrand;
    abs_tol::Float64=0.01,
    rel_tol::Float64=0.0,
    n_init::Int=256,
    n_max::Int=2^30,
    alpha::Float64=0.01,
    trace_iterations::Bool=false,
)
    abs_tol > 0 || throw(ArgumentError("abs_tol must be > 0"))
    rel_tol >= 0 || throw(ArgumentError("rel_tol must be ≥ 0"))
    n_init > 0 || throw(ArgumentError("n_init must be > 0"))
    0 < alpha < 1 || throw(ArgumentError("alpha must be in (0,1)"))

    return CubMCCLTVec(integrand, abs_tol, rel_tol, n_init, n_max, alpha, trace_iterations)
end

function integrate(sc::CubMCCLTVec; resume::Union{Nothing, Dict{Symbol, Any}}=nothing)
    # Vector-valued (multi-output) integrands take a dedicated per-output path.
    # Scalar integrands (d_indv == ()) fall through to the original code below,
    # which is left byte-for-byte unchanged.
    if d_indv(sc.integrand) != ()
        return _integrate_cubmccltvec_multi(sc, resume)
    end
    t_start = time()
    f = sc.integrand
    tm = f.true_measure
    dd = tm.dd

    z_alpha = quantile(Normal(), 1 - sc.alpha / 2)
    log = IterationLog()

    # Restore or initialise accumulation state
    if resume !== nothing
        running_sum = Float64(resume[:_running_sum])
        running_sum2 = Float64(resume[:_running_sum2])
        n_total = Int(resume[:n_total])
        n = 2 * n_total
        prev_time = Float64(get(resume, :time_integrate, 0.0))
    else
        running_sum = 0.0
        running_sum2 = 0.0
        n_total = 0
        n = sc.n_init
        prev_time = 0.0
    end

    solution = n_total > 0 ? running_sum / n_total : 0.0
    err = Inf

    while n_total < sc.n_max
        n_batch = min(n, sc.n_max - n_total)
        x = transform(tm, gen_samples(dd, n_batch))
        y = evaluate(f, x)

        running_sum += sum(y)
        running_sum2 += sum(y .^ 2)
        n_total += n_batch

        solution = running_sum / n_total
        var_est = max(running_sum2 / n_total - solution^2, 0.0)
        sigma_est = sqrt(var_est)
        err = z_alpha * sigma_est / sqrt(Float64(n_total))

        tol = max(sc.abs_tol, sc.rel_tol * abs(solution))

        if sc.trace_iterations
            push!(
                log;
                n=n_total,
                solution=solution,
                error_bound=err,
                tol=tol,
                elapsed=time() - t_start,
            )
        end

        err <= tol && break

        n = min(2 * n, sc.n_max - n_total)
        n <= 0 && break
    end

    t_elapsed = time() - t_start
    data = Dict{Symbol, Any}(
        :n_total => n_total,
        :error_bound => err,
        :time_integrate => prev_time + t_elapsed,
        :converged => err <= max(sc.abs_tol, sc.rel_tol * abs(solution)),
        :_running_sum => running_sum,
        :_running_sum2 => running_sum2,
    )
    if sc.trace_iterations
        data[:iteration_log] = log
    end

    return QMCResult(solution, data)
end

# Multi-output doubling path: per-individual-output running mean/variance and a
# CLT confidence interval, combined via the integrand's `bound_fun`/`combine_fun`
# (identity by default), stopping once every combined output's half-width meets
# its tolerance. Mirrors the doubling structure of QMCPy's `CubMCCLTVec`. The
# per-output variance uses the same uncorrected estimator as the scalar path
# above, for internal consistency. All outputs are recomputed each iteration:
# `compute_flags` short-circuiting (freezing converged outputs) would require
# `evaluate` to accept per-output flags, which the integrand interface does not
# yet expose; recomputing is correct (every output still meets tolerance), just
# not the work-saving optimization.
function _integrate_cubmccltvec_multi(
    sc::CubMCCLTVec,
    resume::Union{Nothing, Dict{Symbol, Any}},
)
    t_start = time()
    f = sc.integrand
    tm = f.true_measure
    dd = tm.dd
    z_alpha = quantile(Normal(), 1 - sc.alpha / 2)
    log = IterationLog()

    ishape = d_indv(f)
    cshape = d_comb(f)
    m = prod(ishape)

    if resume !== nothing
        running_sum = collect(Float64, resume[:_running_sum])
        running_sum2 = collect(Float64, resume[:_running_sum2])
        n_total = Int(resume[:n_total])
        n = 2 * n_total
        prev_time = Float64(get(resume, :time_integrate, 0.0))
    else
        running_sum = zeros(Float64, m)
        running_sum2 = zeros(Float64, m)
        n_total = 0
        n = sc.n_init
        prev_time = 0.0
    end

    solution_indv = zeros(Float64, m)
    indv_low = zeros(Float64, m)
    indv_high = zeros(Float64, m)
    comb_low = zeros(Float64, m)
    comb_high = zeros(Float64, m)
    sol_comb = zeros(Float64, m)
    err_comb = Inf
    converged = false

    while n_total < sc.n_max
        n_batch = min(n, sc.n_max - n_total)
        x = transform(tm, gen_samples(dd, n_batch))
        Y = reshape(evaluate(f, x), n_batch, m)
        @inbounds for k in 1:m
            sk = 0.0
            sk2 = 0.0
            for i in 1:n_batch
                v = Y[i, k]
                sk += v
                sk2 += v * v
            end
            running_sum[k] += sk
            running_sum2[k] += sk2
        end
        n_total += n_batch

        @inbounds for k in 1:m
            mu = running_sum[k] / n_total
            solution_indv[k] = mu
            var_k = max(running_sum2[k] / n_total - mu^2, 0.0)
            ci = z_alpha * sqrt(var_k) / sqrt(Float64(n_total))
            indv_low[k] = mu - ci
            indv_high[k] = mu + ci
        end

        cl, ch = bound_fun(f, indv_low, indv_high)
        comb_low = collect(Float64, cl)
        comb_high = collect(Float64, ch)
        sol_comb = collect(Float64, combine_fun(f, solution_indv))

        halfwidth = (comb_high .- comb_low) ./ 2
        tol_c = max.(sc.abs_tol, sc.rel_tol .* abs.(sol_comb))
        err_comb = maximum(halfwidth)
        converged = all(halfwidth .<= tol_c)

        if sc.trace_iterations
            push!(
                log;
                n=n_total,
                solution=sol_comb[1],
                error_bound=err_comb,
                tol=maximum(tol_c),
                elapsed=time() - t_start,
            )
        end

        converged && break
        n = min(2 * n, sc.n_max - n_total)
        n <= 0 && break
    end

    t_elapsed = time() - t_start
    data = Dict{Symbol, Any}(
        :n_total => n_total,
        :error_bound => err_comb,
        :time_integrate => prev_time + t_elapsed,
        :converged => converged,
        :solution_indv => Array{Float64}(reshape(copy(solution_indv), ishape)),
        :comb_bound_low => Array{Float64}(reshape(comb_low, cshape)),
        :comb_bound_high => Array{Float64}(reshape(comb_high, cshape)),
        :_running_sum => running_sum,
        :_running_sum2 => running_sum2,
    )
    if sc.trace_iterations
        data[:iteration_log] = log
    end
    return QMCVecResult(Array{Float64}(reshape(sol_comb, cshape)), data)
end

function Base.show(io::IO, sc::CubMCCLTVec)
    @printf(
        io,
        "CubMCCLTVec(abs_tol=%.2e, rel_tol=%.2e, n_init=%d)",
        sc.abs_tol,
        sc.rel_tol,
        sc.n_init
    )
end
