"""
    DigitalNetB2(dimension::Int; randomize="LMS_DS", seed=nothing, graycode=nothing,
                 order=nothing, replications=nothing, generating_matrices=nothing,
                 t=nothing, alpha=1, msb=nothing)

Digital net in base 2 (Sobol' sequence) with optional scrambling.

Generates Sobol' points using the published Joe-Kuo direction numbers,
supporting up to 21201 raw Sobol' dimensions and 2^32 points with the bundled
Joe-Kuo table (the "new-joe-kuo-6" set, matching QMCPy). When `alpha > 1`, those
raw dimensions are interlaced in groups of `alpha`, so the bundled
effective-dimension limit becomes `floor(21201/alpha)` unless custom generating
matrices are supplied explicitly.

This generator currently relies on the QMCToolsCL shared library. Install
`qmctoolscl` into a Python visible to Julia, or set `ENV["QMC_PYTHON"]`
before the first `Lattice`, `DigitalNetB2`, or `Halton` use.

# Randomization options
- `"LMS_DS"`: linear matrix scramble followed by a digital shift (default).
- `"LMS"`: linear matrix scramble only.
- `"DS"`: digital shift only (XOR with random integers).
- `"NUS"`: nested uniform scrambling (Owen scrambling).
- `"none"`: no randomization (deterministic Sobol' points).

# Arguments
- `dimension::Int`: number of output dimensions. With the bundled Joe-Kuo
  table, the raw Sobol' dimension cap is 21201, so higher-order
  `alpha > 1` nets have a correspondingly lower effective-dimension limit
  unless custom matrices are supplied.
- `randomize::String`: randomization method.
- `seed`: optional RNG seed for reproducibility.
- `graycode::Union{Nothing,Bool}=nothing`: use Gray-code ordering for efficiency.
- `order`: QMCPy-style ordering alias. Accepts `"GRAY"` / `"GRAY CODE"` or
  `"RADICAL INVERSE"` / `"NATURAL"`. If omitted, Julia keeps the historical
  default `graycode=true`.
- `replications::Union{Nothing,Int}=nothing`: number of independent randomizations.
  If set, `gen_samples` returns an `R × n × d` array.
- `generating_matrices`: optional custom direction-number source. May be
  `nothing` (default Joe-Kuo table), a direct integer matrix with at least
  `dimension * alpha` rows and at most 32 columns, or a QMCPy/LDData-style
  `dnet` text file/name/URL. For direct integer matrices, when the custom
  matrix has `m` columns, `gen_samples` supports at most `2^m` points
  including any `n_start` offset, and each entry must already fit within that
  `m`-bit width. LDData-style text files may carry wider source precision
  (up to 64 bits) and their own sample-limit metadata. A string may point to a
  local file, a bare filename (for example `"joe_kuo.6.21201.txt"`), or a
  GitHub/LDData URL. Non-bundled LDData files download on demand.
- `t`: optional number of bits used after randomization / float conversion.
  Must satisfy `t_source <= t <= 64`, where `t_source` is the bit width of the
  generating matrices. If omitted, Julia preserves the historical `t = t_source`
  for standard nets and uses a higher-order default when `alpha > 1`.
- `alpha`: interlacing factor for higher-order digital nets. When `alpha > 1`,
  Julia interlaces `alpha * dimension` underlying Sobol' dimensions into the
  requested output dimension.
- `msb`: optional flag for custom integer matrices. `true` means entries are
  already in the expected most-significant-bit ordering; `false` bit-reverses
  each entry across the generating-matrix bit width before use.

# Examples
```jldoctest
julia> using QMC

julia> discrete_distrib = DigitalNetB2(2; seed=7);

julia> round.(gen_samples(discrete_distrib, 4); digits=8)
4×2 Matrix{Float64}:
 0.84824541  0.354704
 0.34824541  0.854704
 0.59824541  0.104704
 0.09824541  0.604704

julia> round.(gen_samples(discrete_distrib, 1); digits=8) # first point in the sequence
1×2 Matrix{Float64}:
 0.49777094  0.625998
```

```jldoctest
julia> x = gen_samples(DigitalNetB2(3; seed=7, replications=2), 4);

julia> size(x)
(2, 4, 3)
```

```jldoctest
julia> round.(gen_samples(DigitalNetB2(2; randomize="none", order="GRAY"), 2; n_start=2); digits=8)
2×2 Matrix{Float64}:
 0.75  0.25
 0.25  0.75

julia> round.(gen_samples(DigitalNetB2(2; randomize="none", order="RADICAL INVERSE"), 2; n_start=2); digits=8)
2×2 Matrix{Float64}:
 0.25  0.75
 0.75  0.25
```

Typical larger-scale use cases include higher-order interlacing, e.g.
`DigitalNetB2(3; seed=7, alpha=2)` for interlaced Sobol' points, and
high-dimensional settings such as `DigitalNetB2(52; seed=42)` for
path-dependent problems with many timesteps.
"""

const _SOBOL_BITS = 32
const _DEFAULT_DNET_SOURCE_NAME = "joe_kuo.6.21201.txt"
const _DEFAULT_DNET_1024_SOURCE_NAME = "joe_kuo.6.1024.txt"
const _DNET_LDDATA_RAW_BASE = "https://raw.githubusercontent.com/QMCSoftware/LDData/main/dnet/"

# Maximum raw Sobol' dimension available offline. Dimensions 1..1024 come from the
# embedded `_JK_DIRECTION_MATRIX` (a fast path with no file I/O); dimensions
# 1025..21201 come from the bundled compact binary `joe_kuo.6.21201.bin`, whose
# first 1024 dimensions are bit-for-bit identical to the embedded table. Both are
# the "new-joe-kuo-6" direction numbers, matching QMCPy's bundled
# `joe_kuo.6.21201.npy`. Beyond 21201, an explicit larger LDData source is needed.
const _DNET_MAX_SOURCE_DIMS = 21201
const _DNET_EXTENDED_TABLE_FILE = joinpath(@__DIR__, "..", "data", "joe_kuo.6.21201.bin")
# Lazily-loaded, cached flat UInt32 table (dim-major, 21201 × 32), read on first
# use for dimensions above the embedded 1024 so low-dimensional jobs never pay the
# ~2.7 MB read or carry it in the precompiled image.
const _JK_EXTENDED_MATRIX = Ref{Union{Nothing, Vector{UInt32}}}(nothing)

function _extended_direction_matrix()
    cached = _JK_EXTENDED_MATRIX[]
    cached === nothing || return cached
    bytes = read(_DNET_EXTENDED_TABLE_FILE)
    n = length(bytes) ÷ 4
    v = Vector{UInt32}(undef, n)
    @inbounds for i in 1:n
        b = (i - 1) * 4
        # stored little-endian; decode explicitly so the result is host-independent
        v[i] =
            UInt32(bytes[b + 1]) | (UInt32(bytes[b + 2]) << 8) | (UInt32(bytes[b + 3]) << 16) |
            (UInt32(bytes[b + 4]) << 24)
    end
    _JK_EXTENDED_MATRIX[] = v
    return v
end

# ──────────────────────────────────────────────────────────────────────────────
# Load precomputed direction numbers from data file
# The data file defines _JK_DIRECTION_MATRIX (flat UInt32 array),
# _JK_DIRECTION_MATRIX_DIMS, and _JK_DIRECTION_MATRIX_BITS.
# ──────────────────────────────────────────────────────────────────────────────

"""
    _load_direction_numbers(ndim::Int) -> Matrix{UInt64}

Load the precomputed Joe-Kuo direction numbers for dimensions 1..ndim.
Returns a ndim × 32 matrix V where V[j,k] is the k-th direction number
for dimension j, already left-shifted so that the point value is V/2^32.
Dimensions up to $(_JK_DIRECTION_MATRIX_DIMS) use the embedded table; up to
$(_DNET_MAX_SOURCE_DIMS) use the bundled binary extension.
"""
function _load_direction_numbers(ndim::Int)
    B = _SOBOL_BITS
    ndim <= _DNET_MAX_SOURCE_DIMS || throw(
        ArgumentError(
            "dimension $ndim exceeds the maximum bundled Joe-Kuo dimension ($_DNET_MAX_SOURCE_DIMS); supply a larger generating_matrices source explicitly",
        ),
    )
    src =
        ndim <= _JK_DIRECTION_MATRIX_DIMS ? _JK_DIRECTION_MATRIX : _extended_direction_matrix()
    V = Matrix{UInt64}(undef, ndim, B)
    @inbounds for j in 1:ndim
        base = (j - 1) * B
        for k in 1:B
            V[j, k] = UInt64(src[base + k])
        end
    end
    return V
end

function _canonical_digital_net_matrix_filename(name::AbstractString)
    token = replace(strip(name), '\\' => '/')
    token = split(token, '?'; limit=2)[1]
    token = split(token, '#'; limit=2)[1]
    isempty(token) && throw(ArgumentError("generating_matrices reference cannot be empty"))
    parts = split(token, '/')
    basename = parts[end]
    isempty(basename) &&
        throw(ArgumentError("generating_matrices reference \"$name\" has no filename"))
    return endswith(lowercase(basename), ".txt") ? basename : string(basename, ".txt")
end

function _looks_like_lddata_digital_net_reference(name::AbstractString)
    token = lowercase(replace(strip(name), '\\' => '/'))
    isempty(token) && return false
    if !(occursin('/', token) || occursin('\\', name))
        return true
    end
    return (
        occursin("github.com/qmcsoftware/lddata/", token) ||
        occursin("raw.githubusercontent.com/qmcsoftware/lddata/", token) ||
        startswith(token, "dnet/") ||
        occursin("/dnet/", token)
    )
end

function _parse_digital_net_matrix_entry(token::AbstractString, path::AbstractString)
    value = tryparse(BigInt, token)
    isnothing(value) &&
        throw(ArgumentError("invalid generating-matrix entry in \"$path\": \"$token\""))
    return value
end

function _read_digital_net_matrix_file(path::AbstractString, dimension::Int)
    contents = String[]
    for raw_line in eachline(path)
        line = strip(split(raw_line, '#'; limit=2)[1])
        isempty(line) && continue
        push!(contents, line)
    end
    length(contents) >= 4 || throw(
        ArgumentError(
            "generating_matrices file \"$path\" must contain base, d_limit, n_limit, and bit metadata",
        ),
    )
    base = tryparse(Int, contents[1])
    base == 2 ||
        throw(ArgumentError("DigitalNetB2 requires base=2 in \"$path\", got $(contents[1])"))
    d_limit = tryparse(Int, contents[2])
    isnothing(d_limit) && throw(
        ArgumentError(
            "invalid d_limit in generating_matrices file \"$path\": \"$(contents[2])\"",
        ),
    )
    dimension <= d_limit || throw(
        ArgumentError(
            "dimension $dimension exceeds the file-supported maximum ($d_limit) in \"$path\"",
        ),
    )
    n_limit = tryparse(Int, contents[3])
    isnothing(n_limit) && throw(
        ArgumentError(
            "invalid n_limit in generating_matrices file \"$path\": \"$(contents[3])\"",
        ),
    )
    bit_precision = tryparse(Int, contents[4])
    isnothing(bit_precision) && throw(
        ArgumentError(
            "invalid bit precision in generating_matrices file \"$path\": \"$(contents[4])\"",
        ),
    )
    0 < bit_precision <= 64 || throw(
        ArgumentError(
            "DigitalNetB2 currently supports at most 64-bit generating matrices, got $bit_precision in \"$path\"",
        ),
    )
    length(contents) >= 4 + dimension || throw(
        ArgumentError(
            "generating_matrices file \"$path\" contains fewer than $dimension matrix rows",
        ),
    )
    rows = split.(contents[5:(4 + dimension)])
    mmax = length(rows[1])
    mmax > 0 ||
        throw(ArgumentError("generating_matrices file \"$path\" has an empty matrix row"))
    V = Matrix{UInt64}(undef, dimension, mmax)
    max_entry = (BigInt(1) << bit_precision) - 1
    for j in 1:dimension
        length(rows[j]) == mmax || throw(
            ArgumentError(
                "inconsistent generating-matrix row width in \"$path\": expected $mmax columns, got $(length(rows[j])) on row $j",
            ),
        )
        for k in 1:mmax
            value = _parse_digital_net_matrix_entry(rows[j][k], path)
            0 < value <= max_entry || throw(
                ArgumentError(
                    "generating_matrices entry at ($j, $k) in \"$path\" must lie in 1:$max_entry, got $value",
                ),
            )
            try
                V[j, k] = UInt64(value)
            catch err
                if err isa InexactError
                    throw(
                        ArgumentError(
                            "generating_matrices entry at ($j, $k) in \"$path\" cannot be represented as UInt64: $value",
                        ),
                    )
                end
                rethrow()
            end
        end
    end
    return V, n_limit, bit_precision
end

function _download_digital_net_matrix_from_lddata(filename::AbstractString, dimension::Int)
    url = _DNET_LDDATA_RAW_BASE * filename
    path, io = mktemp()
    close(io)
    try
        _downloads_module().download(url, path)
        return _read_digital_net_matrix_file(path, dimension)
    catch err
        msg = sprint(showerror, err)
        throw(
            ArgumentError(
                "failed to fetch LDData digital-net generating matrices \"$filename\" from $url: $msg",
            ),
        )
    finally
        isfile(path) && rm(path; force=true)
    end
end

# ──────────────────────────────────────────────────────────────────────────────
# Struct
# ──────────────────────────────────────────────────────────────────────────────
"""
    DigitalNetB2 <: AbstractDiscreteDistribution

Digital net in base 2 (Sobol' sequence) with optional scrambling.
Supports up to 21201 raw Sobol' dimensions when using the bundled Joe-Kuo
direction numbers.
See the outer constructor for full documentation.

QMCToolsCL is required for sample generation.
"""
mutable struct DigitalNetB2{R <: AbstractRNG} <: AbstractDiscreteDistribution
    dimension::Int
    randomize::String
    graycode::Bool
    t::Int
    alpha::Int
    source_bits::Int
    rng::R
    direction_nums::Matrix{UInt64}   # raw ndim × mmax generating matrices
    n_limit::Union{Nothing, Int}
    mimics::String
    replications::Union{Nothing, Int}
end

function _normalize_digital_net_randomize(randomize)
    token = randomize isa Symbol ? String(randomize) : randomize
    token isa AbstractString ||
        throw(ArgumentError("randomize must be a string or symbol, got $(typeof(randomize))"))
    token_lc = replace(lowercase(strip(token)), "-" => "_", " " => "_")
    if token_lc == "lms_ds"
        return "LMS_DS"
    elseif token_lc == "lms"
        return "LMS"
    elseif token_lc == "ds"
        return "DS"
    elseif token_lc in ("nus", "owen")
        return "NUS"
    elseif token_lc == "true"
        return "LMS_DS"
    elseif token_lc in ("none", "false", "no")
        return "none"
    end
    throw(
        ArgumentError(
            "randomize must be \"LMS_DS\", \"LMS\", \"DS\", \"NUS\", or \"none\", got \"$randomize\"",
        ),
    )
end

function _normalize_digital_net_order(order)
    token = order isa Symbol ? String(order) : order
    token isa AbstractString ||
        throw(ArgumentError("order must be a string or symbol, got $(typeof(order))"))
    token_lc = replace(lowercase(strip(token)), "_" => " ", "-" => " ")
    token_lc == "gray code" && return true
    token_lc == "gray" && return true
    token_lc == "natural" && return false
    token_lc == "radical inverse" && return false
    throw(
        ArgumentError(
            "order must be \"GRAY\" or \"RADICAL INVERSE\" (\"NATURAL\" is accepted as an alias), got \"$order\"",
        ),
    )
end

function _coerce_direction_matrix(values::AbstractMatrix{<:Integer}, dimension::Int)
    size(values, 1) >= dimension || throw(
        ArgumentError(
            "generating_matrices must have at least $dimension rows, got $(size(values, 1))",
        ),
    )
    mmax = size(values, 2)
    0 < mmax <= _SOBOL_BITS || throw(
        ArgumentError(
            "generating_matrices must have between 1 and $_SOBOL_BITS columns, got $mmax",
        ),
    )
    V = Matrix{UInt64}(undef, dimension, mmax)
    max_entry = (BigInt(1) << mmax) - 1
    for j in 1:dimension, k in 1:mmax
        value = values[j, k]
        value > 0 || throw(
            ArgumentError(
                "generating_matrices entries must be positive, got $value at ($j, $k)",
            ),
        )
        value <= max_entry || throw(
            ArgumentError(
                "generating_matrices entry at ($j, $k) must fit within $mmax bits, got $value",
            ),
        )
        try
            V[j, k] = UInt64(value)
        catch err
            if err isa InexactError
                throw(
                    ArgumentError(
                        "generating_matrices entry at ($j, $k) cannot be represented as UInt64: $value",
                    ),
                )
            end
            rethrow()
        end
    end
    return V, Int(1) << mmax, mmax
end

_bitreverse_width(value::UInt64, width::Int) = bitreverse(value) >> (64 - width)

function _coerce_direction_matrix(
    values::AbstractMatrix{<:Integer},
    dimension::Int,
    msb::Union{Nothing, Bool},
)
    V, n_limit, t_source = _coerce_direction_matrix(values, dimension)
    if msb === false
        width = size(V, 2)
        @inbounds for j in axes(V, 1), k in axes(V, 2)
            V[j, k] = _bitreverse_width(V[j, k], width)
        end
    end
    return V, n_limit, t_source
end

function _resolve_direction_numbers(dimension::Int, generating_matrices, msb)
    if isnothing(generating_matrices)
        return _load_direction_numbers(dimension), Int(1) << _SOBOL_BITS, _SOBOL_BITS
    elseif generating_matrices isa AbstractMatrix{<:Integer}
        return _coerce_direction_matrix(generating_matrices, dimension, msb)
    elseif generating_matrices isa AbstractString
        if isfile(generating_matrices)
            return _read_digital_net_matrix_file(generating_matrices, dimension)
        end
        _looks_like_lddata_digital_net_reference(generating_matrices) ||
            throw(ArgumentError("generating_matrices file \"$generating_matrices\" not found"))
        filename = _canonical_digital_net_matrix_filename(generating_matrices)
        # The default Joe-Kuo sources are bundled offline: the 21201 table via the
        # embedded + binary tables, the 1024 table via the embedded one. Other
        # LDData names (and dimensions past what is bundled) download on demand.
        if filename == _DEFAULT_DNET_SOURCE_NAME && dimension <= _DNET_MAX_SOURCE_DIMS
            return _load_direction_numbers(dimension), Int(1) << _SOBOL_BITS, _SOBOL_BITS
        elseif filename == _DEFAULT_DNET_1024_SOURCE_NAME &&
               dimension <= _JK_DIRECTION_MATRIX_DIMS
            return _load_direction_numbers(dimension), Int(1) << _SOBOL_BITS, _SOBOL_BITS
        end
        return _download_digital_net_matrix_from_lddata(filename, dimension)
    end
    throw(
        ArgumentError(
            "generating_matrices must be nothing, an integer matrix with direction numbers, a local LDData-format text file, or an LDData filename/URL",
        ),
    )
end

function DigitalNetB2(
    dimension::Int;
    randomize="LMS_DS",
    seed=nothing,
    graycode::Union{Nothing, Bool}=nothing,
    order=nothing,
    replications::Union{Nothing, Int}=nothing,
    generating_matrices=nothing,
    t=nothing,
    alpha::Int=1,
    msb=nothing,
)
    dimension > 0 || throw(ArgumentError("dimension must be positive, got $dimension"))
    alpha > 0 || throw(ArgumentError("alpha must be positive, got $alpha"))
    raw_dimension = Base.checked_mul(dimension, alpha)
    isnothing(generating_matrices) &&
        raw_dimension > _DNET_MAX_SOURCE_DIMS &&
        throw(
            ArgumentError(
                "dimension $dimension with alpha=$alpha requires $raw_dimension raw dimensions, exceeding the maximum bundled ($_DNET_MAX_SOURCE_DIMS); supply a larger generating_matrices source explicitly",
            ),
        )
    if !isnothing(replications)
        replications > 0 || throw(ArgumentError("replications must be positive"))
    end

    rng = isnothing(seed) ? Random.default_rng() : MersenneTwister(seed)
    V, n_limit, source_bits =
        _resolve_direction_numbers(raw_dimension, generating_matrices, msb)
    graycode_from_order = isnothing(order) ? nothing : _normalize_digital_net_order(order)
    if !isnothing(graycode_from_order) &&
       !isnothing(graycode) &&
       graycode != graycode_from_order
        throw(ArgumentError("graycode=$(graycode) is inconsistent with order=\"$order\""))
    end
    graycode_bool =
        isnothing(graycode_from_order) ? (isnothing(graycode) ? true : graycode) :
        graycode_from_order
    interlaced_cap = min(64, Base.checked_mul(alpha, source_bits))
    t_bits = isnothing(t) ? (alpha == 1 ? source_bits : interlaced_cap) : t
    t_bits isa Integer || throw(ArgumentError("t must be an integer, got $(typeof(t))"))
    source_bits <= t_bits <= 64 ||
        throw(ArgumentError("t must satisfy $source_bits <= t <= 64, got $t_bits"))
    randomize_norm = _normalize_digital_net_randomize(randomize)
    t_actual =
        randomize_norm == "none" && alpha > 1 ? min(interlaced_cap, Int(t_bits)) : Int(t_bits)

    return DigitalNetB2(
        dimension,
        randomize_norm,
        graycode_bool,
        t_actual,
        alpha,
        source_bits,
        rng,
        V,
        n_limit,
        "StdUniform",
        replications,
    )
end

# ──────────────────────────────────────────────────────────────────────────────
# Matrix-space linear matrix scramble (LMS) over GF(2)
#
# Applies a random lower-triangular `source_bits × source_bits` matrix `L`
# (independent per dimension)
# to each column of the generating matrix V, producing a scrambled copy in
# which each direction number V[j,b] is replaced by L_j * V[j,b] over GF(2).
#
# This is mathematically equivalent to applying the same L_j to every Sobol'
# point in dimension j, but operates in matrix space so the result can be
# passed directly to dnb2_gen_gray_float.
#
# Returns a d × mmax Matrix{UInt64}.
# ──────────────────────────────────────────────────────────────────────────────
function _lms_direction_matrix(
    V::AbstractMatrix{<:Unsigned},
    d::Int,
    source_bits::Int,
    rng::AbstractRNG,
)
    mmax = size(V, 2)
    V_scr = Matrix{UInt64}(undef, d, mmax)
    for j in 1:d
        # Random lower-triangular matrix L over GF(2): L[k] is row k,
        # with the diagonal bit at position (source_bits-k) and random bits below it.
        L = Vector{UInt64}(undef, source_bits)
        for k in 1:source_bits
            diag_bit = UInt64(1) << (source_bits - k)
            below_mask = diag_bit - UInt64(1)
            L[k] = diag_bit | (rand(rng, UInt64) & below_mask)
        end
        for b in 1:mmax
            v = UInt64(V[j, b])
            newv = UInt64(0)
            for k in 1:source_bits
                # Bit k of L*v = parity(L[k] & v)
                t = L[k] & v
                if isodd(count_ones(t))
                    newv |= UInt64(1) << (source_bits - k)
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

function _rand_tbit_uint64s(rng::AbstractRNG, t::Int, n::Int)
    t == 64 && return rand(rng, UInt64, n)
    mask = (UInt64(1) << t) - UInt64(1)
    return rand(rng, UInt64, n) .& mask
end

_left_shift_words(t::Int, bits::Int, R::Int) = fill(UInt64(t - bits), R)
_interlaced_bits(alpha::Int, source_bits::Int, t::Int) = min(alpha * source_bits, t)

# The fused `dnb2_gen_*_float` kernels fold the t-bit alignment left-shift
# (`lshifts`) into the digital-shift pass, which they skip entirely when
# `apply_shift == 0x00`. Whenever `t` exceeds the current bit width the points
# still need that left-shift to land in [0, 1) at the correct scale, so the
# pass must run even when there is no randomization shift. Enabling it with an
# all-zero `shiftsb` performs a no-op digital shift while still applying the
# alignment, matching the unfused gen → digital_shift → integer_to_float path.
_apply_shift_flag(lshifts::AbstractVector{UInt64}) = any(!iszero, lshifts) ? 0x01 : 0x00

function _interlace_direction_matrices(
    C::Vector{UInt64},
    R::Int,
    d_alpha::Int,
    mmax::Int,
    d::Int,
    tmax::Int,
    tmax_alpha::Int,
    alpha::Int,
)
    C_alpha = Vector{UInt64}(undef, R * d_alpha * mmax)
    _c_dnb2_interlace!(R, d_alpha, mmax, d, tmax, tmax_alpha, alpha, C, C_alpha)
    return C_alpha
end

_rowmaj_to_Rnxd_uint64(buf::Vector{UInt64}, R::Int, n::Int, d::Int) =
    permutedims(reshape(buf, d, n, R), (3, 2, 1))
_Rnxd_to_rowmaj_uint64(x::Array{UInt64, 3}) = vec(permutedims(x, (3, 2, 1)))

function _interlace_point_buffer(
    xb_buf::Vector{UInt64},
    R::Int,
    n::Int,
    d_alpha::Int,
    d::Int,
    tmax::Int,
    tmax_alpha::Int,
    alpha::Int,
)
    xb_rnd = _rowmaj_to_Rnxd_uint64(xb_buf, R, n, d)
    xb_rdn = permutedims(xb_rnd, (1, 3, 2))
    C = _Rnxd_to_rowmaj_uint64(xb_rdn)
    C_alpha = _interlace_direction_matrices(C, R, d_alpha, n, d, tmax, tmax_alpha, alpha)
    xb_alpha_rdn = permutedims(reshape(C_alpha, n, d_alpha, R), (3, 2, 1))
    xb_alpha_rnd = permutedims(xb_alpha_rdn, (1, 3, 2))
    return _Rnxd_to_rowmaj_uint64(xb_alpha_rnd)
end

# ──────────────────────────────────────────────────────────────────────────────
# Single-replication and multi-replication generation via qmctoolscl binary net
# generation, optional digital shifts, and integer-to-float conversion.
# ──────────────────────────────────────────────────────────────────────────────
function _gen_single_replication(dd::DigitalNetB2, n::Int; n_start::Int=0)
    d = dd.dimension
    d_raw = dd.alpha == 1 ? d : dd.alpha * d
    V = dd.direction_nums
    mmax = size(V, 2)

    if dd.randomize == "LMS_DS" || dd.randomize == "LMS"
        curr_bits =
            dd.alpha == 1 ? dd.source_bits : _interlaced_bits(dd.alpha, dd.source_bits, dd.t)
        V_scr = _lms_direction_matrix(V, d_raw, dd.source_bits, dd.rng)
        C_flat = if dd.alpha == 1
            _direction_matrix_to_C(V_scr, d_raw)
        else
            _interlace_direction_matrices(
                _direction_matrix_to_C(V_scr, d_raw),
                1,
                d,
                mmax,
                d_raw,
                dd.source_bits,
                curr_bits,
                dd.alpha,
            )
        end
        lshifts = _left_shift_words(dd.t, curr_bits, 1)
        if dd.randomize == "LMS_DS"
            shiftsb = _rand_tbit_uint64s(dd.rng, dd.t, d)
            apply_shift = 0x01
        else
            shiftsb = zeros(UInt64, d)
            apply_shift = _apply_shift_flag(lshifts)
        end
    elseif dd.randomize == "DS"
        curr_bits =
            dd.alpha == 1 ? dd.source_bits : _interlaced_bits(dd.alpha, dd.source_bits, dd.t)
        C_flat = if dd.alpha == 1
            _direction_matrix_to_C(V, d_raw)
        else
            _interlace_direction_matrices(
                _direction_matrix_to_C(V, d_raw),
                1,
                d,
                mmax,
                d_raw,
                dd.source_bits,
                curr_bits,
                dd.alpha,
            )
        end
        lshifts = _left_shift_words(dd.t, curr_bits, 1)
        shiftsb = _rand_tbit_uint64s(dd.rng, dd.t, d)
        apply_shift = 0x01
    elseif dd.randomize == "NUS"
        C_flat = _direction_matrix_to_C(V, d_raw)
        # Generate per-dimension seeds for Owen scrambling
        dim_seeds = rand(dd.rng, UInt64, d_raw)

        xb_buf = Vector{UInt64}(undef, n * d_raw)
        if dd.graycode
            _c_dnb2_gen_gray!(1, n, d_raw, n_start, mmax, C_flat, xb_buf)
        else
            _c_dnb2_gen_natural!(1, n, d_raw, n_start, mmax, C_flat, xb_buf)
        end

        # Apply Owen scrambling in-place
        _owen_scramble_points!(xb_buf, n, d_raw, dd.source_bits, dim_seeds)

        point_bits = dd.source_bits
        if dd.t > point_bits
            xb_shifted = similar(xb_buf)
            _c_dnb2_digital_shift!(
                1,
                n,
                d_raw,
                1,
                _left_shift_words(dd.t, point_bits, 1),
                xb_buf,
                zeros(UInt64, d_raw),
                xb_shifted,
            )
            xb_buf = xb_shifted
            point_bits = dd.t
        end
        if dd.alpha > 1
            xb_buf = _interlace_point_buffer(xb_buf, 1, n, d, d_raw, point_bits, dd.t, dd.alpha)
        end
        tmaxes = fill(UInt64(dd.t), 1)
        x_buf = Vector{Float64}(undef, n * d)
        _c_dnb2_integer_to_float!(1, n, d, tmaxes, xb_buf, x_buf)
        return _rowmaj_to_nxd(x_buf, n, d)
    else  # "none"
        curr_bits = dd.alpha == 1 ? dd.source_bits : dd.t
        C_flat = if dd.alpha == 1
            _direction_matrix_to_C(V, d_raw)
        else
            _interlace_direction_matrices(
                _direction_matrix_to_C(V, d_raw),
                1,
                d,
                mmax,
                d_raw,
                dd.source_bits,
                curr_bits,
                dd.alpha,
            )
        end
        lshifts = _left_shift_words(dd.t, curr_bits, 1)
        shiftsb = zeros(UInt64, d)
        apply_shift = _apply_shift_flag(lshifts)
    end

    tmaxes = fill(UInt64(dd.t), 1)
    x_buf = Vector{Float64}(undef, n * d)
    if _HAS_DNB2_FUSED[]
        if dd.graycode
            _c_dnb2_gen_gray_float!(
                1,
                n,
                d,
                n_start,
                mmax,
                1,
                apply_shift,
                lshifts,
                shiftsb,
                tmaxes,
                C_flat,
                x_buf,
            )
        else
            _c_dnb2_gen_natural_float!(
                1,
                n,
                d,
                n_start,
                mmax,
                1,
                apply_shift,
                lshifts,
                shiftsb,
                tmaxes,
                C_flat,
                x_buf,
            )
        end
    else
        xb_buf = Vector{UInt64}(undef, n * d)
        if dd.graycode
            _c_dnb2_gen_gray!(1, n, d, n_start, mmax, C_flat, xb_buf)
        else
            _c_dnb2_gen_natural!(1, n, d, n_start, mmax, C_flat, xb_buf)
        end
        xrb_buf = Vector{UInt64}(undef, n * d)
        _c_dnb2_digital_shift!(1, n, d, 1, lshifts, xb_buf, shiftsb, xrb_buf)
        _c_dnb2_integer_to_float!(1, n, d, tmaxes, xrb_buf, x_buf)
    end
    return _rowmaj_to_nxd(x_buf, n, d)
end

"""
    gen_samples(dd::DigitalNetB2, n::Int)

Generate `n` Sobol' points in `d` dimensions.  Returns an `n × d` matrix
with values in [0, 1).  If `replications` was set, returns an `R × n × d` array.
`n` should be a power of 2 for optimal equidistribution.
"""
function gen_samples(dd::DigitalNetB2, n::Int; n_start::Int=0)
    n > 0 || throw(ArgumentError("n must be positive, got $n"))
    n_start >= 0 || throw(ArgumentError("n_start must be non-negative"))
    n_stop = Base.checked_add(n, n_start)
    if !isnothing(dd.n_limit)
        n_stop <= dd.n_limit || throw(
            ArgumentError(
                "DigitalNetB2 supports at most $(dd.n_limit) samples for this generating matrix, got n=$n and n_start=$n_start",
            ),
        )
    end

    if isnothing(dd.replications)
        return _gen_single_replication(dd, n; n_start=n_start)
    end

    R = dd.replications
    d = dd.dimension
    d_raw = dd.alpha == 1 ? d : dd.alpha * d
    V = dd.direction_nums
    mmax = size(V, 2)

    if dd.randomize == "LMS_DS" || dd.randomize == "LMS"
        curr_bits =
            dd.alpha == 1 ? dd.source_bits : _interlaced_bits(dd.alpha, dd.source_bits, dd.t)
        C_scr = Vector{UInt64}(undef, R * d_raw * mmax)
        for r in 1:R
            V_scr = _lms_direction_matrix(V, d_raw, dd.source_bits, dd.rng)
            base = (r - 1) * d_raw * mmax
            for j in 1:d_raw, b in 1:mmax
                C_scr[base + (j - 1) * mmax + (b - 1) + 1] = UInt64(V_scr[j, b])
            end
        end
        C_flat =
            dd.alpha == 1 ? C_scr :
            _interlace_direction_matrices(
                C_scr,
                R,
                d,
                mmax,
                d_raw,
                dd.source_bits,
                curr_bits,
                dd.alpha,
            )
        r_x = R
        lshifts = _left_shift_words(dd.t, curr_bits, R)
        if dd.randomize == "LMS_DS"
            shiftsb = _rand_tbit_uint64s(dd.rng, dd.t, R * d)
            apply_shift = 0x01
        else
            shiftsb = zeros(UInt64, R * d)
            apply_shift = _apply_shift_flag(lshifts)
        end
    elseif dd.randomize == "DS"
        curr_bits =
            dd.alpha == 1 ? dd.source_bits : _interlaced_bits(dd.alpha, dd.source_bits, dd.t)
        C_flat =
            dd.alpha == 1 ? _direction_matrix_to_C(V, d_raw) :
            _interlace_direction_matrices(
                _direction_matrix_to_C(V, d_raw),
                1,
                d,
                mmax,
                d_raw,
                dd.source_bits,
                curr_bits,
                dd.alpha,
            )
        r_x = 1
        lshifts = _left_shift_words(dd.t, curr_bits, 1)
        shiftsb = _rand_tbit_uint64s(dd.rng, dd.t, R * d)
        apply_shift = 0x01
    elseif dd.randomize == "NUS"
        C_flat = _direction_matrix_to_C(V, d_raw)
        # Generate unscrambled binary points (single set)
        xb_base = Vector{UInt64}(undef, n * d_raw)
        if dd.graycode
            _c_dnb2_gen_gray!(1, n, d_raw, n_start, mmax, C_flat, xb_base)
        else
            _c_dnb2_gen_natural!(1, n, d_raw, n_start, mmax, C_flat, xb_base)
        end
        # Apply R independent Owen scramblings
        x_buf = Vector{Float64}(undef, R * n * d)
        tmaxes_one = fill(UInt64(dd.t), 1)
        for r in 1:R
            xb_copy = copy(xb_base)
            dim_seeds = rand(dd.rng, UInt64, d_raw)
            _owen_scramble_points!(xb_copy, n, d_raw, dd.source_bits, dim_seeds)
            point_bits = dd.source_bits
            if dd.t > point_bits
                xb_shifted = similar(xb_copy)
                _c_dnb2_digital_shift!(
                    1,
                    n,
                    d_raw,
                    1,
                    _left_shift_words(dd.t, point_bits, 1),
                    xb_copy,
                    zeros(UInt64, d_raw),
                    xb_shifted,
                )
                xb_copy = xb_shifted
                point_bits = dd.t
            end
            if dd.alpha > 1
                xb_copy =
                    _interlace_point_buffer(xb_copy, 1, n, d, d_raw, point_bits, dd.t, dd.alpha)
            end
            x_r = Vector{Float64}(undef, n * d)
            _c_dnb2_integer_to_float!(1, n, d, tmaxes_one, xb_copy, x_r)
            base = (r - 1) * n * d
            x_buf[(base + 1):(base + n * d)] .= x_r
        end
        return _rowmaj_to_Rnxd(x_buf, R, n, d)
    else  # "none"
        curr_bits = dd.alpha == 1 ? dd.source_bits : dd.t
        C_flat =
            dd.alpha == 1 ? _direction_matrix_to_C(V, d_raw) :
            _interlace_direction_matrices(
                _direction_matrix_to_C(V, d_raw),
                1,
                d,
                mmax,
                d_raw,
                dd.source_bits,
                curr_bits,
                dd.alpha,
            )
        r_x = 1
        lshifts = _left_shift_words(dd.t, curr_bits, 1)
        shiftsb = zeros(UInt64, R * d)
        apply_shift = _apply_shift_flag(lshifts)
    end

    tmaxes = fill(UInt64(dd.t), R)
    x_buf = Vector{Float64}(undef, R * n * d)
    if _HAS_DNB2_FUSED[]
        if dd.graycode
            _c_dnb2_gen_gray_float!(
                R,
                n,
                d,
                n_start,
                mmax,
                r_x,
                apply_shift,
                lshifts,
                shiftsb,
                tmaxes,
                C_flat,
                x_buf,
            )
        else
            _c_dnb2_gen_natural_float!(
                R,
                n,
                d,
                n_start,
                mmax,
                r_x,
                apply_shift,
                lshifts,
                shiftsb,
                tmaxes,
                C_flat,
                x_buf,
            )
        end
    else
        xb_buf = Vector{UInt64}(undef, r_x * n * d)
        if dd.graycode
            _c_dnb2_gen_gray!(r_x, n, d, n_start, mmax, C_flat, xb_buf)
        else
            _c_dnb2_gen_natural!(r_x, n, d, n_start, mmax, C_flat, xb_buf)
        end
        xrb_buf = Vector{UInt64}(undef, R * n * d)
        _c_dnb2_digital_shift!(R, n, d, r_x, lshifts, xb_buf, shiftsb, xrb_buf)
        _c_dnb2_integer_to_float!(R, n, d, tmaxes, xrb_buf, x_buf)
    end
    return _rowmaj_to_Rnxd(x_buf, R, n, d)
end

function Base.show(io::IO, dd::DigitalNetB2)
    rep_str = isnothing(dd.replications) ? "" : ", R=$(dd.replications)"
    alpha_str = dd.alpha == 1 ? "" : ", alpha=$(dd.alpha)"
    print(
        io,
        "DigitalNetB2(d=$(dd.dimension), randomize=\"$(dd.randomize)\", graycode=$(dd.graycode)$alpha_str$rep_str)",
    )
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
function _owen_scramble_points!(
    xb::Vector{UInt64},
    n::Int,
    d::Int,
    mmax::Int,
    dim_seeds::Vector{UInt64},
)
    @inbounds for i in 0:(n - 1)
        for j in 0:(d - 1)
            idx = i * d + j + 1
            xb[idx] = _owen_scramble_value(xb[idx], dim_seeds[j + 1], mmax)
        end
    end
end
