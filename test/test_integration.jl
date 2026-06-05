@testset "End-to-End Integration Pipelines" begin
    @testset "IID MC: Uniform integral" begin
        # ∫₀¹ x² dx = 1/3
        dd = IIDStdUniform(1; seed=1000)
        tm = Uniform(dd)
        f = CustomFun(tm, x -> x[:, 1] .^ 2)
        sc = CubMCCLT(f; abs_tol=0.02, n_init=4096)
        result = integrate(sc)
        @test abs(result.solution - 1.0 / 3.0) < 0.05
    end

    @testset "Lattice QMC: Genz continuous" begin
        dd = Lattice(2; randomize=true, seed=2000)
        tm = Uniform(dd)
        f = Genz(tm; kind=:continuous, a=[1.0, 1.0], u=[0.5, 0.5])
        exact = genz_exact(f)
        sc = CubQMCLatticeG(f; abs_tol=0.1, n_init=2^10, n_reps=16)
        result = integrate(sc)
        @test abs(result.solution - exact) < 1.0
        @test result.data[:n] >= 2^10
    end

    @testset "Digital Net QMC: Genz continuous" begin
        dd = DigitalNetB2(2; randomize="LMS_DS", graycode=false, seed=3000)
        tm = Uniform(dd)
        f = Genz(tm; kind=:continuous, a=[1.0, 1.0], u=[0.5, 0.5])
        exact = genz_exact(f)
        sc = CubQMCNetG(f; abs_tol=0.1, n_init=2^10)
        result = integrate(sc)
        @test abs(result.solution - exact) < 1.0
        @test result.data[:n] >= 2^10
    end

    @testset "Asian option (smoke test)" begin
        dd = Lattice(8; randomize=true, seed=4000)
        tm = BrownianMotion(dd)
        f = AsianOption(
            tm;
            volatility=0.2,
            start_price=100.0,
            strike_price=100.0,
            interest_rate=0.05,
            call_put=:call,
            mean_type=:arithmetic,
        )
        sc = CubQMCLatticeG(f; abs_tol=0.5, n_init=2^8, n_reps=4)
        result = integrate(sc)
        @test result.solution > 0.0
        @test result.data[:n] >= 2^8
    end

    @testset "GBM + FinancialOption pipeline" begin
        dd = IIDStdUniform(4; seed=5000)
        gbm = GeometricBrownianMotion(
            dd;
            t_final=1.0,
            initial_value=100.0,
            drift=0.05,
            diffusion=0.04,
        )
        f = FinancialOption(
            gbm;
            option_type=:european,
            volatility=0.2,
            start_price=100.0,
            strike_price=100.0,
            interest_rate=0.05,
            call_put=:call,
        )
        y = sample_and_evaluate(f, 2000)
        @test all(y .>= 0.0)
        @test mean(y) > 0  # ATM call has positive value
    end

    @testset "Periodization smoke test" begin
        x = rand(100, 3)
        for pt in [:C1SIN, :C1, :C2SIN, :C3, :BAKER, :NONE]
            xp = periodize(x, pt)
            @test size(xp) == (100, 3)
            if pt != :NONE
                @test all(0.0 .<= xp .<= 1.0)
            end
        end
    end
end
