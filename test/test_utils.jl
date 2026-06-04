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
end
