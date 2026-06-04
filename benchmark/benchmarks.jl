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

# Silence expected, non-actionable warnings (notably CubMCCLT's single-pass
# non-convergence notice) for EVERY harness that loads this suite — the standalone
# runner and PkgBenchmark's per-revision subprocesses alike. Disabling Warn-and-
# below process-wide is the only mechanism that reliably reaches code executed
# inside BenchmarkTools; errors are still shown.
Logging.disable_logging(Logging.Warn)

# ── Configuration ─────────────────────────────────────────────────────────

const SAMPLES = [256, 1024, 4096, 16384]
const DIMS = [3, 10]

# Large-d cases for the Gaussian transform only (see block 2b). These dimensions
# are where the diagonal fast path's O(n·d²)→O(n·d) saving becomes visible; the
# small DIMS above are far too low for the d² term to matter.
const LARGE_DIMS = [50, 200]
const LARGE_N = [1024, 4096]

# ── Helpers ───────────────────────────────────────────────────────────────

function bench_gen_samples(dd_constructor, dim, n; kwargs...)
    dd = dd_constructor(dim; seed=42, kwargs...)
    @benchmarkable gen_samples($dd, $n) evals=3 samples=5
end

function bench_integrate(make_sc; kwargs...)
    @benchmarkable integrate(sc) evals=1 samples=3 setup=(sc = $make_sc())
end

# ── Benchmark Groups ─────────────────────────────────────────────────────

const SUITE = BenchmarkGroup()

# 1. Discrete Distribution sampling
#    NOTE: Lattice / DigitalNetB2 / Halton call the qmctoolscl C library for
#    point generation (same library QMCPy uses), so these measure the C kernel +
#    foreign function interface (FFI) binding, NOT Julia-vs-Python. IIDStdUniform
#    and Kronecker are pure Julia.
SUITE["gen_samples"] = BenchmarkGroup()
for dim in DIMS, n in SAMPLES
    SUITE["gen_samples"]["IIDStdUniform d=$dim n=$n"] =
        bench_gen_samples(IIDStdUniform, dim, n)
    SUITE["gen_samples"]["Lattice d=$dim n=$n"] =
        bench_gen_samples(Lattice, dim, n; randomize=true)
    SUITE["gen_samples"]["DigitalNetB2 d=$dim n=$n"] =
        bench_gen_samples(DigitalNetB2, dim, n; randomize="LMS_DS")
    SUITE["gen_samples"]["Halton d=$dim n=$n"] =
        bench_gen_samples(Halton, dim, n; randomize=true)
    SUITE["gen_samples"]["Kronecker d=$dim n=$n"] =
        bench_gen_samples(Kronecker, dim, n)
end

# 2. Transform (pure Julia: inverse-CDF + covariance factor)
SUITE["transform"] = BenchmarkGroup()
for dim in DIMS, n in SAMPLES
    dd = IIDStdUniform(dim; seed=42)
    tm_gauss = Gaussian(dd)
    x = gen_samples(dd, n)
    SUITE["transform"]["Gaussian d=$dim n=$n"] =
        @benchmarkable transform($tm_gauss, $x) evals=3 samples=5
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
        @benchmarkable transform($tm_diag, $x) evals=3 samples=5

    # Dense positive-definite Σ (unit diagonal, 0.5 off-diagonal) ⇒ dense A ⇒ GEMM.
    cov = fill(0.5, dim, dim)
    for i in 1:dim
        cov[i, i] = 1.0
    end
    tm_dense = Gaussian(dd; covariance=cov)
    SUITE["transform"]["Gaussian(dense) d=$dim n=$n"] =
        @benchmarkable transform($tm_dense, $x) evals=3 samples=5
end

# 3. Integrand evaluation (pure Julia)
SUITE["evaluate"] = BenchmarkGroup()
for n in SAMPLES
    dd = IIDStdUniform(3; seed=42)
    tm = Gaussian(dd)
    x = transform(tm, gen_samples(dd, n))

    f_keister = Keister(tm)
    SUITE["evaluate"]["Keister n=$n"] =
        @benchmarkable evaluate($f_keister, $x) evals=3 samples=5

    # NOTE: QMCPy's Genz supports only OSCILLATORY / CORNER PEAK. For a matched
    # cross-language comparison use :oscillatory here (see benchmark_qmcpy.py).
    f_genz = Genz(tm; kind=:oscillatory)
    SUITE["evaluate"]["Genz(oscillatory) n=$n"] =
        @benchmarkable evaluate($f_genz, $x) evals=3 samples=5
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
        @benchmarkable evaluate($f_box, $xu) evals=3 samples=5
    SUITE["evaluate"]["Linear0 d=10 n=$n"] =
        @benchmarkable evaluate($f_lin, $xu) evals=3 samples=5
    SUITE["evaluate"]["Genz(gaussian_peak) d=10 n=$n"] =
        @benchmarkable evaluate($f_gp, $xu) evals=3 samples=5
    SUITE["evaluate"]["Genz(continuous) d=10 n=$n"] =
        @benchmarkable evaluate($f_cont, $xu) evals=3 samples=5

    SUITE["transform"]["StudentT d=10 n=$n"] =
        @benchmarkable transform($tm_t, $xu) evals=3 samples=5
    SUITE["transform"]["JohnsonsSU d=10 n=$n"] =
        @benchmarkable transform($tm_j, $xu) evals=3 samples=5
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
        @benchmarkable evaluate($f_box, $xu) evals=3 samples=5
    SUITE["evaluate"]["Linear0 d=$dim n=$n"] =
        @benchmarkable evaluate($f_lin, $xu) evals=3 samples=5
    SUITE["evaluate"]["Genz(gaussian_peak) d=$dim n=$n"] =
        @benchmarkable evaluate($f_gp, $xu) evals=3 samples=5
end

# 4. End-to-end integration (mixed: C-backed generators + pure-Julia compute)
# Each integrate case has a named builder returning a fresh stopping criterion.
# The bodies live in named functions (not anonymous `() -> begin … end` inside the
# array literal below): inside `[ ]` newlines are significant, so a multi-line
# anonymous function in a vector literal fails to parse. The same builders drive
# both the timing benchmark and the accuracy check (runbenchmarks.jl runs
# `integrate(make_sc())` once to record the solution value + tolerances), so both
# measure exactly the same problem setup. The timed suite stays close to the
# Julia-vs-QMCPy overlap, while `INTEGRATE_ACCURACY_CASES` below extends it with
# extra exact-value smoke tests for additional Julia algorithms.
function _int_cubmcclt_keister()
    dd = IIDStdUniform(3; seed=42)
    tm = Gaussian(dd; covariance=0.5)   # Keister requires N(0, I/2); matches QMCPy
    f = Keister(tm)
    CubMCCLT(f; abs_tol=0.01)
end

function _int_cubmcg_keister()
    dd = IIDStdUniform(3; seed=42)
    tm = Gaussian(dd; covariance=0.5)   # Keister requires N(0, I/2); matches QMCPy
    f = Keister(tm)
    CubMCG(f; abs_tol=0.01)
end

function _int_cubmccltvec_keister()
    dd = IIDStdUniform(3; seed=42)
    tm = Gaussian(dd; covariance=0.5)   # Keister requires N(0, I/2); matches QMCPy
    f = Keister(tm)
    CubMCCLTVec(f; abs_tol=0.01)
end

function _int_cubqmclatticeg_keister()
    dd = Lattice(3; seed=42, randomize=true)
    tm = Gaussian(dd; covariance=0.5)   # Keister requires N(0, I/2); matches QMCPy
    f = Keister(tm)
    CubQMCLatticeG(f; abs_tol=0.01)
end

function _int_cubqmcnetg_keister()
    dd = DigitalNetB2(3; seed=42, randomize="LMS_DS")
    tm = Gaussian(dd; covariance=0.5)   # Keister requires N(0, I/2); matches QMCPy
    f = Keister(tm)
    CubQMCNetG(f; abs_tol=0.01)
end

function _int_cubqmclatticeg_genz_continuous()
    dd = Lattice(2; seed=42, randomize=true)
    tm = Uniform(dd)
    f = Genz(tm; kind=:continuous, a=[1.0, 1.0], u=[0.5, 0.5])
    CubQMCLatticeG(f; abs_tol=0.01, n_init=2^10, n_reps=16)
end

function _int_cubqmcnetg_genz_gaussian_peak()
    dd = DigitalNetB2(2; seed=42, randomize="LMS_DS")
    tm = Uniform(dd)
    f = Genz(tm; kind=:gaussian_peak, a=[1.0, 1.0], u=[0.5, 0.5])
    CubQMCNetG(f; abs_tol=0.01, n_init=2^10, n_reps=16)
end

function _int_cubqmcbayeslatticeg_genz_continuous()
    dd = Lattice(2; seed=42, randomize=true)
    tm = Uniform(dd)
    f = Genz(tm; kind=:continuous, a=[1.0, 1.0], u=[0.5, 0.5])
    CubQMCBayesLatticeG(f; abs_tol=0.01, n_init=2^8, n_max=2^14)
end

function _int_cubqmcbayesnetg_genz_continuous()
    dd = DigitalNetB2(2; seed=42, randomize="LMS_DS")
    tm = Uniform(dd)
    f = Genz(tm; kind=:continuous, a=[1.0, 1.0], u=[0.5, 0.5])
    CubQMCBayesNetG(f; abs_tol=0.01, n_init=2^8, n_max=2^14)
end

function _int_cubmcclt_asian()
    dd = IIDStdUniform(50; seed=42)
    tm = GeometricBrownianMotion(dd; volatility=0.2, start_price=100.0,
        interest_rate=0.05, t_final=1.0)
    f = FinancialOption(tm; option_type=:asian, strike_price=100.0)
    CubMCCLT(f; abs_tol=0.5)
end

function _int_cubmcclt_geometric_asian()
    dd = IIDStdUniform(50; seed=42)
    tm = GeometricBrownianMotion(dd; volatility=0.2, start_price=100.0,
        interest_rate=0.05, t_final=1.0)
    f = FinancialOption(
        tm;
        option_type=:asian,
        mean_type=:geometric,
        strike_price=100.0,
    )
    CubMCCLT(f; abs_tol=0.25)
end

function _int_cubqmcnetg_european()
    dd = DigitalNetB2(50; seed=42, randomize="LMS_DS")
    tm = GeometricBrownianMotion(dd; volatility=0.2, start_price=100.0,
        interest_rate=0.05, t_final=1.0)
    f = FinancialOption(tm; option_type=:european, strike_price=100.0)
    CubQMCNetG(f; abs_tol=0.5)
end

const INTEGRATE_CASES = Pair{String, Function}[
    "CubMCCLT Keister" => _int_cubmcclt_keister,
    "CubQMCLatticeG Keister" => _int_cubqmclatticeg_keister,
    "CubQMCNetG Keister" => _int_cubqmcnetg_keister,
    "CubMCCLT AsianOption" => _int_cubmcclt_asian,
    "CubQMCNetG EuropeanOption" => _int_cubqmcnetg_european,
]

const INTEGRATE_ACCURACY_CASES = Pair{String, Function}[
    INTEGRATE_CASES...,
    "CubMCG Keister" => _int_cubmcg_keister,
    "CubMCCLTVec Keister" => _int_cubmccltvec_keister,
    "CubQMCLatticeG Genz(continuous)" => _int_cubqmclatticeg_genz_continuous,
    "CubQMCNetG Genz(gaussian_peak)" => _int_cubqmcnetg_genz_gaussian_peak,
    "CubQMCBayesLatticeG Genz(continuous)" => _int_cubqmcbayeslatticeg_genz_continuous,
    "CubQMCBayesNetG Genz(continuous)" => _int_cubqmcbayesnetg_genz_continuous,
    "CubMCCLT GeometricAsianOption" => _int_cubmcclt_geometric_asian,
]

SUITE["integrate"] = BenchmarkGroup()
for (name, make_sc) in INTEGRATE_CASES
    SUITE["integrate"][name] = bench_integrate(make_sc)
end
