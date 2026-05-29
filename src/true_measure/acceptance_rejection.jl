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
```julia
dd = DigitalNetB2(3; seed=7)  # 2 target dims + 1 acceptance dim
pdf_func(x) = 6.0 * x[1] * x[2]  # target: f(x,y) = 6xy on [0,1]^2
tm = AcceptanceRejection(dd; pdf_func=pdf_func, envelope_multiplier=6.0)
```

# References
1. Zhu, H. and Dick, J. "A discrepancy bound for deterministic acceptance-rejection
   samplers beyond N^{-1/2}." 2014.
"""
struct AcceptanceRejection <: AbstractTrueMeasure
    dd::AbstractDiscreteDistribution
    dimension::Int          # target dimension (d = dd.dimension - 1)
    pdf_func::Function
    proposal_pdf_func::Function
    proposal_sample_func::Function
    envelope_multiplier::Float64
end

function AcceptanceRejection(dd::AbstractDiscreteDistribution;
        pdf_func::Function,
        proposal_pdf_func::Union{Nothing, Function} = nothing,
        proposal_sample_func::Union{Nothing, Function} = nothing,
        envelope_multiplier::Union{Nothing, Float64} = nothing,
        proposal_pdf::Union{Nothing, Function} = nothing,
        proposal_sample::Union{Nothing, Function} = nothing,
        M::Union{Nothing, Float64} = nothing)
    if !isnothing(proposal_pdf_func) && !isnothing(proposal_pdf)
        throw(ArgumentError("proposal_pdf_func and proposal_pdf are aliases; provide only one"))
    end
    if !isnothing(proposal_sample_func) && !isnothing(proposal_sample)
        throw(ArgumentError("proposal_sample_func and proposal_sample are aliases; provide only one"))
    end
    if !isnothing(envelope_multiplier) && !isnothing(M) && envelope_multiplier != M
        throw(ArgumentError("envelope_multiplier and M must match when both are provided"))
    end

    d = dd.dimension - 1
    d > 0 || throw(ArgumentError("DD dimension must be ≥ 2 (d target dims + 1 acceptance dim)"))
    envelope_multiplier = Float64(something(envelope_multiplier, M, 1.0))
    envelope_multiplier > 0 || throw(ArgumentError("envelope_multiplier must be > 0"))

    ppf = isnothing(proposal_pdf_func) ? something(proposal_pdf, x -> 1.0) : proposal_pdf_func
    psf = isnothing(proposal_sample_func) ? something(proposal_sample, x -> x) : proposal_sample_func

    return AcceptanceRejection(dd, d, pdf_func, ppf, psf, envelope_multiplier)
end

"""
    transform(tm::AcceptanceRejection, x::AbstractMatrix) -> Matrix{Float64}

Apply the deterministic acceptance-rejection algorithm. Input `x` has shape
`(n, d+1)` where the last column is the acceptance threshold. Returns only
the accepted samples (may be fewer than n rows).
"""
function transform(tm::AcceptanceRejection, x::AbstractMatrix)
    n = size(x, 1)
    d = tm.dimension
    M = tm.envelope_multiplier

    accepted = Vector{Vector{Float64}}()
    sizehint!(accepted, div(n, 2))

    @inbounds for i in 1:n
        # Candidate point (first d coordinates)
        candidate = tm.proposal_sample_func(@view(x[i, 1:d]))
        # Acceptance threshold (last coordinate)
        u = x[i, d + 1]

        # Accept if u ≤ pdf(candidate) / (M * proposal_pdf(candidate))
        ratio = tm.pdf_func(candidate) / (M * tm.proposal_pdf_func(candidate))
        if u <= ratio
            push!(accepted, collect(candidate))
        end
    end

    if isempty(accepted)
        return Matrix{Float64}(undef, 0, d)
    end
    return reduce(vcat, [a' for a in accepted])
end

function Base.show(io::IO, tm::AcceptanceRejection)
    print(io, "AcceptanceRejection(d=$(tm.dimension), M=$(tm.envelope_multiplier))")
end
