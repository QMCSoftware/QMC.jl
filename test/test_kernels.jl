@testset "Kernels" begin
    @testset "KernelShiftInvar" begin
        k = KernelShiftInvar(order=1)
        @test k.order == 1

        k2 = KernelShiftInvar(order=2)
        @test k2.order == 2

        dd = Lattice(2; randomize=false, seed=1)
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
        k = KernelDigShiftInvar(order=2)
        @test k.order == 2

        dd = DigitalNetB2(2; randomize="none", seed=1)
        x = gen_samples(dd, 32)
        eig = compute_kernel_eigenvalues(k, x)
        @test length(eig) == 32
    end

    @testset "KernelMatern12" begin
        k = KernelMatern12(lengthscale=1.0, outputscale=1.0)
        @test kernel_eval(k, 0.0) ≈ 1.0
        @test kernel_eval(k, 1.0) ≈ exp(-1.0)
        # Build kernel matrix
        x = [0.0 0.0; 0.5 0.5; 1.0 1.0]
        K = kernel_matrix(k, x)
        @test size(K) == (3, 3)
        @test K ≈ K'  # symmetric
        @test all(eigvals(K) .>= -1e-8)  # PSD up to numerical roundoff
    end

    @testset "KernelMatern32" begin
        k = KernelMatern32(lengthscale=1.0, outputscale=1.0)
        @test kernel_eval(k, 0.0) ≈ 1.0
        @test kernel_eval(k, 1.0) ≈ (1.0 + sqrt(3.0)) * exp(-sqrt(3.0))
    end

    @testset "KernelMatern52" begin
        k = KernelMatern52(lengthscale=1.0, outputscale=1.0)
        @test kernel_eval(k, 0.0) ≈ 1.0
    end

    @testset "KernelGaussian" begin
        k = KernelGaussian(lengthscale=1.0, outputscale=2.0)
        @test kernel_eval(k, 0.0) ≈ 2.0
        @test kernel_eval(k, 1.0) ≈ 2.0 * exp(-0.5)
    end

    @testset "KernelRationalQuadratic" begin
        k = KernelRationalQuadratic(lengthscale=1.0, outputscale=2.0, alpha=1.0)
        @test kernel_eval(k, 0.0) ≈ 2.0
        @test kernel_eval(k, 1.0) ≈ 2.0 * (1.0 + 0.5)^(-1.0)
        k2 = KernelRationalQuadratic(lengthscale=1.5, outputscale=1.0, alpha=0.5)
        @test kernel_eval(k2, 2.0) ≈ 0.6
        klim = KernelRationalQuadratic(lengthscale=1.0, outputscale=1.0, alpha=1e8)
        @test kernel_eval(klim, 1.0) ≈ exp(-0.5) atol = 1e-6
        x = [0.0 0.0; 0.5 0.5; 1.0 1.0]
        K = kernel_matrix(k, x)
        @test size(K) == (3, 3)
        @test K ≈ K'
        @test all(eigvals(K) .>= -1e-8)
        @test_throws ArgumentError KernelRationalQuadratic(alpha=0.0)
        @test_throws ArgumentError KernelRationalQuadratic(lengthscale=-1.0)
    end

    @testset "KernelSquaredExponential" begin
        k = KernelSquaredExponential(lengthscale=1.0, outputscale=2.0)
        @test kernel_eval(k, 0.0) ≈ 2.0
        @test kernel_eval(k, 1.0) ≈ 2.0 * exp(-0.5)
        kg = KernelGaussian(lengthscale=1.3, outputscale=0.7)
        kse = KernelSquaredExponential(lengthscale=1.3, outputscale=0.7)
        for r in (0.0, 0.5, 1.0, 2.5)
            @test kernel_eval(kse, r) ≈ kernel_eval(kg, r)
        end
        @test_throws ArgumentError KernelSquaredExponential(lengthscale=0.0)
    end

    @testset "Combined Kernels" begin
        k1 = KernelMatern32(lengthscale=1.0, outputscale=1.0)
        k2 = KernelGaussian(lengthscale=2.0, outputscale=0.5)
        ks = k1 + k2
        kp = k1 * k2
        @test kernel_eval(ks, 0.0) ≈ kernel_eval(k1, 0.0) + kernel_eval(k2, 0.0)
        @test kernel_eval(kp, 0.0) ≈ kernel_eval(k1, 0.0) * kernel_eval(k2, 0.0)
        @test kernel_eval(ks, 1.0) ≈ kernel_eval(k1, 1.0) + kernel_eval(k2, 1.0)
    end

    @testset "SI/DSI value kernels (QMCPy parity)" begin
        # Values pinned from QMCPy's KernelShiftInvarCombined,
        # KernelDigShiftInvarAdaptiveAlpha, and KernelDigShiftInvarCombined at
        # default parameters (validated against qmcpy __call__ to ~1e-13).
        x0 = [0.1, 0.2, 0.3]
        x1 = [0.4, 0.5, 0.6]

        ksic = KernelShiftInvarCombined(3)
        @test kernel_eval(ksic, x0, x1) ≈ 4.54177582569934 atol = 1e-10
        @test kernel_eval(ksic, x0, x0) ≈ -57.35803352414608 atol = 1e-9

        kaa = KernelDigShiftInvarAdaptiveAlpha(3, 32)
        @test kernel_eval(kaa, x0, x1) ≈ 0.6188984220477008 atol = 1e-10
        @test kernel_eval(kaa, x0, x0) ≈ 3.510713675750846 atol = 1e-10

        kdc = KernelDigShiftInvarCombined(3, 32)
        @test kernel_eval(kdc, x0, x1) ≈ 0.2002448027423651 atol = 1e-10
        @test kernel_eval(kdc, x0, x0) ≈ 13.322617152151405 atol = 1e-10

        # Gram matrix: symmetric, diagonal matches the self-kernel value
        X = [0.1 0.2 0.3; 0.4 0.5 0.6; 0.7 0.8 0.9]
        for k in (ksic, kaa, kdc)
            K = kernel_matrix(k, X)
            @test size(K) == (3, 3)
            @test K ≈ K'
            @test K[2, 2] ≈ kernel_eval(k, X[2, :], X[2, :])
        end

        # constructor + helper validation
        @test_throws ArgumentError KernelShiftInvarCombined(3; lengthscales=[1.0, 2.0])
        @test_throws ArgumentError KernelDigShiftInvarCombined(3, 32; alpha=ones(4, 2))
        @test_throws ArgumentError KernelDigShiftInvarAdaptiveAlpha(3, 32; alpha=[1.0, 2.0])
        @test_throws ArgumentError QMC._weighted_walsh_funcs(5, UInt64(3), 32)
    end

    @testset "KernelShiftInvarDeriv (derivative orders)" begin
        # Values pinned from QMCPy's base KernelShiftInvar.__call__ with
        # derivative orders (validated to ~1e-12). d=2, alpha=2, default params.
        x0 = [0.1, 0.2]
        x1 = [0.4, 0.7]
        k = KernelShiftInvarDeriv(2)

        @test kernel_eval(k, x0, x1) ≈ 0.1530551333681213 atol = 1e-10
        # ∂/∂x0₁
        @test kernel_eval_deriv(k, x0, x1, [1, 0], [0, 0]) ≈ 0.973627865517581 atol = 1e-10
        # ∂/∂x1₂ — exactly 0 here since B₃(0.5) = 0
        @test kernel_eval_deriv(k, x0, x1, [0, 0], [0, 1]) ≈ 0.0 atol = 1e-12
        # mixed ∂²/∂x0₁∂x1₁
        @test kernel_eval_deriv(k, x0, x1, [1, 0], [1, 0]) ≈ -3.013610059935374 atol = 1e-10
        # 2nd order in dim 2
        @test kernel_eval_deriv(k, x0, x1, [0, 2], [0, 0]) ≈ 19.108618045798185 atol = 1e-9
        # two-term coefficient combination: 2·∂/∂x0₁ − 0.5·∂/∂x0₂
        @test kernel_eval_deriv(k, x0, x1, [1 0; 0 1], [0 0; 0 0], [2.0, -0.5]) ≈
              1.947255731035162 atol = 1e-10

        # non-derivative call agrees with the undifferentiated value kernel
        @test kernel_eval(k, x0, x1) ≈ kernel_eval_deriv(k, x0, x1, [0, 0], [0, 0])
        # Gram matrix symmetric
        X = [0.1 0.2; 0.4 0.7; 0.6 0.9]
        K = kernel_matrix(k, X)
        @test K ≈ K'
        @test K[2, 2] ≈ kernel_eval(k, X[2, :], X[2, :])

        # validation
        @test_throws ArgumentError KernelShiftInvarDeriv(2; alpha=[0, 2])
        @test_throws ArgumentError kernel_eval_deriv(k, x0, x1, [3, 0], [0, 0])  # order 2α-β = 1 < 2
    end

    @testset "KernelDigShiftInvarDeriv (derivative orders)" begin
        # Values pinned from QMCPy's base KernelDigShiftInvar.__call__ with
        # derivative orders (validated to 0 error). d=2, t=32, x0=[.1,.2], x1=[.4,.7].
        x0 = [0.1, 0.2]
        x1 = [0.4, 0.7]

        k2 = KernelDigShiftInvarDeriv(2, 32; alpha=[2, 2])
        @test kernel_eval(k2, x0, x1) ≈ 0.8500315666346804 atol = 1e-10

        k4 = KernelDigShiftInvarDeriv(2, 32; alpha=[4, 4])
        @test kernel_eval(k4, x0, x1) ≈ 0.8643230465442825 atol = 1e-10
        @test kernel_eval_deriv(k4, x0, x1, [1, 0], [0, 0]) ≈ -0.6553193188872999 atol = 1e-10
        @test kernel_eval_deriv(k4, x0, x1, [0, 0], [0, 1]) ≈ -0.6195565625635286 atol = 1e-10
        @test kernel_eval_deriv(k4, x0, x1, [1, 0], [1, 0]) ≈ 1.3264294648165356 atol = 1e-10
        # DSI derivative depends only on β0+β1, so ∂²/∂x0₁² equals the mixed ∂²/∂x0₁∂x1₁
        @test kernel_eval_deriv(k4, x0, x1, [2, 0], [0, 0]) ≈ 1.3264294648165356 atol = 1e-10
        @test kernel_eval_deriv(k4, x0, x1, [1 0; 0 1], [0 0; 0 0], [1.5, -0.7]) ≈
              -0.5492893845364798 atol = 1e-10

        K = kernel_matrix(k4, [0.1 0.2; 0.4 0.7; 0.6 0.9])
        @test K ≈ K'

        # validation: differentiating the α=2 DSI kernel is unsupported
        @test_throws ArgumentError kernel_eval_deriv(k2, x0, x1, [1, 0], [0, 0])
        @test_throws ArgumentError KernelDigShiftInvarDeriv(2, 32; alpha=[5, 2])
    end

    @testset "KernelMultiTaskDerivs (all-ones task wrapper)" begin
        x0 = [0.1, 0.2]
        x1 = [0.4, 0.7]
        base = KernelShiftInvarDeriv(2)
        mt = KernelMultiTaskDerivs(base, 3)

        # all-ones task matrix ⇒ value equals the base kernel for any task indices
        for (t0, t1) in ((1, 1), (1, 3), (3, 2))
            @test kernel_eval(mt, t0, t1, x0, x1) ≈ kernel_eval(base, x0, x1)
            @test kernel_eval_deriv(mt, t0, t1, x0, x1, [1, 0], [0, 0]) ≈
                  kernel_eval_deriv(base, x0, x1, [1, 0], [0, 0])
        end
        # equals the pinned base values from the SI-deriv testset
        @test kernel_eval(mt, 1, 2, x0, x1) ≈ 0.1530551333681213 atol = 1e-10
        @test kernel_eval_deriv(mt, 2, 3, x0, x1, [1, 0], [0, 0]) ≈ 0.973627865517581 atol =
            1e-10

        # task-index bounds
        @test_throws ArgumentError kernel_eval(mt, 0, 1, x0, x1)
        @test_throws ArgumentError kernel_eval(mt, 1, 4, x0, x1)
        @test_throws ArgumentError KernelMultiTaskDerivs(base, 0)
    end
end
