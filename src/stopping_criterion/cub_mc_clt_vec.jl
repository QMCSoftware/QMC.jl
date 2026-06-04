"""
    CubMCCLTVec(integrand; abs_tol=0.01, rel_tol=0.0, n_init=256,
                n_max=2^30, alpha=0.01, trace_iterations=false)

Vectorized IID Monte Carlo stopping criterion based on the Central Limit
Theorem with doubling sample sizes.

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

function Base.show(io::IO, sc::CubMCCLTVec)
    @printf(
        io,
        "CubMCCLTVec(abs_tol=%.2e, rel_tol=%.2e, n_init=%d)",
        sc.abs_tol,
        sc.rel_tol,
        sc.n_init
    )
end
