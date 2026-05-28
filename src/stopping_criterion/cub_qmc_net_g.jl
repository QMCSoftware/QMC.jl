"""
    CubQMCNetG(integrand::AbstractIntegrand; abs_tol=0.01, rel_tol=0.0,
               n_init=2^10, n_max=2^30, n_reps=16, alpha=0.01)

Guaranteed QMC cubature using replicated randomized digital nets (Sobol').

Same replicated-randomization approach as `CubQMCLatticeG` but expects the
underlying discrete distribution to be `DigitalNetB2`.

# Example
```julia
dd = DigitalNetB2(3; randomize="LMS_DS")
tm = Uniform(dd)
f = Genz(tm; kind=:gaussian_peak)
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
end

function CubQMCNetG(integrand::AbstractIntegrand;
        abs_tol::Float64 = 0.01,
        rel_tol::Float64 = 0.0,
        n_init::Int = 2^10,
        n_max::Int = 2^30,
        n_reps::Int = 16,
        alpha::Float64 = 0.01)
    return CubQMCNetG(integrand, abs_tol, rel_tol, n_init, n_max, n_reps, alpha)
end

function integrate(sc::CubQMCNetG)
    R = sc.n_reps
    n = sc.n_init
    t_crit = quantile(TDist(R - 1), 1.0 - sc.alpha / 2.0)
    mu_hat = 0.0
    err = Inf
    n_iter = 0

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

        if err <= tol
            break
        end

        # Double n (must stay power of 2 for digital nets)
        n = min(2n, sc.n_max + 1)
    end

    converged = err <= max(sc.abs_tol, sc.rel_tol * abs(mu_hat))
    if !converged
        @warn "CubQMCNetG: did not converge within n_max=$(sc.n_max)."
    end

    data = Dict{Symbol, Any}(
        :n => n,
        :n_reps => R,
        :error_bound => err,
        :n_iterations => n_iter,
        :converged => converged
    )
    return QMCResult(mu_hat, data)
end

function Base.show(io::IO, sc::CubQMCNetG)
    print(io, "CubQMCNetG(abs_tol=$(sc.abs_tol), n_reps=$(sc.n_reps))")
end
