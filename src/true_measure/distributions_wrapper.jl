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
```jldoctest
julia> using QuasiMC

julia> import Distributions

julia> dd = Lattice(2; seed=7);

julia> tm = DistributionsWrapper(dd; distribution=Distributions.Exponential(2.0));

julia> round.(transform(tm, gen_samples(dd, 4)); digits=6)
4×2 Matrix{Float64}:
 2.52963   0.551409
 0.491055  2.70157
 6.86588   9.41281
 1.26113   1.35047

julia> size(tm.marginals)
(2,)
```
"""
struct DistributionsWrapper{D <: AbstractDiscreteDistribution} <: AbstractTrueMeasure
    dd::D
    dimension::Int
    marginals::Vector{Distributions.UnivariateDistribution}
end

function DistributionsWrapper(
    dd::AbstractDiscreteDistribution;
    distribution::Union{Nothing, Distributions.UnivariateDistribution}=nothing,
    marginals::Union{Nothing, Vector}=nothing,
)
    d = dimension(dd)
    if !isnothing(distribution) && isnothing(marginals)
        margs = Vector{Distributions.UnivariateDistribution}(fill(distribution, d))
    elseif isnothing(distribution) && !isnothing(marginals)
        length(marginals) == d || throw(
            ArgumentError("marginals length ($(length(marginals))) must match dimension ($d)"),
        )
        margs = Vector{Distributions.UnivariateDistribution}(marginals)
    else
        throw(ArgumentError("Exactly one of `distribution` or `marginals` must be provided"))
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
