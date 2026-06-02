"""
    FinancialOption(tm::AbstractTrueMeasure;
                    volatility=0.5, start_price=30.0, strike_price=25.0,
                    interest_rate=0.0, call_put=:call,
                    option_type=:european, mean_type=:arithmetic,
                    barrier_price=NaN, barrier_in_out=:in)

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
- `:barrier` — European payoff conditional on path crossing (or not) a barrier

# Barrier options
For `:barrier`, set `barrier_price` and `barrier_in_out`:
- `:in` — knock-in: option activates only if the path reaches the barrier
- `:out` — knock-out: option is void if the path reaches the barrier
The up/down direction is determined automatically from `start_price` vs `barrier_price`.

# Examples
```julia
dd = Lattice(13; randomize=true)
tm = BrownianMotion(dd)
f = FinancialOption(tm; option_type=:european, volatility=0.2, strike_price=100.0, start_price=100.0)
```
"""
mutable struct FinancialOption{TM <: AbstractTrueMeasure} <: AbstractIntegrand
    true_measure::TM
    dimension::Int
    volatility::Float64
    start_price::Float64
    strike_price::Float64
    interest_rate::Float64
    call_put::Symbol
    option_type::Symbol
    mean_type::Symbol
    barrier_price::Float64
    barrier_in_out::Symbol
    _time_vector::Vector{Float64}
    _use_gbm_transform::Bool
end

function FinancialOption(tm::AbstractTrueMeasure;
    volatility::Union{Nothing, Float64} = nothing,
    start_price::Union{Nothing, Float64} = nothing,
    strike_price::Float64 = 25.0,
    interest_rate::Union{Nothing, Float64} = nothing,
    call_put::Symbol = :call,
    option_type::Symbol = :european,
    mean_type::Union{Nothing, Symbol} = nothing,
    asian_mean::Union{Nothing, Symbol} = nothing,
    barrier_price::Float64 = NaN,
    barrier_in_out::Symbol = :in)
    if !isnothing(mean_type) && !isnothing(asian_mean) && mean_type != asian_mean
        throw(ArgumentError("mean_type and asian_mean must match when both are provided"))
    end

    if tm isa GeometricBrownianMotion
        volatility = isnothing(volatility) ? sqrt(tm.diffusion) : volatility
        start_price = isnothing(start_price) ? tm.initial_value : start_price
        interest_rate = isnothing(interest_rate) ? tm.drift : interest_rate
    else
        volatility = isnothing(volatility) ? 0.5 : volatility
        start_price = isnothing(start_price) ? 30.0 : start_price
        interest_rate = isnothing(interest_rate) ? 0.0 : interest_rate
    end
    mean_type = something(mean_type, asian_mean, :arithmetic)

    call_put in (:call, :put) || throw(ArgumentError("call_put must be :call or :put"))
    option_type in (:european, :asian, :lookback, :digital, :barrier) ||
        throw(
            ArgumentError(
                "option_type must be :european, :asian, :lookback, :digital, or :barrier",
            ),
        )
    mean_type in (:arithmetic, :geometric) ||
        throw(ArgumentError("mean_type must be :arithmetic or :geometric"))
    if option_type == :barrier
        isnan(barrier_price) &&
            throw(ArgumentError("barrier_price must be set for barrier options"))
        barrier_in_out in (:in, :out) ||
            throw(ArgumentError("barrier_in_out must be :in or :out"))
    end

    d = tm.dimension
    tv = if hasproperty(tm, :time_vector)
        tm.time_vector
    else
        collect(range(1.0 / d, 1.0; length = d))
    end

    use_gbm = tm isa GeometricBrownianMotion

    return FinancialOption(tm, d, volatility, start_price, strike_price,
        interest_rate, call_put, option_type, mean_type,
        barrier_price, barrier_in_out,
        tv, use_gbm)
end

function _stock_prices(f::FinancialOption, x_row::AbstractVector)
    d = f.dimension
    if f._use_gbm_transform
        return x_row
    else
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
            raw = max(maximum(S) - K, 0.0)
        else
            raw = max(K - minimum(S), 0.0)
        end
    elseif opt == :digital
        ST = S[end]
        itm = f.call_put == :call ? (ST > K) : (ST < K)
        raw = itm ? 1.0 : 0.0
    elseif opt == :barrier
        raw = _barrier_payoff(f, S)
    else
        error("Unknown option_type: $(f.option_type)")
    end
    return raw
end

function _barrier_payoff(f::FinancialOption, S::AbstractVector)
    K = f.strike_price
    B = f.barrier_price
    ST = S[end]
    is_up = f.start_price < B

    # Check if barrier was crossed
    if is_up
        crossed = any(s -> s >= B, S)
    else
        crossed = any(s -> s <= B, S)
    end

    # Determine if option is active
    active = f.barrier_in_out == :in ? crossed : !crossed
    if !active
        return 0.0
    end

    # European payoff when active
    return f.call_put == :call ? max(ST - K, 0.0) : max(K - ST, 0.0)
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

# ──────────────────────────────────────────────────────────────────────────────
# Exact analytic pricing
# ──────────────────────────────────────────────────────────────────────────────

"""
    _bs_euro_price(S0, r, T, σ, K) -> (call_price, put_price)

Black-Scholes price for a European call and put.
"""
function _bs_euro_price(S0::Float64, r::Float64, T::Float64, σ::Float64, K::Float64)
    d = Distributions.Normal()
    priceratio = K * exp(-r * T) / S0
    xbig = log(priceratio) / (σ * sqrt(T)) + σ * sqrt(T) / 2
    xsmall = log(priceratio) / (σ * sqrt(T)) - σ * sqrt(T) / 2
    putprice = S0 * (priceratio * Distributions.cdf(d, xbig) - Distributions.cdf(d, xsmall))
    callprice = putprice + S0 * (1 - priceratio)
    return callprice, putprice
end

"""
    get_exact_value(f::FinancialOption) -> Float64

Compute the exact analytic fair price of the option. Supports:
- `:european` (Black-Scholes)
- `:asian` with `mean_type=:geometric` (Kemna-Vorst approximation)
"""
function get_exact_value(f::FinancialOption)
    S0 = f.start_price
    K = f.strike_price
    r = f.interest_rate
    σ = f.volatility
    T = f._time_vector[end]
    d = f.dimension

    if f.option_type == :european
        cp, pp = _bs_euro_price(S0, r, T, σ, K)
        return f.call_put == :call ? cp : pp

    elseif f.option_type == :asian && f.mean_type == :geometric
        # Kemna-Vorst (finite-dimensional geometric Asian)
        Tbar = (1 + 1 / d) * T / 2
        σbar = σ * sqrt((2 + 1 / d) / 3)
        rbar = r + (σbar^2 - σ^2) / 2
        gc, gp = _bs_euro_price(S0, rbar, Tbar, σbar, K)
        factor = exp(rbar * Tbar - r * T)
        return f.call_put == :call ? gc * factor : gp * factor
    else
        error(
            "Exact value not supported for option_type=:$(f.option_type)" *
            (f.option_type == :asian ? " with mean_type=:$(f.mean_type)" : ""),
        )
    end
end

function Base.show(io::IO, f::FinancialOption)
    extra = f.option_type == :barrier ?
            ", B=$(f.barrier_price), $(f.barrier_in_out)" : ""
    print(io,
        "FinancialOption(:$(f.option_type), :$(f.call_put), d=$(f.dimension), " *
        "S₀=$(f.start_price), K=$(f.strike_price), σ=$(f.volatility)$extra)")
end
