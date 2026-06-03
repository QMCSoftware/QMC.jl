"""
    SensitivityIndices(integrand::AbstractIntegrand; indices=:singletons)

Sobol' sensitivity indices (first-order and total) via pick-freeze estimation.

Uses Owen's pick-freeze estimator (Appendix A, Equations A.16 and A.18).
The integrand must have dimension d; this wrapper uses 2d dimensions internally
to generate independent samples X and Z.

# Arguments
- `integrand`: The base integrand whose sensitivity is being analyzed.
- `indices`: Which subsets to compute. Options:
  - `:singletons` (default): one index per dimension (d subsets)
  - `:all`: all non-trivial subsets (2^d - 2 subsets, expensive for large d)
  - `Matrix{Bool}`: custom k × d matrix where each row is a subset indicator

# Returns from `evaluate`
A matrix of size `(n, 3, k)` where k is the number of index subsets:
- `[:, 1, j]` = f(X) * (f(V_j) - f(Z)) — closed (first-order) numerator
- `[:, 2, j]` = (f(Z) - f(V_j))^2 / 2 — total index numerator
- `[:, 3, j]` = f(X)^2 — for variance estimation

# Example
```julia
dd = DigitalNetB2(8; seed=7)   # 2d = 8, so d = 4
tm = Gaussian(dd)
f = Keister(tm)
si = SensitivityIndices(f)
x = transform(tm, gen_samples(dd, 2^12))
y = evaluate(si, x)
# y has shape (4096, 3, 4)
mu = mean(y[:, 1, :], dims=1)           # closed numerator means
var_est = mean(y[:, 3, :], dims=1) .- mean(sqrt.(y[:, 3, :]), dims=1).^2
closed_indices = mu ./ var_est
```

# References
1. Owen, A.B. "Monte Carlo theory, methods and examples." Appendix A, 2013.
2. Sorokin, Rathinavel. "On Bounding and Approximating Functions of Multiple
   Expectations Using Quasi-Monte Carlo." MCQMC 2022.
"""
struct SensitivityIndices{TM <: AbstractTrueMeasure, BI <: AbstractIntegrand} <:
       AbstractIntegrand
    true_measure::TM
    dimension::Int        # 2 * d_base
    base_integrand::BI
    d_base::Int           # original integrand dimension
    indices::Matrix{Bool} # k × d_base, each row is a subset indicator
end

function Base.getproperty(si::SensitivityIndices, name::Symbol)
    if name === :d_original
        return getfield(si, :d_base)
    end
    return getfield(si, name)
end

function SensitivityIndices(integrand::AbstractIntegrand; indices = :singletons)
    d_base = integrand.dimension
    d_base > 1 || throw(ArgumentError("SensitivityIndices requires dimension > 1"))

    if indices == :singletons
        idx_mat = Matrix{Bool}(I(d_base))  # d × d identity = singleton subsets
    elseif indices == :all
        # All non-trivial subsets (exclude empty set and full set)
        n_subsets = (1 << d_base) - 2
        idx_mat = Matrix{Bool}(undef, n_subsets, d_base)
        row = 1
        for i in 1:((1 << d_base) - 2)
            for j in 1:d_base
                idx_mat[row, j] = ((i >> (j - 1)) & 1) == 1
            end
            row += 1
        end
    elseif indices isa Matrix{Bool}
        size(indices, 2) == d_base || throw(
            ArgumentError(
                "indices must have $(d_base) columns, got $(size(indices, 2))"),
        )
        idx_mat = indices
    else
        throw(ArgumentError("indices must be :singletons, :all, or a Matrix{Bool}"))
    end

    # The wrapper uses 2 * d_base dimensions
    tm = integrand.true_measure
    return SensitivityIndices(tm, 2 * d_base, integrand, d_base, idx_mat)
end

function evaluate(si::SensitivityIndices, x::AbstractMatrix)
    n = size(x, 1)
    d = si.d_base
    k = size(si.indices, 1)

    # Split into X (first d dims) and Z (last d dims)
    X = x[:, 1:d]
    Z = x[:, (d + 1):2d]

    # Evaluate f(X) and f(Z)
    f_X = evaluate(si.base_integrand, X)
    f_Z = evaluate(si.base_integrand, Z)

    # Output: n × 3 × k
    y = Array{Float64}(undef, n, 3, k)

    for j in 1:k
        # Build V_j: X on subset, Z on complement
        V = copy(Z)
        for col in 1:d
            if si.indices[j, col]
                V[:, col] .= X[:, col]
            end
        end
        f_V = evaluate(si.base_integrand, V)

        @inbounds for i in 1:n
            y[i, 1, j] = f_X[i] * (f_V[i] - f_Z[i])       # closed/first-order numerator (A.18)
            y[i, 2, j] = (f_Z[i] - f_V[i])^2 / 2           # total index numerator (A.16)
            y[i, 3, j] = f_X[i]^2                            # for variance: E[f²]
        end
    end

    return y
end

"""
    compute_sensitivity_indices(si::SensitivityIndices, x::AbstractMatrix)

Convenience function that evaluates and computes the Sobol' indices directly.
Returns `(closed_indices, total_indices)`, each a vector of length k.
"""
function compute_sensitivity_indices(si::SensitivityIndices, x::AbstractMatrix)
    y = evaluate(si, x)
    k = size(y, 3)

    # Need f(X) values to estimate variance
    d = si.d_base
    X = x[:, 1:d]
    f_X = evaluate(si.base_integrand, X)
    mu_f = mean(f_X)
    sigma2 = mean(f_X .^ 2) - mu_f^2
    sigma2 = max(sigma2, 1e-300)

    closed = Vector{Float64}(undef, k)
    total = Vector{Float64}(undef, k)

    for j in 1:k
        closed[j] = mean(@view(y[:, 1, j])) / sigma2
        total[j] = mean(@view(y[:, 2, j])) / sigma2
    end

    return closed, total
end

function Base.show(io::IO, si::SensitivityIndices)
    k = size(si.indices, 1)
    print(
        io,
        "SensitivityIndices(d=$(si.d_base), subsets=$k, " *
        "base=$(typeof(si.base_integrand).name.name))",
    )
end
