"""
    DigitalNetB2(dimension::Int; randomize="LMS_DS", seed=nothing, graycode=true, replications=nothing)

Digital net in base 2 (Sobol' sequence) with optional scrambling.

Generates Sobol' points using the published Joe-Kuo direction numbers,
supporting up to 1024 dimensions and 2^32 points.

# Randomization options
- `"LMS_DS"`: linear matrix scramble followed by a digital shift (default).
- `"DS"`: digital shift only (XOR with random integers).
- `"none"`: no randomization (deterministic Sobol' points).

# Arguments
- `dimension::Int`: number of dimensions (up to 1024).
- `randomize::String`: randomization method.
- `seed`: optional RNG seed for reproducibility.
- `graycode::Bool=true`: use Gray-code ordering for efficiency.
- `replications::Union{Nothing,Int}=nothing`: number of independent randomizations.
  If set, `gen_samples` returns an `R × n × d` array.

# Examples
```julia
dn = DigitalNetB2(3; seed=7)
x = gen_samples(dn, 1024)  # 1024×3 scrambled Sobol' points

dn_r = DigitalNetB2(3; seed=7, replications=16)
x = gen_samples(dn_r, 1024)  # 16×1024×3 array

# High-dimensional problems
dn_hd = DigitalNetB2(52; seed=42)
x = gen_samples(dn_hd, 4096)  # 4096×52 for e.g. Asian option with 52 timesteps
```
"""

const _SOBOL_BITS = 32

# ──────────────────────────────────────────────────────────────────────────────
# Load precomputed direction numbers from data file
# The data file defines _JK_DIRECTION_MATRIX (flat UInt32 array),
# _JK_DIRECTION_MATRIX_DIMS, and _JK_DIRECTION_MATRIX_BITS.
# ──────────────────────────────────────────────────────────────────────────────

"""
    _load_direction_numbers(ndim::Int) -> Matrix{UInt32}

Load the precomputed Joe-Kuo direction numbers for dimensions 1..ndim.
Returns a ndim × 32 matrix V where V[j,k] is the k-th direction number
for dimension j, already left-shifted so that the point value is V/2^32.
"""
function _load_direction_numbers(ndim::Int)
    B = _SOBOL_BITS
    V = Matrix{UInt32}(undef, ndim, B)
    @inbounds for j in 1:ndim
        base = (j - 1) * B
        for k in 1:B
            V[j, k] = _JK_DIRECTION_MATRIX[base + k]
        end
    end
    return V
end

# ──────────────────────────────────────────────────────────────────────────────
# Struct
# ──────────────────────────────────────────────────────────────────────────────
"""
    DigitalNetB2 <: AbstractDiscreteDistribution

Digital net in base 2 (Sobol' sequence) with optional scrambling.
Supports up to 1024 dimensions using Joe-Kuo direction numbers.
See the outer constructor for full documentation.
"""
mutable struct DigitalNetB2 <: AbstractDiscreteDistribution
    dimension::Int
    randomize::String
    graycode::Bool
    rng::AbstractRNG
    direction_nums::Matrix{UInt32}   # ndim × BITS
    mimics::String
    replications::Union{Nothing,Int}
end

function DigitalNetB2(dimension::Int; randomize::String="LMS_DS", seed=nothing,
                      graycode::Bool=true, replications::Union{Nothing,Int}=nothing)
    dimension > 0 || throw(ArgumentError("dimension must be positive, got $dimension"))
    dimension <= _JK_DIRECTION_MATRIX_DIMS || throw(ArgumentError(
        "dimension $dimension exceeds the maximum supported ($_JK_DIRECTION_MATRIX_DIMS)"))
    randomize in ("LMS_DS", "DS", "none") || throw(ArgumentError(
        "randomize must be \"LMS_DS\", \"DS\", or \"none\", got \"$randomize\""))
    if !isnothing(replications)
        replications > 0 || throw(ArgumentError("replications must be positive"))
    end

    rng = isnothing(seed) ? Random.default_rng() : MersenneTwister(seed)
    V = _load_direction_numbers(dimension)

    return DigitalNetB2(dimension, randomize, graycode, rng, V, "StdUniform", replications)
end

# ──────────────────────────────────────────────────────────────────────────────
# Digital shift: XOR each column with a random UInt32
# ──────────────────────────────────────────────────────────────────────────────
function _digital_shift!(pts::Matrix{UInt32}, rng::AbstractRNG)
    d = size(pts, 2)
    shifts = rand(rng, UInt32, d)
    @inbounds for j in 1:d
        sj = shifts[j]
        for i in axes(pts, 1)
            pts[i, j] = xor(pts[i, j], sj)
        end
    end
end

# ──────────────────────────────────────────────────────────────────────────────
# Linear matrix scramble
# ──────────────────────────────────────────────────────────────────────────────
function _linear_matrix_scramble!(pts::Matrix{UInt32}, rng::AbstractRNG)
    B = _SOBOL_BITS
    n, d = size(pts)
    for j in 1:d
        L = Vector{UInt32}(undef, B)
        for k in 1:B
            diag_bit = UInt32(1) << (B - k)
            below_mask = diag_bit - UInt32(1)
            L[k] = diag_bit | (rand(rng, UInt32) & below_mask)
        end

        @inbounds for i in 1:n
            v = pts[i, j]
            newv = UInt32(0)
            for k in 1:B
                t = v & L[k]
                t = xor(t, t >> 16)
                t = xor(t, t >> 8)
                t = xor(t, t >> 4)
                t = xor(t, t >> 2)
                t = xor(t, t >> 1)
                if t & UInt32(1) == UInt32(1)
                    newv |= UInt32(1) << (B - k)
                end
            end
            pts[i, j] = newv
        end
    end
end

# ──────────────────────────────────────────────────────────────────────────────
# Generate Sobol points in integer form
# ──────────────────────────────────────────────────────────────────────────────
function _sobol_points_uint(dd::DigitalNetB2, n::Int)
    B = _SOBOL_BITS
    d = dd.dimension
    V = dd.direction_nums
    pts = zeros(UInt32, n, d)

    if dd.graycode
        @inbounds for i in 1:n-1
            c = trailing_zeros(~UInt32(i - 1)) + 1
            c = min(c, B)
            for j in 1:d
                pts[i+1, j] = xor(pts[i, j], V[j, c])
            end
        end
    else
        @inbounds for i in 1:n-1
            gray_idx = UInt32(i)
            for j in 1:d
                val = UInt32(0)
                gi = gray_idx
                k = 1
                while gi != 0 && k <= B
                    if gi & UInt32(1) == UInt32(1)
                        val = xor(val, V[j, k])
                    end
                    gi >>= 1
                    k += 1
                end
                pts[i+1, j] = val
            end
        end
    end

    return pts
end

# ──────────────────────────────────────────────────────────────────────────────
# Convert UInt32 points to Float64 in [0,1)
# ──────────────────────────────────────────────────────────────────────────────
function _uint_to_float(pts::Matrix{UInt32}, d::Int)
    n = size(pts, 1)
    scale = 1.0 / (Float64(UInt32(1) << 16) * Float64(UInt32(1) << 16))  # 1/2^32
    x = Matrix{Float64}(undef, n, d)
    @inbounds for j in 1:d
        for i in 1:n
            x[i, j] = Float64(pts[i, j]) * scale
        end
    end
    return x
end

# ──────────────────────────────────────────────────────────────────────────────
# Single-replication sample generation
# ──────────────────────────────────────────────────────────────────────────────
function _gen_single_replication(dd::DigitalNetB2, n::Int)
    pts = _sobol_points_uint(dd, n)

    if dd.randomize == "LMS_DS"
        _linear_matrix_scramble!(pts, dd.rng)
        _digital_shift!(pts, dd.rng)
    elseif dd.randomize == "DS"
        _digital_shift!(pts, dd.rng)
    end

    return _uint_to_float(pts, dd.dimension)
end

# ──────────────────────────────────────────────────────────────────────────────
# Public gen_samples
# ──────────────────────────────────────────────────────────────────────────────
"""
    gen_samples(dd::DigitalNetB2, n::Int)

Generate `n` Sobol' points in `d` dimensions.  Returns an `n × d` matrix
with values in [0, 1).  If `replications` was set, returns an `R × n × d` array.
`n` should be a power of 2 for optimal equidistribution.
"""
function gen_samples(dd::DigitalNetB2, n::Int)
    n > 0 || throw(ArgumentError("n must be positive, got $n"))

    if isnothing(dd.replications)
        return _gen_single_replication(dd, n)
    else
        R = dd.replications
        result = Array{Float64,3}(undef, R, n, dd.dimension)
        for r in 1:R
            result[r, :, :] = _gen_single_replication(dd, n)
        end
        return result
    end
end

function Base.show(io::IO, dd::DigitalNetB2)
    rep_str = isnothing(dd.replications) ? "" : ", R=$(dd.replications)"
    print(io, "DigitalNetB2(d=$(dd.dimension), randomize=\"$(dd.randomize)\", graycode=$(dd.graycode)$rep_str)")
end
