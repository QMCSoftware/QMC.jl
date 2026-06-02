"""
    Sin1D(tm::AbstractTrueMeasure; k=1)

One-dimensional sinusoidal test function: f(t) = sin(t) on U[0, 2πk].

The true measure should map uniform [0,1] samples to [0, 2πk].
Exact integral = 0 for integer k.
"""
struct Sin1D{TM <: AbstractTrueMeasure} <: AbstractIntegrand
    true_measure::TM
    dimension::Int
    k::Int
end

function Sin1D(tm::AbstractTrueMeasure; k::Int = 1)
    tm.dimension == 1 ||
        throw(ArgumentError("Sin1D requires dimension 1, got $(tm.dimension)"))
    k > 0 || throw(ArgumentError("k must be positive"))
    return Sin1D(tm, 1, k)
end

function evaluate(f::Sin1D, x::AbstractMatrix)
    n = size(x, 1)
    y = Vector{Float64}(undef, n)
    @inbounds for i in 1:n
        y[i] = sin(x[i, 1])
    end
    return y
end

function Base.show(io::IO, f::Sin1D)
    print(io, "Sin1D(k=$(f.k))")
end
