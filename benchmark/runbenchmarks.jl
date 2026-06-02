# Standalone benchmark runner.
#
# Usage (from the repository root):
#   julia benchmark/runbenchmarks.jl            # run and save to results/latest.json
#   julia benchmark/runbenchmarks.jl mylabel    # save to results/mylabel.json instead
#
# Bootstraps the benchmark environment on first run (activate benchmark/, develop
# the parent QMC package, install deps), then runs SUITE (defined in benchmarks.jl)
# and writes a BenchmarkTools result file that can be `judged` against another run:
#
#   using BenchmarkTools
#   base = BenchmarkTools.load("benchmark/results/baseline.json")[1]
#   new  = BenchmarkTools.load("benchmark/results/latest.json")[1]
#   judge(median(new), median(base))   # time + memory ratios per benchmark

using Pkg
Pkg.activate(@__DIR__)
let deps = keys(Pkg.project().dependencies)
    "QMC" in deps || Pkg.develop(; path = dirname(@__DIR__))
    "BenchmarkTools" in deps || Pkg.add("BenchmarkTools")
end
Pkg.instantiate()

using BenchmarkTools
using Statistics
using Printf

include(joinpath(@__DIR__, "benchmarks.jl"))   # defines SUITE (and silences expected warnings)

label = isempty(ARGS) ? "latest" : ARGS[1]

println("QMC.jl Benchmarks")
println("="^70)

results = run(SUITE; verbose = true)

# ── Summary ──────────────────────────────────────────────────────────────
println("\n", "="^70)
println("Summary")
println("="^70)
for group_name in sort(collect(keys(results)))
    println("\n── $group_name ──")
    group = results[group_name]
    for bench_name in sort(collect(keys(group)))
        med = median(group[bench_name])
        @printf("  %-45s  %10.3f ms  (%d allocs, %.1f KiB)\n",
            bench_name, med.time / 1e6, med.allocs, med.memory / 1024)
    end
end

# ── Save ───────────────────────────────────────────────────────────────────
resdir = joinpath(@__DIR__, "results")
mkpath(resdir)
outfile = joinpath(resdir, "$(label).json")
BenchmarkTools.save(outfile, results)
println("\nResults saved to benchmark/results/$(label).json")
