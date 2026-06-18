"""
    FinancialOptionML(dd::AbstractDiscreteDistribution;
                      d_coarsest=2, option_type=:asian, mean_type=:arithmetic,
                      volatility=0.5, start_price=30.0, strike_price=25.0,
                      interest_rate=0.0, call_put=:call)

Multilevel financial option integrand implementing `AbstractMLIntegrand`.

At level ``\\ell``, uses ``d_{\\text{coarsest}} \\cdot 2^\\ell`` time steps. The
coarse/fine pairing uses every-other-step subsampling: coarse path increments
are obtained by summing pairs of fine-grid Brownian increments.

The number of levels is determined by `dimension(dd)`: the dimension must equal
``d_{\\text{coarsest}} \\cdot 2^{L-1}`` for some integer ``L \\geq 1``.

# Arguments
- `dd`: Discrete distribution whose dimension determines the finest level.
- `d_coarsest::Int=2`: Number of time steps at level 0.
- `option_type::Symbol=:asian`: Option type (`:european`, `:asian`, `:lookback`, `:digital`).
- Other financial parameters match `FinancialOption`.

# Examples
```jldoctest
julia> using QMC

julia> f = FinancialOptionML(IIDStdUniform(32; seed=7); d_coarsest=4, option_type=:asian)
FinancialOptionML(:asian, :call, d=32, d_coarsest=4, levels=4)

julia> dimension_at_level(f, 0)
4

julia> dimension_at_level(f, 1)
8

julia> cost_at_level(f, 2)
16.0
```

```jldoctest
julia> using QMC, Random

julia> Random.seed!(7);

julia> f = FinancialOptionML(IIDStdUniform(32; seed=7); d_coarsest=4, option_type=:asian);

julia> qc, qf = ml_evaluate(f, randn(1, dimension_at_level(f, 1)), 1);

julia> (length(qc), length(qf))
(1, 1)
```
"""
struct FinancialOptionML{TM <: AbstractTrueMeasure} <: AbstractMLIntegrand
    true_measure::TM
    dimension::Int
    d_coarsest::Int
    nb_of_levels::Int
    volatility::Float64
    start_price::Float64
    strike_price::Float64
    interest_rate::Float64
    call_put::Symbol
    option_type::Symbol
    mean_type::Symbol
end

function _ml_nb_of_levels(dim::Int, d_coarsest::Int)
    d_coarsest > 0 || throw(ArgumentError("d_coarsest must be positive"))
    ratio, remainder = divrem(dim, d_coarsest)
    remainder == 0 && ratio > 0 && ispow2(ratio) || throw(
        ArgumentError(
            "dimension ($dim) must be d_coarsest ($d_coarsest) × 2^k for some integer k ≥ 0",
        ),
    )
    return Int(log2(ratio)) + 1
end

function FinancialOptionML(
    dd::AbstractDiscreteDistribution;
    d_coarsest::Int=2,
    option_type::Symbol=:asian,
    mean_type::Symbol=:arithmetic,
    volatility::Float64=0.5,
    start_price::Float64=30.0,
    strike_price::Float64=25.0,
    interest_rate::Float64=0.0,
    call_put::Symbol=:call,
)
    dim = dimension(dd)
    nb_of_levels = _ml_nb_of_levels(dim, d_coarsest)
    tm = Gaussian(dd)
    return FinancialOptionML(
        tm,
        dim,
        d_coarsest,
        nb_of_levels,
        volatility,
        start_price,
        strike_price,
        interest_rate,
        call_put,
        option_type,
        mean_type,
    )
end

function FinancialOptionML(
    tm::BrownianMotion;
    d_coarsest::Int=2,
    option_type::Symbol=:asian,
    mean_type::Symbol=:arithmetic,
    volatility::Float64=0.5,
    start_price::Float64=30.0,
    strike_price::Float64=25.0,
    interest_rate::Float64=0.0,
    call_put::Symbol=:call,
)
    dim = dimension(tm)
    nb_of_levels = _ml_nb_of_levels(dim, d_coarsest)
    return FinancialOptionML(
        tm,
        dim,
        d_coarsest,
        nb_of_levels,
        volatility,
        start_price,
        strike_price,
        interest_rate,
        call_put,
        option_type,
        mean_type,
    )
end

function FinancialOptionML(
    tm::GeometricBrownianMotion;
    d_coarsest::Int=2,
    option_type::Symbol=:asian,
    mean_type::Symbol=:arithmetic,
    volatility::Union{Nothing, Float64}=nothing,
    start_price::Union{Nothing, Float64}=nothing,
    strike_price::Float64=25.0,
    interest_rate::Union{Nothing, Float64}=nothing,
    call_put::Symbol=:call,
)
    dim = dimension(tm)
    nb_of_levels = _ml_nb_of_levels(dim, d_coarsest)
    volatility = isnothing(volatility) ? sqrt(tm.diffusion) : volatility
    start_price = isnothing(start_price) ? tm.initial_value : start_price
    interest_rate = isnothing(interest_rate) ? tm.drift : interest_rate
    return FinancialOptionML(
        tm,
        dim,
        d_coarsest,
        nb_of_levels,
        volatility,
        start_price,
        strike_price,
        interest_rate,
        call_put,
        option_type,
        mean_type,
    )
end

QMC.dimension_at_level(f::FinancialOptionML, level::Int) = f.d_coarsest * (1 << level)

QMC.cost_at_level(f::FinancialOptionML, level::Int) = Float64(f.d_coarsest * (1 << level))

function _ml_time_horizon(f::FinancialOptionML)
    return hasproperty(f.true_measure, :time_vector) ? f.true_measure.time_vector[end] : 1.0
end

"""
Build stock prices from standard normal increments at a given resolution.
"""
function _build_stock_path(f::FinancialOptionML, z::AbstractVector, d::Int)
    σ = f.volatility
    S0 = f.start_price
    r = f.interest_rate
    T = _ml_time_horizon(f)
    dt = T / d
    S = Vector{Float64}(undef, d)
    S[1] = S0 * exp((r - σ^2/2) * dt + σ * sqrt(dt) * z[1])
    @inbounds for j in 2:d
        S[j] = S[j - 1] * exp((r - σ^2/2) * dt + σ * sqrt(dt) * z[j])
    end
    return S
end

function _stock_path_from_brownian(f::FinancialOptionML, w::AbstractVector, tv::AbstractVector)
    σ = f.volatility
    S0 = f.start_price
    r = f.interest_rate
    S = Vector{Float64}(undef, length(w))
    @inbounds for j in eachindex(w)
        S[j] = S0 * exp((r - σ^2/2) * tv[j] + σ * w[j])
    end
    return S
end

function _coupled_stock_paths(f::FinancialOptionML, x_fine::AbstractVector, level::Int)
    d_fine = length(x_fine)
    if f.true_measure isa GeometricBrownianMotion
        S_fine = x_fine
        S_coarse = level == 0 ? nothing : @view(x_fine[2:2:d_fine])
        return S_coarse, S_fine
    elseif f.true_measure isa BrownianMotion
        tv_fine = @view(f.true_measure.time_vector[1:d_fine])
        S_fine = _stock_path_from_brownian(f, x_fine, tv_fine)
        if level == 0
            return nothing, S_fine
        end
        S_coarse =
            _stock_path_from_brownian(f, @view(x_fine[2:2:d_fine]), @view(tv_fine[2:2:d_fine]))
        return S_coarse, S_fine
    end

    S_fine = _build_stock_path(f, x_fine, d_fine)
    if level == 0
        return nothing, S_fine
    end

    d_coarse = div(d_fine, 2)
    z_coarse = Vector{Float64}(undef, d_coarse)
    @inbounds for j in 1:d_coarse
        z_coarse[j] = (x_fine[2j - 1] + x_fine[2j]) / sqrt(2.0)
    end
    S_coarse = _build_stock_path(f, z_coarse, d_coarse)
    return S_coarse, S_fine
end

"""
Compute payoff from stock path.
"""
function _ml_payoff(f::FinancialOptionML, S::AbstractVector)
    K = f.strike_price
    opt = f.option_type

    if opt == :european
        ST = S[end]
        return f.call_put == :call ? max(ST - K, 0.0) : max(K - ST, 0.0)
    elseif opt == :asian
        if f.mean_type == :arithmetic
            avg = sum(S) / length(S)
        else
            avg = exp(sum(log.(S)) / length(S))
        end
        return f.call_put == :call ? max(avg - K, 0.0) : max(K - avg, 0.0)
    elseif opt == :lookback
        if f.call_put == :call
            return max(maximum(S) - K, 0.0)
        else
            return max(K - minimum(S), 0.0)
        end
    elseif opt == :digital
        ST = S[end]
        itm = f.call_put == :call ? (ST > K) : (ST < K)
        return itm ? 1.0 : 0.0
    else
        error("Unknown option_type: $(f.option_type)")
    end
end

function QMC.ml_evaluate(f::FinancialOptionML, x::AbstractMatrix, level::Int)
    n = size(x, 1)
    d_fine = dimension_at_level(f, level)
    T = _ml_time_horizon(f)
    r = f.interest_rate
    discount = exp(-r * T)

    Qf = zeros(n)
    Qc = zeros(n)

    @inbounds for i in 1:n
        x_fine = @view(x[i, 1:d_fine])
        S_coarse, S_fine = _coupled_stock_paths(f, x_fine, level)
        Qf[i] = discount * _ml_payoff(f, S_fine)

        if level > 0
            Qc[i] = discount * _ml_payoff(f, S_coarse)
        end
    end

    return Qc, Qf
end

function Base.show(io::IO, f::FinancialOptionML)
    print(
        io,
        "FinancialOptionML(:$(f.option_type), :$(f.call_put), d=$(f.dimension), " *
        "d_coarsest=$(f.d_coarsest), levels=$(f.nb_of_levels))",
    )
end
