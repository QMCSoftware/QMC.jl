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
    end

    @testset "CubQMCBayesLatticeG (smoke)" begin
        dd = Lattice(2; randomize = true, seed = 800)
        tm = Uniform(dd)
        f = Genz(tm; kind = :continuous, a = [1.0, 1.0], u = [0.5, 0.5])
        sc = CubQMCBayesLatticeG(f; abs_tol = 0.1, n_init = 2^8, n_max = 2^12)
        result = integrate(sc)
        @test result.solution isa Float64
        @test !isnan(result.solution)
        @test result.data[:n] >= 2^8
    end

    @testset "CubQMCBayesNetG (smoke)" begin
        dd = DigitalNetB2(2; randomize = "LMS_DS", seed = 900)
        tm = Uniform(dd)
        f = Genz(tm; kind = :continuous, a = [1.0, 1.0], u = [0.5, 0.5])
        sc = CubQMCBayesNetG(f; abs_tol = 0.1, n_init = 2^8, n_max = 2^12)
        result = integrate(sc)
        @test result.solution isa Float64
        @test !isnan(result.solution)
        @test result.data[:n] >= 2^8
    end
end
