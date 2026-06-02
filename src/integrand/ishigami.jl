"""
    Ishigami(tm::AbstractTrueMeasure; a=7.0, b=0.1)

Ishigami test function for sensitivity analysis:

    f(t₁, t₂, t₃) = sin(t₁) + a sin²(t₂) + b t₃⁴ sin(t₁)

where t ∈ U(-π, π)³.

The true measure should map uniform [0,1]³ samples to (-π, π)³.

# Exact Sobol' indices (known analytically)
The exact mean, variance, and Sobol' indices are computable in closed form
for given a, b.
"""
struct Ishigami <: AbstractIntegrand
    true_measure::AbstractTrueMeasure
    dimension::Int
    a::Float64
    b::Float64
end

function Ishigami(tm::AbstractTrueMeasure; a::Float64 = 7.0, b::Float64 = 0.1)
    tm.dimension >= 3 ||
        throw(ArgumentError("Ishigami requires dimension at least 3, got $(tm.dimension)"))
    return Ishigami(tm, 3, a, b)
end

function evaluate(f::Ishigami, x::AbstractMatrix)
    n = size(x, 1)
    a = f.a
    b = f.b
    y = Vector{Float64}(undef, n)
    @inbounds for i in 1:n
        t1 = x[i, 1]
        t2 = x[i, 2]
        t3 = x[i, 3]
        y[i] = sin(t1) + a * sin(t2)^2 + b * t3^4 * sin(t1)
    end
    return y
end

function Base.show(io::IO, f::Ishigami)
    print(io, "Ishigami(a=$(f.a), b=$(f.b))")
end
