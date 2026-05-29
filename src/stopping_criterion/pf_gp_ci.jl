"""
    PFGPCI

Probability of Failure estimation using adaptive Gaussian Process
construction and credible intervals.

!!! warning "Not yet implemented"
    This stopping criterion requires a GP regression backend (GPyTorch/PyTorch
    in the Python version).  A full Julia translation would need
    [AbstractGPs.jl](https://github.com/JuliaGaussianProcesses/AbstractGPs.jl)
    or a similar package.  This file provides the struct definition and a
    descriptive error so that code referencing `PFGPCI` will load but
    `integrate` will fail with a clear message.

# Python reference
`qmcpy.stopping_criterion.pf_gp_ci.PFGPCI` — 741 lines, depends on
`gpytorch`, `torch`, `scipy.stats.norm`.

# References
1. Sorokin, Aleksei G., and Vishwas Rao. "Credible Intervals for Probability
   of Failure with Gaussian Processes." arXiv:2311.07733 (2023).
"""
struct PFGPCI <: AbstractStoppingCriterion
    integrand::AbstractIntegrand
    failure_threshold::Float64
    failure_above_threshold::Bool
    abs_tol::Float64
    alpha::Float64
    n_init::Int
    n_limit::Int
    n_batch::Int
    n_approx::Int
end

function PFGPCI(integrand::AbstractIntegrand;
        failure_threshold::Float64 = 0.0,
        failure_above_threshold::Bool = true,
        abs_tol::Float64 = 5e-3,
        alpha::Float64 = 0.01,
        n_init::Int = 64,
        n_limit::Int = 1000,
        n_batch::Int = 4,
        n_approx::Int = 2^20)
    return PFGPCI(integrand, failure_threshold, failure_above_threshold,
                  abs_tol, alpha, n_init, n_limit, n_batch, n_approx)
end

function integrate(sc::PFGPCI; kwargs...)
    error(
        "PFGPCI is not yet implemented in QMC.jl. " *
        "The Python version requires GPyTorch/PyTorch for Gaussian process " *
        "regression.  A Julia port would need AbstractGPs.jl or similar. " *
        "Contributions welcome — see the Python source in " *
        "qmcpy/stopping_criterion/pf_gp_ci.py (741 lines)."
    )
end

function Base.show(io::IO, sc::PFGPCI)
    print(io, "PFGPCI(abs_tol=$(sc.abs_tol), n_limit=$(sc.n_limit)) [stub — not yet implemented]")
end
