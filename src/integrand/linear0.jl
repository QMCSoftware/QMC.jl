"""
    Linear0(tm::AbstractTrueMeasure)

Simple linear test function: f(t) = ∑ tⱼ  where t ∈ U[-0.5, 0.5]^d.

The true measure should map uniform samples to [-0.5, 0.5]^d (i.e., a
`Uniform` measure with `lower_bound=-0.5, upper_bound=0.5`).

Exact integral = 0 by symmetry.
"""
struct Linear0{TM <: AbstractTrueMeasure} <: AbstractIntegrand
    true_measure::TM
    dimension::Int
end

Linear0(tm::AbstractTrueMeasure) = Linear0(tm, tm.dimension)

function evaluate(f::Linear0, x::AbstractMatrix)
    n = size(x, 1)
    y = zeros(Float64, n)
    # Column-major accumulation: each column of `x` is contiguous in memory, so
    # this avoids the stride-n cache misses of a per-row inner loop at large d.
    # For each i the additions still occur in order j = 1:d, so the result is
    # identical to the row-major formulation.
    @inbounds for j in 1:f.dimension
        @simd for i in 1:n
            y[i] += x[i, j]
        end
    end
    return y
end

Base.show(io::IO, f::Linear0) = print(io, "Linear0(d=$(f.dimension))")
