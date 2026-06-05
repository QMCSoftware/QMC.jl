using Test
using QMC
using Statistics

# ── Simple multilevel test integrand ──
# A FinancialOption-style multilevel integrand for Asian call option.
# At level l, uses 2^(l+1) time steps.

struct TestMLIntegrand <: AbstractMLIntegrand
    true_measure::AbstractTrueMeasure
    dimension::Int
    d_coarsest::Int
    volatility::Float64
    start_price::Float64
    strike_price::Float64
    interest_rate::Float64
end

function TestMLIntegrand(
    dd::AbstractDiscreteDistribution;
    d_coarsest::Int=1,
    volatility::Float64=0.5,
    start_price::Float64=30.0,
    strike_price::Float64=35.0,
    interest_rate::Float64=0.0,
)
    # The dimension of the base DD determines max level
    tm = Gaussian(dd)
    return TestMLIntegrand(
        tm,
        dd.dimension,
        d_coarsest,
        volatility,
        start_price,
        strike_price,
        interest_rate,
    )
end

QMC.dimension_at_level(f::TestMLIntegrand, level::Int) = f.d_coarsest * 2^level

QMC.cost_at_level(f::TestMLIntegrand, level::Int) = Float64(2 * f.d_coarsest * 2^level)

function _gbm_payoff(f::TestMLIntegrand, x::AbstractVector)
    d = length(x)
    σ = f.volatility
    S0 = f.start_price
    r = f.interest_rate
    T = 1.0
    dt = T / d
    # Build GBM path from standard normal increments
    S = zeros(d)
    S[1] = S0 * exp((r - σ^2/2) * dt + σ * sqrt(dt) * x[1])
    for j in 2:d
        S[j] = S[j - 1] * exp((r - σ^2/2) * dt + σ * sqrt(dt) * x[j])
    end
    # Asian arithmetic call payoff
    avg = mean(S)
    return max(avg - f.strike_price, 0.0) * exp(-r * T)
end

function QMC.ml_evaluate(f::TestMLIntegrand, x::AbstractMatrix, level::Int)
    n = size(x, 1)
    d_fine = dimension_at_level(f, level)
    Qf = zeros(n)
    Qc = zeros(n)
    for i in 1:n
        # Fine level evaluation
        x_fine = x[i, 1:d_fine]
        Qf[i] = _gbm_payoff(f, x_fine)
        # Coarse level evaluation (using every other time step)
        if level == 0
            Qc[i] = 0.0
        else
            d_coarse = dimension_at_level(f, level - 1)
            # Coarse samples: sum pairs of fine increments
            x_coarse = zeros(d_coarse)
            for j in 1:d_coarse
                # Average the two fine-grid increments to get coarse-grid increment
                x_coarse[j] = (x_fine[2j - 1] + x_fine[2j]) / sqrt(2.0)
            end
            Qc[i] = _gbm_payoff(f, x_coarse)
        end
    end
    return Qc, Qf
end

# ── Tests ──

@testset "Multilevel Interface" begin
    @testset "spawn_dd" begin
        dd = IIDStdUniform(4)
        dd2 = spawn_dd(dd, 8)
        @test dd2.dimension == 8

        dd_lat = Lattice(4; replications=8, order="gray")
        dd_lat2 = spawn_dd(dd_lat, 16)
        @test dd_lat2.dimension == 16
        @test dd_lat2.order == "gray"
        @test dd_lat2.replications == 8

        lat_source = [1, 3, 5, 7, 9, 11]
        dd_lat_custom =
            Lattice(4; randomize=false, order="linear", generating_vector=lat_source)
        dd_lat_custom2 = spawn_dd(dd_lat_custom, 6)
        @test dd_lat_custom2.dimension == 6
        @test dd_lat_custom2.order == "linear"
        @test dd_lat_custom2.gen_vector == UInt64.(lat_source)
        @test gen_samples(dd_lat_custom2, 8) == gen_samples(
            Lattice(6; randomize=false, order="linear", generating_vector=lat_source),
            8,
        )

        dd_dn = DigitalNetB2(4; replications=8)
        dd_dn2 = spawn_dd(dd_dn, 16)
        @test dd_dn2.dimension == 16

        dd_dn_alpha = DigitalNetB2(4; randomize="LMS_DS", seed=7, replications=2, alpha=2)
        dd_dn_alpha2 = spawn_dd(dd_dn_alpha, 8)
        @test dd_dn_alpha2.dimension == 8
        @test dd_dn_alpha2.alpha == 2
        @test dd_dn_alpha2.t == dd_dn_alpha.t
        @test dd_dn_alpha2.replications == 2
        @test size(gen_samples(dd_dn_alpha2, 8)) == (2, 8, 8)

        dd_dn_custom = DigitalNetB2(
            4;
            randomize="none",
            generating_matrices=Int.(dd_dn.direction_nums[:, 1:6] .>> 26),
        )
        dd_dn_custom2 = spawn_dd(dd_dn_custom, 2)
        @test dd_dn_custom2.direction_nums == dd_dn_custom.direction_nums[1:2, :]

        mktemp() do path, io
            write(io, "2\n4\n16\n64\n")
            for _ in 1:4
                write(io, "1 2 4 8\n")
            end
            flush(io)

            dd_dn_file = DigitalNetB2(1; randomize="none", alpha=2, generating_matrices=path)
            dd_dn_file2 = spawn_dd(dd_dn_file, 1)
            @test dd_dn_file2.source_bits == dd_dn_file.source_bits
            @test dd_dn_file2.t == dd_dn_file.t
            @test dd_dn_file2.alpha == dd_dn_file.alpha
            @test gen_samples(dd_dn_file2, 4) == gen_samples(dd_dn_file, 4)
        end
    end

    @testset "spawn_tm" begin
        dd = IIDStdUniform(4)
        tm = Gaussian(dd)
        dd2 = spawn_dd(dd, 8)
        tm2 = spawn_tm(tm, dd2)
        @test tm2.dimension == 8
    end

    @testset "dimension_at_level" begin
        dd = IIDStdUniform(32)
        f = TestMLIntegrand(dd; d_coarsest=1)
        @test dimension_at_level(f, 0) == 1
        @test dimension_at_level(f, 1) == 2
        @test dimension_at_level(f, 2) == 4
        @test dimension_at_level(f, 3) == 8
    end
end

@testset "CubMLMC" begin
    dd = IIDStdUniform(32)
    f = TestMLIntegrand(dd; d_coarsest=1, volatility=0.5, start_price=30.0, strike_price=35.0)
    sc = CubMLMC(f; abs_tol=0.5, n_init=256, levels_min=2, levels_max=6)
    result = integrate(sc)

    @test result.solution isa Float64
    @test !isnan(result.solution)
    @test result.data[:n_total] > 0
    @test result.data[:levels] >= 3  # levels_min + 1
end

@testset "CubMLMCCont" begin
    dd = IIDStdUniform(32)
    f = TestMLIntegrand(dd; d_coarsest=1, volatility=0.5, start_price=30.0, strike_price=35.0)
    sc = CubMLMCCont(f; abs_tol=0.5, n_init=256, levels_min=2, levels_max=6, n_tols=5)
    result = integrate(sc)

    @test result.solution isa Float64
    @test !isnan(result.solution)
    @test result.data[:n_total] > 0
end

@testset "CubMLQMCCont" begin
    dd = Lattice(32; replications=8)
    f = TestMLIntegrand(dd; d_coarsest=1, volatility=0.5, start_price=30.0, strike_price=35.0)
    sc = CubMLQMCCont(f; abs_tol=0.5, n_init=64, levels_min=2, levels_max=6, n_tols=5)
    result = integrate(sc)

    @test result.solution isa Float64
    @test !isnan(result.solution)
    @test result.data[:n_total] > 0
    @test result.data[:replications] == 8
end
