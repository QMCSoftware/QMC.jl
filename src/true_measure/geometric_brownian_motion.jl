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
```jldoctest
julia> using QMC

julia> gbm = GeometricBrownianMotion(DigitalNetB2(4; seed=7); t_final=2.0, drift=0.1, diffusion=0.2)
GeometricBrownianMotion(d=4, S₀=1.0, γ=0.1, σ²=0.2)

julia> round.(transform(gbm, gen_samples(gbm.dd, 2)); digits=6)
2×4 Matrix{Float64}:
 0.597736  0.733922  0.527114  0.400228
 0.841201  0.789829  1.14064   1.51273
```
"""
struct GeometricBrownianMotion{D <: AbstractDiscreteDistribution, B <: BrownianMotion} <:
       AbstractTrueMeasure
    dd::D
    dimension::Int
    time_vector::Vector{Float64}
    initial_value::Float64
    drift::Float64
    diffusion::Float64
    _bm::B
end

function GeometricBrownianMotion(
    dd::AbstractDiscreteDistribution;
    t_final::Float64=1.0,
    initial_value::Union{Nothing, Float64}=nothing,
    drift::Union{Nothing, Float64}=nothing,
    diffusion::Union{Nothing, Float64}=nothing,
    volatility::Union{Nothing, Float64}=nothing,
    start_price::Union{Nothing, Float64}=nothing,
    interest_rate::Union{Nothing, Float64}=nothing,
    decomp_type::Symbol=:PCA,
)
    if !isnothing(initial_value) && !isnothing(start_price) && initial_value != start_price
        throw(ArgumentError("initial_value and start_price must match when both are provided"))
    end
    if !isnothing(drift) && !isnothing(interest_rate) && drift != interest_rate
        throw(ArgumentError("drift and interest_rate must match when both are provided"))
    end
    if !isnothing(volatility) && volatility < 0.0
        throw(ArgumentError("volatility must be non-negative, got $volatility"))
    end
    if !isnothing(diffusion) && !isnothing(volatility) && diffusion != volatility^2
        throw(ArgumentError("diffusion and volatility must satisfy diffusion = volatility^2"))
    end

    initial_value = Float64(something(initial_value, start_price, 1.0))
    drift = Float64(something(drift, interest_rate, 0.0))
    diffusion =
        Float64(isnothing(diffusion) ? (isnothing(volatility) ? 1.0 : volatility^2) : diffusion)

    t_final >= 0.0 || throw(ArgumentError("t_final must be non-negative, got $t_final"))
    initial_value > 0.0 ||
        throw(ArgumentError("initial_value must be positive, got $initial_value"))
    diffusion > 0.0 || throw(ArgumentError("diffusion must be positive, got $diffusion"))

    d = dimension(dd)
    tv = collect(range(t_final / d, t_final; length=d))

    # Build BM covariance: C[i,j] = diffusion * min(t[i], t[j])
    cov = Matrix{Float64}(undef, d, d)
    @inbounds for j in 1:d, i in 1:d
        cov[i, j] = diffusion * min(tv[i], tv[j])
    end

    gauss = Gaussian(dd; mean=0.0, covariance=cov, decomp_type=decomp_type)
    bm = BrownianMotion(dd, d, tv, 0.0, 0.0, diffusion, gauss)

    return GeometricBrownianMotion(dd, d, tv, initial_value, drift, diffusion, bm)
end

function transform(tm::GeometricBrownianMotion, x::AbstractMatrix)
    # Get BM paths (these already have diffusion scaling via covariance)
    bm_samples = transform(tm._bm, x)
    # S(t) = S₀ exp[(γ - σ²/2) t + BM(t)]
    # where BM(t) already has variance σ² t from the covariance
    # offsets is 1×d; broadcast fuses + and exp into one 
    # Single Instruction, Multiple Data (SIMD) pass over the n×d array.
    offsets = transpose((tm.drift - 0.5 * tm.diffusion) .* tm.time_vector)
    return @. tm.initial_value * exp(offsets + bm_samples)
end

function Base.show(io::IO, tm::GeometricBrownianMotion)
    print(
        io,
        "GeometricBrownianMotion(d=$(tm.dimension), S₀=$(tm.initial_value), γ=$(tm.drift), σ²=$(tm.diffusion))",
    )
end
