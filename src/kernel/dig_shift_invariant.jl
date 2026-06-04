"""
    KernelDigShiftInvar(; order=2)

Digitally shift-invariant kernel for digital net (base 2) rules.
Diagonalized by the Walsh-Hadamard Transform (WHT).

``K(\\mathbf{x}, \\mathbf{y}) = K(\\mathbf{x} \\oplus \\mathbf{y})``

where ``\\oplus`` is the bitwise XOR operation on the binary representations.
The 1D kernel of order `r` is based on Walsh series coefficients.

# Example
```julia
kernel = KernelDigShiftInvar(order=2)
eigenvalues = compute_kernel_eigenvalues(kernel, sobol_points)
```
"""
struct KernelDigShiftInvar <: AbstractKernel
    order::Int
end

function KernelDigShiftInvar(; order::Int=2)
    @assert order >= 1 "Kernel order must be ≥ 1"
    return KernelDigShiftInvar(order)
end

"""
    _xor_float(a::Float64, b::Float64; nbits::Int=30) -> Float64

XOR two floats in [0,1) by treating their binary expansions as integers.
"""
function _xor_float(a::Float64, b::Float64; nbits::Int=30)
    scale = 2^nbits
    ia = floor(Int64, a * scale)
    ib = floor(Int64, b * scale)
    return (ia ⊻ ib) / scale
end

"""
    _dig_kernel_1d(order::Int, t::Float64; nbits::Int=30) -> Float64

Evaluate the 1D digitally shift-invariant kernel.
For order `r`, the kernel in Walsh-function domain has decay `|ω|^{-2r}`.

Implementation uses the explicit formula:
``K_r(x) = 1 + \\sum_{l=1}^{m} x_l \\cdot \\prod_{k=1}^{l} c_{r,k}``

where ``x_l`` are the binary digits of ``x``, and ``c_{r,k}`` encodes the
Walsh decay. For the standard order-2 kernel:

``K_2(x) = 1 + \\sum_{l=1}^{m} (-1)^{b_l} \\cdot 2^{-2l}``

Simplified: use the digital analog of Bernoulli polynomials.
"""
function _dig_kernel_1d(order::Int, t::Float64; nbits::Int=30)
    if abs(t) < 1e-15
        return 1.0  # K(0) = 1 + sum of positive terms (kernel at origin)
    end
    r = order
    val = 1.0
    # Binary expansion of t
    remaining = t
    for l in 1:nbits
        remaining *= 2.0
        bit = floor(Int, remaining)
        remaining -= bit
        # Each bit contributes to the kernel value
        # Weight decays as 2^{-2r*l} for order r
        if bit == 1
            val += (-1)^(r + 1) * (2.0^(-2r))^l
        end
        if remaining < 1e-15
            break
        end
    end
    return val
end

"""
    compute_kernel_eigenvalues(kernel::KernelDigShiftInvar, x::AbstractMatrix) -> Vector{Float64}

Compute eigenvalues of the kernel matrix for digital net points `x` (n×d)
using Walsh-Hadamard Transform. Returns a vector of `n` eigenvalues.
"""
function compute_kernel_eigenvalues(kernel::KernelDigShiftInvar, x::AbstractMatrix)
    n, d = size(x)
    @assert ispow2(n) "Number of points must be a power of 2 for WHT, got $n"
    # Build first column: K(x_i ⊕ x_1)
    first_col = ones(n)
    for i in 1:n
        for j in 1:d
            diff = _xor_float(x[i, j], x[1, j])
            first_col[i] *= _dig_kernel_1d(kernel.order, diff)
        end
    end
    # Eigenvalues via Walsh-Hadamard Transform
    eigenvalues = fwht(first_col)
    return eigenvalues
end

Base.show(io::IO, k::KernelDigShiftInvar) = print(io, "KernelDigShiftInvar(order=$(k.order))")
