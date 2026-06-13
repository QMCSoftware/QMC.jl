"""
    CubMCCLTVec(integrand; abs_tol=0.01, rel_tol=0.0, n_init=256,
                n_max=2^30, alpha=0.01, trace_iterations=false)

Vectorized IID Monte Carlo stopping criterion based on the Central Limit
Theorem with doubling sample sizes.

Handles both **scalar** integrands (`d_indv == ()`, returning a `QMCResult`) and
**vector-valued / multi-output** integrands (`d_indv != ()`, returning a
[`QMCVecResult`](@ref)). For a multi-output integrand it tracks a per-output
running mean and CLT interval (with `ddof=1` sample variance), maps them to
combined outputs through the integrand's `bound_fun`, and stops once **every**
combined output's bound width meets its tolerance — mirroring QMCPy's
`CubMCCLTVec`, which derives the solution and convergence from the combined
bounds via `error_fun` and does not use `combine_fun`.

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

# Distribute the combined confidence level `alpha` down to the individual outputs
# using the integrand's `dependency` map (mirrors QMCPy's `_compute_indv_alphas`).
# For each combined output, the individuals it depends on share its alpha budget
# (`alpha / n_dep`), and each individual takes the smallest alpha assigned to it.
# Identity dependency leaves every individual at `alpha` (uniform `z`); a ratio's
# single combined output depends on two individuals, so each receives `alpha/2`,
# keeping the combined output's simultaneous coverage at `1 - alpha`.
function _cubmccltvec_indv_alphas(f, alpha::Float64)
    ishape = d_indv(f)
    cshape = d_comb(f)
    m = prod(ishape)
    alphas_indv = fill(1.0, m)
    for kc in 1:prod(cshape)
        cflags = trues(cshape)
        cflags[kc] = false
        flags_indv = collect(Bool, dependency(f, cflags))
        deps = .!vec(flags_indv)
        n_dep = count(deps)
        n_dep == 0 && continue
        alpha_k = alpha / n_dep
        @inbounds for j in 1:m
            if deps[j]
                alphas_indv[j] = min(alphas_indv[j], alpha_k)
            end
        end
    end
    return alphas_indv
end

function _integrate_cubmccltvec_multi(
    sc::CubMCCLTVec,
    resume::Union{Nothing, Dict{Symbol, Any}},
)
    t_start = time()
    f = sc.integrand
    tm = f.true_measure
    dd = tm.dd
    # Per-individual confidence levels via the integrand's dependency map: the
    # combined alpha is split among the individual outputs each combined output
    # depends on (identity dependency ⇒ every individual gets alpha ⇒ uniform z,
    # matching the previous behavior; a ratio's combined output depends on two
    # individuals ⇒ each gets alpha/2). Mirrors QMCPy's _compute_indv_alphas.
    alphas_indv = _cubmccltvec_indv_alphas(f, sc.alpha)
    z_indv = [quantile(Normal(), 1 - a / 2) for a in alphas_indv]
    log = IterationLog()

    ishape = d_indv(f)
    cshape = d_comb(f)
    m = prod(ishape)
    mc = prod(cshape)

    # Per-output accumulators and sample counts so converged outputs can freeze
    # (stop drawing new samples) while the rest keep doubling. `n_max` doubles
    # each iteration; an active output's count grows toward it, a frozen one keeps
    # the count it had when it converged — mirroring QMCPy's per-output `n`.
    n_min = 0
    n_max = sc.n_init
    recheck_only = false
    if resume !== nothing
        running_sum = collect(Float64, resume[:_running_sum])
        running_sum2 = collect(Float64, resume[:_running_sum2])
        n_indv = collect(Int, resume[:_n_indv])
        prev_time = Float64(get(resume, :time_integrate, 0.0))
        # Re-evaluate the (possibly tighter) tolerance from existing samples before
        # drawing more: unfreeze everything and skip generation on the first pass.
        n_min = maximum(n_indv)
        n_max = n_min
        recheck_only = true
    else
        running_sum = zeros(Float64, m)
        running_sum2 = zeros(Float64, m)
        n_indv = zeros(Int, m)
        prev_time = 0.0
    end
    compute_flags = trues(m)

    solution_indv = zeros(Float64, m)
    indv_low = zeros(Float64, m)
    indv_high = zeros(Float64, m)
    comb_low = zeros(Float64, mc)
    comb_high = zeros(Float64, mc)
    sol_comb = zeros(Float64, mc)
    comb_flags = falses(mc)
    err_comb = Inf
    converged = false

    while true
        if !recheck_only
            n_new = n_max - n_min
            if n_new > 0
                x = transform(tm, gen_samples(dd, n_new))
                Y = reshape(evaluate(f, x, compute_flags), n_new, m)
                @inbounds for k in 1:m
                    compute_flags[k] || continue
                    sk = 0.0
                    sk2 = 0.0
                    for i in 1:n_new
                        v = Y[i, k]
                        sk += v
                        sk2 += v * v
                    end
                    running_sum[k] += sk
                    running_sum2[k] += sk2
                    n_indv[k] += n_new
                end
            end
        end
        recheck_only = false

        @inbounds for k in 1:m
            nk = n_indv[k]
            if nk > 1
                mu = running_sum[k] / nk
                solution_indv[k] = mu
                # corrected (ddof=1) sample variance, matching QMCPy's std(ddof=1)
                var_k = max((running_sum2[k] - nk * mu^2) / (nk - 1), 0.0)
                ci = z_indv[k] * sqrt(var_k) / sqrt(Float64(nk))
                indv_low[k] = mu - ci
                indv_high[k] = mu + ci
            else
                solution_indv[k] = NaN
                indv_low[k] = -Inf
                indv_high[k] = Inf
            end
        end

        cl, ch = bound_fun(f, indv_low, indv_high)
        comb_low = collect(Float64, cl)
        comb_high = collect(Float64, ch)

        # Solution, convergence, and tolerance are derived from the combined
        # bounds via error_fun (QMCPy's "EITHER" rule: max(abs_tol, |s|*rel_tol)),
        # matching CubMCCLTVec exactly — it does not use combine_fun. A combined
        # output converges when its bound width is within error_fun(low) +
        # error_fun(high), and the reported solution is the tolerance-adjusted
        # bound midpoint.
        err_comb = 0.0
        tol_max = 0.0
        @inbounds for kc in 1:mc
            lo = comb_low[kc]
            hi = comb_high[kc]
            if isfinite(lo) && isfinite(hi)
                el = max(sc.abs_tol, abs(lo) * sc.rel_tol)
                eh = max(sc.abs_tol, abs(hi) * sc.rel_tol)
                sol_comb[kc] = 0.5 * (lo + hi + el - eh)
                hw = (hi - lo) / 2
                tol_kc = (el + eh) / 2
                comb_flags[kc] = hw <= tol_kc
                hw > err_comb && (err_comb = hw)
                tol_kc > tol_max && (tol_max = tol_kc)
            else
                sol_comb[kc] = NaN
                comb_flags[kc] = false
            end
        end

        # Freeze the individuals that feed only converged combined outputs.
        flags_indv = vec(collect(Bool, dependency(f, reshape(comb_flags, cshape))))
        @inbounds for k in 1:m
            compute_flags[k] = !flags_indv[k]
        end
        converged = all(comb_flags)

        if sc.trace_iterations
            push!(
                log;
                n=maximum(n_indv),
                solution=sol_comb[1],
                error_bound=err_comb,
                tol=tol_max,
                elapsed=time() - t_start,
            )
        end

        count(compute_flags) == 0 && break        # all outputs sufficiently estimated
        2 * maximum(n_indv) > sc.n_max && break    # next doubling would exceed n_max
        n_min = n_max
        n_max = 2 * n_max
    end

    t_elapsed = time() - t_start
    data = Dict{Symbol, Any}(
        :n_total => maximum(n_indv),
        :n_indv => Array{Int}(reshape(copy(n_indv), ishape)),
        :error_bound => err_comb,
        :time_integrate => prev_time + t_elapsed,
        :converged => converged,
        :solution_indv => Array{Float64}(reshape(copy(solution_indv), ishape)),
        :comb_bound_low => Array{Float64}(reshape(comb_low, cshape)),
        :comb_bound_high => Array{Float64}(reshape(comb_high, cshape)),
        :_running_sum => running_sum,
        :_running_sum2 => running_sum2,
        :_n_indv => copy(n_indv),
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
