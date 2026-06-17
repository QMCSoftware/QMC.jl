# Derivative-aware digitally-shift-invariant (Walsh) value kernel — step 2 of the
# derivative machinery (see sc_notes/DESIGN_kernel_multitask_derivs.md). Ports
# QMCPy 2.3's base `KernelDigShiftInvar.__call__` with derivative orders.
#
# Per dimension `j` and derivative term `ℓ`, with `βsum = β0[ℓ,j] + β1[ℓ,j]`,
# `δ_j = bin(x0_j) ⊻ bin(x1_j)` over `t` bits, `order = α_j − βsum`:
#   kpart = (order == 1) ? order-1 closed form : weighted_walsh(order, δ_j, t) − 1
#   kperdim = (−2)^βsum · (1·(βsum>0) + kpart)
# and the kernel is `scale Σ_ℓ c_ℓ ∏_j (1·(βsum==0) + γ_j kperdim_{ℓ,j})`.
# Reuses `_to_bin_b2`, `_weighted_walsh_funcs`, `_default_si_lengthscales` from
# `si_dsi_value_kernels.jl`. Validated against QMCPy's `__call__` to machine
# precision.
#
# Derivative-order rules (from QMCPy): `1 ≤ order ≤ 4`, and differentiating the
# order-2 kernel is unsupported (`order == 1` with `α > 1` is rejected). In
# practice first derivatives require `α ≥ 3` and DSI derivatives depend only on
# `βsum`, not the β0/β1 split.

"""
    KernelDigShiftInvarDeriv(d, t; scale=1.0, lengthscales=2^(1/d)-1, alpha=fill(2,d))

Derivative-aware digitally-shift-invariant (Walsh) value kernel, port of QMCPy's
base `KernelDigShiftInvar`. `kernel_eval(k, x0, x1)` gives the undifferentiated
value; [`kernel_eval_deriv`](@ref) evaluates mixed partial derivatives. DSI
derivatives require `α ≥ 3` (the order-2 kernel cannot be differentiated) and
depend only on `β0 + β1`.

# Examples
```jldoctest
julia> using QMC

julia> k = KernelDigShiftInvarDeriv(2, 32)
KernelDigShiftInvarDeriv(d=2, t=32, alpha=[2, 2], scale=1.0)

julia> round(kernel_eval(k, [0.1, 0.2], [0.4, 0.5]); digits=6)
0.771478
```
"""
struct KernelDigShiftInvarDeriv <: AbstractKernel
    d::Int
    t::Int
    scale::Float64
    lengthscales::Vector{Float64}
    alpha::Vector{Int}        # per-dimension, 1..4
end

function KernelDigShiftInvarDeriv(
    d::Int,
    t::Int;
    scale::Float64=1.0,
    lengthscales=nothing,
    alpha=nothing,
)
    ls = lengthscales === nothing ? _default_si_lengthscales(d) : collect(Float64, lengthscales)
    al = alpha === nothing ? fill(2, d) : collect(Int, alpha)
    length(ls) == d || throw(ArgumentError("lengthscales must have length d=$d"))
    length(al) == d || throw(ArgumentError("alpha must have length d=$d"))
    all(a -> 1 <= a <= 4, al) || throw(ArgumentError("alpha entries must be in 1..4"))
    return KernelDigShiftInvarDeriv(d, t, scale, ls, al)
end

# per-dimension component (−2)^βsum (ind + kpart), order = α − βsum
function _dsi_deriv_perdim(alpha::Int, b0::Int, b1::Int, delta::UInt64, t::Int)
    bsum = b0 + b1
    order = alpha - bsum
    (1 <= order <= 4) ||
        throw(ArgumentError("DSI derivative order $order out of 1..4 (increase alpha)"))
    (order == 1 && alpha > 1) && throw(
        ArgumentError(
            "differentiating the order-2 digitally-shift-invariant kernel is unsupported",
        ),
    )
    ind = bsum > 0 ? 1.0 : 0.0
    if order == 1
        if delta == 0
            kpart = 1.0
        else
            flog2 = floor(log2(Float64(delta))) - t
            kpart = 6 * (1.0 / 6.0 - 2.0^(flog2 - 1))
        end
    else
        kpart = _weighted_walsh_funcs(order, delta, t) - 1
    end
    return ((-2.0)^bsum) * (ind + kpart)
end

"""
    kernel_eval_deriv(k::KernelDigShiftInvarDeriv, x0, x1, beta0, beta1, c)

Evaluate `Σ_ℓ c_ℓ ∂_{x0}^{β0_ℓ} ∂_{x1}^{β1_ℓ} K(x0,x1)` for the digitally-shift-
invariant kernel; `beta0`, `beta1` are `(p, d)` integer matrices, `c` length `p`.
"""
function kernel_eval_deriv(
    k::KernelDigShiftInvarDeriv,
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
            delta = _to_bin_b2(x0[j], k.t) ⊻ _to_bin_b2(x1[j], k.t)
            ind = (b0 + b1 == 0) ? 1.0 : 0.0
            prod *=
                (ind + k.lengthscales[j] * _dsi_deriv_perdim(k.alpha[j], b0, b1, delta, k.t))
        end
        total += c[l] * prod
    end
    return k.scale * total
end

"Single-term convenience (`c = 1`) taking length-`d` derivative-order vectors."
function kernel_eval_deriv(
    k::KernelDigShiftInvarDeriv,
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

function kernel_eval(k::KernelDigShiftInvarDeriv, x0::AbstractVector, x1::AbstractVector)
    z = zeros(Int, 1, k.d)
    return kernel_eval_deriv(k, x0, x1, z, z, [1.0])
end

function kernel_matrix(k::KernelDigShiftInvarDeriv, X::AbstractMatrix)
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

Base.show(io::IO, k::KernelDigShiftInvarDeriv) = print(
    io,
    "KernelDigShiftInvarDeriv(d=$(k.d), t=$(k.t), alpha=$(k.alpha), scale=$(k.scale))",
)
