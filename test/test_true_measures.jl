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

    @testset "Replicated transforms" begin
        ddg = DigitalNetB2(3; seed=7, replications=2)
        tmg = Gaussian(ddg; mean=0.0, covariance=3.0)
        xg = gen_samples(ddg, 4)
        yg = transform(tmg, xg)
        @test size(yg) == (2, 4, 3)
        @test @view(yg[1, :, :]) ≈ transform(tmg, @view xg[1, :, :])
        @test @view(yg[2, :, :]) ≈ transform(tmg, @view xg[2, :, :])

        ddz = DigitalNetB2(2; randomize="none", seed=8, replications=2)
        tmz = ZeroInflatedExpUniform(ddz; p_zero=0.3, rate=2.0)
        xz = gen_samples(ddz, 6)
        yz = transform(tmz, xz)
        @test size(yz) == (2, 6, 1)
        @test @view(yz[1, :, :]) ≈ transform(tmz, @view xz[1, :, :])
        @test @view(yz[2, :, :]) ≈ transform(tmz, @view xz[2, :, :])

        ddar = DigitalNetB2(3; randomize="none", seed=7, replications=2)
        tmar =
            AcceptanceRejection(ddar; pdf_func=x -> 6.0 * x[1] * x[2], envelope_multiplier=6.0)
        xar = gen_samples(ddar, 16)
        yar = transform(tmar, xar)
        @test yar isa Vector{Matrix{Float64}}
        @test length(yar) == 2
        @test yar[1] == transform(tmar, @view xar[1, :, :])
        @test yar[2] == transform(tmar, @view xar[2, :, :])

        logit(u) = log(u / (1 - u))
        lpdf(z) = exp(-z) / (1 + exp(-z))^2
        ddarr = DigitalNetB2(2; randomize="none", seed=7, replications=2)
        tmarr = AcceptanceRejectionReal(
            ddarr;
            target_density=z -> 0.5 * lpdf(z[1]),
            inv_cdfs=[logit],
            H_func=z -> lpdf(z[1]),
            upper_bound=1.0,
            density_integral=0.5,
        )
        xarr = gen_samples(ddarr, 16)
        yarr = transform(tmarr, xarr)
        @test yarr isa Vector{Matrix{Float64}}
        @test length(yarr) == 2
        @test yarr[1] == transform(tmarr, @view xarr[1, :, :])
        @test yarr[2] == transform(tmarr, @view xarr[2, :, :])
    end

    @testset "BrownianMotion" begin
        dd = IIDStdUniform(4; seed=40)
        tm = BrownianMotion(dd)
        x = gen_samples(dd, 2000)
        xt = transform(tm, x)
        @test size(xt) == (2000, 4)
        @test abs(mean(xt[:, end])) < 0.1
        @test abs(var(xt[:, end]) - 1.0) < 0.3

        # t_final sets the grid [T/d, …, T] (QMCPy convention)
        @test BrownianMotion(IIDStdUniform(4); t_final=2.0).time_vector ≈ [0.5, 1.0, 1.5, 2.0]
        # default call is unchanged (t_final = 1)
        @test BrownianMotion(IIDStdUniform(4)).time_vector ≈ [0.25, 0.5, 0.75, 1.0]
        @test_throws ArgumentError BrownianMotion(
            IIDStdUniform(4);
            time_vector=[0.5, 1, 1.5, 2],
            t_final=2.0,
        )
        @test_throws ArgumentError BrownianMotion(IIDStdUniform(4); diffusion=0.0)

        # initial_value + drift·t mean, diffusion·min(tᵢ,tⱼ) covariance (QMCPy semantics)
        dd2 = DigitalNetB2(4; seed=1)
        bm = BrownianMotion(dd2; t_final=2.0, initial_value=3.0, drift=1.0, diffusion=4.0)
        paths = transform(bm, gen_samples(dd2, 2^14))
        tv = [0.5, 1.0, 1.5, 2.0]
        @test maximum(abs.(vec(mean(paths; dims=1)) .- (3.0 .+ 1.0 .* tv))) < 0.1
        @test abs(var(paths[:, end]) - 4.0 * 2.0) < 0.8      # diffusion · t_final = 8
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

    @testset "StudentT df=2 closed form" begin
        dd = DigitalNetB2(2; randomize="none", seed=71)
        x = gen_samples(dd, 16)

        tm_std = StudentT(dd)
        xt_std = transform(tm_std, x)
        expected_std = Matrix{Float64}(undef, size(x))
        @inbounds for j in axes(x, 2), i in axes(x, 1)
            p = QMC._open_unit_interval(x[i, j])
            expected_std[i, j] = (2.0 * p - 1.0) / sqrt(2.0 * p * (1.0 - p))
        end
        @test xt_std ≈ expected_std

        loc = [1.0, -2.0]
        scale = [0.5, 2.0]
        tm_affine = StudentT(dd; df=2.0, loc=loc, scale=scale)
        xt_affine = transform(tm_affine, x)
        @test xt_affine ≈ expected_std .* transpose(scale) .+ transpose(loc)
    end

    @testset "StudentT df=1 closed form" begin
        dd = DigitalNetB2(2; randomize="none", seed=72)
        x = gen_samples(dd, 16)

        tm_std = StudentT(dd; df=1.0)
        xt_std = transform(tm_std, x)
        expected_std = Matrix{Float64}(undef, size(x))
        @inbounds for j in axes(x, 2), i in axes(x, 1)
            expected_std[i, j] = tanpi(QMC._open_unit_interval(x[i, j]) - 0.5)
        end
        @test xt_std ≈ expected_std

        loc = [0.25, -1.5]
        scale = [1.5, 0.25]
        tm_affine = StudentT(dd; df=1.0, loc=loc, scale=scale)
        xt_affine = transform(tm_affine, x)
        @test xt_affine ≈ expected_std .* transpose(scale) .+ transpose(loc)
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

    @testset "Kumaraswamy/JohnsonsSU defaults match QMCPy" begin
        # Default-constructed measures must reproduce QMCPy's defaults exactly
        # (oracle values computed from qmcpy==2.3 on the same uniforms).
        u = [0.1 0.3; 0.5 0.7; 0.9 0.25]
        dd = IIDStdUniform(2; seed=1)

        km = Kumaraswamy(dd)                       # QMCPy: a=2, b=2
        @test km.alpha == [2.0, 2.0]
        @test km.beta == [2.0, 2.0]
        @test transform(km, u) ≈ [
            0.226532 0.404153
            0.541196 0.672516
            0.826905 0.366025
        ] atol = 1e-5

        js = JohnsonsSU(dd)                        # QMCPy: gamma=1, xi=1, delta=2, lam=2
        @test js.xi == [1.0, 1.0]
        @test js.lambda == [2.0, 2.0]
        @test js.gamma == [1.0, 1.0]
        @test js.delta == [2.0, 2.0]
        @test transform(js, u) ≈ [
            -1.809624 -0.676348
            -0.042191 0.519905
            1.282482 -0.877092
        ] atol = 1e-5
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

        u = [0.25 0.50; 0.75 0.25]
        tm_vec = BernoulliCont(dd; lam=[0.25, 0.75])
        expected = [
            log1p(-2 / 3 * 0.25) / log(1 / 3) log1p(2 * 0.50) / log(3)
            log1p(-2 / 3 * 0.75) / log(1 / 3) log1p(2 * 0.25) / log(3)
        ]
        @test transform(tm_vec, u) ≈ expected atol=1e-14

        dd_mean = DigitalNetB2(1; seed=7, graycode=false)
        lam = 0.75
        tm_mean = BernoulliCont(dd_mean; lam=lam)
        sample_mean = mean(transform(tm_mean, gen_samples(dd_mean, 2^18)))
        exact_mean = lam / (2lam - 1) + 1 / (2atanh(1 - 2lam))
        @test sample_mean ≈ exact_mean atol=1e-5
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

    @testset "MaternGP" begin
        dd = IIDStdUniform(5; seed=7)
        tm = MaternGP(dd; nu=2.5, lengthscale=0.3)
        x = gen_samples(dd, 100)
        y = transform(tm, x)
        @test size(y) == (100, 5)
        @test all(isfinite, y)
        # GP sample paths have zero mean (approximately) over many draws.
        @test abs(mean(y)) < 1.0

        # ν = 0.5 (exponential covariance).
        tm05 = MaternGP(IIDStdUniform(4; seed=1); nu=0.5, lengthscale=1.0)
        y05 = transform(tm05, gen_samples(tm05.dd, 50))
        @test size(y05) == (50, 4)
        @test all(isfinite, y05)

        # ν = 1.5.
        tm15 = MaternGP(IIDStdUniform(4; seed=2); nu=1.5, lengthscale=0.5)
        y15 = transform(tm15, gen_samples(tm15.dd, 50))
        @test all(isfinite, y15)

        # show method.
        @test repr(tm) == "MaternGP(ν=2.5, ℓ=0.3, σ²=1.0)"

        # Argument errors.
        @test_throws ArgumentError MaternGP(dd; nu=-1.0)
        @test_throws ArgumentError MaternGP(dd; lengthscale=0.0)
        @test_throws ArgumentError MaternGP(dd; variance=-1.0)
    end

    @testset "UniformTriangle" begin
        dd = IIDStdUniform(2; seed=7)
        tm = UniformTriangle(dd)
        x = gen_samples(dd, 1000)
        y = transform(tm, x)
        @test size(y) == (1000, 2)
        # Output lies in the triangle: 0 ≤ y2 ≤ y1 ≤ 1.
        @test all(0.0 .<= y[:, 2] .<= y[:, 1] .<= 1.0)
        # Mean of uniform on {y2 ≤ y1}: E[y1] = 2/3, E[y2] = 1/3.
        @test abs(mean(y[:, 1]) - 2/3) < 0.05
        @test abs(mean(y[:, 2]) - 1/3) < 0.05

        # Deterministic check using docstring example values.
        u = [0.601137 0.553600; 0.943441 0.631885; 0.717708 0.099473; 0.357784 0.240963]
        y_det = transform(tm, u)
        @test y_det[:, 1] ≈ max.(u[:, 1], u[:, 2]) atol=1e-6
        @test y_det[:, 2] ≈ min.(u[:, 1], u[:, 2]) atol=1e-6

        @test repr(tm) == "UniformTriangle()"
        @test_throws ArgumentError UniformTriangle(IIDStdUniform(3))
    end

    @testset "ZeroInflatedExpUniform" begin
        dd = IIDStdUniform(2; seed=7)
        tm = ZeroInflatedExpUniform(dd; p_zero=0.3, rate=2.0)
        @test QMC.dimension(tm) == 1

        x = gen_samples(dd, 5000)
        y = transform(tm, x)
        @test size(y) == (5000, 1)
        @test all(y .>= 0.0)
        # Fraction of zeros ≈ p_zero = 0.3.
        @test abs(mean(y .== 0.0) - 0.3) < 0.05

        # Non-zero values: half exponential (rate=2), half Uniform(0,1).
        # Mean of Exp(2) = 0.5, mean of U(0,1) = 0.5 ⇒ non-zero mean ≈ 0.5.
        nonzero = y[y .!= 0.0]
        @test abs(mean(nonzero) - 0.5) < 0.1

        # Default parameters (p_zero=0.3, rate=1.0).
        tm_def = ZeroInflatedExpUniform(IIDStdUniform(2; seed=1))
        @test tm_def.p_zero == 0.3
        @test tm_def.rate == 1.0

        # show method.
        @test repr(tm) == "ZeroInflatedExpUniform(p_zero=0.30, rate=2.00)"

        # Argument errors.
        @test_throws ArgumentError ZeroInflatedExpUniform(IIDStdUniform(3))
        @test_throws ArgumentError ZeroInflatedExpUniform(dd; p_zero=-0.1)
        @test_throws ArgumentError ZeroInflatedExpUniform(dd; rate=0.0)
        @test_throws ArgumentError ZeroInflatedExpUniform(dd; low=1.0, high=0.0)
    end

    @testset "BrownianMotion time_vector parameter" begin
        dd = IIDStdUniform(4; seed=201)
        tv = [0.25, 0.5, 0.75, 1.0]
        tm = BrownianMotion(dd; time_vector=tv)
        x = gen_samples(dd, 10)
        y = transform(tm, x)
        @test size(y) == (10, 4)
        @test all(isfinite, y)
        @test_throws ArgumentError BrownianMotion(dd; time_vector=tv, t_final=1.0)
        @test_throws ArgumentError BrownianMotion(dd; time_vector=[0.5, 1.0])
        @test_throws ArgumentError BrownianMotion(dd; time_vector=[0.5, 0.5, 0.75, 1.0])
        @test_throws ArgumentError BrownianMotion(dd; time_vector=[-0.1, 0.25, 0.5, 1.0])
    end

    @testset "Gaussian vector and matrix covariance" begin
        dd = IIDStdUniform(3; seed=202)
        tm_vec = Gaussian(dd; covariance=[1.0, 2.0, 3.0])
        x = gen_samples(dd, 20)
        y_vec = transform(tm_vec, x)
        @test size(y_vec) == (20, 3)
        @test all(isfinite, y_vec)
        Σ = [2.0 1.0 0.5; 1.0 2.0 0.5; 0.5 0.5 2.0]
        tm_mat = Gaussian(dd; covariance=Σ)
        y_mat = transform(tm_mat, x)
        @test size(y_mat) == (20, 3)
        @test all(isfinite, y_mat)
        tm_nd = Gaussian(IIDStdUniform(2; seed=203); covariance=[1.0 0.5; 0.5 1.0])
        z = randn(10, 2)
        yr = QMC._transform_from_randn(tm_nd, z)
        @test size(yr) == (10, 2)
        @test all(isfinite, yr)
    end

    @testset "GeometricBrownianMotion constructor error branches" begin
        dd = IIDStdUniform(4; seed=204)
        @test_throws ArgumentError GeometricBrownianMotion(
            dd;
            initial_value=100.0,
            start_price=50.0,
            t_final=1.0,
        )
        @test_throws ArgumentError GeometricBrownianMotion(
            dd;
            drift=0.1,
            interest_rate=0.05,
            t_final=1.0,
        )
        @test_throws ArgumentError GeometricBrownianMotion(dd; volatility=-0.2, t_final=1.0)
        @test_throws ArgumentError GeometricBrownianMotion(
            dd;
            diffusion=0.5,
            volatility=0.2,
            t_final=1.0,
        )
    end

    @testset "Non-Standard Gaussian covariance (regression: shared-dd cross/star artifact)" begin
        # DigitalNetB2 is a stateful mutable struct: every gen_samples call advances the
        # internal MersenneTwister rng (LMS scramble + digital shift). Sharing one
        # DigitalNetB2 instance across multiple true measures means each measure's
        # gen_samples call sees a different scramble. The 2nd and 3rd calls on seed=7
        # with default t produce degenerate [0,1]^2 sequences (arc/ring and cross/star)
        # that look wrong after erfinv. Each true measure must use its own fresh
        # DigitalNetB2 with t=63 for high-quality LMS scrambling (matching the
        # scatter-plot convention used elsewhere in the demo notebooks).
        n = 2^12
        Σ = [5.0 4.0; 4.0 9.0]
        μ = [1.0, 2.0]

        # Correct: fresh dd with t=63 → first gen_samples call → good scramble
        tm_ok = Gaussian(DigitalNetB2(2; seed=9, t=63); mean=μ, covariance=Σ)
        t_ok = transform(tm_ok, gen_samples(tm_ok.dd, n))
        @test abs(mean(t_ok[:, 1]) - μ[1]) < 0.1
        @test abs(mean(t_ok[:, 2]) - μ[2]) < 0.1
        @test abs(cov(t_ok)[1, 1] - Σ[1, 1]) < 2.0
        @test abs(cov(t_ok)[2, 2] - Σ[2, 2]) < 2.0
        @test abs(cov(t_ok)[1, 2] - Σ[1, 2]) < 1.5  # off-diagonal ≈ 4.0; bug gives ≈ 0

        # Bug: shared dd → 3rd gen_samples call → degenerate scramble → cross/star artifact
        dd_shared = DigitalNetB2(2; seed=7)
        tm1 = Uniform(dd_shared; lower_bound=[-3.0, -2.0], upper_bound=[3.0, 2.0])
        tm2 = Gaussian(dd_shared)
        tm3 = Gaussian(dd_shared; mean=μ, covariance=Σ)
        gen_samples(tm1.dd, n)   # 1st advance — tm1 gets scramble S1
        gen_samples(tm2.dd, n)   # 2nd advance — tm2 gets scramble S2
        t_bug = transform(tm3, gen_samples(tm3.dd, n))  # 3rd advance — S3 is degenerate
        @test abs(cov(t_bug)[1, 2] - Σ[1, 2]) > abs(cov(t_ok)[1, 2] - Σ[1, 2])
    end
end
