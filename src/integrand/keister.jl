"""
    Keister(tm::AbstractTrueMeasure)

Keister integrand: ``f(\\mathbf{x}) = \\pi^{d/2} \\cos(\\|\\mathbf{x}\\|)``

This is a classic QMC test function integrating over ℝᵈ with a Gaussian measure.
The true measure should be `Gaussian` with mean 0 and covariance I/2.

The exact integral value is:
``I = \\pi^{d/2} \\cdot \\frac{1}{(2\\pi)^{d/2}} \\int \\cos(\\|x\\|) e^{-\\|x\\|^2/2} dx``

# Examples
```jldoctest
julia> using QuasiMC, Statistics

julia> f = Keister(Gaussian(DigitalNetB2(2; seed=7); covariance=0.5))
Keister(d=2)

julia> y = sample_and_evaluate(f, 2^10);

julia> round(mean(y); digits=4)
1.806

julia> round(keister_exact(2); digits=4)
1.8082
```
"""
struct Keister{TM <: AbstractTrueMeasure} <: AbstractIntegrand
    true_measure::TM
    dimension::Int
end

Keister(tm::AbstractTrueMeasure) = Keister(tm, dimension(tm))

function evaluate(f::Keister, x::AbstractMatrix)
    _require_sample_dimension(f.dimension, x, nameof(typeof(f)))
    coeff = π^(f.dimension / 2)
    # sum(abs2, x; dims=2) sweeps column-by-column (cache-friendly for column-major
    # Julia arrays), avoiding row-stride cache misses in the original loop.
    norms = vec(sqrt.(sum(abs2, x; dims=2)))
    return @. coeff * cos(norms)
end

_supports_evaluate_into(::Keister) = true

function _evaluate_into!(f::Keister, x::AbstractMatrix, y::AbstractVector)
    n, d = size(x)
    coeff = π^(f.dimension / 2)
    fill!(y, 0.0)
    @inbounds for j in 1:d
        @simd for i in 1:n
            y[i] += x[i, j]^2
        end
    end
    @inbounds @simd for i in 1:n
        y[i] = coeff * cos(sqrt(y[i]))
    end
    return y
end

"""
    keister_exact(d::Int)

Compute the exact value of the Keister integral in `d` dimensions.

For the standard Keister setup used here, the true measure is `N(0, I/2)`, so

``I_d = \\int_{\\mathbb{R}^d} e^{-\\|x\\|^2} \\cos(\\|x\\|)\\,dx
     = \\pi^{d/2} \\, {}_1F_1\\!\\left(\\frac{d}{2}; \\frac{1}{2}; -\\frac{1}{4}\\right).``

The hypergeometric argument is small and fixed (`-1/4`), so a direct series is
simple and stable.
"""
function keister_exact(d::Int)
    d > 0 || throw(ArgumentError("dimension must be positive"))
    a = d / 2.0
    b = 0.5
    z = -0.25
    term = 1.0
    total = 1.0
    for k in 1:10_000
        term *= ((a + k - 1.0) / (b + k - 1.0)) * (z / k)
        total_new = total + term
        if abs(term) <= eps(Float64) * abs(total_new)
            return π^(d / 2) * total_new
        end
        total = total_new
    end
    error("keister_exact failed to converge for d=$d")
end

Base.show(io::IO, f::Keister) = print(io, "Keister(d=$(f.dimension))")
