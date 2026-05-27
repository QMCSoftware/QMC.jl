"""
    Hartmann6D(tm::AbstractTrueMeasure)

6-dimensional Hartmann test function, commonly used as an optimization benchmark.

    f(x) = - ∑ᵢ₌₁⁴ αᵢ exp(- ∑ⱼ₌₁⁶ Aᵢⱼ (xⱼ - Pᵢⱼ)²)

where x ∈ [0,1]⁶. The global minimum is approximately -3.3224 at
x* ≈ (0.2017, 0.1500, 0.4769, 0.2753, 0.3117, 0.6573).
"""
struct Hartmann6D <: AbstractIntegrand
    true_measure::AbstractTrueMeasure
    dimension::Int
end

function Hartmann6D(tm::AbstractTrueMeasure)
    tm.dimension == 6 || throw(ArgumentError("Hartmann6D requires dimension 6, got $(tm.dimension)"))
    return Hartmann6D(tm, 6)
end

const _HARTMANN_ALPHA = [1.0, 1.2, 3.0, 3.2]

const _HARTMANN_A = [
    10.0  3.0  17.0  3.5  1.7  8.0;
     0.05 10.0 17.0  0.1  8.0 14.0;
     3.0  3.5  1.7  10.0 17.0  8.0;
    17.0  8.0  0.05 10.0  0.1 14.0
]

const _HARTMANN_P = [
    0.1312 0.1696 0.5569 0.0124 0.8283 0.5886;
    0.2329 0.4135 0.8307 0.3736 0.1004 0.9991;
    0.2348 0.1451 0.3522 0.2883 0.3047 0.6650;
    0.4047 0.8828 0.8732 0.5743 0.1091 0.0381
]

function evaluate(f::Hartmann6D, x::AbstractMatrix)
    n = size(x, 1)
    y = Vector{Float64}(undef, n)
    @inbounds for i in 1:n
        val = 0.0
        for k in 1:4
            inner = 0.0
            for j in 1:6
                inner += _HARTMANN_A[k, j] * (x[i, j] - _HARTMANN_P[k, j])^2
            end
            val -= _HARTMANN_ALPHA[k] * exp(-inner)
        end
        y[i] = val
    end
    return y
end

function Base.show(io::IO, f::Hartmann6D)
    print(io, "Hartmann6D()")
end
