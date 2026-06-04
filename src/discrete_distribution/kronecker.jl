"""
    Kronecker(dimension::Int; seed=nothing, generator=:default)

Low-discrepancy Kronecker sequence based on irrational number multiples.

The Kronecker sequence generates points as `x_i = frac(i * α)` where `α` is a
d-dimensional vector of irrational numbers and `frac` denotes the fractional part.

By default, uses the sequence of square roots of successive primes:
`α = (√2, √3, √5, √7, √11, ...)`.

An optional random shift Δ ~ U[0,1)^d can be applied for randomization.

# Arguments
- `dimension::Int`: number of dimensions.
- `seed`: optional RNG seed. If provided, applies a random shift.
- `generator`: `:default` uses √primes; or pass a `Vector{Float64}` of length d.

# Example
```julia
kr = Kronecker(3; seed=7)
x = gen_samples(kr, 100)  # 100 × 3 Kronecker points
```
"""
struct Kronecker <: AbstractDiscreteDistribution
    dimension::Int
    alpha::Vector{Float64}  # generator vector
    shift::Vector{Float64}  # random shift (zeros if unrandomized)
    randomize::Bool
    mimics::String
end

# First 1000 primes (enough for high dimensions)
function _first_primes(n::Int)
    primes = Int[]
    candidate = 2
    while length(primes) < n
        is_prime = true
        for p in primes
            p * p > candidate && break
            if candidate % p == 0
                is_prime = false
                break
            end
        end
        if is_prime
            push!(primes, candidate)
        end
        candidate += 1
    end
    return primes
end

function Kronecker(dimension::Int; seed=nothing, generator=:default)
    dimension > 0 || throw(ArgumentError("dimension must be positive"))

    if generator == :default
        primes = _first_primes(dimension)
        alpha = sqrt.(Float64.(primes))
    elseif generator isa Vector{Float64}
        length(generator) == dimension || throw(
            ArgumentError(
                "generator length ($(length(generator))) must match dimension ($dimension)",
            ),
        )
        alpha = generator
    else
        throw(ArgumentError("generator must be :default or a Vector{Float64}"))
    end

    randomize = !isnothing(seed)
    if randomize
        rng = MersenneTwister(seed)
        shift = rand(rng, dimension)
    else
        shift = zeros(dimension)
    end

    return Kronecker(dimension, alpha, shift, randomize, "StdUniform")
end

"""
    gen_samples(kr::Kronecker, n::Int) -> Matrix{Float64}

Generate `n` Kronecker sequence points. Returns an `n × d` matrix with values
in [0, 1).
"""
function gen_samples(kr::Kronecker, n::Int; n_start::Int=0)
    n > 0 || throw(ArgumentError("n must be positive"))
    d = kr.dimension
    x = Matrix{Float64}(undef, n, d)

    @inbounds for i in 1:n
        for j in 1:d
            x[i, j] = mod((n_start + i) * kr.alpha[j] + kr.shift[j], 1.0)
        end
    end

    return x
end

function Base.show(io::IO, kr::Kronecker)
    rstr = kr.randomize ? "shifted" : "unshifted"
    print(io, "Kronecker(d=$(kr.dimension), $rstr)")
end
