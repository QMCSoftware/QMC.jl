# Value-kernel (kernel_eval / kernel_matrix) ports of QMCPy's combined and
# adaptive-alpha shift-invariant / digitally-shift-invariant kernels. These
# complement the eigenvalue-based `KernelShiftInvar` / `KernelDigShiftInvar`
# used for fast Bayesian cubature; here the kernels expose pointwise values
# K(x0, x1) for users building Gaussian-process models directly, matching
# QMCPy's `KernelShiftInvarCombined`, `KernelDigShiftInvarAdaptiveAlpha`, and
# `KernelDigShiftInvarCombined` at default (non-derivative) settings.
#
# All three are product kernels: K(x0,x1) = scale * ∏_j (1 + γ_j * kpart_j),
# differing only in the per-dimension component kpart_j. Validated against
# QMCPy's `__call__` to machine precision (see test/test_kernels.jl).

# ---- digitally-shift-invariant helpers (base-2 Walsh machinery) ----

"Binary representation of x ∈ [0,1) with `t` bits: ⌊(x mod 1)·2ᵗ⌋ as a UInt64."
_to_bin_b2(x::Real, t::Int) = floor(UInt64, mod(Float64(x), 1.0) * 2.0^t)

"""
    _k4sumterm(x::UInt64, t::Int) -> Float64

`∑_{a=0}^{t-1} (-1)^{x_a} / 2^{3a}` where `x_a` is bit `a` of `x` (MSB-first over
`t` bits). Mirrors QMCPy's `k4sumterm`; terms below `1e-8` are dropped.
"""
function _k4sumterm(x::UInt64, t::Int; cutoff::Float64=1e-8)
    total = 0.0
    for a in 0:(t - 1)
        factor = 1.0 / 2.0^(3a)
        factor < cutoff && break
        bit = (x >> (t - a - 1)) & UInt64(1)
        total += (bit == 0 ? factor : -factor)
    end
    return total
end

"""
    _weighted_walsh_funcs(alpha::Int, delta::UInt64, t::Int) -> Float64

Weighted Walsh function of order `alpha ∈ {2,3,4}` at the integer point `delta`
(`t` bits). Mirrors QMCPy's `weighted_walsh_funcs` closed forms.
"""
function _weighted_walsh_funcs(alpha::Int, delta::UInt64, t::Int)
    (alpha == 2 || alpha == 3 || alpha == 4) ||
        throw(ArgumentError("weighted Walsh order alpha must be 2, 3, or 4, got $alpha"))
    if delta == 0
        return alpha == 2 ? 5.0 / 2.0 : alpha == 3 ? 43.0 / 18.0 : 701.0 / 294.0
    end
    xf = 2.0^(-t) * Float64(delta)
    beta = -floor(log2(xf))
    if alpha == 2
        return -beta * xf + 5.0 / 2.0 * (1 - 2.0^(-beta))
    elseif alpha == 3
        return beta * xf^2 - 5 * (1 - 2.0^(-beta)) * xf + 43.0 / 18.0 * (1 - 2.0^(-2beta))
    else  # alpha == 4
        return -2.0 / 3.0 * beta * xf^3 + 5 * (1 - 2.0^(-beta)) * xf^2 -
               43.0 / 9.0 * (1 - 2.0^(-2beta)) * xf +
               701.0 / 294.0 * (1 - 2.0^(-3beta)) +
               beta * (1.0 / 48.0 * _k4sumterm(delta, t) - 1.0 / 42.0)
    end
end

_default_si_lengthscales(d::Int) = fill(2.0^(1 / d) - 1.0, d)

# ---------------------------------------------------------------------------
# KernelShiftInvarCombined
# ---------------------------------------------------------------------------
"""
    KernelShiftInvarCombined(d; scale=1.0, lengthscales=2^(1/d)-1, alpha=ones(4,d))

Combined shift-invariant (lattice) product kernel
`K(x0,x1) = scale ∏_j (1 + γ_j ∑_{a=1}^4 α_{a,j} c_a B_a(δ_j))`, where
`δ_j = (x0_j - x1_j) mod 1`, `B_a` is the degree-`a` Bernoulli polynomial, and
`c_a = (-1)^{a+1} (2π)^{2a} / (2a)!`. Port of QMCPy's `KernelShiftInvarCombined`.

# Examples
```jldoctest
julia> using QMC

julia> k = KernelShiftInvarCombined(2)
KernelShiftInvarCombined(d=2, scale=1.0)

julia> round(kernel_eval(k, [0.1, 0.2], [0.4, 0.5]); digits=6)
4.184073
```
"""
struct KernelShiftInvarCombined <: AbstractKernel
    d::Int
    scale::Float64
    lengthscales::Vector{Float64}
    alpha::Matrix{Float64}        # (4, d)
    coeffs::NTuple{4, Float64}
end

function KernelShiftInvarCombined(
    d::Int;
    scale::Float64=1.0,
    lengthscales=nothing,
    alpha=nothing,
)
    ls = lengthscales === nothing ? _default_si_lengthscales(d) : collect(Float64, lengthscales)
    al = alpha === nothing ? ones(4, d) : Matrix{Float64}(alpha)
    length(ls) == d || throw(ArgumentError("lengthscales must have length d=$d"))
    size(al) == (4, d) || throw(ArgumentError("alpha must have shape (4, d=$d)"))
    coeffs = ntuple(a -> (-1.0)^(a + 1) * (2π)^(2a) / factorial(2a), 4)
    return KernelShiftInvarCombined(d, scale, ls, al, coeffs)
end

function kernel_eval(k::KernelShiftInvarCombined, x0::AbstractVector, x1::AbstractVector)
    p = 1.0
    @inbounds for j in 1:k.d
        delta = mod(x0[j] - x1[j], 1.0)
        kperdim = 0.0
        for a in 1:4
            kperdim += k.alpha[a, j] * k.coeffs[a] * bernoulli_poly(a, delta)
        end
        p *= (1.0 + k.lengthscales[j] * kperdim)
    end
    return k.scale * p
end

Base.show(io::IO, k::KernelShiftInvarCombined) =
    print(io, "KernelShiftInvarCombined(d=$(k.d), scale=$(k.scale))")

# ---------------------------------------------------------------------------
# KernelDigShiftInvarAdaptiveAlpha
# ---------------------------------------------------------------------------
"""
    KernelDigShiftInvarAdaptiveAlpha(d, t; scale=1.0, lengthscales=2^(1/d)-1, alpha=ones(d))

Digitally-shift-invariant product kernel with per-dimension (possibly
non-integer) smoothness `alpha`. With `δ_j = bin(x0_j) ⊻ bin(x1_j)` over `t`
bits, `ν_j = 2^{α_j+1}/(2^{α_j+1}-2)`, the per-dimension component is `ν_j` when
`δ_j = 0` and `ν_j - (ν_j+1) 2^{α_j(⌊log2 δ_j⌋ - t + 1)}` otherwise; the kernel
is `scale ∏_j (1 + γ_j kpart_j)`. Port of QMCPy's `KernelDigShiftInvarAdaptiveAlpha`.
"""
struct KernelDigShiftInvarAdaptiveAlpha <: AbstractKernel
    d::Int
    t::Int
    scale::Float64
    lengthscales::Vector{Float64}
    alpha::Vector{Float64}        # per-dimension, length d
end

function KernelDigShiftInvarAdaptiveAlpha(
    d::Int,
    t::Int;
    scale::Float64=1.0,
    lengthscales=nothing,
    alpha=nothing,
)
    ls = lengthscales === nothing ? _default_si_lengthscales(d) : collect(Float64, lengthscales)
    al = alpha === nothing ? ones(d) : collect(Float64, alpha)
    length(ls) == d || throw(ArgumentError("lengthscales must have length d=$d"))
    length(al) == d || throw(ArgumentError("alpha must have length d=$d"))
    return KernelDigShiftInvarAdaptiveAlpha(d, t, scale, ls, al)
end

function kernel_eval(
    k::KernelDigShiftInvarAdaptiveAlpha,
    x0::AbstractVector,
    x1::AbstractVector,
)
    p = 1.0
    @inbounds for j in 1:k.d
        delta = _to_bin_b2(x0[j], k.t) ⊻ _to_bin_b2(x1[j], k.t)
        aj = k.alpha[j]
        p2 = 2.0^(aj + 1)
        nu = p2 / (p2 - 2)
        if delta == 0
            kpart = nu
        else
            flog2 = floor(log2(Float64(delta))) - k.t
            kpart = nu - (nu + 1) * 2.0^(aj * (flog2 + 1))
        end
        p *= (1.0 + k.lengthscales[j] * kpart)
    end
    return k.scale * p
end

Base.show(io::IO, k::KernelDigShiftInvarAdaptiveAlpha) =
    print(io, "KernelDigShiftInvarAdaptiveAlpha(d=$(k.d), t=$(k.t), scale=$(k.scale))")

# ---------------------------------------------------------------------------
# KernelDigShiftInvarCombined
# ---------------------------------------------------------------------------
"""
    KernelDigShiftInvarCombined(d, t; scale=1.0, lengthscales=2^(1/d)-1, alpha=ones(4,d))

Combined digitally-shift-invariant product kernel. With `δ_j = bin(x0_j) ⊻
bin(x1_j)` over `t` bits, the four per-dimension components are an order-1 term
`6(1/6 - 2^{⌊log2 δ_j⌋ - t - 1})` (→ 1 when `δ_j = 0`) and `weighted_walsh(a,δ_j)
- 1` for `a = 2,3,4`; the kernel is `scale ∏_j (1 + γ_j ∑_a α_{a,j} kpart_{a,j})`.
Port of QMCPy's `KernelDigShiftInvarCombined`.
"""
struct KernelDigShiftInvarCombined <: AbstractKernel
    d::Int
    t::Int
    scale::Float64
    lengthscales::Vector{Float64}
    alpha::Matrix{Float64}        # (4, d)
end

function KernelDigShiftInvarCombined(
    d::Int,
    t::Int;
    scale::Float64=1.0,
    lengthscales=nothing,
    alpha=nothing,
)
    ls = lengthscales === nothing ? _default_si_lengthscales(d) : collect(Float64, lengthscales)
    al = alpha === nothing ? ones(4, d) : Matrix{Float64}(alpha)
    length(ls) == d || throw(ArgumentError("lengthscales must have length d=$d"))
    size(al) == (4, d) || throw(ArgumentError("alpha must have shape (4, d=$d)"))
    return KernelDigShiftInvarCombined(d, t, scale, ls, al)
end

function kernel_eval(k::KernelDigShiftInvarCombined, x0::AbstractVector, x1::AbstractVector)
    p = 1.0
    @inbounds for j in 1:k.d
        delta = _to_bin_b2(x0[j], k.t) ⊻ _to_bin_b2(x1[j], k.t)
        if delta == 0
            k0 = 1.0
        else
            flog2 = floor(log2(Float64(delta))) - k.t
            k0 = 6 * (1.0 / 6.0 - 2.0^(flog2 - 1))
        end
        k1 = _weighted_walsh_funcs(2, delta, k.t) - 1
        k2 = _weighted_walsh_funcs(3, delta, k.t) - 1
        k3 = _weighted_walsh_funcs(4, delta, k.t) - 1
        kperdim =
            k.alpha[1, j] * k0 + k.alpha[2, j] * k1 + k.alpha[3, j] * k2 + k.alpha[4, j] * k3
        p *= (1.0 + k.lengthscales[j] * kperdim)
    end
    return k.scale * p
end

Base.show(io::IO, k::KernelDigShiftInvarCombined) =
    print(io, "KernelDigShiftInvarCombined(d=$(k.d), t=$(k.t), scale=$(k.scale))")

# ---- shared pairwise kernel matrix over rows of X (n × d) ----
const _SIDSIValueKernel = Union{
    KernelShiftInvarCombined,
    KernelDigShiftInvarAdaptiveAlpha,
    KernelDigShiftInvarCombined,
}

"""
    kernel_matrix(k, X) -> Matrix{Float64}

Symmetric `n × n` Gram matrix `K[i,j] = kernel_eval(k, X[i,:], X[j,:])` for the
combined / adaptive SI/DSI value kernels and points `X` (`n × d`).
"""
function kernel_matrix(k::_SIDSIValueKernel, X::AbstractMatrix)
    n = size(X, 1)
    K = Matrix{Float64}(undef, n, n)
    @inbounds for i in 1:n
        xi = @view X[i, :]
        for j in i:n
            v = kernel_eval(k, xi, @view X[j, :])
            K[i, j] = v
            K[j, i] = v
        end
    end
    return K
end
