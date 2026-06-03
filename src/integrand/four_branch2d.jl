"""
    FourBranch2D(tm::AbstractTrueMeasure; k=6.0)

Four-branch series system reliability function in 2D:

    f(x₁, x₂) = min(
        k + x₁ + x₂,
        k - x₁ + x₂,
        k + x₁ - x₂,
        k - x₁ - x₂
    ) / k

where x ∈ ℝ² (typically from a standard Gaussian measure). The failure
region is defined by f(x) ≤ 0. This is a standard benchmark in structural
reliability analysis.

The true measure should be a `Gaussian` with mean 0 and appropriate covariance.
"""
struct FourBranch2D{TM <: AbstractTrueMeasure} <: AbstractIntegrand
    true_measure::TM
    dimension::Int
    k::Float64
end

function FourBranch2D(tm::AbstractTrueMeasure; k::Float64 = 6.0)
    tm.dimension == 2 ||
        throw(ArgumentError("FourBranch2D requires dimension 2, got $(tm.dimension)"))
    return FourBranch2D(tm, 2, k)
end

function evaluate(f::FourBranch2D, x::AbstractMatrix)
    n = size(x, 1)
    k = f.k
    y = Vector{Float64}(undef, n)
    @inbounds for i in 1:n
        x1 = x[i, 1]
        x2 = x[i, 2]
        y[i] = min(k + x1 + x2, k - x1 + x2, k + x1 - x2, k - x1 - x2) / k
    end
    return y
end

function Base.show(io::IO, f::FourBranch2D)
    print(io, "FourBranch2D(k=$(f.k))")
end
