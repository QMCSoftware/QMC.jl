"""
    Multimodal2D(tm::AbstractTrueMeasure)

2-dimensional multimodal test function with multiple peaks:

    f(x₁, x₂) = ∑ᵢ₌₁⁵ hᵢ exp(-aᵢ((x₁-cᵢ)² + (x₂-dᵢ)²))

where x ∈ [0,1]². This is useful for testing QMC on functions with
multiple local features.

# Examples
```jldoctest
julia> using QMC

julia> dd = DigitalNetB2(2; seed=7);

julia> f = Multimodal2D(Uniform(dd))
Multimodal2D()

julia> round.(sample_and_evaluate(f, 4); digits=6)
4-element Vector{Float64}:
 0.29559
 0.677029
 0.047796
 0.00069
```
"""
struct Multimodal2D{TM <: AbstractTrueMeasure} <: AbstractIntegrand
    true_measure::TM
    dimension::Int
end

function Multimodal2D(tm::AbstractTrueMeasure)
    tm.dimension == 2 ||
        throw(ArgumentError("Multimodal2D requires dimension 2, got $(tm.dimension)"))
    return Multimodal2D(tm, 2)
end

# Five peaks with heights h, widths 1/sqrt(a), centered at (c, d)
const _MM2D_H = [1.0, 1.5, 2.0, 1.0, 0.8]
const _MM2D_A = [80.0, 60.0, 75.0, 100.0, 90.0]
const _MM2D_C = [0.2, 0.5, 0.8, 0.3, 0.7]
const _MM2D_D = [0.3, 0.7, 0.2, 0.8, 0.5]

function evaluate(f::Multimodal2D, x::AbstractMatrix)
    n = size(x, 1)
    y = Vector{Float64}(undef, n)
    @inbounds for i in 1:n
        val = 0.0
        x1 = x[i, 1]
        x2 = x[i, 2]
        for k in 1:5
            val += _MM2D_H[k] * exp(-_MM2D_A[k] * ((x1 - _MM2D_C[k])^2 + (x2 - _MM2D_D[k])^2))
        end
        y[i] = val
    end
    return y
end

Base.show(io::IO, f::Multimodal2D) = print(io, "Multimodal2D()")
