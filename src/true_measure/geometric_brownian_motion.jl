"""
    GeometricBrownianMotion(dd; t_final=1.0, initial_value=1.0, drift=0.0, diffusion=1.0, decomp_type=:PCA)

Geometric Brownian Motion (GBM) measure:

    GBM(t) = S₀ exp[(γ - σ²/2) t + σ BM(t)]

where BM is a standard Brownian motion, γ is the drift, and σ² is the diffusion.

# Arguments
- `dd`: discrete distribution providing uniform samples in [0,1)^d.
- `t_final`: end time (default 1.0).
- `initial_value`: positive initial value S₀ (default 1.0).
- `drift`: drift coefficient γ (default 0.0).
- `diffusion`: positive diffusion coefficient σ² (default 1.0).
- `decomp_type`: `:PCA` or `:Cholesky` for the underlying BM covariance decomposition.

# Examples
```julia
dd = DigitalNetB2(4; seed=7)
gbm = GeometricBrownianMotion(dd; t_final=2.0, drift=0.1, diffusion=0.2)
x = gen_samples(dd, 256)
paths = transform(gbm, x)  # 256×4 stock price paths
```
"""
struct GeometricBrownianMotion <: AbstractTrueMeasure
    dd::AbstractDiscreteDistribution
    dimension::Int
    time_vector::Vector{Float64}
    initial_value::Float64
    drift::Float64
    diffusion::Float64
    _bm::BrownianMotion
end

function GeometricBrownianMotion(dd::AbstractDiscreteDistribution;
        t_final::Float64 = 1.0,
        initial_value::Float64 = 1.0,
        drift::Float64 = 0.0,
        diffusion::Float64 = 1.0,
        decomp_type::Symbol = :PCA)
    t_final >= 0.0 || throw(ArgumentError("t_final must be non-negative, got $t_final"))
    initial_value > 0.0 ||
        throw(ArgumentError("initial_value must be positive, got $initial_value"))
    diffusion > 0.0 || throw(ArgumentError("diffusion must be positive, got $diffusion"))

    d = dd.dimension
    tv = collect(range(t_final / d, t_final; length = d))

    # Build BM covariance: C[i,j] = diffusion * min(t[i], t[j])
    cov = Matrix{Float64}(undef, d, d)
    @inbounds for j in 1:d, i in 1:d

        cov[i, j] = diffusion * min(tv[i], tv[j])
    end

    gauss = Gaussian(dd; mean = 0.0, covariance = cov, decomp_type = decomp_type)
    bm = BrownianMotion(dd, d, tv, 0.0, gauss)

    return GeometricBrownianMotion(dd, d, tv, initial_value, drift, diffusion, bm)
end

function transform(tm::GeometricBrownianMotion, x::AbstractMatrix)
    # Get BM paths (these already have diffusion scaling via covariance)
    bm_samples = transform(tm._bm, x)
    # S(t) = S₀ exp[(γ - σ²/2) t + BM(t)]
    # where BM(t) already has variance σ² t from the covariance
    n, d = size(bm_samples)
    result = Matrix{Float64}(undef, n, d)
    @inbounds for j in 1:d
        exponent_drift = (tm.drift - 0.5 * tm.diffusion) * tm.time_vector[j]
        for i in 1:n
            result[i, j] = tm.initial_value * exp(exponent_drift + bm_samples[i, j])
        end
    end
    return result
end

function Base.show(io::IO, tm::GeometricBrownianMotion)
    print(io,
        "GeometricBrownianMotion(d=$(tm.dimension), S₀=$(tm.initial_value), γ=$(tm.drift), σ²=$(tm.diffusion))")
end
