"""
    Lattice(dimension::Int; randomize=true, seed=nothing, order="natural",
            replications=nothing, generating_vector=nothing)

Rank-1 integration lattice using either the published Kuo generating vector
(`kuo.lattice-33002-1024-1048576.9125`) or a user-supplied generating vector.
The bundled Kuo vector supports up to 9125 dimensions and `n` up to `2^20`.

Points: x_i = frac(i · z / n), with optional random shift Δ ~ U[0,1)^d.

When `replications` is set to an integer R > 1, `gen_samples` returns an
`R × n × d` array of R independently shifted copies.

This generator currently relies on the QMCToolsCL shared library. Install
`qmctoolscl` into a Python visible to Julia, or set `ENV["QMC_PYTHON"]`
before `using QMC`.

# Arguments
- `dimension`: number of dimensions (up to 9125).
- `randomize`: if true, apply a random shift.
- `seed`: optional RNG seed.
- `order`: `"linear"`, `"radical_inverse"`, or `"gray"` (`"natural"` is accepted
  as an alias for `"radical_inverse"`, and `"gray code"` for `"gray"`, matching
  QMCPy). Radical-inverse order requires `n_start` and `n + n_start` to be
  powers of 2 when calling `gen_samples`.
- `replications`: number of independent shifts (nothing = 1, no extra dim).
- `generating_vector`: optional custom generating vector. May be
  - `nothing` (default): use the bundled Kuo vector,
  - a vector of integers: use its first `dimension` entries,
  - an integer `M`: generate a random odd vector `(1, v₂, …, v_d)` with
    `v_j ∈ {3, 5, …, 2^M - 1}`,
  - a local text-file path: load one integer per non-comment line, or a
    QMCPy/LDData-style file whose first two integers are metadata followed by
    the vector entries,
  - a QMCPy/LDData filename or GitHub URL (for example
    `"kuo.lattice-33002-1024-1048576.9125"` or the corresponding
    `QMCSoftware/LDData` `lattice/` URL). Non-bundled LDData files are
    downloaded on demand.

# Examples
```julia
dd = Lattice(3; randomize=true, seed=7)
x = gen_samples(dd, 1024)  # 1024×3 shifted lattice points

dd_r = Lattice(3; seed=7, replications=16)
x = gen_samples(dd_r, 1024)  # 16×1024×3 array
```
"""
mutable struct Lattice{R <: AbstractRNG} <: AbstractDiscreteDistribution
    dimension::Int
    randomize::Bool
    order::String
    replications::Union{Nothing, Int}
    gen_vector::Vector{UInt64}
    source_gen_vector::Union{Nothing, Vector{UInt64}}
    shift::Matrix{Float64}   # R × d
    rng::R
    n_limit::Union{Nothing, Int}
    mimics::String
end

const _DEFAULT_LATTICE_VECTOR_NAME = "kuo.lattice-33002-1024-1048576.9125.txt"
const _LATTICE_LDDATA_RAW_BASE = "https://raw.githubusercontent.com/QMCSoftware/LDData/main/lattice/"
const _DOWNLOADS_PKGID =
    Base.PkgId(Base.UUID("f43a241f-c20a-4ad4-852c-f6b1247861c6"), "Downloads")

_downloads_module() = Base.require(_DOWNLOADS_PKGID)

function _normalize_lattice_order(order::String)
    # Normalize order aliases to canonical tokens, matching QMCPy semantics:
    # "natural" is an alias for "radical inverse" (both use the lat_gen_natural
    # kernel) and "gray code" == "gray". Accept "_" or " " as word separators.
    order_lc = replace(lowercase(strip(order)), "_" => " ")
    order_lc == "gray code" && (order_lc = "gray")
    order_lc == "natural" && (order_lc = "radical inverse")
    order_lc = replace(order_lc, " " => "_")
    order_lc in ("linear", "radical_inverse", "gray") || throw(
        ArgumentError(
            "order must be one of linear/radical_inverse/gray " *
            "(natural is accepted as an alias for radical_inverse)",
        ),
    )
    return order_lc
end

function _coerce_lattice_vector(values::AbstractVector{<:Integer}, dimension::Int)
    length(values) >= dimension || throw(
        ArgumentError(
            "generating_vector must have at least $dimension entries, got $(length(values))",
        ),
    )
    gv = Vector{UInt64}(undef, dimension)
    for j in 1:dimension
        value = values[j]
        value > 0 || throw(
            ArgumentError("generating_vector entries must be positive, got $value at index $j"),
        )
        try
            gv[j] = UInt64(value)
        catch err
            if err isa InexactError
                throw(
                    ArgumentError(
                        "generating_vector entry at index $j cannot be represented as UInt64: $value",
                    ),
                )
            end
            rethrow()
        end
    end
    return gv
end

function _read_lattice_vector_file(path::AbstractString)
    values = UInt64[]
    saw_d_limit = false
    saw_n_limit = false
    open(path, "r") do io
        for raw_line in eachline(io)
            split_line = split(raw_line, '#'; limit=2)
            line = strip(first(split_line))
            if length(split_line) == 2
                comment = replace(lowercase(strip(split_line[2])), " " => "_")
                saw_d_limit |= occursin("d_limit", comment)
                saw_n_limit |= occursin("n_limit", comment)
            elseif startswith(strip(raw_line), '#')
                comment = replace(lowercase(strip(raw_line[2:end])), " " => "_")
                saw_d_limit |= occursin("d_limit", comment)
                saw_n_limit |= occursin("n_limit", comment)
            end
            isempty(line) && continue
            value = tryparse(UInt64, line)
            isnothing(value) && throw(
                ArgumentError("invalid generating-vector entry in \"$path\": \"$raw_line\""),
            )
            push!(values, value)
        end
    end
    isempty(values) && throw(ArgumentError("generating_vector file \"$path\" is empty"))
    if saw_d_limit || saw_n_limit
        saw_d_limit && saw_n_limit || throw(
            ArgumentError(
                "generating_vector file \"$path\" must specify both d_limit and n_limit metadata",
            ),
        )
        length(values) >= 3 || throw(
            ArgumentError(
                "generating_vector file \"$path\" metadata must be followed by vector entries",
            ),
        )
        values[1] <= typemax(Int) || throw(
            ArgumentError("generating_vector file \"$path\" has d_limit too large for Int"),
        )
        values[2] <= typemax(Int) || throw(
            ArgumentError("generating_vector file \"$path\" has n_limit too large for Int"),
        )
        d_limit = Int(values[1])
        n_limit = Int(values[2])
        d_limit > 0 ||
            throw(ArgumentError("generating_vector file \"$path\" must have positive d_limit"))
        n_limit > 0 ||
            throw(ArgumentError("generating_vector file \"$path\" must have positive n_limit"))
        length(values) == d_limit + 2 || throw(
            ArgumentError(
                "generating_vector file \"$path\" declares d_limit=$d_limit but contains $(length(values) - 2) vector entries",
            ),
        )
        return values[3:end], n_limit
    end
    if length(values) >= 3 && values[1] <= typemax(Int) && Int(values[1]) == length(values) - 2
        values[2] <= typemax(Int) || throw(
            ArgumentError("generating_vector file \"$path\" has n_limit too large for Int"),
        )
        return values[3:end], Int(values[2])
    end
    return values, nothing
end

function _canonical_lattice_vector_filename(name::AbstractString)
    token = replace(strip(name), '\\' => '/')
    token = split(token, '?'; limit=2)[1]
    token = split(token, '#'; limit=2)[1]
    isempty(token) && throw(ArgumentError("generating_vector reference cannot be empty"))
    parts = split(token, '/')
    basename = parts[end]
    isempty(basename) &&
        throw(ArgumentError("generating_vector reference \"$name\" has no filename"))
    return endswith(lowercase(basename), ".txt") ? basename : string(basename, ".txt")
end

function _looks_like_lddata_lattice_reference(name::AbstractString)
    token = lowercase(replace(strip(name), '\\' => '/'))
    isempty(token) && return false
    if !(occursin('/', token) || occursin('\\', name))
        return true
    end
    return (
        occursin("github.com/qmcsoftware/lddata/", token) ||
        occursin("raw.githubusercontent.com/qmcsoftware/lddata/", token) ||
        startswith(token, "lattice/") ||
        occursin("/lattice/", token)
    )
end

function _download_lattice_vector_from_lddata(filename::AbstractString)
    url = _LATTICE_LDDATA_RAW_BASE * filename
    path, io = mktemp()
    close(io)
    try
        _downloads_module().download(url, path)
        return _read_lattice_vector_file(path)
    catch err
        msg = sprint(showerror, err)
        throw(
            ArgumentError(
                "failed to fetch LDData lattice generating vector \"$filename\" from $url: $msg",
            ),
        )
    finally
        isfile(path) && rm(path; force=true)
    end
end

function _random_lattice_vector(dimension::Int, m::Integer, rng::AbstractRNG)
    1 < m < 27 ||
        throw(ArgumentError("integer generating_vector must satisfy 1 < M < 27, got $m"))
    gv = Vector{UInt64}(undef, dimension)
    gv[1] = UInt64(1)
    if dimension > 1
        max_half = (1 << (Int(m) - 1)) - 1
        for j in 2:dimension
            gv[j] = UInt64(2 * rand(rng, 1:max_half) + 1)
        end
    end
    return gv, 1 << Int(m)
end

function _resolve_lattice_generating_vector(dimension::Int, generating_vector, rng::AbstractRNG)
    if isnothing(generating_vector)
        dimension <= _KUO_LATTICE_MAX_DIM || throw(
            ArgumentError(
                "dimension $dimension exceeds maximum supported ($_KUO_LATTICE_MAX_DIM)",
            ),
        )
        return _KUO_LATTICE_GEN_VECTOR[1:dimension], 1 << 20, nothing
    elseif generating_vector isa AbstractVector{<:Integer}
        length(generating_vector) >= dimension || throw(
            ArgumentError(
                "generating_vector must have at least $dimension entries, got $(length(generating_vector))",
            ),
        )
        source = _coerce_lattice_vector(generating_vector, length(generating_vector))
        return source[1:dimension], nothing, source
    elseif generating_vector isa Integer
        gv, n_limit = _random_lattice_vector(dimension, generating_vector, rng)
        return gv, n_limit, copy(gv)
    elseif generating_vector isa AbstractString
        if isfile(generating_vector)
            values, n_limit = _read_lattice_vector_file(generating_vector)
            source = _coerce_lattice_vector(values, length(values))
            length(source) >= dimension || throw(
                ArgumentError(
                    "generating_vector must have at least $dimension entries, got $(length(source))",
                ),
            )
            return source[1:dimension], n_limit, source
        end
        _looks_like_lddata_lattice_reference(generating_vector) ||
            throw(ArgumentError("generating_vector file \"$generating_vector\" not found"))
        filename = _canonical_lattice_vector_filename(generating_vector)
        if filename == _DEFAULT_LATTICE_VECTOR_NAME
            dimension <= _KUO_LATTICE_MAX_DIM || throw(
                ArgumentError(
                    "dimension $dimension exceeds maximum supported ($_KUO_LATTICE_MAX_DIM)",
                ),
            )
            return _KUO_LATTICE_GEN_VECTOR[1:dimension], 1 << 20, nothing
        end
        values, n_limit = _download_lattice_vector_from_lddata(filename)
        source = _coerce_lattice_vector(values, length(values))
        length(source) >= dimension || throw(
            ArgumentError(
                "generating_vector must have at least $dimension entries, got $(length(source))",
            ),
        )
        return source[1:dimension], n_limit, source
    else
        throw(
            ArgumentError(
                "generating_vector must be nothing, an integer, a vector of integers, a local file path, or an LDData lattice filename/URL",
            ),
        )
    end
end

function Lattice(
    dimension::Int;
    randomize::Bool=true,
    seed=nothing,
    order::String="natural",
    replications=nothing,
    generating_vector=nothing,
)
    dimension > 0 || throw(ArgumentError("dimension must be positive"))
    order_lc = _normalize_lattice_order(order)

    R = isnothing(replications) ? 1 : replications
    R >= 1 || throw(ArgumentError("replications must be >= 1"))

    rng = isnothing(seed) ? Random.default_rng() : MersenneTwister(seed)
    gv, n_limit, source_gv =
        _resolve_lattice_generating_vector(dimension, generating_vector, rng)
    shift = randomize ? rand(rng, R, dimension) : zeros(R, dimension)

    return Lattice(
        dimension,
        randomize,
        order_lc,
        replications,
        gv,
        source_gv,
        shift,
        rng,
        n_limit,
        "StdUniform",
    )
end

function _validate_lattice_window(dd::Lattice, n::Int, n_start::Int)
    n_stop = Base.checked_add(n, n_start)
    if !isnothing(dd.n_limit)
        n_eval = dd.order == "linear" ? n : n_stop
        n_eval <= dd.n_limit || throw(
            ArgumentError(
                "Lattice supports at most $(dd.n_limit) samples for this generating vector, got n=$n and n_start=$n_start",
            ),
        )
    end

    order = dd.order
    if order == "radical_inverse"
        (n_start == 0 || ispow2(n_start)) || throw(
            ArgumentError(
                "Lattice order \"$order\" requires n_start to be 0 or a power of 2, got $n_start",
            ),
        )
        (n_stop == 0 || ispow2(n_stop)) || throw(
            ArgumentError(
                "Lattice order \"$order\" requires n + n_start to be a power of 2, got n=$n and n_start=$n_start",
            ),
        )
    end
end

function gen_samples(dd::Lattice, n::Int; n_start::Int=0)
    n > 0 || throw(ArgumentError("n must be positive"))
    n_start >= 0 || throw(ArgumentError("n_start must be non-negative"))
    _validate_lattice_window(dd, n, n_start)
    d = dd.dimension
    R = isnothing(dd.replications) ? 1 : dd.replications
    g = dd.gen_vector  # Vector{UInt64}, length d

    # Regenerate shift on each call when randomized
    if dd.randomize
        dd.shift .= rand(dd.rng, R, d)
    end

    # Generate unshifted base lattice (1 replication, n points, d dims)
    x_buf = Vector{Float64}(undef, n * d)
    if dd.order == "linear"
        if n_start != 0
            @warn "Lattice linear order ignores n_start; generating from index 0"
        end
        _c_lat_gen_linear!(n, d, g, x_buf)
    elseif dd.order == "radical_inverse"
        _c_lat_gen_natural!(n, d, n_start, g, x_buf)
    else  # "gray"
        _c_lat_gen_gray!(n, d, n_start, g, x_buf)
    end

    # Build a row-major R×d shifts buffer: shifts_buf[l*d + j] = dd.shift[l+1, j+1]
    shifts_buf = Float64[dd.shift[l, j] for l in 1:R for j in 1:d]

    # Apply R independent shifts via the C fused shift-mod-1 function
    xr_buf = Vector{Float64}(undef, R * n * d)
    _c_lat_shift_mod_1!(R, n, d, 1, x_buf, shifts_buf, xr_buf)

    return R == 1 ? _rowmaj_to_nxd(xr_buf, n, d) : _rowmaj_to_Rnxd(xr_buf, R, n, d)
end

function Base.show(io::IO, dd::Lattice)
    reps = isnothing(dd.replications) ? "" : ", reps=$(dd.replications)"
    print(
        io,
        "Lattice(d=$(dd.dimension), randomize=$(dd.randomize), order=\"$(dd.order)\"$reps)",
    )
end
