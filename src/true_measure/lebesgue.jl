"""
    Lebesgue(dd::AbstractDiscreteDistribution; lower_bound=0.0, upper_bound=1.0)

Lebesgue (unnormalized uniform) measure on [a,b]^d. The transform is the same
linear scaling as `Uniform`, but the volume `prod(b - a)` is stored separately
so it can be used as a weight factor in integration rather than being absorbed
into the density.

# Arguments
- `dd`: a discrete distribution providing uniform samples in [0,1)^d.
- `lower_bound`: scalar or vector lower bound(s). Default `0.0`.
- `upper_bound`: scalar or vector upper bound(s). Default `1.0`.

# Examples
```julia
dd = IIDStdUniform(2; seed=7)
tm = Lebesgue(dd; lower_bound=0.0, upper_bound=2.0)
x = gen_samples(dd, 100)
y = transform(tm, x)        # 100×2 matrix in [0, 2]^2
tm.volume                   # 4.0
```
"""
struct Lebesgue <: AbstractTrueMeasure
    dd::AbstractDiscreteDistribution
    dimension::Int
    lower_bound::Vector{Float64}
    upper_bound::Vector{Float64}
    volume::Float64
end

function Lebesgue(dd::AbstractDiscreteDistribution;
        lower_bound = 0.0, upper_bound = 1.0)
    d = dd.dimension
    lb = _expand_bounds(lower_bound, d)
    ub = _expand_bounds(upper_bound, d)
    all(lb .< ub) ||
        throw(ArgumentError("lower_bound must be less than upper_bound in every dimension"))
    vol = prod(ub .- lb)
    return Lebesgue(dd, d, lb, ub, vol)
end

function transform(tm::Lebesgue, x::AbstractMatrix)
    # Same linear scaling as Uniform: a + x * (b - a)
    range = tm.upper_bound .- tm.lower_bound
    return x .* range' .+ tm.lower_bound'
end

function Base.show(io::IO, tm::Lebesgue)
    print(io,
        "Lebesgue(d=$(tm.dimension), volume=$(tm.volume), lower=$(tm.lower_bound), upper=$(tm.upper_bound))")
end
