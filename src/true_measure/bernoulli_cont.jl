"""
    BernoulliCont(dd; lam=0.5)

Continuous Bernoulli distribution measure via inverse CDF.

The continuous Bernoulli with parameter λ ∈ (0,1) has PDF:
    f(x) = C(λ) λˣ (1-λ)^(1-x)    for x ∈ [0,1]

where C(λ) is the normalizing constant. The inverse CDF is:
    F⁻¹(u) = log(1 + u(λ/(1-λ) - 1) / C(λ)) / log(λ/(1-λ))   for λ ≠ 0.5
    F⁻¹(u) = u                                                    for λ = 0.5

# Arguments
- `dd`: discrete distribution.
- `lam`: parameter λ ∈ (0,1), scalar or d-vector.
"""
struct BernoulliCont <: AbstractTrueMeasure
    dd::AbstractDiscreteDistribution
    dimension::Int
    lam::Vector{Float64}
end

function BernoulliCont(dd::AbstractDiscreteDistribution; lam = 0.5)
    d = dd.dimension
    lam_vec = lam isa Number ? fill(Float64(lam), d) : Float64.(collect(lam))
    all(0.0 .< lam_vec .< 1.0) || throw(ArgumentError("lam must be in (0,1)"))
    return BernoulliCont(dd, d, lam_vec)
end

function _cont_bern_ppf(u::Float64, lam::Float64)
    if abs(lam - 0.5) < 1e-12
        return u
    end
    # Normalizing constant: C(λ) = 2 * atanh(1 - 2λ) / (1 - 2λ)
    r = lam / (1.0 - lam)
    C = 2.0 * atanh(1.0 - 2.0 * lam) / (1.0 - 2.0 * lam)
    # CDF: F(x) = (λˣ(1-λ)^(1-x) - (1-λ)) / (λ - (1-λ)) * 1/C   ... simplified:
    # F⁻¹(u):
    return log(1.0 + (r - 1.0) * u / C) / log(r)
end

function transform(tm::BernoulliCont, x::AbstractMatrix)
    n, d = size(x)
    y = Matrix{Float64}(undef, n, d)
    @inbounds for j in 1:d
        for i in 1:n
            y[i, j] = _cont_bern_ppf(x[i, j], tm.lam[j])
        end
    end
    return y
end

function Base.show(io::IO, tm::BernoulliCont)
    print(io, "BernoulliCont(d=$(tm.dimension))")
end
