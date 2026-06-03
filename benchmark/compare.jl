# Compare benchmark results across git revisions using PkgBenchmark.jl.
#
# Usage (from the repository root):
#   julia benchmark/compare.jl                  # benchmark the current working tree only
#   julia benchmark/compare.jl main             # compare working tree (incl. uncommitted
#                                               #   changes) against `main`
#   julia benchmark/compare.jl HEAD main        # compare one committed revision against another
#
# Output: benchmark/results/compare_head.md
#
# Ratio convention (same as compare_py.jl):
#   ratio = reference time ÷ local time
#   ratio < 1  →  local is SLOWER than reference  ❌
#   ratio > 1  →  local is FASTER than reference  ✅
#
# Dirty-tree friendly: a baseline/target *revision* is benchmarked inside a
# temporary `git worktree`, so uncommitted changes are never stashed or
# checked out. The literal "current working tree" is benchmarked in place and may
# be dirty. (Both revisions must still post-date the `SUITE` refactor, since
# PkgBenchmark runs each revision's own benchmarks.jl.)

using Pkg
Pkg.activate(@__DIR__)
let deps = keys(Pkg.project().dependencies)
    "QMC" in deps || Pkg.develop(; path = dirname(@__DIR__))
    "PkgBenchmark" in deps || Pkg.add("PkgBenchmark")
end
Pkg.instantiate()

using PkgBenchmark
using Printf

const PKG = dirname(@__DIR__)
const RESDIR = joinpath(@__DIR__, "results")
mkpath(RESDIR)

"""
    write_comparison_md(outfile, target_result, baseline_result, target_label, baseline_label)

Write a Markdown comparison table to `outfile`.

Ratio = reference (`baseline_label`) time ÷ local (`target_label`) time.
  - ratio < 1  →  local is **slower** than reference  ❌
  - ratio > 1  →  local is **faster** than reference  ✅
"""
function write_comparison_md(outfile, target_result, baseline_result,
                             target_label, baseline_label)
    tg = target_result.benchmarkgroup
    bg = baseline_result.benchmarkgroup
    open(outfile, "w") do io
        println(io, "# Benchmark: `$(target_label)` vs `$(baseline_label)`\n")
        println(io, "| | local (`$(target_label)`) | reference (`$(baseline_label)`) |")
        println(io, "|---|---|---|")
        println(io, "| commit | $(target_result.commit) | $(baseline_result.commit) |")
        println(io, "| date | $(target_result.date) | $(baseline_result.date) |")
        println(io, "")
        println(io, "**`ratio = reference time ÷ local time`**  ")
        println(io, "ratio `< 1` → local is **slower** ❌  |  ratio `> 1` → local is **faster** ✅")
        println(io, "")
        println(io, "| benchmark | ratio | verdict | local (ms) | reference (ms) |")
        println(io, "|:----------|------:|:-------:|----------:|---------------:|")
        for group in sort(collect(keys(tg)))
            haskey(bg, group) || continue
            for name in sort(collect(keys(tg[group])))
                haskey(bg[group], name) || continue
                local_ms = median(tg[group][name]).time / 1e6
                ref_ms   = median(bg[group][name]).time / 1e6
                ratio    = ref_ms / local_ms
                verdict  = ratio < 0.95 ? "❌" : ratio > 1.05 ? "✅" : "–"
                @printf(io, "| `[\"%s\", \"%s\"]` | %.3f | %s | %.3f | %.3f |\n",
                        group, name, ratio, verdict, local_ms, ref_ms)
            end
        end
    end
end

"Benchmark the current working tree in place (uncommitted changes included)."
bench_worktree() = benchmarkpkg(PKG)

"True if `rev` contains a benchmark/benchmarks.jl that defines `SUITE`."
function revision_has_suite(rev::AbstractString)
    out = try
        read(`git -C $PKG show $(rev):benchmark/benchmarks.jl`, String)
    catch
        return false   # file absent at that revision
    end
    return occursin("SUITE", out)
end

"Benchmark a committed `rev` in a throwaway git worktree, leaving PKG untouched."
function bench_revision(rev::AbstractString)
    if !success(`git -C $PKG rev-parse --verify --quiet $rev`)
        error("git revision \"$rev\" not found in this repository. Pass a valid " *
              "branch/tag/commit, e.g. `make bench-compare REV=HEAD` (compare " *
              "uncommitted changes against the last commit) or `REV=master`.")
    end
    if !revision_has_suite(rev)
        error("""
              Revision "$rev" does not contain the PkgBenchmark `SUITE` harness
              (a benchmark/benchmarks.jl that defines `const SUITE`). PkgBenchmark
              runs each revision's own harness, so both sides must already have it —
              and the benchmark tooling is currently UNCOMMITTED, so it is absent at
              "$rev". Either:
                * commit the benchmark tooling first, then compare later revisions; or
                * for a git-free A/B on the current machine, use the manual flow:
                    julia benchmark/runbenchmarks.jl a   # state A -> results/a.json
                    julia benchmark/runbenchmarks.jl b   # state B -> results/b.json
                  then in Julia:
                    using BenchmarkTools
                    judge(median(BenchmarkTools.load("benchmark/results/b.json")[1]),
                          median(BenchmarkTools.load("benchmark/results/a.json")[1]))
              """)
    end
    parent = mktempdir()
    wt = joinpath(parent, "wt")   # must not pre-exist; `git worktree add` creates it
    run(`git -C $PKG worktree add --quiet --detach $wt $rev`)
    try
        return benchmarkpkg(wt)
    finally
        try
            run(`git -C $PKG worktree remove --force $wt`)
        catch
        end
        rm(parent; force = true, recursive = true)
    end
end

if length(ARGS) == 0
    result = bench_worktree()
    outfile = joinpath(RESDIR, "bench_local.md")
    export_markdown(outfile, result)
    println("\nWrote benchmark/results/bench_local.md (single-run summary, no comparison)")
elseif length(ARGS) == 1
    baseline_rev = ARGS[1]
    target   = bench_worktree()              # current tree (dirty OK)
    baseline = bench_revision(baseline_rev)
    outfile  = joinpath(RESDIR, "compare_head.md")
    write_comparison_md(outfile, target, baseline, "local", baseline_rev)
    println("\nWrote benchmark/results/compare_head.md (local vs $(baseline_rev))")
    println("  ratio = $(baseline_rev) ÷ local  →  < 1: local slower  |  > 1: local faster")
else
    target_rev, baseline_rev = ARGS[1], ARGS[2]
    target   = bench_revision(target_rev)
    baseline = bench_revision(baseline_rev)
    outfile  = joinpath(RESDIR, "compare_head.md")
    write_comparison_md(outfile, target, baseline, target_rev, baseline_rev)
    println("\nWrote benchmark/results/compare_head.md ($(target_rev) vs $(baseline_rev))")
    println("  ratio = $(baseline_rev) ÷ $(target_rev)  →  < 1: $(target_rev) slower  |  > 1: $(target_rev) faster")
end
