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
end
