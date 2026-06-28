# KernelMultiTaskDerivs — step 3 of the derivative machinery (see
# sc_notes/DESIGN_kernel_multitask_derivs.md). Port of QMCPy's
# `KernelMultiTaskDerivs`: a multi-task kernel over a differentiable base value
# kernel with a fixed all-ones task covariance. Because the task matrix is
# identically 1, the cross-covariance between any two tasks is just the base
# kernel's derivative-weighted value
#   K((i0,x0),(i1,x1); β0,β1,c) = Σ_ℓ c_ℓ ∂_{x0}^{β0_ℓ} ∂_{x1}^{β1_ℓ} K_base(x0,x1),
# so the task indices select which derivative observation is being related — the
# derivative orders are supplied explicitly per evaluation. The base kernel must
# support `kernel_eval_deriv` (e.g. `KernelShiftInvarDeriv`,
# `KernelDigShiftInvarDeriv`).

"""
    KernelMultiTaskDerivs(base_kernel, num_tasks)

Multi-task kernel over a differentiable base value kernel with an all-ones task
covariance (port of QMCPy's `KernelMultiTaskDerivs`). Use with a base kernel
supporting [`kernel_eval_deriv`](@ref) (e.g. `KernelShiftInvarDeriv`,
`KernelDigShiftInvarDeriv`); task indices relate derivative observations whose
orders are supplied per evaluation.

# Examples
```jldoctest
julia> using QuasiMC

julia> base = KernelShiftInvarDeriv(2);

julia> k = KernelMultiTaskDerivs(base, 3)
KernelMultiTaskDerivs(base=KernelShiftInvarDeriv, num_tasks=3)

julia> round(kernel_eval(k, 1, 2, [0.1, 0.2], [0.4, 0.5]); digits=6)
0.504654
```
"""
struct KernelMultiTaskDerivs{K} <: AbstractKernel
    base_kernel::K
    num_tasks::Int
    taskmat::Matrix{Float64}   # all ones, num_tasks × num_tasks
end

function KernelMultiTaskDerivs(base_kernel, num_tasks::Int)
    num_tasks >= 1 || throw(ArgumentError("num_tasks must be ≥ 1, got $num_tasks"))
    return KernelMultiTaskDerivs(base_kernel, num_tasks, ones(num_tasks, num_tasks))
end

@inline function _check_tasks(k::KernelMultiTaskDerivs, t0::Integer, t1::Integer)
    (1 <= t0 <= k.num_tasks && 1 <= t1 <= k.num_tasks) ||
        throw(ArgumentError("task indices must be in 1..$(k.num_tasks), got ($t0, $t1)"))
end

"""
    kernel_eval_deriv(k::KernelMultiTaskDerivs, task0, task1, x0, x1, beta0, beta1, c)

Multi-task derivative kernel value `taskmat[task0,task1] · Σ_ℓ c_ℓ
∂^{β0_ℓ}∂^{β1_ℓ} K_base(x0,x1)`. With the all-ones task covariance this equals
the base kernel's derivative value for any task indices.
"""
function kernel_eval_deriv(
    k::KernelMultiTaskDerivs,
    task0::Integer,
    task1::Integer,
    x0::AbstractVector,
    x1::AbstractVector,
    beta0::AbstractMatrix{<:Integer},
    beta1::AbstractMatrix{<:Integer},
    c::AbstractVector,
)
    _check_tasks(k, task0, task1)
    return k.taskmat[task0, task1] * kernel_eval_deriv(k.base_kernel, x0, x1, beta0, beta1, c)
end

"Single-term convenience (`c = 1`) taking length-`d` derivative-order vectors."
function kernel_eval_deriv(
    k::KernelMultiTaskDerivs,
    task0::Integer,
    task1::Integer,
    x0::AbstractVector,
    x1::AbstractVector,
    beta0::AbstractVector{<:Integer},
    beta1::AbstractVector{<:Integer},
)
    _check_tasks(k, task0, task1)
    return k.taskmat[task0, task1] * kernel_eval_deriv(k.base_kernel, x0, x1, beta0, beta1)
end

"Undifferentiated multi-task kernel value `taskmat[task0,task1] · K_base(x0,x1)`."
function kernel_eval(
    k::KernelMultiTaskDerivs,
    task0::Integer,
    task1::Integer,
    x0::AbstractVector,
    x1::AbstractVector,
)
    _check_tasks(k, task0, task1)
    return k.taskmat[task0, task1] * kernel_eval(k.base_kernel, x0, x1)
end

Base.show(io::IO, k::KernelMultiTaskDerivs) = print(
    io,
    "KernelMultiTaskDerivs(base=$(typeof(k.base_kernel).name.name), num_tasks=$(k.num_tasks))",
)
