"""
    StudentT(dd; df=2.0, loc=0.0, scale=1.0)

Multivariate Student-t measure via sequential conditioning.

Each dimension uses the inverse CDF of the marginal t-distribution,
applied to the uniform samples.

# Arguments
- `dd`: discrete distribution.
- `df`: degrees of freedom (> 0).
- `loc`: location (scalar or d-vector).
- `scale`: scale (scalar or d-vector, positive).
"""
struct StudentT{D <: AbstractDiscreteDistribution} <: AbstractTrueMeasure
    dd::D
    dimension::Int
    df::Float64
    loc::Vector{Float64}
    scale::Vector{Float64}
end

function StudentT(dd::AbstractDiscreteDistribution; df::Float64=2.0, loc=0.0, scale=1.0)
    df > 0 || throw(ArgumentError("df must be positive"))
    d = dd.dimension
    loc_vec = loc isa Number ? fill(Float64(loc), d) : Float64.(collect(loc))
    scale_vec = scale isa Number ? fill(Float64(scale), d) : Float64.(collect(scale))
    all(scale_vec .> 0) || throw(ArgumentError("scale must be positive"))
    length(loc_vec) == d || throw(ArgumentError("loc length must match dimension"))
    length(scale_vec) == d || throw(ArgumentError("scale length must match dimension"))
    return StudentT(dd, d, df, loc_vec, scale_vec)
end

function transform(tm::StudentT, x::AbstractMatrix)
    n, d = size(x)
    y = Matrix{Float64}(undef, n, d)
    if tm.df == 2.0
        # Exact closed form for the Student-t quantile at ν = 2:
        #   Q(p) = (2p − 1) / √(2p(1 − p)).
        # This avoids the per-element inverse-incomplete-beta in
        # Distributions.quantile and matches it to numerical precision.
        @inbounds for j in 1:d
            loc = tm.loc[j]
            scale = tm.scale[j]
            @simd for i in 1:n
                p = _open_unit_interval(x[i, j])
                y[i, j] = loc + scale * (2.0 * p - 1.0) / sqrt(2.0 * p * (1.0 - p))
            end
        end
    else
        tdist = Distributions.TDist(tm.df)
        @inbounds for j in 1:d
            for i in 1:n
                y[i, j] =
                    tm.loc[j] + tm.scale[j] * quantile(tdist, _open_unit_interval(x[i, j]))
            end
        end
    end
    return y
end

Base.show(io::IO, tm::StudentT) = print(io, "StudentT(d=$(tm.dimension), df=$(tm.df))")
