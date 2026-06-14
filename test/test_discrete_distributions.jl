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

        dd_gray = Lattice(2; randomize=true, seed=42, order="gray")
        x_gray = gen_samples(dd_gray, 200)
        @test size(x_gray) == (200, 2)
        @test all(0.0 .<= x_gray .< 1.0)

        dd_nat = Lattice(2; randomize=true, seed=42, order="natural")
        @test_throws ArgumentError gen_samples(dd_nat, 200)
        @test_throws ArgumentError gen_samples(dd_nat, 40; n_start=8)

        # "natural" is an alias for "radical_inverse" (QMCPy semantics): it is
        # normalized to the canonical token and produces identical points.
        @test Lattice(2; order="natural").order == "radical_inverse"
        @test Lattice(2; order="RADICAL INVERSE").order == "radical_inverse"
        @test Lattice(2; order="gray code").order == "gray"
        let a = Lattice(3; randomize=false, seed=7, order="natural"),
            b = Lattice(3; randomize=false, seed=7, order="radical_inverse")

            @test gen_samples(a, 64) ≈ gen_samples(b, 64)
        end
        @test_throws ArgumentError Lattice(2; order="bogus")

        # Custom generating vectors keep the existing C-backed generation path.
        gv = [1, 3, 5]
        dd_custom = Lattice(2; randomize=false, order="linear", generating_vector=gv)
        x_custom = gen_samples(dd_custom, 8)
        @test x_custom ≈ [
            0.0 0.0
            1 / 8 3 / 8
            2 / 8 6 / 8
            3 / 8 1 / 8
            4 / 8 4 / 8
            5 / 8 7 / 8
            6 / 8 2 / 8
            7 / 8 5 / 8
        ]
        @test dd_custom.gen_vector == UInt64[1, 3]

        # m_max caps the valid sample count for a raw generating vector
        # (QMCPy parity): without it the count is uncapped; with it, 2^m_max.
        @test Lattice(2; generating_vector=[1, 3, 5]).n_limit === nothing
        let dd_cap = Lattice(
                2;
                randomize=false,
                order="linear",
                generating_vector=[1, 3, 5],
                m_max=3,
            )
            @test dd_cap.n_limit == 8
            @test size(gen_samples(dd_cap, 8), 1) == 8           # at the cap: OK
            @test_throws ArgumentError gen_samples(dd_cap, 16)   # beyond the cap
        end
        @test_throws ArgumentError Lattice(2; generating_vector=[1, 3, 5], m_max=0)
        @test_throws ArgumentError Lattice(2; generating_vector=[1, 3, 5], m_max=-1)
        # m_max only applies to a custom integer vector
        @test_throws ArgumentError Lattice(2; m_max=10)                       # default vector
        @test_throws ArgumentError Lattice(2; generating_vector=6, m_max=10)  # random vector

        mktemp() do path, io
            write(io, "# d_limit\n4\n# n_limit\n16\n1\n3\n5\n7\n")
            close(io)
            dd_file = Lattice(3; randomize=false, order="linear", generating_vector=path)
            dd_direct =
                Lattice(3; randomize=false, order="linear", generating_vector=[1, 3, 5, 7])
            @test gen_samples(dd_file, 8) ≈ gen_samples(dd_direct, 8)
            @test dd_file.n_limit == 16
            @test_throws ArgumentError gen_samples(dd_file, 17)
        end
        mktemp() do path, io
            write(io, "# d_limit\n2\n# n_limit\n16\n1\n3\n5\n7\n")
            close(io)
            @test_throws ArgumentError Lattice(
                3;
                randomize=false,
                order="linear",
                generating_vector=path,
            )
        end

        dd_default = Lattice(3; randomize=false, order="linear")
        for ref in (
            "kuo.lattice-33002-1024-1048576.9125",
            "lattice/kuo.lattice-33002-1024-1048576.9125.txt",
            "https://github.com/QMCSoftware/LDData/tree/main/lattice/kuo.lattice-33002-1024-1048576.9125.txt",
            "https://raw.githubusercontent.com/QMCSoftware/LDData/main/lattice/kuo.lattice-33002-1024-1048576.9125.txt",
        )
            dd_named = Lattice(3; randomize=false, order="linear", generating_vector=ref)
            @test dd_named.gen_vector == dd_default.gen_vector
            @test dd_named.n_limit == dd_default.n_limit
            @test gen_samples(dd_named, 16) ≈ gen_samples(dd_default, 16)
        end

        dd_default = Lattice(3; randomize=false, order="linear")
        for ref in (
            "kuo.lattice-33002-1024-1048576.9125",
            "lattice/kuo.lattice-33002-1024-1048576.9125.txt",
            "https://github.com/QMCSoftware/LDData/tree/main/lattice/kuo.lattice-33002-1024-1048576.9125.txt",
            "https://raw.githubusercontent.com/QMCSoftware/LDData/main/lattice/kuo.lattice-33002-1024-1048576.9125.txt",
        )
            dd_named = Lattice(3; randomize=false, order="linear", generating_vector=ref)
            @test dd_named.gen_vector == dd_default.gen_vector
            @test dd_named.n_limit == dd_default.n_limit
            @test gen_samples(dd_named, 16) ≈ gen_samples(dd_default, 16)
        end

        dd_rand_a = Lattice(4; randomize=false, order="linear", seed=11, generating_vector=6)
        dd_rand_b = Lattice(4; randomize=false, order="linear", seed=11, generating_vector=6)
        @test dd_rand_a.gen_vector == dd_rand_b.gen_vector
        @test dd_rand_a.gen_vector[1] == UInt64(1)
        @test all(isodd, dd_rand_a.gen_vector[2:end])
        @test all(3 .<= dd_rand_a.gen_vector[2:end] .<= 63)
        @test size(gen_samples(dd_rand_a, 16)) == (16, 4)
        @test_throws ArgumentError gen_samples(dd_rand_a, 65)

        @test_throws ArgumentError Lattice(3; generating_vector=[1, 3])
        @test_throws ArgumentError Lattice(2; generating_vector=[1, 0])
        @test_throws ArgumentError Lattice(2; generating_vector=1)
        @test_throws ArgumentError Lattice(2; generating_vector=27)
        @test_throws ArgumentError Lattice(2; generating_vector="missing-vector.txt")
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

        dd_lms_a = DigitalNetB2(3; randomize="LMS", seed=42)
        xlms_a = gen_samples(dd_lms_a, 64)
        dd_lms_b = DigitalNetB2(3; randomize="LMS", seed=42)
        xlms_b = gen_samples(dd_lms_b, 64)
        @test size(xlms_a) == (64, 3)
        @test all(0.0 .<= xlms_a .< 1.0)
        @test xlms_a ≈ xlms_b
        @test xlms_a[1, :] ≈ zeros(3) atol=1e-12
        @test xlms_a != gen_samples(DigitalNetB2(3; randomize="none", seed=42), 64)

        dd_lms_rep = DigitalNetB2(2; randomize="LMS", seed=77, replications=4)
        xlms_rep = gen_samples(dd_lms_rep, 32)
        @test size(xlms_rep) == (4, 32, 2)
        @test all(0.0 .<= xlms_rep .< 1.0)
        @test xlms_rep[1, :, :] != xlms_rep[2, :, :]

        # Constructor parity: accept QMCPy-style token spellings.
        @test DigitalNetB2(2; randomize="LMS DS").randomize == "LMS_DS"
        @test DigitalNetB2(2; randomize=:LMS_DS).randomize == "LMS_DS"
        @test DigitalNetB2(2; randomize="false").randomize == "none"
        @test DigitalNetB2(2; randomize="OWEN").randomize == "NUS"

        # Constructor parity: accept QMCPy-style order spellings.
        @test DigitalNetB2(2; order="GRAY CODE").graycode
        @test !DigitalNetB2(2; order="NATURAL").graycode
        @test !DigitalNetB2(2; order=:RADICAL_INVERSE).graycode
        let a = DigitalNetB2(3; randomize="none", seed=7, order="natural"),
            b = DigitalNetB2(3; randomize="none", seed=7, graycode=false)

            @test gen_samples(a, 16) ≈ gen_samples(b, 16)
        end
        @test_throws ArgumentError DigitalNetB2(2; order="bogus")
        @test_throws ArgumentError DigitalNetB2(2; order="gray", graycode=false)

        # Custom direction matrices keep the existing generation path.
        V8 = Int.(dd.direction_nums[:, 1:8] .>> 24)
        dd_custom = DigitalNetB2(2; randomize="none", seed=1, generating_matrices=V8)
        @test gen_samples(dd_custom, 16) ≈ gen_samples(dd, 16)
        @test dd_custom.direction_nums == UInt64.(V8)
        V8_lsb = map(v -> Int(bitreverse(UInt32(v)) >> 24), V8)
        dd_custom_lsb =
            DigitalNetB2(2; randomize="none", seed=1, generating_matrices=V8_lsb, msb=false)
        @test gen_samples(dd_custom_lsb, 16) ≈ gen_samples(dd_custom, 16)
        Vsparse = [1 2 4 8 1 2 4 8; 1 2 4 8 1 2 4 8]
        dd_sparse_lsb =
            DigitalNetB2(2; randomize="none", seed=1, generating_matrices=Vsparse, msb=false)
        @test dd_sparse_lsb.direction_nums == map(v -> bitreverse(UInt64(v)) >> 56, Vsparse)

        # Advanced constructor parity: widened t-bits and msb handling.
        @test DigitalNetB2(2; randomize="none", t=40).t == 40
        @test gen_samples(DigitalNetB2(2; randomize="none", seed=1, t=40), 16) == x
        xrep_t =
            gen_samples(DigitalNetB2(2; randomize="none", seed=1, replications=3, t=40), 16)
        @test size(xrep_t) == (3, 16, 2)
        @test all(0.0 .<= xrep_t .< 1.0)
        @test xrep_t[1, :, :] == xrep_t[2, :, :]
        @test xrep_t[2, :, :] == xrep_t[3, :, :]

        x_nus_t_a = gen_samples(DigitalNetB2(2; randomize="NUS", seed=9, t=40), 16)
        x_nus_t_b = gen_samples(DigitalNetB2(2; randomize="NUS", seed=9, t=40), 16)
        @test size(x_nus_t_a) == (16, 2)
        @test all(0.0 .<= x_nus_t_a .< 1.0)
        @test x_nus_t_a ≈ x_nus_t_b
        x_nus_rep_t =
            gen_samples(DigitalNetB2(2; randomize="NUS", seed=9, replications=2, t=40), 8)
        @test size(x_nus_rep_t) == (2, 8, 2)
        @test all(0.0 .<= x_nus_rep_t .< 1.0)

        # Higher-order / interlaced digital nets.
        dd_alpha = DigitalNetB2(3; randomize="none", seed=7, alpha=2, graycode=false)
        @test dd_alpha.alpha == 2
        @test dd_alpha.t == 64
        @test gen_samples(dd_alpha, 4) == [
            0.0 0.0 0.0
            0.75 0.75 0.75
            0.4375 0.9375 0.1875
            0.6875 0.1875 0.9375
        ]

        x_alpha_lmsds_a = gen_samples(DigitalNetB2(3; randomize="LMS_DS", seed=7, alpha=2), 8)
        x_alpha_lmsds_b = gen_samples(DigitalNetB2(3; randomize="LMS_DS", seed=7, alpha=2), 8)
        @test size(x_alpha_lmsds_a) == (8, 3)
        @test all(0.0 .<= x_alpha_lmsds_a .< 1.0)
        @test x_alpha_lmsds_a ≈ x_alpha_lmsds_b

        x_alpha_lms_a = gen_samples(DigitalNetB2(3; randomize="LMS", seed=7, alpha=2), 8)
        x_alpha_lms_b = gen_samples(DigitalNetB2(3; randomize="LMS", seed=7, alpha=2), 8)
        @test size(x_alpha_lms_a) == (8, 3)
        @test all(0.0 .<= x_alpha_lms_a .< 1.0)
        @test x_alpha_lms_a ≈ x_alpha_lms_b
        x_alpha_lms_rep =
            gen_samples(DigitalNetB2(3; randomize="LMS", seed=7, replications=2, alpha=2), 8)
        @test size(x_alpha_lms_rep) == (2, 8, 3)
        @test all(0.0 .<= x_alpha_lms_rep .< 1.0)

        x_alpha_ds_a = gen_samples(DigitalNetB2(3; randomize="DS", seed=7, alpha=2), 8)
        x_alpha_ds_b = gen_samples(DigitalNetB2(3; randomize="DS", seed=7, alpha=2), 8)
        @test size(x_alpha_ds_a) == (8, 3)
        @test all(0.0 .<= x_alpha_ds_a .< 1.0)
        @test x_alpha_ds_a ≈ x_alpha_ds_b
        x_alpha_ds_rep =
            gen_samples(DigitalNetB2(3; randomize="DS", seed=7, replications=2, alpha=2), 8)
        @test size(x_alpha_ds_rep) == (2, 8, 3)
        @test all(0.0 .<= x_alpha_ds_rep .< 1.0)

        x_alpha_nus_a = gen_samples(DigitalNetB2(3; randomize="NUS", seed=7, alpha=2), 8)
        x_alpha_nus_b = gen_samples(DigitalNetB2(3; randomize="NUS", seed=7, alpha=2), 8)
        @test size(x_alpha_nus_a) == (8, 3)
        @test all(0.0 .<= x_alpha_nus_a .< 1.0)
        @test x_alpha_nus_a ≈ x_alpha_nus_b
        x_alpha_nus_rep =
            gen_samples(DigitalNetB2(3; randomize="NUS", seed=7, replications=2, alpha=2), 8)
        @test size(x_alpha_nus_rep) == (2, 8, 3)
        @test all(0.0 .<= x_alpha_nus_rep .< 1.0)
        if QMC._HAS_DNB2_FUSED[]
            old_fused = QMC._HAS_DNB2_FUSED[]
            try
                QMC._HAS_DNB2_FUSED[] = true
                x_alpha_fused =
                    gen_samples(DigitalNetB2(3; randomize="LMS_DS", seed=7, alpha=2), 8)
                QMC._HAS_DNB2_FUSED[] = false
                x_alpha_unfused =
                    gen_samples(DigitalNetB2(3; randomize="LMS_DS", seed=7, alpha=2), 8)
                @test x_alpha_fused ≈ x_alpha_unfused
            finally
                QMC._HAS_DNB2_FUSED[] = old_fused
            end
        end

        # LDData-style text sources: local file paths and QMCPy-compatible names.
        mktemp() do path, io
            write(io, "# base\n2\n# d_limit\n2\n# n_limit\n16\n# bit precision\n32\n")
            for j in 1:2
                write(io, join(string.(Int.(dd.direction_nums[j, :])), ' '))
                write(io, "\n")
            end
            flush(io)

            dd_file = DigitalNetB2(2; randomize="none", seed=1, generating_matrices=path)
            @test gen_samples(dd_file, 16) ≈ gen_samples(dd, 16)
            @test dd_file.n_limit == 16
            @test_throws ArgumentError gen_samples(dd_file, 17)
        end
        mktemp() do path, io
            write(io, "# base\n2\n# d_limit\n2\n# n_limit\n16\n# bit precision\n64\n")
            for _ in 1:2
                write(io, "1 2 4 8\n")
            end
            flush(io)

            dd_file64 =
                DigitalNetB2(1; randomize="none", seed=1, alpha=2, generating_matrices=path)
            @test dd_file64.source_bits == 64
            @test dd_file64.t == 64
            @test size(gen_samples(dd_file64, 4)) == (4, 1)
        end
        mktemp() do path, io
            write(io, "# base\n2\n# d_limit\n1024\n# n_limit\n2\n# bit precision\n32\n")
            for _ in 1:1024
                write(io, "1\n")
            end
            flush(io)

            @test_throws ArgumentError DigitalNetB2(
                513;
                randomize="none",
                alpha=2,
                generating_matrices=path,
            )
        end
        mktemp() do path, io
            write(io, "# base\n2\n# d_limit\n1026\n# n_limit\n2\n# bit precision\n32\n")
            for _ in 1:1026
                write(io, "1\n")
            end
            flush(io)

            dd_file_alpha_limit =
                DigitalNetB2(513; randomize="none", alpha=2, generating_matrices=path)
            @test dd_file_alpha_limit.source_bits == 32
            @test dd_file_alpha_limit.n_limit == 2
            @test size(gen_samples(dd_file_alpha_limit, 2)) == (2, 513)
        end

        dd_default = DigitalNetB2(3; randomize="none", seed=7)
        for ref in (
            "joe_kuo.6.21201.txt",
            "joe_kuo.6.1024.txt",
            "dnet/joe_kuo.6.21201.txt",
            "https://github.com/QMCSoftware/LDData/tree/main/dnet/joe_kuo.6.21201.txt",
            "https://raw.githubusercontent.com/QMCSoftware/LDData/main/dnet/joe_kuo.6.21201.txt",
        )
            dd_named = DigitalNetB2(3; randomize="none", seed=7, generating_matrices=ref)
            @test gen_samples(dd_named, 16) ≈ gen_samples(dd_default, 16)
        end

        # The custom matrix precision limits the allowable sample window.
        dd_short = DigitalNetB2(
            2;
            randomize="none",
            generating_matrices=Int.(dd.direction_nums[:, 1:3] .>> 29),
        )
        @test size(gen_samples(dd_short, 8)) == (8, 2)
        @test_throws ArgumentError gen_samples(dd_short, 9)
        @test_throws ArgumentError gen_samples(dd_short, 4; n_start=5)

        # Higher-order bundled data uses raw Sobol' dimensions, so the default
        # Joe-Kuo table tops out at floor(21201 / alpha) output dimensions. The
        # 513-dim alpha=2 case (1026 raw dims) now resolves from the bundled
        # table, where it previously exceeded the old 1024-dim cap.
        dd_alpha_limit = DigitalNetB2(512; randomize="none", alpha=2)
        @test size(gen_samples(dd_alpha_limit, 2)) == (2, 512)
        @test size(gen_samples(DigitalNetB2(513; randomize="none", alpha=2), 2)) == (2, 513)

        # Explicit custom matrices remain supported for higher-order interlacing
        # as long as enough raw rows are supplied.
        dd_alpha_custom =
            DigitalNetB2(513; randomize="none", alpha=2, generating_matrices=ones(Int, 1026, 1))
        @test size(gen_samples(dd_alpha_custom, 2)) == (2, 513)

        @test_throws ArgumentError DigitalNetB2(2; generating_matrices=ones(Int, 1, 4))
        @test_throws ArgumentError DigitalNetB2(2; generating_matrices=ones(Int, 2, 33))
        @test_throws ArgumentError DigitalNetB2(2; generating_matrices=zeros(Int, 2, 4))
        @test_throws ArgumentError DigitalNetB2(2; generating_matrices=fill(1 << 20, 2, 8))
        @test_throws ArgumentError DigitalNetB2(2; randomize="none", t=31)
        @test_throws ArgumentError DigitalNetB2(2; randomize="none", t=65)
        @test_throws ArgumentError DigitalNetB2(2; generating_matrices=V8, t=7)
        @test_throws ArgumentError DigitalNetB2(
            2;
            generating_matrices=fill(BigInt(typemax(UInt64)) + 1, 2, 4),
        )
        @test_throws ArgumentError DigitalNetB2(
            3;
            randomize="none",
            alpha=2,
            generating_matrices=V8,
        )
    end

    @testset "DigitalNetB2 high-dimensional (bundled 21201 table)" begin
        # Dimensions above the embedded 1024 now come from the bundled binary
        # table (offline), matching QMCPy's reach of 21201 raw dimensions.
        dn_hi = DigitalNetB2(1500; randomize="none", seed=1)
        x_hi = gen_samples(dn_hi, 8)
        @test size(x_hi) == (8, 1500)
        @test all(0 .<= x_hi .< 1)

        # Nesting: the binary extension's first 1024 dimensions are bit-for-bit
        # identical to the embedded table, so a 1500-dim net's first 1024 columns
        # equal a 1024-dim net's columns exactly (deterministic, randomize="none").
        x_lo = gen_samples(DigitalNetB2(1024; randomize="none", seed=1), 8)
        @test x_hi[:, 1:1024] == x_lo

        # Higher-order interlacing past the old 1024 raw-dimension cap.
        dn_ho = DigitalNetB2(600; randomize="none", seed=1, alpha=2)  # 1200 raw dims
        @test size(gen_samples(dn_ho, 8)) == (8, 600)

        # The maximum bundled dimension constructs; one past it throws.
        @test size(gen_samples(DigitalNetB2(21201; randomize="none"), 2)) == (2, 21201)
        @test_throws ArgumentError DigitalNetB2(21202)
        @test_throws ArgumentError DigitalNetB2(10601; alpha=2)  # 21202 raw dims

        # Explicitly naming the default 21201 LDData table stays offline (uses the
        # bundle, no download) for dimensions within the bundled range.
        dn_named = DigitalNetB2(
            1500;
            randomize="none",
            seed=1,
            generating_matrices="joe_kuo.6.21201.txt",
        )
        @test gen_samples(dn_named, 8) == x_hi
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

        # Replications: R×n×d, independent randomizations sharing the base
        # sequence (mirrors Lattice/DigitalNetB2).
        @test Halton(2; replications=nothing).replications === nothing
        dd_rep = Halton(3; randomize=true, seed=7, replications=4)
        xrep = gen_samples(dd_rep, 64)
        @test size(xrep) == (4, 64, 3)
        @test all(0.0 .<= xrep .< 1.0)
        @test xrep[1, :, :] != xrep[2, :, :]      # distinct randomizations
        # Without randomization the R copies are identical (no shift to differ)
        dd_rep0 = Halton(3; randomize=false, replications=3)
        xrep0 = gen_samples(dd_rep0, 32)
        @test size(xrep0) == (3, 32, 3)
        @test xrep0[1, :, :] == xrep0[2, :, :]
        @test_throws ArgumentError Halton(2; replications=0)
        @test_throws ArgumentError Halton(2; replications=-1)
    end

    @testset "Owen/NUS Scrambling" begin
        dd = DigitalNetB2(3; randomize="NUS", seed=42)
        x = gen_samples(dd, 256)
        @test size(x) == (256, 3)
        @test all(0.0 .<= x .< 1.0)
        dd_none = DigitalNetB2(3; randomize="none")
        x_none = gen_samples(dd_none, 256)
        @test x != x_none
        # Replicated NUS
        dd_rep = DigitalNetB2(3; randomize="NUS", seed=42, replications=4)
        xr = gen_samples(dd_rep, 64)
        @test size(xr) == (4, 64, 3)
        @test all(0.0 .<= xr .< 1.0)
        @test xr[1, :, :] != xr[2, :, :]
    end

    @testset "Kronecker" begin
        kr = Kronecker(3; seed=42)
        x = gen_samples(kr, 1000)
        @test size(x) == (1000, 3)
        @test all(0.0 .<= x .< 1.0)
        @test abs(mean(x) - 0.5) < 0.05
        x2 = gen_samples(kr, 500; n_start=500)
        @test size(x2) == (500, 3)
    end

    @testset "n_start windowed sampling" begin
        # Lattice
        dd = Lattice(2; randomize=false, order="natural")
        x1 = gen_samples(dd, 64)
        x2 = gen_samples(dd, 32; n_start=32)
        @test size(x2) == (32, 2)
        # DigitalNetB2
        dd2 = DigitalNetB2(2; randomize="none")
        x3 = gen_samples(dd2, 32; n_start=0)
        @test size(x3) == (32, 2)
        # Kronecker
        kr = Kronecker(2; seed=1)
        x4 = gen_samples(kr, 50; n_start=100)
        @test size(x4) == (50, 2)
        @test all(0.0 .<= x4 .< 1.0)
    end
end
