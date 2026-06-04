"""
    CubMLQMCCont(integrand::AbstractMLIntegrand; abs_tol=0.05, n_init=256,
                 n_limit=10_000_000_000, alpha_ci=0.01,
                 levels_min=2, levels_max=10,
                 n_tols=10, inflate=100^(1/9), theta_init=0.5)

Continuation multilevel quasi-Monte Carlo (MLQMC) stopping criterion.

Uses replicated low-discrepancy sequences (lattice or digital net) at each
level to estimate the variance of the QMC estimator per replication.
The variance is driven down by doubling the sample size at the most
cost-efficient level. A continuation strategy with `n_tols` progressively
tighter tolerances improves convergence rate estimation.

The discrete distribution must have `replications ≥ 4`.

# Arguments
- `integrand`: A multilevel integrand (`AbstractMLIntegrand`).
- `abs_tol`: Absolute error tolerance.
- `n_init`: Initial number of samples per replication per level.
- `n_limit`: Maximum total number of samples.
- `alpha_ci`: Confidence level for `abs_tol` → RMSE conversion.
- `levels_min`: Minimum refinement levels (≥ 2).
- `levels_max`: Maximum refinement levels.
- `n_tols`: Number of coarser tolerance steps.
- `inflate`: Multiplication factor between successive tolerances (≥ 1).
- `theta_init`: Initial error-splitting parameter.

# Example
```julia
dd = Lattice(1; replications=16)
tm = BrownianMotion(dd)
f = FinancialOptionML(tm)
sc = CubMLQMCCont(f; abs_tol=0.01)
result = integrate(sc)
```

# References
1. [MultilevelEstimators.jl](https://github.com/PieterjanRobbe/MultilevelEstimators.jl)
"""
mutable struct CubMLQMCCont{I <: AbstractMLIntegrand} <: AbstractStoppingCriterion
    integrand::I
    target_tol::Float64
    n_init::Int
    n_limit::Int
    replications::Int
    levels_min::Int
    levels_max::Int
    n_tols::Int
    inflate::Float64
    theta_init::Float64
    theta::Float64
end

function CubMLQMCCont(
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
)
    levels_min >= 2 || throw(ArgumentError("levels_min must be ≥ 2"))
    levels_max >= levels_min || throw(ArgumentError("levels_max must be ≥ levels_min"))
    n_init > 0 || throw(ArgumentError("n_init must be > 0"))
    inflate >= 1.0 || throw(ArgumentError("inflate must be ≥ 1"))
    0 < alpha_ci < 1 || throw(ArgumentError("alpha_ci must be in (0,1)"))

    dd = integrand.true_measure.dd
    R = hasproperty(dd, :replications) && !isnothing(dd.replications) ? dd.replications : 1
    R >= 4 || throw(ArgumentError("CubMLQMCCont requires replications ≥ 4, got $R"))

    if isnothing(rmse_tol)
        z = quantile(Normal(), 1.0 - alpha_ci / 2.0)
        target_tol = abs_tol / z
    else
        target_tol = rmse_tol
    end

    return CubMLQMCCont(
        integrand,
        target_tol,
        n_init,
        n_limit,
        R,
        levels_min,
        levels_max,
        n_tols,
        inflate,
        theta_init,
        theta_init,
    )
end

# ── MLQMC internal state ──

mutable struct _MLQMCState
    levels::Int                         # number of levels (0-indexed max level)
    n_level::Vector{Int}                # samples per replication at each level
    eval_level::Vector{Bool}            # which levels need evaluation
    mean_level_reps::Vector{Vector{Float64}}  # per-replication means at each level
    mean_level::Vector{Float64}         # overall mean at each level
    var_level::Vector{Float64}          # variance of replication means
    cost_level::Vector{Float64}         # cumulative cost
    var_cost_ratio::Vector{Float64}     # var / cost_per_sample
    bias_estimate::Float64
    level_dd::Vector{AbstractDiscreteDistribution}
    level_tm::Vector{AbstractTrueMeasure}
end

function _init_mlqmc_state(sc::CubMLQMCCont)
    L = sc.levels_min + 1  # number of levels (Python convention: levels_min + 1 initial levels)
    R = sc.replications
    return _MLQMCState(
        L,
        zeros(Int, L),
        ones(Bool, L),
        [zeros(R) for _ in 1:L],
        zeros(L),
        fill(Inf, L),
        zeros(L),
        fill(Inf, L),
        Inf,
        AbstractDiscreteDistribution[],
        AbstractTrueMeasure[],
    )
end

function _ensure_level_spawned_qmc!(sc::CubMLQMCCont, state::_MLQMCState, l::Int)
    while length(state.level_dd) <= l
        level_idx = length(state.level_dd)
        d_l = dimension_at_level(sc.integrand, level_idx)
        dd_l = spawn_dd(sc.integrand.true_measure.dd, d_l)
        tm_l = spawn_tm(sc.integrand.true_measure, dd_l)
        push!(state.level_dd, dd_l)
        push!(state.level_tm, tm_l)
    end
end

function _add_level_qmc!(sc::CubMLQMCCont, state::_MLQMCState)
    state.levels += 1
    L = state.levels
    R = sc.replications
    if L > length(state.n_level)
        push!(state.n_level, 0)
        push!(state.eval_level, true)
        push!(state.mean_level_reps, zeros(R))
        push!(state.mean_level, 0.0)
        push!(state.var_level, Inf)
        push!(state.cost_level, 0.0)
        push!(state.var_cost_ratio, Inf)
    end
end

# ── Update data: evaluate levels that need it ──

function _update_data_qmc!(sc::CubMLQMCCont, state::_MLQMCState)
    R = sc.replications
    for l in 0:(state.levels - 1)
        if !state.eval_level[l + 1]
            continue
        end
        _ensure_level_spawned_qmc!(sc, state, l)

        # Determine sample size: double or init
        n_max = state.n_level[l + 1] == 0 ? sc.n_init : 2 * state.n_level[l + 1]
        n_new = n_max - state.n_level[l + 1]

        dd_l = state.level_dd[l + 1]
        tm_l = state.level_tm[l + 1]

        # Evaluate R replications of n_new samples each
        rep_sums = zeros(R)
        for r in 1:R
            x_uniform = gen_samples(dd_l, n_new)
            if ndims(x_uniform) == 3
                # Replicated sampler — take slice r
                x_uniform = x_uniform[r, :, :]
            end
            x_transformed = transform(tm_l, x_uniform)
            Qc, Qf = ml_evaluate(sc.integrand, x_transformed, l)
            rep_sums[r] = sum(Qf .- Qc)
        end

        # Update running means per replication
        prev_sum = state.mean_level_reps[l + 1] .* state.n_level[l + 1]
        state.mean_level_reps[l + 1] = (rep_sums .+ prev_sum) ./ n_max

        cost_per = cost_at_level(sc.integrand, l)
        state.cost_level[l + 1] += R * n_new * cost_per
        state.n_level[l + 1] = n_max
        state.mean_level[l + 1] = mean(state.mean_level_reps[l + 1])
        state.var_level[l + 1] = var(state.mean_level_reps[l + 1]; corrected=false)
        cps = state.cost_level[l + 1] / state.n_level[l + 1] / R
        state.var_cost_ratio[l + 1] = state.var_level[l + 1] / max(cps, 1e-300)
    end

    # Update bias estimate
    _update_bias_qmc!(state)

    # Reset eval flags
    state.eval_level .= false
end

function _update_bias_qmc!(state::_MLQMCState)
    L = state.levels
    if L < 2
        state.bias_estimate = Inf
        return
    end
    l0 = L - 2  # 0-based
    l1 = L - 1
    y0 = log2(max(abs(mean(state.mean_level_reps[l0 + 1])), 1e-300))
    y1 = log2(max(abs(mean(state.mean_level_reps[l1 + 1])), 1e-300))
    A = [Float64(l0) 1.0; Float64(l1) 1.0]
    y = [y0, y1]
    x = A \ y
    alpha_est = max(0.5, -x[1])
    state.bias_estimate = abs(2^(x[2] + L * x[1]) / (2^alpha_est - 1))
end

function _update_theta_qmc!(sc::CubMLQMCCont, state::_MLQMCState, step_tol::Float64)
    L = state.levels
    if L < 2
        sc.theta = sc.theta_init
        return
    end
    l0 = L - 2
    l1 = L - 1
    y0 = log2(max(abs(mean(state.mean_level_reps[l0 + 1])), 1e-300))
    y1 = log2(max(abs(mean(state.mean_level_reps[l1 + 1])), 1e-300))
    A = [Float64(l0) 1.0; Float64(l1) 1.0]
    y = [y0, y1]
    x = A \ y
    alpha_est = max(0.5, -x[1])
    real_bias = abs(2^(x[2] + L * x[1]) / (2^alpha_est - 1))
    sc.theta = clamp((real_bias / step_tol)^2, 0.01, 0.125)
end

_varest_qmc(state::_MLQMCState) = sum(state.var_level[1:state.levels])

function _mse_qmc(sc::CubMLQMCCont, state::_MLQMCState)
    return (1 - sc.theta) * _varest_qmc(state) + sc.theta * state.bias_estimate^2
end

_rmse_qmc(sc::CubMLQMCCont, state::_MLQMCState) = sqrt(max(0.0, _mse_qmc(sc, state)))

# ── Single tolerance step ──

function _integrate_step_qmc!(sc::CubMLQMCCont, state::_MLQMCState, step_tol::Float64)
    converged = false
    while !converged
        # Ensure we have samples at all active levels
        _update_data_qmc!(sc, state)
        _update_theta_qmc!(sc, state, step_tol)

        # Inner loop: double samples at most cost-efficient level until variance target met
        while _varest_qmc(state) > (1 - sc.theta) * step_tol^2
            # Find most cost-efficient level to double
            efficient_l = argmax(state.var_cost_ratio[1:state.levels])
            state.eval_level[efficient_l] = true

            # Check budget
            total_next = sum(
                sc.replications .* state.eval_level[1:state.levels] .*
                state.n_level[1:state.levels] .* 2,
            )
            n_total = sc.replications * sum(state.n_level)
            if n_total + total_next > sc.n_limit
                @warn "CubMLQMCCont: would exceed n_limit=$(sc.n_limit). Stopping."
                return
            end

            _update_data_qmc!(sc, state)
            _update_theta_qmc!(sc, state, step_tol)
        end

        # Check convergence
        converged = _rmse_qmc(sc, state) < step_tol
        if !converged
            if state.levels >= sc.levels_max
                @warn "CubMLQMCCont: failed to achieve weak convergence (levels == levels_max=$(sc.levels_max))."
                converged = true
            else
                _add_level_qmc!(sc, state)
            end
        end
    end
end

# ── Main integrate ──

function integrate(sc::CubMLQMCCont; resume::Union{Nothing, Dict{Symbol, Any}}=nothing)
    t_start = time()
    state = _init_mlqmc_state(sc)

    # Continuation: loop over progressively tighter tolerances
    for t in 0:(sc.n_tols - 1)
        step_tol = sc.inflate^(sc.n_tols - t - 1) * sc.target_tol
        _integrate_step_qmc!(sc, state, step_tol)
    end

    # Final solution
    solution = sum(state.mean_level[1:state.levels])
    n_total = sc.replications * sum(state.n_level)
    t_elapsed = time() - t_start

    data = Dict{Symbol, Any}(
        :n_total => n_total,
        :levels => state.levels,
        :n_level => state.n_level[1:state.levels],
        :mean_level => state.mean_level[1:state.levels],
        :var_level => state.var_level[1:state.levels],
        :bias_estimate => state.bias_estimate,
        :replications => sc.replications,
        :rmse_tol => sc.target_tol,
        :time_integrate => t_elapsed,
    )

    return QMCResult(solution, data)
end

function Base.show(io::IO, sc::CubMLQMCCont)
    @printf(
        io,
        "CubMLQMCCont(rmse_tol=%.2e, n_init=%d, reps=%d, n_tols=%d)",
        sc.target_tol,
        sc.n_init,
        sc.replications,
        sc.n_tols
    )
end
