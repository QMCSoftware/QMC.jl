"""
    CubMLMCCont(integrand::AbstractMLIntegrand; abs_tol=0.05, n_init=256,
                n_limit=10_000_000_000, alpha_ci=0.01,
                levels_min=2, levels_max=10,
                n_tols=10, inflate=100^(1/9), theta_init=0.5,
                trace_iterations=false)

Continuation multilevel Monte Carlo (MLMC) stopping criterion.

Runs the MLMC algorithm at a sequence of progressively tighter tolerances
(from `inflate^(n_tols-1) * target_tol` down to `target_tol`), reusing
samples from coarser tolerances. This improves the estimation of the
convergence rates α, β, γ before the final tolerance is reached.

Set `trace_iterations=true` to record an `IterationLog` in
`result.data[:iteration_log]`.

# Arguments
- `integrand`: A multilevel integrand (`AbstractMLIntegrand`).
- `abs_tol`: Absolute error tolerance.
- `n_init`: Initial number of samples per level.
- `n_limit`: Maximum total number of samples.
- `alpha_ci`: Confidence level for `abs_tol` → RMSE conversion.
- `levels_min`: Minimum refinement levels (≥ 2).
- `levels_max`: Maximum refinement levels.
- `n_tols`: Number of coarser tolerance steps.
- `inflate`: Multiplication factor between successive tolerances (≥ 1).
- `theta_init`: Initial error-splitting parameter.

# Examples
```jldoctest
julia> using QuasiMC

julia> f = FinancialOptionML(IIDStdUniform(32; seed=7); d_coarsest=4, option_type=:asian)
FinancialOptionML(:asian, :call, d=32, d_coarsest=4, levels=4)

julia> sc = CubMLMCCont(f; abs_tol=0.5, n_init=256, levels_min=2, levels_max=6, n_tols=5)
CubMLMCCont(rmse_tol=1.94e-01, n_init=256, n_tols=5, inflate=1.668)

julia> result = integrate(sc);

julia> result.data[:n_total] > 0
true

julia> result.data[:levels] >= 3
true
```

# References
1. [MultilevelEstimators.jl](https://github.com/PieterjanRobbe/MultilevelEstimators.jl)
"""
mutable struct CubMLMCCont{I <: AbstractMLIntegrand} <: AbstractStoppingCriterion
    integrand::I
    target_tol::Float64
    n_init::Int
    n_limit::Int
    levels_min::Int
    levels_max::Int
    n_tols::Int
    inflate::Float64
    theta_init::Float64
    theta::Float64
    alpha0::Float64
    beta0::Float64
    gamma0::Float64
    trace_iterations::Bool
end

function CubMLMCCont(
    integrand::AbstractMLIntegrand;
    abs_tol::Float64=0.05,
    rmse_tol::Union{Nothing, Float64}=nothing,
    n_init::Int=256,
    n_limit::Int=10_000_000_000,
    alpha_ci::Float64=0.01,
    levels_min::Int=2,
    levels_max::Int=10,
    n_tols::Int=10,
    inflate::Float64=100.0^(1/9),
    theta_init::Float64=0.5,
    trace_iterations::Bool=false,
)
    levels_min >= 2 || throw(ArgumentError("levels_min must be ≥ 2"))
    levels_max >= levels_min || throw(ArgumentError("levels_max must be ≥ levels_min"))
    n_init > 0 || throw(ArgumentError("n_init must be > 0"))
    inflate >= 1.0 || throw(ArgumentError("inflate must be ≥ 1"))
    0 < alpha_ci < 1 || throw(ArgumentError("alpha_ci must be in (0,1)"))

    if isnothing(rmse_tol)
        z = quantile(Normal(), 1.0 - alpha_ci / 2.0)
        target_tol = abs_tol / z
    else
        target_tol = rmse_tol
    end

    return CubMLMCCont(
        integrand,
        target_tol,
        n_init,
        n_limit,
        levels_min,
        levels_max,
        n_tols,
        inflate,
        theta_init,
        theta_init,
        -1.0,
        -1.0,
        -1.0,
        trace_iterations,
    )
end

# ── Internal state (reuses _MLMCState from cub_mlmc.jl) ──

function _init_mlmc_cont_state(sc::CubMLMCCont)
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
        AbstractTrueMeasure[],
    )
end

# ── Bias estimation ──

function _estimate_bias(state::_MLMCState, level::Int)
    if level < 1
        return Inf
    end
    # Linear regression on last two levels
    l1 = level      # 0-based
    l0 = level - 1
    y0 = log2(max(abs(state.sum_level[1, l0 + 1] / max(state.n_level[l0 + 1], 1)), 1e-300))
    y1 = log2(max(abs(state.sum_level[1, l1 + 1] / max(state.n_level[l1 + 1], 1)), 1e-300))
    A = [Float64(l0) 1.0; Float64(l1) 1.0]
    y = [y0, y1]
    x = A \ y
    alpha_est = max(0.5, -x[1])
    bias = 2^(x[2] + (level + 1) * x[1]) / (2^alpha_est - 1)
    return abs(bias)
end

function _varest(state::_MLMCState)
    L = state.levels
    s = 0.0
    for l in 0:L
        nl = state.n_level[l + 1]
        if nl > 0
            s += state.var_level[l + 1] / nl
        end
    end
    return s
end

function _mse(sc::CubMLMCCont, state::_MLMCState, step_tol::Float64)
    bias = _estimate_bias(state, state.levels)
    return (1 - sc.theta) * _varest(state) + sc.theta * bias^2
end

function _rmse(sc::CubMLMCCont, state::_MLMCState, step_tol::Float64)
    return sqrt(max(0.0, _mse(sc, state, step_tol)))
end

function _update_theta!(sc::CubMLMCCont, state::_MLMCState, step_tol::Float64)
    bias = _estimate_bias(state, state.levels)
    sc.theta = clamp((bias / step_tol)^2, 0.01, 0.5)
end

# ── Optimal sample allocation (same formula as CubMLMC) ──

function _get_optimal_samples_cont(sc::CubMLMCCont, state::_MLMCState)
    L = state.levels
    vl = state.var_level[1:(L + 1)]
    cl = max.(state.cost_per_sample[1:(L + 1)], 1e-300)
    sqrt_vc = sqrt.(vl .* cl)
    sqrt_v_over_c = sqrt.(vl ./ cl)
    ns = ceil.(Int, sqrt_v_over_c .* sum(sqrt_vc) ./ ((1 - sc.theta) * sc.target_tol^2))
    return ns
end

# ── Single tolerance step ──

function _integrate_step!(sc::CubMLMCCont, state::_MLMCState, step_tol::Float64)
    sc.theta = sc.theta_init

    # Ensure warm-up samples exist
    diff_n = zeros(Int, state.levels + 1)
    for l in 0:state.levels
        if state.n_level[l + 1] == 0
            diff_n[l + 1] = sc.n_init
        end
    end
    if sum(diff_n) > 0
        _update_samples_cont!(sc, state, diff_n)
    end

    converged = false
    while !converged
        # Ensure finest level has samples
        if state.n_level[state.levels + 1] == 0
            diff_n = zeros(Int, state.levels + 1)
            diff_n[state.levels + 1] = sc.n_init
            _update_samples_cont!(sc, state, diff_n)
        end

        # Update error splitting
        _update_theta!(sc, state, step_tol)

        # Optimal allocation
        n_opt = _get_optimal_samples_cont(sc, state)
        diff_n = max.(0, n_opt .- state.n_level[1:(state.levels + 1)])

        # Check budget
        n_total = sum(state.n_level)
        if n_total + sum(diff_n) > sc.n_limit
            @warn "CubMLMCCont: would exceed n_limit=$(sc.n_limit). Stopping."
            break
        end

        # Take samples
        if sum(diff_n) > 0
            _update_samples_cont!(sc, state, diff_n)
        end

        # Check convergence
        converged = _rmse(sc, state, step_tol) < step_tol
        if !converged
            if state.levels >= sc.levels_max
                @warn "CubMLMCCont: failed to achieve weak convergence (levels == levels_max=$(sc.levels_max))."
                converged = true
            else
                _add_level_cont!(sc, state)
            end
        end
    end
end

# ── Helpers that mirror CubMLMC but operate on CubMLMCCont ──

function _ensure_level_spawned_cont!(sc::CubMLMCCont, state::_MLMCState, l::Int)
    while length(state.level_dd) <= l
        level_idx = length(state.level_dd)
        d_l = dimension_at_level(sc.integrand, level_idx)
        tm = true_measure(sc.integrand)
        dd_l = spawn_dd(discrete_distribution(tm), d_l)
        tm_l = spawn_tm(tm, dd_l)
        push!(state.level_dd, dd_l)
        push!(state.level_tm, tm_l)
    end
end

function _update_samples_cont!(sc::CubMLMCCont, state::_MLMCState, diff_n::Vector{Int})
    for l in 0:state.levels
        if l+1 > length(diff_n) || diff_n[l + 1] <= 0
            continue
        end
        _ensure_level_spawned_cont!(sc, state, l)
        n = diff_n[l + 1]
        dp, cost = ml_sample_and_evaluate(
            sc.integrand,
            state.level_dd[l + 1],
            state.level_tm[l + 1],
            n,
            l,
        )
        state.n_level[l + 1] += n
        state.sum_level[1, l + 1] += sum(dp)
        state.sum_level[2, l + 1] += sum(dp .^ 2)
        state.cost_level[l + 1] += cost
    end
    _refresh_statistics_cont!(sc, state)
end

function _refresh_statistics_cont!(sc::CubMLMCCont, state::_MLMCState)
    L = state.levels
    for l in 0:L
        nl = state.n_level[l + 1]
        if nl > 0
            state.mean_level[l + 1] = abs(state.sum_level[1, l + 1] / nl)
            state.var_level[l + 1] =
                max(0.0, state.sum_level[2, l + 1] / nl - state.mean_level[l + 1]^2)
            state.cost_per_sample[l + 1] = state.cost_level[l + 1] / nl
        end
    end
    # Fix zero values
    for l in 2:L
        state.mean_level[l + 1] =
            max(state.mean_level[l + 1], 0.5 * state.mean_level[l] / 2^state.alpha)
        state.var_level[l + 1] =
            max(state.var_level[l + 1], 0.5 * state.var_level[l] / 2^state.beta)
    end
    # Regression
    if L >= 2
        a_mat = ones(L, 2)
        a_mat[:, 1] = 1:L
        if sc.alpha0 <= 0
            y = log2.(max.(state.mean_level[2:(L + 1)], 1e-300))
            x = a_mat \ y
            state.alpha = max(0.5, -x[1])
        end
        if sc.beta0 <= 0
            y = log2.(max.(state.var_level[2:(L + 1)], 1e-300))
            x = a_mat \ y
            state.beta = max(0.5, -x[1])
        end
        if sc.gamma0 <= 0
            y = log2.(max.(state.cost_per_sample[2:(L + 1)], 1e-300))
            x = a_mat \ y
            state.gamma = max(0.5, x[1])
        end
    end
end

function _add_level_cont!(sc::CubMLMCCont, state::_MLMCState)
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

# ── Main integrate method ──

function integrate(sc::CubMLMCCont; resume::Union{Nothing, Dict{Symbol, Any}}=nothing)
    t_start = time()
    state = _init_mlmc_cont_state(sc)
    log = IterationLog()

    # Loop over progressively tighter tolerances
    for t in 0:(sc.n_tols - 1)
        step_tol = sc.inflate^(sc.n_tols - t - 1) * sc.target_tol
        _integrate_step!(sc, state, step_tol)
        if sc.trace_iterations
            push!(
                log;
                n=sum(state.n_level),
                solution=_solution_mlmc(state),
                error_bound=_rmse(sc, state, step_tol),
                tol=step_tol,
                elapsed=time() - t_start,
            )
        end
    end

    # Compute final solution
    solution = sum(
        state.sum_level[1, l + 1] / state.n_level[l + 1] for
        l in 0:state.levels if state.n_level[l + 1] > 0
    )
    n_total = sum(state.n_level)
    t_elapsed = time() - t_start

    data = Dict{Symbol, Any}(
        :n_total => n_total,
        :levels => state.levels + 1,
        :n_level => state.n_level[1:(state.levels + 1)],
        :mean_level => state.mean_level[1:(state.levels + 1)],
        :var_level => state.var_level[1:(state.levels + 1)],
        :cost_per_sample => state.cost_per_sample[1:(state.levels + 1)],
        :alpha => state.alpha,
        :beta => state.beta,
        :gamma => state.gamma,
        :rmse_tol => sc.target_tol,
        :time_integrate => t_elapsed,
    )
    if sc.trace_iterations
        data[:iteration_log] = log
    end

    return QMCResult(solution, data)
end

function Base.show(io::IO, sc::CubMLMCCont)
    @printf(
        io,
        "CubMLMCCont(rmse_tol=%.2e, n_init=%d, n_tols=%d, inflate=%.3f)",
        sc.target_tol,
        sc.n_init,
        sc.n_tols,
        sc.inflate
    )
end
