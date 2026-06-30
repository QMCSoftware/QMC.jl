"""
    CubMCG(integrand; abs_tol=0.01, rel_tol=0.0, n_init=1024,
           n_limit=2^30, alpha=0.01, inflate=1.2, trace_iterations=false)

Guaranteed IID Monte Carlo stopping criterion using Berry-Esseen inequalities.

This two-stage algorithm first estimates the variance with `n_init` samples,
then uses the Berry-Esseen inequality to compute the number of additional
samples needed to achieve the error tolerance with guaranteed coverage for
functions with bounded kurtosis.

# Arguments
- `integrand`: The integrand to integrate.
- `abs_tol`: Absolute error tolerance.
- `rel_tol`: Relative error tolerance. When > 0, effective tolerance is
  `max(abs_tol, rel_tol * |μ̂|)`.
- `n_init`: Number of initial samples for variance estimation.
- `n_limit`: Maximum total number of samples.
- `alpha`: Uncertainty level in (0, 1).
- `inflate`: Inflation factor ≥ 1 for conservative variance estimation.
- `trace_iterations`: record an `IterationLog` in `result.data[:iteration_log]`.

Pass `control_variates` (an integrand or vector of integrands sharing the main
integrand's discrete distribution and dimension) with their known
`control_variate_means` to apply linear control variates. The regression
coefficients are fit on the pilot sample, reused for every subsequent batch
(both the fixed-tolerance and the iterative relative-tolerance paths), and
returned in `result.data[:control_variate_beta]`.

# Examples
```jldoctest
julia> using QuasiMC

julia> f = Keister(Gaussian(IIDStdUniform(2; seed=7)));

julia> sc = CubMCG(f; abs_tol=0.05)
CubMCG(abs_tol=5.00e-02, rel_tol=0.00e+00, n_init=1024, inflate=1.20)

julia> result = integrate(sc);

julia> isapprox(result.solution, 0.8483; atol=0.05)
true

julia> result.data[:n_total] > 0
true
```

```jldoctest
julia> using QuasiMC

julia> f = Keister(Gaussian(IIDStdUniform(2; seed=7)));

julia> r = integrate(CubMCG(f; abs_tol=0.01, rel_tol=0.05, n_init=256, n_limit=2^18, trace_iterations=true));

julia> isfinite(r.solution)
true

julia> haskey(r.data, :iteration_log)
true
```

# References
1. Hickernell, Jiang, Liu, Owen. "Guaranteed conservative fixed width
   confidence intervals via Monte Carlo sampling." MCQMC 2012.
"""
mutable struct CubMCG{I <: AbstractIntegrand} <: AbstractStoppingCriterion
    integrand::I
    abs_tol::Float64
    rel_tol::Float64
    n_init::Int
    n_limit::Int
    alpha::Float64
    inflate::Float64
    alpha_sigma::Float64
    kurtmax::Float64
    trace_iterations::Bool
    cv_spec::Union{Nothing, _ControlVariateSpec}
end

function CubMCG(
    integrand::AbstractIntegrand;
    abs_tol::Float64=0.01,
    rel_tol::Float64=0.0,
    n_init::Int=1024,
    n_limit::Int=2^30,
    alpha::Float64=0.01,
    inflate::Float64=1.2,
    trace_iterations::Bool=false,
    control_variates=nothing,
    control_variate_means=nothing,
)
    abs_tol > 0 || throw(ArgumentError("abs_tol must be > 0"))
    rel_tol >= 0 || throw(ArgumentError("rel_tol must be ≥ 0"))
    n_init > 0 || throw(ArgumentError("n_init must be > 0"))
    0 < alpha < 1 || throw(ArgumentError("alpha must be in (0,1)"))
    inflate >= 1 || throw(ArgumentError("inflate must be ≥ 1"))

    alpha_sigma = alpha / 2.0
    kurtmax =
        (n_init - 3) / (n_init - 1) +
        (alpha_sigma * n_init) / (1 - alpha_sigma) * (1 - 1 / inflate^2)^2
    cv_spec = _make_control_variate_spec(integrand, control_variates, control_variate_means)

    return CubMCG(
        integrand,
        abs_tol,
        rel_tol,
        n_init,
        n_limit,
        alpha,
        inflate,
        alpha_sigma,
        kurtmax,
        trace_iterations,
        cv_spec,
    )
end

# Berry-Esseen constants
const _BE_A = 18.1139
const _BE_A1 = 0.3328
const _BE_A2 = 0.429

"""
    _nchebe(toloversig, alpha, kurtmax, n_budget, sigma_up) -> (n, err)

Compute sample size and error bound using Berry-Esseen + Chebyshev.
"""
function _nchebe(
    toloversig::Float64,
    alpha::Float64,
    kurtmax::Float64,
    n_budget::Int,
    sigma_up::Float64,
)
    d = Distributions.Normal()
    M3upper = kurtmax^0.75

    # Chebyshev sample size
    ncheb = ceil(Int, 1 / (alpha * toloversig^2))

    # Berry-Esseen sample size via bisection
    _b = -quantile(d, eps(Float64))

    function BEfun2(logsqrtn)
        sqrtn = exp(logsqrtn)
        Distributions.cdf(d, -sqrtn * toloversig) +
        exp(-logsqrtn) *
        min(_BE_A1 * (M3upper + _BE_A2), _BE_A * M3upper / (1 + (sqrtn * toloversig)^3)) -
        alpha / 2.0
    end

    # Find root via bisection
    lo, hi = -_b, _b
    for _ in 1:100
        mid = (lo + hi) / 2
        if BEfun2(mid) > 0
            lo = mid
        else
            hi = mid
        end
    end
    nbe = ceil(Int, exp(2 * (lo + hi) / 2))

    ncb = min(ncheb, nbe, n_budget)

    # Compute error bound at ncb
    logsqrtn = log(sqrt(Float64(ncb)))
    sqrtn = exp(logsqrtn)

    function BEfun3(t)
        Distributions.cdf(d, -sqrtn * t) +
        exp(-logsqrtn) *
        min(_BE_A1 * (M3upper + _BE_A2), _BE_A * M3upper / (1 + (sqrtn * t)^3)) - alpha / 2.0
    end

    # Find toloversig at which BEfun3 = 0
    lo2, hi2 = -_b, _b
    for _ in 1:100
        mid = (lo2 + hi2) / 2
        if BEfun3(mid) > 0
            lo2 = mid
        else
            hi2 = mid
        end
    end
    err = (lo2 + hi2) / 2 * sigma_up

    return ncb, err
end

"""
    _ncbinv(n1, alpha1, kurtmax) -> eps

Compute initial error bound for n1 samples using Berry-Esseen + Chebyshev.
"""
function _ncbinv(n1::Int, alpha1::Float64, kurtmax::Float64)
    d = Distributions.Normal()
    NCheb_inv = 1 / sqrt(n1 * alpha1)
    M3upper = kurtmax^0.75

    _b = -quantile(d, eps(Float64))

    function BEfun(logsqrtb)
        Distributions.cdf(d, n1 * logsqrtb) +
        min(
            _BE_A1 * (M3upper + _BE_A2),
            _BE_A * M3upper / (1 + (sqrt(Float64(n1)) * logsqrtb)^3),
        ) / sqrt(Float64(n1)) - alpha1 / 2
    end

    lo, hi = -_b, _b
    for _ in 1:100
        mid = (lo + hi) / 2
        if BEfun(mid) > 0
            lo = mid
        else
            hi = mid
        end
    end
    NBE_inv = exp(2 * (lo + hi) / 2)
    return min(NCheb_inv, NBE_inv)
end

function integrate(sc::CubMCG; resume::Union{Nothing, Dict{Symbol, Any}}=nothing)
    t_start = time()
    f = sc.integrand
    tm = true_measure(f)
    dd = discrete_distribution(tm)
    log = IterationLog()
    cv = sc.cv_spec
    cv_beta = nothing

    # Stage 1: pilot samples (fit control-variate coefficients here, reuse below)
    xu0 = _sample_uniform_points(dd, sc.n_init)
    y0 = evaluate_on_uniform(f, xu0)
    if cv !== nothing
        ycv0 = _control_variate_values(cv, xu0)
        cv_beta = _fit_control_variate_beta(y0, ycv0)
        y0 = _apply_control_variates(y0, ycv0, cv.means, cv_beta)
    end
    mu0 = mean(y0)
    sig0 = std(y0; corrected=true)
    sigma_up = sc.inflate * sig0
    tol0 = max(sc.abs_tol, sc.rel_tol * abs(mu0))

    if sc.rel_tol == 0.0
        # Fixed absolute tolerance
        alpha_mu = 1 - (1 - sc.alpha) / (1 - sc.alpha_sigma)
        pilot_bound = sigma_up * _ncbinv(sc.n_init, alpha_mu, sc.kurtmax)
        if sc.trace_iterations
            push!(
                log;
                n=sc.n_init,
                solution=mu0,
                error_bound=pilot_bound,
                tol=tol0,
                elapsed=time() - t_start,
            )
        end
        toloversig = sc.abs_tol / max(sigma_up, 1e-300)
        n_mu, bound_hw = _nchebe(toloversig, alpha_mu, sc.kurtmax, sc.n_limit, sigma_up)

        n_mu = min(n_mu, sc.n_limit - sc.n_init)
        if n_mu > 0
            y1 = _draw_adjusted(f, dd, n_mu, cv, cv_beta)
            solution = mean(y1)
        else
            solution = mu0
        end
        n_total = sc.n_init + max(n_mu, 0)
        if sc.trace_iterations
            push!(
                log;
                n=n_total,
                solution=solution,
                error_bound=bound_hw,
                tol=sc.abs_tol,
                elapsed=time() - t_start,
            )
        end
    else
        # Relative tolerance mode: iterative
        alphai = (sc.alpha - sc.alpha_sigma) / (2 * (1 - sc.alpha_sigma))
        eps1 = _ncbinv(sc.n_init, alphai, sc.kurtmax)
        bound_hw = sigma_up * eps1
        solution = mu0
        n_total = sc.n_init
        tau = 1.0
        if sc.trace_iterations
            push!(
                log;
                n=n_total,
                solution=solution,
                error_bound=bound_hw,
                tol=tol0,
                elapsed=time() - t_start,
            )
        end

        while true
            tol_eff = max(sc.abs_tol, sc.rel_tol * abs(solution))
            if bound_hw <= tol_eff || n_total >= sc.n_limit
                break
            end

            # Tighten the bound
            bound_hw = min(bound_hw / 2, max(sc.abs_tol, 0.95 * sc.rel_tol * abs(solution)))
            tau += 1

            toloversig = bound_hw / max(sigma_up, 1e-300)
            alphai = 2^tau * (sc.alpha - sc.alpha_sigma) / (1 - sc.alpha_sigma)
            n_new, _ = _nchebe(toloversig, min(alphai, 0.99), sc.kurtmax, sc.n_limit, sigma_up)
            n_new = min(n_new, sc.n_limit - n_total)
            if n_new <= 0
                break
            end

            y1 = _draw_adjusted(f, dd, n_new, cv, cv_beta)
            solution = mean(y1)
            n_total += n_new
            if sc.trace_iterations
                push!(
                    log;
                    n=n_total,
                    solution=solution,
                    error_bound=bound_hw,
                    tol=max(sc.abs_tol, sc.rel_tol * abs(solution)),
                    elapsed=time() - t_start,
                )
            end
        end
    end

    t_elapsed = time() - t_start
    data = Dict{Symbol, Any}(
        :n_total => n_total,
        :bound_low => solution - bound_hw,
        :bound_high => solution + bound_hw,
        :bound_diff => 2 * bound_hw,
        :time_integrate => t_elapsed,
    )
    if cv_beta !== nothing
        data[:control_variate_beta] = cv_beta
    end
    if sc.trace_iterations
        data[:iteration_log] = log
    end

    return QMCResult(solution, data)
end

function Base.show(io::IO, sc::CubMCG)
    @printf(
        io,
        "CubMCG(abs_tol=%.2e, rel_tol=%.2e, n_init=%d, inflate=%.2f)",
        sc.abs_tol,
        sc.rel_tol,
        sc.n_init,
        sc.inflate
    )
end
