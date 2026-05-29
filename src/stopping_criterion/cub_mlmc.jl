"""
    CubMLMC(integrand::AbstractMLIntegrand; abs_tol=0.05, n_init=256,
            n_limit=10_000_000_000, alpha_ci=0.01,
            levels_min=2, levels_max=10,
            alpha0=-1.0, beta0=-1.0, gamma0=-1.0)

Multilevel Monte Carlo (MLMC) stopping criterion based on Giles (2008).

Uses the telescoping sum E[Q_L] = E[Q_0] + Σ E[Q_l - Q_{l-1}] and
allocates samples optimally across levels to minimize total cost for a
given RMSE tolerance.

The rates α (weak error), β (variance decay), γ (cost growth) are
estimated via linear regression if not provided (`alpha0`, `beta0`,
`gamma0` ≤ 0).

# Arguments
- `integrand`: A multilevel integrand (`AbstractMLIntegrand`).
- `abs_tol`: Absolute error tolerance (converted to RMSE tolerance internally).
- `n_init`: Initial number of samples per level for warm-up.
- `n_limit`: Maximum total number of samples.
- `alpha_ci`: Confidence level for converting `abs_tol` to RMSE tolerance.
- `levels_min`: Minimum number of refinement levels (≥ 2).
- `levels_max`: Maximum number of refinement levels.
- `alpha0`, `beta0`, `gamma0`: Convergence rates. If ≤ 0, estimated automatically.

# Example
```julia
dd = IIDStdUniform(1)
tm = BrownianMotion(dd)
f = FinancialOptionML(tm)  # a multilevel integrand
sc = CubMLMC(f; abs_tol=0.05)
result = integrate(sc)
```

# References
1. M.B. Giles. "Multi-level Monte Carlo path simulation."
   Operations Research, 56(3):607–617, 2008.
"""
mutable struct CubMLMC <: AbstractStoppingCriterion
    integrand::AbstractMLIntegrand
    rmse_tol::Float64
    n_init::Int
    n_limit::Int
    levels_min::Int
    levels_max::Int
    theta::Float64
    alpha0::Float64
    beta0::Float64
    gamma0::Float64
end

function CubMLMC(integrand::AbstractMLIntegrand;
                  abs_tol::Float64 = 0.05,
                  rmse_tol::Union{Nothing, Float64} = nothing,
                  n_init::Int = 256,
                  n_limit::Int = 10_000_000_000,
                  alpha_ci::Float64 = 0.01,
                  levels_min::Int = 2,
                  levels_max::Int = 10,
                  alpha0::Float64 = -1.0,
                  beta0::Float64 = -1.0,
                  gamma0::Float64 = -1.0)
    levels_min >= 2 || throw(ArgumentError("levels_min must be ≥ 2"))
    levels_max >= levels_min || throw(ArgumentError("levels_max must be ≥ levels_min"))
    n_init > 0 || throw(ArgumentError("n_init must be > 0"))
    0 < alpha_ci < 1 || throw(ArgumentError("alpha_ci must be in (0,1)"))

    if isnothing(rmse_tol)
        z = quantile(Normal(), 1.0 - alpha_ci / 2.0)
        rmse_tol = abs_tol / z
    end

    return CubMLMC(integrand, rmse_tol, n_init, n_limit, levels_min, levels_max,
                    0.5, alpha0, beta0, gamma0)
end

# ── Internal MLMC State ──

mutable struct _MLMCState
    levels::Int                    # current number of levels (0-indexed, so levels+1 total)
    n_level::Vector{Int}           # samples taken at each level
    sum_level::Matrix{Float64}     # [2, max_levels]: row 1 = sum(dp), row 2 = sum(dp^2)
    cost_level::Vector{Float64}    # cumulative cost at each level
    mean_level::Vector{Float64}    # |mean| at each level
    var_level::Vector{Float64}     # variance at each level
    cost_per_sample::Vector{Float64}
    alpha::Float64                 # weak error rate
    beta::Float64                  # variance decay rate
    gamma::Float64                 # cost growth rate
    # Per-level discrete distributions and true measures (spawned)
    level_dd::Vector{AbstractDiscreteDistribution}
    level_tm::Vector{AbstractTrueMeasure}
end

function _init_mlmc_state(sc::CubMLMC)
    L = sc.levels_min
    n = L + 1
    return _MLMCState(
        L,
        zeros(Int, n),
        zeros(2, n),
        zeros(n),
        zeros(n),
        zeros(n),
        zeros(n),
        max(0.0, sc.alpha0),
        max(0.0, sc.beta0),
        max(0.0, sc.gamma0),
        AbstractDiscreteDistribution[],
        AbstractTrueMeasure[]
    )
end

# ── Helper: ensure level l has a spawned DD and TM ──

function _ensure_level_spawned!(sc::CubMLMC, state::_MLMCState, l::Int)
    while length(state.level_dd) <= l
        level_idx = length(state.level_dd)  # 0-based level
        d_l = dimension_at_level(sc.integrand, level_idx)
        dd_l = spawn_dd(sc.integrand.true_measure.dd, d_l)
        tm_l = spawn_tm(sc.integrand.true_measure, dd_l)
        push!(state.level_dd, dd_l)
        push!(state.level_tm, tm_l)
    end
end

# ── Helper: expand state arrays for a new level ──

function _add_level!(sc::CubMLMC, state::_MLMCState)
    state.levels += 1
    L = state.levels
    if length(state.n_level) <= L
        push!(state.n_level, 0)
        state.sum_level = hcat(state.sum_level, zeros(2))
        push!(state.cost_level, 0.0)
        push!(state.mean_level, state.mean_level[end] / 2^state.alpha)
        push!(state.var_level, state.var_level[end] / 2^state.beta)
        push!(state.cost_per_sample, state.cost_per_sample[end] * 2^state.gamma)
    end
end

# ── Helper: take samples and update sums ──

function _update_samples!(sc::CubMLMC, state::_MLMCState, diff_n::Vector{Int})
    for l in 0:state.levels
        if diff_n[l+1] <= 0
            continue
        end
        _ensure_level_spawned!(sc, state, l)
        n = diff_n[l+1]
        dp, cost = ml_sample_and_evaluate(sc.integrand, state.level_dd[l+1],
                                           state.level_tm[l+1], n, l)
        state.n_level[l+1] += n
        state.sum_level[1, l+1] += sum(dp)
        state.sum_level[2, l+1] += sum(dp .^ 2)
        state.cost_level[l+1] += cost
    end
    _refresh_statistics!(sc, state)
end

# ── Helper: refresh mean/var/cost estimates and regression ──

function _refresh_statistics!(sc::CubMLMC, state::_MLMCState)
    L = state.levels
    for l in 0:L
        nl = state.n_level[l+1]
        if nl > 0
            state.mean_level[l+1] = abs(state.sum_level[1, l+1] / nl)
            state.var_level[l+1] = max(0.0,
                state.sum_level[2, l+1] / nl - state.mean_level[l+1]^2)
            state.cost_per_sample[l+1] = state.cost_level[l+1] / nl
        end
    end

    # Fix zero values by extrapolation
    for l in 2:L
        state.mean_level[l+1] = max(state.mean_level[l+1],
            0.5 * state.mean_level[l] / 2^state.alpha)
        state.var_level[l+1] = max(state.var_level[l+1],
            0.5 * state.var_level[l] / 2^state.beta)
    end

    # Linear regression to estimate alpha, beta, gamma
    if L >= 2
        a_mat = ones(L, 2)
        a_mat[:, 1] = 1:L

        if sc.alpha0 <= 0
            y = log2.(max.(state.mean_level[2:L+1], 1e-300))
            x = a_mat \ y
            state.alpha = max(0.5, -x[1])
        end
        if sc.beta0 <= 0
            y = log2.(max.(state.var_level[2:L+1], 1e-300))
            x = a_mat \ y
            state.beta = max(0.5, -x[1])
        end
        if sc.gamma0 <= 0
            y = log2.(max.(state.cost_per_sample[2:L+1], 1e-300))
            x = a_mat \ y
            state.gamma = max(0.5, x[1])
        end
    end
end

# ── Helper: compute optimal sample allocation ──

function _get_optimal_samples(sc::CubMLMC, state::_MLMCState)
    L = state.levels
    vl = state.var_level[1:L+1]
    cl = state.cost_per_sample[1:L+1]
    # Optimal allocation: n_l ∝ sqrt(V_l / C_l) * sum(sqrt(V_l * C_l)) / ((1-θ) * ε²)
    sqrt_vc = sqrt.(vl .* cl)
    sqrt_v_over_c = sqrt.(vl ./ max.(cl, 1e-300))
    ns = ceil.(Int, sqrt_v_over_c .* sum(sqrt_vc) ./ ((1 - sc.theta) * sc.rmse_tol^2))
    return ns
end

# ── Main integrate method ──

function integrate(sc::CubMLMC; resume::Union{Nothing, Dict{Symbol,Any}} = nothing)
    t_start = time()
    state = _init_mlmc_state(sc)

    # Initial warm-up: n_init samples at each level
    diff_n = fill(sc.n_init, state.levels + 1)
    _update_samples!(sc, state, diff_n)

    # Main loop
    while true
        # Compute optimal number of samples
        n_opt = _get_optimal_samples(sc, state)
        diff_n = max.(0, n_opt .- state.n_level[1:state.levels+1])

        # Check sample budget
        n_total = sum(state.n_level)
        if n_total + sum(diff_n) > sc.n_limit
            @warn "CubMLMC: would exceed n_limit=$(sc.n_limit). Stopping."
            break
        end

        # Take additional samples
        _update_samples!(sc, state, diff_n)

        # Check if (almost) converged
        if all(diff_n .<= ceil.(Int, 0.01 .* state.n_level[1:state.levels+1]))
            # Estimate remaining bias
            L = state.levels
            range_check = min(2, L - 1)
            rem = 0.0
            for k in 0:range_check
                idx = L - k  # 0-based level
                rem = max(rem, state.mean_level[idx+1] / 2.0^(k * state.alpha))
            end
            rem /= (2.0^state.alpha - 1)

            if rem > sqrt(sc.theta) * sc.rmse_tol
                # Need more levels
                if state.levels >= sc.levels_max
                    @warn "CubMLMC: failed to achieve weak convergence (levels == levels_max=$(sc.levels_max))."
                    break
                else
                    _add_level!(sc, state)
                    # Recompute optimal samples with new level
                    n_opt = _get_optimal_samples(sc, state)
                    diff_n = max.(0, n_opt .- state.n_level[1:state.levels+1])
                    continue
                end
            else
                # Converged
                break
            end
        end
    end

    # Compute final solution
    solution = sum(state.sum_level[1, l+1] / state.n_level[l+1]
                   for l in 0:state.levels if state.n_level[l+1] > 0)
    n_total = sum(state.n_level)
    t_elapsed = time() - t_start

    data = Dict{Symbol, Any}(
        :n_total => n_total,
        :levels => state.levels + 1,  # number of levels (1-based for display)
        :n_level => state.n_level[1:state.levels+1],
        :mean_level => state.mean_level[1:state.levels+1],
        :var_level => state.var_level[1:state.levels+1],
        :cost_per_sample => state.cost_per_sample[1:state.levels+1],
        :alpha => state.alpha,
        :beta => state.beta,
        :gamma => state.gamma,
        :rmse_tol => sc.rmse_tol,
        :time_integrate => t_elapsed,
    )

    return QMCResult(solution, data)
end

function Base.show(io::IO, sc::CubMLMC)
    @printf(io, "CubMLMC(rmse_tol=%.2e, n_init=%d, levels_min=%d, levels_max=%d)",
            sc.rmse_tol, sc.n_init, sc.levels_min, sc.levels_max)
end
