"""
    AsianOption(tm::AbstractTrueMeasure;
                volatility=0.5, start_price=30.0, strike_price=25.0,
                interest_rate=0.0, call_put=:call, mean_type=:arithmetic)

Asian option pricing under geometric Brownian motion.
The true measure `tm` should be a `BrownianMotion` measure. The dimension
determines the number of monitoring dates.

Given Brownian motion paths ``W(t_j)``, stock price at each monitoring date is:
``S(t_j) = S_0 \\exp\\bigl((r - \\sigma^2/2) t_j + \\sigma W(t_j)\\bigr)``

Payoff (discounted):
- `:arithmetic` call: ``e^{-rT} \\max(\\bar{S}_{\\mathrm{arith}} - K, 0)``
- `:geometric` call:  ``e^{-rT} \\max(\\bar{S}_{\\mathrm{geom}} - K, 0)``

# Examples
```jldoctest
julia> using QMC, Statistics

julia> f = AsianOption(BrownianMotion(Lattice(13; randomize=true, seed=7)); volatility=0.5, start_price=30.0, strike_price=25.0)
AsianOption(call, arithmetic, d=13, S0=30.0, K=25.0, σ=0.5)

julia> y = sample_and_evaluate(f, 2^10);

julia> round(mean(y); digits=4)
6.3321
```

```jldoctest
julia> using QMC

julia> f = AsianOption(BrownianMotion(DigitalNetB2(8; seed=7)); mean_type=:geometric, volatility=0.5, start_price=30.0, strike_price=25.0)
AsianOption(call, geometric, d=8, S0=30.0, K=25.0, σ=0.5)

julia> round(get_exact_value(f); digits=4)
6.0394
```
"""
mutable struct AsianOption{TM <: AbstractTrueMeasure} <: AbstractIntegrand
    true_measure::TM
    dimension::Int
    volatility::Float64
    start_price::Float64
    strike_price::Float64
    interest_rate::Float64
    call_put::Symbol        # :call or :put
    mean_type::Symbol       # :arithmetic or :geometric
    _time_vector::Vector{Float64}
end

function AsianOption(
    tm::AbstractTrueMeasure;
    volatility::Float64=0.5,
    start_price::Float64=30.0,
    strike_price::Float64=25.0,
    interest_rate::Float64=0.0,
    call_put::Symbol=:call,
    mean_type::Symbol=:arithmetic,
)
    @assert call_put in (:call, :put) "call_put must be :call or :put"
    @assert mean_type in (:arithmetic, :geometric) "mean_type must be :arithmetic or :geometric"
    d = tm.dimension
    # Extract time vector from BrownianMotion if available
    tv = if hasproperty(tm, :time_vector)
        tm.time_vector
    else
        collect(range(1.0 / d, 1.0, length=d))
    end
    return AsianOption(
        tm,
        d,
        volatility,
        start_price,
        strike_price,
        interest_rate,
        call_put,
        mean_type,
        tv,
    )
end

function evaluate(f::AsianOption, x::AbstractMatrix)
    n, d = size(x)
    σ = f.volatility
    S0 = f.start_price
    K = f.strike_price
    r = f.interest_rate
    T = f._time_vector[end]
    tv = f._time_vector
    drift = r - 0.5 * σ^2
    avg = zeros(Float64, n)
    # Julia matrices are column-major, so the natural `i`-outer / `j`-inner
    # stock-price loop would stride by `n` across `x[i, j]`. Accumulating the
    # average with `j` outer / `i` inner reads each Brownian-motion column
    # contiguously while preserving the per-row monitoring-date order.
    if f.mean_type == :arithmetic
        @inbounds for j in 1:d
            tj = tv[j]
            @simd for i in 1:n
                avg[i] += S0 * exp(drift * tj + σ * x[i, j])
            end
        end
        @. avg = avg / d
    else  # geometric
        logS0 = log(S0)
        @inbounds for j in 1:d
            tj = tv[j]
            @simd for i in 1:n
                avg[i] += logS0 + drift * tj + σ * x[i, j]
            end
        end
        @. avg = exp(avg / d)
    end

    discount = exp(-r * T)
    y = Vector{Float64}(undef, n)
    @inbounds for i in 1:n
        payoff = if f.call_put == :call
            max(avg[i] - K, 0.0)
        else
            max(K - avg[i], 0.0)
        end
        y[i] = discount * payoff
    end

    return y
end

function Base.show(io::IO, f::AsianOption)
    print(
        io,
        "AsianOption($(f.call_put), $(f.mean_type), d=$(f.dimension), " *
        "S0=$(f.start_price), K=$(f.strike_price), σ=$(f.volatility))",
    )
end

"""
    get_exact_value(f::AsianOption) -> Float64

Exact fair price of a geometric-mean Asian option via the Kemna-Vorst formula
(`mean_type=:geometric` only). Uses the same discrete-monitoring convention as
[`FinancialOption`](@ref): `d` equally spaced dates with terminal time
`T = _time_vector[end]`. Throws for `mean_type=:arithmetic`, which has no
closed form.
"""
function get_exact_value(f::AsianOption)
    f.mean_type == :geometric || error(
        "Exact value only supported for AsianOption with mean_type=:geometric " *
        "(got mean_type=:$(f.mean_type))",
    )
    S0 = f.start_price
    K = f.strike_price
    r = f.interest_rate
    σ = f.volatility
    T = f._time_vector[end]
    d = f.dimension
    # Kemna-Vorst (finite-dimensional geometric Asian)
    Tbar = (1 + 1 / d) * T / 2
    σbar = σ * sqrt((2 + 1 / d) / 3)
    rbar = r + (σbar^2 - σ^2) / 2
    gc, gp = _bs_euro_price(S0, rbar, Tbar, σbar, K)
    factor = exp(rbar * Tbar - r * T)
    return f.call_put == :call ? gc * factor : gp * factor
end
