"""
    Halton(dimension::Int; randomize=true, seed=nothing, generalize=true)

Halton sequence based on van der Corput sequences in successive prime bases.

The ``j``-th coordinate uses the ``j``-th prime number as its base.  With
`randomize=true` a random shift ``\\Delta_j \\sim U[0,1)`` is added (mod 1)
to each coordinate independently.

When `generalize=true`, a per-dimension permutation of digits is applied
(generalized Halton / Faure permutation style) to improve uniformity in
higher dimensions.

# Arguments
- `dimension::Int`: number of dimensions (up to 250).
- `randomize::Bool=true`: apply random shift randomization.
- `seed`: optional RNG seed for reproducibility.
- `generalize::Bool=true`: apply generalized digit permutations.

# Examples
```julia
hal = Halton(5; seed=42)
x = gen_samples(hal, 1000)  # 1000×5 matrix
```
"""

# ──────────────────────────────────────────────────────────────────────────────
# First 250 prime numbers
# ──────────────────────────────────────────────────────────────────────────────
const _PRIMES_250 = Int[
2, 3, 5, 7, 11, 13, 17, 19, 23, 29,
31, 37, 41, 43, 47, 53, 59, 61, 67, 71,
73, 79, 83, 89, 97, 101, 103, 107, 109, 113,
127, 131, 137, 139, 149, 151, 157, 163, 167, 173,
179, 181, 191, 193, 197, 199, 211, 223, 227, 229,
233, 239, 241, 251, 257, 263, 269, 271, 277, 281,
283, 293, 307, 311, 313, 317, 331, 337, 347, 349,
353, 359, 367, 373, 379, 383, 389, 397, 401, 409,
419, 421, 431, 433, 439, 443, 449, 457, 461, 463,
467, 479, 487, 491, 499, 503, 509, 521, 523, 541,
547, 557, 563, 569, 571, 577, 587, 593, 599, 601,
607, 613, 617, 619, 631, 641, 643, 647, 653, 659,
661, 673, 677, 683, 691, 701, 709, 719, 727, 733,
739, 743, 751, 757, 761, 769, 773, 787, 797, 809,
811, 821, 823, 827, 829, 839, 853, 857, 859, 863,
877, 881, 883, 887, 907, 911, 919, 929, 937, 941,
947, 953, 967, 971, 977, 983, 991, 997, 1009, 1013,
1019, 1021, 1031, 1033, 1039, 1049, 1051, 1061, 1063, 1069,
1087, 1091, 1093, 1097, 1103, 1109, 1117, 1123, 1129, 1151,
1153, 1163, 1171, 1181, 1187, 1193, 1201, 1213, 1217, 1223,
1229, 1231, 1237, 1249, 1259, 1277, 1279, 1283, 1289, 1291,
1297, 1301, 1303, 1307, 1319, 1321, 1327, 1361, 1367, 1373,
1381, 1399, 1409, 1423, 1427, 1429, 1433, 1439, 1447, 1451,
1453, 1459, 1471, 1481, 1483, 1487, 1489, 1493, 1499, 1511,
1523, 1531, 1543, 1549, 1553, 1559, 1567, 1571, 1579, 1583
]

# ──────────────────────────────────────────────────────────────────────────────
# Struct
# ──────────────────────────────────────────────────────────────────────────────
"""
    Halton <: AbstractDiscreteDistribution

Halton sequence based on van der Corput sequences in successive prime bases.
Supports up to 250 dimensions with optional random shift and generalized permutations.
See the outer constructor for full documentation.
"""
mutable struct Halton <: AbstractDiscreteDistribution
    dimension::Int
    randomize::Bool
    generalize::Bool
    primes::Vector{Int}
    shift::Vector{Float64}
    permutations::Vector{Vector{Int}}   # per-dimension digit permutations
    rng::AbstractRNG
    mimics::String
end

function Halton(dimension::Int; randomize::Bool = true, seed = nothing,
        generalize::Bool = true)
    dimension > 0 || throw(ArgumentError("dimension must be positive, got $dimension"))
    max_dim = length(_PRIMES_250)
    dimension <= max_dim || throw(ArgumentError(
        "dimension $dimension exceeds the maximum supported ($max_dim)"))

    rng = isnothing(seed) ? Random.default_rng() : MersenneTwister(seed)
    primes = _PRIMES_250[1:dimension]
    shift = randomize ? rand(rng, dimension) : zeros(dimension)

    # Build permutations for the generalized Halton sequence
    permutations = Vector{Vector{Int}}(undef, dimension)
    if generalize
        for j in 1:dimension
            p = primes[j]
            # Random permutation of {0, 1, ..., p-1} that fixes 0
            perm = collect(0:(p - 1))
            # Shuffle elements 2:end (keep 0 in place)
            for k in p:-1:2
                r = rand(rng, 1:k)
                perm[k], perm[r] = perm[r], perm[k]
            end
            permutations[j] = perm
        end
    else
        for j in 1:dimension
            permutations[j] = collect(0:(primes[j] - 1))  # identity
        end
    end

    return Halton(dimension, randomize, generalize, primes, shift, permutations,
        rng, "StdUniform")
end

# ──────────────────────────────────────────────────────────────────────────────
# Van der Corput sequence in an arbitrary base with optional digit permutation
# ──────────────────────────────────────────────────────────────────────────────
"""
    _van_der_corput(n::Int, base::Int, perm::Vector{Int})

Compute the first `n` values (indices 0, ..., n-1) of the van der Corput
sequence in the given `base`, applying digit permutation `perm`.
Returns a `Vector{Float64}` with values in [0, 1).
"""
function _van_der_corput(n::Int, base::Int, perm::Vector{Int})
    result = Vector{Float64}(undef, n)
    inv_base = 1.0 / base

    @inbounds for i in 0:(n - 1)
        val = 0.0
        factor = inv_base
        idx = i
        while idx > 0
            digit = idx % base
            val += perm[digit + 1] * factor   # perm is 1-indexed, stores 0-based values
            factor *= inv_base
            idx = div(idx, base)
        end
        result[i + 1] = val
    end

    return result
end

# ──────────────────────────────────────────────────────────────────────────────
# gen_samples
# ──────────────────────────────────────────────────────────────────────────────
"""
    gen_samples(dd::Halton, n::Int)

Generate the first `n` points of the (generalized, shifted) Halton sequence.
Returns an `n × d` matrix with values in [0, 1).
"""
function gen_samples(dd::Halton, n::Int)
    n > 0 || throw(ArgumentError("n must be positive, got $n"))
    d = dd.dimension

    # Regenerate shift for each call when randomized
    if dd.randomize
        dd.shift .= rand(dd.rng, d)
    end

    x = Matrix{Float64}(undef, n, d)

    for j in 1:d
        col = _van_der_corput(n, dd.primes[j], dd.permutations[j])
        if dd.randomize
            sj = dd.shift[j]
            @inbounds for i in 1:n
                x[i, j] = mod(col[i] + sj, 1.0)
            end
        else
            @inbounds for i in 1:n
                x[i, j] = col[i]
            end
        end
    end

    return x
end

function Base.show(io::IO, dd::Halton)
    print(io, "Halton(d=$(dd.dimension), randomize=$(dd.randomize), generalize=$(dd.generalize))")
end
