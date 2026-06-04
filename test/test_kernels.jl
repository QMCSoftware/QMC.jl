@testset "Kernels" begin
    @testset "KernelShiftInvar" begin
        k = KernelShiftInvar(order = 1)
        @test k.order == 1

        k2 = KernelShiftInvar(order = 2)
        @test k2.order == 2

        dd = Lattice(2; randomize = false, seed = 1)
        x = gen_samples(dd, 64)

        # Eigenvalues are real and correct length (PSD is not guaranteed
        # on a discrete lattice without the MLE parameter θ)
        eig1 = compute_kernel_eigenvalues(k, x)
        @test length(eig1) == 64
        @test all(isfinite, eig1)

        eig2 = compute_kernel_eigenvalues(k2, x)
        @test length(eig2) == 64
        @test all(isfinite, eig2)
    end

    @testset "KernelDigShiftInvar" begin
        k = KernelDigShiftInvar(order = 2)
        @test k.order == 2

        dd = DigitalNetB2(2; randomize = "none", seed = 1)
        x = gen_samples(dd, 32)
        eig = compute_kernel_eigenvalues(k, x)
        @test length(eig) == 32
    end

    @testset "KernelMatern12" begin
        k = KernelMatern12(lengthscale = 1.0, outputscale = 1.0)
        @test kernel_eval(k, 0.0) ≈ 1.0
        @test kernel_eval(k, 1.0) ≈ exp(-1.0)
        # Build kernel matrix
        x = [0.0 0.0; 0.5 0.5; 1.0 1.0]
        K = kernel_matrix(k, x)
        @test size(K) == (3, 3)
        @test K ≈ K'  # symmetric
        @test all(eigvals(K) .>= -1e-10)  # PSD
    end

    @testset "KernelMatern32" begin
        k = KernelMatern32(lengthscale = 1.0, outputscale = 1.0)
        @test kernel_eval(k, 0.0) ≈ 1.0
        @test kernel_eval(k, 1.0) ≈ (1.0 + sqrt(3.0)) * exp(-sqrt(3.0))
    end

    @testset "KernelMatern52" begin
        k = KernelMatern52(lengthscale = 1.0, outputscale = 1.0)
        @test kernel_eval(k, 0.0) ≈ 1.0
    end

    @testset "KernelGaussian" begin
        k = KernelGaussian(lengthscale = 1.0, outputscale = 2.0)
        @test kernel_eval(k, 0.0) ≈ 2.0
        @test kernel_eval(k, 1.0) ≈ 2.0 * exp(-0.5)
    end

    @testset "KernelRationalQuadratic" begin
        k = KernelRationalQuadratic(lengthscale = 1.0, outputscale = 2.0, alpha = 1.0)
        @test kernel_eval(k, 0.0) ≈ 2.0
        @test kernel_eval(k, 1.0) ≈ 2.0 * (1.0 + 0.5)^(-1.0)
        k2 = KernelRationalQuadratic(lengthscale = 1.5, outputscale = 1.0, alpha = 0.5)
        @test kernel_eval(k2, 2.0) ≈ 0.6
        klim = KernelRationalQuadratic(lengthscale = 1.0, outputscale = 1.0, alpha = 1e8)
        @test kernel_eval(klim, 1.0) ≈ exp(-0.5) atol = 1e-6
        x = [0.0 0.0; 0.5 0.5; 1.0 1.0]
        K = kernel_matrix(k, x)
        @test size(K) == (3, 3)
        @test K ≈ K'
        @test all(eigvals(K) .>= -1e-10)
        @test_throws ArgumentError KernelRationalQuadratic(alpha = 0.0)
        @test_throws ArgumentError KernelRationalQuadratic(lengthscale = -1.0)
    end

    @testset "KernelSquaredExponential" begin
        k = KernelSquaredExponential(lengthscale = 1.0, outputscale = 2.0)
        @test kernel_eval(k, 0.0) ≈ 2.0
        @test kernel_eval(k, 1.0) ≈ 2.0 * exp(-0.5)
        kg = KernelGaussian(lengthscale = 1.3, outputscale = 0.7)
        kse = KernelSquaredExponential(lengthscale = 1.3, outputscale = 0.7)
        for r in (0.0, 0.5, 1.0, 2.5)
            @test kernel_eval(kse, r) ≈ kernel_eval(kg, r)
        end
        @test_throws ArgumentError KernelSquaredExponential(lengthscale = 0.0)
    end

    @testset "Combined Kernels" begin
        k1 = KernelMatern32(lengthscale = 1.0, outputscale = 1.0)
        k2 = KernelGaussian(lengthscale = 2.0, outputscale = 0.5)
        ks = k1 + k2
        kp = k1 * k2
        @test kernel_eval(ks, 0.0) ≈ kernel_eval(k1, 0.0) + kernel_eval(k2, 0.0)
        @test kernel_eval(kp, 0.0) ≈ kernel_eval(k1, 0.0) * kernel_eval(k2, 0.0)
        @test kernel_eval(ks, 1.0) ≈ kernel_eval(k1, 1.0) + kernel_eval(k2, 1.0)
    end
end
