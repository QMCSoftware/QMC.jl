"""
    IIDStdUniform(dimension::Int; seed=nothing)

IID standard uniform random number generator producing points in [0,1)^d.

Each call to `gen_samples` draws independent uniform random samples using
the stored RNG. Setting `seed` makes the sequence reproducible.

# Examples
```julia
dd = IIDStdUniform(3; seed=42)
x = gen_samples(dd, 1024)  # 1024×3 matrix of uniform samples
```
"""
mutable struct IIDStdUniform{R <: AbstractRNG} <: AbstractDiscreteDistribution
    dimension::Int
    rng::R
    mimics::String
end

function IIDStdUniform(dimension::Int; seed = nothing)
    dimension > 0 || throw(ArgumentError("dimension must be positive, got $dimension"))
    rng = isnothing(seed) ? Random.default_rng() : MersenneTwister(seed)
    return IIDStdUniform(dimension, rng, "StdUniform")
end

function gen_samples(dd::IIDStdUniform, n::Int; n_start::Int = 0)
    n > 0 || throw(ArgumentError("n must be positive, got $n"))
    return rand(dd.rng, n, dd.dimension)
end

function Base.show(io::IO, dd::IIDStdUniform)
    print(io, "IIDStdUniform(d=$(dd.dimension))")
end
