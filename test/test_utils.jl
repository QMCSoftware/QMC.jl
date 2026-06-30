@testset "Utilities" begin
    @testset "FWHT (natural order)" begin
        # Known natural-order Hadamard transforms: y = Hₙ · x.
        @test fwht([1.0, 1.0]) == [2.0, 0.0]
        @test fwht([1.0, 0.0, 0.0, 0.0]) == [1.0, 1.0, 1.0, 1.0]
        @test fwht([1.0, 2.0, 3.0, 4.0]) == [10.0, -2.0, -4.0, 0.0]
        @test fwht([1.0, 1.0, 1.0, 1.0]) == [4.0, 0.0, 0.0, 0.0]

        x = Float64[3, 1, 4, 1, 5, 9, 2, 6]
        # Involution: Hₙ² = n·I ⇒ fwht(fwht(x)) = n·x.
        @test fwht(fwht(x)) ≈ 8 .* x
        # ifwht inverts fwht (both directions).
        @test QuasiMC.ifwht(fwht(x)) ≈ x
        @test fwht(QuasiMC.ifwht(x)) ≈ x

        # In-place variants mutate and return the same object.
        z = copy(x)
        @test fwht!(z) === z
        @test z == fwht(x)
        w = copy(z)
        @test ifwht!(w) === w
        @test w ≈ x

        g = gpu_fwht(x)
        @test g == fwht(x)
        @test x == Float64[3, 1, 4, 1, 5, 9, 2, 6]
        h = copy(x)
        @test gpu_fwht!(h) === h
        @test h == g

        # Non-power-of-2 length is rejected.
        @test_throws AssertionError fwht([1.0, 2.0, 3.0])
    end

    @testset "FWHT (sequency order)" begin
        # Sequency order is a permutation of the natural-order spectrum.
        x = Float64[3, 1, 4, 1, 5, 9, 2, 6]
        @test sort(QuasiMC.fwht_sequency(x)) ≈ sort(fwht(x))
        # A constant vector has only a DC term, at index 1 in either ordering.
        @test QuasiMC.fwht_sequency([1.0, 1.0, 1.0, 1.0]) ≈ [4.0, 0.0, 0.0, 0.0]
    end

    @testset "FWHT (2D)" begin
        # Row-then-column transform of the 2×2 all-ones matrix: only the DC
        # corner survives, equal to the total sum.
        X = ones(2, 2)
        QuasiMC.fwht_2d!(X)
        @test X == [4.0 0.0; 0.0 0.0]
    end

    @testset "to_bin / to_float" begin
        # Binary expansions of dyadic rationals.
        @test to_bin(0.5, 4) == [1, 0, 0, 0]
        @test to_bin(0.25, 4) == [0, 1, 0, 0]
        @test to_bin(0.75, 4) == [1, 1, 0, 0]
        @test to_bin(0.625, 4) == [1, 0, 1, 0]
        @test to_bin(0.0, 4) == [0, 0, 0, 0]
        # to_float inverts to_bin for values with finite expansions ≤ m bits.
        for x in (0.0, 0.25, 0.5, 0.625, 0.75)
            @test to_float(to_bin(x, 8)) ≈ x
        end
        # Out-of-range inputs are rejected.
        @test_throws AssertionError to_bin(1.0, 4)
        @test_throws AssertionError to_bin(-0.1, 4)
    end

    @testset "bro_fft / bro_ifft" begin
        # bro_fft = FFT of the bit-reversed input; a constant gives a pure DC term.
        @test bro_fft([1.0, 1.0, 1.0, 1.0]) ≈ ComplexF64[4, 0, 0, 0]
        @test bro_fft([1.0, 2.0, 3.0, 4.0]) ≈ ComplexF64[10, -1 + 1im, -4, -1 - 1im]
        # Bit reversal is an involution, so bro_ifft inverts bro_fft.
        x = Float64[3, 1, 4, 1, 5, 9, 2, 6]
        @test bro_ifft(bro_fft(x)) ≈ x
    end

    @testset "periodize" begin
        x = [0.0 0.25; 0.5 0.75]
        @test periodize(x, :NONE) == x
        # All smooth transforms fix the endpoints and map the midpoint to itself.
        for pt in (:C1, :C1SIN, :C2SIN, :C3)
            @test periodize(x, pt)[2, 1] ≈ 0.5     # x = 0.5 ↦ 0.5
        end
        @test periodize([0.0 1.0], :C3) ≈ [0.0 1.0]
        # Baker's (tent) transform: 1 - |2x - 1|.
        @test periodize([0.0 0.25 0.5 0.75], :BAKER) ≈ [0.0 0.5 1.0 0.5]
        # Unknown transforms error.
        @test_throws ErrorException periodize(x, :BOGUS)
    end

    @testset "FWHT (orthonormal)" begin
        # Matches QMCPy's `fwht` convention: H_n*x / sqrt(n) (orthonormal).
        @test QuasiMC._fwht_ortho([1.0, 1.0]) ≈ [sqrt(2.0), 0.0]
        @test QuasiMC._fwht_ortho([1.0, 0.0, 0.0, 0.0]) ≈ [0.5, 0.5, 0.5, 0.5]
        @test QuasiMC._fwht_ortho([1.0, 2.0, 3.0, 4.0]) ≈ [5.0, -1.0, -2.0, 0.0]
        @test QuasiMC._fwht_ortho([1.0, 1.0, 1.0, 1.0]) ≈ [2.0, 0.0, 0.0, 0.0]

        x = Float64[3, 1, 4, 1, 5, 9, 2, 6]
        # Orthonormal => norm-preserving, and the DC coefficient equals mean*sqrt(n).
        @test norm(QuasiMC._fwht_ortho(x)) ≈ norm(x)
        @test QuasiMC._fwht_ortho(x)[1] ≈ sum(x) / sqrt(length(x))

        # Doubling identity (all-ones weights): _fwht_ortho([x_1; x_2]) for equal
        # halves equals [y_1.+y_2; y_1.-y_2]/sqrt(2). This is the incremental-update
        # relation the guaranteed cubature relies on.
        x1 = Float64[1, 2, 3, 4]
        x2 = Float64[5, 6, 7, 8]
        y1 = QuasiMC._fwht_ortho(x1)
        y2 = QuasiMC._fwht_ortho(x2)
        @test QuasiMC._fwht_ortho(vcat(x1, x2)) ≈ vcat(y1 .+ y2, y1 .- y2) ./ sqrt(2.0)
    end

    @testset "ytilde incremental doubling" begin
        # The incremental update must equal the orthonormal transform of the full
        # point set - the relation that lets the cubature reuse work across
        # doublings - and the first coefficient must track the running mean.
        y = Float64[3, 1, 4, 1, 5, 9, 2, 6, 5, 3, 5, 8, 9, 7, 9, 3]  # 16 = 2^4
        N = 4
        yt = QuasiMC._ytilde_init(y[1:N])
        off = N
        cur = N
        for _ in 1:2  # 4 -> 8 -> 16
            yt = QuasiMC._ytilde_double(yt, y[(off + 1):(off + cur)])
            off += cur
            cur *= 2
        end
        @test yt ≈ QuasiMC._ytilde_init(y[1:off])
        @test yt[1] ≈ sum(y[1:off]) / off
    end

    @testset "kappanumap (coefficient ordering)" begin
        # Reference outputs computed from QMCPy's own _update_kappanumap (scalar).
        # The comparison uses only the magnitude ordering of ytilde, so rounded
        # literals reproduce the exact permutation.
        yt3 = [-0.535669, 0.361595, 1.304, 0.947081, -0.703735, -1.265421, -0.623274, 0.041326]
        k3 = QuasiMC._update_kappanumap!(collect(0:7), yt3, 2, 0, 3)
        @test k3 == [0, 5, 2, 3, 4, 1, 6, 7]

        yt4 = [
            -2.325,
            -0.2188,
            -1.2459,
            -0.7323,
            -0.5443,
            -0.3163,
            0.4116,
            1.0425,
            -0.1285,
            1.3665,
            -0.6652,
            0.3515,
            0.9035,
            0.094,
            -0.7435,
            -0.9217,
        ]
        k4 = QuasiMC._update_kappanumap!(collect(0:15), yt4, 3, 0, 4)
        @test k4 == [0, 9, 2, 7, 12, 5, 14, 3, 8, 1, 10, 15, 4, 13, 6, 11]

        # Structural invariants: output is a permutation of 0:n-1, and the first
        # (power-of-two) index is never moved.
        @test sort(k3) == collect(0:7)
        @test sort(k4) == collect(0:15)
        @test k3[1] == 0 && k4[1] == 0
    end

    @testset "bernoulli_poly" begin
        # k=0: B_0(x) = 1 everywhere.
        @test bernoulli_poly(0, 0.0) == 1.0
        @test bernoulli_poly(0, 0.5) == 1.0
        @test bernoulli_poly(0, 1.0) == 1.0

        # k=1: B_1(x) = x - 1/2.
        @test bernoulli_poly(1, 0.0) == -0.5
        @test bernoulli_poly(1, 0.5) == 0.0
        @test bernoulli_poly(1, 1.0) == 0.5

        # k=2: B_2(x) = x² - x + 1/6; B_2(1/2) = -1/12.
        @test bernoulli_poly(2, 0.5) ≈ -1/12 atol=1e-15
        @test bernoulli_poly(2, 0.0) ≈ 1/6 atol=1e-15
        @test bernoulli_poly(2, 1.0) ≈ 1/6 atol=1e-15  # B_k(0) = B_k(1) for k ≥ 2

        # k=4: B_4(0) = -1/30.
        @test bernoulli_poly(4, 0.0) ≈ -1/30 atol=1e-15

        # k=6: B_6(0) = 1/42.
        @test bernoulli_poly(6, 0.0) ≈ 1/42 atol=1e-14

        # Unsupported k raises an error.
        @test_throws ErrorException bernoulli_poly(7, 0.5)

        # bernoulli_number is B_k(0).
        for k in 0:6
            @test QuasiMC.bernoulli_number(k) == bernoulli_poly(k, 0.0)
        end

        # lattice_kernel_component: alpha=1 uses B_2, alpha=2 uses B_4, alpha=3 uses B_6.
        x = 0.3
        # sign_factor = (-1)^(alpha+1): alpha=1 → +1, alpha=2 → -1.
        @test QuasiMC.lattice_kernel_component(x, 1) ≈ (2π)^2 / 2 * bernoulli_poly(2, x) atol=1e-12
        @test QuasiMC.lattice_kernel_component(x, 2) ≈ -(2π)^4 / 24 * bernoulli_poly(4, x) atol=1e-12
        # alpha out of range raises an error.
        @test_throws ErrorException QuasiMC.lattice_kernel_component(x, 0)
        @test_throws ErrorException QuasiMC.lattice_kernel_component(x, 4)
        # Fractional part: x=1.3 same as x=0.3.
        @test QuasiMC.lattice_kernel_component(1.3, 2) ≈
              QuasiMC.lattice_kernel_component(0.3, 2) atol=1e-12
    end

    @testset "DisplayTable" begin
        rows = [(n=64, label="small", error=0.012345), (n=128, label="<large>", error=0.001234)]
        table = display_table(
            rows;
            columns=[:n, :label, :error],
            headers=["N", "case", "error"],
            formatters=(error=x -> string(round(x; sigdigits=4)),),
            caption="Convergence",
        )
        @test table isa DisplayTable
        txt = sprint(show, table)
        @test startswith(txt, "Convergence\n")
        @test occursin("  N  case        error", txt)
        @test occursin(" 64  small     0.01234", txt)
        @test occursin("128  <large>  0.001234", txt)

        html = sprint(io -> show(io, MIME("text/html"), table))
        @test occursin("<caption>Convergence</caption>", html)
        @test occursin("<th>N</th>", html)
        @test occursin("text-align:right", html)
        @test occursin("text-align:left", html)
        @test occursin("&lt;large&gt;", html)

        empty_table = display_table(NamedTuple[]; columns=[:n], headers=["N"])
        @test sprint(show, empty_table) == ""
        @test_throws ArgumentError display_table(NamedTuple[])
        @test_throws ArgumentError display_table(rows; columns=[:missing])
        @test_throws ArgumentError display_table(rows; columns=[:n], headers=["N", "extra"])
        @test_throws ArgumentError display_table([(n=1,), (value=2,)])
    end

    @testset "IterationRows/Log empty show and elapsed formatting" begin
        empty_rows = iterations(IterationLog())
        @test sprint(show, empty_rows) == "IterationRows (empty)"
        @test sprint(io -> show(io, MIME("text/html"), empty_rows)) ==
              "<p>IterationRows (empty)</p>"
        @test sprint(show, IterationLog()) == "IterationLog (empty)"
        log_nan = IterationLog()
        push!(log_nan; n=10, solution=1.0, error_bound=0.1, tol=0.1, elapsed=NaN)
        txt_nan = sprint(show, log_nan)
        @test occursin("-", txt_nan)
        html_nan = sprint(io -> show(io, MIME("text/html"), log_nan))
        @test occursin("<caption>IterationLog (1 iterations)</caption>", html_nan)
        log_tiny = IterationLog()
        push!(log_tiny; n=10, solution=1.0, error_bound=0.1, tol=0.1, elapsed=1e-5)
        txt_tiny = sprint(show, log_tiny)
        @test occursin("e", txt_tiny)
        @test QuasiMC._format_iteration_entry(:label, :custom) == "custom"
    end
end
