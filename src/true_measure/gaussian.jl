"""
    Gaussian(dd::AbstractDiscreteDistribution; mean=0.0, covariance=1.0, decomp_type=:PCA)

Gaussian (Normal) measure. Transforms uniform [0,1) samples into samples from
a multivariate Gaussian distribution.

The transform first applies the inverse standard normal CDF componentwise,
then multiplies by a decomposition matrix `A` derived from the covariance,
and finally adds the mean vector:

    y = Φ⁻¹(x) * Aᵀ .+ μᵀ

# Arguments
- `dd`: a discrete distribution providing uniform samples in [0,1)^d.
- `mean`: scalar or d-vector mean. Default `0.0`.
- `covariance`: scalar, d-vector (diagonal), or d×d matrix covariance. Default `1.0`.
- `decomp_type`: `:PCA` (eigendecomposition, eigenvalues sorted descending) or
  `:Cholesky` (lower Cholesky factor). Default `:PCA`.

# Examples
```julia
dd = IIDStdUniform(2; seed=7)
tm = Gaussian(dd; mean=[1.0, 2.0], covariance=[1.0 0.5; 0.5 1.0])
x = gen_samples(dd, 256)
y = transform(tm, x)  # 256×2 Gaussian samples
```
"""
struct Gaussian{D <: AbstractDiscreteDistribution} <: AbstractTrueMeasure
    dd::D
    dimension::Int
    mean::Vector{Float64}
    covariance::Matrix{Float64}
    decomp_type::Symbol
    _decomp::Matrix{Float64}
    # Diagonal of `_decomp` when that factor is diagonal, else `nothing`. Enables an
    # O(n·d) column-scaling fast path in `transform` (see the deviation note there).
    _decomp_diag::Union{Nothing, Vector{Float64}}
end

function Gaussian(
    dd::AbstractDiscreteDistribution;
    mean=0.0,
    covariance=1.0,
    decomp_type::Symbol=:PCA,
)
    d = dd.dimension
    mu = _expand_mean(mean, d)
    cov = _expand_covariance(covariance, d)
    decomp_type in (:PCA, :Cholesky) ||
        throw(ArgumentError("decomp_type must be :PCA or :Cholesky, got :$decomp_type"))
    A = _compute_decomp(cov, decomp_type)
    # Capture the diagonal only when the *computed* factor A is genuinely diagonal
    # (e.g. Cholesky of a diagonal/scalar Σ). This keeps the exact same A — and thus
    # bit-identical samples — while letting `transform` skip the dense multiply.
    diagA = isdiag(A) ? diag(A) : nothing
    return Gaussian(dd, d, mu, cov, decomp_type, A, diagA)
end

function _expand_mean(val, d::Int)
    if val isa Real
        return fill(Float64(val), d)
    else
        length(val) == d || throw(
            ArgumentError("mean vector length ($(length(val))) must match dimension ($d)"),
        )
        return Float64.(collect(val))
    end
end

function _expand_covariance(val, d::Int)
    if val isa Real
        return Float64(val) * Matrix{Float64}(I, d, d)
    elseif val isa AbstractVector
        length(val) == d || throw(
            ArgumentError(
                "covariance diagonal length ($(length(val))) must match dimension ($d)",
            ),
        )
        return diagm(Float64.(collect(val)))
    elseif val isa AbstractMatrix
        size(val) == (d, d) ||
            throw(ArgumentError("covariance matrix size $(size(val)) must be ($d, $d)"))
        return Float64.(collect(val))
    else
        throw(ArgumentError("covariance must be a scalar, vector, or matrix"))
    end
end

"""
Compute the decomposition matrix A such that A * Aᵀ = Σ.

For `:PCA`: eigendecomposition with eigenvalues sorted descending.
  A = V * sqrt(Λ)  where Σ = V Λ Vᵀ.

For `:Cholesky`: lower Cholesky factor L where Σ = L Lᵀ.
"""
function _compute_decomp(cov::Matrix{Float64}, decomp_type::Symbol)
    if decomp_type == :PCA
        eig = eigen(Symmetric(cov))
        # Sort eigenvalues descending
        idx = sortperm(eig.values; rev=true)
        vals = eig.values[idx]
        vecs = eig.vectors[:, idx]
        # Clamp small negative eigenvalues to zero (numerical tolerance)
        vals = max.(vals, 0.0)
        A = vecs * Diagonal(sqrt.(vals))
        return Matrix{Float64}(A)
    else  # :Cholesky
        L = cholesky(Symmetric(cov)).L
        return Matrix{Float64}(L)
    end
end

function transform(tm::Gaussian, x::AbstractMatrix)
    # x is n×d with entries in [0,1); compute  y = Φ⁻¹(x) * Aᵀ .+ μᵀ.
    # Φ⁻¹(u) = √2·erfinv(2u-1) — avoids per-element Distributions.Normal() dispatch.
    # Deterministic QMC rules can include exact 0, so remap to the open interval
    # before applying the inverse normal CDF.
    dvec = tm._decomp_diag
    if dvec === nothing
        # General (dense) case: BLAS GEMM, O(n·d²).
        z = @. sqrt(2.0) * SpecialFunctions.erfinv(2.0 * _open_unit_interval(x) - 1.0)
        y = z * transpose(tm._decomp)
        y .+= transpose(tm.mean)                                    # in-place mean shift
        return y
    else
        # Diagonal-covariance fast path: A is diagonal, so y[:,j] = √2·erfinv(2x[:,j]-1)·A[j,j] + μ[j].
        # This is O(n·d) column scaling instead of the O(n·d²) dense multiply, and the whole
        # transform fuses into a single allocation.
        #
        # DEVIATION FROM QMCPy: QMCPy's Gaussian._transform always does the dense factor
        # multiply (`self.mu + np.einsum("...ij,kj->...ik", norm.ppf(x), self.a)`), with no
        # diagonal special case. Results here are numerically identical to that dense form
        # (column scaling equals multiplying by a diagonal A); only the cost differs.
        dvec_t = transpose(dvec)        # 1×d row (computed outside @. so it isn't dotted)
        mean_t = transpose(tm.mean)
        return @. sqrt(2.0) *
                  SpecialFunctions.erfinv(2.0 * _open_unit_interval(x) - 1.0) *
                  dvec_t + mean_t
    end
end

function Base.show(io::IO, tm::Gaussian)
    print(io, "Gaussian(d=$(tm.dimension), decomp=$(tm.decomp_type))")
end
