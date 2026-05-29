"""
    DigitalNetB2(dimension::Int; randomize="LMS_DS", seed=nothing, graycode=true, replications=nothing)

Digital net in base 2 (Sobol' sequence) with optional scrambling.

Generates Sobol' points using the published Joe-Kuo direction numbers,
supporting up to 1024 dimensions and 2^32 points.

This generator currently relies on the QMCToolsCL shared library. Install
`qmctoolscl` into a Python visible to Julia, or set `ENV["QMC_PYTHON"]`
before `using QMC`.

# Randomization options
- `"LMS_DS"`: linear matrix scramble followed by a digital shift (default).
- `"DS"`: digital shift only (XOR with random integers).
- `"NUS"`: nested uniform scrambling (Owen scrambling).
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

QMCToolsCL is required for sample generation.
"""
mutable struct DigitalNetB2 <: AbstractDiscreteDistribution
    dimension::Int
    randomize::String
    graycode::Bool
    rng::AbstractRNG
    direction_nums::Matrix{UInt32}   # ndim × BITS
    mimics::String
    replications::Union{Nothing, Int}
end

function DigitalNetB2(dimension::Int; randomize::String = "LMS_DS", seed = nothing,
        graycode::Bool = true, replications::Union{Nothing, Int} = nothing)
    dimension > 0 || throw(ArgumentError("dimension must be positive, got $dimension"))
    dimension <= _JK_DIRECTION_MATRIX_DIMS || throw(ArgumentError(
        "dimension $dimension exceeds the maximum supported ($_JK_DIRECTION_MATRIX_DIMS)"))
    randomize in ("LMS_DS", "DS", "NUS", "none") || throw(ArgumentError(
        "randomize must be \"LMS_DS\", \"DS\", \"NUS\", or \"none\", got \"$randomize\""))
    if !isnothing(replications)
        replications > 0 || throw(ArgumentError("replications must be positive"))
    end

    rng = isnothing(seed) ? Random.default_rng() : MersenneTwister(seed)
    V = _load_direction_numbers(dimension)

    return DigitalNetB2(dimension, randomize, graycode, rng, V, "StdUniform", replications)
end

# ──────────────────────────────────────────────────────────────────────────────
# Matrix-space linear matrix scramble (LMS) over GF(2)
#
# Applies a random lower-triangular 32×32 matrix L (independent per dimension)
# to each column of the generating matrix V, producing a scrambled copy in
# which each direction number V[j,b] is replaced by L_j * V[j,b] over GF(2).
#
# This is mathematically equivalent to applying the same L_j to every Sobol'
# point in dimension j, but operates in matrix space so the result can be
# passed directly to dnb2_gen_gray_float.
#
# Returns a d × mmax Matrix{UInt64}.
# ──────────────────────────────────────────────────────────────────────────────
function _lms_direction_matrix(V::Matrix{UInt32}, d::Int, rng::AbstractRNG)
    mmax = size(V, 2)
    V_scr = Matrix{UInt64}(undef, d, mmax)
    for j in 1:d
        # Random lower-triangular matrix L over GF(2): L[k] is row k,
        # with the diagonal bit at position (mmax-k) and random bits below it.
        L = Vector{UInt32}(undef, mmax)
        for k in 1:mmax
            diag_bit = UInt32(1) << (mmax - k)
            below_mask = diag_bit - UInt32(1)
            L[k] = diag_bit | (rand(rng, UInt32) & below_mask)
        end
        for b in 1:mmax
            v = V[j, b]
            newv = UInt32(0)
            for k in 1:mmax
                # Bit k of L*v = parity(L[k] & v)
                t = L[k] & v
                t = xor(t, t >> 16)
                t = xor(t, t >> 8)
                t = xor(t, t >> 4)
                t = xor(t, t >> 2)
                t = xor(t, t >> 1)
                if t & UInt32(1) == UInt32(1)
                    newv |= UInt32(1) << (mmax - k)
                end
            end
            V_scr[j, b] = UInt64(newv)
        end
    end
    return V_scr
end

# ──────────────────────────────────────────────────────────────────────────────
# Build the flat C-array for dnb2_gen_gray_float from a d×mmax direction matrix.
# Layout: C_flat[l_x*d*mmax + j*mmax + b + 1] = V_mat[j+1, b+1] (row-major).
# ──────────────────────────────────────────────────────────────────────────────
function _direction_matrix_to_C(V_mat::AbstractMatrix{T}, d::Int) where {T}
    mmax = size(V_mat, 2)
    C_flat = Vector{UInt64}(undef, d * mmax)
    for j in 1:d, b in 1:mmax
        C_flat[(j - 1) * mmax + (b - 1) + 1] = UInt64(V_mat[j, b])
    end
    return C_flat
end

# ──────────────────────────────────────────────────────────────────────────────
# Single-replication and multi-replication generation via qmctoolscl binary net
# generation, optional digital shifts, and integer-to-float conversion.
# ──────────────────────────────────────────────────────────────────────────────
function _gen_single_replication(dd::DigitalNetB2, n::Int; n_start::Int = 0)
    d = dd.dimension
    mmax = _SOBOL_BITS
    V = dd.direction_nums

    if dd.randomize == "LMS_DS"
        V_scr = _lms_direction_matrix(V, d, dd.rng)
        C_flat = _direction_matrix_to_C(V_scr, d)
        lshifts = zeros(UInt64, 1)
        shiftsb = UInt64.(rand(dd.rng, UInt32, d))
        apply_shift = 0x01
    elseif dd.randomize == "DS"
        C_flat = _direction_matrix_to_C(V, d)
        lshifts = zeros(UInt64, 1)
        shiftsb = UInt64.(rand(dd.rng, UInt32, d))
        apply_shift = 0x01
    elseif dd.randomize == "NUS"
        C_flat = _direction_matrix_to_C(V, d)
        # Generate per-dimension seeds for Owen scrambling
        dim_seeds = UInt64.(rand(dd.rng, UInt64, d))

        xb_buf = Vector{UInt64}(undef, n * d)
        if dd.graycode
            _c_dnb2_gen_gray!(1, n, d, n_start, mmax, C_flat, xb_buf)
        else
            _c_dnb2_gen_natural!(1, n, d, n_start, mmax, C_flat, xb_buf)
        end

        # Apply Owen scrambling in-place
        _owen_scramble_points!(xb_buf, n, d, mmax, dim_seeds)

        tmaxes = fill(UInt64(mmax), 1)
        x_buf = Vector{Float64}(undef, n * d)
        _c_dnb2_integer_to_float!(1, n, d, tmaxes, xb_buf, x_buf)
        return _rowmaj_to_nxd(x_buf, n, d)
    else  # "none"
        C_flat = _direction_matrix_to_C(V, d)
        lshifts = zeros(UInt64, 1)
        shiftsb = zeros(UInt64, d)
        apply_shift = 0x00
    end

    xb_buf = Vector{UInt64}(undef, n * d)
    if dd.graycode
        _c_dnb2_gen_gray!(1, n, d, n_start, mmax, C_flat, xb_buf)
    else
        _c_dnb2_gen_natural!(1, n, d, n_start, mmax, C_flat, xb_buf)
    end

    xrb_buf = Vector{UInt64}(undef, n * d)
    _c_dnb2_digital_shift!(1, n, d, 1, lshifts, xb_buf, shiftsb, xrb_buf)

    tmaxes = fill(UInt64(mmax), 1)
    x_buf = Vector{Float64}(undef, n * d)
    _c_dnb2_integer_to_float!(1, n, d, tmaxes, xrb_buf, x_buf)
    return _rowmaj_to_nxd(x_buf, n, d)
end

"""
    gen_samples(dd::DigitalNetB2, n::Int)

Generate `n` Sobol' points in `d` dimensions.  Returns an `n × d` matrix
with values in [0, 1).  If `replications` was set, returns an `R × n × d` array.
`n` should be a power of 2 for optimal equidistribution.
"""
function gen_samples(dd::DigitalNetB2, n::Int; n_start::Int = 0)
    n > 0 || throw(ArgumentError("n must be positive, got $n"))
    n_start >= 0 || throw(ArgumentError("n_start must be non-negative"))

    if isnothing(dd.replications)
        return _gen_single_replication(dd, n; n_start=n_start)
    end

    R = dd.replications
    d = dd.dimension
    mmax = _SOBOL_BITS
    V = dd.direction_nums

    if dd.randomize == "LMS_DS"
        # Build R independently scrambled generating matrices (r_x = R)
        C_flat = Vector{UInt64}(undef, R * d * mmax)
        for r in 1:R
            V_scr = _lms_direction_matrix(V, d, dd.rng)
            base = (r - 1) * d * mmax
            for j in 1:d, b in 1:mmax
                C_flat[base + (j - 1) * mmax + (b - 1) + 1] = UInt64(V_scr[j, b])
            end
        end
        r_x = R
        lshifts = zeros(UInt64, R)
        shiftsb = UInt64.(rand(dd.rng, UInt32, R * d))
        apply_shift = 0x01
    elseif dd.randomize == "DS"
        C_flat = _direction_matrix_to_C(V, d)
        r_x = 1
        lshifts = zeros(UInt64, 1)
        shiftsb = UInt64.(rand(dd.rng, UInt32, R * d))
        apply_shift = 0x01
    elseif dd.randomize == "NUS"
        C_flat = _direction_matrix_to_C(V, d)
        # Generate unscrambled binary points (single set)
        xb_base = Vector{UInt64}(undef, n * d)
        if dd.graycode
            _c_dnb2_gen_gray!(1, n, d, n_start, mmax, C_flat, xb_base)
        else
            _c_dnb2_gen_natural!(1, n, d, n_start, mmax, C_flat, xb_base)
        end
        # Apply R independent Owen scramblings
        x_buf = Vector{Float64}(undef, R * n * d)
        tmaxes_one = fill(UInt64(mmax), 1)
        for r in 1:R
            xb_copy = copy(xb_base)
            dim_seeds = UInt64.(rand(dd.rng, UInt64, d))
            _owen_scramble_points!(xb_copy, n, d, mmax, dim_seeds)
            x_r = Vector{Float64}(undef, n * d)
            _c_dnb2_integer_to_float!(1, n, d, tmaxes_one, xb_copy, x_r)
            base = (r - 1) * n * d
            x_buf[base+1:base+n*d] .= x_r
        end
        return _rowmaj_to_Rnxd(x_buf, R, n, d)
    else  # "none"
        C_flat = _direction_matrix_to_C(V, d)
        r_x = 1
        lshifts = zeros(UInt64, 1)
        shiftsb = zeros(UInt64, R * d)
        apply_shift = 0x00
    end

    xb_buf = Vector{UInt64}(undef, r_x * n * d)
    if dd.graycode
        _c_dnb2_gen_gray!(r_x, n, d, n_start, mmax, C_flat, xb_buf)
    else
        _c_dnb2_gen_natural!(r_x, n, d, n_start, mmax, C_flat, xb_buf)
    end

    xrb_buf = Vector{UInt64}(undef, R * n * d)
    _c_dnb2_digital_shift!(R, n, d, r_x, lshifts, xb_buf, shiftsb, xrb_buf)

    tmaxes = fill(UInt64(mmax), R)
    x_buf = Vector{Float64}(undef, R * n * d)
    _c_dnb2_integer_to_float!(R, n, d, tmaxes, xrb_buf, x_buf)
    return _rowmaj_to_Rnxd(x_buf, R, n, d)
end

function Base.show(io::IO, dd::DigitalNetB2)
    rep_str = isnothing(dd.replications) ? "" : ", R=$(dd.replications)"
    print(io,
        "DigitalNetB2(d=$(dd.dimension), randomize=\"$(dd.randomize)\", graycode=$(dd.graycode)$rep_str)")
end

# ──────────────────────────────────────────────────────────────────────────────
# Owen / Nested Uniform Scrambling (NUS)
#
# Implements Owen (1995) scrambling using a hash-based approach: the random
# bit flip at each node of the scrambling tree is determined by hashing
# (dim_seed, depth, prefix). This is mathematically equivalent to generating
# a full random tree but uses O(1) memory per dimension.
# ──────────────────────────────────────────────────────────────────────────────

"""
    _owen_scramble_value(x::UInt64, dim_seed::UInt64, mmax::Int) -> UInt64

Apply Owen scrambling to a single UInt64 digital net point value in one
dimension. The point is stored with digit 1 at bit position `mmax-1` (MSB).

The scrambling uses Julia's `hash` as a pseudo-random function, keyed by
`dim_seed`, to determine the random bit flip at each node of the binary
tree. This is the Matousek-style hash-based construction.
"""
function _owen_scramble_value(x::UInt64, dim_seed::UInt64, mmax::Int)
    result = UInt64(0)
    prefix = UInt64(0)
    @inbounds for k in 0:(mmax - 1)
        bit_pos = mmax - 1 - k
        digit = (x >> bit_pos) & UInt64(1)
        # Hash-based flip: deterministic from (dim_seed, depth, prefix)
        h = hash((dim_seed, UInt64(k), prefix))
        flip = h & UInt64(1)
        new_digit = xor(digit, flip)
        result |= (new_digit << bit_pos)
        prefix = (prefix << 1) | new_digit
    end
    return result
end

"""
    _owen_scramble_points!(xb::Vector{UInt64}, n::Int, d::Int, mmax::Int,
                           dim_seeds::Vector{UInt64})

Apply Owen scrambling in-place to binary digital net points stored in
row-major order: `xb[i*d + j + 1]` (0-indexed i=point, j=dimension).
`dim_seeds` has length `d`, one per dimension.
"""
function _owen_scramble_points!(xb::Vector{UInt64}, n::Int, d::Int,
        mmax::Int, dim_seeds::Vector{UInt64})
    @inbounds for i in 0:(n - 1)
        for j in 0:(d - 1)
            idx = i * d + j + 1
            xb[idx] = _owen_scramble_value(xb[idx], dim_seeds[j + 1], mmax)
        end
    end
end
