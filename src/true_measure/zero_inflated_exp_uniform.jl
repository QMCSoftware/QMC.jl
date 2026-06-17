"""
    ZeroInflatedExpUniform(dd; p_zero=0.3, rate=1.0, low=0.0, high=1.0)

Mixture distribution: point mass at 0 with probability `p_zero`, plus
a mixture of Exponential(rate) and Uniform(low, high) with equal remaining
probability.

Transforms 2D uniform samples: first dimension selects the component,
second dimension generates the value.

Requires `dd.dimension == 2`.

# Examples
```jldoctest
julia> using QMC

julia> tm = ZeroInflatedExpUniform(IIDStdUniform(2; seed=7); p_zero=0.3, rate=2.0)
ZeroInflatedExpUniform(p_zero=0.30, rate=2.00)

julia> round.(transform(tm, gen_samples(tm.dd, 6)); digits=6)
6×1 Matrix{Float64}:
 0.052388
 0.357784
 0.426401
 0.0
 2.125008
 0.283284
```
"""
struct ZeroInflatedExpUniform{D <: AbstractDiscreteDistribution} <: AbstractTrueMeasure
    dd::D
    p_zero::Float64
    rate::Float64
    low::Float64
    high::Float64
end

function ZeroInflatedExpUniform(
    dd::AbstractDiscreteDistribution;
    p_zero::Float64=0.3,
    rate::Float64=1.0,
    low::Float64=0.0,
    high::Float64=1.0,
)
    dd.dimension == 2 || throw(ArgumentError("ZeroInflatedExpUniform requires dimension=2"))
    0 <= p_zero <= 1 || throw(ArgumentError("p_zero must be in [0,1]"))
    rate > 0 || throw(ArgumentError("rate must be > 0"))
    low < high || throw(ArgumentError("low must be < high"))
    return ZeroInflatedExpUniform(dd, p_zero, rate, low, high)
end

function transform(tm::ZeroInflatedExpUniform, x::AbstractMatrix)
    n = size(x, 1)
    u_select = x[:, 1]  # component selector
    u_val = x[:, 2]     # value generator

    result = zeros(n, 1)
    p_exp = (1 - tm.p_zero) / 2
    p_unif = (1 - tm.p_zero) / 2

    for i in 1:n
        if u_select[i] < tm.p_zero
            result[i] = 0.0
        elseif u_select[i] < tm.p_zero + p_exp
            # Exponential via inverse CDF
            result[i] = -log(1 - u_val[i]) / tm.rate
        else
            # Uniform
            result[i] = tm.low + u_val[i] * (tm.high - tm.low)
        end
    end
    return result
end

function Base.show(io::IO, tm::ZeroInflatedExpUniform)
    @printf(io, "ZeroInflatedExpUniform(p_zero=%.2f, rate=%.2f)", tm.p_zero, tm.rate)
end
