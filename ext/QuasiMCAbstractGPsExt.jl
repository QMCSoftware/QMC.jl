"""
    QuasiMCAbstractGPsExt

Gaussian-process backend for [`QuasiMC.PFGPCI`](@ref), loaded automatically when
`AbstractGPs` and `Optim` are available. Provides methods for the
`QuasiMC._pfgpci_fit` / `QuasiMC._pfgpci_predict` contract: a zero-mean GP with a scaled
Matérn-5/2 kernel (ν = 2.5), hyperparameters fit by maximizing the log marginal
likelihood, used as an effectively interpolating surrogate (tiny fixed jitter).

Mirrors QMCPy's default `ScaleKernel(MaternKernel(nu=2.5))` with a near-zero
noise constraint. Hyperparameter optimization is numerical (Optim), so this
agrees with QMCPy's gpytorch/Adam fit only statistically, not bit-for-bit.
"""
module QuasiMCAbstractGPsExt

using QuasiMC
using AbstractGPs          # re-exports KernelFunctions (Matern52Kernel, with_lengthscale, RowVecs)
using Optim
using LinearAlgebra

# Effectively interpolating surrogate: tiny fixed observation noise standing in
# for QMCPy's GaussianLikelihood noise constraint Interval(1e-12, 1e-8).
const _PFGPCI_JITTER = 1e-8

# Zero-mean GP with a scaled Matérn-5/2 kernel parameterized in log-space:
# logθ = (log lengthscale, log signal-variance). Zero mean means the posterior
# reverts to the failure boundary (shifted target 0 ⇒ φ = 1/2, maximal
# uncertainty) away from data — the principled choice for failure estimation and
# what QMCPy uses.
function _build_gp(logθ)
    ℓ = exp(logθ[1])
    σ² = exp(logθ[2])
    kernel = σ² * with_lengthscale(Matern52Kernel(), ℓ)
    return GP(kernel)
end

# Negative log marginal likelihood of the training data under hyperparameters logθ.
function _nlml(logθ, X, y)
    f = _build_gp(logθ)
    fx = f(X, _PFGPCI_JITTER)
    return -logpdf(fx, y)
end

# Fitted-GP container returned to the criterion core.
struct PFGPCIModel{P}
    post::P
end

function QuasiMC._pfgpci_fit(x::AbstractMatrix, y::AbstractVector)
    X = RowVecs(Matrix{Float64}(x))
    yv = Vector{Float64}(y)
    logθ0 = [log(0.2), log(1.0)]   # lengthscale 0.2, unit signal variance
    res = Optim.optimize(θ -> _nlml(θ, X, yv), logθ0, Optim.NelderMead())
    f = _build_gp(Optim.minimizer(res))
    return PFGPCIModel(posterior(f(X, _PFGPCI_JITTER), yv))
end

function QuasiMC._pfgpci_predict(model::PFGPCIModel, xq::AbstractMatrix)
    Xq = RowVecs(Matrix{Float64}(xq))
    m, v = mean_and_var(model.post(Xq))
    return m, sqrt.(max.(v, 0.0))
end

end # module
