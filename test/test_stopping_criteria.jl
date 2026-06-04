@testset "Stopping Criteria" begin
    @testset "CubMCCLT" begin
        dd = IIDStdUniform(2; seed = 500)
        tm = Uniform(dd)
        f = CustomFun(tm, x -> sum(x, dims = 2)[:])
        sc = CubMCCLT(f; abs_tol = 0.05, n_init = 1024)
        result = integrate(sc)
        @test abs(result.solution - 1.0) < 0.1
        @test result.data[:converged] == true
        @test result.data[:n] > 0
        @test result.data[:n_total] == result.data[:n]
    end

    @testset "CubQMCLatticeG" begin
        dd = Lattice(2; randomize = true, seed = 600)
        tm = Uniform(dd)
        f = Genz(tm; kind = :continuous, a = [1.0, 1.0], u = [0.5, 0.5])
        exact = genz_exact(f)
        sc = CubQMCLatticeG(f; abs_tol = 0.1, n_init = 2^10, n_reps = 16)
        result = integrate(sc)
        @test abs(result.solution - exact) < 1.0
        @test result.data[:n] >= 2^10
        @test result.data[:n_per_rep] == result.data[:n]
        @test result.data[:n_total] == result.data[:n] * result.data[:n_reps]
    end

    @testset "CubQMCNetG" begin
        dd = DigitalNetB2(2; randomize = "DS", seed = 700)
        tm = Uniform(dd)
        f = Genz(tm; kind = :gaussian_peak, a = [1.0, 1.0], u = [0.5, 0.5])
        exact = genz_exact(f)
        sc = CubQMCNetG(f; abs_tol = 0.1, n_init = 2^10, n_reps = 16)
        result = integrate(sc)
        @test abs(result.solution - exact) < 1.0
        @test result.data[:n] >= 2^10
        @test result.data[:n_per_rep] == result.data[:n]
        @test result.data[:n_total] == result.data[:n] * result.data[:n_reps]
    end

    @testset "CubQMCBayesLatticeG (smoke)" begin
        dd = Lattice(2; randomize = true, seed = 800)
        tm = Uniform(dd)
        f = Genz(tm; kind = :continuous, a = [1.0, 1.0], u = [0.5, 0.5])
        exact = genz_exact(f)
        sc = CubQMCBayesLatticeG(f; abs_tol = 0.1, n_init = 2^8, n_max = 2^12)
        result = integrate(sc)
        @test result.solution isa Float64
        @test !isnan(result.solution)
        @test abs(result.solution - exact) < 0.02
        @test result.data[:n] >= 2^8
        @test result.data[:n_total] == result.data[:n]
        @test result.data[:n_per_rep] == result.data[:n]
    end

    @testset "CubQMCBayesNetG (smoke)" begin
        dd = DigitalNetB2(2; randomize = "LMS_DS", seed = 900)
        tm = Uniform(dd)
        f = Genz(tm; kind = :continuous, a = [1.0, 1.0], u = [0.5, 0.5])
        exact = genz_exact(f)
        sc = CubQMCBayesNetG(f; abs_tol = 0.1, n_init = 2^8, n_max = 2^12)
        result = integrate(sc)
        @test result.solution isa Float64
        @test !isnan(result.solution)
        @test abs(result.solution - exact) < 0.02
        @test result.data[:n] >= 2^8
        @test result.data[:n_total] == result.data[:n]
        @test result.data[:n_per_rep] == result.data[:n]
    end

    @testset "CubQMCRepStudentT (smoke)" begin
        dd = DigitalNetB2(2; randomize = "LMS_DS", seed = 901, replications = 4)
        tm = Uniform(dd)
        f = Genz(tm; kind = :continuous, a = [1.0, 1.0], u = [0.5, 0.5])
        sc = CubQMCRepStudentT(f; abs_tol = 0.2, n_init = 32, n_limit = 128)
        result = integrate(sc)
        @test result.solution isa Float64
        @test isfinite(result.solution)
        @test result.data[:n_total] == result.data[:n]
        @test result.data[:n_per_rep] == result.data[:n_rep]
        @test result.data[:n_total] == result.data[:n_per_rep] * result.data[:replications]
    end

    @testset "rel_tol in stopping criteria" begin
        dd = IIDStdUniform(3; seed = 7)
        tm = Gaussian(dd)
        f = Keister(tm)
        sc = CubMCCLT(f; abs_tol = 1.0, rel_tol = 0.01)
        @test sc.rel_tol == 0.01
    end

    @testset "CubMLQMC" begin
        dd = DigitalNetB2(16; randomize = "LMS_DS", seed = 7)
        tm = GeometricBrownianMotion(dd; volatility = 0.2, start_price = 100.0,
            interest_rate = 0.05, t_final = 1.0)
        fml = FinancialOptionML(tm; d_coarsest = 4)
        sc = CubMLQMC(fml; rmse_tol = 0.5, n_init = 64, levels_min = 2, levels_max = 4)
        @test sc.rmse_tol == 0.5
    end

    @testset "CubMCG" begin
        dd = IIDStdUniform(3; seed = 7)
        tm = Gaussian(dd)
        f = Keister(tm)
        sc = CubMCG(f; abs_tol = 0.1)
        @test sc.abs_tol == 0.1
        @test sc.kurtmax > 0
    end

    @testset "CubMCCLTVec" begin
        dd = IIDStdUniform(3; seed = 7)
        tm = Gaussian(dd)
        f = Keister(tm)
        sc = CubMCCLTVec(f; abs_tol = 0.05)
        @test sc.n_init == 256
    end

    @testset "Resume/Checkpoint" begin
        dd = IIDStdUniform(3; seed = 7)
        tm = Gaussian(dd)
        f = Keister(tm)
        sc1 = CubMCCLTVec(f; abs_tol = 0.1)
        r1 = integrate(sc1)
        @test haskey(r1.data, :_running_sum)
        sc2 = CubMCCLTVec(f; abs_tol = 0.01)
        r2 = integrate(sc2; resume = r1.data)
        @test r2.data[:n_total] >= r1.data[:n_total]
    end

    @testset "IterationLog" begin
        log = IterationLog()
        @test isempty(log)
        push!(log; n = 100, solution = 1.5, error_bound = 0.1, tol = 0.01, elapsed = 0.5)
        push!(log; n = 200, solution = 1.48, error_bound = 0.05, tol = 0.01, elapsed = 1.0)
        @test length(log) == 2
        rows = iterations(log)
        @test rows[1].n == 100
        @test rows[2].solution ≈ 1.48

        dd = IIDStdUniform(3; seed = 7)
        tm = Gaussian(dd)
        f = Keister(tm)
        sc = CubMCCLTVec(f; abs_tol = 0.05, trace_iterations = true)
        r = integrate(sc)
        @test haskey(r.data, :iteration_log)
        @test length(r.data[:iteration_log]) >= 1
    end

    @testset "QMCResult show" begin
        txt = sprint(show, QMCResult(1.0, Dict{Symbol, Any}(:n_total => 16, :error_bound => 0.1)))
        @test occursin("n_total=16", txt)
        @test occursin("error_bound=", txt)
    end
end
