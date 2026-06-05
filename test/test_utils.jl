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
        @test QMC.ifwht(fwht(x)) ≈ x
        @test fwht(QMC.ifwht(x)) ≈ x

        # In-place variants mutate and return the same object.
        z = copy(x)
        @test fwht!(z) === z
        @test z == fwht(x)
        w = copy(z)
        @test ifwht!(w) === w
        @test w ≈ x

        # Non-power-of-2 length is rejected.
        @test_throws AssertionError fwht([1.0, 2.0, 3.0])
    end

    @testset "FWHT (sequency order)" begin
        # Sequency order is a permutation of the natural-order spectrum.
        x = Float64[3, 1, 4, 1, 5, 9, 2, 6]
        @test sort(QMC.fwht_sequency(x)) ≈ sort(fwht(x))
        # A constant vector has only a DC term, at index 1 in either ordering.
        @test QMC.fwht_sequency([1.0, 1.0, 1.0, 1.0]) ≈ [4.0, 0.0, 0.0, 0.0]
    end

    @testset "FWHT (2D)" begin
        # Row-then-column transform of the 2×2 all-ones matrix: only the DC
        # corner survives, equal to the total sum.
        X = ones(2, 2)
        QMC.fwht_2d!(X)
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
        @test QMC._fwht_ortho([1.0, 1.0]) ≈ [sqrt(2.0), 0.0]
        @test QMC._fwht_ortho([1.0, 0.0, 0.0, 0.0]) ≈ [0.5, 0.5, 0.5, 0.5]
        @test QMC._fwht_ortho([1.0, 2.0, 3.0, 4.0]) ≈ [5.0, -1.0, -2.0, 0.0]
        @test QMC._fwht_ortho([1.0, 1.0, 1.0, 1.0]) ≈ [2.0, 0.0, 0.0, 0.0]

        x = Float64[3, 1, 4, 1, 5, 9, 2, 6]
        # Orthonormal => norm-preserving, and the DC coefficient equals mean*sqrt(n).
        @test norm(QMC._fwht_ortho(x)) ≈ norm(x)
        @test QMC._fwht_ortho(x)[1] ≈ sum(x) / sqrt(length(x))

        # Doubling identity (all-ones weights): _fwht_ortho([x_1; x_2]) for equal
        # halves equals [y_1.+y_2; y_1.-y_2]/sqrt(2). This is the incremental-update
        # relation the guaranteed cubature relies on.
        x1 = Float64[1, 2, 3, 4]
        x2 = Float64[5, 6, 7, 8]
        y1 = QMC._fwht_ortho(x1)
        y2 = QMC._fwht_ortho(x2)
        @test QMC._fwht_ortho(vcat(x1, x2)) ≈ vcat(y1 .+ y2, y1 .- y2) ./ sqrt(2.0)
    end

    @testset "ytilde incremental doubling" begin
        # The incremental update must equal the orthonormal transform of the full
        # point set - the relation that lets the cubature reuse work across
        # doublings - and the first coefficient must track the running mean.
        y = Float64[3, 1, 4, 1, 5, 9, 2, 6, 5, 3, 5, 8, 9, 7, 9, 3]  # 16 = 2^4
        N = 4
        yt = QMC._ytilde_init(y[1:N])
        off = N
        cur = N
        for _ in 1:2  # 4 -> 8 -> 16
            yt = QMC._ytilde_double(yt, y[(off + 1):(off + cur)])
            off += cur
            cur *= 2
        end
        @test yt ≈ QMC._ytilde_init(y[1:off])
        @test yt[1] ≈ sum(y[1:off]) / off
    end

    @testset "kappanumap (coefficient ordering)" begin
        # Reference outputs computed from QMCPy's own _update_kappanumap (scalar).
        # The comparison uses only the magnitude ordering of ytilde, so rounded
        # literals reproduce the exact permutation.
        yt3 = [-0.535669, 0.361595, 1.304, 0.947081, -0.703735, -1.265421, -0.623274, 0.041326]
        k3 = QMC._update_kappanumap!(collect(0:7), yt3, 2, 0, 3)
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
        k4 = QMC._update_kappanumap!(collect(0:15), yt4, 3, 0, 4)
        @test k4 == [0, 9, 2, 7, 12, 5, 14, 3, 8, 1, 10, 15, 4, 13, 6, 11]

        # Structural invariants: output is a permutation of 0:n-1, and the first
        # (power-of-two) index is never moved.
        @test sort(k3) == collect(0:7)
        @test sort(k4) == collect(0:15)
        @test k3[1] == 0 && k4[1] == 0
    end
end
