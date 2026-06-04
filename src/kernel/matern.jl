"""
Matérn kernel family for Bayesian QMC.

Provides Matérn-1/2, Matérn-3/2, Matérn-5/2, and Gaussian (RBF / squared
exponential) kernels. These kernels are parameterized by a length-scale ℓ
and an output scale σ².

    k(r) = σ² · m(r/ℓ)

where r = |x - x'| and m depends on the kernel variant:

- **Matérn-1/2 (Exponential):** m(z) = exp(-z)
- **Matérn-3/2:** m(z) = (1 + √3 z) exp(-√3 z)
- **Matérn-5/2:** m(z) = (1 + √5 z + 5z²/3) exp(-√5 z)
- **Gaussian (RBF):** m(z) = exp(-z²/2)
"""

"""
    AbstractStationaryKernel <: AbstractKernel

Abstract supertype for stationary (distance-based) kernels.
Subtypes must implement `kernel_eval(k, r::Float64)` where `r` is the Euclidean distance.
"""
abstract type AbstractStationaryKernel <: AbstractKernel end

# ──────────────────────────────────────────────────────────────────────────────
# Matérn-1/2 (Exponential)
# ──────────────────────────────────────────────────────────────────────────────
"""
    KernelMatern12(; lengthscale=1.0, outputscale=1.0)

Matérn-1/2 (exponential) kernel: k(r) = σ² exp(-r/ℓ).
"""
struct KernelMatern12 <: AbstractStationaryKernel
    lengthscale::Float64
    outputscale::Float64
end

function KernelMatern12(; lengthscale::Float64 = 1.0, outputscale::Float64 = 1.0)
    lengthscale > 0 || throw(ArgumentError("lengthscale must be positive"))
    outputscale > 0 || throw(ArgumentError("outputscale must be positive"))
    return KernelMatern12(lengthscale, outputscale)
end

"""
    kernel_eval(k::AbstractStationaryKernel, r::Float64) -> Float64

Evaluate kernel `k` at distance `r`. Each kernel subtype has its own method.
"""
function kernel_eval(k::KernelMatern12, r::Float64)
    return k.outputscale * exp(-r / k.lengthscale)
end

# ──────────────────────────────────────────────────────────────────────────────
# Matérn-3/2
# ──────────────────────────────────────────────────────────────────────────────
"""
    KernelMatern32(; lengthscale=1.0, outputscale=1.0)

Matérn-3/2 kernel: k(r) = σ² (1 + √3 r/ℓ) exp(-√3 r/ℓ).
"""
struct KernelMatern32 <: AbstractStationaryKernel
    lengthscale::Float64
    outputscale::Float64
end

function KernelMatern32(; lengthscale::Float64 = 1.0, outputscale::Float64 = 1.0)
    lengthscale > 0 || throw(ArgumentError("lengthscale must be positive"))
    outputscale > 0 || throw(ArgumentError("outputscale must be positive"))
    return KernelMatern32(lengthscale, outputscale)
end

function kernel_eval(k::KernelMatern32, r::Float64)
    z = sqrt(3.0) * r / k.lengthscale
    return k.outputscale * (1.0 + z) * exp(-z)
end

# ──────────────────────────────────────────────────────────────────────────────
# Matérn-5/2
# ──────────────────────────────────────────────────────────────────────────────
"""
    KernelMatern52(; lengthscale=1.0, outputscale=1.0)

Matérn-5/2 kernel: k(r) = σ² (1 + √5 r/ℓ + 5r²/(3ℓ²)) exp(-√5 r/ℓ).
"""
struct KernelMatern52 <: AbstractStationaryKernel
    lengthscale::Float64
    outputscale::Float64
end

function KernelMatern52(; lengthscale::Float64 = 1.0, outputscale::Float64 = 1.0)
    lengthscale > 0 || throw(ArgumentError("lengthscale must be positive"))
    outputscale > 0 || throw(ArgumentError("outputscale must be positive"))
    return KernelMatern52(lengthscale, outputscale)
end

function kernel_eval(k::KernelMatern52, r::Float64)
    z = sqrt(5.0) * r / k.lengthscale
    return k.outputscale * (1.0 + z + z^2 / 3.0) * exp(-z)
end

# ──────────────────────────────────────────────────────────────────────────────
# Gaussian (RBF / Squared Exponential)
# ──────────────────────────────────────────────────────────────────────────────
"""
    KernelGaussian(; lengthscale=1.0, outputscale=1.0)

Gaussian (RBF / squared exponential) kernel: k(r) = σ² exp(-r²/(2ℓ²)).
"""
struct KernelGaussian <: AbstractStationaryKernel
    lengthscale::Float64
    outputscale::Float64
end

function KernelGaussian(; lengthscale::Float64 = 1.0, outputscale::Float64 = 1.0)
    lengthscale > 0 || throw(ArgumentError("lengthscale must be positive"))
    outputscale > 0 || throw(ArgumentError("outputscale must be positive"))
    return KernelGaussian(lengthscale, outputscale)
end

function kernel_eval(k::KernelGaussian, r::Float64)
    z = r / k.lengthscale
    return k.outputscale * exp(-0.5 * z^2)
end

# ──────────────────────────────────────────────────────────────────────────────
# Rational Quadratic
# ──────────────────────────────────────────────────────────────────────────────
"""
    KernelRationalQuadratic(; lengthscale=1.0, outputscale=1.0, alpha=1.0)

Rational-quadratic kernel: k(r) = σ² (1 + r²/(2 α ℓ²))^(-α), the scale-mixture of
Gaussian kernels with mixture parameter `alpha` (α > 0). As `alpha → ∞` it
converges to the Gaussian (RBF) kernel `σ² exp(-r²/(2ℓ²))`.

Matches QMCPy's `KernelRationalQuadratic`: with distance
`d_γ = ‖(x - z)/(√2 ℓ)‖₂`, k = σ² (1 + d_γ²/α)^(-α) = σ² (1 + r²/(2 α ℓ²))^(-α).
"""
struct KernelRationalQuadratic <: AbstractStationaryKernel
    lengthscale::Float64
    outputscale::Float64
    alpha::Float64
end

function KernelRationalQuadratic(; lengthscale::Float64 = 1.0,
    outputscale::Float64 = 1.0, alpha::Float64 = 1.0)
    lengthscale > 0 || throw(ArgumentError("lengthscale must be positive"))
    outputscale > 0 || throw(ArgumentError("outputscale must be positive"))
    alpha > 0 || throw(ArgumentError("alpha must be positive"))
    return KernelRationalQuadratic(lengthscale, outputscale, alpha)
end

function kernel_eval(k::KernelRationalQuadratic, r::Float64)
    z2 = (r / k.lengthscale)^2
    return k.outputscale * (1.0 + z2 / (2.0 * k.alpha))^(-k.alpha)
end

# ──────────────────────────────────────────────────────────────────────────────
# Kernel matrix construction (common to all stationary kernels)
# ──────────────────────────────────────────────────────────────────────────────
"""
    kernel_matrix(k::AbstractStationaryKernel, x::AbstractMatrix) -> Matrix{Float64}

Build the n×n kernel matrix K[i,j] = k(‖xᵢ - xⱼ‖) for points x (n × d).
"""
function kernel_matrix(k::AbstractStationaryKernel, x::AbstractMatrix)
    n, d = size(x)
    K = Matrix{Float64}(undef, n, n)
    @inbounds for j in 1:n
        K[j, j] = kernel_eval(k, 0.0)
        for i in (j + 1):n
            r = 0.0
            for dim in 1:d
                r += (x[i, dim] - x[j, dim])^2
            end
            r = sqrt(r)
            kval = kernel_eval(k, r)
            K[i, j] = kval
            K[j, i] = kval
        end
    end
    return K
end

# ──────────────────────────────────────────────────────────────────────────────
# Combined (Sum/Product) kernels
# ──────────────────────────────────────────────────────────────────────────────
"""
    SumKernel(k1::AbstractKernel, k2::AbstractKernel)

Sum of two kernels: k(r) = k₁(r) + k₂(r).
"""
struct SumKernel <: AbstractKernel
    k1::AbstractKernel
    k2::AbstractKernel
end

function kernel_eval(k::SumKernel, r::Float64)
    return kernel_eval(k.k1, r) + kernel_eval(k.k2, r)
end

"""
    ProductKernel(k1::AbstractKernel, k2::AbstractKernel)

Product of two kernels: k(r) = k₁(r) · k₂(r).
"""
struct ProductKernel <: AbstractKernel
    k1::AbstractKernel
    k2::AbstractKernel
end

function kernel_eval(k::ProductKernel, r::Float64)
    return kernel_eval(k.k1, r) * kernel_eval(k.k2, r)
end

# Convenience operators
Base.:+(k1::AbstractKernel, k2::AbstractKernel) = SumKernel(k1, k2)
Base.:*(k1::AbstractKernel, k2::AbstractKernel) = ProductKernel(k1, k2)

function Base.show(io::IO, k::KernelMatern12)
    print(io, "KernelMatern12(ℓ=$(k.lengthscale), σ²=$(k.outputscale))")
end
function Base.show(io::IO, k::KernelMatern32)
    print(io, "KernelMatern32(ℓ=$(k.lengthscale), σ²=$(k.outputscale))")
end
function Base.show(io::IO, k::KernelMatern52)
    print(io, "KernelMatern52(ℓ=$(k.lengthscale), σ²=$(k.outputscale))")
end
function Base.show(io::IO, k::KernelGaussian)
    print(io, "KernelGaussian(ℓ=$(k.lengthscale), σ²=$(k.outputscale))")
end
function Base.show(io::IO, k::KernelRationalQuadratic)
    print(
        io,
        "KernelRationalQuadratic(ℓ=$(k.lengthscale), σ²=$(k.outputscale), α=$(k.alpha))",
    )
end
function Base.show(io::IO, k::SumKernel)
    print(io, "($(k.k1) + $(k.k2))")
end
function Base.show(io::IO, k::ProductKernel)
    print(io, "($(k.k1) * $(k.k2))")
end
