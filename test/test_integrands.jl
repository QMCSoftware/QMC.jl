@testset "Integrands" begin
    @testset "CustomFun" begin
        dd = IIDStdUniform(2; seed = 100)
        tm = Uniform(dd)
        f = CustomFun(tm, x -> sum(x, dims = 2)[:])
        y = sample_and_evaluate(f, 1000)
        @test length(y) == 1000
        @test abs(mean(y) - 1.0) < 0.1
    end

    @testset "Keister" begin
        dd = IIDStdUniform(2; seed = 200)
        tm = Gaussian(dd; covariance = 0.5)
        f = Keister(tm)
        @test f.dimension == 2
        y = sample_and_evaluate(f, 5000)
        @test length(y) == 5000
        @test !any(isnan, y)
        @test !any(isinf, y)
        # Verify exact value
        exact = keister_exact(2)
        @test exact > 0
        @test keister_exact(1) ≈ sqrt(π) * exp(-0.25) rtol = 1e-14
        @test keister_exact(3) ≈ (π^(3 / 2) / 2) * exp(-0.25) rtol = 1e-14
    end

    @testset "Genz" begin
        dd = IIDStdUniform(3; seed = 300)
        tm = Uniform(dd)

        for kind in [:oscillatory, :product_peak, :corner_peak,
            :gaussian_peak, :continuous, :discontinuous]
            f = Genz(tm; kind = kind)
            @test f.dimension == 3
            y = sample_and_evaluate(f, 500)
            @test length(y) == 500
            @test !any(isnan, y)
        end

        # Test exact values for continuous Genz
        f_cont = Genz(tm; kind = :continuous, a = [1.0, 1.0, 1.0], u = [0.5, 0.5, 0.5])
        exact = genz_exact(f_cont)
        y = sample_and_evaluate(f_cont, 50000)
        @test abs(mean(y) - exact) < 0.05
    end

    @testset "AsianOption" begin
        dd = IIDStdUniform(4; seed = 400)
        tm = BrownianMotion(dd)
        f = AsianOption(tm; volatility = 0.5, start_price = 30.0,
            strike_price = 25.0, interest_rate = 0.0)
        @test f.dimension == 4
        y = sample_and_evaluate(f, 1000)
        @test length(y) == 1000
        @test all(y .>= 0.0)
    end

    @testset "FinancialOption" begin
        dd = IIDStdUniform(4; seed = 401)
        tm = BrownianMotion(dd)

        # European call
        f_eu = FinancialOption(tm; option_type = :european, volatility = 0.2,
            start_price = 100.0, strike_price = 100.0,
            interest_rate = 0.05, call_put = :call)
        y_eu = sample_and_evaluate(f_eu, 2000)
        @test all(y_eu .>= 0.0)
        @test mean(y_eu) > 0  # ATM call should have positive value

        # Lookback call
        f_lb = FinancialOption(tm; option_type = :lookback, volatility = 0.2,
            start_price = 100.0, strike_price = 90.0,
            interest_rate = 0.05, call_put = :call)
        y_lb = sample_and_evaluate(f_lb, 1000)
        @test all(y_lb .>= 0.0)

        # Digital call
        f_dg = FinancialOption(tm; option_type = :digital, volatility = 0.2,
            start_price = 100.0, strike_price = 100.0,
            interest_rate = 0.05, call_put = :call)
        y_dg = sample_and_evaluate(f_dg, 2000)
        @test all(y_dg .>= 0.0)
        @test all(y_dg .<= 1.0)  # digital pays 0 or discounted 1

        # Asian (same as AsianOption but via FinancialOption)
        f_as = FinancialOption(tm; option_type = :asian, volatility = 0.5,
            start_price = 30.0, strike_price = 25.0,
            call_put = :call, mean_type = :arithmetic)
        y_as = sample_and_evaluate(f_as, 1000)
        @test all(y_as .>= 0.0)
    end

    @testset "BoxIntegral" begin
        dd = IIDStdUniform(3; seed = 410)
        tm = Uniform(dd)
        f = BoxIntegral(tm; s = 2.0)
        y = sample_and_evaluate(f, 5000)
        # ∫[0,1]³ (x₁²+x₂²+x₃²) dx = 3 × 1/3 = 1.0
        @test abs(mean(y) - 1.0) < 0.05
    end

    @testset "Linear0" begin
        dd = IIDStdUniform(3; seed = 420)
        tm = Uniform(dd; lower_bound = -0.5, upper_bound = 0.5)
        f = Linear0(tm)
        y = sample_and_evaluate(f, 10000)
        # Exact integral = 0
        @test abs(mean(y)) < 0.05
    end

    @testset "Ishigami" begin
        dd = IIDStdUniform(3; seed = 430)
        tm = Uniform(dd; lower_bound = -π, upper_bound = π)
        f = Ishigami(tm; a = 7.0, b = 0.1)
        y = sample_and_evaluate(f, 10000)
        # Exact mean = a/2 = 3.5
        @test abs(mean(y) - 3.5) < 0.3
    end

    @testset "Hartmann6D" begin
        dd = IIDStdUniform(6; seed = 440)
        tm = Uniform(dd)
        f = Hartmann6D(tm)
        y = sample_and_evaluate(f, 1000)
        @test length(y) == 1000
        @test all(y .< 0)  # Hartmann6D is always negative
    end

    @testset "Multimodal2D" begin
        dd = IIDStdUniform(2; seed = 450)
        tm = Uniform(dd)
        f = Multimodal2D(tm)
        y = sample_and_evaluate(f, 1000)
        @test length(y) == 1000
        @test all(y .>= 0)  # sum of Gaussians is positive
    end

    @testset "FourBranch2D" begin
        dd = IIDStdUniform(2; seed = 460)
        tm = Gaussian(dd; mean = 0.0, covariance = 1.0)
        f = FourBranch2D(tm; k = 6.0)
        y = sample_and_evaluate(f, 1000)
        @test length(y) == 1000
        @test !any(isnan, y)
    end

    @testset "Barrier Option" begin
        dd = IIDStdUniform(50; seed = 7)
        tm = GeometricBrownianMotion(dd; volatility = 0.2, start_price = 100.0,
            interest_rate = 0.05, t_final = 1.0)
        fo = FinancialOption(tm; option_type = :barrier, strike_price = 100.0,
            barrier_price = 120.0, barrier_in_out = :out)
        x = transform(tm, gen_samples(dd, 1000))
        y = evaluate(fo, x)
        @test length(y) == 1000
        @test all(y .>= 0.0)
    end

    @testset "FinancialOption Exact Values" begin
        dd = IIDStdUniform(50; seed = 7)
        tm = GeometricBrownianMotion(dd; volatility = 0.2, start_price = 100.0,
            interest_rate = 0.05, t_final = 1.0)
        fo_euro = FinancialOption(tm; option_type = :european, strike_price = 100.0)
        ev = get_exact_value(fo_euro)
        @test ev > 0.0
        @test ev < 20.0

        fo_asian = FinancialOption(tm; option_type = :asian, strike_price = 100.0,
            asian_mean = :geometric)
        ev_asian = get_exact_value(fo_asian)
        @test ev_asian > 0.0
    end

    @testset "FinancialOptionML" begin
        dd = IIDStdUniform(16; seed = 7)
        tm = GeometricBrownianMotion(dd; volatility = 0.2, start_price = 100.0,
            interest_rate = 0.05, t_final = 1.0)
        fml = FinancialOptionML(tm; d_coarsest = 4)
        @test dimension_at_level(fml, 0) == 4
        @test dimension_at_level(fml, 1) == 8
        @test dimension_at_level(fml, 2) == 16

        x = transform(tm, gen_samples(dd, 100))
        Pc, Pf = ml_evaluate(fml, x, 2)
        @test length(Pc) == 100
        @test length(Pf) == 100
    end

    @testset "SensitivityIndices" begin
        dd = IIDStdUniform(6; seed = 7)
        tm = Uniform(dd)
        base = Ishigami(tm)
        si = SensitivityIndices(base)
        @test si.d_original == 3

        x = transform(tm, gen_samples(dd, 200))
        y = evaluate(si, x)
        @test size(y, 1) == 200
        @test size(y, 2) == 3
    end

    @testset "BayesianLRCoeffs" begin
        features = randn(50, 3)
        response = rand(0:1, 50)
        dd = IIDStdUniform(3; seed = 7)
        tm = Gaussian(dd)
        blr = BayesianLRCoeffs(
            tm;
            feature_array = features,
            response_vector = Float64.(response),
        )
        x = transform(tm, gen_samples(dd, 100))
        y = evaluate(blr, x)
        @test length(y) == 100
    end
end
