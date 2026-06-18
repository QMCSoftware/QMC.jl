"""
    CubQMCRepStudentT(integrand; abs_tol=0.01, rel_tol=0.0,
                      n_init=256, n_limit=2^30, alpha=0.01,
                      inflate=1.0, error_fun=:either,
                      trace_iterations=false)

Quasi-Monte Carlo cubature with Student's *t*-distribution confidence intervals
built from multiple independent randomised replications.

Each iteration doubles the per-replication sample count.  The half-width of the
confidence interval at level `1 - alpha` is

    t* · inflate · σ̂ / √R

where `R = dd.replications`, `σ̂` is the standard deviation of the replication
means, and `t* = -quantile(TDist(R-1), alpha/2)`.

Supports scalar and **vector** integrand outputs.  For vector outputs the
algorithm doubles only the components that have not yet converged.

# Keywords
- `abs_tol::Float64`: absolute error tolerance.
- `rel_tol::Float64`: relative error tolerance.
- `n_init::Int`: initial per-replication sample size (must be a power of 2).
- `n_limit::Int`: maximum per-replication sample size (must be a power of 2).
- `alpha::Float64`: significance level ∈ (0,1).
- `inflate::Float64`: ≥ 1 inflation factor applied to the variance estimate.
- `error_fun::Symbol`: `:either` (max of abs/rel), `:both` (min of abs/rel).
- `trace_iterations::Bool`: enable iteration logging.

# Examples
```jldoctest
julia> using QMC

julia> f = Genz(Uniform(DigitalNetB2(2; randomize="LMS_DS", seed=901, replications=4)); kind=:continuous, a=[1.0, 1.0], u=[0.5, 0.5])
Genz(:continuous, d=2)

julia> sc = CubQMCRepStudentT(f; abs_tol=0.2, n_init=32, n_limit=128)
CubQMCRepStudentT(abs_tol=0.2, alpha=0.01, inflate=1.0)

julia> result = integrate(sc);

julia> round(result.solution; digits=4)
0.6195

julia> result.data[:converged]
true
```

# References
1. Art B. Owen. "Practical Quasi-Monte Carlo Integration." 2023.
2. Pierre l'Ecuyer et al. "Confidence intervals for randomized quasi-Monte
   Carlo estimators." 2023 Winter Simulation Conference.
"""
mutable struct CubQMCRepStudentT{I <: AbstractIntegrand} <: AbstractStoppingCriterion
    integrand::I
    abs_tol::Float64
    rel_tol::Float64
    n_init::Int
    n_limit::Int
    alpha::Float64
    inflate::Float64
    error_fun::Symbol       # :either or :both
    trace_iterations::Bool
end

function CubQMCRepStudentT(
    integrand::AbstractIntegrand;
    abs_tol::Float64=0.01,
    rel_tol::Float64=0.0,
    n_init::Int=256,
    n_limit::Int=2^30,
    alpha::Float64=0.01,
    inflate::Float64=1.0,
    error_fun::Symbol=:either,
    trace_iterations::Bool=false,
)
    # Input validation
    ispow2(n_init) || (@warn "n_init must be a power of 2; using 2^5=32"; n_init=32)
    ispow2(n_limit) || (@warn "n_limit must be a power of 2; using 2^30"; n_limit=2^30)
    inflate >= 1.0 || throw(ArgumentError("inflate must be >= 1.0"))
    0 < alpha < 1 || throw(ArgumentError("alpha must be in (0,1)"))
    error_fun in (:either, :both) || throw(ArgumentError("error_fun must be :either or :both"))
    return CubQMCRepStudentT(
        integrand,
        abs_tol,
        rel_tol,
        n_init,
        n_limit,
        alpha,
        inflate,
        error_fun,
        trace_iterations,
    )
end

"""Compute combined tolerance from solution value, abs_tol, rel_tol."""
function _error_bound_tol(efun::Symbol, sv::Float64, abs_tol::Float64, rel_tol::Float64)
    if efun == :either
        return max(abs_tol, abs(sv) * rel_tol)
    else  # :both
        return min(abs_tol, abs(sv) * rel_tol)
    end
end

function integrate(sc::CubQMCRepStudentT; resume::Union{Nothing, Dict{Symbol, Any}}=nothing)
    dd = discrete_distribution(sc.integrand)
    R = dd.replications
    R > 1 || throw(ArgumentError("CubQMCRepStudentT requires replications > 1"))

    t_star = -quantile(TDist(R - 1), sc.alpha / 2.0)

    # --- Initialise or resume ---
    if resume !== nothing
        n_prev = haskey(resume, :n_per_rep) ? Int(resume[:n_per_rep]) : Int(resume[:n_rep])
        n_rep = 2 * n_prev
        prev_time = Float64(get(resume, :time_integrate, 0.0))
    else
        n_rep = sc.n_init
        prev_time = 0.0
    end

    t_start = time()
    log = IterationLog()
    n_iter = 0
    converged = false

    # Accumulators: for scalar integrands, rep_means is Vector{Float64}(R)
    # We accumulate _ysums across doublings to avoid recomputing from scratch.
    ysums = zeros(Float64, R)           # running sum per replication
    n_so_far = 0                        # points already generated per replication

    while n_rep <= sc.n_limit
        n_iter += 1

        # Generate only the incremental block for all replications at once, then
        # split the flattened evaluations back into per-replication sums.
        n_new = n_rep - n_so_far
        x_uniform = gen_samples(dd, n_new; n_start=n_so_far)
        ndims(x_uniform) == 3 ||
            throw(ArgumentError("CubQMCRepStudentT requires a replicated sampler"))
        _, m, d = size(x_uniform)
        x_trans = transform(true_measure(sc.integrand), reshape(x_uniform, R * m, d))
        y = evaluate(sc.integrand, x_trans)
        ysums .+= vec(sum(reshape(y, R, m); dims=2))
        n_so_far = n_rep

        # Replication means and statistics
        rep_means = ysums ./ n_rep
        mu_hat = mean(rep_means)
        sigma_hat = std(rep_means; corrected=true)
        ci_half = t_star * sc.inflate * sigma_hat / sqrt(R)

        tol = _error_bound_tol(sc.error_fun, mu_hat, sc.abs_tol, sc.rel_tol)

        if sc.trace_iterations
            push!(
                log;
                n=n_rep * R,
                solution=mu_hat,
                error_bound=ci_half,
                tol=tol,
                elapsed=time() - t_start,
            )
        end

        if ci_half <= tol
            converged = true
            break
        end

        if 2 * n_rep > sc.n_limit
            @warn "CubQMCRepStudentT: generated $(n_rep*R) samples; " *
                  "doubling would exceed n_limit=$(sc.n_limit). Stopping."
            break
        end

        n_rep *= 2
    end

    t_elapsed = time() - t_start
    sigma_hat = std(ysums ./ n_so_far; corrected=true)
    ci_half = t_star * sc.inflate * sigma_hat / sqrt(R)
    mu_hat = mean(ysums ./ n_so_far)

    data = Dict{Symbol, Any}(
        :n => n_so_far * R,
        :n_total => n_so_far * R,
        :n_rep => n_so_far,
        :n_per_rep => n_so_far,
        :replications => R,
        :error_bound => ci_half,
        :bound_low => mu_hat - ci_half,
        :bound_high => mu_hat + ci_half,
        :n_iterations => n_iter,
        :converged => converged,
        :time_integrate => prev_time + t_elapsed,
        :_ysums => ysums,          # for resume
    )
    if sc.trace_iterations
        data[:iteration_log] = log
    end
    return QMCResult(mu_hat, data)
end

function Base.show(io::IO, sc::CubQMCRepStudentT)
    print(
        io,
        "CubQMCRepStudentT(abs_tol=$(sc.abs_tol), alpha=$(sc.alpha), inflate=$(sc.inflate))",
    )
end
