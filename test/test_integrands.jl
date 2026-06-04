@testset "Integrands" begin
    @testset "CustomFun" begin
        dd = IIDStdUniform(2; seed=100)
        tm = Uniform(dd)
        f = CustomFun(tm, x -> sum(x, dims=2)[:])
        y = sample_and_evaluate(f, 1000)
        @test length(y) == 1000
        @test abs(mean(y) - 1.0) < 0.1
    end

    @testset "Keister" begin
        dd = IIDStdUniform(2; seed=200)
        tm = Gaussian(dd; covariance=0.5)
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
        dd = IIDStdUniform(3; seed=300)
        tm = Uniform(dd)

        for kind in [
            :oscillatory,
            :product_peak,
            :corner_peak,
            :gaussian_peak,
            :continuous,
            :discontinuous,
        ]
            f = Genz(tm; kind=kind)
            @test f.dimension == 3
            y = sample_and_evaluate(f, 500)
            @test length(y) == 500
            @test !any(isnan, y)
        end

        # Test exact values for continuous Genz
        f_cont = Genz(tm; kind=:continuous, a=[1.0, 1.0, 1.0], u=[0.5, 0.5, 0.5])
        exact = genz_exact(f_cont)
        y = sample_and_evaluate(f_cont, 50000)
        @test abs(mean(y) - exact) < 0.05

        f_osc1 = Genz(Uniform(IIDStdUniform(1)); kind=:oscillatory, a=[1.0], u=[0.5])
        @test genz_exact(f_osc1) ≈ -sin(1.0)
        f_osc2 =
            Genz(Uniform(IIDStdUniform(2)); kind=:oscillatory, a=[1.0, 1.0], u=[0.5, 0.5])
        @test genz_exact(f_osc2) ≈ cos(π + 1.0) * (sin(0.5) / 0.5)^2
        f_cp =
            Genz(Uniform(IIDStdUniform(2)); kind=:corner_peak, a=[1.0, 1.0], u=[0.5, 0.5])
        @test genz_exact(f_cp) ≈ 1 / 6
        f_cp2 =
            Genz(Uniform(IIDStdUniform(2)); kind=:corner_peak, a=[0.5, 2.0], u=[0.5, 0.5])
        @test genz_exact(f_cp2) ≈ 1 / 7

        f_pp =
            Genz(Uniform(IIDStdUniform(2)); kind=:product_peak, a=[1.0, 1.0], u=[0.5, 0.5])
        @test genz_exact(f_pp) ≈ 0.8598764213 atol = 1e-9
        f_gp =
            Genz(Uniform(IIDStdUniform(2)); kind=:gaussian_peak, a=[1.0, 1.0], u=[0.5, 0.5])
        @test genz_exact(f_gp) ≈ 0.8511206675 atol = 1e-9
        f_dc =
            Genz(Uniform(IIDStdUniform(2)); kind=:discontinuous, a=[1.0, 1.0], u=[0.5, 0.5])
        @test genz_exact(f_dc) ≈ 0.4208392871 atol = 1e-9
    end

    @testset "AsianOption" begin
        dd = IIDStdUniform(4; seed=400)
        tm = BrownianMotion(dd)
        f = AsianOption(
            tm;
            volatility=0.5,
            start_price=30.0,
            strike_price=25.0,
            interest_rate=0.0,
        )
        @test f.dimension == 4
        y = sample_and_evaluate(f, 1000)
        @test length(y) == 1000
        @test all(y .>= 0.0)

        # Geometric Asian exact value (Kemna-Vorst) — must agree with the
        # FinancialOption geometric-Asian exact for matching parameters.
        tmg = BrownianMotion(IIDStdUniform(50; seed=7))
        ao = AsianOption(
            tmg;
            mean_type=:geometric,
            volatility=0.2,
            start_price=100.0,
            strike_price=100.0,
            interest_rate=0.05,
        )
        fo = FinancialOption(
            tmg;
            option_type=:asian,
            asian_mean=:geometric,
            volatility=0.2,
            start_price=100.0,
            strike_price=100.0,
            interest_rate=0.05,
        )
        @test get_exact_value(ao) ≈ get_exact_value(fo)
        @test get_exact_value(ao) > 0.0
        ao_a = AsianOption(
            tmg;
            mean_type=:arithmetic,
            volatility=0.2,
            start_price=100.0,
            strike_price=100.0,
            interest_rate=0.05,
        )
        @test_throws ErrorException get_exact_value(ao_a)
    end

    @testset "FinancialOption" begin
        dd = IIDStdUniform(4; seed=401)
        tm = BrownianMotion(dd)

        # European call
        f_eu = FinancialOption(
            tm;
            option_type=:european,
            volatility=0.2,
            start_price=100.0,
            strike_price=100.0,
            interest_rate=0.05,
            call_put=:call,
        )
        y_eu = sample_and_evaluate(f_eu, 2000)
        @test all(y_eu .>= 0.0)
        @test mean(y_eu) > 0  # ATM call should have positive value

        # Lookback call
        f_lb = FinancialOption(
            tm;
            option_type=:lookback,
            volatility=0.2,
            start_price=100.0,
            strike_price=90.0,
            interest_rate=0.05,
            call_put=:call,
        )
        y_lb = sample_and_evaluate(f_lb, 1000)
        @test all(y_lb .>= 0.0)

        # Digital call
        f_dg = FinancialOption(
            tm;
            option_type=:digital,
            volatility=0.2,
            start_price=100.0,
            strike_price=100.0,
            interest_rate=0.05,
            call_put=:call,
        )
        y_dg = sample_and_evaluate(f_dg, 2000)
        @test all(y_dg .>= 0.0)
        @test all(y_dg .<= 1.0)  # digital pays 0 or discounted 1

        # Asian (same as AsianOption but via FinancialOption)
        f_as = FinancialOption(
            tm;
            option_type=:asian,
            volatility=0.5,
            start_price=30.0,
            strike_price=25.0,
            call_put=:call,
            mean_type=:arithmetic,
        )
        y_as = sample_and_evaluate(f_as, 1000)
        @test all(y_as .>= 0.0)
    end

    @testset "BoxIntegral" begin
        dd = IIDStdUniform(3; seed=410)
        tm = Uniform(dd)
        f = BoxIntegral(tm; s=2.0)
        y = sample_and_evaluate(f, 5000)
        # ∫[0,1]³ (x₁²+x₂²+x₃²) dx = 3 × 1/3 = 1.0
        @test abs(mean(y) - 1.0) < 0.05
    end

    @testset "Linear0" begin
        dd = IIDStdUniform(3; seed=420)
        tm = Uniform(dd; lower_bound=-0.5, upper_bound=0.5)
        f = Linear0(tm)
        y = sample_and_evaluate(f, 10000)
        # Exact integral = 0
        @test abs(mean(y)) < 0.05
    end

    @testset "Ishigami" begin
        dd = IIDStdUniform(3; seed=430)
        tm = Uniform(dd; lower_bound=(-π), upper_bound=π)
        f = Ishigami(tm; a=7.0, b=0.1)
        y = sample_and_evaluate(f, 10000)
        # Exact mean = a/2 = 3.5
        @test abs(mean(y) - 3.5) < 0.3
    end

    @testset "Hartmann6D" begin
        dd = IIDStdUniform(6; seed=440)
        tm = Uniform(dd)
        f = Hartmann6D(tm)
        y = sample_and_evaluate(f, 1000)
        @test length(y) == 1000
        @test all(y .< 0)  # Hartmann6D is always negative

        # Deterministic value checks (verify the A/P/α constants). Evaluating at
        # the known global minimizer gives the textbook minimum ≈ -3.32237.
        xstar = [0.20169 0.150011 0.476874 0.275332 0.311652 0.6573]
        @test evaluate(f, xstar)[1] ≈ -3.322368 atol = 1e-5
        @test evaluate(f, fill(0.5, 1, 6))[1] ≈ -0.505315 atol = 1e-5
    end

    @testset "Multimodal2D" begin
        dd = IIDStdUniform(2; seed=450)
        tm = Uniform(dd)
        f = Multimodal2D(tm)
        y = sample_and_evaluate(f, 1000)
        @test length(y) == 1000
        @test all(y .>= 0)  # sum of Gaussians is positive

        # Deterministic values: near a peak centre the matching term dominates.
        v = evaluate(f, [0.2 0.3; 0.5 0.7])
        @test v[1] ≈ 1.0000004589 atol = 1e-6   # peak 1 (h=1.0) at its centre
        @test v[2] ≈ 1.5073352177 atol = 1e-6   # peak 2 (h=1.5) at its centre
    end

    @testset "FourBranch2D" begin
        dd = IIDStdUniform(2; seed=460)
        tm = Gaussian(dd; mean=0.0, covariance=1.0)
        f = FourBranch2D(tm; k=6.0)
        y = sample_and_evaluate(f, 1000)
        @test length(y) == 1000
        @test !any(isnan, y)

        # Deterministic values: min branch = (k - |x₁| - |x₂|)/k.
        v = evaluate(f, [0.0 0.0; 1.0 2.0; 3.0 4.0])
        @test v ≈ [1.0, 0.5, -1 / 6]
    end

    @testset "Barrier Option" begin
        dd = IIDStdUniform(50; seed=7)
        tm = GeometricBrownianMotion(
            dd;
            volatility=0.2,
            start_price=100.0,
            interest_rate=0.05,
            t_final=1.0,
        )
        fo = FinancialOption(
            tm;
            option_type=:barrier,
            strike_price=100.0,
            barrier_price=120.0,
            barrier_in_out=:out,
        )
        x = transform(tm, gen_samples(dd, 1000))
        y = evaluate(fo, x)
        @test length(y) == 1000
        @test all(y .>= 0.0)
    end

    @testset "FinancialOption Exact Values" begin
        dd = IIDStdUniform(50; seed=7)
        tm = GeometricBrownianMotion(
            dd;
            volatility=0.2,
            start_price=100.0,
            interest_rate=0.05,
            t_final=1.0,
        )
        fo_euro = FinancialOption(tm; option_type=:european, strike_price=100.0)
        ev = get_exact_value(fo_euro)
        @test ev > 0.0
        @test ev < 20.0

        fo_asian = FinancialOption(
            tm;
            option_type=:asian,
            strike_price=100.0,
            asian_mean=:geometric,
        )
        ev_asian = get_exact_value(fo_asian)
        @test ev_asian > 0.0

        # Digital (cash-or-nothing) European option: discounted P(ITM at T).
        S0, K, r, sigma, T = 100.0, 100.0, 0.05, 0.2, 1.0
        d2 = (log(S0 / K) + (r - sigma^2 / 2) * T) / (sigma * sqrt(T))
        nd = Distributions.Normal()
        fo_dig_c = FinancialOption(tm; option_type=:digital, call_put=:call,
            strike_price=100.0)
        fo_dig_p = FinancialOption(tm; option_type=:digital, call_put=:put,
            strike_price=100.0)
        @test get_exact_value(fo_dig_c) ≈ exp(-r * T) * Distributions.cdf(nd, d2)
        @test get_exact_value(fo_dig_p) ≈ exp(-r * T) * Distributions.cdf(nd, -d2)
        @test get_exact_value(fo_dig_c) + get_exact_value(fo_dig_p) ≈ exp(-r * T)
    end

    @testset "FinancialOptionML" begin
        dd = IIDStdUniform(16; seed=7)
        tm = GeometricBrownianMotion(
            dd;
            volatility=0.2,
            start_price=100.0,
            interest_rate=0.05,
            t_final=1.0,
        )
        fml = FinancialOptionML(tm; d_coarsest=4)
        @test dimension_at_level(fml, 0) == 4
        @test dimension_at_level(fml, 1) == 8
        @test dimension_at_level(fml, 2) == 16

        x = transform(tm, gen_samples(dd, 100))
        Pc, Pf = ml_evaluate(fml, x, 2)
        @test length(Pc) == 100
        @test length(Pf) == 100
    end

    @testset "SensitivityIndices" begin
        dd = IIDStdUniform(6; seed=7)
        tm = Uniform(dd)
        base = Ishigami(tm)
        si = SensitivityIndices(base)
        @test si.d_original == 3

        x = transform(tm, gen_samples(dd, 200))
        y = evaluate(si, x)
        @test size(y, 1) == 200
        @test size(y, 2) == 3

        # End-to-end correctness: pick-freeze estimates vs the analytical Ishigami
        # indices. The base must live on U(-π,π)³, and the wrapper consumes 2d=6
        # uniform columns (X = cols 1:3, Z = cols 4:6). n and tolerance chosen so
        # the estimate reliably lands near exact (validated against a reference
        # pick-freeze MC: max component error ≈ 0.014 at this n).
        ddc = IIDStdUniform(6; seed = 42)
        tmc = Uniform(ddc; lower_bound = -π, upper_bound = π)
        sic = SensitivityIndices(Ishigami(tmc))
        xc = transform(tmc, gen_samples(ddc, 2^16))
        closed, total = compute_sensitivity_indices(sic, xc)
        ref = ishigami_exact()
        @test all(abs.(closed .- ref.closed) .<= 0.05)
        @test all(abs.(total .- ref.total) .<= 0.05)
    end

    @testset "BayesianLRCoeffs" begin
        features = randn(50, 3)
        response = rand(0:1, 50)
        dd = IIDStdUniform(3; seed=7)
        tm = Gaussian(dd)
        blr =
            BayesianLRCoeffs(tm; feature_array=features, response_vector=Float64.(response))
        x = transform(tm, gen_samples(dd, 100))
        y = evaluate(blr, x)
        @test length(y) == 100
    end
end
