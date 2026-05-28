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
struct JohnsonsSU <: AbstractTrueMeasure
    dd::AbstractDiscreteDistribution
    dimension::Int
    xi::Vector{Float64}
    lambda::Vector{Float64}
    gamma::Vector{Float64}
    delta::Vector{Float64}
end

function JohnsonsSU(dd::AbstractDiscreteDistribution;
        xi = 0.0, lambda = 1.0, gamma = 0.0, delta = 1.0)
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
    n, d = size(x)
    ndist = Distributions.Normal()
    y = Matrix{Float64}(undef, n, d)
    @inbounds for j in 1:d
        for i in 1:n
            z = quantile(ndist, x[i, j])
            y[i, j] = tm.xi[j] + tm.lambda[j] * sinh((z - tm.gamma[j]) / tm.delta[j])
        end
    end
    return y
end

function Base.show(io::IO, tm::JohnsonsSU)
    print(io, "JohnsonsSU(d=$(tm.dimension))")
end
