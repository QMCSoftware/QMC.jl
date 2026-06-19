"""
    PFGPCI(integrand; failure_threshold=0.0, failure_above_threshold=true,
           abs_tol=5e-3, alpha=0.01, n_init=64, n_limit=1000, n_batch=4,
           n_approx=2^20)

Probability-of-failure estimation with adaptive Gaussian-process construction
and credible intervals (Sorokin & Rao, arXiv:2311.07733), mirroring QMCPy's
`PFGPCI`.

# API status
**Experimental.** `PFGPCI` is exported for early adopters and QMCPy parity, but
it is not yet part of QMC.jl's stable API contract. The constructor and
deterministic credible-interval helpers are supported, and end-to-end
`integrate` works once the optional Gaussian-process backend extension is
loaded. Expect interface and backend details to evolve until the Julia GP
story stabilizes.

The criterion repeatedly fits a GP surrogate to the affine-shifted simulation
output `g(x) = y - failure_threshold` (or `failure_threshold - y` when
`failure_above_threshold == false`), so that the *failure region* is `g ≥ 0`.
At a fixed bank of `n_approx` low-discrepancy points it forms, per point, the
posterior failure probability `φ(x) = Φ(μ(x) / σ(x))`; the probability-of-failure
estimate is the fraction `mean(φ ≥ 0.5)`. A credible interval of half-width
`γ = emr / alpha` (with `emr = mean(min(φ, 1-φ))`, the expected misclassification
rate) is clamped to `[0, 1]`, and the criterion stops once that half-width drops
to `abs_tol` (or the simulation budget `n_limit` is exhausted). New batches of
`n_batch` points are proposed by acceptance–rejection sampling from the error
density `2 min(φ, 1-φ)`, concentrating effort near the learned failure boundary.

# Gaussian-process backend
The GP fit/predict step is supplied by the **`QMCAbstractGPsExt` package
extension**, which loads automatically once `AbstractGPs` and `Optim` are
present. Without them, `integrate` raises an actionable error. Unlike QMCPy's
deterministic stopping criteria, cross-implementation *bit*-parity is not
attainable here — the GP hyperparameters are fit by numerical optimization, so
QMCPy (gpytorch + Adam) and QMC.jl (AbstractGPs + Optim) agree only
*statistically* (same algorithm, same credible-interval math, convergence to
the same probability of failure). The deterministic pieces — `φ`, the estimate,
`emr`, the credible interval, the acceptance–rejection proposal — match QMCPy
exactly.

# Examples
```jldoctest
julia> using QMC

julia> dd = DigitalNetB2(2; seed=7);

julia> f = FourBranch2D(Gaussian(dd));

julia> sc = PFGPCI(f; abs_tol=0.05, n_init=32, n_limit=200)
PFGPCI(failure_threshold=0.0, abs_tol=0.05, alpha=0.01, n_limit=200)
```

# References
1. Sorokin, Aleksei G., and Vishwas Rao. "Credible Intervals for Probability of
   Failure with Gaussian Processes." arXiv:2311.07733 (2023).
"""
struct PFGPCI{I <: AbstractIntegrand} <: AbstractStoppingCriterion
    integrand::I
    failure_threshold::Float64
    failure_above_threshold::Bool
    abs_tol::Float64
    alpha::Float64
    n_init::Int
    n_limit::Int
    n_batch::Int
    n_approx::Int
end

function PFGPCI(
    integrand::AbstractIntegrand;
    failure_threshold::Float64=0.0,
    failure_above_threshold::Bool=true,
    abs_tol::Float64=5e-3,
    alpha::Float64=0.01,
    n_init::Int=64,
    n_limit::Int=1000,
    n_batch::Int=4,
    n_approx::Int=2^20,
)
    0 < alpha < 1 || throw(ArgumentError("alpha must be in (0, 1), got $alpha"))
    n_limit >= n_init || throw(ArgumentError("n_limit ($n_limit) must be ≥ n_init ($n_init)"))
    n_batch >= 1 || throw(ArgumentError("n_batch must be ≥ 1, got $n_batch"))
    return PFGPCI(
        integrand,
        failure_threshold,
        failure_above_threshold,
        abs_tol,
        alpha,
        n_init,
        n_limit,
        n_batch,
        n_approx,
    )
end

# ---------------------------------------------------------------------------
# Gaussian-process backend contract.
#
# Implemented by the `QMCAbstractGPsExt` extension (loaded when AbstractGPs and
# Optim are available). `_pfgpci_fit(x, y)` returns an opaque fitted-GP object
# for training inputs `x` (an `n × d` matrix, one point per row) and targets
# `y`; `_pfgpci_predict(model, xq)` returns `(mean, std)` posterior vectors at
# the query rows of `xq`. With no backend loaded these generic functions have no
# methods, and `integrate` reports a clear, actionable error instead of a raw
# `MethodError`.
# ---------------------------------------------------------------------------
function _pfgpci_fit end
function _pfgpci_predict end

_pfgpci_backend_loaded() = !isempty(methods(_pfgpci_fit))

# Affine shift placing the failure region at `g ≥ 0`.
function _pfgpci_affine_tf(sc::PFGPCI, y::AbstractVector)
    return sc.failure_above_threshold ? (y .- sc.failure_threshold) :
           (sc.failure_threshold .- y)
end

# Posterior failure probability φ(x) = Φ(μ/σ) at each point, with a guard for the
# degenerate σ = 0 case (a point pinned to the failure side or the safe side).
function _pfgpci_phi(mean::AbstractVector, std::AbstractVector)
    nrm = Distributions.Normal()
    phi = Vector{Float64}(undef, length(mean))
    @inbounds for i in eachindex(mean)
        s = std[i]
        if s > 0
            phi[i] = Distributions.cdf(nrm, mean[i] / s)
        else
            phi[i] = mean[i] >= 0 ? 1.0 : 0.0
        end
    end
    return phi
end

# Error / acquisition density 2·min(φ, 1-φ): peaks (= 1) where the surrogate is
# maximally undecided (φ = 1/2) and vanishes where it is confident.
_pfgpci_error_udens(phi::AbstractVector) = 2 .* min.(phi, 1 .- phi)

# Acceptance–rejection draw of `n` proposal points in [0,1]^d from the error
# density, evaluating the GP on each trial block. `efficiency ≈ 2·emr` is the
# mean acceptance probability; it sizes each trial block so that, in expectation,
# a fraction `pct` of the remaining points is filled per round. Mirrors QMCPy's
# `PFSampleErrorDensityAR.suggest`.
function _pfgpci_ar_suggest(
    n::Int,
    d::Int,
    model,
    rng::Random.AbstractRNG,
    efficiency::Float64;
    pct::Float64=0.5,
)
    eff = clamp(efficiency, 1e-6, 1 - 1e-6)
    draws_per_rem = max(1, ceil(Int, log(pct) / log(1 - eff)))
    accepted = Matrix{Float64}(undef, 0, d)
    while size(accepted, 1) < n
        remaining = n - size(accepted, 1)
        ntries = remaining * draws_per_rem
        z = rand(rng, ntries, d)
        u = rand(rng, ntries)
        mean_z, std_z = _pfgpci_predict(model, z)
        udens = _pfgpci_error_udens(_pfgpci_phi(mean_z, std_z))
        keep = findall(u .<= udens)
        if !isempty(keep)
            accepted = vcat(accepted, z[keep, :])
        end
    end
    return accepted[1:n, :]
end

# One credible-interval update from the GP posterior at the approximation bank.
# Returns (solution, emr, ci_low, ci_high, error_bound). Identical arithmetic to
# QMCPy's `PFGPCIData.update_data`.
function _pfgpci_credible_interval(phi::AbstractVector, alpha::Float64)
    solution = count(>=(0.5), phi) / length(phi)
    emr = sum(min.(phi, 1 .- phi)) / length(phi)
    gamma = emr / alpha
    ci_low = max(solution - gamma, 0.0)
    ci_high = min(solution + gamma, 1.0)
    error_bound = max(solution - ci_low, ci_high - solution)
    return solution, emr, ci_low, ci_high, error_bound
end

"""
    integrate(sc::PFGPCI; seed=nothing, verbose=false) -> QMCResult

Run the adaptive PFGPCI loop and return the probability-of-failure estimate. The
result's `data` carries the per-batch trajectory (`:solutions`, `:error_bounds`,
`:ci_low`, `:ci_high`, `:n_batch`), the final credible interval (`:bound_low`,
`:bound_high`), `:n_total`, and `:converged`.

**Experimental.** This method depends on QMC.jl's optional Gaussian-process
backend extension and may change before the API is declared stable.

Requires the `AbstractGPs`/`Optim` GP backend extension to be loaded.
"""
function integrate(sc::PFGPCI; seed=nothing, verbose::Bool=false)
    if !_pfgpci_backend_loaded()
        error(
            "PFGPCI requires a Gaussian-process backend, supplied by QMC's " *
            "`QMCAbstractGPsExt` package extension. Install and load AbstractGPs " *
            "and Optim to enable it:\n\n" *
            "    using AbstractGPs, Optim   # loads QMC's GP backend\n" *
            "    integrate(PFGPCI(integrand; ...))\n",
        )
    end

    integrand = sc.integrand
    tm = true_measure(integrand)
    d = dimension(tm)
    dd = discrete_distribution(tm)
    rng = isnothing(seed) ? Random.default_rng() : Random.MersenneTwister(seed)

    # Fixed low-discrepancy bank for approximating the estimate / credible interval,
    # plus a disjoint QMC block for the initial design (non-overlapping `n_start`).
    qmc_pts = _sample_uniform_points(dd, sc.n_approx)
    if size(qmc_pts, 1) != sc.n_approx
        # replicated distributions flatten to R*n rows; trim to the requested count
        qmc_pts = qmc_pts[1:min(sc.n_approx, size(qmc_pts, 1)), :]
    end

    x = Matrix{Float64}(undef, 0, d)
    y = Float64[]
    solutions = Float64[]
    error_bounds = Float64[]
    ci_low = Float64[]
    ci_high = Float64[]
    n_batch = Int[]
    emr_last = 0.0
    model = nothing
    n_total = 0
    converged = false
    batch = 0

    while true
        if batch == 0
            xdraw = _sample_uniform_points(dd, sc.n_init; n_start=sc.n_approx)
            xdraw = xdraw[1:min(sc.n_init, size(xdraw, 1)), :]
        else
            n_new = min(sc.n_batch, sc.n_limit - n_total)
            xdraw = _pfgpci_ar_suggest(n_new, d, model, rng, 2 * emr_last)
        end
        ydraw = evaluate_on_uniform(integrand, xdraw)
        ytf = _pfgpci_affine_tf(sc, vec(ydraw))

        x = vcat(x, xdraw)
        append!(y, ytf)
        n_total += size(xdraw, 1)

        model = _pfgpci_fit(x, y)
        mean_q, std_q = _pfgpci_predict(model, qmc_pts)
        phi = _pfgpci_phi(mean_q, std_q)
        solution, emr, lo, hi, eb = _pfgpci_credible_interval(phi, sc.alpha)
        emr_last = emr

        push!(solutions, solution)
        push!(error_bounds, eb)
        push!(ci_low, lo)
        push!(ci_high, hi)
        push!(n_batch, size(xdraw, 1))
        batch += 1

        if verbose
            @info "PFGPCI batch $batch" n_total solution error_bound = eb
        end

        if eb <= sc.abs_tol
            converged = true
            break
        end
        if n_total >= sc.n_limit
            break
        end
    end

    data = Dict{Symbol, Any}(
        :n_total => n_total,
        :error_bound => error_bounds[end],
        :bound_low => ci_low[end],
        :bound_high => ci_high[end],
        :bound_diff => ci_high[end] - ci_low[end],
        :converged => converged,
        :confidence_level => 1.0 - sc.alpha,
        :solutions => copy(solutions),
        :error_bounds => copy(error_bounds),
        :ci_low => copy(ci_low),
        :ci_high => copy(ci_high),
        :n_batch => copy(n_batch),
        :n_iter => batch,
    )
    return QMCResult(solutions[end], data)
end

function Base.show(io::IO, sc::PFGPCI)
    print(
        io,
        "PFGPCI(failure_threshold=$(sc.failure_threshold), abs_tol=$(sc.abs_tol), ",
        "alpha=$(sc.alpha), n_limit=$(sc.n_limit))",
    )
end
