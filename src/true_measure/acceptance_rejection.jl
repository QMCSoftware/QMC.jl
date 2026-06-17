"""
    AcceptanceRejection(dd::AbstractDiscreteDistribution;
                        pdf_func, proposal_pdf_func=nothing,
                        proposal_sample_func=nothing,
                        envelope_multiplier=1.0)

Deterministic Acceptance-Rejection (DAR) sampler on the unit cube.

Implements Algorithm 2 from Zhu & Dick (2014). An (s+1)-dimensional
low-discrepancy sequence is used: the first s coordinates form the candidate
point and the last coordinate is the acceptance threshold. This produces
accepted samples with star discrepancy O(N^{-1/(s+1)}) instead of O(N^{-1/2})
from random acceptance-rejection.

The integrand's true measure dimension `d` corresponds to the s-dimensional
target distribution. The discrete distribution must have dimension `d + 1`.

# Arguments
- `dd`: Discrete distribution with dimension d + 1.
- `pdf_func`: Target PDF function `f(x) -> Float64` where `x` is a d-vector.
- `proposal_pdf_func`: Proposal PDF. Default: uniform on [0,1]^d (constant 1).
- `proposal_sample_func`: Maps [0,1]^d to proposal samples. Default: identity.
- `envelope_multiplier`: M such that `pdf_func(x) ≤ M * proposal_pdf_func(x)`.

# Example
```jldoctest
julia> using QMC

julia> dd = DigitalNetB2(3; randomize="none", seed=7);  # 2 target dims + 1 acceptance dim

julia> pdf_func(x) = 6.0 * x[1] * x[2];  # target: f(x,y) = 6xy on [0,1]^2

julia> tm = AcceptanceRejection(dd; pdf_func=pdf_func, envelope_multiplier=6.0)
AcceptanceRejection(d=2, M=6.0)

julia> z = transform(tm, gen_samples(dd, 16));

julia> size(z)
(5, 2)

julia> z
5×2 Matrix{Float64}:
 0.0     0.0
 0.875   0.875
 0.6875  0.8125
 0.4375  0.5625
 0.5625  0.4375
```

# References
1. Zhu, H. and Dick, J. "A discrepancy bound for deterministic acceptance-rejection
   samplers beyond N^{-1/2}." 2014.
"""
struct AcceptanceRejection{D <: AbstractDiscreteDistribution, F1, F2, F3} <: AbstractTrueMeasure
    dd::D
    dimension::Int          # target dimension (d = dd.dimension - 1)
    pdf_func::F1
    proposal_pdf_func::F2
    proposal_sample_func::F3
    envelope_multiplier::Float64
end

function AcceptanceRejection(
    dd::AbstractDiscreteDistribution;
    pdf_func::Function,
    proposal_pdf_func::Union{Nothing, Function}=nothing,
    proposal_sample_func::Union{Nothing, Function}=nothing,
    envelope_multiplier::Union{Nothing, Float64}=nothing,
    proposal_pdf::Union{Nothing, Function}=nothing,
    proposal_sample::Union{Nothing, Function}=nothing,
    M::Union{Nothing, Float64}=nothing,
)
    if !isnothing(proposal_pdf_func) && !isnothing(proposal_pdf)
        throw(ArgumentError("proposal_pdf_func and proposal_pdf are aliases; provide only one"))
    end
    if !isnothing(proposal_sample_func) && !isnothing(proposal_sample)
        throw(
            ArgumentError(
                "proposal_sample_func and proposal_sample are aliases; provide only one",
            ),
        )
    end
    if !isnothing(envelope_multiplier) && !isnothing(M) && envelope_multiplier != M
        throw(ArgumentError("envelope_multiplier and M must match when both are provided"))
    end

    d = dd.dimension - 1
    d > 0 || throw(ArgumentError("DD dimension must be ≥ 2 (d target dims + 1 acceptance dim)"))
    envelope_multiplier = Float64(something(envelope_multiplier, M, 1.0))
    envelope_multiplier > 0 || throw(ArgumentError("envelope_multiplier must be > 0"))

    ppf = isnothing(proposal_pdf_func) ? something(proposal_pdf, x -> 1.0) : proposal_pdf_func
    psf =
        isnothing(proposal_sample_func) ? something(proposal_sample, x -> x) :
        proposal_sample_func

    return AcceptanceRejection(dd, d, pdf_func, ppf, psf, envelope_multiplier)
end

"""
    transform(tm::AcceptanceRejection, x::AbstractMatrix) -> Matrix{Float64}

Apply the deterministic acceptance-rejection algorithm. Input `x` has shape
`(n, d+1)` where the last column is the acceptance threshold. Returns only
the accepted samples (may be fewer than n rows).

For replicated input `x::AbstractArray{<:Real,3}`, returns a length-`R` vector
of accepted-sample matrices, one per replication.
"""
function transform(tm::AcceptanceRejection, x::AbstractMatrix)
    n = size(x, 1)
    d = tm.dimension
    M = tm.envelope_multiplier

    # Accumulate accepted candidates row-major into one flat buffer instead of a
    # Vector{Vector{Float64}} + reduce(vcat, [a' …]): that avoided a per-row
    # `collect`, an array of adjoints, and a quadratic-ish vcat. The candidate
    # computation and acceptance test are unchanged.
    flat = Float64[]
    sizehint!(flat, (d * n) ÷ 2)
    m = 0
    @inbounds for i in 1:n
        # Candidate point (first d coordinates)
        candidate = tm.proposal_sample_func(@view(x[i, 1:d]))
        # Acceptance threshold (last coordinate)
        u = x[i, d + 1]

        # Accept if u ≤ pdf(candidate) / (M * proposal_pdf(candidate))
        ratio = tm.pdf_func(candidate) / (M * tm.proposal_pdf_func(candidate))
        if u <= ratio
            for k in 1:d
                push!(flat, candidate[k])
            end
            m += 1
        end
    end

    m == 0 && return Matrix{Float64}(undef, 0, d)
    # `flat` holds m rows of length d in row-major order; reshape to d×m (each
    # column is an accepted row) and transpose to the (m, d) result.
    return permutedims(reshape(flat, d, m))
end

function transform(tm::AcceptanceRejection, x::AbstractArray{T, 3}) where {T <: Real}
    R = size(x, 1)
    out = Vector{Matrix{Float64}}(undef, R)
    @inbounds for r in 1:R
        out[r] = transform(tm, @view x[r, :, :])
    end
    return out
end

function Base.show(io::IO, tm::AcceptanceRejection)
    print(io, "AcceptanceRejection(d=$(tm.dimension), M=$(tm.envelope_multiplier))")
end

"""
    AcceptanceRejectionReal(dd::AbstractDiscreteDistribution;
                            target_density, inv_cdfs, H_func,
                            upper_bound, density_integral, max_retries=4)

Deterministic Acceptance-Rejection (DAR) sampler on real space ℝ^d.

Implements Algorithm 3 from Zhu & Dick (2014), extending the unit-cube
[`AcceptanceRejection`](@ref) to densities on ℝ^d. The first `d` coordinates of
each `(d+1)`-dimensional driver point are mapped through per-dimension quantile
functions (an inverse Rosenblatt transform), and the last coordinate is the
acceptance threshold:

    zⱼ = Fⱼ⁻¹(uⱼ)   for j = 1, …, d        u = u_{d+1}

A candidate `z` is accepted when `ψ(z) ≥ L · H(z) · u`, where `ψ = target_density`
is the (unnormalised) target, `H = H_func` is an auxiliary bound density with
`ψ(z) ≤ L · H(z)` everywhere, and `L = upper_bound`. The acceptance rate is
`density_integral / upper_bound`.

The integrand's true-measure dimension `d` equals `dd.dimension - 1`; the discrete
distribution must therefore have dimension `d + 1` and mimic StdUniform.

# Arguments
- `dd`: discrete distribution of dimension `d + 1`.
- `target_density`: `ψ(z) -> Float64` for a `d`-vector `z` (unnormalised target).
- `inv_cdfs`: vector of `d` quantile functions `Fⱼ⁻¹: [0,1] -> ℝ`, one per dim.
- `H_func`: `H(z) -> Float64`, the auxiliary bound density.
- `upper_bound`: `L` with `ψ(z) ≤ L · H(z)` for all `z`.
- `density_integral`: `C = ∫_{ℝ^d} ψ(z) dz`; the acceptance rate is `C / L`.
- `max_retries`: retained for parity; the cube-style `transform` filters a single
  supplied driver batch.

# Example
```jldoctest
julia> using QMC

julia> dd = DigitalNetB2(2; randomize="none", seed=7);  # 1 target dim + 1 acceptance dim

julia> logit(u) = log(u / (1 - u));

julia> lpdf(z) = exp(-z) / (1 + exp(-z))^2;  # logistic density (proposal H)

julia> tm = AcceptanceRejectionReal(dd;
           target_density = z -> 0.5 * lpdf(z[1]),
           inv_cdfs = [logit],
           H_func = z -> lpdf(z[1]),
           upper_bound = 1.0,
           density_integral = 0.5)
AcceptanceRejectionReal(d=1, L=1.0, acceptance_rate=0.5)

julia> z = transform(tm, gen_samples(dd, 16));

julia> size(z)
(9, 1)

julia> round.(z; digits=6)
9×1 Matrix{Float64}:
 -18.420681
   0.0
   1.098612
  -0.510826
   0.510826
  -1.466337
   2.70805
  -0.788457
   0.251314
```

# References
1. Zhu, H. and Dick, J. "A discrepancy bound for deterministic acceptance-rejection
   samplers beyond N^{-1/2}." 2014.
"""
struct AcceptanceRejectionReal{D <: AbstractDiscreteDistribution, F1, F2, V} <:
       AbstractTrueMeasure
    dd::D
    dimension::Int
    target_density::F1
    inv_cdfs::V
    H_func::F2
    upper_bound::Float64
    density_integral::Float64
    acceptance_rate::Float64
    max_retries::Int
end

function AcceptanceRejectionReal(
    dd::AbstractDiscreteDistribution;
    target_density::Function,
    inv_cdfs::AbstractVector,
    H_func::Function,
    upper_bound::Float64,
    density_integral::Float64,
    max_retries::Int=4,
)
    d = dd.dimension - 1
    d > 0 || throw(ArgumentError("DD dimension must be ≥ 2 (d target dims + 1 acceptance dim)"))
    length(inv_cdfs) == d || throw(
        ArgumentError(
            "inv_cdfs must have one entry per target dimension " *
            "(got $(length(inv_cdfs)), expected $d)",
        ),
    )
    upper_bound > 0 || throw(ArgumentError("upper_bound must be > 0"))
    density_integral > 0 || throw(ArgumentError("density_integral must be > 0"))
    acceptance_rate = density_integral / upper_bound
    cdfs = collect(inv_cdfs)
    return AcceptanceRejectionReal(
        dd,
        d,
        target_density,
        cdfs,
        H_func,
        upper_bound,
        density_integral,
        acceptance_rate,
        max_retries,
    )
end

"""
    transform(tm::AcceptanceRejectionReal, x::AbstractMatrix) -> Matrix{Float64}

Map a driver matrix `x` of shape `(n, d+1)` to accepted real-valued samples. The
first `d` columns are pushed through `inv_cdfs` (clamped to `[1e-8, 1-1e-8]` to
keep quantiles finite) and the last column is the acceptance threshold. Returns
only the accepted rows (an `(m, d)` matrix with `m ≤ n`).

For replicated input `x::AbstractArray{<:Real,3}`, returns a length-`R` vector
of accepted-sample matrices, one per replication.
"""
function transform(tm::AcceptanceRejectionReal, x::AbstractMatrix)
    n = size(x, 1)
    d = tm.dimension
    L = tm.upper_bound
    epsq = 1e-8

    # Julia matrices are column-major, so map each proposal coordinate in
    # column-major order first, then perform the row-wise acceptance test.
    zmat = Matrix{Float64}(undef, n, d)
    @inbounds for j in 1:d
        invcdf = tm.inv_cdfs[j]
        @simd for i in 1:n
            uj = clamp(x[i, j], epsq, 1.0 - epsq)
            zmat[i, j] = invcdf(uj)
        end
    end

    # Acceptance test reuses the already-materialised `zmat`: record the indices
    # of accepted rows, then gather them in one shot (`zmat[keep, :]`). This drops
    # the per-row `copy(z)`, the Vector{Vector{Float64}}, and the reduce(vcat).
    keep = Int[]
    sizehint!(keep, ceil(Int, n * tm.acceptance_rate))
    @inbounds for i in 1:n
        z = @view zmat[i, :]
        u = x[i, d + 1]
        if tm.target_density(z) >= L * tm.H_func(z) * u
            push!(keep, i)
        end
    end

    isempty(keep) && return Matrix{Float64}(undef, 0, d)
    return zmat[keep, :]
end

function transform(tm::AcceptanceRejectionReal, x::AbstractArray{T, 3}) where {T <: Real}
    R = size(x, 1)
    out = Vector{Matrix{Float64}}(undef, R)
    @inbounds for r in 1:R
        out[r] = transform(tm, @view x[r, :, :])
    end
    return out
end

function Base.show(io::IO, tm::AcceptanceRejectionReal)
    print(
        io,
        "AcceptanceRejectionReal(d=$(tm.dimension), L=$(tm.upper_bound), ",
        "acceptance_rate=$(round(tm.acceptance_rate, digits = 4)))",
    )
end
