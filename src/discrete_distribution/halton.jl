"""
    Halton(dimension::Int; randomize=true, seed=nothing, generalize=true, replications=nothing)

Halton sequence based on van der Corput sequences in successive prime bases.

The ``j``-th coordinate uses the ``j``-th prime number as its base.  With
`randomize=true` a random shift ``\\Delta_j \\sim U[0,1)`` is added (mod 1)
to each coordinate independently.

When `generalize=true`, a per-dimension permutation of digits is applied
(generalized Halton / Faure permutation style) to improve uniformity in
higher dimensions.

This generator currently relies on the QMCToolsCL shared library. Install
`qmctoolscl` into a Python visible to Julia, or set `ENV["QMC_PYTHON"]`
before `using QMC`.

# Arguments
- `dimension::Int`: number of dimensions (up to 250).
- `randomize::Bool=true`: apply random shift randomization.
- `seed`: optional RNG seed for reproducibility.
- `generalize::Bool=true`: apply generalized digit permutations.
- `replications`: `nothing` (default) returns an `n × d` matrix; an integer `R`
  returns an `R × n × d` array of `R` independently randomized copies (matching
  `Lattice`/`DigitalNetB2`).

# Examples
```julia
hal = Halton(5; seed=42)
x = gen_samples(hal, 1000)  # 1000×5 matrix
```
"""

# ──────────────────────────────────────────────────────────────────────────────
# Struct
# ──────────────────────────────────────────────────────────────────────────────
"""
    Halton <: AbstractDiscreteDistribution

Halton sequence backed by the QMCToolsCL `halton_qrng` C function.
Supports up to 250 dimensions.  See the outer constructor for full documentation.

QMCToolsCL is required for sample generation.
"""
mutable struct Halton{R <: AbstractRNG} <: AbstractDiscreteDistribution
    dimension::Int
    randomize::Bool
    generalize::Bool
    replications::Union{Nothing, Int}
    rng::R
    mimics::String
end

function Halton(
    dimension::Int;
    randomize::Bool=true,
    seed=nothing,
    generalize::Bool=true,
    replications=nothing,
)
    dimension > 0 || throw(ArgumentError("dimension must be positive, got $dimension"))
    dimension <= 250 ||
        throw(ArgumentError("dimension $dimension exceeds the maximum supported (250)"))
    if replications !== nothing
        (replications isa Integer && replications >= 1) ||
            throw(ArgumentError("replications must be a positive integer or nothing"))
    end
    rng = isnothing(seed) ? Random.default_rng() : MersenneTwister(seed)
    return Halton(dimension, randomize, generalize, replications, rng, "StdUniform")
end

# ──────────────────────────────────────────────────────────────────────────────
# gen_samples
# ──────────────────────────────────────────────────────────────────────────────
"""
    gen_samples(dd::Halton, n::Int)

Generate the first `n` points of the (generalized, shifted) Halton sequence.
Returns an `n × d` matrix with values in [0, 1) when `replications` is `nothing`,
or an `R × n × d` array of `R` independently randomized copies when
`replications = R` (matching the `Lattice`/`DigitalNetB2` convention).
"""
function gen_samples(dd::Halton, n::Int; n_start::Int=0)
    n > 0 || throw(ArgumentError("n must be positive, got $n"))
    d = dd.dimension
    gen = dd.generalize ? 1 : 0
    dvec = Int32[i for i in 0:(d - 1)]
    R = isnothing(dd.replications) ? 1 : dd.replications

    res = Vector{Float64}(undef, d * n)
    # randu_d_32: d×32 random doubles encoding the per-dimension shift.
    # Pass zeros for no randomization (deterministic sequence).
    _draw_shift() = dd.randomize ? rand(dd.rng, d * 32) : zeros(d * 32)

    if R == 1
        _c_halton_qrng!(n, d, n_start, gen, res, _draw_shift(), dvec)
        # halton_qrng writes res[j*n + i] for 0-indexed dim j and point i.
        # This is identical to Julia column-major layout for an n×d matrix.
        return reshape(res, n, d)
    end

    # R independent randomizations, each with a fresh shift, stacked R×n×d.
    out = Array{Float64}(undef, R, n, d)
    @inbounds for r in 1:R
        _c_halton_qrng!(n, d, n_start, gen, res, _draw_shift(), dvec)
        out[r, :, :] .= reshape(res, n, d)
    end
    return out
end

function Base.show(io::IO, dd::Halton)
    print(
        io,
        "Halton(d=$(dd.dimension), randomize=$(dd.randomize), generalize=$(dd.generalize), replications=$(dd.replications))",
    )
end
