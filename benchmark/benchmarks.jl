# QMC.jl Benchmark Suite (PkgBenchmark-compatible).
#
# This file ONLY defines `const SUITE::BenchmarkGroup`; it does not run anything.
#   * `benchmark/runbenchmarks.jl` runs SUITE standalone and saves results.
#   * `benchmark/compare.jl` uses PkgBenchmark.jl to diff two git revisions.
#   * PkgBenchmark.benchmarkpkg(...) includes this file directly.
#
# Environment: the `benchmark/` project (benchmark/Project.toml). The runner and
# compare scripts bootstrap it; PkgBenchmark sets it up itself.

using BenchmarkTools
using QMC
import QMC: Uniform
using Logging
using LinearAlgebra

# Silence expected, non-actionable warnings (notably CubMCCLT's single-pass
# non-convergence notice) for EVERY harness that loads this suite — the standalone
# runner and PkgBenchmark's per-revision subprocesses alike. Disabling Warn-and-
# below process-wide is the only mechanism that reliably reaches code executed
# inside BenchmarkTools; errors are still shown.
Logging.disable_logging(Logging.Warn)

# ── Configuration ─────────────────────────────────────────────────────────

const SAMPLES = [256, 1024, 4096, 16384]
const DIMS = [3, 10]
const BENCH_SAMPLES = 5
const INTEGRATE_BENCH_SAMPLES = 9
const ORACLE_ROWS = 4
# Coverage jobs reuse this suite but also need broader src/ branch execution than
# the timed rows alone provide. Those extra probes are enabled only when the
# coverage targets set BENCH_COVERAGE=1.
const BENCH_COVERAGE = get(ENV, "BENCH_COVERAGE", "0") == "1"
# StudentT is reported as its own cross-language row, so its sample count is
# matched to the Python harness's `STUDENT_T_REPEAT = 21` (benchmark_qmcpy.py) to
# keep that comparison apples-to-apples. Both sides report the median per call;
# Python additionally does 3 explicit warmup runs, while BenchmarkTools performs
# its own JIT/tuning warmup before sampling (plus `evals=3` per sample), which is
# its analog — the sample/repeat count is the directly comparable knob.
const STUDENT_T_BENCH_SAMPLES = 21

const BENCH_BLAS_THREADS = let raw = get(ENV, "QMC_BENCH_BLAS_THREADS", "1")
    threads = try
        parse(Int, raw)
    catch err
        throw(ArgumentError("QMC_BENCH_BLAS_THREADS must be an integer, got $(repr(raw))"))
    end
    threads > 0 || throw(ArgumentError("QMC_BENCH_BLAS_THREADS must be ≥ 1, got $threads"))
    threads
end
BLAS.set_num_threads(BENCH_BLAS_THREADS)
# With multiple Julia threads, clamp BLAS to 1 thread before any threads are spawned.
# Toggling BLAS thread count while Julia threads are live is not thread-safe and
# causes OpenBLAS to crash at Julia shutdown (signal 11). CubQMCNetGRep's parallel
# replicates rely on this invariant: each Julia thread calls BLAS with 1 internal
# thread, so OpenBLAS serializes concurrent calls without spawning extra workers.
if Threads.nthreads() > 1
    BLAS.set_num_threads(1)
end

# Large-d cases for the Gaussian transform only (see block 2b). These dimensions
# are where the diagonal fast path's O(n·d²)→O(n·d) saving becomes visible; the
# small DIMS above are far too low for the d² term to matter.
const LARGE_DIMS = [50, 200]
const LARGE_N = [1024, 4096]

# ── Helpers ───────────────────────────────────────────────────────────────

function bench_gen_samples(dd_constructor, dim, n; kwargs...)
    dd = dd_constructor(dim; seed=42, kwargs...)
    @benchmarkable gen_samples($dd, $n) evals=3 samples=BENCH_SAMPLES
end

function bench_integrate(make_sc; kwargs...)
    @benchmarkable integrate(sc) evals=1 samples=INTEGRATE_BENCH_SAMPLES setup=(sc = $make_sc())
end

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

struct _BenchBadDD <: AbstractDiscreteDistribution end
struct _BenchBadTM <: AbstractTrueMeasure end
struct _BenchBadIntegrand <: AbstractIntegrand end

struct _BenchVecIntegrand{TM} <: AbstractIntegrand
    true_measure::TM
end
QMC.d_indv(::_BenchVecIntegrand) = (2,)
function QMC.evaluate(f::_BenchVecIntegrand, x::AbstractMatrix)
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
    QMC.set_tolerance!(sc; abs_tol=0.02, rel_tol=0.01)

    sc_ml = CubMLMC(FinancialOptionML(IIDStdUniform(4; seed=8); d_coarsest=2); abs_tol=0.5)
    QMC.set_tolerance!(sc_ml; rmse_tol=0.25)
    _expect_exception(ArgumentError) do
        QMC.set_tolerance!(sc_ml; rel_tol=0.01)
    end
    _expect_exception(ArgumentError) do
        QMC.dimension(_BenchBadDD())
    end
    _expect_exception(ArgumentError) do
        QMC.discrete_distribution(_BenchBadTM())
    end
    _expect_exception(ArgumentError) do
        QMC.true_measure(_BenchBadIntegrand())
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

    QMC.get_exact_value(
        FinancialOption(tm_gbm; option_type=:european, call_put=:call, strike_price=100.0),
    )
    QMC.get_exact_value(
        FinancialOption(
            tm_gbm;
            option_type=:asian,
            call_put=:put,
            mean_type=:geometric,
            strike_price=100.0,
        ),
    )
    QMC.get_exact_value(
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
        QMC.get_exact_value(
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
    spec = QMC._make_control_variate_spec(main, [cv1, cv2], [0.5, 0.5])
    xu = gen_samples(dd, 8)
    y = vec(QMC.evaluate_on_uniform(main, xu))
    ycv = QMC._control_variate_values(spec, xu)
    beta = QMC._fit_control_variate_beta(y, ycv)
    QMC._apply_control_variates(y, ycv, spec.means, beta)
    ymat = hcat(y, y .^ 2)
    beta_mat = QMC._fit_control_variate_beta(ymat, ycv)
    QMC._apply_control_variates(ymat, ycv, spec.means, beta_mat)
    ytilde = collect(1.0:8.0)
    ycvtilde_list = [collect(0.5:0.5:4.0), collect(1.0:8.0)]
    kappanumap = collect(0:7)
    QMC._fit_control_variate_beta_transform(ytilde, ycvtilde_list, kappanumap, 1)
    QMC._draw_adjusted(main, dd, 8, spec, beta)

    dd_other = IIDStdUniform(2; seed=32)
    cv_other = CustomFun(Uniform(dd_other), x -> x[:, 1])
    cv_wrongdim = CustomFun(Uniform(IIDStdUniform(3; seed=33)), x -> x[:, 1])
    _expect_exception(ArgumentError) do
        QMC._make_control_variate_spec(main, cv1, nothing)
    end
    _expect_exception(ArgumentError) do
        QMC._make_control_variate_spec(main, [cv1, cv2], [0.5])
    end
    _expect_exception(ArgumentError) do
        QMC._make_control_variate_spec(main, cv_other, 0.5)
    end
    _expect_exception(ArgumentError) do
        QMC._make_control_variate_spec(main, cv_wrongdim, 0.5)
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
    QMC.resume_iteration_log(loose.data, resumed.data)
    QMC.combined_iteration_log(loose.data, resumed.data)
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
    f_vec = _BenchVecIntegrand(Uniform(dd_vec))
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

function run_benchmark_coverage_probes()
    _run_interface_coverage_probes()
    _run_generator_coverage_probes()
    _run_genz_coverage_probes()
    _run_financial_option_coverage_probes()
    _run_control_variate_coverage_probes()
    _run_cubqmclatticeg_coverage_probes()
    return nothing
end

BENCH_COVERAGE && run_benchmark_coverage_probes()

# ── Benchmark Groups ─────────────────────────────────────────────────────

const SUITE = BenchmarkGroup()

# 1. Discrete Distribution sampling
#    NOTE: Lattice / DigitalNetB2 / Halton call the qmctoolscl C library for
#    point generation (same library QMCPy uses), so these measure the C kernel +
#    foreign function interface (FFI) binding, NOT Julia-vs-Python. IIDStdUniform
#    and Kronecker are pure Julia.
SUITE["gen_samples"] = BenchmarkGroup()
for dim in DIMS, n in SAMPLES
    SUITE["gen_samples"]["IIDStdUniform d=$dim n=$n"] = bench_gen_samples(IIDStdUniform, dim, n)
    SUITE["gen_samples"]["Lattice d=$dim n=$n"] =
        bench_gen_samples(Lattice, dim, n; randomize=true)
    SUITE["gen_samples"]["DigitalNetB2 d=$dim n=$n"] =
        bench_gen_samples(DigitalNetB2, dim, n; randomize="LMS_DS")
    SUITE["gen_samples"]["Halton d=$dim n=$n"] =
        bench_gen_samples(Halton, dim, n; randomize=true)
    SUITE["gen_samples"]["Kronecker d=$dim n=$n"] = bench_gen_samples(Kronecker, dim, n)
end

# 2. Transform (pure Julia: inverse-CDF + covariance factor)
SUITE["transform"] = BenchmarkGroup()
for dim in DIMS, n in SAMPLES
    dd = IIDStdUniform(dim; seed=42)
    tm_gauss = Gaussian(dd)
    x = gen_samples(dd, n)
    SUITE["transform"]["Gaussian d=$dim n=$n"] =
        @benchmarkable transform($tm_gauss, $x) evals=3 samples=BENCH_SAMPLES
end

# 2b. Large-d transform cases — exercise the Gaussian diagonal fast path at
# dimensions where its O(n·d²)→O(n·d) saving actually matters. Two covariance
# types per (d, n):
#   * (diag)  default identity Σ → factor A is diagonal → column-scaling fast path
#   * (dense) full PD Σ          → factor A is dense    → BLAS GEMM (= baseline path)
# Diag-vs-dense within ONE run isolates the fast path's benefit (no git A/B needed);
# an opt1-vs-baseline A/B on the (diag) rows confirms it, while the (dense) rows —
# unchanged by opt1 — act as a built-in control that should stay ~1.0.
for dim in LARGE_DIMS, n in LARGE_N
    dd = IIDStdUniform(dim; seed=42)
    x = gen_samples(dd, n)

    tm_diag = Gaussian(dd)                       # identity Σ ⇒ diagonal A ⇒ fast path
    SUITE["transform"]["Gaussian(diag) d=$dim n=$n"] =
        @benchmarkable transform($tm_diag, $x) evals=3 samples=BENCH_SAMPLES

    # Dense positive-definite Σ (unit diagonal, 0.5 off-diagonal) ⇒ dense A ⇒ GEMM.
    tm_dense = Gaussian(dd; covariance=dense_covariance(dim))
    SUITE["transform"]["Gaussian(dense) d=$dim n=$n"] =
        @benchmarkable transform($tm_dense, $x) evals=3 samples=BENCH_SAMPLES
end

# 3. Integrand evaluation (pure Julia)
SUITE["evaluate"] = BenchmarkGroup()
for n in SAMPLES
    dd = IIDStdUniform(3; seed=42)
    tm = Gaussian(dd)
    x = transform(tm, gen_samples(dd, n))

    f_keister = Keister(tm)
    SUITE["evaluate"]["Keister n=$n"] =
        @benchmarkable evaluate($f_keister, $x) evals=3 samples=BENCH_SAMPLES

    # NOTE: QMCPy's Genz supports only OSCILLATORY / CORNER PEAK. For a matched
    # cross-language comparison use :oscillatory here (see benchmark_qmcpy.py).
    f_genz = Genz(tm; kind=:oscillatory)
    SUITE["evaluate"]["Genz(oscillatory) n=$n"] =
        @benchmarkable evaluate($f_genz, $x) evals=3 samples=BENCH_SAMPLES
end

# 3b. Allocation-audit coverage (opt2). These are the transform/evaluate bodies the
# allocation audit actually rewrote (the rest of the suite reuses code that already
# existed pre-opt2). Read the MEMORY column first in an opt2-vs-baseline A/B —
# allocation counts are deterministic, so that is the unambiguous signal.
#   * reductions     : BoxIntegral, Linear0 (sum over columns)        — expect a win
#   * GEMV broadcasts: Genz(:gaussian_peak), Genz(:continuous)        — expect a win
#   * per-element ppf: StudentT, JohnsonsSU (quantile broadcast)      — expect ~neutral
for n in SAMPLES
    dd = IIDStdUniform(10; seed=42)
    xu = gen_samples(dd, n)                       # uniform [0,1)^d input
    tm = Gaussian(dd)
    f_box = BoxIntegral(tm)
    f_lin = Linear0(tm)
    f_gp = Genz(tm; kind=:gaussian_peak)
    f_cont = Genz(tm; kind=:continuous)
    tm_t = StudentT(dd)
    tm_j = JohnsonsSU(dd)

    SUITE["evaluate"]["BoxIntegral d=10 n=$n"] =
        @benchmarkable evaluate($f_box, $xu) evals=3 samples=BENCH_SAMPLES
    SUITE["evaluate"]["Linear0 d=10 n=$n"] =
        @benchmarkable evaluate($f_lin, $xu) evals=3 samples=BENCH_SAMPLES
    SUITE["evaluate"]["Genz(gaussian_peak) d=10 n=$n"] =
        @benchmarkable evaluate($f_gp, $xu) evals=3 samples=BENCH_SAMPLES
    SUITE["evaluate"]["Genz(continuous) d=10 n=$n"] =
        @benchmarkable evaluate($f_cont, $xu) evals=3 samples=BENCH_SAMPLES

    SUITE["transform"]["StudentT d=10 n=$n"] =
        @benchmarkable transform($tm_t, $xu) evals=3 samples=STUDENT_T_BENCH_SAMPLES
    SUITE["transform"]["JohnsonsSU d=10 n=$n"] =
        @benchmarkable transform($tm_j, $xu) evals=3 samples=BENCH_SAMPLES
end

# Large-d variants for the reductions / GEMV kinds, where the cache-friendly
# column sweep should show the clearest benefit.
for dim in LARGE_DIMS, n in LARGE_N
    dd = IIDStdUniform(dim; seed=42)
    xu = gen_samples(dd, n)
    tm = Gaussian(dd)
    f_box = BoxIntegral(tm)
    f_lin = Linear0(tm)
    f_gp = Genz(tm; kind=:gaussian_peak)
    SUITE["evaluate"]["BoxIntegral d=$dim n=$n"] =
        @benchmarkable evaluate($f_box, $xu) evals=3 samples=BENCH_SAMPLES
    SUITE["evaluate"]["Linear0 d=$dim n=$n"] =
        @benchmarkable evaluate($f_lin, $xu) evals=3 samples=BENCH_SAMPLES
    SUITE["evaluate"]["Genz(gaussian_peak) d=$dim n=$n"] =
        @benchmarkable evaluate($f_gp, $xu) evals=3 samples=BENCH_SAMPLES
end

# 3c. Deterministic cross-language oracle cases. These are small fixed-value
# checks that complement the timing rows by comparing actual computed outputs
# against QMCPy on the same inputs.
function _oracle_transform_gaussian_small()
    dd = IIDStdUniform(3; seed=42)
    tm = Gaussian(dd; decomp_type=:Cholesky)
    return transform(tm, oracle_uniform_matrix(ORACLE_ROWS, 3; offset=1))
end

function _oracle_transform_gaussian_diag_large()
    dd = IIDStdUniform(50; seed=42)
    tm = Gaussian(dd; decomp_type=:Cholesky)
    return transform(tm, oracle_uniform_matrix(3, 50; offset=2))
end

function _oracle_transform_gaussian_dense_large()
    dd = IIDStdUniform(50; seed=42)
    tm = Gaussian(dd; covariance=dense_covariance(50), decomp_type=:Cholesky)
    return transform(tm, oracle_uniform_matrix(3, 50; offset=3))
end

function _oracle_transform_student_t()
    dd = IIDStdUniform(1; seed=42)
    tm = StudentT(dd)
    return transform(tm, oracle_uniform_matrix(ORACLE_ROWS, 1; offset=4))
end

function _oracle_transform_johnsons_su()
    dd = IIDStdUniform(10; seed=42)
    tm = JohnsonsSU(dd)
    return transform(tm, oracle_uniform_matrix(ORACLE_ROWS, 10; offset=5))
end

function _oracle_evaluate_keister()
    dd = IIDStdUniform(3; seed=42)
    tm = Gaussian(dd; covariance=0.5)
    f = Keister(tm)
    x = transform(tm, oracle_uniform_matrix(ORACLE_ROWS, 3; offset=11))
    return evaluate(f, x)
end

function _oracle_evaluate_genz_oscillatory()
    dd = IIDStdUniform(3; seed=42)
    tm = Uniform(dd)
    f = Genz(tm; kind=:oscillatory, a=qmcpy_genz_coeffs(3), u=zeros(3))
    x = oracle_uniform_matrix(ORACLE_ROWS, 3; offset=12)
    return evaluate(f, x)
end

function _oracle_evaluate_boxintegral()
    dd = IIDStdUniform(10; seed=42)
    tm = Uniform(dd)
    f = BoxIntegral(tm; s=1.0)
    return evaluate(f, oracle_uniform_matrix(ORACLE_ROWS, 10; offset=13))
end

function _oracle_evaluate_linear0()
    dd = IIDStdUniform(10; seed=42)
    tm = Uniform(dd)
    f = Linear0(tm)
    return evaluate(f, oracle_uniform_matrix(ORACLE_ROWS, 10; offset=14))
end

function _oracle_evaluate_genz_gaussian_peak()
    dd = IIDStdUniform(10; seed=42)
    tm = Uniform(dd)
    f = Genz(tm; kind=:gaussian_peak)
    return evaluate(f, oracle_uniform_matrix(ORACLE_ROWS, 10; offset=15))
end

function _oracle_evaluate_genz_continuous()
    dd = IIDStdUniform(10; seed=42)
    tm = Uniform(dd)
    f = Genz(tm; kind=:continuous)
    return evaluate(f, oracle_uniform_matrix(ORACLE_ROWS, 10; offset=16))
end

const TRANSFORM_ORACLE_CASES = [
    (name="Gaussian d=3 rows=4", atol=1e-10, rtol=1e-10, make=_oracle_transform_gaussian_small),
    (
        name="Gaussian(diag) d=50 rows=3",
        atol=1e-10,
        rtol=1e-10,
        make=_oracle_transform_gaussian_diag_large,
    ),
    (
        name="Gaussian(dense) d=50 rows=3",
        atol=5e-10,
        rtol=5e-10,
        make=_oracle_transform_gaussian_dense_large,
    ),
    (name="StudentT d=1 rows=4", atol=1e-7, rtol=1e-7, make=_oracle_transform_student_t),
    (name="JohnsonsSU d=10 rows=4", atol=1e-10, rtol=1e-10, make=_oracle_transform_johnsons_su),
]

const EVALUATE_ORACLE_CASES = [
    (name="Keister rows=4", atol=1e-10, rtol=1e-10, make=_oracle_evaluate_keister),
    (
        name="Genz(oscillatory) rows=4",
        atol=1e-10,
        rtol=1e-10,
        make=_oracle_evaluate_genz_oscillatory,
    ),
    (name="BoxIntegral d=10 rows=4", atol=1e-10, rtol=1e-10, make=_oracle_evaluate_boxintegral),
    (name="Linear0 d=10 rows=4", atol=1e-10, rtol=1e-10, make=_oracle_evaluate_linear0),
    (
        name="Genz(gaussian_peak) d=10 rows=4",
        atol=1e-10,
        rtol=1e-10,
        make=_oracle_evaluate_genz_gaussian_peak,
    ),
    (
        name="Genz(continuous) d=10 rows=4",
        atol=1e-10,
        rtol=1e-10,
        make=_oracle_evaluate_genz_continuous,
    ),
]

const ORACLE_CASES =
    Dict("transform" => TRANSFORM_ORACLE_CASES, "evaluate" => EVALUATE_ORACLE_CASES)

# 4. End-to-end integration (mixed: C-backed generators + pure-Julia compute)
# Each integrate case has a named builder returning a fresh stopping criterion.
# The bodies live in named functions (not anonymous `() -> begin … end` inside the
# array literal below): inside `[ ]` newlines are significant, so a multi-line
# anonymous function in a vector literal fails to parse. The same builders drive
# both the timing benchmark and the accuracy check (runbenchmarks.jl runs
# `integrate(make_sc())` once to record the solution value + tolerances), so both
# measure exactly the same problem setup.
function _int_cubmcclt_keister()
    dd = IIDStdUniform(3; seed=42)
    tm = Gaussian(dd; covariance=0.5)   # Keister requires N(0, I/2); matches QMCPy
    f = Keister(tm)
    CubMCCLT(f; abs_tol=0.01)
end

function _int_cubqmclatticeg_keister()
    dd = Lattice(3; seed=42, randomize=true)
    tm = Gaussian(dd; covariance=0.5)   # Keister requires N(0, I/2); matches QMCPy
    f = Keister(tm)
    CubQMCLatticeG(f; abs_tol=0.01)
end

function _int_cubqmcnetg_keister()
    dd = DigitalNetB2(3; seed=42, randomize="LMS_DS", graycode=false)
    tm = Gaussian(dd; covariance=0.5)   # Keister requires N(0, I/2); matches QMCPy
    f = Keister(tm)
    CubQMCNetG(f; abs_tol=0.01)
end

function _int_cubqmcnetgrep_keister()
    dd = DigitalNetB2(3; seed=42, randomize="LMS_DS")
    tm = Gaussian(dd; covariance=0.5)   # Keister requires N(0, I/2); matches QMCPy
    f = Keister(tm)
    CubQMCNetGRep(f; abs_tol=0.01)
end

function _int_cubmcclt_asian()
    dd = IIDStdUniform(50; seed=42)
    tm = GeometricBrownianMotion(
        dd;
        volatility=0.2,
        start_price=100.0,
        interest_rate=0.05,
        t_final=1.0,
    )
    f = FinancialOption(tm; option_type=:asian, strike_price=100.0)
    CubMCCLT(f; abs_tol=0.5)
end

function _int_cubqmcnetg_european()
    dd = DigitalNetB2(50; seed=42, randomize="LMS_DS", graycode=false)
    tm = GeometricBrownianMotion(
        dd;
        volatility=0.2,
        start_price=100.0,
        interest_rate=0.05,
        t_final=1.0,
    )
    f = FinancialOption(tm; option_type=:european, strike_price=100.0)
    CubQMCNetG(f; abs_tol=0.5)
end

function _int_cubqmcnetgrep_european()
    dd = DigitalNetB2(50; seed=42, randomize="LMS_DS")
    tm = GeometricBrownianMotion(
        dd;
        volatility=0.2,
        start_price=100.0,
        interest_rate=0.05,
        t_final=1.0,
    )
    f = FinancialOption(tm; option_type=:european, strike_price=100.0)
    CubQMCNetGRep(f; abs_tol=0.5)
end

function _int_cubmcclt_european()
    dd = IIDStdUniform(50; seed=42)
    tm = GeometricBrownianMotion(
        dd;
        volatility=0.2,
        start_price=100.0,
        interest_rate=0.05,
        t_final=1.0,
    )
    f = FinancialOption(tm; option_type=:european, strike_price=100.0)
    CubMCCLT(f; abs_tol=0.5)
end

function _int_cubqmclatticeg_european()
    dd = Lattice(50; seed=42, randomize=true)
    tm = GeometricBrownianMotion(
        dd;
        volatility=0.2,
        start_price=100.0,
        interest_rate=0.05,
        t_final=1.0,
    )
    f = FinancialOption(tm; option_type=:european, strike_price=100.0)
    CubQMCLatticeG(f; abs_tol=0.5)
end

function _int_cubqmcnetg_asian()
    dd = DigitalNetB2(50; seed=42, randomize="LMS_DS", graycode=false)
    tm = GeometricBrownianMotion(
        dd;
        volatility=0.2,
        start_price=100.0,
        interest_rate=0.05,
        t_final=1.0,
    )
    f = FinancialOption(tm; option_type=:asian, strike_price=100.0)
    CubQMCNetG(f; abs_tol=0.5)
end

function _int_cubqmcnetgrep_asian()
    dd = DigitalNetB2(50; seed=42, randomize="LMS_DS")
    tm = GeometricBrownianMotion(
        dd;
        volatility=0.2,
        start_price=100.0,
        interest_rate=0.05,
        t_final=1.0,
    )
    f = FinancialOption(tm; option_type=:asian, strike_price=100.0)
    CubQMCNetGRep(f; abs_tol=0.5)
end

const INTEGRATE_CASES = Pair{String, Function}[
    "CubMCCLT Keister" => _int_cubmcclt_keister,
    "CubQMCLatticeG Keister" => _int_cubqmclatticeg_keister,
    "CubQMCNetG Keister" => _int_cubqmcnetg_keister,
    "CubQMCNetGRep Keister" => _int_cubqmcnetgrep_keister,
    "CubMCCLT AsianOption" => _int_cubmcclt_asian,
    "CubQMCNetG EuropeanOption" => _int_cubqmcnetg_european,
    "CubQMCNetGRep EuropeanOption" => _int_cubqmcnetgrep_european,
    "CubMCCLT EuropeanOption" => _int_cubmcclt_european,
    "CubQMCLatticeG EuropeanOption" => _int_cubqmclatticeg_european,
    "CubQMCNetG AsianOption" => _int_cubqmcnetg_asian,
    "CubQMCNetGRep AsianOption" => _int_cubqmcnetgrep_asian,
]

SUITE["integrate"] = BenchmarkGroup()
for (name, make_sc) in INTEGRATE_CASES
    SUITE["integrate"][name] = bench_integrate(make_sc)
end
