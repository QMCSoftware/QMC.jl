using Test
using QMC
using Statistics

struct InterfaceDD <: QMC.AbstractDiscreteDistribution
    d::Int
    fill_value::Float64
end

QMC.dimension(dd::InterfaceDD) = dd.d
QMC.gen_samples(dd::InterfaceDD, n::Int; n_start::Int=0) = fill(dd.fill_value, n, dd.d)

struct InterfaceTM <: QMC.AbstractTrueMeasure
    sampler::InterfaceDD
    shift::Float64
end

QMC.discrete_distribution(tm::InterfaceTM) = tm.sampler
QMC.dimension(tm::InterfaceTM) = QMC.dimension(tm.sampler)
QMC.transform(tm::InterfaceTM, x::AbstractMatrix) = x .+ tm.shift

struct InterfaceIntegrand <: QMC.AbstractIntegrand
    measure::InterfaceTM
    scale::Float64
end

QMC.true_measure(f::InterfaceIntegrand) = f.measure
QMC.dimension(f::InterfaceIntegrand) = QMC.dimension(f.measure)
QMC.evaluate(f::InterfaceIntegrand, x::AbstractMatrix) = f.scale .* sum(x; dims=2)[:]

@testset "Interface Contracts" begin
    @testset "Accessor-based toy subtypes" begin
        dd = InterfaceDD(3, 0.25)
        tm = InterfaceTM(dd, 0.5)
        f = InterfaceIntegrand(tm, 2.0)

        @test QMC.dimension(dd) == 3
        @test QMC.discrete_distribution(tm) === dd
        @test QMC.dimension(tm) == 3
        @test QMC.true_measure(f) === tm
        @test QMC.discrete_distribution(f) === dd
        @test sample_and_evaluate(f, 4) == fill(4.5, 4)
    end

    @testset "Built-in true measures accept interface DDs" begin
        dd3 = InterfaceDD(3, 0.25)
        dd2 = InterfaceDD(2, 0.25)

        tm_uniform = Uniform(dd3; lower_bound=-1.0, upper_bound=2.0)
        tm_gaussian = Gaussian(dd3; covariance=0.5)
        tm_lebesgue = Lebesgue(dd3; lower_bound=0.0, upper_bound=3.0)
        tm_student = StudentT(dd3; df=2.0)
        tm_tri = Triangular(dd3; lower=0.0, upper=1.0, mode=0.5)
        tm_kuma = Kumaraswamy(dd3; alpha=2.0, beta=3.0)
        tm_jsu = JohnsonsSU(dd3; xi=1.0, lambda=2.0, gamma=1.0, delta=2.0)
        tm_bc = BernoulliCont(dd3; lam=0.2)
        tm_dist = DistributionsWrapper(dd3; distribution=Distributions.Exponential(2.0))
        tm_gp = MaternGP(dd3; nu=2.5, lengthscale=0.3)
        tm_ut = UniformTriangle(dd2)
        tm_zieu = ZeroInflatedExpUniform(dd2; p_zero=0.3, rate=2.0)
        tm_ar = AcceptanceRejection(
            InterfaceDD(3, 0.25);
            pdf_func=x -> 6.0 * x[1] * x[2],
            envelope_multiplier=6.0,
        )

        for tm in (
            tm_uniform,
            tm_gaussian,
            tm_lebesgue,
            tm_student,
            tm_tri,
            tm_kuma,
            tm_jsu,
            tm_bc,
            tm_dist,
            tm_gp,
        )
            @test QMC.discrete_distribution(tm) isa InterfaceDD
            @test QMC.dimension(tm) == 3
            @test size(transform(tm, gen_samples(dd3, 4)), 2) == 3
        end

        @test QMC.dimension(tm_ut) == 2
        @test size(transform(tm_ut, gen_samples(dd2, 4))) == (4, 2)

        @test QMC.dimension(tm_zieu) == 1
        @test size(transform(tm_zieu, gen_samples(dd2, 4))) == (4, 1)

        @test QMC.dimension(tm_ar) == 2
        @test QMC.discrete_distribution(tm_ar) isa InterfaceDD
    end

    @testset "Built-in integrands accept interface TMs" begin
        tm1 = InterfaceTM(InterfaceDD(1, 0.25), 0.0)
        tm2 = InterfaceTM(InterfaceDD(2, 0.25), 0.0)
        tm3 = InterfaceTM(InterfaceDD(3, 0.25), 0.0)
        tm4 = InterfaceTM(InterfaceDD(4, 0.25), 0.0)
        tm6 = InterfaceTM(InterfaceDD(6, 0.25), 0.0)

        @test QMC.dimension(Keister(tm3)) == 3
        @test QMC.dimension(Genz(tm3; kind=:continuous)) == 3
        @test QMC.dimension(BoxIntegral(tm3; s=2.0)) == 3
        @test QMC.dimension(Linear0(tm3)) == 3
        @test QMC.dimension(Sin1D(tm1)) == 1
        @test QMC.dimension(Ishigami(tm3)) == 3
        @test QMC.dimension(Hartmann6D(tm6)) == 6
        @test QMC.dimension(Multimodal2D(tm2)) == 2
        @test QMC.dimension(FourBranch2D(tm2)) == 2
        @test QMC.dimension(AsianOption(tm4)) == 4
        @test QMC.dimension(FinancialOption(tm4; option_type=:european)) == 4
        @test FinancialOptionML(InterfaceDD(8, 0.25); d_coarsest=2).nb_of_levels == 3
    end
end
