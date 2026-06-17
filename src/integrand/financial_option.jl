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
```jldoctest
julia> using QMC, Statistics

julia> f = FinancialOption(
           GeometricBrownianMotion(DigitalNetB2(3; seed=7); t_final=1.0, drift=0.0, diffusion=0.25, initial_value=30.0);
           option_type=:european,
           strike_price=35.0,
           call_put=:call,
       )
FinancialOption(:european, :call, d=3, S₀=30.0, K=35.0, σ=0.5)

julia> y = sample_and_evaluate(f, 2^10);

julia> round(mean(y); digits=4)
4.2482

julia> round(get_exact_value(f); digits=4)
4.2115
```

```jldoctest
julia> using QMC, Statistics

julia> f = FinancialOption(
           GeometricBrownianMotion(DigitalNetB2(64; seed=7); t_final=1.0, drift=0.0, diffusion=0.25, initial_value=30.0);
           option_type=:asian,
           strike_price=35.0,
           call_put=:call,
       )
FinancialOption(:asian, :call, d=64, S₀=30.0, K=35.0, σ=0.5)

julia> y = sample_and_evaluate(f, 2^10);

julia> round(mean(y); digits=4)
1.8146
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

function FinancialOption(
    tm::AbstractTrueMeasure;
    volatility::Union{Nothing, Float64}=nothing,
    start_price::Union{Nothing, Float64}=nothing,
    strike_price::Float64=25.0,
    interest_rate::Union{Nothing, Float64}=nothing,
    call_put::Symbol=:call,
    option_type::Symbol=:european,
    mean_type::Union{Nothing, Symbol}=nothing,
    asian_mean::Union{Nothing, Symbol}=nothing,
    barrier_price::Float64=NaN,
    barrier_in_out::Symbol=:in,
)
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
    option_type in (:european, :asian, :lookback, :digital, :barrier) || throw(
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
        collect(range(1.0 / d, 1.0; length=d))
    end

    use_gbm = tm isa GeometricBrownianMotion

    return FinancialOption(
        tm,
        d,
        volatility,
        start_price,
        strike_price,
        interest_rate,
        call_put,
        option_type,
        mean_type,
        barrier_price,
        barrier_in_out,
        tv,
        use_gbm,
    )
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
    r = f.interest_rate
    T = f._time_vector[end]
    discount = exp(-r * T)

    # Fast path: European option with GBM transform already applied.
    # Only the terminal price S(T) = x[:, end] is needed; skip the row loop
    # and the per-row _stock_prices / _payoff calls entirely.
    if f.option_type == :european && f._use_gbm_transform
        S_T = @view x[:, end]
        K = f.strike_price
        return if f.call_put == :call
            @. discount * max(S_T - K, 0.0)
        else
            @. discount * max(K - S_T, 0.0)
        end
    end

    # Fast path: Asian option with GBM transform already applied. The transform
    # gives the full price path in x, so the payoff is the mean across the d
    # monitoring dates. Doing it as a column reduction (j outer, i inner) reads x
    # contiguously and skips the per-row _stock_prices/_payoff calls and the
    # per-row log allocation; per-row accumulation order (j = 1:d) is unchanged,
    # so results match the generic path.
    if f.option_type == :asian && f._use_gbm_transform
        n, d = size(x)
        K = f.strike_price
        avg = zeros(Float64, n)
        if f.mean_type == :arithmetic
            @inbounds for j in 1:d
                @simd for i in 1:n
                    avg[i] += x[i, j]
                end
            end
            @. avg = avg / d
        else  # geometric: exp(mean(log S))
            @inbounds for j in 1:d
                @simd for i in 1:n
                    avg[i] += log(x[i, j])
                end
            end
            @. avg = exp(avg / d)
        end
        return if f.call_put == :call
            @. discount * max(avg - K, 0.0)
        else
            @. discount * max(K - avg, 0.0)
        end
    end

    # Fast path: digital option with GBM transform already applied.
    # Only the terminal price S(T) = x[:, end] matters.
    if f.option_type == :digital && f._use_gbm_transform
        S_T = @view x[:, end]
        K = f.strike_price
        return if f.call_put == :call
            @. discount * ifelse(S_T > K, 1.0, 0.0)
        else
            @. discount * ifelse(S_T < K, 1.0, 0.0)
        end
    end

    # Fast path: lookback option with GBM transform already applied.
    # Reduce the path extrema in column-major order instead of rebuilding each
    # row's stock-price vector.
    if f.option_type == :lookback && f._use_gbm_transform
        n, d = size(x)
        extrema = copy(@view x[:, 1])
        if f.call_put == :call
            @inbounds for j in 2:d
                @simd for i in 1:n
                    extrema[i] = max(extrema[i], x[i, j])
                end
            end
            K = f.strike_price
            return @. discount * max(extrema - K, 0.0)
        else
            @inbounds for j in 2:d
                @simd for i in 1:n
                    extrema[i] = min(extrema[i], x[i, j])
                end
            end
            K = f.strike_price
            return @. discount * max(K - extrema, 0.0)
        end
    end

    # Fast path: barrier option with GBM transform already applied.
    # Track the terminal price and the path crossing state by reducing columns.
    if f.option_type == :barrier && f._use_gbm_transform
        n, d = size(x)
        B = f.barrier_price
        K = f.strike_price
        ST = @view x[:, end]
        crossed = falses(n)
        if f.start_price < B
            @inbounds for j in 1:d
                @simd for i in 1:n
                    crossed[i] |= x[i, j] >= B
                end
            end
        else
            @inbounds for j in 1:d
                @simd for i in 1:n
                    crossed[i] |= x[i, j] <= B
                end
            end
        end
        active = f.barrier_in_out == :in ? crossed : .!crossed
        return if f.call_put == :call
            @. discount * ifelse(active, max(ST - K, 0.0), 0.0)
        else
            @. discount * ifelse(active, max(K - ST, 0.0), 0.0)
        end
    end

    n = size(x, 1)
    y = Vector{Float64}(undef, n)
    if f._use_gbm_transform
        # Prices already in x; pass row views straight to the payoff — no per-row
        # price-vector allocation.
        @inbounds for i in 1:n
            y[i] = discount * _payoff(f, @view(x[i, :]))
        end
    else
        # Non-GBM: build the price path into a single reused buffer instead of
        # allocating a length-d vector per row inside _stock_prices. Also hoists
        # the GBM/non-GBM branch out of the loop.
        d = f.dimension
        σ = f.volatility
        S0 = f.start_price
        r = f.interest_rate
        tv = f._time_vector
        Sbuf = Vector{Float64}(undef, d)
        @inbounds for i in 1:n
            for j in 1:d
                Sbuf[j] = S0 * exp((r - 0.5 * σ^2) * tv[j] + σ * x[i, j])
            end
            y[i] = discount * _payoff(f, Sbuf)
        end
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
- `:digital` (cash-or-nothing, Black-Scholes)
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
    elseif f.option_type == :digital
        # Cash-or-nothing digital under Black-Scholes: discounted P(ITM at T).
        # Same convention as _bs_euro_price, where xbig = -d2, so
        #   call = e^{-rT}(1 - Φ(xbig)) = e^{-rT} Φ(d2),  put = e^{-rT} Φ(xbig).
        nd = Distributions.Normal()
        sqrtT = σ * sqrt(T)
        xbig = log(K * exp(-r * T) / S0) / sqrtT + sqrtT / 2
        disc = exp(-r * T)
        cdf_xbig = Distributions.cdf(nd, xbig)
        return f.call_put == :call ? disc * (1 - cdf_xbig) : disc * cdf_xbig
    else
        error(
            "Exact value not supported for option_type=:$(f.option_type)" *
            (f.option_type == :asian ? " with mean_type=:$(f.mean_type)" : ""),
        )
    end
end

function Base.show(io::IO, f::FinancialOption)
    extra = f.option_type == :barrier ? ", B=$(f.barrier_price), $(f.barrier_in_out)" : ""
    print(
        io,
        "FinancialOption(:$(f.option_type), :$(f.call_put), d=$(f.dimension), " *
        "S₀=$(f.start_price), K=$(f.strike_price), σ=$(f.volatility)$extra)",
    )
end
