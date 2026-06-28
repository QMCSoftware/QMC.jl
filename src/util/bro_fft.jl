"""
    bro_fft(x::Vector{Float64}) -> Vector{ComplexF64}

Compute the FFT of a vector in bit-reversed order (BRO).

Lattice rules with natural (bit-reversed) ordering produce function values
in BRO. This function computes the DFT directly from BRO-ordered data
without requiring an explicit bit-reversal permutation.

Equivalent to `fft(bitreverse_permute(x))` but potentially more efficient
for in-place FFT implementations.

# Examples
```jldoctest
julia> using QuasiMC

julia> bro_fft([1.0, 2.0, 3.0, 4.0])
4-element Vector{ComplexF64}:
 10.0 + 0.0im
 -1.0 + 1.0im
 -4.0 + 0.0im
 -1.0 - 1.0im
```

```jldoctest
julia> using QuasiMC

julia> bro_ifft(ComplexF64[10, -1 + 1im, -4, -1 - 1im])
4-element Vector{Float64}:
 1.0
 2.0
 3.0
 4.0
```
"""
function bro_fft(x::Vector{Float64})
    n = length(x)
    @assert ispow2(n) "bro_fft requires length to be a power of 2"
    # Bit-reverse permutation
    x_perm = _bitrev_permute(x)
    return FFTW.fft(x_perm)
end

"""
    bro_ifft(X::Vector{ComplexF64}) -> Vector{Float64}

Inverse FFT returning result in bit-reversed order.
"""
function bro_ifft(X::Vector{ComplexF64})
    x = real.(FFTW.ifft(X))
    return _bitrev_permute(x)
end

function _bitrev_permute(x::Vector{T}) where {T}
    n = length(x)
    m = trailing_zeros(n)
    out = similar(x)
    for i in 0:(n - 1)
        j = _bitrev(i, m)
        out[j + 1] = x[i + 1]
    end
    return out
end

function _bitrev(x::Int, m::Int)
    result = 0
    for _ in 1:m
        result = (result << 1) | (x & 1)
        x >>= 1
    end
    return result
end
