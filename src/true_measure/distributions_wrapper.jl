"""
    DistributionsWrapper(dd::AbstractDiscreteDistribution;
                         distribution=nothing,
                         marginals=nothing)

Wraps any `Distributions.jl` distribution via its quantile function (inverse CDF).

This is the Julia equivalent of QMCSoftware's `SciPyWrapper`. It maps
uniform [0,1] samples to the target distribution using the PPF (percent
point function / quantile function).

# Arguments
- `dd`: Discrete distribution providing uniform samples.
- `distribution`: A single `Distributions.UnivariateDistribution` applied to
  all dimensions. One of `distribution` or `marginals` must be provided.
- `marginals`: A vector of `d` univariate distributions, one per dimension.

# Examples
```julia
# Same distribution for all dimensions
dd = Lattice(3; seed=7)
tm = DistributionsWrapper(dd; distribution=Distributions.Exponential(2.0))
x = transform(tm, gen_samples(dd, 100))  # 100 × 3 Exponential(2) samples

# Different distributions per dimension
dd = Lattice(2; seed=7)
tm = DistributionsWrapper(dd; marginals=[
    Distributions.Normal(0, 1),
    Distributions.Exponential(1.0)
])
```
"""
struct DistributionsWrapper <: AbstractTrueMeasure
    dd::AbstractDiscreteDistribution
    dimension::Int
    marginals::Vector{Distributions.UnivariateDistribution}
end

function DistributionsWrapper(dd::AbstractDiscreteDistribution;
    distribution::Union{Nothing, Distributions.UnivariateDistribution} = nothing,
    marginals::Union{Nothing, Vector} = nothing)
    d = dd.dimension
    if !isnothing(distribution) && isnothing(marginals)
        margs = fill(distribution, d)
    elseif isnothing(distribution) && !isnothing(marginals)
        length(marginals) == d || throw(
            ArgumentError(
                "marginals length ($(length(marginals))) must match dimension ($d)"),
        )
        margs = Vector{Distributions.UnivariateDistribution}(marginals)
    else
        throw(
            ArgumentError("Exactly one of `distribution` or `marginals` must be provided"),
        )
    end

    return DistributionsWrapper(dd, d, margs)
end

function transform(tm::DistributionsWrapper, x::AbstractMatrix)
    n, d = size(x)
    y = Matrix{Float64}(undef, n, d)
    @inbounds for j in 1:d
        dist = tm.marginals[j]
        for i in 1:n
            # Clamp to avoid Inf at boundaries
            u = clamp(x[i, j], 1e-15, 1.0 - 1e-15)
            y[i, j] = Distributions.quantile(dist, u)
        end
    end
    return y
end

function Base.show(io::IO, tm::DistributionsWrapper)
    if all(m -> m == tm.marginals[1], tm.marginals)
        print(io, "DistributionsWrapper(d=$(tm.dimension), dist=$(tm.marginals[1]))")
    else
        print(io, "DistributionsWrapper(d=$(tm.dimension), mixed marginals)")
    end
end
