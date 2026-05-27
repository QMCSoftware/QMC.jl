"""
    FinancialOption(tm::AbstractTrueMeasure;
                    volatility=0.5, start_price=30.0, strike_price=25.0,
                    interest_rate=0.0, call_put=:call,
                    option_type=:european, mean_type=:arithmetic)

Financial option pricing via QMC integration under geometric Brownian motion.

The true measure `tm` should be a `BrownianMotion` or `GeometricBrownianMotion`.
When `tm` is a `BrownianMotion`, the GBM stock price is constructed internally:
    S(tⱼ) = S₀ exp[(r - σ²/2) tⱼ + σ W(tⱼ)]

When `tm` is a `GeometricBrownianMotion`, the stock prices come directly
from the transform (and `volatility`, `start_price`, etc. should match
the GBM parameters).

# Supported option types
- `:european` — payoff based on terminal stock price S(T)
- `:asian` — payoff based on average stock price (arithmetic or geometric)
- `:lookback` — payoff based on max (call) or min (put) stock price
- `:digital` — binary payoff: pays 1 if in-the-money, 0 otherwise

# Examples
```julia
dd = Lattice(13; randomize=true)
tm = BrownianMotion(dd)
f = FinancialOption(tm; option_type=:european, volatility=0.2, strike_price=100.0, start_price=100.0)
```
"""
mutable struct FinancialOption <: AbstractIntegrand
    true_measure::AbstractTrueMeasure
    dimension::Int
    volatility::Float64
    start_price::Float64
    strike_price::Float64
    interest_rate::Float64
    call_put::Symbol
    option_type::Symbol
    mean_type::Symbol
    _time_vector::Vector{Float64}
    _use_gbm_transform::Bool  # true if tm is GeometricBrownianMotion
end

function FinancialOption(tm::AbstractTrueMeasure;
        volatility::Float64 = 0.5,
        start_price::Float64 = 30.0,
        strike_price::Float64 = 25.0,
        interest_rate::Float64 = 0.0,
        call_put::Symbol = :call,
        option_type::Symbol = :european,
        mean_type::Symbol = :arithmetic)
    call_put in (:call, :put) || throw(ArgumentError("call_put must be :call or :put"))
    option_type in (:european, :asian, :lookback, :digital) ||
        throw(ArgumentError("option_type must be :european, :asian, :lookback, or :digital"))
    mean_type in (:arithmetic, :geometric) ||
        throw(ArgumentError("mean_type must be :arithmetic or :geometric"))

    d = tm.dimension
    tv = if hasproperty(tm, :time_vector)
        tm.time_vector
    else
        collect(range(1.0 / d, 1.0; length = d))
    end

    use_gbm = tm isa GeometricBrownianMotion

    return FinancialOption(tm, d, volatility, start_price, strike_price,
        interest_rate, call_put, option_type, mean_type,
        tv, use_gbm)
end

function _stock_prices(f::FinancialOption, x_row::AbstractVector)
    d = f.dimension
    if f._use_gbm_transform
        # x_row already contains stock prices from GBM transform
        return x_row
    else
        # x_row contains BM paths; build GBM internally
        σ = f.volatility
        S0 = f.start_price
        r = f.interest_rate
        tv = f._time_vector
        S = Vector{Float64}(undef, d)
        @inbounds for j in 1:d
            S[j] = S0 * exp((r - 0.5 * σ^2) * tv[j] + σ * x_row[j])
        end
        return S
    end
end

function _payoff(f::FinancialOption, S::AbstractVector)
    K = f.strike_price
    opt = f.option_type

    if opt == :european
        ST = S[end]
        raw = f.call_put == :call ? max(ST - K, 0.0) : max(K - ST, 0.0)
    elseif opt == :asian
        if f.mean_type == :arithmetic
            avg = sum(S) / length(S)
        else
            avg = exp(sum(log.(S)) / length(S))
        end
        raw = f.call_put == :call ? max(avg - K, 0.0) : max(K - avg, 0.0)
    elseif opt == :lookback
        if f.call_put == :call
            raw = maximum(S) - K
            raw = max(raw, 0.0)
        else
            raw = K - minimum(S)
            raw = max(raw, 0.0)
        end
    elseif opt == :digital
        ST = S[end]
        itm = f.call_put == :call ? (ST > K) : (ST < K)
        raw = itm ? 1.0 : 0.0
    else
        error("Unknown option_type: $(f.option_type)")
    end
    return raw
end

function evaluate(f::FinancialOption, x::AbstractMatrix)
    n = size(x, 1)
    r = f.interest_rate
    T = f._time_vector[end]
    discount = exp(-r * T)
    y = Vector{Float64}(undef, n)

    @inbounds for i in 1:n
        S = _stock_prices(f, @view(x[i, :]))
        y[i] = discount * _payoff(f, S)
    end
    return y
end

function Base.show(io::IO, f::FinancialOption)
    print(io,
        "FinancialOption(:$(f.option_type), :$(f.call_put), d=$(f.dimension), " *
        "S₀=$(f.start_price), K=$(f.strike_price), σ=$(f.volatility))")
end
