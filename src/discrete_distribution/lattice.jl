"""
    Lattice(dimension::Int; randomize=true, seed=nothing, order="natural",
            replications=nothing)

Rank-1 integration lattice using the published Kuo generating vector
(kuo.lattice-33002-1024-1048576.9125), supporting up to 9125 dimensions
and n up to 2^20.

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
    shift::Matrix{Float64}   # R × d
    rng::R
    mimics::String
end

function Lattice(
    dimension::Int;
    randomize::Bool=true,
    seed=nothing,
    order::String="natural",
    replications=nothing,
)
    dimension > 0 || throw(ArgumentError("dimension must be positive"))
    dimension <= _KUO_LATTICE_MAX_DIM || throw(
        ArgumentError(
            "dimension $dimension exceeds maximum supported ($_KUO_LATTICE_MAX_DIM)",
        ),
    )
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

    R = isnothing(replications) ? 1 : replications
    R >= 1 || throw(ArgumentError("replications must be >= 1"))

    rng = isnothing(seed) ? Random.default_rng() : MersenneTwister(seed)
    gv = _KUO_LATTICE_GEN_VECTOR[1:dimension]
    shift = randomize ? rand(rng, R, dimension) : zeros(R, dimension)

    return Lattice(
        dimension,
        randomize,
        order_lc,
        replications,
        gv,
        shift,
        rng,
        "StdUniform",
    )
end

function _validate_lattice_window(order::String, n::Int, n_start::Int)
    if order == "radical_inverse"
        n_stop = Base.checked_add(n, n_start)
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
    _validate_lattice_window(dd.order, n, n_start)
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
