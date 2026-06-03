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
#     (foreign function interface (FFI)binding, NOT Julia-vs-Python. IIDStdUniform and Kronecker are pure Julia.
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

# 4. End-to-end integration (mixed: C-backed generators + pure-Julia compute)
SUITE["integrate"] = BenchmarkGroup()

SUITE["integrate"]["CubMCCLT Keister"] = bench_integrate() do
    dd = IIDStdUniform(3; seed=42)
    tm = Gaussian(dd)
    f = Keister(tm)
    CubMCCLT(f; abs_tol=0.01)
end

SUITE["integrate"]["CubQMCLatticeG Keister"] = bench_integrate() do
    dd = Lattice(3; seed=42, randomize=true)
    tm = Gaussian(dd)
    f = Keister(tm)
    CubQMCLatticeG(f; abs_tol=0.01)
end

SUITE["integrate"]["CubQMCNetG Keister"] = bench_integrate() do
    dd = DigitalNetB2(3; seed=42, randomize="LMS_DS")
    tm = Gaussian(dd)
    f = Keister(tm)
    CubQMCNetG(f; abs_tol=0.01)
end

SUITE["integrate"]["CubMCCLT AsianOption"] = bench_integrate() do
    dd = IIDStdUniform(50; seed=42)
    tm = GeometricBrownianMotion(dd; volatility=0.2, start_price=100.0,
                                  interest_rate=0.05, t_final=1.0)
    f = FinancialOption(tm; option_type=:asian, strike_price=100.0)
    CubMCCLT(f; abs_tol=0.5)
end

SUITE["integrate"]["CubQMCNetG EuropeanOption"] = bench_integrate() do
    dd = DigitalNetB2(50; seed=42, randomize="LMS_DS")
    tm = GeometricBrownianMotion(dd; volatility=0.2, start_price=100.0,
                                  interest_rate=0.05, t_final=1.0)
    f = FinancialOption(tm; option_type=:european, strike_price=100.0)
    CubQMCNetG(f; abs_tol=0.5)
end
