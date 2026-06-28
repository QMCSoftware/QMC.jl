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

# Examples
```jldoctest
julia> using QuasiMC, Statistics

julia> for (kind, coeff, target) in (
           (:oscillatory, 1, -0.351),
           (:oscillatory, 2, -0.329),
           (:oscillatory, 3, -0.217),
           (:corner_peak, 1, 0.713),
           (:corner_peak, 2, 0.714),
           (:corner_peak, 3, 0.720),
       )
           d = 2
           base = coeff == 1 ? (collect(1:d) .- 0.5) ./ d :
               coeff == 2 ? 1.0 ./ (collect(1:d) .^ 2) :
               exp.((collect(1:d) .* log(1e-8)) ./ d)
           a = kind == :oscillatory ? 4.5 .* base ./ sum(base) : 0.25 .* base ./ sum(base)
           f = Genz(Uniform(DigitalNetB2(2; seed=7)); kind=kind, a=a, u=zeros(d))
           y = sample_and_evaluate(f, 2^14)
           println(kind, " ", coeff, " ", round(mean(y); digits=3), " ", round(genz_exact(f); digits=3))
       end
oscillatory 1 -0.351 -0.351
oscillatory 2 -0.329 -0.329
oscillatory 3 -0.217 -0.217
corner_peak 1 0.713 0.713
corner_peak 2 0.714 0.714
corner_peak 3 0.72 0.72
```
"""
struct Genz{TM <: AbstractTrueMeasure} <: AbstractIntegrand
    true_measure::TM
    dimension::Int
    kind::Symbol
    a::Vector{Float64}
    u::Vector{Float64}
end

const GENZ_KINDS =
    (:oscillatory, :product_peak, :corner_peak, :gaussian_peak, :continuous, :discontinuous)

function Genz(
    tm::AbstractTrueMeasure;
    kind::Symbol=:oscillatory,
    a::Union{Nothing, Vector{Float64}}=nothing,
    u::Union{Nothing, Vector{Float64}}=nothing,
)
    @assert kind in GENZ_KINDS "kind must be one of $GENZ_KINDS, got :$kind"
    d = dimension(tm)
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
        # Julia matrices are column-major, so keeping `i` outer and `j` inner
        # would make the inner loop stride by `n`. Swapping to `j` outer / `i`
        # inner reads each column contiguously while preserving the per-row
        # product order.
        fill!(y, 1.0)
        @inbounds for j in 1:d
            aj_m2 = a[j]^(-2)
            uj = u[j]
            @simd for i in 1:n
                y[i] *= 1.0 / (aj_m2 + (x[i, j] - uj)^2)
            end
        end

    elseif f.kind == :corner_peak
        # Same column-major cache argument as above: `j` outer / `i` inner keeps
        # reads contiguous instead of stride-`n` across columns.
        s = ones(n)
        @inbounds for j in 1:d
            aj = a[j]
            @simd for i in 1:n
                s[i] += aj * x[i, j]
            end
        end
        @inbounds @. y = s^(-(d + 1))

    elseif f.kind == :gaussian_peak
        # Column reduction avoids the stride-`n` access pattern of a row-major
        # loop nest on Julia's column-major arrays.
        s = zeros(n)
        @inbounds for j in 1:d
            aj2 = a[j]^2
            uj = u[j]
            @simd for i in 1:n
                s[i] += aj2 * (x[i, j] - uj)^2
            end
        end
        @. y = exp(-s)

    elseif f.kind == :continuous
        # Same column-major tip: loop over columns outside, rows inside, so each
        # column is read contiguously and accumulated into a length-`n` vector.
        s = zeros(n)
        @inbounds for j in 1:d
            aj = a[j]
            uj = u[j]
            @simd for i in 1:n
                s[i] += aj * abs(x[i, j] - uj)
            end
        end
        @. y = exp(-s)

    elseif f.kind == :discontinuous
        # Preserve the early-stop semantics with a per-row activity mask while
        # iterating in column-major order; once a row crosses the discontinuity,
        # later coordinates are ignored exactly as in the row loop.
        active = trues(n)
        s = zeros(n)
        @inbounds for j in 1:d
            aj = a[j]
            uj = u[j]
            for i in 1:n
                if active[i]
                    xij = x[i, j]
                    if xij > uj
                        active[i] = false
                    else
                        s[i] += aj * xij
                    end
                end
            end
        end
        @inbounds for i in 1:n
            y[i] = active[i] ? exp(s[i]) : 0.0
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
        # ∫_{[0,1]^d} cos(2π u₁ + Σ aⱼ xⱼ) dx
        #   = cos(2π u₁ + Σ aⱼ/2) · ∏ sinc(aⱼ/2),  sinc(t) = sin(t)/t (→ 1 as t→0).
        phase = 2π * u[1]
        val = 1.0
        for j in 1:d
            phase += a[j] / 2
            if abs(a[j]) >= 1e-15
                val *= sin(a[j] / 2) / (a[j] / 2)
            end
        end
        return cos(phase) * val

    elseif f.kind == :product_peak
        val = 1.0
        for j in 1:d
            val *= a[j] * (atan(a[j] * (1.0 - u[j])) - atan(a[j] * (-u[j])))
        end
        return val

    elseif f.kind == :corner_peak
        # ∫_{[0,1]^d} (1 + Σ aⱼ xⱼ)^{-(d+1)} dx
        #   = 1/(d! ∏ aⱼ) · Σ_{v∈{0,1}^d} (-1)^{|v|} (1 + Σ vⱼ aⱼ)^{-1}
        # (inclusion–exclusion over the cube corners). Requires every aⱼ ≠ 0;
        # the 2^d sum is only practical for modest d.
        any(aj -> abs(aj) < 1e-15, a) && return NaN
        d > 20 && return NaN
        total = 0.0
        for mask in 0:(2 ^ d - 1)
            s = 1.0
            bits = 0
            for j in 1:d
                if (mask >> (j - 1)) & 1 == 1
                    s += a[j]
                    bits += 1
                end
            end
            total += (iseven(bits) ? 1.0 : -1.0) / s
        end
        fact = 1.0
        for k in 2:d
            fact *= k
        end
        return total / (fact * prod(a))

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

Base.show(io::IO, f::Genz) = print(io, "Genz(:$(f.kind), d=$(f.dimension))")
