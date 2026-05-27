"""
    fwht!(x::AbstractVector)

In-place Fast Walsh-Hadamard Transform (natural/Hadamard-ordered).
Length of `x` must be a power of 2.

The transform computes y = H_n * x where H_n is the n x n
Hadamard matrix. This is done in O(n log n) operations using
the butterfly decomposition.
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
