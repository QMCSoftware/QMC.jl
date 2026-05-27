"""
    BoxIntegral(tm::AbstractTrueMeasure; s=2.0)

Box integral test function:  f(t) = (∑ tⱼ²)^(s/2)

where t ∈ [0,1]^d via a Uniform true measure.

The parameter `s` controls the singularity strength. For `s ≥ 0` the integrand
is smooth; for `s < 0` it has an integrable singularity at the origin.

The exact integral is known for certain values of s and d (see BoxIntegral
tables by Bailey, Borwein, and Crandall).
"""
struct BoxIntegral <: AbstractIntegrand
    true_measure::AbstractTrueMeasure
    dimension::Int
    s::Float64
end

function BoxIntegral(tm::AbstractTrueMeasure; s::Float64=2.0)
    return BoxIntegral(tm, tm.dimension, s)
end

function evaluate(f::BoxIntegral, x::AbstractMatrix)
    n, d = size(x)
    s_half = f.s / 2.0
    y = Vector{Float64}(undef, n)
    @inbounds for i in 1:n
        r2 = 0.0
        for j in 1:d
            r2 += x[i, j]^2
        end
        y[i] = r2 == 0.0 && s_half < 0.0 ? 0.0 : r2^s_half
    end
    return y
end

function Base.show(io::IO, f::BoxIntegral)
    print(io, "BoxIntegral(d=$(f.dimension), s=$(f.s))")
end
