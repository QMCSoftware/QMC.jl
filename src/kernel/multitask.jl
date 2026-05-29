"""
    KernelMultiTask(base_kernel, num_tasks; factor, diag)

Multi-task (multi-output) kernel:

  K((i,x), (j,z)) = K_task(i,j) · K_base(x,z)

where the task correlation matrix is

  K_task = F · F' + diag(v)

with factor matrix F ∈ ℝ^{T×r} and diagonal v ∈ ℝ^T.

# Arguments
- `base_kernel::AbstractKernel`: spatial kernel K_base(x, z)
- `num_tasks::Int`: number of tasks T
- `factor::Matrix{Float64}`: factor matrix F (T × r), default zeros(T, 1)
- `diag::Vector{Float64}`: diagonal v, default ones(T)

# Example
```julia
base = KernelGaussian(2)
kmt = KernelMultiTask(base, 3; diag=[1.0, 2.0, 3.0])
# Task correlation matrix is I + diag([1,2,3])
```
"""
struct KernelMultiTask <: AbstractKernel
    base_kernel::AbstractKernel
    num_tasks::Int
    factor::Matrix{Float64}
    diag_vec::Vector{Float64}
    taskmat::Matrix{Float64}  # precomputed F*F' + diag(v)
end

function KernelMultiTask(base_kernel::AbstractKernel, num_tasks::Int;
        factor::Matrix{Float64} = zeros(num_tasks, 1),
        diag::Vector{Float64} = ones(num_tasks))
    num_tasks > 0 || throw(ArgumentError("num_tasks must be > 0"))
    size(factor, 1) == num_tasks || throw(ArgumentError(
        "factor must have $num_tasks rows, got $(size(factor, 1))"))
    length(diag) == num_tasks || throw(ArgumentError(
        "diag must have length $num_tasks, got $(length(diag))"))

    taskmat = factor * factor' + LinearAlgebra.Diagonal(diag)
    return KernelMultiTask(base_kernel, num_tasks, factor, diag, Matrix(taskmat))
end

"""
    kernel_eval(kmt::KernelMultiTask, task_i, task_j, x, z)

Evaluate K((task_i, x), (task_j, z)) = taskmat[task_i, task_j] * K_base(x, z).
Task indices are 1-based.
"""
function kernel_eval(kmt::KernelMultiTask, task_i::Int, task_j::Int,
        x::AbstractVector, z::AbstractVector)
    return kmt.taskmat[task_i, task_j] * kernel_eval(kmt.base_kernel, x, z)
end

"""
    kernel_matrix(kmt::KernelMultiTask, tasks, X)

Build the full (T·n) × (T·n) kernel matrix for tasks ∈ 1:T and data X (n × d).
Rows/columns are ordered as (task_1, x_1), (task_1, x_2), ..., (task_T, x_n).
"""
function kernel_matrix(kmt::KernelMultiTask, tasks::AbstractVector{Int},
        X::AbstractMatrix)
    T = length(tasks)
    n = size(X, 1)
    N = T * n

    # Base spatial kernel matrix
    K_base = kernel_matrix(kmt.base_kernel, X)

    # Full multitask kernel via Kronecker product: K_task ⊗ K_base
    K_full = Matrix{Float64}(undef, N, N)
    for (ti, i) in enumerate(tasks), (tj, j) in enumerate(tasks)
        tval = kmt.taskmat[i, j]
        for a in 1:n, b in 1:n
            K_full[(ti-1)*n + a, (tj-1)*n + b] = tval * K_base[a, b]
        end
    end

    return K_full
end

function Base.show(io::IO, kmt::KernelMultiTask)
    r = size(kmt.factor, 2)
    print(io, "KernelMultiTask(T=$(kmt.num_tasks), rank=$r, base=$(kmt.base_kernel))")
end
