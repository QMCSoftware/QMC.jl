module CoverageProbes

using LinearAlgebra
using QuasiMC
import QuasiMC: Uniform

export run_shared_coverage_probes

struct _ProbeBadDD <: AbstractDiscreteDistribution end
struct _ProbeBadTM <: AbstractTrueMeasure end
struct _ProbeBadIntegrand <: AbstractIntegrand end

struct _ProbeVecIntegrand{TM} <: AbstractIntegrand
    true_measure::TM
end

QuasiMC.d_indv(::_ProbeVecIntegrand) = (2,)

function QuasiMC.evaluate(f::_ProbeVecIntegrand, x::AbstractMatrix)
    y = Matrix{Float64}(undef, size(x, 1), 2)
    @views y[:, 1] .= x[:, 1]
    @views y[:, 2] .= x[:, 1] .^ 2
    return y
end

function _expect_exception(f::Function, ::Type{T}) where {T <: Exception}
    try
        f()
    catch err
        err isa T || rethrow()
    end
    return nothing
end

function _run_interface_coverage_probes()
    dd = IIDStdUniform(1; seed=7)
    sc = CubMCCLT(Keister(Gaussian(dd; covariance=0.5)); abs_tol=0.05)
    QuasiMC.set_tolerance!(sc; abs_tol=0.02, rel_tol=0.01)

    sc_ml = CubMLMC(FinancialOptionML(IIDStdUniform(4; seed=8); d_coarsest=2); abs_tol=0.5)
    QuasiMC.set_tolerance!(sc_ml; rmse_tol=0.25)
    _expect_exception(ArgumentError) do
        QuasiMC.set_tolerance!(sc_ml; rel_tol=0.01)
    end
    _expect_exception(ArgumentError) do
        QuasiMC.dimension(_ProbeBadDD())
    end
    _expect_exception(ArgumentError) do
        QuasiMC.discrete_distribution(_ProbeBadTM())
    end
    _expect_exception(ArgumentError) do
        QuasiMC.true_measure(_ProbeBadIntegrand())
    end
    return nothing
end

function _run_generator_coverage_probes()
    gen_samples(Lattice(2; randomize=false, seed=7, order="gray"), 8; n_start=2)
    gen_samples(Lattice(2; randomize=false, seed=7, order="natural"), 2; n_start=2)
    gen_samples(Lattice(2; randomize=true, seed=55, replications=3), 8)
    gen_samples(Lattice(3; randomize=false, order="linear", generating_vector=[1, 3, 5]), 8)
    _expect_exception(ArgumentError) do
        Lattice(2; order="bogus")
    end

    dn_default = DigitalNetB2(2; randomize="none", seed=1)
    gen_samples(dn_default, 8)
    gen_samples(DigitalNetB2(2; randomize="none", order="RADICAL INVERSE"), 8; n_start=2)
    gen_samples(DigitalNetB2(2; randomize="none", order="GRAY"), 8; n_start=2)
    gen_samples(DigitalNetB2(2; randomize="DS", seed=7, replications=2), 8)
    gen_samples(DigitalNetB2(2; randomize="LMS", seed=7, replications=2, t=40), 8)
    gen_samples(DigitalNetB2(2; randomize="NUS", seed=7, replications=2, t=40), 8)
    gen_samples(DigitalNetB2(3; randomize="LMS_DS", seed=7, alpha=2), 8)
    V8 = Int.(dn_default.direction_nums[:, 1:8] .>> 24)
    gen_samples(DigitalNetB2(2; randomize="none", seed=1, generating_matrices=V8), 8)
    gen_samples(DigitalNetB2(2; randomize="none", generating_matrices="joe_kuo.6.21201.txt"), 8)
    gen_samples(DigitalNetB2(1500; randomize="none", seed=1), 2)
    _expect_exception(ArgumentError) do
        DigitalNetB2(2; order="bogus")
    end
    _expect_exception(ArgumentError) do
        DigitalNetB2(2; order="gray", graycode=false)
    end
    _expect_exception(ArgumentError) do
        DigitalNetB2(2; randomize="none", t=31)
    end
    _expect_exception(ArgumentError) do
        DigitalNetB2(2; generating_matrices=ones(Int, 1, 4))
    end

    gen_samples(Halton(3; randomize=false, seed=1), 8)
    gen_samples(Halton(3; randomize=true, seed=7, replications=2), 8)
    _expect_exception(ArgumentError) do
        Halton(2; replications=0)
    end
    return nothing
end

function _run_genz_coverage_probes()
    dd = IIDStdUniform(2; seed=11)
    tm = Uniform(dd)
    x = gen_samples(dd, 8)
    for kind in
        (:oscillatory, :product_peak, :corner_peak, :gaussian_peak, :continuous, :discontinuous)
        f = Genz(tm; kind=kind, a=[1.0, 1.5], u=[0.4, 0.6])
        evaluate(f, x)
        genz_exact(f)
        sprint(show, f)
    end
    genz_exact(Genz(Uniform(IIDStdUniform(21; seed=12)); kind=:corner_peak))
    genz_exact(Genz(tm; kind=:gaussian_peak, a=[0.0, 1.0], u=[0.5, 0.5]))
    genz_exact(Genz(tm; kind=:continuous, a=[0.0, 1.0], u=[0.5, 0.5]))
    genz_exact(Genz(tm; kind=:discontinuous, a=[0.0, 1.0], u=[0.5, 0.5]))
    return nothing
end

function _run_financial_option_coverage_probes()
    dd_gbm = IIDStdUniform(4; seed=21)
    tm_gbm = GeometricBrownianMotion(
        dd_gbm;
        volatility=0.2,
        start_price=100.0,
        interest_rate=0.05,
        t_final=1.0,
    )
    x_gbm = [
        100.0 110.0 120.0 130.0
        100.0 95.0 90.0 85.0
        100.0 105.0 98.0 101.0
    ]

    for call_put in (:call, :put)
        evaluate(
            FinancialOption(
                tm_gbm;
                option_type=:european,
                call_put=call_put,
                strike_price=100.0,
            ),
            x_gbm,
        )
        evaluate(
            FinancialOption(
                tm_gbm;
                option_type=:digital,
                call_put=call_put,
                strike_price=100.0,
            ),
            x_gbm,
        )
        evaluate(
            FinancialOption(
                tm_gbm;
                option_type=:lookback,
                call_put=call_put,
                strike_price=100.0,
            ),
            x_gbm,
        )
        evaluate(
            FinancialOption(
                tm_gbm;
                option_type=:asian,
                call_put=call_put,
                mean_type=:arithmetic,
                strike_price=100.0,
            ),
            x_gbm,
        )
        evaluate(
            FinancialOption(
                tm_gbm;
                option_type=:asian,
                call_put=call_put,
                mean_type=:geometric,
                strike_price=100.0,
            ),
            x_gbm,
        )
    end

    evaluate(
        FinancialOption(
            tm_gbm;
            option_type=:barrier,
            call_put=:call,
            strike_price=100.0,
            barrier_price=120.0,
            barrier_in_out=:in,
        ),
        x_gbm,
    )
    evaluate(
        FinancialOption(
            tm_gbm;
            option_type=:barrier,
            call_put=:put,
            strike_price=100.0,
            barrier_price=80.0,
            barrier_in_out=:out,
        ),
        x_gbm,
    )

    dd_bm = IIDStdUniform(4; seed=22)
    tm_bm = BrownianMotion(dd_bm; t_final=1.0)
    x_bm = transform(tm_bm, gen_samples(dd_bm, 4))
    evaluate(
        FinancialOption(
            tm_bm;
            option_type=:asian,
            call_put=:put,
            mean_type=:geometric,
            strike_price=100.0,
        ),
        x_bm,
    )
    evaluate(
        FinancialOption(tm_bm; option_type=:lookback, call_put=:put, strike_price=100.0),
        x_bm,
    )
    evaluate(
        FinancialOption(
            tm_bm;
            option_type=:barrier,
            call_put=:call,
            strike_price=100.0,
            barrier_price=120.0,
            barrier_in_out=:in,
        ),
        x_bm,
    )
    evaluate(
        FinancialOption(
            tm_bm;
            option_type=:barrier,
            call_put=:put,
            strike_price=100.0,
            barrier_price=80.0,
            barrier_in_out=:out,
        ),
        x_bm,
    )

    QuasiMC.get_exact_value(
        FinancialOption(tm_gbm; option_type=:european, call_put=:call, strike_price=100.0),
    )
    QuasiMC.get_exact_value(
        FinancialOption(
            tm_gbm;
            option_type=:asian,
            call_put=:put,
            mean_type=:geometric,
            strike_price=100.0,
        ),
    )
    QuasiMC.get_exact_value(
        FinancialOption(tm_gbm; option_type=:digital, call_put=:call, strike_price=100.0),
    )
    sprint(
        show,
        FinancialOption(
            tm_gbm;
            option_type=:barrier,
            call_put=:call,
            strike_price=100.0,
            barrier_price=120.0,
            barrier_in_out=:in,
        ),
    )
    _expect_exception(ErrorException) do
        QuasiMC.get_exact_value(
            FinancialOption(tm_gbm; option_type=:lookback, call_put=:call, strike_price=100.0),
        )
    end
    _expect_exception(ArgumentError) do
        FinancialOption(tm_gbm; option_type=:barrier, strike_price=100.0)
    end
    _expect_exception(ArgumentError) do
        FinancialOption(
            tm_gbm;
            option_type=:asian,
            mean_type=:arithmetic,
            asian_mean=:geometric,
        )
    end
    return nothing
end

function _run_control_variate_coverage_probes()
    dd = IIDStdUniform(2; seed=31)
    tm = Uniform(dd)
    main = CustomFun(tm, x -> x[:, 1] .+ x[:, 2])
    cv1 = CustomFun(tm, x -> x[:, 1])
    cv2 = CustomFun(tm, x -> x[:, 2])
    spec = QuasiMC._make_control_variate_spec(main, [cv1, cv2], [0.5, 0.5])
    xu = gen_samples(dd, 8)
    y = vec(QuasiMC.evaluate_on_uniform(main, xu))
    ycv = QuasiMC._control_variate_values(spec, xu)
    beta = QuasiMC._fit_control_variate_beta(y, ycv)
    QuasiMC._apply_control_variates(y, ycv, spec.means, beta)
    ymat = hcat(y, y .^ 2)
    beta_mat = QuasiMC._fit_control_variate_beta(ymat, ycv)
    QuasiMC._apply_control_variates(ymat, ycv, spec.means, beta_mat)
    ytilde = collect(1.0:8.0)
    ycvtilde_list = [collect(0.5:0.5:4.0), collect(1.0:8.0)]
    kappanumap = collect(0:7)
    QuasiMC._fit_control_variate_beta_transform(ytilde, ycvtilde_list, kappanumap, 1)
    QuasiMC._draw_adjusted(main, dd, 8, spec, beta)

    dd_other = IIDStdUniform(2; seed=32)
    cv_other = CustomFun(Uniform(dd_other), x -> x[:, 1])
    cv_wrongdim = CustomFun(Uniform(IIDStdUniform(3; seed=33)), x -> x[:, 1])
    _expect_exception(ArgumentError) do
        QuasiMC._make_control_variate_spec(main, cv1, nothing)
    end
    _expect_exception(ArgumentError) do
        QuasiMC._make_control_variate_spec(main, [cv1, cv2], [0.5])
    end
    _expect_exception(ArgumentError) do
        QuasiMC._make_control_variate_spec(main, cv_other, 0.5)
    end
    _expect_exception(ArgumentError) do
        QuasiMC._make_control_variate_spec(main, cv_wrongdim, 0.5)
    end
    return nothing
end

function _run_cubqmclatticeg_coverage_probes()
    dd_fft = Lattice(2; randomize=true, seed=41)
    f_fft = Genz(Uniform(dd_fft); kind=:continuous, a=[1.0, 1.0], u=[0.5, 0.5])
    loose = integrate(
        CubQMCLatticeG(f_fft; abs_tol=2.0, n_init=2^5, n_max=2^6, trace_iterations=true),
    )
    resumed = integrate(
        CubQMCLatticeG(f_fft; abs_tol=0.05, n_init=2^5, n_max=2^8, trace_iterations=true);
        resume=loose.data,
    )
    QuasiMC.resume_iteration_log(loose.data, resumed.data)
    QuasiMC.combined_iteration_log(loose.data, resumed.data)
    sprint(show, CubQMCLatticeG(f_fft; abs_tol=0.05))

    dd_rep = Lattice(2; randomize=true, seed=42)
    f_rep = Genz(Uniform(dd_rep); kind=:continuous, a=[1.0, 1.0], u=[0.5, 0.5])
    rep_loose = integrate(
        CubQMCLatticeG(
            f_rep;
            abs_tol=1.0,
            n_init=2^4,
            n_max=2^5,
            n_reps=4,
            fft_error_bound=false,
            trace_iterations=true,
        ),
    )
    integrate(
        CubQMCLatticeG(
            f_rep;
            abs_tol=0.05,
            n_init=2^4,
            n_max=2^7,
            n_reps=4,
            fft_error_bound=false,
            trace_iterations=true,
        );
        resume=rep_loose.data,
    )

    dd_cv = Lattice(2; randomize=true, seed=43)
    g = CustomFun(Uniform(dd_cv), x -> x[:, 1] .^ 2 .+ x[:, 2])
    integrate(
        CubQMCLatticeG(
            g;
            abs_tol=1e-3,
            n_init=2^5,
            n_max=2^7,
            control_variates=g,
            control_variate_means=5 / 6,
        ),
    )

    dd_vec = Lattice(1; randomize=true, seed=44)
    f_vec = _ProbeVecIntegrand(Uniform(dd_vec))
    vec_loose = integrate(
        CubQMCLatticeG(f_vec; abs_tol=0.2, n_init=2^5, n_max=2^6, trace_iterations=true),
    )
    integrate(
        CubQMCLatticeG(f_vec; abs_tol=0.05, n_init=2^5, n_max=2^8, trace_iterations=true);
        resume=vec_loose.data,
    )
    integrate(
        CubQMCLatticeG(
            f_vec;
            abs_tol=0.2,
            n_init=2^4,
            n_max=2^6,
            n_reps=4,
            fft_error_bound=false,
        ),
    )
    return nothing
end

function _run_cubmccltvec_coverage_probes()
    dd = IIDStdUniform(1; seed=51)
    f = _ProbeVecIntegrand(Uniform(dd))
    loose = integrate(CubMCCLTVec(f; abs_tol=0.2, n_init=32, trace_iterations=true))
    integrate(
        CubMCCLTVec(f; abs_tol=0.05, n_init=32, trace_iterations=true);
        resume=loose.data,
    )
    sprint(show, CubMCCLTVec(f; abs_tol=0.1, n_init=32))
    return nothing
end

function _run_cubqmcnetgrep_coverage_probes()
    dd = DigitalNetB2(2; randomize="DS", seed=52)
    f = Genz(Uniform(dd); kind=:gaussian_peak, a=[1.0, 1.0], u=[0.5, 0.5])
    loose = integrate(CubQMCNetGRep(f; abs_tol=0.5, n_init=2^4, n_max=2^5, n_reps=4))
    integrate(
        CubQMCNetGRep(f; abs_tol=0.05, n_init=2^4, n_max=2^7, n_reps=4, trace_iterations=true);
        resume=loose.data,
    )
    sprint(show, CubQMCNetGRep(f; abs_tol=0.1, n_reps=4))
    return nothing
end

function _run_ml_integrand_coverage_probes()
    f = FinancialOptionML(GeometricBrownianMotion(IIDStdUniform(4; seed=61)); d_coarsest=2)
    dimension_at_level(f, 0)
    dimension_at_level(f, 1)
    cost_at_level(f, 2)
    spawn_integrand(f, 0)
    spawn_integrand(f, 1)
    return nothing
end

function _run_latnetbuilder_coverage_probes()
    mktempdir() do dir
        ordinary = join([
            "Ordinary  // type",
            "8  // n_points",
            "3  // dim",
            "comment",
            "comment",
            "1  // gen1",
            "3  // gen2",
            "5  // gen3",
            "",
        ], "\n")
        open(joinpath(dir, "outputMachine.txt"), "w") do io
            write(io, ordinary)
        end
        latnetbuilder_linker(dir)
    end

    mktempdir() do dir
        digital = join([
            "2  // nb_cols",
            "2  // nb_rows",
            "4  // n_points",
            "2  // dim",
            "comment",
            "Sobol  // set_type",
            "comment",
            "comment",
            "---",
            "1 0",
            "0 1",
            "---",
            "1 1",
            "0 1",
            "",
        ], "\n")
        open(joinpath(dir, "outputMachine.txt"), "w") do io
            write(io, digital)
        end
        latnetbuilder_linker(dir)
    end
    return nothing
end

function run_shared_coverage_probes()
    _run_interface_coverage_probes()
    _run_generator_coverage_probes()
    _run_genz_coverage_probes()
    _run_financial_option_coverage_probes()
    _run_control_variate_coverage_probes()
    _run_cubqmclatticeg_coverage_probes()
    _run_cubmccltvec_coverage_probes()
    _run_cubqmcnetgrep_coverage_probes()
    _run_ml_integrand_coverage_probes()
    _run_latnetbuilder_coverage_probes()
    return nothing
end

end
