"""
    MaternGP(dd; nu=2.5, lengthscale=1.0, variance=1.0)

Gaussian Process prior with Matérn covariance kernel as a true measure.

Transforms uniform samples to GP sample paths via the Cholesky decomposition
of the Matérn covariance matrix evaluated at equally-spaced points.

The Matérn covariance function is:
  k(r) = σ² · 2^{1-ν}/Γ(ν) · (√(2ν)·r/ℓ)^ν · K_ν(√(2ν)·r/ℓ)

Common special cases: ν=0.5 (exponential), ν=1.5, ν=2.5, ν→∞ (Gaussian/RBF).

# Examples
```jldoctest
julia> using QMC

julia> tm = MaternGP(IIDStdUniform(5; seed=7); nu=2.5, lengthscale=0.3)
MaternGP(ν=2.5, ℓ=0.3, σ²=1.0)

julia> round.(transform(tm, gen_samples(tm.dd, 2)); digits=6)
2×5 Matrix{Float64}:
 0.256291  0.610101  0.515407  -0.727085  -0.852017
 1.58433   0.438711  0.175567  -0.13253   -0.394796
```
"""
struct MaternGP{D <: AbstractDiscreteDistribution, M <: AbstractMatrix{Float64}} <:
       AbstractTrueMeasure
    dd::D
    nu::Float64
    lengthscale::Float64
    variance::Float64
    chol_L::LowerTriangular{Float64, M}
end

function MaternGP(
    dd::AbstractDiscreteDistribution;
    nu::Float64=2.5,
    lengthscale::Float64=1.0,
    variance::Float64=1.0,
)
    nu > 0 || throw(ArgumentError("nu must be > 0"))
    lengthscale > 0 || throw(ArgumentError("lengthscale must be > 0"))
    variance > 0 || throw(ArgumentError("variance must be > 0"))

    d = dimension(dd)
    # Build covariance matrix at equally spaced points on [0, 1]
    t = range(0.0, 1.0, length=d)
    K = Matrix{Float64}(undef, d, d)
    for i in 1:d, j in 1:d
        K[i, j] = _matern_cov(abs(t[i] - t[j]), nu, lengthscale, variance)
    end
    # Add nugget for numerical stability
    K += 1e-10 * I

    L = cholesky(Symmetric(K)).L
    return MaternGP(dd, nu, lengthscale, variance, L)
end

function _matern_cov(r::Float64, nu::Float64, ℓ::Float64, σ²::Float64)
    if r < 1e-15
        return σ²
    end
    z = sqrt(2nu) * r / ℓ
    if nu == 0.5
        return σ² * exp(-z)
    elseif nu == 1.5
        return σ² * (1 + z) * exp(-z)
    elseif nu == 2.5
        return σ² * (1 + z + z^2 / 3) * exp(-z)
    else
        # General case via Bessel function
        coeff = σ² * 2^(1 - nu) / gamma(nu)
        return coeff * z^nu * besselk(nu, z)
    end
end

function transform(tm::MaternGP, x::AbstractMatrix)
    # x is n × d uniform samples; transform to normal then apply Cholesky
    z = quantile.(Normal(), clamp.(x, 1e-10, 1 - 1e-10))
    return z * tm.chol_L'  # n × d GP sample paths
end

function Base.show(io::IO, tm::MaternGP)
    print(io, "MaternGP(ν=$(tm.nu), ℓ=$(tm.lengthscale), σ²=$(tm.variance))")
end
