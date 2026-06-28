"""
Periodization transforms for Bayesian QMC stopping criteria.

These transforms map a function on [0,1]^d to a periodic function,
which improves the convergence analysis for lattice and digital net rules.
"""

"""
    periodize(x::AbstractMatrix, ptransform::Symbol) -> AbstractMatrix

Apply a periodization transform to uniform samples `x` in [0,1)^d.
Returns transformed samples in [0,1)^d.

# Supported transforms
- `:C1SIN` — C¹ sinusoidal transform (default for lattice rules)
- `:C1` — C¹ polynomial transform
- `:C2SIN` — C² sinusoidal transform
- `:C3` — C³ polynomial transform
- `:BAKER` — Baker's (tent) transform
- `:NONE` — identity (no transform)

# Examples
```jldoctest
julia> using QuasiMC

julia> x = [0.25 0.5; 0.75 0.1];

julia> round.(periodize(x, :C1SIN); digits=6)
2×2 Matrix{Float64}:
 0.090845  0.5
 0.909155  0.006451

julia> periodize(x, :BAKER)
2×2 Matrix{Float64}:
 0.5  1.0
 0.5  0.2
```

```jldoctest
julia> using QuasiMC

julia> x = [0.25 0.5; 0.75 0.1];

julia> periodize(x, :NONE) == x
true

julia> all(0.0 .<= periodize(x, :C1) .<= 1.0)
true

julia> all(0.0 .<= periodize(x, :C2SIN) .<= 1.0)
true

julia> all(0.0 .<= periodize(x, :C3) .<= 1.0)
true
```
"""
function periodize(x::AbstractMatrix, ptransform::Symbol)
    if ptransform == :NONE || ptransform == :none
        return copy(x)
    elseif ptransform == :C1SIN
        return clamp.(_c1sin.(x), 0.0, 1.0)
    elseif ptransform == :C1
        return clamp.(_c1.(x), 0.0, 1.0)
    elseif ptransform == :C2SIN
        return clamp.(_c2sin.(x), 0.0, 1.0)
    elseif ptransform == :C3
        return clamp.(_c3.(x), 0.0, 1.0)
    elseif ptransform == :BAKER
        return clamp.(_baker.(x), 0.0, 1.0)
    else
        error(
            "Unknown periodization transform: :$ptransform. " *
            "Use :C1SIN, :C1, :C2SIN, :C3, :BAKER, or :NONE.",
        )
    end
end

"""
    _periodize_with_weight(x, ptransform) -> (x_periodized, weight)

Apply the periodization map and return the product Jacobian weight needed to
preserve the original integral. Baker's transform is measure-preserving as
implemented here, so its weight is identically one.
"""
function _periodize_with_weight(x::AbstractMatrix, ptransform::Symbol)
    xp = periodize(x, ptransform)
    n, d = size(x)
    w = ones(Float64, n)

    if ptransform == :NONE || ptransform == :none || ptransform == :BAKER
        return xp, w
    end

    deriv = if ptransform == :C1SIN
        _c1sin_deriv
    elseif ptransform == :C1
        _c1_deriv
    elseif ptransform == :C2SIN
        _c2sin_deriv
    elseif ptransform == :C3
        _c3_deriv
    else
        error(
            "Unknown periodization transform: :$ptransform. " *
            "Use :C1SIN, :C1, :C2SIN, :C3, :BAKER, or :NONE.",
        )
    end

    @inbounds for j in 1:d, i in 1:n
        w[i] *= deriv(x[i, j])
    end
    return xp, w
end

@inline _c1sin(x::Float64) = x - sin(2π * x) / (2π)
@inline _c1(x::Float64) = 3.0 * x^2 - 2.0 * x^3
@inline _c2sin(x::Float64) = x - sin(2π*x)/(2π) * (8.0/3.0) + sin(4π*x)/(4π) * (1.0/3.0)
@inline _c3(x::Float64) = x^3 * (10.0 - 15.0*x + 6.0*x^2)
@inline _baker(x::Float64) = 1.0 - abs(2.0*x - 1.0)
@inline _c1sin_deriv(x::Float64) = 1.0 - cos(2π * x)
@inline _c1_deriv(x::Float64) = 6.0 * x * (1.0 - x)
@inline _c2sin_deriv(x::Float64) = 1.0 - (8.0 / 3.0) * cos(2π * x) + (1.0 / 3.0) * cos(4π * x)
@inline _c3_deriv(x::Float64) = 30.0 * x^2 * (1.0 - x)^2
