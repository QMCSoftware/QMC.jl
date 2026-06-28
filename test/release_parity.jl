using Test
using QuasiMC

include(joinpath(@__DIR__, "qmcpy23_release_parity_fixture.jl"))

function dense_covariance(dim::Int)
    cov = fill(0.5, dim, dim)
    for i in 1:dim
        cov[i, i] = 1.0
    end
    return cov
end

function oracle_uniform_matrix(rows::Int, dim::Int; offset::Int=0)
    out = Matrix{Float64}(undef, rows, dim)
    for i in 1:rows, j in 1:dim
        numer = mod(37 * i + 17 * j + 13 * offset, 997)
        out[i, j] = (numer + 0.5) / 997.0
    end
    return out
end

function qmcpy_genz_coeffs(dim::Int)
    base = (collect(1:dim) .- 0.5) ./ dim
    return 4.5 .* base ./ sum(base)
end

function flat_row_major(x)
    arr = Array(x)
    ndims(arr) == 0 && return [Float64(arr)]
    ndims(arr) == 1 && return Float64.(vec(arr))
    return Float64.(vec(permutedims(arr)))
end

function assert_exact_entry(local_value, entry, label::AbstractString)
    expected_shape = Tuple(Int.(entry["shape"]))
    @test size(local_value) == expected_shape
    expected = Float64.(entry["values"])
    actual = flat_row_major(local_value)
    @test length(actual) == length(expected)
    atol = Float64(entry["atol"])
    rtol = Float64(entry["rtol"])
    @testset "$(label)" begin
        for (a, b) in zip(actual, expected)
            @test isapprox(a, b; atol=atol, rtol=rtol)
        end
    end
end

effective_tol(ref_solution, abs_tol, rel_tol) = max(abs_tol, rel_tol * abs(ref_solution))

function assert_solution_within_qmcpy_tolerance(local_solution, ref_solution, abs_tol, rel_tol)
    allowed = 2 * effective_tol(ref_solution, abs_tol, rel_tol)
    @test abs(local_solution - ref_solution) <= allowed
end

function exact_cases()
    dd_lattice = Lattice(2; randomize=false, order="RADICAL INVERSE")
    dd_dnb2 = DigitalNetB2(2; randomize="none", order="RADICAL INVERSE", graycode=false)
    dd_halton = Halton(2; randomize=false, generalize=false)

    return Dict(
        "gen_samples" => Dict(
            "Lattice base deterministic" => gen_samples(dd_lattice, 4),
            "DigitalNetB2 base deterministic" => gen_samples(dd_dnb2, 4),
            "Halton base deterministic" => gen_samples(dd_halton, 4),
        ),
        "spawn" => Dict(
            "Lattice spawn deterministic" => gen_samples(spawn_dd(dd_lattice, 4), 4),
            "DigitalNetB2 spawn deterministic" => gen_samples(spawn_dd(dd_dnb2, 4), 4),
            "Halton spawn deterministic" => gen_samples(spawn_dd(dd_halton, 4), 4),
        ),
        "transform" => Dict(
            "Gaussian d=3 rows=4" => transform(
                Gaussian(IIDStdUniform(3; seed=42); decomp_type=:Cholesky),
                oracle_uniform_matrix(4, 3; offset=1),
            ),
            "Gaussian(dense) d=50 rows=3" => transform(
                Gaussian(
                    IIDStdUniform(50; seed=42);
                    covariance=dense_covariance(50),
                    decomp_type=:Cholesky,
                ),
                oracle_uniform_matrix(3, 50; offset=3),
            ),
            "StudentT d=1 rows=4" => transform(
                StudentT(IIDStdUniform(1; seed=42)),
                oracle_uniform_matrix(4, 1; offset=4),
            ),
            "JohnsonsSU d=10 rows=4" => transform(
                JohnsonsSU(IIDStdUniform(10; seed=42)),
                oracle_uniform_matrix(4, 10; offset=5),
            ),
        ),
        "evaluate" => Dict(
            "Keister rows=4" => begin
                dd = IIDStdUniform(3; seed=42)
                tm = Gaussian(dd; covariance=0.5, decomp_type=:Cholesky)
                f = Keister(tm)
                evaluate(f, transform(tm, oracle_uniform_matrix(4, 3; offset=11)))
            end,
            "Genz(oscillatory) rows=4" => begin
                dd = IIDStdUniform(3; seed=42)
                tm = Uniform(dd)
                f = Genz(tm; kind=:oscillatory, a=qmcpy_genz_coeffs(3), u=zeros(3))
                evaluate(f, oracle_uniform_matrix(4, 3; offset=12))
            end,
            "BoxIntegral d=10 rows=4" => begin
                dd = IIDStdUniform(10; seed=42)
                f = BoxIntegral(Uniform(dd); s=1.0)
                evaluate(f, oracle_uniform_matrix(4, 10; offset=13))
            end,
            "Linear0 d=10 rows=4" => begin
                dd = IIDStdUniform(10; seed=42)
                f = Linear0(Uniform(dd))
                evaluate(f, oracle_uniform_matrix(4, 10; offset=14))
            end,
            "Genz(gaussian_peak) d=10 rows=4" => begin
                dd = IIDStdUniform(10; seed=42)
                f = Genz(Uniform(dd); kind=:gaussian_peak)
                evaluate(f, oracle_uniform_matrix(4, 10; offset=15))
            end,
            "Genz(continuous) d=10 rows=4" => begin
                dd = IIDStdUniform(10; seed=42)
                f = Genz(Uniform(dd); kind=:continuous)
                evaluate(f, oracle_uniform_matrix(4, 10; offset=16))
            end,
        ),
    )
end

function run_release_parity()
    fixture = QMCPY23_RELEASE_PARITY

    @testset "Release Parity: exact deterministic oracles" begin
        cases = exact_cases()
        for group_name in ("gen_samples", "spawn", "transform", "evaluate")
            group_fixture = fixture[group_name]
            group_cases = cases[group_name]
            @testset "$(group_name)" begin
                for name in sort!(collect(keys(group_fixture)))
                    assert_exact_entry(group_cases[name], group_fixture[name], name)
                end
            end
        end
    end

    @testset "Release Parity: stopping criteria" begin
        stop_fixture = fixture["stopping_criteria"]

        @testset "CubMCCLT Keister rel_tol" begin
            ref = stop_fixture["CubMCCLT Keister rel_tol"]
            dd = IIDStdUniform(3; seed=42)
            f = Keister(Gaussian(dd; covariance=0.5))
            result = integrate(CubMCCLT(f; abs_tol=1.0, rel_tol=0.01))
            assert_solution_within_qmcpy_tolerance(
                result.solution,
                Float64(ref["solution"]),
                Float64(ref["abs_tol"]),
                Float64(ref["rel_tol"]),
            )
            @test result.data[:n_total] == Int(ref["n_total"])
            @test result.data[:n_total] >= 256
        end

        @testset "CubQMCNetG Keister" begin
            ref = stop_fixture["CubQMCNetG Keister"]
            dd = DigitalNetB2(3; seed=42, graycode=false)
            f = Keister(Gaussian(dd; covariance=0.5))
            result = integrate(CubQMCNetG(f; abs_tol=0.05, n_init=2^8, n_max=2^12))
            assert_solution_within_qmcpy_tolerance(
                result.solution,
                Float64(ref["solution"]),
                Float64(ref["abs_tol"]),
                Float64(ref["rel_tol"]),
            )
            @test result.data[:n] == Int(ref["n"])
            @test result.data[:n_total] == Int(ref["n_total"])
            @test result.data[:n_total] == result.data[:n]
            @test result.data[:error_bound] <= 0.05 + 1e-12
        end

        @testset "CubQMCRepStudentT Keister" begin
            ref = stop_fixture["CubQMCRepStudentT Keister"]
            dd = DigitalNetB2(3; seed=42, replications=8)
            f = Keister(Gaussian(dd; covariance=0.5))
            result = integrate(CubQMCRepStudentT(f; abs_tol=0.05, n_init=2^8, n_limit=2^12))
            assert_solution_within_qmcpy_tolerance(
                result.solution,
                Float64(ref["solution"]),
                Float64(ref["abs_tol"]),
                Float64(ref["rel_tol"]),
            )
            @test result.data[:n_total] == Int(ref["n_total"])
            @test result.data[:n_rep] == Int(ref["n_rep"])
            @test result.data[:n_per_rep] == Int(ref["n_rep"])
            @test result.data[:replications] == Int(ref["replications"])
            @test result.data[:n_total] == result.data[:n_per_rep] * result.data[:replications]
        end
    end

    @testset "Release Parity: multilevel accounting" begin
        ref = fixture["multilevel"]["CubMLQMC AsianOption"]
        tm = GeometricBrownianMotion(
            Lattice(16; seed=7, replications=8);
            volatility=0.2,
            start_price=100.0,
            interest_rate=0.05,
            t_final=1.0,
        )
        f = FinancialOptionML(tm; d_coarsest=4, strike_price=100.0)
        result = integrate(CubMLQMC(f; abs_tol=1.0, n_init=32, levels_min=2, levels_max=3))

        assert_solution_within_qmcpy_tolerance(
            result.solution,
            Float64(ref["solution"]),
            Float64(ref["abs_tol"]),
            Float64(ref["rel_tol"]),
        )
        @test result.data[:levels] == Int(ref["levels"])
        @test result.data[:n_total] >= Int(ref["n_total"])
        @test length(result.data[:n_level]) == length(ref["n_level"])
        @test all(collect(Int, result.data[:n_level]) .>= Int.(ref["n_level"]))
        @test result.data[:replications] == Int(ref["replications"])
        @test result.data[:n_total] == result.data[:replications] * sum(result.data[:n_level])
    end

    @testset "Release Parity: continuation accounting" begin
        ref = fixture["continuation"]["CubMLQMCCont AsianOption"]
        tm = GeometricBrownianMotion(
            Lattice(16; seed=7, replications=8);
            volatility=0.2,
            start_price=100.0,
            interest_rate=0.05,
            t_final=1.0,
        )
        f = FinancialOptionML(tm; d_coarsest=4, strike_price=100.0)
        result = integrate(
            CubMLQMCCont(f; abs_tol=1.0, n_init=32, levels_min=2, levels_max=3, n_tols=3),
        )

        assert_solution_within_qmcpy_tolerance(
            result.solution,
            Float64(ref["solution"]),
            Float64(ref["abs_tol"]),
            Float64(ref["rel_tol"]),
        )
        @test result.data[:levels] == Int(ref["levels"])
        @test result.data[:n_total] >= Int(ref["n_total"])
        @test length(result.data[:n_level]) == length(ref["n_level"])
        @test all(collect(Int, result.data[:n_level]) .>= Int.(ref["n_level"]))
        @test result.data[:replications] == Int(ref["replications"])
        @test result.data[:n_total] == result.data[:replications] * sum(result.data[:n_level])
    end

    @testset "Release Parity: resume semantics" begin
        ref = fixture["resume"]["CubQMCRepStudentT Keister"]
        dd = DigitalNetB2(3; seed=42, replications=8)
        f = Keister(Gaussian(dd; covariance=0.5))

        loose = integrate(CubQMCRepStudentT(f; abs_tol=0.5, n_init=2^8, n_limit=2^9))
        resumed = integrate(
            CubQMCRepStudentT(f; abs_tol=0.05, n_init=2^8, n_limit=2^12);
            resume=loose.data,
        )

        loose_ref = ref["loose"]
        resumed_ref = ref["resumed"]

        assert_solution_within_qmcpy_tolerance(
            loose.solution,
            Float64(loose_ref["solution"]),
            Float64(loose_ref["abs_tol"]),
            Float64(loose_ref["rel_tol"]),
        )
        assert_solution_within_qmcpy_tolerance(
            resumed.solution,
            Float64(resumed_ref["solution"]),
            Float64(resumed_ref["abs_tol"]),
            Float64(resumed_ref["rel_tol"]),
        )

        @test loose.data[:n_total] == Int(loose_ref["n_total"])
        @test loose.data[:n_rep] == Int(loose_ref["n_rep"])
        @test resumed.data[:n_total] >= loose.data[:n_total]
        @test resumed.data[:n_rep] >= loose.data[:n_rep]
        @test resumed.data[:n_per_rep] == resumed.data[:n_rep]
    end
end

run_release_parity()
