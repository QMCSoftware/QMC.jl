"""
    Kumaraswamy(dd; alpha=2.0, beta=2.0)

Kumaraswamy distribution measure via inverse CDF.

    F⁻¹(u) = (1 - (1 - u)^(1/β))^(1/α)

This distribution is similar to the Beta distribution but has a closed-form
inverse CDF, making it efficient for QMC.

# Arguments
- `dd`: discrete distribution.
- `alpha`: shape parameter α > 0 (scalar or d-vector). Default `2.0`.
- `beta`: shape parameter β > 0 (scalar or d-vector). Default `2.0` (matches
  QMC v2.3's `a=2, b=2`; QMC.jl's `alpha`/`beta` correspond to QMCPy's `a`/`b`).

# Examples
```jldoctest
julia> using QMC

julia> dd = DigitalNetB2(2; seed=7);

julia> tm = Kumaraswamy(dd; alpha=[1.0, 2.0], beta=[3.0, 4.0])
Kumaraswamy(d=2, α=[1.0, 2.0], β=[3.0, 4.0])

julia> round.(transform(tm, gen_samples(dd, 4)); digits=6)
4×2 Matrix{Float64}:
 0.466607  0.322069
 0.132982  0.61855
 0.262118  0.165141
 0.033884  0.455058
```
"""
struct Kumaraswamy{D <: AbstractDiscreteDistribution} <: AbstractTrueMeasure
    dd::D
    dimension::Int
    alpha::Vector{Float64}
    beta::Vector{Float64}
end

function Kumaraswamy(dd::AbstractDiscreteDistribution; alpha=2.0, beta=2.0)
    d = dimension(dd)
    a = alpha isa Number ? fill(Float64(alpha), d) : Float64.(collect(alpha))
    b = beta isa Number ? fill(Float64(beta), d) : Float64.(collect(beta))
    all(a .> 0) || throw(ArgumentError("alpha must be positive"))
    all(b .> 0) || throw(ArgumentError("beta must be positive"))
    return Kumaraswamy(dd, d, a, b)
end

function transform(tm::Kumaraswamy, x::AbstractMatrix)
    n, d = size(x)
    y = Matrix{Float64}(undef, n, d)
    @inbounds for j in 1:d
        inv_beta = 1.0 / tm.beta[j]
        inv_alpha = 1.0 / tm.alpha[j]
        for i in 1:n
            y[i, j] = (1.0 - (1.0 - x[i, j])^inv_beta)^inv_alpha
        end
    end
    return y
end

function Base.show(io::IO, tm::Kumaraswamy)
    print(io, "Kumaraswamy(d=$(tm.dimension), α=$(tm.alpha), β=$(tm.beta))")
end
