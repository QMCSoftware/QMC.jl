"""
    Hartmann6D(tm::AbstractTrueMeasure)

6-dimensional Hartmann test function, commonly used as an optimization benchmark.

    f(x) = - ∑ᵢ₌₁⁴ αᵢ exp(- ∑ⱼ₌₁⁶ Aᵢⱼ (xⱼ - Pᵢⱼ)²)

where x ∈ [0,1]⁶. The global minimum is approximately -3.3224 at
x* ≈ (0.2017, 0.1500, 0.4769, 0.2753, 0.3117, 0.6573).
"""
struct Hartmann6D{TM <: AbstractTrueMeasure} <: AbstractIntegrand
    true_measure::TM
    dimension::Int
end

function Hartmann6D(tm::AbstractTrueMeasure)
    tm.dimension == 6 ||
        throw(ArgumentError("Hartmann6D requires dimension 6, got $(tm.dimension)"))
    return Hartmann6D(tm, 6)
end

const _HARTMANN_ALPHA = [1.0, 1.2, 3.0, 3.2]

const _HARTMANN_A = [
    10.0 3.0 17.0 3.5 1.7 8.0;
    0.05 10.0 17.0 0.1 8.0 14.0;
    3.0 3.5 1.7 10.0 17.0 8.0;
    17.0 8.0 0.05 10.0 0.1 14.0
]

const _HARTMANN_P = [
    0.1312 0.1696 0.5569 0.0124 0.8283 0.5886;
    0.2329 0.4135 0.8307 0.3736 0.1004 0.9991;
    0.2348 0.1451 0.3522 0.2883 0.3047 0.6650;
    0.4047 0.8828 0.8732 0.5743 0.1091 0.0381
]

function evaluate(f::Hartmann6D, x::AbstractMatrix)
    n = size(x, 1)
    s1 = zeros(Float64, n)
    s2 = zeros(Float64, n)
    s3 = zeros(Float64, n)
    s4 = zeros(Float64, n)
    # Julia matrices are column-major, so accumulate one coordinate at a time
    # rather than striding by `n` across a per-row inner loop.
    @inbounds for j in 1:6
        a1 = _HARTMANN_A[1, j]
        a2 = _HARTMANN_A[2, j]
        a3 = _HARTMANN_A[3, j]
        a4 = _HARTMANN_A[4, j]
        p1 = _HARTMANN_P[1, j]
        p2 = _HARTMANN_P[2, j]
        p3 = _HARTMANN_P[3, j]
        p4 = _HARTMANN_P[4, j]
        @simd for i in 1:n
            xij = x[i, j]
            s1[i] += a1 * (xij - p1)^2
            s2[i] += a2 * (xij - p2)^2
            s3[i] += a3 * (xij - p3)^2
            s4[i] += a4 * (xij - p4)^2
        end
    end
    y = Vector{Float64}(undef, n)
    @inbounds for i in 1:n
        y[i] = -(
            _HARTMANN_ALPHA[1] * exp(-s1[i]) +
            _HARTMANN_ALPHA[2] * exp(-s2[i]) +
            _HARTMANN_ALPHA[3] * exp(-s3[i]) +
            _HARTMANN_ALPHA[4] * exp(-s4[i])
        )
    end
    return y
end

Base.show(io::IO, f::Hartmann6D) = print(io, "Hartmann6D()")
