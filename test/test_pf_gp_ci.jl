# Tests for PFGPCI (probability-of-failure via adaptive GP credible intervals).
#
# The deterministic core (φ, error density, credible-interval arithmetic, the
# affine failure transform) is validated against values computed from QMCPy's
# exact formulas and runs without any GP backend. The end-to-end test runs only
# when the AbstractGPs/Optim backend extension is loaded; because GP
# hyperparameters are fit numerically, it asserts *statistical* agreement with a
# QMC reference probability of failure (loose tolerance), not bit-parity.
#
# AbstractGPs/Optim are weak (extension-trigger) dependencies, so they are absent
# from the default test environment: this preamble loads them if present (which
# auto-triggers the QMCAbstractGPsExt extension) and otherwise exercises the
# "backend not loaded" error path, keeping the suite green either way.
const _PFGPCI_HAS_BACKEND = try
    @eval using AbstractGPs
    @eval using Optim
    true
catch
    false
end

@testset "PFGPCI" begin
    @testset "deterministic helpers" begin
        # φ(x) = Φ(μ/σ); reference from scipy.stats.norm.cdf
        phi = QMC._pfgpci_phi([-2.0, -0.5, 0.0, 0.5, 2.0], ones(5))
        @test isapprox(phi, [0.02275, 0.308538, 0.5, 0.691462, 0.97725]; atol=1e-5)
        # error / acquisition density 2·min(φ, 1-φ)
        @test isapprox(
            QMC._pfgpci_error_udens(phi),
            [0.0455, 0.617075, 1.0, 0.617075, 0.0455];
            atol=1e-5,
        )
        # σ = 0 guard: pinned to the failure side (μ≥0 ⇒ 1) or safe side (⇒ 0)
        @test QMC._pfgpci_phi([1.0, -1.0, 0.0], zeros(3)) == [1.0, 0.0, 1.0]

        # credible-interval arithmetic (QMCPy PFGPCIData.update_data)
        phi2 = [0.01, 0.2, 0.5, 0.49, 0.8, 0.99, 0.999]
        sol, emr, lo, hi, eb = QMC._pfgpci_credible_interval(phi2, 0.05)
        @test isapprox(sol, 4 / 7; atol=1e-12)          # mean(φ ≥ 0.5)
        @test isapprox(emr, 0.201571; atol=1e-5)        # mean(min(φ,1-φ))
        @test lo == 0.0 && hi == 1.0                    # γ = emr/α clamps to [0,1]
        @test isapprox(eb, 4 / 7; atol=1e-12)           # max(sol-lo, hi-sol)

        # a tight (low-emr) φ gives a narrow, unclamped interval centered on sol
        phi3 = vcat(fill(0.999, 50), fill(0.001, 50))   # confident, half failing
        s3, e3, l3, h3, eb3 = QMC._pfgpci_credible_interval(phi3, 0.01)
        @test isapprox(s3, 0.5; atol=1e-12)
        @test isapprox(e3, 0.001; atol=1e-9)
        @test isapprox(h3 - l3, 2 * (e3 / 0.01); atol=1e-9)  # width = 2γ, unclamped
    end

    @testset "affine failure transform + constructor" begin
        dd = DigitalNetB2(3; seed=7)
        tm = Uniform(dd; lower_bound=(-π), upper_bound=π)
        f = Ishigami(tm)
        sc_above = PFGPCI(f; failure_threshold=2.0, failure_above_threshold=true)
        sc_below = PFGPCI(f; failure_threshold=2.0, failure_above_threshold=false)
        y = [1.0, 2.0, 3.0]
        @test QMC._pfgpci_affine_tf(sc_above, y) == [-1.0, 0.0, 1.0]   # failure: y ≥ 2
        @test QMC._pfgpci_affine_tf(sc_below, y) == [1.0, 0.0, -1.0]   # failure: y ≤ 2

        @test_throws ArgumentError PFGPCI(f; alpha=0.0)
        @test_throws ArgumentError PFGPCI(f; alpha=1.0)
        @test_throws ArgumentError PFGPCI(f; n_init=100, n_limit=50)
        @test_throws ArgumentError PFGPCI(f; n_batch=0)
    end

    if QMC._pfgpci_backend_loaded()
        @testset "Ishigami probability of failure (end-to-end)" begin
            dd = DigitalNetB2(3; seed=7)
            tm = Uniform(dd; lower_bound=(-π), upper_bound=π)
            f = Ishigami(tm)
            sc = PFGPCI(
                f;
                failure_threshold=0.0,
                abs_tol=0.02,
                n_init=32,
                n_limit=200,
                n_batch=4,
                n_approx=2^12,
            )
            r = integrate(sc; seed=11)
            @test r isa QMCResult
            @test 0.0 <= r.solution <= 1.0
            @test r.data[:bound_low] <= r.solution <= r.data[:bound_high]
            @test 0.0 <= r.data[:bound_low] <= r.data[:bound_high] <= 1.0
            @test r.data[:n_total] <= sc.n_limit
            @test length(r.data[:solutions]) == r.data[:n_iter]

            # statistical agreement with a QMC reference PF = mean(y ≥ threshold)
            ref_pts = QMC._sample_uniform_points(DigitalNetB2(3; seed=99), 2^16)
            ref_y = QMC.evaluate_on_uniform(f, ref_pts)
            ref_pf = count(>=(0.0), ref_y) / length(ref_y)
            @test isapprox(r.solution, ref_pf; atol=0.1)     # loose: GP-backend dependent
            @test r.data[:bound_low] <= ref_pf <= r.data[:bound_high]  # CI covers truth
        end
    else
        @testset "backend not loaded ⇒ actionable error" begin
            dd = DigitalNetB2(3; seed=7)
            tm = Uniform(dd; lower_bound=(-π), upper_bound=π)
            f = Ishigami(tm)
            @test_throws ErrorException integrate(PFGPCI(f))
        end
    end
end
