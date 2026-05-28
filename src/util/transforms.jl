"""
    to_bin(x::Real, m::Int)

Convert a float `x` in [0, 1) to its binary representation with `m` bits.
Returns a vector of `m` integers (0 or 1).
"""
function to_bin(x::Real, m::Int)
    @assert 0.0 <= x < 1.0 "x must be in [0, 1), got x = $x"
    bits = zeros(Int, m)
    val = x
    for i in 1:m
        val *= 2.0
        bits[i] = floor(Int, val)
        val -= bits[i]
    end
    return bits
end

"""
    to_float(bits::AbstractVector{<:Integer})

Convert a binary representation back to a float in [0, 1).
"""
function to_float(bits::AbstractVector{<:Integer})
    val = 0.0
    for i in eachindex(bits)
        val += bits[i] * 2.0^(-i)
    end
    return val
end

"""
    to_bin_matrix(x::AbstractMatrix, m::Int)

Convert an n×d matrix of floats in [0,1) to an n×d×m binary tensor.
"""
function to_bin_matrix(x::AbstractMatrix, m::Int)
    n, d = size(x)
    bits = zeros(Int, n, d, m)
    for j in 1:d, i in 1:n

        bits[i, j, :] .= to_bin(x[i, j], m)
    end
    return bits
end

"""
    cranley_patterson_shift!(x::AbstractMatrix, shift::AbstractVector)

Apply a Cranley-Patterson (random) shift: x[i,j] = mod(x[i,j] + shift[j], 1).
Standard randomization for lattice rules.
"""
function cranley_patterson_shift!(x::AbstractMatrix, shift::AbstractVector)
    n, d = size(x)
    @assert length(shift) == d
    @inbounds for j in 1:d, i in 1:n

        x[i, j] = mod(x[i, j] + shift[j], 1.0)
    end
    return x
end

cranley_patterson_shift(x, shift) = cranley_patterson_shift!(copy(x), shift)
gen_cranley_patterson_shift(d::Int; rng = Random.default_rng()) = rand(rng, d)
