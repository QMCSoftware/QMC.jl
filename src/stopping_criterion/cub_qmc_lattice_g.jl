"""
    CubQMCLatticeG(integrand::AbstractIntegrand; abs_tol=0.01, rel_tol=0.0,
                   n_init=2^10, n_max=2^30, n_reps=16, alpha=0.01)

Guaranteed QMC cubature using replicated randomized lattice rules.

**Algorithm:**
1. For each of `R` replications, generate an independently shifted lattice of size `n`
2. Evaluate the integrand for each replication → `R` independent estimates ``\\hat{\\mu}_r``
3. Overall estimate: ``\\bar{\\mu} = \\mathrm{mean}(\\hat{\\mu}_r)``
4. Error bound: ``t_{R-1, 1-\\alpha/2} \\cdot \\mathrm{std}(\\hat{\\mu}_r) / \\sqrt{R}``
5. If error < tolerance, stop; otherwise double `n`

# Example
```julia
dd = Lattice(3; randomize=true)
tm = Uniform(dd)
f = Genz(tm; kind=:oscillatory)
sc = CubQMCLatticeG(f; abs_tol=1e-4)
result = integrate(sc)
```
"""
mutable struct CubQMCLatticeG <: AbstractStoppingCriterion
    integrand::AbstractIntegrand
    abs_tol::Float64
    rel_tol::Float64
    n_init::Int
    n_max::Int
    n_reps::Int
    alpha::Float64
end

function CubQMCLatticeG(integrand::AbstractIntegrand;
        abs_tol::Float64 = 0.01,
        rel_tol::Float64 = 0.0,
        n_init::Int = 2^10,
        n_max::Int = 2^30,
        n_reps::Int = 16,
        alpha::Float64 = 0.01)
    return CubQMCLatticeG(integrand, abs_tol, rel_tol, n_init, n_max, n_reps, alpha)
end

function integrate(sc::CubQMCLatticeG)
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

        # Double n
        n = min(2n, sc.n_max + 1)
    end

    converged = err <= max(sc.abs_tol, sc.rel_tol * abs(mu_hat))
    if !converged
        @warn "CubQMCLatticeG: did not converge within n_max=$(sc.n_max)."
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

function Base.show(io::IO, sc::CubQMCLatticeG)
    print(io, "CubQMCLatticeG(abs_tol=$(sc.abs_tol), n_reps=$(sc.n_reps))")
end
