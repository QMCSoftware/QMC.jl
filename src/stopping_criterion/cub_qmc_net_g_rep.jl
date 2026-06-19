"""
    CubQMCNetGRep(integrand; abs_tol=0.01, rel_tol=0.0,
                  n_init=2^10, n_max=2^30, n_reps=16, alpha=0.01,
                  trace_iterations=false)

Guaranteed QMC cubature using replicated randomized digital nets.

This is Julia's replicated companion to the single-net [`CubQMCNetG`](@ref).
It estimates the mean from `n_reps` independently randomized digital nets and
uses a Student's t half-width across the replication means as its stopping rule.

Supports **resume** and optional **iteration logging** (`trace_iterations=true`).

# Examples
```jldoctest
julia> using QMC

julia> f = Genz(Uniform(DigitalNetB2(2; randomize="DS", seed=700)); kind=:gaussian_peak, a=[1.0, 1.0], u=[0.5, 0.5])
Genz(:gaussian_peak, d=2)

julia> sc = CubQMCNetGRep(f; abs_tol=0.1, n_init=2^10, n_reps=16)
CubQMCNetGRep(abs_tol=0.1, n_reps=16)

julia> result = integrate(sc);

julia> abs(result.solution - genz_exact(f)) < 0.05
true

julia> result.data[:n_total] > 0
true
```
"""
mutable struct CubQMCNetGRep{I <: AbstractIntegrand} <: AbstractStoppingCriterion
    integrand::I
    abs_tol::Float64
    rel_tol::Float64
    n_init::Int
    n_max::Int
    n_reps::Int
    alpha::Float64
    trace_iterations::Bool
end

function CubQMCNetGRep(
    integrand::AbstractIntegrand;
    abs_tol::Float64=0.01,
    rel_tol::Float64=0.0,
    n_init::Int=2^10,
    n_max::Int=2^30,
    n_reps::Int=16,
    alpha::Float64=0.01,
    trace_iterations::Bool=false,
)
    return CubQMCNetGRep(
        integrand,
        abs_tol,
        rel_tol,
        n_init,
        n_max,
        n_reps,
        alpha,
        trace_iterations,
    )
end

function integrate(sc::CubQMCNetGRep; resume::Union{Nothing, Dict{Symbol, Any}}=nothing)
    R = sc.n_reps
    t_crit = quantile(TDist(R - 1), 1.0 - sc.alpha / 2.0)

    if resume !== nothing
        n_prev = haskey(resume, :n_per_rep) ? Int(resume[:n_per_rep]) : Int(resume[:n])
        n = 2 * n_prev
        prev_time = Float64(get(resume, :time_integrate, 0.0))
    else
        n = sc.n_init
        prev_time = 0.0
    end

    t_start = time()
    mu_hat = 0.0
    err = Inf
    n_iter = 0
    log = IterationLog()
    f = sc.integrand
    dd = discrete_distribution(f)
    tm = true_measure(f)
    estimates = Vector{Float64}(undef, R)

    while n <= sc.n_max
        n_iter += 1

        # Step 1: generate all R sample matrices sequentially.
        # gen_samples advances dd.rng on each call, so this must stay serial.
        samples = Vector{Matrix{Float64}}(undef, R)
        for r in 1:R
            xu = gen_samples(dd, n)
            samples[r] =
                ndims(xu) == 3 ? reshape(xu, size(xu, 1) * size(xu, 2), size(xu, 3)) : xu
        end

        # Step 2: transform + evaluate, parallelised over replicates when nthreads > 1.
        # With nthreads == 1 Threads.@threads is a plain for loop — no overhead.
        # tm and f are read-only; each replicate owns its sample matrix → thread-safe.
        # Callers running with multiple Julia threads must call BLAS.set_num_threads(1)
        # once at process startup (before any Julia threads are live); toggling the BLAS
        # thread count while threads are active is not thread-safe and crashes OpenBLAS.
        Threads.@threads for r in 1:R
            y = evaluate(f, transform(tm, samples[r]))
            @inbounds estimates[r] = mean(y)
        end

        mu_hat = mean(estimates)
        sigma_reps = std(estimates; corrected=true)
        err = t_crit * sigma_reps / sqrt(R)
        tol = max(sc.abs_tol, sc.rel_tol * abs(mu_hat))

        if sc.trace_iterations
            push!(
                log;
                n=n*R,
                solution=mu_hat,
                error_bound=err,
                tol=tol,
                elapsed=time() - t_start,
            )
        end

        err <= tol && break
        n = min(2n, sc.n_max + 1)
    end

    converged = err <= max(sc.abs_tol, sc.rel_tol * abs(mu_hat))
    if !converged
        @warn "CubQMCNetGRep: did not converge within n_max=$(sc.n_max)."
    end

    t_elapsed = time() - t_start
    n_per_rep = n > sc.n_max ? sc.n_max : n
    data = Dict{Symbol, Any}(
        :n => n_per_rep,
        :n_per_rep => n_per_rep,
        :n_total => n_per_rep * R,
        :n_reps => R,
        :error_bound => err,
        :n_iterations => n_iter,
        :converged => converged,
        :time_integrate => prev_time + t_elapsed,
    )
    if sc.trace_iterations
        data[:iteration_log] = log
    end
    return QMCResult(mu_hat, data)
end

function Base.show(io::IO, sc::CubQMCNetGRep)
    print(io, "CubQMCNetGRep(abs_tol=$(sc.abs_tol), n_reps=$(sc.n_reps))")
end
