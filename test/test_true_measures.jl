@testset "True Measures" begin
    @testset "Uniform" begin
        dd = IIDStdUniform(2; seed=10)
        tm = Uniform(dd; lower_bound=-1.0, upper_bound=2.0)
        x = gen_samples(dd, 1000)
        xt = transform(tm, x)
        @test size(xt) == (1000, 2)
        @test all(-1.0 .<= xt .<= 2.0)
        @test abs(mean(xt) - 0.5) < 0.1
    end

    @testset "Gaussian (scalar)" begin
        dd = IIDStdUniform(3; seed=20)
        tm = Gaussian(dd; mean=0.0, covariance=1.0)
        x = gen_samples(dd, 5000)
        xt = transform(tm, x)
        @test size(xt) == (5000, 3)
        @test abs(mean(xt)) < 0.1
        @test abs(std(xt) - 1.0) < 0.15
    end

    @testset "Gaussian (custom covariance)" begin
        dd = IIDStdUniform(2; seed=30)
        Σ = [2.0 0.5; 0.5 1.0]
        tm = Gaussian(dd; mean=[1.0, -1.0], covariance=Σ, decomp_type=:Cholesky)
        x = gen_samples(dd, 5000)
        xt = transform(tm, x)
        @test size(xt) == (5000, 2)
        @test abs(mean(xt[:, 1]) - 1.0) < 0.2
        @test abs(mean(xt[:, 2]) - (-1.0)) < 0.2
    end

    @testset "Deterministic inverse-CDF boundaries" begin
        dd = DigitalNetB2(2; randomize="none", seed=31)
        x = gen_samples(dd, 8)
        @test x[1, :] == [0.0, 0.0]

        gauss = transform(Gaussian(dd; mean=0.0, covariance=1.0), x)
        stud = transform(StudentT(dd; df=5.0), x)
        jsu = transform(JohnsonsSU(dd), x)
        bm = transform(BrownianMotion(dd), x)
        gbm = transform(
            GeometricBrownianMotion(dd; initial_value=100.0, drift=0.05, diffusion=0.04),
            x,
        )

        for y in (gauss, stud, jsu, bm, gbm)
            @test size(y) == size(x)
            @test all(isfinite, y)
            @test all(isfinite, y[1, :])
        end
        @test all(gbm .> 0.0)
    end

    @testset "BrownianMotion" begin
        dd = IIDStdUniform(4; seed=40)
        tm = BrownianMotion(dd)
        x = gen_samples(dd, 2000)
        xt = transform(tm, x)
        @test size(xt) == (2000, 4)
        @test abs(mean(xt[:, end])) < 0.1
        @test abs(var(xt[:, end]) - 1.0) < 0.3
    end

    @testset "Lebesgue" begin
        dd = IIDStdUniform(2; seed=50)
        tm = Lebesgue(dd; lower_bound=0.0, upper_bound=3.0)
        @test tm.volume ≈ 9.0
        x = gen_samples(dd, 100)
        xt = transform(tm, x)
        @test all(0.0 .<= xt .<= 3.0)
    end

    @testset "GeometricBrownianMotion" begin
        dd = IIDStdUniform(4; seed=60)
        gbm = GeometricBrownianMotion(
            dd;
            t_final=1.0,
            initial_value=100.0,
            drift=0.05,
            diffusion=0.04,
        )
        x = gen_samples(dd, 5000)
        paths = transform(gbm, x)
        @test size(paths) == (5000, 4)
        # GBM values must be positive
        @test all(paths .> 0)
        # Mean of GBM at time T: S₀ exp(γ T)
        expected_mean_T = 100.0 * exp(0.05 * 1.0)
        @test abs(mean(paths[:, end]) - expected_mean_T) / expected_mean_T < 0.1
    end

    @testset "StudentT" begin
        dd = IIDStdUniform(2; seed=70)
        tm = StudentT(dd; df=5.0)
        x = gen_samples(dd, 5000)
        xt = transform(tm, x)
        @test size(xt) == (5000, 2)
        # Student-t with df=5 has mean 0 and variance df/(df-2) = 5/3
        @test abs(mean(xt)) < 0.15
    end

    @testset "Triangular" begin
        dd = IIDStdUniform(2; seed=80)
        tm = Triangular(dd; lower=0.0, upper=1.0, mode=0.5)
        x = gen_samples(dd, 5000)
        xt = transform(tm, x)
        @test size(xt) == (5000, 2)
        @test all(0.0 .<= xt .<= 1.0)
        # Mean of Triangular(0,1,0.5) = (0+1+0.5)/3 = 0.5
        @test abs(mean(xt) - 0.5) < 0.05
    end

    @testset "Kumaraswamy" begin
        dd = IIDStdUniform(2; seed=90)
        tm = Kumaraswamy(dd; alpha=2.0, beta=5.0)
        x = gen_samples(dd, 5000)
        xt = transform(tm, x)
        @test size(xt) == (5000, 2)
        @test all(0.0 .<= xt .<= 1.0)
    end

    @testset "JohnsonsSU" begin
        dd = IIDStdUniform(2; seed=91)
        tm = JohnsonsSU(dd; xi=0.0, lambda=1.0, gamma=0.0, delta=1.0)
        x = gen_samples(dd, 3000)
        xt = transform(tm, x)
        @test size(xt) == (3000, 2)
        @test !any(isnan, xt)
    end

    @testset "BernoulliCont" begin
        dd = IIDStdUniform(2; seed=92)
        tm = BernoulliCont(dd; lam=0.3)
        x = gen_samples(dd, 3000)
        xt = transform(tm, x)
        @test size(xt) == (3000, 2)
        @test all(0.0 .<= xt .<= 1.0)
        # λ = 0.5 is identity
        tm05 = BernoulliCont(dd; lam=0.5)
        x2 = gen_samples(dd, 100)
        xt2 = transform(tm05, x2)
        @test xt2 ≈ x2 atol=1e-10
    end

    @testset "AcceptanceRejection" begin
        dd = IIDStdUniform(2; seed=7)
        ar = AcceptanceRejection(
            dd;
            pdf_func=x -> exp(-x[1]^2/2) / sqrt(2π),
            proposal_pdf=x -> 1.0,
            M=1.0 / sqrt(2π) + 0.01,
        )
        @test ar isa AcceptanceRejection
    end

    @testset "AcceptanceRejectionReal" begin
        logit(u) = log(u / (1 - u))
        lpdf(z) = exp(-z) / (1 + exp(-z))^2

        dd = DigitalNetB2(2; randomize="none", seed=7)
        tm = AcceptanceRejectionReal(
            dd;
            target_density=z -> lpdf(z[1]),
            inv_cdfs=[logit],
            H_func=z -> lpdf(z[1]),
            upper_bound=1.0,
            density_integral=1.0,
        )
        @test tm isa AcceptanceRejectionReal
        @test tm.dimension == 1
        @test tm.acceptance_rate ≈ 1.0
        x = gen_samples(dd, 64)
        s = transform(tm, x)
        @test size(s, 2) == 1
        @test size(s, 1) == 64
        @test all(isfinite, s)

        tm2 = AcceptanceRejectionReal(
            dd;
            target_density=z -> 0.5 * lpdf(z[1]),
            inv_cdfs=[logit],
            H_func=z -> lpdf(z[1]),
            upper_bound=1.0,
            density_integral=0.5,
        )
        @test tm2.acceptance_rate ≈ 0.5
        s2 = transform(tm2, x)
        @test 0 < size(s2, 1) < 64
        @test all(isfinite, s2)

        @test_throws ArgumentError AcceptanceRejectionReal(
            dd;
            target_density=z -> lpdf(z[1]),
            inv_cdfs=[logit, logit],
            H_func=z -> lpdf(z[1]),
            upper_bound=1.0,
            density_integral=1.0,
        )
        @test_throws ArgumentError AcceptanceRejectionReal(
            dd;
            target_density=z -> lpdf(z[1]),
            inv_cdfs=[logit],
            H_func=z -> lpdf(z[1]),
            upper_bound=-1.0,
            density_integral=1.0,
        )
        @test_throws ArgumentError AcceptanceRejectionReal(
            DigitalNetB2(1; seed=1);
            target_density=z -> lpdf(z[1]),
            inv_cdfs=Function[],
            H_func=z -> lpdf(z[1]),
            upper_bound=1.0,
            density_integral=1.0,
        )
    end

    @testset "DistributionsWrapper" begin
        dd = IIDStdUniform(2; seed=7)
        dw = DistributionsWrapper(
            dd;
            marginals=[Distributions.Normal(0, 1), Distributions.Exponential(1.0)],
        )
        x = gen_samples(dd, 100)
        y = transform(dw, x)
        @test size(y) == (100, 2)
        @test abs(mean(y[:, 1])) < 0.5
    end

    @testset "Open unit interval helper" begin
        @test QMC._open_unit_interval(0.0f0) == eps(Float32)
        @test QMC._open_unit_interval(1.0f0) == 1.0f0 - eps(Float32)
        @test QMC._open_unit_interval(0) == eps(Float64)

        dd = IIDStdUniform(2; seed=101)
        tm = JohnsonsSU(dd)
        x = Float32.(gen_samples(dd, 8))
        y = transform(tm, x)
        @test size(y) == size(x)
        @test all(isfinite, y)
    end
end
