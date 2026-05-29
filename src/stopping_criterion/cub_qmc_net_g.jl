"""
    CubQMCNetG(integrand; abs_tol=0.01, rel_tol=0.0,
               n_init=2^10, n_max=2^30, n_reps=16, alpha=0.01,
               trace_iterations=false)

Guaranteed QMC cubature using replicated randomized digital nets.

Supports **resume** and optional **iteration logging** (`trace_iterations=true`).

# Example
```julia
dd = DigitalNetB2(3; randomize="LMS_DS")
tm = Uniform(dd)
f = Genz(tm; kind=:oscillatory)
sc = CubQMCNetG(f; abs_tol=1e-4)
result = integrate(sc)
```
"""
mutable struct CubQMCNetG <: AbstractStoppingCriterion
    integrand::AbstractIntegrand
    abs_tol::Float64
    rel_tol::Float64
    n_init::Int
    n_max::Int
    n_reps::Int
    alpha::Float64
    trace_iterations::Bool
end

function CubQMCNetG(integrand::AbstractIntegrand;
    abs_tol::Float64 = 0.01,
    rel_tol::Float64 = 0.0,
    n_init::Int = 2^10,
    n_max::Int = 2^30,
    n_reps::Int = 16,
    alpha::Float64 = 0.01,
    trace_iterations::Bool = false)
    return CubQMCNetG(
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

function integrate(sc::CubQMCNetG; resume::Union{Nothing, Dict{Symbol, Any}} = nothing)
    R = sc.n_reps
    t_crit = quantile(TDist(R - 1), 1.0 - sc.alpha / 2.0)

    if resume !== nothing
        n = 2 * Int(resume[:n])
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

    while n <= sc.n_max
        n_iter += 1
        estimates = Vector{Float64}(undef, R)

        for r in 1:R
            y = sample_and_evaluate(sc.integrand, n)
            estimates[r] = mean(y)
        end

        mu_hat = mean(estimates)
        sigma_reps = std(estimates; corrected = true)
        err = t_crit * sigma_reps / sqrt(R)
        tol = max(sc.abs_tol, sc.rel_tol * abs(mu_hat))

        if sc.trace_iterations
            push!(log; n = n*R, solution = mu_hat, error_bound = err,
                tol = tol, elapsed = time() - t_start)
        end

        err <= tol && break
        n = min(2n, sc.n_max + 1)
    end

    converged = err <= max(sc.abs_tol, sc.rel_tol * abs(mu_hat))
    if !converged
        @warn "CubQMCNetG: did not converge within n_max=$(sc.n_max)."
    end

    t_elapsed = time() - t_start
    data = Dict{Symbol, Any}(
        :n => n > sc.n_max ? sc.n_max : n,
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

function Base.show(io::IO, sc::CubQMCNetG)
    print(io, "CubQMCNetG(abs_tol=$(sc.abs_tol), n_reps=$(sc.n_reps))")
end
