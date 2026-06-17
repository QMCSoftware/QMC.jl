"""
    Triangular(dd; lower=0.0, upper=1.0, mode=0.5)

Multivariate Triangular measure via inverse CDF (quantile function).

Each dimension is independently transformed through the triangular PPF.

# Arguments
- `dd`: discrete distribution.
- `lower`: lower bound (scalar or d-vector).
- `upper`: upper bound (scalar or d-vector).
- `mode`: peak/mode (scalar or d-vector), must satisfy lower ≤ mode ≤ upper.

# Examples
```jldoctest
julia> using QMC

julia> dd = DigitalNetB2(2; seed=7);

julia> tm = Triangular(dd; lower=0.0, upper=2.0, mode=1.0)
Triangular(d=2)

julia> round.(transform(tm, gen_samples(dd, 4)); digits=6)
4×2 Matrix{Float64}:
 1.44908   0.842264
 0.83456   1.46093
 1.10361   0.457611
 0.443273  1.11085
```
"""
struct Triangular{D <: AbstractDiscreteDistribution} <: AbstractTrueMeasure
    dd::D
    dimension::Int
    lower::Vector{Float64}
    upper::Vector{Float64}
    mode::Vector{Float64}
end

function Triangular(dd::AbstractDiscreteDistribution; lower=0.0, upper=1.0, mode=0.5)
    d = dd.dimension
    lo = lower isa Number ? fill(Float64(lower), d) : Float64.(collect(lower))
    hi = upper isa Number ? fill(Float64(upper), d) : Float64.(collect(upper))
    md = mode isa Number ? fill(Float64(mode), d) : Float64.(collect(mode))
    all(lo .<= md .<= hi) || throw(ArgumentError("need lower ≤ mode ≤ upper"))
    all(lo .< hi) || throw(ArgumentError("need lower < upper"))
    return Triangular(dd, d, lo, hi, md)
end

function _triangular_ppf(u::Float64, a::Float64, b::Float64, c::Float64)
    # Inverse CDF of Triangular(a, b, c) at probability u
    Fc = (c - a) / (b - a)
    if u < Fc
        return a + sqrt(u * (b - a) * (c - a))
    else
        return b - sqrt((1.0 - u) * (b - a) * (b - c))
    end
end

function transform(tm::Triangular, x::AbstractMatrix)
    n, d = size(x)
    y = Matrix{Float64}(undef, n, d)
    @inbounds for j in 1:d
        for i in 1:n
            y[i, j] = _triangular_ppf(x[i, j], tm.lower[j], tm.upper[j], tm.mode[j])
        end
    end
    return y
end

Base.show(io::IO, tm::Triangular) = print(io, "Triangular(d=$(tm.dimension))")
