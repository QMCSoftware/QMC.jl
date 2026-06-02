"""
    Uniform(dd::AbstractDiscreteDistribution; lower_bound=0.0, upper_bound=1.0)

Uniform measure on [a,b]^d. Transforms uniform [0,1) samples via linear scaling.

The transform maps each component `x_j` to `a_j + x_j * (b_j - a_j)`.
The Jacobian factor is `prod(upper_bound - lower_bound)`.

# Arguments
- `dd`: a discrete distribution providing uniform samples in [0,1)^d.
- `lower_bound`: scalar or vector lower bound(s). Default `0.0`.
- `upper_bound`: scalar or vector upper bound(s). Default `1.0`.

# Examples
```julia
dd = IIDStdUniform(3; seed=42)
tm = Uniform(dd; lower_bound=-2.0, upper_bound=2.0)
x = gen_samples(dd, 100)
y = transform(tm, x)  # 100×3 matrix in [-2, 2]^3
```
"""
struct Uniform{D <: AbstractDiscreteDistribution} <: AbstractTrueMeasure
    dd::D
    dimension::Int
    lower_bound::Vector{Float64}
    upper_bound::Vector{Float64}
end

function Uniform(dd::AbstractDiscreteDistribution;
    lower_bound = 0.0, upper_bound = 1.0)
    d = dd.dimension
    lb = _expand_bounds(lower_bound, d)
    ub = _expand_bounds(upper_bound, d)
    all(lb .< ub) ||
        throw(ArgumentError("lower_bound must be less than upper_bound in every dimension"))
    return Uniform(dd, d, lb, ub)
end

"""Expand a scalar or vector to a `d`-length Float64 vector."""
function _expand_bounds(val, d::Int)
    if val isa Real
        return fill(Float64(val), d)
    else
        length(val) == d ||
            throw(
                ArgumentError(
                    "bound vector length ($(length(val))) must match dimension ($d)",
                ),
            )
        return Float64.(collect(val))
    end
end

function transform(tm::Uniform, x::AbstractMatrix)
    # x is n×d with entries in [0,1)
    range = tm.upper_bound .- tm.lower_bound
    return x .* range' .+ tm.lower_bound'
end

"""
    jacobian(tm::Uniform)

Return the Jacobian determinant of the Uniform transform (product of interval widths).
"""
jacobian(tm::Uniform) = prod(tm.upper_bound .- tm.lower_bound)

function Base.show(io::IO, tm::Uniform)
    print(
        io,
        "Uniform(d=$(tm.dimension), lower=$(tm.lower_bound), upper=$(tm.upper_bound))",
    )
end
