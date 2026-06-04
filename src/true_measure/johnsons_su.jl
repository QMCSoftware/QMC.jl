"""
    JohnsonsSU(dd; xi=0.0, lambda=1.0, gamma=0.0, delta=1.0)

Johnson's SU distribution measure via inverse CDF.

Transform:  z = ξ + λ sinh((Φ⁻¹(u) - γ) / δ)

where Φ⁻¹ is the standard normal quantile function.

# Arguments
- `dd`: discrete distribution.
- `xi`: location parameter ξ (scalar or d-vector).
- `lambda`: scale parameter λ > 0 (scalar or d-vector).
- `gamma`: shape parameter γ (scalar or d-vector).
- `delta`: shape parameter δ > 0 (scalar or d-vector).
"""
struct JohnsonsSU{D <: AbstractDiscreteDistribution} <: AbstractTrueMeasure
    dd::D
    dimension::Int
    xi::Vector{Float64}
    lambda::Vector{Float64}
    gamma::Vector{Float64}
    delta::Vector{Float64}
end

function JohnsonsSU(dd::AbstractDiscreteDistribution; xi=0.0, lambda=1.0, gamma=0.0, delta=1.0)
    d = dd.dimension
    _xi = xi isa Number ? fill(Float64(xi), d) : Float64.(collect(xi))
    _lam = lambda isa Number ? fill(Float64(lambda), d) : Float64.(collect(lambda))
    _gam = gamma isa Number ? fill(Float64(gamma), d) : Float64.(collect(gamma))
    _del = delta isa Number ? fill(Float64(delta), d) : Float64.(collect(delta))
    all(_lam .> 0) || throw(ArgumentError("lambda must be positive"))
    all(_del .> 0) || throw(ArgumentError("delta must be positive"))
    return JohnsonsSU(dd, d, _xi, _lam, _gam, _del)
end

function transform(tm::JohnsonsSU, x::AbstractMatrix)
    # Phi^-1(u) = sqrt(2) * erfinv(2u - 1): the same fast standard-normal quantile the Gaussian
    # transform uses, applied over the whole n x d input as a fused broadcast rather
    # than a per-element Distributions.quantile call. The Johnson S_u map
    # y = xi + lambda * sinh((Phi^-1(u) - gamma)/delta) is then broadcast column-wise
    # (parameters are 1 x d rows). Numerically equivalent to the scalar form.
    xi = transpose(tm.xi)
    lam = transpose(tm.lambda)
    gam = transpose(tm.gamma)
    del = transpose(tm.delta)
    z = @. sqrt(2.0) * SpecialFunctions.erfinv(2.0 * _open_unit_interval(x) - 1.0)
    return @. xi + lam * sinh((z - gam) / del)
end

Base.show(io::IO, tm::JohnsonsSU) = print(io, "JohnsonsSU(d=$(tm.dimension))")
