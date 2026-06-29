"""
    CubMLQMC(integrand::AbstractMLIntegrand; abs_tol=0.05, n_init=256,
             n_limit=10_000_000_000, alpha_ci=0.01,
             levels_min=2, levels_max=10, trace_iterations=false)

Multilevel quasi-Monte Carlo (MLQMC) stopping criterion.

Uses replicated low-discrepancy sequences (lattice or digital net) at each
level to estimate the QMC error via the variance of replication means.
Samples are doubled at the most cost-efficient level until the RMSE target
is met. Unlike `CubMLQMCCont`, this criterion does not use a continuation
strategy — it targets the final tolerance directly.

The discrete distribution must have `replications ≥ 4`.

Set `trace_iterations=true` to record an `IterationLog` in
`result.data[:iteration_log]`.

# Arguments
- `integrand`: A multilevel integrand (`AbstractMLIntegrand`).
- `abs_tol`: Absolute error tolerance.
- `n_init`: Initial number of samples per replication per level.
- `n_limit`: Maximum total number of samples.
- `alpha_ci`: Confidence level for `abs_tol` → RMSE conversion.
- `levels_min`: Minimum refinement levels (≥ 2).
- `levels_max`: Maximum refinement levels.

# Examples
```jldoctest
julia> using QuasiMC

julia> f = FinancialOptionML(Lattice(32; seed=7, replications=8); d_coarsest=4, option_type=:asian)
FinancialOptionML(:asian, :call, d=32, d_coarsest=4, levels=4)

julia> sc = CubMLQMC(f; abs_tol=0.5, n_init=64, levels_min=2, levels_max=6)
CubMLQMC(rmse_tol=1.94e-01, n_init=64, reps=8)

julia> result = integrate(sc);

julia> result.data[:levels] >= 3
true

julia> result.data[:n_total] > 0
true
```
"""
mutable struct CubMLQMC{I <: AbstractMLIntegrand} <: AbstractStoppingCriterion
    integrand::I
    target_tol::Float64
    n_init::Int
    n_limit::Int
    replications::Int
    levels_min::Int
    levels_max::Int
    theta::Float64
    trace_iterations::Bool
end

function Base.getproperty(sc::CubMLQMC, name::Symbol)
    if name === :rmse_tol
        return getfield(sc, :target_tol)
    end
    return getfield(sc, name)
end

function CubMLQMC(
    integrand::AbstractMLIntegrand;
    abs_tol::Float64=0.05,
    rmse_tol::Union{Nothing, Float64}=nothing,
    n_init::Int=256,
    n_limit::Int=10_000_000_000,
    alpha_ci::Float64=0.01,
    levels_min::Int=2,
    levels_max::Int=10,
    trace_iterations::Bool=false,
)
    levels_min >= 2 || throw(ArgumentError("levels_min must be ≥ 2"))
    levels_max >= levels_min || throw(ArgumentError("levels_max must be ≥ levels_min"))
    n_init > 0 || throw(ArgumentError("n_init must be > 0"))
    0 < alpha_ci < 1 || throw(ArgumentError("alpha_ci must be in (0,1)"))

    dd = discrete_distribution(integrand)
    has_reps = hasproperty(dd, :replications) && !isnothing(dd.replications)
    R = has_reps ? dd.replications : 4
    has_reps && R < 4 && throw(ArgumentError("CubMLQMC requires replications ≥ 4, got $R"))

    if isnothing(rmse_tol)
        z = quantile(Normal(), 1.0 - alpha_ci / 2.0)
        target_tol = abs_tol / z
    else
        target_tol = rmse_tol
    end

    return CubMLQMC(
        integrand,
        target_tol,
        n_init,
        n_limit,
        R,
        levels_min,
        levels_max,
        0.5,
        trace_iterations,
    )
end

# Reuse _MLQMCState from cub_mlqmc_cont.jl

function _init_mlqmc_direct_state(sc::CubMLQMC)
    L = sc.levels_min + 1
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

function _ensure_level_spawned_mlqmc!(sc::CubMLQMC, state::_MLQMCState, l::Int)
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

function _add_level_mlqmc!(sc::CubMLQMC, state::_MLQMCState)
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

function _update_data_mlqmc!(sc::CubMLQMC, state::_MLQMCState)
    R = sc.replications
    for l in 0:(state.levels - 1)
        if !state.eval_level[l + 1]
            continue
        end
        _ensure_level_spawned_mlqmc!(sc, state, l)

        n_max = state.n_level[l + 1] == 0 ? sc.n_init : 2 * state.n_level[l + 1]
        n_new = n_max - state.n_level[l + 1]

        dd_l = state.level_dd[l + 1]
        tm_l = state.level_tm[l + 1]

        rep_sums = zeros(R)
        _ml_replication_sums!(rep_sums, sc.integrand, dd_l, tm_l, n_new, l)

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

    # Update bias estimate (same as CubMLQMCCont)
    _update_bias_mlqmc!(state)
    state.eval_level .= false
end

function _update_bias_mlqmc!(state::_MLQMCState)
    L = state.levels
    if L < 2
        state.bias_estimate = Inf
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
    state.bias_estimate = abs(2^(x[2] + L * x[1]) / (2^alpha_est - 1))
end

function integrate(sc::CubMLQMC; resume::Union{Nothing, Dict{Symbol, Any}}=nothing)
    t_start = time()
    state = _init_mlqmc_direct_state(sc)
    target_tol = sc.target_tol
    log = IterationLog()

    converged = false
    while !converged
        _update_data_mlqmc!(sc, state)

        # Update theta based on bias
        if state.levels >= 2
            sc.theta = clamp((state.bias_estimate / target_tol)^2, 0.01, 0.5)
        end

        # Inner loop: double samples at most cost-efficient level
        varest = sum(state.var_level[1:state.levels])
        while varest > (1 - sc.theta) * target_tol^2
            efficient_l = argmax(state.var_cost_ratio[1:state.levels])
            state.eval_level[efficient_l] = true

            n_total = sc.replications * sum(state.n_level)
            total_next = sum(
                sc.replications .* state.eval_level[1:state.levels] .*
                state.n_level[1:state.levels] .* 2,
            )
            if n_total + total_next > sc.n_limit
                @warn "CubMLQMC: would exceed n_limit=$(sc.n_limit). Stopping."
                converged = true
                break
            end

            _update_data_mlqmc!(sc, state)
            if state.levels >= 2
                sc.theta = clamp((state.bias_estimate / target_tol)^2, 0.01, 0.5)
            end
            varest = sum(state.var_level[1:state.levels])
        end

        if converged
            rmse = sqrt(max(0.0, (1 - sc.theta) * varest + sc.theta * state.bias_estimate^2))
            if sc.trace_iterations
                push!(
                    log;
                    n=(sc.replications * sum(state.n_level)),
                    solution=sum(state.mean_level[1:state.levels]),
                    error_bound=rmse,
                    tol=target_tol,
                    elapsed=time() - t_start,
                )
            end
            break
        end

        # Check overall convergence
        rmse = sqrt(max(0.0, (1 - sc.theta) * varest + sc.theta * state.bias_estimate^2))
        if sc.trace_iterations
            push!(
                log;
                n=(sc.replications * sum(state.n_level)),
                solution=sum(state.mean_level[1:state.levels]),
                error_bound=rmse,
                tol=target_tol,
                elapsed=time() - t_start,
            )
        end
        converged = rmse < target_tol
        if !converged
            if state.levels >= sc.levels_max
                @warn "CubMLQMC: failed to achieve weak convergence (levels == levels_max=$(sc.levels_max))."
                converged = true
            else
                _add_level_mlqmc!(sc, state)
            end
        end
    end

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
    if sc.trace_iterations
        data[:iteration_log] = log
    end

    return QMCResult(solution, data)
end

function Base.show(io::IO, sc::CubMLQMC)
    @printf(
        io,
        "CubMLQMC(rmse_tol=%.2e, n_init=%d, reps=%d)",
        sc.target_tol,
        sc.n_init,
        sc.replications
    )
end
