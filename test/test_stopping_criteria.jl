# Top-level multi-output integrand for the CubMCCLTVec vector tests (structs must
# be defined at top level, not inside a @testset). Two outputs over U[0,1]:
# output 1 = x₁ (mean 0.5), output 2 = x₁² (mean 1/3).
struct _VecCLTIntegrand{TM} <: QMC.AbstractIntegrand
    true_measure::TM
end
QMC.d_indv(::_VecCLTIntegrand) = (2,)
function QMC.evaluate(f::_VecCLTIntegrand, x::AbstractMatrix)
    Y = Matrix{Float64}(undef, size(x, 1), 2)
    @views Y[:, 1] .= x[:, 1]
    @views Y[:, 2] .= x[:, 1] .^ 2
    return Y
end

@testset "Stopping Criteria" begin
    @testset "CubMCCLT" begin
        dd = IIDStdUniform(2; seed=500)
        tm = Uniform(dd)
        f = CustomFun(tm, x -> sum(x, dims=2)[:])
        sc = CubMCCLT(f; abs_tol=0.05, n_init=1024)
        result = integrate(sc)
        @test abs(result.solution - 1.0) < 0.1
        @test result.data[:converged] == true
        @test result.data[:n] > 0
        @test result.data[:n_total] == result.data[:n]
    end

    @testset "Control variates" begin
        # ── core regression math, validated to equal QMC v2.3's lstsq formula ──
        # F1: a single, perfectly affine control variate g = 2y with known mean 6.
        let
            y = [1.0, 2.0, 3.0, 4.0, 5.0]
            ycv = reshape([2.0, 4.0, 6.0, 8.0, 10.0], 5, 1)
            beta = QMC._fit_control_variate_beta(y, ycv)
            @test length(beta) == 1
            @test beta[1] ≈ 0.5
            yadj = QMC._apply_control_variates(y, ycv, [6.0], beta)
            @test all(v -> isapprox(v, 3.0; atol=1e-12), yadj)  # fully explained ⇒ constant
            @test mean(yadj) ≈ 3.0
        end
        # F2: two control variates against hand-computed (QMCPy-formula) values.
        let
            y = [1.5, -0.5, 2.0, 3.5, 0.0, 1.0]
            ycv = [1.0 0.2; 0.0 0.1; 2.0 0.4; 3.0 0.5; 0.5 0.0; 1.0 0.3]
            beta = QMC._fit_control_variate_beta(y, ycv)
            @test beta ≈ [1.1666666666666667, 0.8333333333333331] rtol = 1e-9
            yadj = QMC._apply_control_variates(y, ycv, [1.25, 0.30], beta)
            @test mean(yadj) ≈ 1.2916666666666665 rtol = 1e-9
        end

        # ── constructor validation mirrors QMCPy's compatibility checks ──
        let
            dd = IIDStdUniform(1; seed=11)
            tm = Uniform(dd)
            main = CustomFun(tm, x -> exp.(x[:, 1]))
            cv = CustomFun(tm, x -> x[:, 1])
            @test_throws ArgumentError CubMCCLT(main; control_variates=cv)  # means missing
            @test_throws ArgumentError CubMCCLT(
                main;
                control_variates=[cv],
                control_variate_means=[0.5, 0.1],
            )  # length mismatch
            cv_wrongdim = CustomFun(Uniform(IIDStdUniform(2; seed=12)), x -> x[:, 1])
            @test_throws ArgumentError CubMCCLT(
                main;
                control_variates=cv_wrongdim,
                control_variate_means=0.5,
            )  # dimension/distribution mismatch
        end

        # ── end-to-end variance reduction: ∫₀¹ eˣ dx = e − 1 ──
        let
            dd = IIDStdUniform(1; seed=20240607)
            tm = Uniform(dd)
            main = CustomFun(tm, x -> exp.(x[:, 1]))
            cv = CustomFun(tm, x -> x[:, 1])           # known mean 0.5
            truth = exp(1) - 1
            r0 = integrate(CubMCCLT(main; abs_tol=5e-3, n_init=2^12, n_max=2^20))
            r1 = integrate(
                CubMCCLT(
                    main;
                    abs_tol=5e-3,
                    n_init=2^12,
                    n_max=2^20,
                    control_variates=cv,
                    control_variate_means=0.5,
                ),
            )
            @test abs(r1.solution - truth) < 5e-2
            @test haskey(r1.data, :control_variate_beta)
            @test r1.data[:control_variate_beta][1] > 1.0          # ≈1.69 for eˣ vs x
            @test r1.data[:sigma_main] < 0.5 * r0.data[:sigma_main] # real variance cut
        end

        # ── CubMCG: the variance cut shows up as far fewer guaranteed samples ──
        let
            dd = IIDStdUniform(1; seed=815)
            tm = Uniform(dd)
            main = CustomFun(tm, x -> exp.(x[:, 1]))
            cv = CustomFun(tm, x -> x[:, 1])           # known mean 0.5
            truth = exp(1) - 1
            r0 = integrate(CubMCG(main; abs_tol=5e-3, n_init=2^12, n_max=2^24))
            r1 = integrate(
                CubMCG(
                    main;
                    abs_tol=5e-3,
                    n_init=2^12,
                    n_max=2^24,
                    control_variates=cv,
                    control_variate_means=0.5,
                ),
            )
            @test abs(r1.solution - truth) < 5e-2
            @test haskey(r1.data, :control_variate_beta)
            @test r1.data[:control_variate_beta][1] > 1.0
            # a guaranteed method spends its variance reduction on a smaller budget
            @test r1.data[:n_total] < r0.data[:n_total]
        end
    end

    @testset "Control variates (QMC, CubQMCNetG)" begin
        # ── robust property: an integrand used as its own control variate is
        # recovered exactly (β→1, the corrected coefficients vanish, bound→0) ──
        let
            dd = DigitalNetB2(2; randomize="LMS_DS", graycode=false, seed=77)
            tm = Uniform(dd)
            g = CustomFun(tm, x -> x[:, 1] .^ 2 .+ x[:, 2])
            mu_g = 1 / 3 + 1 / 2                       # E[x₁² + x₂] on U[0,1]²
            r = integrate(
                CubQMCNetG(g; abs_tol=1e-3, control_variates=g, control_variate_means=mu_g),
            )
            @test isapprox(r.solution, mu_g; atol=1e-10)
            @test r.data[:error_bound] < 1e-10
            @test haskey(r.data, :control_variate_beta)
            @test isapprox(r.data[:control_variate_beta][1], 1.0; atol=1e-8)
        end
        # ── correlated control variate: accuracy maintained, β stored ──
        let
            dd = DigitalNetB2(2; randomize="LMS_DS", graycode=false, seed=78)
            tm = Uniform(dd)
            f = CustomFun(tm, x -> exp.(x[:, 1]) .* x[:, 2])
            cv = CustomFun(tm, x -> x[:, 1] .+ x[:, 2])  # known mean 1.0
            truth = (exp(1) - 1) * 0.5
            r = integrate(
                CubQMCNetG(f; abs_tol=1e-4, control_variates=cv, control_variate_means=1.0),
            )
            @test abs(r.solution - truth) < 1e-3
            @test haskey(r.data, :control_variate_beta)
            @test isfinite(r.data[:control_variate_beta][1])
        end
    end

    @testset "Control variates (QMC, CubQMCLatticeG)" begin
        # ── same robust exact-recovery property as the net case ──
        let
            dd = Lattice(2; randomize=true, seed=77)
            tm = Uniform(dd)
            g = CustomFun(tm, x -> x[:, 1] .^ 2 .+ x[:, 2])
            mu_g = 1 / 3 + 1 / 2                       # E[x₁² + x₂] on U[0,1]²
            r = integrate(
                CubQMCLatticeG(g; abs_tol=1e-3, control_variates=g, control_variate_means=mu_g),
            )
            @test isapprox(r.solution, mu_g; atol=1e-10)
            @test r.data[:error_bound] < 1e-10
            @test haskey(r.data, :control_variate_beta)
            @test isapprox(r.data[:control_variate_beta][1], 1.0; atol=1e-8)
        end
        # ── correlated control variate: accuracy maintained, β stored ──
        let
            dd = Lattice(2; randomize=true, seed=78)
            tm = Uniform(dd)
            f = CustomFun(tm, x -> exp.(x[:, 1]) .* x[:, 2])
            cv = CustomFun(tm, x -> x[:, 1] .+ x[:, 2])  # known mean 1.0
            truth = (exp(1) - 1) * 0.5
            r = integrate(
                CubQMCLatticeG(f; abs_tol=1e-4, control_variates=cv, control_variate_means=1.0),
            )
            @test abs(r.solution - truth) < 1e-3
            @test haskey(r.data, :control_variate_beta)
            @test isfinite(r.data[:control_variate_beta][1])
        end
    end

    @testset "CubQMCLatticeG" begin
        dd = Lattice(2; randomize=true, seed=600)
        tm = Uniform(dd)
        f = Genz(tm; kind=:continuous, a=[1.0, 1.0], u=[0.5, 0.5])
        exact = genz_exact(f)
        sc = CubQMCLatticeG(f; abs_tol=0.1, n_init=2^10, n_reps=16)
        result = integrate(sc)
        @test abs(result.solution - exact) < 1.0
        @test result.data[:n] >= 2^10
        @test result.data[:n_per_rep] == result.data[:n]
        @test result.data[:n_total] == result.data[:n] * result.data[:n_reps]
    end

    @testset "CubQMCNetG" begin
        # Single-net guaranteed cubature (QMCPy CubQMCNetG). Requires a
        # non-replicated DigitalNetB2 in natural (radical-inverse) order.
        dd = DigitalNetB2(3; randomize="LMS_DS", graycode=false, seed=2024)
        tm = Gaussian(dd; covariance=0.5)
        f = Keister(tm)
        exact = keister_exact(3)
        sc = CubQMCNetG(f; abs_tol=0.01, n_init=2^10)
        result = integrate(sc)
        @test abs(result.solution - exact) < 0.05
        @test result.data[:error_bound] <= 0.01 + 1e-9
        @test result.data[:converged]
        @test result.data[:n_reps] == 1
        @test result.data[:n_total] == result.data[:n]

        # Guard: a default (graycode=true) net is rejected at construction.
        dd_gc = DigitalNetB2(3; randomize="LMS_DS", seed=1)
        @test_throws ErrorException CubQMCNetG(Keister(Gaussian(dd_gc; covariance=0.5)))
    end

    @testset "CubQMCNetGRep" begin
        dd = DigitalNetB2(2; randomize="DS", seed=700)
        tm = Uniform(dd)
        f = Genz(tm; kind=:gaussian_peak, a=[1.0, 1.0], u=[0.5, 0.5])
        exact = genz_exact(f)
        sc = CubQMCNetGRep(f; abs_tol=0.1, n_init=2^10, n_reps=16)
        result = integrate(sc)
        @test abs(result.solution - exact) < 1.0
        @test result.data[:n] >= 2^10
        @test result.data[:n_per_rep] == result.data[:n]
        @test result.data[:n_total] == result.data[:n] * result.data[:n_reps]
    end

    @testset "CubQMCNetGSingle alias" begin
        dd = DigitalNetB2(3; randomize="LMS_DS", graycode=false, seed=11)
        tm = Gaussian(dd; covariance=0.5)
        f = Keister(tm)
        sc = CubQMCNetGSingle(f; abs_tol=0.01, n_init=2^10)
        @test sc isa CubQMCNetG
        @test integrate(sc).data[:n_reps] == 1
    end

    @testset "CubQMCBayesLatticeG (smoke)" begin
        dd = Lattice(2; randomize=true, seed=800)
        tm = Uniform(dd)
        f = Genz(tm; kind=:continuous, a=[1.0, 1.0], u=[0.5, 0.5])
        exact = genz_exact(f)
        sc = CubQMCBayesLatticeG(f; abs_tol=0.1, n_init=2^8, n_max=2^12)
        result = integrate(sc)
        @test result.solution isa Float64
        @test !isnan(result.solution)
        @test abs(result.solution - exact) < 0.02
        @test result.data[:n] >= 2^8
        @test result.data[:n_total] == result.data[:n]
        @test result.data[:n_per_rep] == result.data[:n]
        traced = integrate(
            CubQMCBayesLatticeG(f; abs_tol=0.1, n_init=2^8, n_max=2^12, trace_iterations=true),
        )
        @test haskey(traced.data, :iteration_log)
        @test length(traced.data[:iteration_log]) >= 1
    end

    @testset "CubQMCBayesNetG (smoke)" begin
        dd = DigitalNetB2(2; randomize="LMS_DS", seed=900)
        tm = Uniform(dd)
        f = Genz(tm; kind=:continuous, a=[1.0, 1.0], u=[0.5, 0.5])
        exact = genz_exact(f)
        sc = CubQMCBayesNetG(f; abs_tol=0.1, n_init=2^8, n_max=2^12)
        result = integrate(sc)
        @test result.solution isa Float64
        @test !isnan(result.solution)
        @test abs(result.solution - exact) < 0.02
        @test result.data[:n] >= 2^8
        @test result.data[:n_total] == result.data[:n]
        @test result.data[:n_per_rep] == result.data[:n]
        traced = integrate(
            CubQMCBayesNetG(f; abs_tol=0.1, n_init=2^8, n_max=2^12, trace_iterations=true),
        )
        @test haskey(traced.data, :iteration_log)
        @test length(traced.data[:iteration_log]) >= 1
    end

    @testset "CubQMCRepStudentT (smoke)" begin
        dd = DigitalNetB2(2; randomize="LMS_DS", seed=901, replications=4)
        tm = Uniform(dd)
        f = Genz(tm; kind=:continuous, a=[1.0, 1.0], u=[0.5, 0.5])
        sc = CubQMCRepStudentT(f; abs_tol=0.2, n_init=32, n_limit=128)
        result = integrate(sc)
        @test result.solution isa Float64
        @test isfinite(result.solution)
        @test result.data[:n_total] == result.data[:n]
        @test result.data[:n_per_rep] == result.data[:n_rep]
        @test result.data[:n_total] == result.data[:n_per_rep] * result.data[:replications]
    end

    @testset "rel_tol in stopping criteria" begin
        dd = IIDStdUniform(3; seed=7)
        tm = Gaussian(dd)
        f = Keister(tm)
        sc = CubMCCLT(f; abs_tol=1.0, rel_tol=0.01)
        @test sc.rel_tol == 0.01
    end

    @testset "CubMLQMC" begin
        dd = DigitalNetB2(16; randomize="LMS_DS", seed=7)
        tm = GeometricBrownianMotion(
            dd;
            volatility=0.2,
            start_price=100.0,
            interest_rate=0.05,
            t_final=1.0,
        )
        fml = FinancialOptionML(tm; d_coarsest=4)
        sc = CubMLQMC(fml; rmse_tol=0.5, n_init=64, levels_min=2, levels_max=4)
        @test sc.rmse_tol == 0.5
    end

    @testset "CubMCG" begin
        dd = IIDStdUniform(3; seed=7)
        tm = Gaussian(dd)
        f = Keister(tm)
        sc = CubMCG(f; abs_tol=0.1)
        @test sc.abs_tol == 0.1
        @test sc.kurtmax > 0
        r = integrate(CubMCG(f; abs_tol=0.1, trace_iterations=true))
        @test haskey(r.data, :iteration_log)
        @test length(r.data[:iteration_log]) >= 1
    end

    @testset "CubMCCLTVec" begin
        dd = IIDStdUniform(3; seed=7)
        tm = Gaussian(dd)
        f = Keister(tm)
        sc = CubMCCLTVec(f; abs_tol=0.05)
        @test sc.n_init == 256
    end

    @testset "CubMCCLTVec (multi-output)" begin
        dd = IIDStdUniform(1; seed=303)
        tm = Uniform(dd)
        f = _VecCLTIntegrand(tm)
        r = integrate(CubMCCLTVec(f; abs_tol=0.02, n_max=2^20))
        @test r isa QMCVecResult
        @test length(r.solution) == 2
        @test isapprox(r.solution[1], 0.5; atol=0.05)         # E[x] = 1/2
        @test isapprox(r.solution[2], 1 / 3; atol=0.05)       # E[x²] = 1/3
        @test r.data[:converged]
        @test r.data[:error_bound] <= 0.02 + 1e-9             # every output within tol
        @test size(r.data[:solution_indv]) == (2,)
        @test size(r.data[:comb_bound_low]) == (2,)
        # combined bounds bracket the per-output solutions
        @test all(r.data[:comb_bound_low] .<= r.solution .<= r.data[:comb_bound_high])

        # scalar integrand still returns a scalar QMCResult (path unchanged)
        fs = CustomFun(Uniform(IIDStdUniform(2; seed=304)), x -> sum(x; dims=2)[:])
        rs = integrate(CubMCCLTVec(fs; abs_tol=0.05))
        @test rs isa QMCResult
        @test rs.solution isa Float64
    end

    @testset "Resume/Checkpoint" begin
        dd = IIDStdUniform(3; seed=7)
        tm = Gaussian(dd)
        f = Keister(tm)
        sc1 = CubMCCLTVec(f; abs_tol=0.1)
        r1 = integrate(sc1)
        @test haskey(r1.data, :_running_sum)
        sc2 = CubMCCLTVec(f; abs_tol=0.01)
        r2 = integrate(sc2; resume=r1.data)
        @test r2.data[:n_total] >= r1.data[:n_total]
    end

    @testset "IterationLog" begin
        log = IterationLog()
        @test isempty(log)
        push!(log; n=100, solution=1.5, error_bound=0.1, tol=0.01, elapsed=0.5)
        push!(log; n=200, solution=1.48, error_bound=0.05, tol=0.01, elapsed=1.0)
        @test length(log) == 2
        rows = iterations(log)
        @test rows[1].n == 100
        @test rows[2].solution ≈ 1.48

        dd = IIDStdUniform(3; seed=7)
        tm = Gaussian(dd)
        f = Keister(tm)
        sc = CubMCCLTVec(f; abs_tol=0.05, trace_iterations=true)
        r = integrate(sc)
        @test haskey(r.data, :iteration_log)
        @test length(r.data[:iteration_log]) >= 1

        sc_clt = CubMCCLT(f; abs_tol=0.05, trace_iterations=true)
        r_clt = integrate(sc_clt)
        @test haskey(r_clt.data, :iteration_log)
        @test length(r_clt.data[:iteration_log]) == 2
    end

    @testset "QMCResult show" begin
        txt =
            sprint(show, QMCResult(1.0, Dict{Symbol, Any}(:n_total => 16, :error_bound => 0.1)))
        @test occursin("n_total=16", txt)
        @test occursin("error_bound=", txt)
    end

    @testset "set_tolerance!" begin
        dd = IIDStdUniform(3; seed=42)
        f = Keister(Gaussian(dd; covariance=0.5))
        sc = CubMCCLT(f; abs_tol=0.05)
        @test sc.abs_tol == 0.05
        @test sc.rel_tol == 0.0

        ret = set_tolerance!(sc; abs_tol=0.2)
        @test ret === sc
        @test sc.abs_tol == 0.2
        @test sc.rel_tol == 0.0

        set_tolerance!(sc; rel_tol=0.01)
        @test sc.abs_tol == 0.2
        @test sc.rel_tol == 0.01

        @test_throws ArgumentError set_tolerance!(sc; abs_tol=-1.0)
        @test_throws ArgumentError set_tolerance!(sc; rel_tol=-0.5)

        dd_ml = DigitalNetB2(16; randomize="LMS_DS", seed=7)
        gbm = GeometricBrownianMotion(
            dd_ml;
            volatility=0.2,
            start_price=100.0,
            interest_rate=0.05,
            t_final=1.0,
        )
        scml = CubMLMC(FinancialOptionML(gbm; d_coarsest=4); abs_tol=0.1)
        @test scml.rmse_tol > 0
        set_tolerance!(scml; rmse_tol=0.05)
        @test scml.rmse_tol == 0.05

        scmlqmc = CubMLQMC(FinancialOptionML(gbm; d_coarsest=4); abs_tol=0.1)
        @test scmlqmc.rmse_tol > 0
        set_tolerance!(scmlqmc; rmse_tol=0.05)
        @test scmlqmc.rmse_tol == 0.05

        scmlcont = CubMLMCCont(FinancialOptionML(gbm; d_coarsest=4); abs_tol=0.1)
        @test scmlcont.target_tol > 0
        set_tolerance!(scmlcont; rmse_tol=0.05)
        @test scmlcont.target_tol == 0.05

        @test_throws ArgumentError set_tolerance!(scml; rel_tol=0.01)
    end

    @testset "QMC criterion contract (characterization)" begin
        # Value-free regression guards that any future rework of the replicated
        # QMC criteria must preserve. They assert the convergence *contract* and
        # cross-criterion consistency rather than hard-coded estimates, so they
        # remain valid across legitimate refactors (e.g. an incremental-net or
        # Walsh-coefficient rewrite) while catching a criterion that silently
        # stops converging, drops a schema key, becomes non-reproducible, or
        # disagrees with the other QMC rule.
        exact = keister_exact(3)
        net =
            tol -> CubQMCNetGRep(
                Keister(
                    Gaussian(DigitalNetB2(3; randomize="LMS_DS", seed=2024); covariance=0.5),
                );
                abs_tol=tol,
                n_init=2^10,
                n_reps=16,
            )
        lat =
            tol -> CubQMCLatticeG(
                Keister(Gaussian(Lattice(3; randomize=true, seed=2024); covariance=0.5));
                abs_tol=tol,
                n_init=2^10,
                n_reps=16,
            )

        for make in (net, lat)
            res = integrate(make(0.05))
            # Converges within a safe (5x) margin of the known exact value.
            @test abs(res.solution - exact) < 0.25
            # Reports having met the requested tolerance.
            @test res.data[:error_bound] <= 0.05 + 1e-9
            # Standardized result schema is complete and self-consistent.
            for k in (:n, :n_per_rep, :n_total, :n_reps, :error_bound)
                @test haskey(res.data, k)
            end
            @test res.data[:n_total] == res.data[:n_per_rep] * res.data[:n_reps]
            # Reproducible under a fixed seed.
            @test integrate(make(0.05)).solution == res.solution
            # A tighter tolerance never uses fewer samples.
            @test integrate(make(0.005)).data[:n_total] >= res.data[:n_total]
        end

        # The two QMC rules estimate the same integral.
        @test abs(integrate(net(0.05)).solution - integrate(lat(0.05)).solution) < 0.2
    end
end
