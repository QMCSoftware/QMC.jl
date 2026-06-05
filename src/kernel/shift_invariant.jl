"""
    KernelShiftInvar(; order=2)

Shift-invariant kernel for lattice rules, diagonalized by the DFT (FFT).

The 1D kernel of order `r` is:
``K_r(x) = 1 + (-1)^{r+1} \\frac{(2\\pi)^{2r}}{(2r)!} B_{2r}(\\{x\\})``

where ``B_{2r}`` is the Bernoulli polynomial and ``\\{x\\}`` is the fractional part.
The multivariate kernel is a product: ``K(\\mathbf{x}) = \\prod_j K_r(x_j)``.

For a rank-1 lattice the kernel matrix is **circulant**, so its eigenvalues are
obtained via a single FFT of the first column.

# Example
```julia
kernel = KernelShiftInvar(order=2)
eigenvalues = compute_kernel_eigenvalues(kernel, lattice_points)
```
"""
struct KernelShiftInvar <: AbstractKernel
    order::Int
end

function KernelShiftInvar(; order::Int=2)
    @assert order >= 1 "Kernel order must be ≥ 1"
    return KernelShiftInvar(order)
end

"""
    _kernel_1d_shift(order::Int, t::Float64) -> Float64

Evaluate the 1D shift-invariant kernel component at fractional part of `t`.

Following QMC, this uses cancellation-avoiding forms of the Bernoulli polynomial
without the (2π)^{2r}/(2r)! scaling (which is absorbed into the MLE parameter θ).
The kernel component is: 1 + const_mult * bern_poly({t}), where
  const_mult = -(-1)^r  (r = order, b_order = 2r)
For order=1: 1 + (-x(1-x) + 1/6)  [using -B₂(x) form]
For order=2: 1 - ((x(1-x))² - 1/30)  [using B₄(x) cancellation-free form]
"""
function _kernel_1d_shift(order::Int, t::Float64)
    frac_t = mod(t, 1.0)
    b_order = 2 * order
    const_mult = -((-1)^(b_order ÷ 2))
    if b_order == 2
        bern_val = -frac_t * (1.0 - frac_t) + 1.0 / 6.0
    elseif b_order == 4
        bern_val = (frac_t * (1.0 - frac_t))^2 - 1.0 / 30.0
    else
        # General fallback using Bernoulli polynomial
        bern_val = bernoulli_poly(b_order, frac_t)
    end
    return 1.0 + const_mult * bern_val
end

"""
    compute_kernel_eigenvalues(kernel::KernelShiftInvar, x::AbstractMatrix) -> Vector{Float64}

Compute eigenvalues of the circulant kernel matrix for lattice points `x` (n×d)
using FFT. Returns a vector of `n` real eigenvalues.
"""
function compute_kernel_eigenvalues(kernel::KernelShiftInvar, x::AbstractMatrix)
    n, d = size(x)
    # Build the first column of the circulant kernel matrix:
    #   K_col[i] = K(x_i - x_1) = ∏_j K_1d(x_{i,j} - x_{1,j})
    first_col = ones(n)
    # Column-major reduction: update all rows for one coordinate at a time.
    for j in 1:d
        x1j = x[1, j]
        for i in 1:n
            diff = x[i, j] - x1j
            first_col[i] *= _kernel_1d_shift(kernel.order, diff)
        end
    end
    # Eigenvalues of circulant matrix = DFT of first column
    eigenvalues = real.(FFTW.fft(first_col))
    return eigenvalues
end

Base.show(io::IO, k::KernelShiftInvar) = print(io, "KernelShiftInvar(order=$(k.order))")
