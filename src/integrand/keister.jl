"""
    Keister(tm::AbstractTrueMeasure)

Keister integrand: ``f(\\mathbf{x}) = \\pi^{d/2} \\cos(\\|\\mathbf{x}\\|)``

This is a classic QMC test function integrating over ℝᵈ with a Gaussian measure.
The true measure should be `Gaussian` with mean 0 and covariance I/2.

The exact integral value is:
``I = \\pi^{d/2} \\cdot \\frac{1}{(2\\pi)^{d/2}} \\int \\cos(\\|x\\|) e^{-\\|x\\|^2/2} dx``

# Example
```julia
dd = Lattice(3; randomize=true)
tm = Gaussian(dd; covariance=0.5)
f = Keister(tm)
```
"""
struct Keister{TM <: AbstractTrueMeasure} <: AbstractIntegrand
    true_measure::TM
    dimension::Int
end

function Keister(tm::AbstractTrueMeasure)
    return Keister(tm, tm.dimension)
end

function evaluate(f::Keister, x::AbstractMatrix)
    n, d = size(x)
    y = Vector{Float64}(undef, n)
    coeff = π^(d / 2)
    @inbounds for i in 1:n
        norm_xi = sqrt(sum(x[i, j]^2 for j in 1:d))
        y[i] = coeff * cos(norm_xi)
    end
    return y
end

"""
    keister_exact(d::Int)

Compute the exact value of the Keister integral in `d` dimensions.
Uses the formula involving the modified Bessel function of the first kind.

``I_d = \\pi^{d/2} \\cdot 2^{1-d/2} \\cdot e^{-1/2} \\cdot I_{d/2-1}(1/2)``

where ``I_\\nu`` is the modified Bessel function (besselI).
For d=1: I₁ ≈ 1.3803884470431430
"""
function keister_exact(d::Int)
    nu = d / 2.0 - 1.0
    # The exact integral for Keister with covariance I/2:
    # π^(d/2) * (2π)^(-d/2) * ∫ cos(||x||) * exp(-||x||^2/2) dx
    # = exp(-1/2) * besseli(nu, 1/2) * 2^(1 - d/2) * π^(d/2)
    # Simplified using the known closed form:
    val = π^(d / 2) * exp(-0.5)
    if d == 1
        val *= besseli(nu, 0.5) * sqrt(2)
    else
        val *= besseli(nu, 0.5) * 2.0^(1.0 - d / 2.0)
    end
    return val
end

function Base.show(io::IO, f::Keister)
    print(io, "Keister(d=$(f.dimension))")
end
