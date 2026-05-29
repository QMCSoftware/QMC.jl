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

# Example
```julia
dd = Lattice(13; randomize=true)
tm = BrownianMotion(dd)
f = AsianOption(tm; volatility=0.5, start_price=30.0, strike_price=25.0)
```
"""
mutable struct AsianOption <: AbstractIntegrand
    true_measure::AbstractTrueMeasure
    dimension::Int
    volatility::Float64
    start_price::Float64
    strike_price::Float64
    interest_rate::Float64
    call_put::Symbol        # :call or :put
    mean_type::Symbol       # :arithmetic or :geometric
    _time_vector::Vector{Float64}
end

function AsianOption(tm::AbstractTrueMeasure;
    volatility::Float64 = 0.5,
    start_price::Float64 = 30.0,
    strike_price::Float64 = 25.0,
    interest_rate::Float64 = 0.0,
    call_put::Symbol = :call,
    mean_type::Symbol = :arithmetic)
    @assert call_put in (:call, :put) "call_put must be :call or :put"
    @assert mean_type in (:arithmetic, :geometric) "mean_type must be :arithmetic or :geometric"
    d = tm.dimension
    # Extract time vector from BrownianMotion if available
    tv = if hasproperty(tm, :time_vector)
        tm.time_vector
    else
        collect(range(1.0 / d, 1.0, length = d))
    end
    return AsianOption(tm, d, volatility, start_price, strike_price,
        interest_rate, call_put, mean_type, tv)
end

function evaluate(f::AsianOption, x::AbstractMatrix)
    n, d = size(x)
    σ = f.volatility
    S0 = f.start_price
    K = f.strike_price
    r = f.interest_rate
    T = f._time_vector[end]
    tv = f._time_vector
    y = Vector{Float64}(undef, n)

    for i in 1:n
        # Compute stock prices at each monitoring date
        # x[i,:] contains Brownian motion values W(t_1), ..., W(t_d)
        stock_prices = Vector{Float64}(undef, d)
        for j in 1:d
            stock_prices[j] = S0 * exp((r - 0.5 * σ^2) * tv[j] + σ * x[i, j])
        end

        # Compute average
        if f.mean_type == :arithmetic
            avg_price = mean(stock_prices)
        else  # :geometric
            avg_price = exp(mean(log.(stock_prices)))
        end

        # Compute payoff
        if f.call_put == :call
            payoff = max(avg_price - K, 0.0)
        else  # :put
            payoff = max(K - avg_price, 0.0)
        end

        # Discount
        y[i] = exp(-r * T) * payoff
    end

    return y
end

function Base.show(io::IO, f::AsianOption)
    print(io,
        "AsianOption($(f.call_put), $(f.mean_type), d=$(f.dimension), " *
        "S0=$(f.start_price), K=$(f.strike_price), σ=$(f.volatility))")
end
