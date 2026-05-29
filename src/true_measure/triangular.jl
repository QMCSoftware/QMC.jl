"""
    Triangular(dd; lower=0.0, upper=1.0, mode=0.5)

Multivariate Triangular measure via inverse CDF (quantile function).

Each dimension is independently transformed through the triangular PPF.

# Arguments
- `dd`: discrete distribution.
- `lower`: lower bound (scalar or d-vector).
- `upper`: upper bound (scalar or d-vector).
- `mode`: peak/mode (scalar or d-vector), must satisfy lower ≤ mode ≤ upper.
"""
struct Triangular <: AbstractTrueMeasure
    dd::AbstractDiscreteDistribution
    dimension::Int
    lower::Vector{Float64}
    upper::Vector{Float64}
    mode::Vector{Float64}
end

function Triangular(dd::AbstractDiscreteDistribution;
    lower = 0.0, upper = 1.0, mode = 0.5)
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

function Base.show(io::IO, tm::Triangular)
    print(io, "Triangular(d=$(tm.dimension))")
end
