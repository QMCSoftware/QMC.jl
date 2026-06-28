"""
    fwht!(x::AbstractVector)

In-place Fast Walsh-Hadamard Transform (natural/Hadamard-ordered).
Length of `x` must be a power of 2.

The transform computes y = H_n * x where H_n is the n x n
Hadamard matrix. This is done in O(n log n) operations using
the butterfly decomposition.

# Examples
```jldoctest
julia> using QuasiMC

julia> x = [1.0, 0.0, 1.0, 0.0, 0.0, 1.0, 1.0, 0.0];

julia> fwht!(x)
8-element Vector{Float64}:
  4.0
  2.0
  0.0
 -2.0
  0.0
  2.0
  0.0
  2.0

julia> fwht([1.0, 1.0, 1.0, 1.0])
4-element Vector{Float64}:
 4.0
 0.0
 0.0
 0.0
```
"""
function fwht!(x::AbstractVector{T}) where {T <: Real}
    n = length(x)
    @assert ispow2(n) "Length must be a power of 2, got $n"
    h = 1
    while h < n
        for i in 0:2h:(n - 1)
            for j in 0:(h - 1)
                u = x[i + j + 1]
                v = x[i + j + h + 1]
                x[i + j + 1] = u + v
                x[i + j + h + 1] = u - v
            end
        end
        h *= 2
    end
    return x
end

"""
    fwht(x::AbstractVector)

Fast Walsh-Hadamard Transform (out-of-place). Returns a new vector
containing the WHT of `x`. Length of `x` must be a power of 2.
"""
function fwht(x::AbstractVector)
    y = copy(x)
    fwht!(y)
    return y
end

"""
    ifwht!(x::AbstractVector)

In-place inverse Fast Walsh-Hadamard Transform.
Computes the inverse by applying the forward transform and dividing by n.
"""
function ifwht!(x::AbstractVector)
    fwht!(x)
    x ./= length(x)
    return x
end

"""
    ifwht(x::AbstractVector)

Inverse Fast Walsh-Hadamard Transform (out-of-place). Returns a new vector.
"""
function ifwht(x::AbstractVector)
    y = copy(x)
    ifwht!(y)
    return y
end

"""
    fwht_sequency!(x::AbstractVector{T}) where T<:Real

In-place Fast Walsh-Hadamard Transform in sequency (Walsh) order.
The sequency ordering sorts basis functions by number of zero crossings.
Length of `x` must be a power of 2.
"""
function fwht_sequency!(x::AbstractVector{T}) where {T <: Real}
    n = length(x)
    @assert ispow2(n) "Length must be a power of 2, got $n"
    # Apply natural-order WHT
    fwht!(x)
    # Bit-reversal permutation followed by Gray code permutation
    # to convert from natural to sequency order
    log2n = trailing_zeros(n)
    perm = zeros(Int, n)
    for i in 0:(n - 1)
        # Gray code: g = i XOR (i >> 1)
        g = i ⊻ (i >> 1)
        # Bit-reverse the Gray code
        br = 0
        val = g
        for b in 1:log2n
            br = (br << 1) | (val & 1)
            val >>= 1
        end
        perm[i + 1] = br + 1
    end
    x .= x[perm]
    return x
end

"""
    fwht_sequency(x::AbstractVector)

Fast Walsh-Hadamard Transform in sequency order (out-of-place).
"""
function fwht_sequency(x::AbstractVector)
    y = copy(x)
    fwht_sequency!(y)
    return y
end

"""
    fwht_2d!(X::AbstractMatrix{T}) where T<:Real

In-place 2D Fast Walsh-Hadamard Transform applied along both
rows and columns of a square matrix. Both dimensions must be powers of 2.
"""
function fwht_2d!(X::AbstractMatrix{T}) where {T <: Real}
    m, n = size(X)
    @assert ispow2(m) && ispow2(n) "Both dimensions must be powers of 2, got ($m, $n)"
    # Transform along rows
    for i in 1:m
        row = X[i, :]
        fwht!(row)
        X[i, :] .= row
    end
    # Transform along columns
    for j in 1:n
        col = X[:, j]
        fwht!(col)
        X[:, j] .= col
    end
    return X
end

"""
    _fwht_ortho(x::AbstractVector) -> Vector{Float64}

Orthonormal (norm-preserving) natural-order fast Walsh-Hadamard transform:
`H_n*x / sqrt(n)`. This is the convention used by QMCPy's `fwht` (each
butterfly step divides by `sqrt(2)`), as opposed to the unnormalised [`fwht`](@ref)
(`H_n*x`). It is the fast transform underlying the guaranteed digital-net
cubature error bound.

The doubling identity holds with all-ones weights: for `x = [x_1; x_2]` with
equal halves, `_fwht_ortho(x) == [y_1 .+ y_2; y_1 .- y_2] ./ sqrt(2)` where
`y_i = _fwht_ortho(x_i)`.
"""
function _fwht_ortho(x::AbstractVector)
    n = length(x)
    return fwht(x) ./ sqrt(n)
end

"""
    _ytilde_init(y) -> Vector{Float64}

Scaled orthonormal Walsh coefficients of the function values `y` over the first
`length(y)` net points: `_fwht_ortho(y) / √length(y)`. The first entry equals
`mean(y)`. Used to initialise the guaranteed digital-net cubature.
"""
_ytilde_init(y::AbstractVector) = _fwht_ortho(y) ./ sqrt(length(y))

"""
    _ytilde_double(ytilde_prev, ynext) -> Vector{Float64}

Incrementally extend the scaled Walsh coefficients when the sample size doubles,
reusing `ytilde_prev` (coefficients of the existing points) and the function
values `ynext` at the newly added points (equal in number). Uses the all-ones
FWHT doubling merge, so the result equals `_ytilde_init([y_prev; ynext])` without
recomputing the transform over the existing points.
"""
function _ytilde_double(ytilde_prev::AbstractVector, ynext::AbstractVector)
    N = length(ynext)
    yt_omega = _fwht_ortho(ynext) ./ sqrt(N)
    return vcat((ytilde_prev .+ yt_omega) ./ 2, (ytilde_prev .- yt_omega) ./ 2)
end

"""
    _update_kappanumap!(kappanumap, ytilde, mfrom, mto, m) -> kappanumap

In-place port of QMCPy's coefficient decay-ordering used by the guaranteed
digital-net cubature. `kappanumap` is a permutation of `0:2^m-1` (0-based values,
1-based positions); `ytilde` are the orthonormal Walsh coefficients. For each
level `l` from `mfrom` down to `mto+1`, it compares the magnitudes of paired
coefficients and swaps their indices so larger-magnitude coefficients move to the
earlier (low-frequency) block - building the ordering the error bound sums over.
The first index (a power of two) is never moved. Scalar (single-output) version.
"""
function _update_kappanumap!(
    kappanumap::Vector{Int},
    ytilde::AbstractVector,
    mfrom::Int,
    mto::Int,
    m::Int,
)
    for l in mfrom:-1:(mto + 1)
        nl = 2^l
        flip = Int[]
        for j in 0:(nl - 2)
            v_old = kappanumap[j + 2]
            v_new = kappanumap[nl + j + 2]
            if abs(ytilde[v_new + 1]) > abs(ytilde[v_old + 1])
                push!(flip, j + 1)
            end
        end
        isempty(flip) && continue
        for off in 0:(2 ^ (l + 1)):(2 ^ m - 2)
            for f in flip
                p_old = f + off + 1
                p_new = nl + f + off + 1
                kappanumap[p_old], kappanumap[p_new] = kappanumap[p_new], kappanumap[p_old]
            end
        end
    end
    return kappanumap
end
