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
using JSON3

include(joinpath(@__DIR__, "benchmarks.jl"))   # defines SUITE (and silences expected warnings)

label = isempty(ARGS) ? "latest" : ARGS[1]

function current_rss_kib()
    out = read(`ps -o rss= -p $(getpid())`, String)
    return parse(Float64, strip(out))
end

function measure_rss_delta_kib(bench::BenchmarkTools.Benchmark)
    # Warm once so retained-memory deltas reflect steady-state behavior rather
    # than first-call compilation/cache effects inside the benchmarkable body.
    # NOTE: `seconds` is a per-benchmark time limit and BenchmarkTools requires it
    # to be > 0 (seconds = 0.0 throws "time limit must be greater than 0.0"). With
    # samples = 1 the run stops after a single sample regardless, so any positive
    # limit works; 1.0 is a comfortable cap.
    run(bench; samples = 1, evals = 1, seconds = 1.0)
    GC.gc()
    GC.gc()
    rss_before = current_rss_kib()
    run(bench; samples = 1, evals = 1, seconds = 1.0)
    GC.gc()
    GC.gc()
    rss_after = current_rss_kib()
    return max(rss_after - rss_before, 0.0)
end

function collect_rss_deltas(group::BenchmarkTools.BenchmarkGroup)
    out = Dict{String, Any}()
    for group_name in sort(collect(keys(group)))
        subgroup = group[group_name]
        rows = Dict{String, Any}()
        for bench_name in sort(collect(keys(subgroup)))
            rows[string(bench_name)] = Dict(
                "rss_delta_kib" => measure_rss_delta_kib(subgroup[bench_name]),
            )
        end
        out[string(group_name)] = rows
    end
    return out
end

println("QMC.jl Benchmarks")
println("="^70)

results = run(SUITE; verbose = true)
julia_memory = collect_rss_deltas(SUITE)

# ── Summary ──────────────────────────────────────────────────────────────
println("\n", "="^70)
println("Summary")
println("="^70)
for group_name in sort(collect(keys(results)))
    println("\n── $group_name ──")
    group = results[group_name]
    for bench_name in sort(collect(keys(group)))
        med = median(group[bench_name])
        rss_delta = julia_memory[string(group_name)][string(bench_name)]["rss_delta_kib"]
        @printf("  %-45s  %10.3f ms  (%d allocs, %.1f KiB, rss Δ %.1f KiB)\n",
            bench_name, med.time / 1e6, med.allocs, med.memory / 1024, rss_delta)
    end
end

# ── Save ───────────────────────────────────────────────────────────────────
resdir = joinpath(@__DIR__, "results")
mkpath(resdir)
outfile = joinpath(resdir, "$(label).json")
BenchmarkTools.save(outfile, results)
memfile = joinpath(resdir, "$(label)_memory.json")
# JSON3.pretty(str) prints to stdout and returns `nothing`; pass an IO target so the
# pretty-printed JSON is written to the file instead.
open(memfile, "w") do io
    JSON3.pretty(io, JSON3.write(Dict(
        "julia_version" => string(VERSION),
        "results" => julia_memory,
    )))
end
println("\nResults saved to benchmark/results/$(label).json")
println("Julia memory sidecar saved to benchmark/results/$(label)_memory.json")
