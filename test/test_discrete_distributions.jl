@testset "Discrete Distributions" begin

    @testset "IIDStdUniform" begin
        dd = IIDStdUniform(3; seed=42)
        x = gen_samples(dd, 1000)
        @test size(x) == (1000, 3)
        @test all(0.0 .<= x .< 1.0)
        @test abs(mean(x) - 0.5) < 0.05
        # Reproducibility
        dd2 = IIDStdUniform(3; seed=42)
        x2 = gen_samples(dd2, 100)
        dd3 = IIDStdUniform(3; seed=42)
        x3 = gen_samples(dd3, 100)
        @test x2 == x3
        # Edge case: dimension=1
        dd1 = IIDStdUniform(1; seed=1)
        x1 = gen_samples(dd1, 10)
        @test size(x1) == (10, 1)
    end

    @testset "Lattice" begin
        dd = Lattice(2; randomize=false, seed=7)
        x = gen_samples(dd, 64)
        @test size(x) == (64, 2)
        @test all(0.0 .<= x .< 1.0)
        # Deterministic reproducibility
        dd2 = Lattice(2; randomize=false, seed=7)
        x2 = gen_samples(dd2, 64)
        @test x ≈ x2

        # With randomization
        dd_r = Lattice(3; randomize=true, seed=99)
        xr = gen_samples(dd_r, 128)
        @test size(xr) == (128, 3)
        @test all(0.0 .<= xr .< 1.0)

        # Replications
        dd_rep = Lattice(2; randomize=true, seed=55, replications=8)
        xrep = gen_samples(dd_rep, 64)
        @test size(xrep) == (8, 64, 2)
        @test all(0.0 .<= xrep .< 1.0)
        # Different replications should differ (randomized)
        @test xrep[1, :, :] != xrep[2, :, :]

        # Orderings
        for ord in ["natural", "linear", "radical_inverse", "gray"]
            dd_o = Lattice(2; randomize=false, seed=1, order=ord)
            xo = gen_samples(dd_o, 32)
            @test size(xo) == (32, 2)
            @test all(0.0 .<= xo .< 1.0)
        end
    end

    @testset "DigitalNetB2" begin
        dd = DigitalNetB2(2; randomize="none", seed=1)
        x = gen_samples(dd, 16)
        @test size(x) == (16, 2)
        @test all(0.0 .<= x .< 1.0)
        # First point of Sobol is (0, 0)
        @test x[1, 1] ≈ 0.0 atol=1e-10
        @test x[1, 2] ≈ 0.0 atol=1e-10

        # Seed reproducibility
        dd_a = DigitalNetB2(3; randomize="LMS_DS", seed=42)
        xa = gen_samples(dd_a, 64)
        dd_b = DigitalNetB2(3; randomize="LMS_DS", seed=42)
        xb = gen_samples(dd_b, 64)
        @test xa ≈ xb

        # With digital shift
        dd_ds = DigitalNetB2(3; randomize="DS", seed=42)
        x_ds = gen_samples(dd_ds, 64)
        @test size(x_ds) == (64, 3)
        @test all(0.0 .<= x_ds .< 1.0)

        # Replications
        dd_rep = DigitalNetB2(2; randomize="LMS_DS", seed=77, replications=4)
        xrep = gen_samples(dd_rep, 32)
        @test size(xrep) == (4, 32, 2)
        @test all(0.0 .<= xrep .< 1.0)

        # Edge case: dimension=1
        dd1 = DigitalNetB2(1; randomize="none")
        x1 = gen_samples(dd1, 8)
        @test size(x1) == (8, 1)
    end

    @testset "Halton" begin
        dd = Halton(3; randomize=false, seed=1)
        x = gen_samples(dd, 100)
        @test size(x) == (100, 3)
        @test all(0.0 .<= x .< 1.0)
        @test x[1, 1] ≈ 0.0 atol=1e-10
        @test x[2, 1] ≈ 0.5 atol=1e-10

        # With randomization
        dd_r = Halton(2; randomize=true, seed=42)
        xr = gen_samples(dd_r, 128)
        @test size(xr) == (128, 2)
        @test all(0.0 .<= xr .< 1.0)
    end

end
