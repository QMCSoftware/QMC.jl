"""
    Lattice(dimension::Int; randomize=true, seed=nothing, order="natural",
            replications=nothing)

Rank-1 integration lattice using the published Kuo generating vector
(kuo.lattice-33002-1024-1048576.9125), supporting up to 9125 dimensions
and n up to 2^20.

Points: x_i = frac(i · z / n), with optional random shift Δ ~ U[0,1)^d.

When `replications` is set to an integer R > 1, `gen_samples` returns an
`R × n × d` array of R independently shifted copies.

# Arguments
- `dimension`: number of dimensions (up to 9125).
- `randomize`: if true, apply a random shift.
- `seed`: optional RNG seed.
- `order`: `"natural"`, `"linear"`, `"radical_inverse"`, or `"gray"`.
- `replications`: number of independent shifts (nothing = 1, no extra dim).

# Examples
```julia
dd = Lattice(3; randomize=true, seed=7)
x = gen_samples(dd, 1024)  # 1024×3 shifted lattice points

dd_r = Lattice(3; seed=7, replications=16)
x = gen_samples(dd_r, 1024)  # 16×1024×3 array
```
"""
mutable struct Lattice <: AbstractDiscreteDistribution
    dimension::Int
    randomize::Bool
    order::String
    replications::Union{Nothing,Int}
    gen_vector::Vector{UInt64}
    shift::Matrix{Float64}   # R × d
    rng::AbstractRNG
    mimics::String
end

function Lattice(dimension::Int; randomize::Bool=true, seed=nothing,
                 order::String="natural", replications=nothing)
    dimension > 0 || throw(ArgumentError("dimension must be positive"))
    dimension <= _KUO_LATTICE_MAX_DIM || throw(ArgumentError(
        "dimension $dimension exceeds maximum supported ($_KUO_LATTICE_MAX_DIM)"))
    order_lc = lowercase(strip(order))
    order_lc in ("natural","linear","radical_inverse","gray") ||
        throw(ArgumentError("order must be natural/linear/radical_inverse/gray"))

    R = isnothing(replications) ? 1 : replications
    R >= 1 || throw(ArgumentError("replications must be >= 1"))

    rng = isnothing(seed) ? Random.default_rng() : MersenneTwister(seed)
    gv = _KUO_LATTICE_GEN_VECTOR[1:dimension]
    shift = randomize ? rand(rng, R, dimension) : zeros(R, dimension)

    return Lattice(dimension, randomize, order_lc, replications, gv, shift, rng, "StdUniform")
end

"""
    _radical_inverse(i::Int, n::Int)

Map integer i in 0..n-1 to its radical-inverse (bit-reversal) index.
`n` must be a power of 2.
"""
function _radical_inverse(i::Int, n::Int)
    m = trailing_zeros(n)
    rev = 0
    val = i
    for _ in 1:m
        rev = (rev << 1) | (val & 1)
        val >>= 1
    end
    return rev
end

"""
    _gray_code(i::Int)

Map integer i to its Gray code.
"""
_gray_code(i::Int) = i ⊻ (i >> 1)

function gen_samples(dd::Lattice, n::Int)
    n > 0 || throw(ArgumentError("n must be positive"))
    d = dd.dimension
    R = isnothing(dd.replications) ? 1 : dd.replications
    z = dd.gen_vector

    # Regenerate shift each call when randomized
    if dd.randomize
        dd.shift .= rand(dd.rng, R, d)
    end

    # Generate base (unshifted) points for one generating vector
    x_base = Matrix{Float64}(undef, n, d)

    if dd.order == "linear"
        @inbounds for j in 1:d
            zj = Float64(z[j])
            for i in 0:n-1
                x_base[i+1, j] = mod(i * zj / n, 1.0)
            end
        end
    elseif dd.order == "radical_inverse" || dd.order == "natural"
        # Radical-inverse (bit-reversal) ordering
        @inbounds for j in 1:d
            zj = Float64(z[j])
            for i in 0:n-1
                ri = ispow2(n) ? _radical_inverse(i, n) : i
                x_base[ri+1, j] = mod(i * zj / n, 1.0)
            end
        end
    elseif dd.order == "gray"
        @inbounds for j in 1:d
            zj = Float64(z[j])
            for i in 0:n-1
                gi = _gray_code(i)
                x_base[i+1, j] = mod(gi * zj / n, 1.0)
            end
        end
    end

    if R == 1
        # Single replication: return n × d
        @inbounds for j in 1:d
            sj = dd.shift[1, j]
            for i in 1:n
                x_base[i, j] = mod(x_base[i, j] + sj, 1.0)
            end
        end
        return x_base
    else
        # Multiple replications: return R × n × d
        result = Array{Float64}(undef, R, n, d)
        @inbounds for r in 1:R
            for j in 1:d
                sj = dd.shift[r, j]
                for i in 1:n
                    result[r, i, j] = mod(x_base[i, j] + sj, 1.0)
                end
            end
        end
        return result
    end
end

function Base.show(io::IO, dd::Lattice)
    reps = isnothing(dd.replications) ? "" : ", reps=$(dd.replications)"
    print(io, "Lattice(d=$(dd.dimension), randomize=$(dd.randomize), order=\"$(dd.order)\"$reps)")
end
