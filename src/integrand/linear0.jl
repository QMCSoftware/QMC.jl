"""
    Linear0(tm::AbstractTrueMeasure)

Simple linear test function: f(t) = ∑ tⱼ  where t ∈ U[-0.5, 0.5]^d.

The true measure should map uniform samples to [-0.5, 0.5]^d (i.e., a
`Uniform` measure with `lower_bound=-0.5, upper_bound=0.5`).

Exact integral = 0 by symmetry.

# Examples
```jldoctest
julia> using QMC, Statistics

julia> f = Linear0(Uniform(DigitalNetB2(100; seed=7); lower_bound=-0.5, upper_bound=0.5))
Linear0(d=100)

julia> y = sample_and_evaluate(f, 2^10);

julia> round(mean(y); sigdigits=5)
-0.0031028
```
"""
struct Linear0{TM <: AbstractTrueMeasure} <: AbstractIntegrand
    true_measure::TM
    dimension::Int
end

Linear0(tm::AbstractTrueMeasure) = Linear0(tm, tm.dimension)

function evaluate(f::Linear0, x::AbstractMatrix)
    n = size(x, 1)
    y = zeros(Float64, n)
    # Julia stores matrices in column-major order, so a loop nest like
    # `for i in 1:n; for j in 1:d; x[i, j] end end` strides by `n` in the inner
    # loop and starts thrashing cache at large `d`. Swapping the loop nest to
    # `j` outer / `i` inner reads each column contiguously while accumulating
    # into a length-`n` vector. For each row `i`, the additions still happen in
    # order `j = 1:d`, so the result matches the original formulation.
    @inbounds for j in 1:f.dimension
        @simd for i in 1:n
            y[i] += x[i, j]
        end
    end
    return y
end

Base.show(io::IO, f::Linear0) = print(io, "Linear0(d=$(f.dimension))")
