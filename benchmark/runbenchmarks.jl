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
    "QMC" in deps || Pkg.develop(; path=dirname(@__DIR__))
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
    run(bench; samples=1, evals=1, seconds=1.0)
    GC.gc()
    GC.gc()
    rss_before = current_rss_kib()
    run(bench; samples=1, evals=1, seconds=1.0)
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
            rows[string(bench_name)] =
                Dict("rss_delta_kib" => measure_rss_delta_kib(subgroup[bench_name]))
        end
        out[string(group_name)] = rows
    end
    return out
end

maybe_exact_value(f) =
    if f isa Keister
        return keister_exact(f.dimension)
    elseif f isa Genz
        exact = genz_exact(f)
        return isfinite(exact) ? exact : nothing
    elseif f isa FinancialOption
        try
            return get_exact_value(f)
        catch
            return nothing
        end
    else
        return nothing
    end

function exact_accuracy_check(solution, exact_value, abs_tol, rel_tol)
    diff = abs(solution - exact_value)
    eff_tol = max(abs_tol, rel_tol * abs(exact_value))
    rel_diff = exact_value != 0 ? diff / abs(exact_value) : NaN
    # Use 2×tol as a smoke threshold to reduce false positives from randomized
    # runs while still surfacing clear correctness regressions.
    allowed = 2 * eff_tol
    return (
        diff=diff,
        rel_diff=rel_diff,
        eff_tol=eff_tol,
        allowed=allowed,
        flagged=diff > allowed,
    )
end

"""
    run_suite(suite) -> BenchmarkGroup

Run every leaf of `suite`, printing rounded per-benchmark progress. Replaces
`run(suite; verbose=true)`, whose progress line prints full-precision seconds
(`done (took 0.211567875 seconds)`) with no formatting hook.
"""
function run_suite(suite)
    results = BenchmarkGroup()
    groups = sort(collect(keys(suite)))
    total = sum(length(keys(suite[g])) for g in groups)
    i = 0
    for g in groups
        results[g] = BenchmarkGroup()
        for name in sort(collect(keys(suite[g])))
            i += 1
            @printf("(%d/%d) benchmarking %s / %s ...\n", i, total, g, name)
            t0 = time()
            results[g][name] = run(suite[g][name])
            @printf("  done (took %.3f seconds)\n", time() - t0)
        end
    end
    return results
end

"""
    collect_integrate_solutions() -> Dict

Run each integrate case once (outside the timing loop) and record its
solution value and the tolerances it was configured with. Used by the
Julia-vs-Python accuracy check in `compare_py.jl` and by the standalone exact-
value smoke summary. Relies on `INTEGRATE_CASES` from benchmarks.jl.
"""
function collect_integrate_solutions()
    out = Dict{String, Any}()
    for (name, make_sc) in INTEGRATE_CASES
        try
            sc = make_sc()
            res = integrate(sc)
            entry = Dict(
                "solution" => float(res.solution),
                "abs_tol" => float(sc.abs_tol),
                "rel_tol" => float(sc.rel_tol),
            )
            exact_value = maybe_exact_value(sc.integrand)
            if exact_value !== nothing
                check = exact_accuracy_check(res.solution, exact_value, sc.abs_tol, sc.rel_tol)
                entry["exact_value"] = float(exact_value)
                entry["abs_error"] = check.diff
                entry["rel_error"] = check.rel_diff
                entry["effective_tol"] = check.eff_tol
                entry["allowed_error"] = check.allowed
                entry["exact_flagged"] = check.flagged
            end
            out[name] = entry
        catch err
            out[name] = Dict("error" => sprint(showerror, err))
        end
    end
    return out
end

function print_integrate_accuracy_summary(julia_solutions)
    rows = NamedTuple[]
    for name in sort(collect(keys(julia_solutions)))
        entry = julia_solutions[name]
        haskey(entry, "error") && continue
        haskey(entry, "exact_value") || continue
        push!(
            rows,
            (
                name=name,
                solution=Float64(entry["solution"]),
                exact_value=Float64(entry["exact_value"]),
                abs_error=Float64(entry["abs_error"]),
                rel_error=Float64(entry["rel_error"]),
                allowed=Float64(entry["allowed_error"]),
                flagged=Bool(entry["exact_flagged"]),
            ),
        )
    end

    isempty(rows) && return

    println("\n", "="^70)
    println("Integration Accuracy (vs exact)")
    println("="^70)
    flagged = 0
    for row in rows
        mark = row.flagged ? "!!" : "ok"
        flagged += row.flagged
        rel_txt = isnan(row.rel_error) ? "n/a" : @sprintf("%.2e", row.rel_error)
        @printf(
            "  %-37s exact=%- 12.6g  est=%- 12.6g  |Δ|=%.3g  rel=%8s  smoke(2·tol)=%.3g  %s\n",
            row.name,
            row.exact_value,
            row.solution,
            row.abs_error,
            rel_txt,
            row.allowed,
            mark
        )
    end
    @printf("%d of %d exact-check case(s) exceed 2×tolerance\n", flagged, length(rows))
end

println("QMC.jl Benchmarks")
println("="^70)

results = run_suite(SUITE)
julia_memory = collect_rss_deltas(SUITE)
julia_solutions = collect_integrate_solutions()

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
        @printf(
            "  %-45s  %10.3f ms  (%d allocs, %.1f KiB, rss Δ %.1f KiB)\n",
            bench_name,
            med.time / 1e6,
            med.allocs,
            med.memory / 1024,
            rss_delta
        )
    end
end
print_integrate_accuracy_summary(julia_solutions)

# ── Save ───────────────────────────────────────────────────────────────────
resdir = joinpath(@__DIR__, "results")
mkpath(resdir)
outfile = joinpath(resdir, "$(label).json")
BenchmarkTools.save(outfile, results)
memfile = joinpath(resdir, "$(label)_memory.json")
# JSON3.pretty(str) prints to stdout and returns `nothing`; pass an IO target so the
# pretty-printed JSON is written to the file instead.
open(memfile, "w") do io
    JSON3.pretty(
        io,
        JSON3.write(Dict("julia_version" => string(VERSION), "results" => julia_memory)),
    )
end
println("\nResults saved to benchmark/results/$(label).json")
println("Julia memory sidecar saved to benchmark/results/$(label)_memory.json")

solfile = joinpath(resdir, "$(label)_solutions.json")
open(solfile, "w") do io
    JSON3.pretty(
        io,
        JSON3.write(Dict("julia_version" => string(VERSION), "solutions" => julia_solutions)),
    )
end
println("Julia solution sidecar saved to benchmark/results/$(label)_solutions.json\n\n")
