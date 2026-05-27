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
        error("Unknown periodization transform: :$ptransform. " *
              "Use :C1SIN, :C1, :C2SIN, :C3, :BAKER, or :NONE.")
    end
end

@inline _c1sin(x::Float64) = x - sin(2π * x) / (2π)
@inline _c1(x::Float64) = 3.0 * x^2 - 2.0 * x^3
@inline _c2sin(x::Float64) = x - sin(2π*x)/(2π) * (8.0/3.0) + sin(4π*x)/(4π) * (1.0/3.0)
@inline _c3(x::Float64) = x^3 * (10.0 - 15.0*x + 6.0*x^2)
@inline _baker(x::Float64) = 1.0 - abs(2.0*x - 1.0)
