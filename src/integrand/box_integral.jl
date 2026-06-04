"""
    BoxIntegral(tm::AbstractTrueMeasure; s=2.0)

Box integral test function:  f(t) = (∑ tⱼ²)^(s/2)

where t ∈ [0,1]^d via a Uniform true measure.

The parameter `s` controls the singularity strength. For `s ≥ 0` the integrand
is smooth; for `s < 0` it has an integrable singularity at the origin.

The exact integral is known for certain values of s and d (see BoxIntegral
tables by Bailey, Borwein, and Crandall).
"""
struct BoxIntegral{TM <: AbstractTrueMeasure} <: AbstractIntegrand
    true_measure::TM
    dimension::Int
    s::Float64
end

BoxIntegral(tm::AbstractTrueMeasure; s::Float64=2.0) = BoxIntegral(tm, tm.dimension, s)

function evaluate(f::BoxIntegral, x::AbstractMatrix)
    n, d = size(x)
    s_half = f.s / 2.0
    # Column-major accumulation of the squared radius (contiguous reads, no
    # stride-n cache misses at large d); per-row summation order is unchanged.
    r2 = zeros(Float64, n)
    @inbounds for j in 1:d
        @simd for i in 1:n
            r2[i] += x[i, j]^2
        end
    end
    y = Vector{Float64}(undef, n)
    @inbounds for i in 1:n
        y[i] = r2[i] == 0.0 && s_half < 0.0 ? 0.0 : r2[i]^s_half
    end
    return y
end

Base.show(io::IO, f::BoxIntegral) = print(io, "BoxIntegral(d=$(f.dimension), s=$(f.s))")
