"""
    IIDStdUniform(dimension::Int; seed=nothing)

IID standard uniform random number generator producing points in [0,1)^d.

Each call to `gen_samples` draws independent uniform random samples using
the stored RNG. Setting `seed` makes the sequence reproducible.

# Examples
```jldoctest
julia> using QMC

julia> dd = IIDStdUniform(2; seed=7)
IIDStdUniform(d=2)

julia> round.(gen_samples(dd, 4); digits=6)
4×2 Matrix{Float64}:
 0.601137  0.5536
 0.943441  0.631885
 0.717708  0.099473
 0.240963  0.357784

julia> round.(gen_samples(dd, 4); digits=6) # new samples every call
4×2 Matrix{Float64}:
 0.426401  0.577333
 0.380653  0.385786
 0.985736  0.344253
 0.432531  0.32357
```

```jldoctest
julia> using QMC

julia> x = gen_samples(IIDStdUniform(3; seed=7), 4);

julia> size(x)
(4, 3)
```
"""
mutable struct IIDStdUniform{R <: AbstractRNG} <: AbstractDiscreteDistribution
    dimension::Int
    rng::R
    mimics::String
end

function IIDStdUniform(dimension::Int; seed=nothing)
    dimension > 0 || throw(ArgumentError("dimension must be positive, got $dimension"))
    rng = isnothing(seed) ? Random.default_rng() : MersenneTwister(seed)
    return IIDStdUniform(dimension, rng, "StdUniform")
end

function gen_samples(dd::IIDStdUniform, n::Int; n_start::Int=0)
    n > 0 || throw(ArgumentError("n must be positive, got $n"))
    return rand(dd.rng, n, dd.dimension)
end

Base.show(io::IO, dd::IIDStdUniform) = print(io, "IIDStdUniform(d=$(dd.dimension))")
