# Top-level helper for the Stage A multi-output interface test. Struct
# definitions must live at top level (not inside a `@testset` block), so the toy
# vector-valued integrand and its `d_indv` override are declared here.
struct _VecOutputToy <: QuasiMC.AbstractIntegrand end
QuasiMC.d_indv(::_VecOutputToy) = (3,)

struct _AltLayoutDD <: QuasiMC.AbstractDiscreteDistribution
    d::Int
    fill_value::Float64
end
QuasiMC.dimension(dd::_AltLayoutDD) = dd.d
QuasiMC.gen_samples(dd::_AltLayoutDD, n::Int; n_start::Int=0) = fill(dd.fill_value, n, dd.d)

struct _AltLayoutTM <: QuasiMC.AbstractTrueMeasure
    sampler::_AltLayoutDD
    shift::Float64
end
QuasiMC.discrete_distribution(tm::_AltLayoutTM) = tm.sampler
QuasiMC.dimension(tm::_AltLayoutTM) = QuasiMC.dimension(tm.sampler)
QuasiMC.transform(tm::_AltLayoutTM, x::AbstractMatrix) = x .+ tm.shift

struct _AltLayoutIntegrand <: QuasiMC.AbstractIntegrand
    measure::_AltLayoutTM
    scale::Float64
end
QuasiMC.true_measure(f::_AltLayoutIntegrand) = f.measure
QuasiMC.dimension(f::_AltLayoutIntegrand) = QuasiMC.dimension(f.measure)
QuasiMC.evaluate(f::_AltLayoutIntegrand, x::AbstractMatrix) = f.scale .* sum(x; dims=2)[:]

@testset "Integrands" begin
    @testset "Accessor-based extensibility" begin
        f = _AltLayoutIntegrand(_AltLayoutTM(_AltLayoutDD(3, 0.25), 0.5), 2.0)
        y = sample_and_evaluate(f, 4)
        @test y == fill(4.5, 4)
        @test QuasiMC.dimension(f) == 3
        @test QuasiMC.discrete_distribution(f) isa _AltLayoutDD
    end

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
        f_osc2 = Genz(Uniform(IIDStdUniform(2)); kind=:oscillatory, a=[1.0, 1.0], u=[0.5, 0.5])
        @test genz_exact(f_osc2) ≈ cos(π + 1.0) * (sin(0.5) / 0.5)^2
        f_cp = Genz(Uniform(IIDStdUniform(2)); kind=:corner_peak, a=[1.0, 1.0], u=[0.5, 0.5])
        @test genz_exact(f_cp) ≈ 1 / 6
        f_cp2 = Genz(Uniform(IIDStdUniform(2)); kind=:corner_peak, a=[0.5, 2.0], u=[0.5, 0.5])
        @test genz_exact(f_cp2) ≈ 1 / 7

        f_pp = Genz(Uniform(IIDStdUniform(2)); kind=:product_peak, a=[1.0, 1.0], u=[0.5, 0.5])
        @test genz_exact(f_pp) ≈ 0.8598764213 atol = 1e-9
        f_gp = Genz(Uniform(IIDStdUniform(2)); kind=:gaussian_peak, a=[1.0, 1.0], u=[0.5, 0.5])
        @test genz_exact(f_gp) ≈ 0.8511206675 atol = 1e-9
        f_dc = Genz(Uniform(IIDStdUniform(2)); kind=:discontinuous, a=[1.0, 1.0], u=[0.5, 0.5])
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

        # Closed-form analytical reference values (validated vs pick-freeze MC).
        ref = ishigami_exact(a=7.0, b=0.1)
        @test ref.mean == 3.5
        @test ref.variance ≈ 13.844588 atol = 1e-3
        @test ref.closed ≈ [0.31391, 0.44241, 0.0] atol = 1e-3
        @test ref.total ≈ [0.55759, 0.44241, 0.24368] atol = 1e-3
        # structural: 0 ≤ Sᵢ ≤ Tᵢ ≤ 1, x₃ has no main effect, x₂ has no interactions
        @test all(0.0 .<= ref.closed .<= ref.total .<= 1.0)
        @test ref.closed[3] == 0.0
        @test ref.closed[2] ≈ ref.total[2]
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

        fo_asian =
            FinancialOption(tm; option_type=:asian, strike_price=100.0, asian_mean=:geometric)
        ev_asian = get_exact_value(fo_asian)
        @test ev_asian > 0.0

        # Digital (cash-or-nothing) European option: discounted P(ITM at T).
        S0, K, r, sigma, T = 100.0, 100.0, 0.05, 0.2, 1.0
        d2 = (log(S0 / K) + (r - sigma^2 / 2) * T) / (sigma * sqrt(T))
        nd = Distributions.Normal()
        fo_dig_c = FinancialOption(tm; option_type=:digital, call_put=:call, strike_price=100.0)
        fo_dig_p = FinancialOption(tm; option_type=:digital, call_put=:put, strike_price=100.0)
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
        ddc = IIDStdUniform(6; seed=42)
        tmc = Uniform(ddc; lower_bound=(-π), upper_bound=π)
        sic = SensitivityIndices(Ishigami(tmc))
        xc = transform(tmc, gen_samples(ddc, 2^16))
        closed, total = compute_sensitivity_indices(sic, xc)
        ref = ishigami_exact()
        @test all(abs.(closed .- ref.closed) .<= 0.06)
        @test all(abs.(total .- ref.total) .<= 0.06)

        # indices=:all enumerates every non-trivial subset (2^d - 2 = 6 for d=3).
        # Re-use the same 6D tm pattern from the existing test above so evaluate
        # receives a 200×6 matrix (cols 1:3 = X, cols 4:6 = Z pick-freeze pairs).
        dd_all = IIDStdUniform(6; seed=11)
        tm_all = Uniform(dd_all; lower_bound=(-π), upper_bound=π)
        si_all = SensitivityIndices(Ishigami(tm_all); indices=:all)
        @test size(si_all.indices, 1) == (1 << 3) - 2   # 6 subsets for d=3
        @test size(si_all.indices, 2) == 3
        y_all = evaluate(si_all, transform(tm_all, gen_samples(dd_all, 200)))
        @test size(y_all) == (200, 3, 6)  # (n, 3 estimator terms, k subsets)

        # indices=Matrix{Bool}: pass a custom 2×3 subset matrix.
        idx = Bool[1 0 0; 1 1 0]   # subsets {x1} and {x1, x2}
        dd_mb = IIDStdUniform(6; seed=12)
        tm_mb = Uniform(dd_mb; lower_bound=(-π), upper_bound=π)
        si_mb = SensitivityIndices(Ishigami(tm_mb); indices=idx)
        @test size(si_mb.indices) == (2, 3)
        y_mb = evaluate(si_mb, transform(tm_mb, gen_samples(dd_mb, 100)))
        @test size(y_mb) == (100, 3, 2)  # (n, 3 estimator terms, 2 subsets)

        # Wrong column count for Matrix{Bool} indices.
        @test_throws ArgumentError SensitivityIndices(base; indices=Bool[1 0; 0 1])

        # Completely unknown indices symbol.
        @test_throws ArgumentError SensitivityIndices(base; indices=:unknown)
    end

    @testset "BayesianLRCoeffs" begin
        features = randn(50, 3)
        response = rand(0:1, 50)
        dd = IIDStdUniform(3; seed=7)
        tm = Gaussian(dd)
        blr = BayesianLRCoeffs(tm; feature_array=features, response_vector=Float64.(response))
        x = transform(tm, gen_samples(dd, 100))
        y = evaluate(blr, x)
        @test length(y) == 100
    end

    @testset "Sin1D" begin
        dd = DigitalNetB2(1; seed=7)
        tm = Uniform(dd; lower_bound=0.0, upper_bound=2π)
        f = Sin1D(tm)
        @test f.dimension == 1
        @test f.k == 1
        @test repr(f) == "Sin1D(k=1)"

        # Exact integral of sin over [0, 2πk] is 0 for integer k.
        y = sample_and_evaluate(f, 2^10)
        @test length(y) == 2^10
        @test !any(isnan, y)
        @test abs(mean(y)) < 1e-14

        # k=2: integral over [0, 4π] is also 0.
        tm2 = Uniform(DigitalNetB2(1; seed=8); lower_bound=0.0, upper_bound=4π)
        f2 = Sin1D(tm2; k=2)
        @test f2.k == 2
        y2 = sample_and_evaluate(f2, 2^10)
        @test abs(mean(y2)) < 1e-14

        # Deterministic: evaluate at known points.
        x_pts = [0.0 π/2; π/2 π; π 3π/2]
        v = evaluate(f, x_pts)
        @test v ≈ [sin(0.0), sin(π/2), sin(π)] atol=1e-14

        # Argument errors.
        @test_throws ArgumentError Sin1D(Uniform(IIDStdUniform(2)))  # requires d=1
        @test_throws ArgumentError Sin1D(tm; k=0)
    end

    @testset "Multi-output interface (Stage A)" begin
        dd = IIDStdUniform(2; seed=11)
        tm = Uniform(dd)
        f = CustomFun(tm, x -> sum(x; dims=2)[:])
        # Scalar integrands get scalar/identity defaults (no behavior change).
        @test QuasiMC.d_indv(f) == ()
        @test QuasiMC.d_comb(f) == ()
        @test QuasiMC.combine_fun(f, 3.0) === 3.0
        @test QuasiMC.bound_fun(f, -1.0, 2.0) == (-1.0, 2.0)
        @test QuasiMC.dependency(f, [true, false]) == [true, false]
        @test QuasiMC.d_indv(Keister(Gaussian(dd; covariance=0.5))) == ()
        @test QuasiMC.d_indv(Ishigami(Uniform(IIDStdUniform(3)))) == ()

        # A vector-valued integrand can override d_indv; d_comb then defaults to
        # it (identity combine) and the bound map stays identity until specialized.
        toy = _VecOutputToy()
        @test QuasiMC.d_indv(toy) == (3,)
        @test QuasiMC.d_comb(toy) == (3,)
        lo, hi = [0.0, 0.0, 0.0], [1.0, 1.0, 1.0]
        @test QuasiMC.bound_fun(toy, lo, hi) == (lo, hi)
        @test QuasiMC.dependency(toy, [true, false, true]) == [true, false, true]
    end

    @testset "CustomFun (matrix output + replicated sampler)" begin
        dd = IIDStdUniform(2; seed=12)
        tm = Uniform(dd)
        # g returns a matrix — evaluate must vec() it (line 51 in custom_fun.jl)
        f_mat = CustomFun(tm, x -> reshape(sum(x; dims=2), size(x, 1), 1))
        y_mat = sample_and_evaluate(f_mat, 100)
        @test length(y_mat) == 100
        @test all(isfinite, y_mat)

        # _sample_uniform_points with a replicated DD flattens R×n×d → R*n × d
        dd_rep = DigitalNetB2(2; randomize="DS", seed=13, replications=2)
        tm_rep = Uniform(dd_rep)
        f_rep = CustomFun(tm_rep, x -> sum(x; dims=2)[:])
        y_rep = sample_and_evaluate(f_rep, 8)
        @test length(y_rep) == 16  # 2 reps × 8 points
        @test all(isfinite, y_rep)
    end

    @testset "Genz exact value (zero a[j] branches)" begin
        # When a[j] ≈ 0 the exact-value formulas take special branches:
        # gaussian_peak: continue (line 224), continuous: val *= 1 (line 236),
        # discontinuous: val *= u[j] (line 249).
        dd = IIDStdUniform(2; seed=14)
        tm = Uniform(dd)
        f_gp = Genz(tm; kind=:gaussian_peak, a=[0.0, 1.0], u=[0.5, 0.5])
        ev_gp = genz_exact(f_gp)
        @test isfinite(ev_gp) && ev_gp > 0

        f_cont = Genz(tm; kind=:continuous, a=[0.0, 1.0], u=[0.5, 0.5])
        ev_cont = genz_exact(f_cont)
        @test isfinite(ev_cont) && ev_cont > 0

        f_disc = Genz(tm; kind=:discontinuous, a=[0.0, 1.0], u=[0.5, 0.5])
        ev_disc = genz_exact(f_disc)
        @test isfinite(ev_disc) && ev_disc > 0
    end

    @testset "AsianOption (geometric-mean evaluate)" begin
        # Covers lines 106-113 in asian_option.jl (geometric path of evaluate).
        dd = IIDStdUniform(8; seed=15)
        tm = BrownianMotion(dd)
        ao_geo = AsianOption(
            tm;
            mean_type=:geometric,
            volatility=0.2,
            start_price=100.0,
            strike_price=100.0,
            interest_rate=0.05,
        )
        y_geo = sample_and_evaluate(ao_geo, 500)
        @test all(y_geo .>= 0.0)
        @test mean(y_geo) > 0

        # Put variant via AsianOption
        ao_put = AsianOption(
            tm;
            call_put=:put,
            volatility=0.2,
            start_price=100.0,
            strike_price=100.0,
            interest_rate=0.05,
        )
        y_put = sample_and_evaluate(ao_put, 300)
        @test all(y_put .>= 0.0)
    end

    @testset "BayesianLRCoeffs (bias term + extreme eta)" begin
        # d = n_features + 1 triggers offset=1 (bias intercept), line 82.
        # Large feature values make eta > 20 or < -20, covering lines 88 and 90.
        features_extreme = vcat(100 .* ones(25, 3), -100 .* ones(25, 3))
        response = vcat(ones(Int, 25), zeros(Int, 25))
        dd_bias = IIDStdUniform(4; seed=16)  # d=4 = n_features(3) + 1 → bias offset
        tm_bias = Gaussian(dd_bias)
        blr_bias = BayesianLRCoeffs(
            tm_bias;
            feature_array=features_extreme,
            response_vector=Float64.(response),
        )
        x_bias = transform(tm_bias, gen_samples(dd_bias, 20))
        y_bias = evaluate(blr_bias, x_bias)
        @test length(y_bias) == 20
        @test all(isfinite, y_bias)
    end

    @testset "FinancialOption (non-GBM coverage)" begin
        dd_bm = IIDStdUniform(4; seed=403)
        tm_bm = BrownianMotion(dd_bm)

        # Constructor: conflicting mean_type and asian_mean (line 99)
        @test_throws ArgumentError FinancialOption(
            tm_bm;
            option_type=:asian,
            mean_type=:arithmetic,
            asian_mean=:geometric,
        )

        # Geometric asian mean, non-GBM path → _payoff line 182
        f_ag = FinancialOption(
            tm_bm;
            option_type=:asian,
            mean_type=:geometric,
            volatility=0.2,
            start_price=100.0,
            strike_price=100.0,
        )
        y_ag = sample_and_evaluate(f_ag, 300)
        @test all(y_ag .>= 0.0)

        # Lookback put, non-GBM → _payoff line 189
        f_lp = FinancialOption(
            tm_bm;
            option_type=:lookback,
            call_put=:put,
            volatility=0.2,
            start_price=100.0,
            strike_price=90.0,
        )
        y_lp = sample_and_evaluate(f_lp, 300)
        @test all(y_lp .>= 0.0)

        # Barrier up-barrier :in, non-GBM → _barrier_payoff lines 203-223 (up branch line 211)
        f_bin = FinancialOption(
            tm_bm;
            option_type=:barrier,
            barrier_price=120.0,
            barrier_in_out=:in,
            volatility=0.2,
            start_price=100.0,
            strike_price=100.0,
        )
        y_bin = sample_and_evaluate(f_bin, 300)
        @test all(y_bin .>= 0.0)

        # Barrier down-barrier :out, non-GBM → _barrier_payoff down branch line 213
        f_bout = FinancialOption(
            tm_bm;
            option_type=:barrier,
            barrier_price=80.0,
            barrier_in_out=:out,
            volatility=0.2,
            start_price=100.0,
            strike_price=100.0,
        )
        y_bout = sample_and_evaluate(f_bout, 300)
        @test all(y_bout .>= 0.0)
    end

    @testset "FinancialOption (GBM fast-path coverage)" begin
        dd_g = IIDStdUniform(16; seed=404)
        tm_g = GeometricBrownianMotion(
            dd_g;
            volatility=0.2,
            start_price=100.0,
            interest_rate=0.05,
            t_final=1.0,
        )
        x_g = transform(tm_g, gen_samples(dd_g, 200))

        # European put GBM fast path (line 240)
        f_ep = FinancialOption(tm_g; option_type=:european, call_put=:put, strike_price=100.0)
        y_ep = evaluate(f_ep, x_g)
        @test all(y_ep .>= 0.0)

        # Asian arithmetic put GBM fast path (lines 251-272 put branch)
        f_ap = FinancialOption(
            tm_g;
            option_type=:asian,
            call_put=:put,
            mean_type=:arithmetic,
            strike_price=100.0,
        )
        y_ap = evaluate(f_ap, x_g)
        @test all(y_ap .>= 0.0)

        # Asian geometric call GBM fast path (lines 262-270)
        f_agc = FinancialOption(
            tm_g;
            option_type=:asian,
            call_put=:call,
            mean_type=:geometric,
            strike_price=100.0,
        )
        y_agc = evaluate(f_agc, x_g)
        @test all(y_agc .>= 0.0)

        # Asian geometric put GBM fast path (lines 262-272)
        f_agp = FinancialOption(
            tm_g;
            option_type=:asian,
            call_put=:put,
            mean_type=:geometric,
            strike_price=100.0,
        )
        y_agp = evaluate(f_agp, x_g)
        @test all(y_agp .>= 0.0)

        # Digital put GBM fast path (lines 279-285)
        f_dp = FinancialOption(tm_g; option_type=:digital, call_put=:put, strike_price=100.0)
        y_dp = evaluate(f_dp, x_g)
        @test all(0.0 .<= y_dp .<= 1.0)

        # Lookback call GBM fast path (lines 292-301)
        f_lbc = FinancialOption(tm_g; option_type=:lookback, call_put=:call, strike_price=90.0)
        y_lbc = evaluate(f_lbc, x_g)
        @test all(y_lbc .>= 0.0)

        # Lookback put GBM fast path (lines 303-309)
        f_lbp = FinancialOption(tm_g; option_type=:lookback, call_put=:put, strike_price=110.0)
        y_lbp = evaluate(f_lbp, x_g)
        @test all(y_lbp .>= 0.0)

        # Barrier down-barrier (start_price > barrier_price) GBM fast path (lines 328-332)
        dd_gd = IIDStdUniform(16; seed=405)
        tm_gd = GeometricBrownianMotion(
            dd_gd;
            volatility=0.2,
            start_price=100.0,
            interest_rate=0.05,
            t_final=1.0,
        )
        x_gd = transform(tm_gd, gen_samples(dd_gd, 200))
        f_bdown = FinancialOption(
            tm_gd;
            option_type=:barrier,
            barrier_price=80.0,
            barrier_in_out=:in,
            call_put=:call,
            strike_price=100.0,
        )
        y_bdown = evaluate(f_bdown, x_gd)
        @test all(y_bdown .>= 0.0)

        # Barrier put GBM fast path (line 338)
        f_bput = FinancialOption(
            tm_g;
            option_type=:barrier,
            barrier_price=120.0,
            barrier_in_out=:out,
            call_put=:put,
            strike_price=100.0,
        )
        y_bput = evaluate(f_bput, x_g)
        @test all(y_bput .>= 0.0)

        # exact_value error for unsupported option types (line 428)
        @test_throws ErrorException get_exact_value(
            FinancialOption(
                tm_g;
                option_type=:barrier,
                barrier_price=120.0,
                strike_price=100.0,
            ),
        )
        @test_throws ErrorException get_exact_value(
            FinancialOption(tm_g; option_type=:lookback, strike_price=100.0),
        )
    end

    @testset "FinancialOptionML (BrownianMotion + generic path + option types)" begin
        # BrownianMotion path in _coupled_stock_paths (lines 207-215)
        dd_bm = IIDStdUniform(8; seed=406)
        tm_bm = BrownianMotion(dd_bm)
        fml_bm = FinancialOptionML(tm_bm; d_coarsest=4)
        x_bm = transform(tm_bm, gen_samples(dd_bm, 20))
        Qc0, Qf0 = ml_evaluate(fml_bm, x_bm, 0)  # level=0 → lines 207-211
        @test length(Qf0) == 20
        @test all(iszero, Qc0)
        Qc1, Qf1 = ml_evaluate(fml_bm, x_bm, 1)  # level=1 → lines 207-215
        @test length(Qf1) == 20
        @test !any(isnan, Qf1)

        # Generic fallback path (lines 218-229): FinancialOptionML(dd) → Gaussian TM
        dd_g = IIDStdUniform(8; seed=407)
        fml_g = FinancialOptionML(dd_g; d_coarsest=4)
        x_g = transform(fml_g.true_measure, gen_samples(dd_g, 20))
        Qc0g, Qf0g = ml_evaluate(fml_g, x_g, 0)  # level=0 → lines 218-220
        @test length(Qf0g) == 20
        Qc1g, Qf1g = ml_evaluate(fml_g, x_g, 1)  # level=1 → lines 218-229
        @test length(Qf1g) == 20
        @test !any(isnan, Qf1g)

        # _ml_payoff variants: european put (241), geometric asian (246),
        # asian put (249), lookback call/put (250-253), digital call/put (255-258)
        dd_opt = IIDStdUniform(8; seed=408)
        tm_opt = BrownianMotion(dd_opt)
        x_opt = transform(tm_opt, gen_samples(dd_opt, 20))
        for (opt, cp, mt) in [
            (:european, :put, :arithmetic),
            (:asian, :call, :geometric),
            (:asian, :put, :arithmetic),
            (:lookback, :call, :arithmetic),
            (:lookback, :put, :arithmetic),
            (:digital, :call, :arithmetic),
            (:digital, :put, :arithmetic),
        ]
            fml_t = FinancialOptionML(
                tm_opt;
                d_coarsest=4,
                option_type=opt,
                mean_type=mt,
                call_put=cp,
                start_price=30.0,
                strike_price=25.0,
            )
            _, Qf = ml_evaluate(fml_t, x_opt, 0)
            @test length(Qf) == 20
            @test !any(isnan, Qf)
        end
    end
end
