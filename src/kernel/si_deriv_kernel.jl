# Derivative-aware shift-invariant value kernel — step 1 of the derivative
# machinery (see sc_notes/DESIGN_kernel_multitask_derivs.md). Ports QMCPy's
# base `KernelShiftInvar.__call__` with derivative orders, evaluating the
# coefficient-weighted sum of mixed partial derivatives
#
#   Σ_ℓ c_ℓ · ∂_{x0}^{β0_ℓ} ∂_{x1}^{β1_ℓ} K(x0, x1)
#
# of the scaled product shift-invariant (Bernoulli) kernel
# `K(x0,x1) = scale ∏_j (1 + γ_j c_{α_j} B_{2α_j}(δ_j))`. Per dimension `j` and
# derivative term `ℓ`, with `βsum = β0[ℓ,j] + β1[ℓ,j]`, the component is
# `c·B_order(δ_j)` for `order = 2α_j − βsum` and
# `c = (−1)^{α_j+β1+1} (2π)^{2α_j}/order!`; a differentiated dimension
# (`βsum>0`) drops the constant `1` of its product term. Validated against
# QMCPy's `__call__(x0,x1,beta0,beta1,c)` to machine precision.
#
# Note: orders are bounded by `bernoulli_poly` (k ≤ 6), so `2α_j ≤ 6` for the
# undifferentiated kernel (α_j ≤ 3); higher smoothness would need `bernoulli_poly`
# extended beyond degree 6.

"""
    KernelShiftInvarDeriv(d; scale=1.0, lengthscales=2^(1/d)-1, alpha=fill(2,d))

Derivative-aware shift-invariant (Bernoulli) product kernel, port of QMCPy's base
`KernelShiftInvar`. Beyond the undifferentiated value `kernel_eval(k, x0, x1) =
scale ∏_j (1 + γ_j c_{α_j} B_{2α_j}(δ_j))`, it supports mixed partial derivatives
via [`kernel_eval_deriv`](@ref). Smoothness `alpha` is bounded by `bernoulli_poly`
(degree ≤ 6), so `2α_j ≤ 6` for the undifferentiated kernel.

# Examples
```jldoctest
julia> using QMC

julia> k = KernelShiftInvarDeriv(2)
KernelShiftInvarDeriv(d=2, alpha=[2, 2], scale=1.0)

julia> round(kernel_eval(k, [0.1, 0.2], [0.4, 0.5]); digits=6)
0.504654
```
"""
struct KernelShiftInvarDeriv <: AbstractKernel
    d::Int
    scale::Float64
    lengthscales::Vector{Float64}
    alpha::Vector{Int}        # per-dimension smoothness, ≥ 1
end

function KernelShiftInvarDeriv(d::Int; scale::Float64=1.0, lengthscales=nothing, alpha=nothing)
    ls = lengthscales === nothing ? _default_si_lengthscales(d) : collect(Float64, lengthscales)
    al = alpha === nothing ? fill(2, d) : collect(Int, alpha)
    length(ls) == d || throw(ArgumentError("lengthscales must have length d=$d"))
    length(al) == d || throw(ArgumentError("alpha must have length d=$d"))
    all(>=(1), al) || throw(ArgumentError("alpha entries must be ≥ 1"))
    return KernelShiftInvarDeriv(d, scale, ls, al)
end

# per-dimension component coeff·B_order(δ), order = 2α − (β0+β1)
function _si_deriv_perdim(alpha::Int, b0::Int, b1::Int, delta::Float64)
    order = 2 * alpha - (b0 + b1)
    order >= 2 ||
        throw(ArgumentError("derivative order too high: 2α-(β0+β1) must be ≥ 2, got $order"))
    coeff = (-1.0)^(alpha + b1 + 1) * exp(2 * alpha * log(2π) - loggamma(order + 1))
    return coeff * bernoulli_poly(order, delta)
end

"""
    kernel_eval_deriv(k::KernelShiftInvarDeriv, x0, x1, beta0, beta1, c)

Evaluate `Σ_ℓ c_ℓ ∂_{x0}^{β0_ℓ} ∂_{x1}^{β1_ℓ} K(x0,x1)` where `beta0`, `beta1`
are `(p, d)` integer derivative-order matrices (one row per term) and `c` is a
length-`p` coefficient vector.
"""
function kernel_eval_deriv(
    k::KernelShiftInvarDeriv,
    x0::AbstractVector,
    x1::AbstractVector,
    beta0::AbstractMatrix{<:Integer},
    beta1::AbstractMatrix{<:Integer},
    c::AbstractVector,
)
    p = size(beta0, 1)
    (size(beta0) == (p, k.d) && size(beta1) == (p, k.d) && length(c) == p) ||
        throw(ArgumentError("beta0/beta1 must be (p, d=$(k.d)) and c must have length p"))
    total = 0.0
    @inbounds for l in 1:p
        prod = 1.0
        for j in 1:k.d
            b0 = Int(beta0[l, j])
            b1 = Int(beta1[l, j])
            delta = mod(x0[j] - x1[j], 1.0)
            ind = (b0 + b1 == 0) ? 1.0 : 0.0
            prod *= (ind + k.lengthscales[j] * _si_deriv_perdim(k.alpha[j], b0, b1, delta))
        end
        total += c[l] * prod
    end
    return k.scale * total
end

"Single-term convenience (`c = 1`) taking length-`d` derivative-order vectors."
function kernel_eval_deriv(
    k::KernelShiftInvarDeriv,
    x0::AbstractVector,
    x1::AbstractVector,
    beta0::AbstractVector{<:Integer},
    beta1::AbstractVector{<:Integer},
)
    return kernel_eval_deriv(
        k,
        x0,
        x1,
        reshape(collect(Int, beta0), 1, :),
        reshape(collect(Int, beta1), 1, :),
        [1.0],
    )
end

# Undifferentiated kernel value.
function kernel_eval(k::KernelShiftInvarDeriv, x0::AbstractVector, x1::AbstractVector)
    z = zeros(Int, 1, k.d)
    return kernel_eval_deriv(k, x0, x1, z, z, [1.0])
end

function kernel_matrix(k::KernelShiftInvarDeriv, X::AbstractMatrix)
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

Base.show(io::IO, k::KernelShiftInvarDeriv) =
    print(io, "KernelShiftInvarDeriv(d=$(k.d), alpha=$(k.alpha), scale=$(k.scale))")
