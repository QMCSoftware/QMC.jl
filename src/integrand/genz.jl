"""
    Genz(tm::AbstractTrueMeasure; kind=:oscillatory, a=nothing, u=nothing)

Genz test integrand family — six standard test functions for numerical integration.

# Variants (selected by `kind`):
- `:oscillatory`   — ``\\cos(2\\pi u_1 + \\sum a_i x_i)``
- `:product_peak`  — ``\\prod 1/(a_i^{-2} + (x_i - u_i)^2)``
- `:corner_peak`   — ``(1 + \\sum a_i x_i)^{-(d+1)}``
- `:gaussian_peak` — ``\\exp(-\\sum a_i^2 (x_i - u_i)^2)``
- `:continuous`    — ``\\exp(-\\sum a_i |x_i - u_i|)``
- `:discontinuous` — ``0`` if any ``x_i > u_i``, else ``\\exp(\\sum a_i x_i)``

Default parameters: ``a = \\mathbf{1}``, ``u = 0.5 \\cdot \\mathbf{1}``.

# Example
```julia
dd = Lattice(3; randomize=true)
tm = Uniform(dd)
f = Genz(tm; kind=:oscillatory)
```
"""
struct Genz{TM <: AbstractTrueMeasure} <: AbstractIntegrand
    true_measure::TM
    dimension::Int
    kind::Symbol
    a::Vector{Float64}
    u::Vector{Float64}
end

const GENZ_KINDS = (:oscillatory, :product_peak, :corner_peak,
    :gaussian_peak, :continuous, :discontinuous)

function Genz(tm::AbstractTrueMeasure;
    kind::Symbol = :oscillatory,
    a::Union{Nothing, Vector{Float64}} = nothing,
    u::Union{Nothing, Vector{Float64}} = nothing)
    @assert kind in GENZ_KINDS "kind must be one of $GENZ_KINDS, got :$kind"
    d = tm.dimension
    a_vec = isnothing(a) ? ones(d) : a
    u_vec = isnothing(u) ? fill(0.5, d) : u
    @assert length(a_vec) == d "a must have length $d"
    @assert length(u_vec) == d "u must have length $d"
    return Genz(tm, d, kind, a_vec, u_vec)
end

function evaluate(f::Genz, x::AbstractMatrix)
    n, d = size(x)
    a = f.a
    u = f.u
    y = Vector{Float64}(undef, n)

    if f.kind == :oscillatory
        # x * a is BLAS GEMV (O(n·d) but vectorised): much faster than a row loop
        # for large n; @. fuses cos into one broadcast pass.
        s = x * a
        @. y = cos(2π * u[1] + s)

    elseif f.kind == :product_peak
        for i in 1:n
            p = 1.0
            for j in 1:d
                p *= 1.0 / (a[j]^(-2) + (x[i, j] - u[j])^2)
            end
            y[i] = p
        end

    elseif f.kind == :corner_peak
        for i in 1:n
            s = 1.0
            for j in 1:d
                s += a[j] * x[i, j]
            end
            y[i] = s^(-(d + 1))
        end

    elseif f.kind == :gaussian_peak
        for i in 1:n
            s = 0.0
            for j in 1:d
                s += a[j]^2 * (x[i, j] - u[j])^2
            end
            y[i] = exp(-s)
        end

    elseif f.kind == :continuous
        for i in 1:n
            s = 0.0
            for j in 1:d
                s += a[j] * abs(x[i, j] - u[j])
            end
            y[i] = exp(-s)
        end

    elseif f.kind == :discontinuous
        for i in 1:n
            discont = false
            s = 0.0
            for j in 1:d
                if x[i, j] > u[j]
                    discont = true
                    break
                end
                s += a[j] * x[i, j]
            end
            y[i] = discont ? 0.0 : exp(s)
        end
    end

    return y
end

"""
    genz_exact(f::Genz)

Compute the exact integral of the Genz function over [0,1]^d (when available).
"""
function genz_exact(f::Genz)
    d = f.dimension
    a = f.a
    u = f.u

    if f.kind == :oscillatory
        # Exact: product of sinc-like terms (complex)
        # For a_j, u_1: cos(2π u_1) * ∏ sin(a_j) / a_j  (simplified for a ≠ 0)
        val = cos(2π * u[1])
        for j in 1:d
            if abs(a[j]) < 1e-15
                continue
            end
            val *= sin(a[j]) / a[j]
        end
        return val

    elseif f.kind == :product_peak
        val = 1.0
        for j in 1:d
            val *= a[j] * (atan(a[j] * (1.0 - u[j])) - atan(a[j] * (-u[j])))
        end
        return val

    elseif f.kind == :corner_peak
        # Recursive formula — use simple numeric integration for now
        return NaN  # Exact formula is complex; not implemented

    elseif f.kind == :gaussian_peak
        val = 1.0
        for j in 1:d
            aj = a[j]
            uj = u[j]
            if abs(aj) < 1e-15
                continue
            end
            val *= sqrt(π) / (2.0 * aj) * (erf(aj * (1.0 - uj)) - erf(aj * (-uj)))
        end
        return val

    elseif f.kind == :continuous
        val = 1.0
        for j in 1:d
            aj = a[j]
            uj = u[j]
            if abs(aj) < 1e-15
                val *= 1.0
            else
                val *= (2.0 - exp(-aj * uj) - exp(-aj * (1.0 - uj))) / aj
            end
        end
        return val

    elseif f.kind == :discontinuous
        val = 1.0
        for j in 1:d
            aj = a[j]
            uj = u[j]
            if abs(aj) < 1e-15
                val *= uj
            else
                val *= (exp(aj * uj) - 1.0) / aj
            end
        end
        return val
    end
end

function Base.show(io::IO, f::Genz)
    print(io, "Genz(:$(f.kind), d=$(f.dimension))")
end
