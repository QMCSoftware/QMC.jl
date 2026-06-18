"""
    StudentT(dd; df=2.0, loc=0.0, scale=1.0)

Multivariate Student-t measure via sequential conditioning.

Each dimension uses the inverse CDF of the marginal t-distribution,
applied to the uniform samples.

The exact `df=1.0` (Cauchy) and `df=2.0` cases use closed-form quantiles,
with a dedicated standard-parameter fast path for `loc=0.0, scale=1.0`.

# Arguments
- `dd`: discrete distribution.
- `df`: degrees of freedom (> 0).
- `loc`: location (scalar or d-vector).
- `scale`: scale (scalar or d-vector, positive).

# Examples
```jldoctest
julia> using QMC

julia> dd = DigitalNetB2(2; seed=7);

julia> tm = StudentT(dd; df=2.0)
StudentT(d=2, df=2.0)

julia> round.(transform(tm, gen_samples(dd, 4)); digits=6)
4×2 Matrix{Float64}:
  1.37268   -0.429493
 -0.450476   1.42346
  0.283405  -1.82588
 -1.90887    0.302863
```
"""
struct StudentT{D <: AbstractDiscreteDistribution, Standard, QuantileCase} <:
       AbstractTrueMeasure
    dd::D
    dimension::Int
    df::Float64
    loc::Vector{Float64}
    scale::Vector{Float64}
end

function StudentT(dd::AbstractDiscreteDistribution; df::Float64=2.0, loc=0.0, scale=1.0)
    df > 0 || throw(ArgumentError("df must be positive"))
    d = dimension(dd)
    loc_vec = loc isa Number ? fill(Float64(loc), d) : Float64.(collect(loc))
    scale_vec = scale isa Number ? fill(Float64(scale), d) : Float64.(collect(scale))
    all(scale_vec .> 0) || throw(ArgumentError("scale must be positive"))
    length(loc_vec) == d || throw(ArgumentError("loc length must match dimension"))
    length(scale_vec) == d || throw(ArgumentError("scale length must match dimension"))
    is_standard = all(iszero, loc_vec) && all(==(1.0), scale_vec)
    quantile_case = df == 1.0 ? :df1 : (df == 2.0 ? :df2 : :generic)
    return StudentT{typeof(dd), is_standard, quantile_case}(dd, d, df, loc_vec, scale_vec)
end

@inline _student_t_quantile_df1(u::Real) = tanpi(_open_unit_interval(u) - 0.5)

@inline function _student_t_quantile_df2(u::Real)
    p = _open_unit_interval(u)
    return (2.0 * p - 1.0) / sqrt(2.0 * p * (1.0 - p))
end

function _transform_student_t_df1_standard!(y::Matrix{Float64}, x::AbstractMatrix)
    n, d = size(x)
    @inbounds for j in 1:d
        @simd for i in 1:n
            y[i, j] = _student_t_quantile_df1(x[i, j])
        end
    end
    return y
end

function _transform_student_t_df1_affine!(y::Matrix{Float64}, tm::StudentT, x::AbstractMatrix)
    n, d = size(x)
    @inbounds for j in 1:d
        loc = tm.loc[j]
        scale = tm.scale[j]
        @simd for i in 1:n
            y[i, j] = loc + scale * _student_t_quantile_df1(x[i, j])
        end
    end
    return y
end

function _transform_student_t_df2_standard!(y::Matrix{Float64}, x::AbstractMatrix)
    n, d = size(x)
    @inbounds for j in 1:d
        @simd for i in 1:n
            y[i, j] = _student_t_quantile_df2(x[i, j])
        end
    end
    return y
end

function _transform_student_t_df2_affine!(y::Matrix{Float64}, tm::StudentT, x::AbstractMatrix)
    n, d = size(x)
    @inbounds for j in 1:d
        loc = tm.loc[j]
        scale = tm.scale[j]
        @simd for i in 1:n
            y[i, j] = loc + scale * _student_t_quantile_df2(x[i, j])
        end
    end
    return y
end

function _transform_student_t_quantile_standard!(
    y::Matrix{Float64},
    tm::StudentT,
    x::AbstractMatrix,
)
    n, d = size(x)
    tdist = Distributions.TDist(tm.df)
    @inbounds for j in 1:d
        for i in 1:n
            y[i, j] = quantile(tdist, _open_unit_interval(x[i, j]))
        end
    end
    return y
end

function _transform_student_t_quantile_affine!(
    y::Matrix{Float64},
    tm::StudentT,
    x::AbstractMatrix,
)
    n, d = size(x)
    tdist = Distributions.TDist(tm.df)
    @inbounds for j in 1:d
        loc = tm.loc[j]
        scale = tm.scale[j]
        for i in 1:n
            y[i, j] = loc + scale * quantile(tdist, _open_unit_interval(x[i, j]))
        end
    end
    return y
end

function transform(tm::StudentT, x::AbstractMatrix)
    n, d = size(x)
    y = Matrix{Float64}(undef, n, d)
    _transform_student_t!(y, tm, x)
    return y
end

function _transform_student_t!(
    y::Matrix{Float64},
    tm::StudentT{<:Any, true, :df1},
    x::AbstractMatrix,
)
    # Exact Cauchy quantile for ν = 1:
    #   Q(p) = tan(π(p − 1/2)).
    return _transform_student_t_df1_standard!(y, x)
end

function _transform_student_t!(
    y::Matrix{Float64},
    tm::StudentT{<:Any, false, :df1},
    x::AbstractMatrix,
)
    return _transform_student_t_df1_affine!(y, tm, x)
end

function _transform_student_t!(
    y::Matrix{Float64},
    tm::StudentT{<:Any, true, :df2},
    x::AbstractMatrix,
)
    # Exact closed form for the Student-t quantile at ν = 2:
    #   Q(p) = (2p − 1) / √(2p(1 − p)).
    # This avoids the per-element inverse-incomplete-beta in
    # Distributions.quantile and matches it to numerical precision.
    return _transform_student_t_df2_standard!(y, x)
end

function _transform_student_t!(
    y::Matrix{Float64},
    tm::StudentT{<:Any, false, :df2},
    x::AbstractMatrix,
)
    return _transform_student_t_df2_affine!(y, tm, x)
end

function _transform_student_t!(
    y::Matrix{Float64},
    tm::StudentT{<:Any, true, :generic},
    x::AbstractMatrix,
)
    return _transform_student_t_quantile_standard!(y, tm, x)
end

function _transform_student_t!(
    y::Matrix{Float64},
    tm::StudentT{<:Any, false, :generic},
    x::AbstractMatrix,
)
    return _transform_student_t_quantile_affine!(y, tm, x)
end

Base.show(io::IO, tm::StudentT) = print(io, "StudentT(d=$(tm.dimension), df=$(tm.df))")
