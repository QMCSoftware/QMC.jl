# QMC.jl Benchmark Suite
#
# Usage (from the repository root):
#   julia benchmark/benchmarks.jl
#
# The script uses its own environment in `benchmark/` (see benchmark/Project.toml)
# so BenchmarkTools is not pulled into the main package deps. It bootstraps that
# environment on first run: activating it, developing the parent QMC package, and
# installing BenchmarkTools. No `--project` flag or manual `Pkg.add` is needed.

using Pkg
Pkg.activate(@__DIR__)
let deps = keys(Pkg.project().dependencies)
    "QMC" in deps || Pkg.develop(; path = dirname(@__DIR__))
    "BenchmarkTools" in deps || Pkg.add("BenchmarkTools")
end
Pkg.instantiate()

using QMC
using BenchmarkTools
using Statistics
using Printf
using Logging
import QMC: Uniform

# ── Configuration ─────────────────────────────────────────────────────────

const SAMPLES = [256, 1024, 4096, 16384]
const DIMS = [3, 10]

# ── Helpers ───────────────────────────────────────────────────────────────

function bench_gen_samples(dd_constructor, dim, n; kwargs...)
    dd = dd_constructor(dim; seed=42, kwargs...)
    @benchmarkable gen_samples($dd, $n) evals=3 samples=5
end

function bench_integrate(make_sc; kwargs...)
    @benchmarkable integrate(sc) evals=1 samples=3 setup=(sc = $make_sc())
end

# ── Benchmark Groups ─────────────────────────────────────────────────────

suite = BenchmarkGroup()

# 1. Discrete Distribution sampling
suite["gen_samples"] = BenchmarkGroup()
for dim in DIMS, n in SAMPLES
    suite["gen_samples"]["IIDStdUniform d=$dim n=$n"] =
        bench_gen_samples(IIDStdUniform, dim, n)
    suite["gen_samples"]["Lattice d=$dim n=$n"] =
        bench_gen_samples(Lattice, dim, n; randomize=true)
    suite["gen_samples"]["DigitalNetB2 d=$dim n=$n"] =
        bench_gen_samples(DigitalNetB2, dim, n; randomize="LMS_DS")
    suite["gen_samples"]["Halton d=$dim n=$n"] =
        bench_gen_samples(Halton, dim, n; randomize=true)
    suite["gen_samples"]["Kronecker d=$dim n=$n"] =
        bench_gen_samples(Kronecker, dim, n)
end

# 2. Transform
suite["transform"] = BenchmarkGroup()
for dim in DIMS, n in SAMPLES
    dd = IIDStdUniform(dim; seed=42)
    tm_gauss = Gaussian(dd)
    x = gen_samples(dd, n)
    suite["transform"]["Gaussian d=$dim n=$n"] =
        @benchmarkable transform($tm_gauss, $x) evals=3 samples=5
end

# 3. Integrand evaluation
suite["evaluate"] = BenchmarkGroup()
for n in SAMPLES
    dd = IIDStdUniform(3; seed=42)
    tm = Gaussian(dd)
    x = transform(tm, gen_samples(dd, n))

    f_keister = Keister(tm)
    suite["evaluate"]["Keister n=$n"] =
        @benchmarkable evaluate($f_keister, $x) evals=3 samples=5

    f_genz = Genz(tm; kind=:continuous)
    suite["evaluate"]["Genz(continuous) n=$n"] =
        @benchmarkable evaluate($f_genz, $x) evals=3 samples=5
end

# 4. End-to-end integration
suite["integrate"] = BenchmarkGroup()

suite["integrate"]["CubMCCLT Keister"] = bench_integrate() do
    dd = IIDStdUniform(3; seed=42)
    tm = Gaussian(dd)
    f = Keister(tm)
    CubMCCLT(f; abs_tol=0.01)
end

suite["integrate"]["CubQMCLatticeG Keister"] = bench_integrate() do
    dd = Lattice(3; seed=42, randomize=true)
    tm = Gaussian(dd)
    f = Keister(tm)
    CubQMCLatticeG(f; abs_tol=0.01)
end

suite["integrate"]["CubQMCNetG Keister"] = bench_integrate() do
    dd = DigitalNetB2(3; seed=42, randomize="LMS_DS")
    tm = Gaussian(dd)
    f = Keister(tm)
    CubQMCNetG(f; abs_tol=0.01)
end

suite["integrate"]["CubMCCLT AsianOption"] = bench_integrate() do
    dd = IIDStdUniform(50; seed=42)
    tm = GeometricBrownianMotion(dd; volatility=0.2, start_price=100.0,
                                  interest_rate=0.05, t_final=1.0)
    f = FinancialOption(tm; option_type=:asian, strike_price=100.0)
    CubMCCLT(f; abs_tol=0.5)
end

suite["integrate"]["CubQMCNetG EuropeanOption"] = bench_integrate() do
    dd = DigitalNetB2(50; seed=42, randomize="LMS_DS")
    tm = GeometricBrownianMotion(dd; volatility=0.2, start_price=100.0,
                                  interest_rate=0.05, t_final=1.0)
    f = FinancialOption(tm; option_type=:european, strike_price=100.0)
    CubQMCNetG(f; abs_tol=0.5)
end

# ── Run ──────────────────────────────────────────────────────────────────

println("QMC.jl Benchmarks")
println("=" ^ 70)

# CubMCCLT is a faithful single-pass two-stage estimator: its realized error can
# land just above the requested tolerance whenever the main-stage variance
# exceeds the pilot estimate, which correctly emits a non-convergence warning.
# That is expected and irrelevant here — we are timing, not checking accuracy —
# so warnings are silenced for the duration of the run to keep output readable.
results = with_logger(ConsoleLogger(stderr, Logging.Error)) do
    run(suite; verbose=true)
end

# ── Summary ──────────────────────────────────────────────────────────────

println("\n", "=" ^ 70)
println("Summary")
println("=" ^ 70)

for group_name in sort(collect(keys(results)))
    println("\n── $group_name ──")
    group = results[group_name]
    for bench_name in sort(collect(keys(group)))
        t = group[bench_name]
        med = median(t)
        @printf("  %-45s  %10.3f ms  (%d allocs, %.1f KiB)\n",
                bench_name,
                med.time / 1e6,
                med.allocs,
                med.memory / 1024)
    end
end

# Save results
using BenchmarkTools: save
mkpath(joinpath(@__DIR__, "results"))
save(joinpath(@__DIR__, "results", "latest.json"), results)
println("\nResults saved to benchmark/results/latest.json")
