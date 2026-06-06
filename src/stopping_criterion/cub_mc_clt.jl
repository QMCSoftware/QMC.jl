"""
    CubMCCLT(integrand; abs_tol=0.01, rel_tol=0.0, n_init=1024,
             n_max=2^30, alpha=0.01, inflate=1.2, trace_iterations=false)

IID Monte Carlo cubature with CLT-based confidence interval (two-stage method).

Set `trace_iterations=true` to record an `IterationLog` in
`result.data[:iteration_log]`.

**Algorithm:**
1. **Pilot stage:** Draw `n_init` IID samples, compute variance estimate σ̂.
2. **Main stage:** Compute the number of *new* samples needed:
   ``n_\\mu = \\lceil (z_{1-α/2} \\cdot \\text{inflate} \\cdot \\hat{\\sigma} / \\text{tol})^2 \\rceil``
   Draw those samples and compute the final mean and confidence interval from the
   main-stage samples alone.

Matches QMC v2.3's `CubMCCLT` algorithm.

# Example
```julia
dd = IIDStdUniform(3)
tm = Uniform(dd)
f = CustomFun(tm, x -> sum(x, dims=2)[:])
sc = CubMCCLT(f; abs_tol=1e-3)
result = integrate(sc)
```
"""
mutable struct CubMCCLT{I <: AbstractIntegrand} <: AbstractStoppingCriterion
    integrand::I
    abs_tol::Float64
    rel_tol::Float64
    n_init::Int
    n_max::Int
    alpha::Float64
    inflate::Float64
    trace_iterations::Bool
end

function CubMCCLT(
    integrand::AbstractIntegrand;
    abs_tol::Float64=0.01,
    rel_tol::Float64=0.0,
    n_init::Int=1024,
    n_max::Int=2^30,
    alpha::Float64=0.01,
    inflate::Float64=1.2,
    trace_iterations::Bool=false,
)
    n_max > 2 * n_init || throw(ArgumentError("n_max must be > 2 * n_init"))
    inflate >= 1.0 || throw(ArgumentError("inflate must be ≥ 1.0"))
    0.0 < alpha < 1.0 || throw(ArgumentError("alpha must be in (0, 1)"))
    return CubMCCLT(
        integrand,
        abs_tol,
        rel_tol,
        n_init,
        n_max,
        alpha,
        inflate,
        trace_iterations,
    )
end

function integrate(sc::CubMCCLT; resume::Union{Nothing, Dict{Symbol, Any}}=nothing)
    t_start = time()
    z_star = quantile(Normal(), 1.0 - sc.alpha / 2.0)
    log = IterationLog()

    # ── Stage 1: Pilot sample to estimate variance ──
    y0 = sample_and_evaluate(sc.integrand, sc.n_init)
    sig_hat0 = std(y0; corrected=true)
    mu_hat0 = mean(y0)

    # Determine tolerance using pilot estimate
    tol = max(sc.abs_tol, sc.rel_tol * abs(mu_hat0))
    pilot_err = z_star * sc.inflate * sig_hat0 / sqrt(sc.n_init)
    if sc.trace_iterations
        push!(
            log;
            n=sc.n_init,
            solution=mu_hat0,
            error_bound=pilot_err,
            tol=tol,
            elapsed=time() - t_start,
        )
    end

    # Compute required main-stage sample size
    n_mu = ceil(Int, (z_star * sc.inflate * sig_hat0 / tol)^2)
    n_mu = max(n_mu, sc.n_init)  # at least n_init

    if (sc.n_init + n_mu) > sc.n_max
        @warn "CubMCCLT: requested n_mu=$n_mu new samples would exceed n_max=$(sc.n_max). " *
              "Generating $(sc.n_max - sc.n_init) instead."
        n_mu = sc.n_max - sc.n_init
    end

    # ── Stage 2: Main sample ──
    y = sample_and_evaluate(sc.integrand, n_mu)
    sig_hat = std(y; corrected=true)
    mu_hat = mean(y)

    # Final confidence interval from main-stage samples
    err = z_star * sc.inflate * sig_hat / sqrt(n_mu)
    n_total = sc.n_init + n_mu

    bound_low = mu_hat - err
    bound_high = mu_hat + err

    converged = err <= max(sc.abs_tol, sc.rel_tol * abs(mu_hat))
    if !converged
        @warn "CubMCCLT: did not converge within n_max=$(sc.n_max). " *
              "Error bound: $err, tolerance: $(max(sc.abs_tol, sc.rel_tol * abs(mu_hat)))"
    end
    if sc.trace_iterations
        push!(
            log;
            n=n_total,
            solution=mu_hat,
            error_bound=err,
            tol=max(sc.abs_tol, sc.rel_tol * abs(mu_hat)),
            elapsed=time() - t_start,
        )
    end

    data = Dict{Symbol, Any}(
        :n => n_total,
        :n_total => n_total,
        :n_mu => n_mu,
        :error_bound => err,
        :bound_low => bound_low,
        :bound_high => bound_high,
        :bound_diff => bound_high - bound_low,
        :sigma_pilot => sig_hat0,
        :sigma_main => sig_hat,
        :converged => converged,
        :confidence_level => 1.0 - sc.alpha,
    )
    if sc.trace_iterations
        data[:iteration_log] = log
    end
    return QMCResult(mu_hat, data)
end

function Base.show(io::IO, sc::CubMCCLT)
    print(io, "CubMCCLT(abs_tol=$(sc.abs_tol), rel_tol=$(sc.rel_tol), inflate=$(sc.inflate))")
end
