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

function Linear0(tm::AbstractTrueMeasure)
    return Linear0(tm, tm.dimension)
end

function evaluate(f::Linear0, x::AbstractMatrix)
    n = size(x, 1)
    y = Vector{Float64}(undef, n)
    @inbounds for i in 1:n
        s = 0.0
        for j in 1:f.dimension
            s += x[i, j]
        end
        y[i] = s
    end
    return y
end

function Base.show(io::IO, f::Linear0)
    print(io, "Linear0(d=$(f.dimension))")
end
