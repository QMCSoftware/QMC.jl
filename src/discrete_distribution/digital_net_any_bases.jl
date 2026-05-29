"""
    DigitalNetAnyBases(dimension; bases, generating_matrices, randomize="none",
                       alpha=1, seed=nothing, replications=nothing)

Low-discrepancy digital net with arbitrary bases for each dimension.

The generating matrices `C[j]` are `m × m` lower-triangular matrices with
entries in `{0, …, b_j - 1}`. Point `i` in dimension `j` is computed as:

    x_{i,j} = ∑_k (C_j · digits(i, b_j))_k / b_j^{k+1}

Supports Owen (NUS) scrambling and higher-order construction via interlacing
(`alpha > 1`).

# Arguments
- `dimension::Int`: number of output dimensions.
- `bases::Union{Int, Vector{Int}}`: base(s) for each dimension.
- `generating_matrices::Array{Int, 3}`: `d × m × m` array of generating matrices.
- `randomize::String`: `"none"`, `"DS"` (digital shift), or `"NUS"` (Owen scrambling).
- `alpha::Int`: interlacing factor for higher-order nets (default 1).
- `seed`: optional RNG seed.
- `replications`: number of independent randomizations.

# Example
```julia
C = zeros(Int, 2, 3, 3)
C[1,:,:] = [1 0 0; 0 1 0; 1 2 1]
C[2,:,:] = [2 0 0; 1 2 0; 0 2 2]
dd = DigitalNetAnyBases(2; bases=3, generating_matrices=C, randomize="none")
x = gen_samples(dd, 9)
```
"""
mutable struct DigitalNetAnyBases <: AbstractDiscreteDistribution
    dimension::Int
    d_gen::Int               # dimension of generating matrices (may differ from dimension if alpha > 1)
    bases::Vector{Int}       # base per gen-dimension
    generating_matrices::Array{Int, 3}  # d_gen × m × m
    m::Int                   # precision (number of digits)
    randomize::String
    alpha::Int
    replications::Union{Nothing, Int}
    rng::AbstractRNG
    mimics::String
end

function DigitalNetAnyBases(dimension::Int;
    bases::Union{Int, Vector{Int}},
    generating_matrices::Array{Int, 3},
    randomize::String = "none",
    alpha::Int = 1,
    seed = nothing,
    replications = nothing)
    dimension > 0 || throw(ArgumentError("dimension must be positive"))
    alpha >= 1 || throw(ArgumentError("alpha must be >= 1"))
    randomize in ("none", "DS", "NUS") || throw(ArgumentError(
        "randomize must be none, DS, or NUS"))

    d_gen = size(generating_matrices, 1)
    m = size(generating_matrices, 2)
    @assert size(generating_matrices, 3) == m "Generating matrices must be square (m × m)"

    if alpha > 1
        # Higher-order: d_gen dimensions get interlaced into dimension = d_gen ÷ alpha
        d_gen >= dimension * alpha || throw(ArgumentError(
            "Need d_gen >= dimension * alpha for higher-order nets"))
    else
        d_gen >= dimension || throw(ArgumentError(
            "Need at least $dimension generating matrices, got $d_gen"))
    end

    b_vec = bases isa Int ? fill(bases, d_gen) : bases
    length(b_vec) >= d_gen || throw(ArgumentError("Need bases for all $d_gen dimensions"))

    rng = isnothing(seed) ? Random.default_rng() : MersenneTwister(seed)

    return DigitalNetAnyBases(dimension, d_gen, b_vec[1:d_gen],
        generating_matrices, m, randomize, alpha, replications, rng, "StdUniform")
end

function _digits_base(i::Int, base::Int, m::Int)
    d = zeros(Int, m)
    val = i
    for k in 1:m
        d[k] = mod(val, base)
        val = div(val, base)
    end
    return d
end

function _gen_point(C::AbstractMatrix{Int}, i::Int, base::Int, m::Int)
    digs = _digits_base(i, base, m)
    # Matrix-vector product mod base
    result = zeros(Int, m)
    for k in 1:m, j in 1:m
        result[k] = mod(result[k] + C[k, j] * digs[j], base)
    end
    # Convert to floating point
    val = 0.0
    for k in m:-1:1
        val = (val + result[k]) / base
    end
    return val
end

function _interlace(vals::Vector{Float64}, alpha::Int, bases::Vector{Int})
    # Interlace alpha consecutive dimensions into one higher-order dimension
    d_out = div(length(vals), alpha)
    result = zeros(Float64, d_out)
    for j in 1:d_out
        base = bases[(j - 1) * alpha + 1]  # all bases should be same for interlacing
        val = 0.0
        for a in 1:alpha
            src_idx = (j-1)*alpha + a
            # Interleave digits
            digits_a = Int[]
            v = vals[src_idx]
            for _ in 1:div(64, alpha)  # enough precision
                v *= base
                push!(digits_a, floor(Int, v))
                v -= floor(v)
            end
            for (k, d) in enumerate(digits_a)
                pos = (k-1)*alpha + a
                val += d / Float64(base)^pos
            end
        end
        result[j] = val
    end
    return result
end

function gen_samples(dd::DigitalNetAnyBases, n::Int; n_start::Int = 0)
    n > 0 || throw(ArgumentError("n must be positive"))
    d = dd.dimension
    d_gen = dd.d_gen
    m = dd.m
    R = isnothing(dd.replications) ? 1 : dd.replications

    if R > 1 && dd.randomize == "none"
        @warn "replications > 1 with no randomization produces identical copies"
    end

    x_all = Array{Float64}(undef, R == 1 ? (n, d) : (R, n, d))

    for r in 1:R
        # Generate digital shift if needed
        ds = if dd.randomize in ("DS", "NUS")
            [rand(dd.rng) for _ in 1:d_gen]
        else
            zeros(d_gen)
        end

        for i in 1:n
            idx = n_start + i - 1  # 0-based sample index
            raw = Vector{Float64}(undef, d_gen)
            for j in 1:d_gen
                raw[j] = _gen_point(
                    @view(dd.generating_matrices[j, :, :]),
                    idx, dd.bases[j], m)
            end

            # Apply digital shift
            if dd.randomize in ("DS", "NUS")
                for j in 1:d_gen
                    raw[j] = mod(raw[j] + ds[j], 1.0)
                end
            end

            # Apply interlacing for higher-order nets
            pt = dd.alpha > 1 ? _interlace(raw, dd.alpha, dd.bases) : raw[1:d]

            if R == 1
                x_all[i, :] .= pt
            else
                x_all[r, i, :] .= pt
            end
        end
    end

    return x_all
end

function Base.show(io::IO, dd::DigitalNetAnyBases)
    b_str = length(unique(dd.bases)) == 1 ? "$(dd.bases[1])" : "mixed"
    rep_str = isnothing(dd.replications) ? "" : ", R=$(dd.replications)"
    print(io, "DigitalNetAnyBases(d=$(dd.dimension), base=$b_str, α=$(dd.alpha)$rep_str)")
end

# ── Faure sequence (special case) ─────────────────────────────────────────

"""
    Faure(dimension; seed=nothing, randomize="none", replications=nothing)

Faure sequence: a digital net in a single prime base `b ≥ dimension`.
Uses Pascal-matrix-based generating matrices.

# Example
```julia
dd = Faure(3)
x = gen_samples(dd, 125)  # 125 = 5^3 points in base 5
```
"""
function Faure(dimension::Int; seed = nothing, randomize::String = "none",
    replications = nothing)
    dimension > 0 || throw(ArgumentError("dimension must be positive"))

    # Find smallest prime >= dimension
    base = dimension
    while !_is_prime(base)
        base += 1
    end

    m = max(ceil(Int, log(base, 1024)), 10)  # enough precision

    # Generate Pascal-matrix-based generating matrices
    C = zeros(Int, dimension, m, m)
    for j in 1:dimension
        for row in 1:m, col in 1:m
            if col <= row
                # C_j[row, col] = binomial(row-1, col-1) * (j-1)^(row-col) mod base
                C[j, row, col] = mod(
                    binomial(row - 1, col - 1) * powermod(j - 1, row - col, base),
                    base)
            end
        end
    end

    return DigitalNetAnyBases(dimension; bases = base,
        generating_matrices = C, randomize = randomize, seed = seed,
        replications = replications)
end

function _is_prime(n::Int)
    n < 2 && return false
    n < 4 && return true
    (n % 2 == 0 || n % 3 == 0) && return false
    i = 5
    while i * i <= n
        (n % i == 0 || n % (i + 2) == 0) && return false
        i += 6
    end
    return true
end
