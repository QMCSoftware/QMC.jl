# Compare benchmark results across git revisions using PkgBenchmark.jl.
#
# Usage (from the repository root):
#   julia benchmark/compare.jl                  # benchmark the current working tree only
#   julia benchmark/compare.jl main             # compare working tree (incl. uncommitted
#                                               #   changes) against `main`
#   julia benchmark/compare.jl HEAD main        # compare one committed revision against another
#
# Output: benchmark/results/compare_head.md by default, or compare_<label>.md
#
# Ratio convention (same as compare_py.jl):
#   ratio = reference time ÷ local time
#   ratio < 1  →  local is SLOWER than reference  ❌
#   ratio > 1  →  local is FASTER than reference  ✅
#
# Dirty-tree friendly: a baseline/target *revision* is benchmarked inside a
# temporary `git worktree`, so uncommitted changes are never stashed or
# checked out. The literal "current working tree" is benchmarked in place and may
# be dirty. The CURRENT benchmark/benchmarks.jl is copied into the revision's
# worktree before benchmarking, so both sides run the same suite against their own
# package source — an old or broken benchmarks.jl committed at the revision does
# not affect the comparison.

using Pkg
Pkg.activate(@__DIR__)
let deps = keys(Pkg.project().dependencies)
    "QMC" in deps || Pkg.develop(; path=dirname(@__DIR__))
    "BenchmarkTools" in deps || Pkg.add("BenchmarkTools")
    "PkgBenchmark" in deps || Pkg.add("PkgBenchmark")
end
Pkg.instantiate()

using PkgBenchmark
using BenchmarkTools: median
using Printf

const PKG = dirname(@__DIR__)
const RESDIR = joinpath(@__DIR__, "results")
mkpath(RESDIR)

comparison_outfile(label::AbstractString) =
    isempty(label) ? joinpath(RESDIR, "compare_head.md") :
    joinpath(RESDIR, "compare_$(label).md")

"Return comparable per-benchmark rows extracted from two benchmark results."
function collect_comparison_rows(target_result, baseline_result)
    tg = target_result.benchmarkgroup
    bg = baseline_result.benchmarkgroup
    rows = NamedTuple[]
    for group in sort(collect(keys(tg)))
        haskey(bg, group) || continue
        for name in sort(collect(keys(tg[group])))
            haskey(bg[group], name) || continue
            local_trial = median(tg[group][name])
            ref_trial = median(bg[group][name])
            push!(
                rows,
                (
                    group=group,
                    name=name,
                    local_ms=(local_trial.time / 1e6),
                    ref_ms=(ref_trial.time / 1e6),
                    local_kib=(local_trial.memory / 1024),
                    ref_kib=(ref_trial.memory / 1024),
                ),
            )
        end
    end
    return rows
end

"Weighted summary ratios using local totals as weights."
function summary_metrics(rows)
    total_local_ms = sum(row.local_ms for row in rows)
    total_ref_ms = sum(row.ref_ms for row in rows)
    total_local_kib = sum(row.local_kib for row in rows)
    total_ref_kib = sum(row.ref_kib for row in rows)
    return (
        matched=length(rows),
        local_ms=total_local_ms,
        ref_ms=total_ref_ms,
        time_ratio=total_local_ms > 0 ? total_ref_ms / total_local_ms : NaN,
        local_kib=total_local_kib,
        ref_kib=total_ref_kib,
        memory_ratio=total_local_kib > 0 ? total_ref_kib / total_local_kib : NaN,
    )
end

"Write a sanitized single-run benchmark summary without host or path metadata."
function write_single_run_md(outfile, result; label="local")
    groupdata = result.benchmarkgroup
    open(outfile, "w") do io
        println(io, "# Benchmark: `$(label)`\n")
        println(io, "| benchmark | median time (ms) | allocs | memory (KiB) |")
        println(io, "|:----------|-----------------:|-------:|-------------:|")
        for group in sort(collect(keys(groupdata)))
            for name in sort(collect(keys(groupdata[group])))
                trial = median(groupdata[group][name])
                @printf(
                    io,
                    "| `[\"%s\", \"%s\"]` | %.3f | %d | %.1f |\n",
                    group,
                    name,
                    trial.time / 1e6,
                    trial.allocs,
                    trial.memory / 1024
                )
            end
        end
    end
end

"""
    write_comparison_md(outfile, target_result, baseline_result, target_label, baseline_label)

Write a Markdown comparison table to `outfile`.

Ratio = reference (`baseline_label`) time ÷ local (`target_label`) time.
  - ratio < 1  →  local is **slower** than reference  ❌
  - ratio > 1  →  local is **faster** than reference  ✅
"""
function write_comparison_md(
    outfile,
    target_result,
    baseline_result,
    target_label,
    baseline_label,
)
    rows = collect_comparison_rows(target_result, baseline_result)
    summary = summary_metrics(rows)
    open(outfile, "w") do io
        println(io, "# Benchmark: `$(target_label)` vs `$(baseline_label)`\n")
        println(io, "| | local (`$(target_label)`) | reference (`$(baseline_label)`) |")
        println(io, "|---|---|---|")
        println(io, "| commit | $(target_result.commit) | $(baseline_result.commit) |")
        println(io, "| date | $(target_result.date) | $(baseline_result.date) |")
        println(io, "")
        println(io, "**`ratio = reference time ÷ local time`**  ")
        println(
            io,
            "ratio `< 1` → local is **slower** ❌  |  ratio `> 1` → local is **faster** ✅",
        )
        println(io, "")
        println(io, "## Aggregate Summary\n")
        println(io, "| metric | ratio | local total | reference total |")
        println(io, "|:-------|------:|------------:|----------------:|")
        println(io, "| matched benchmarks | $(summary.matched) | — | — |")
        @printf(
            io,
            "| weighted time ratio | %.3f | %.3f ms | %.3f ms |\n",
            summary.time_ratio,
            summary.local_ms,
            summary.ref_ms
        )
        @printf(
            io,
            "| weighted memory ratio | %.3f | %.1f KiB | %.1f KiB |\n\n",
            summary.memory_ratio,
            summary.local_kib,
            summary.ref_kib
        )
        println(io, "| benchmark | ratio | verdict | local (ms) | reference (ms) |")
        println(io, "|:----------|------:|:-------:|----------:|---------------:|")
        for row in rows
            ratio = row.ref_ms / row.local_ms
            verdict = ratio < 0.95 ? "❌" : ratio > 1.05 ? "✅" : "–"
            @printf(
                io,
                "| `[\"%s\", \"%s\"]` | %.3f | %s | %.3f | %.3f |\n",
                row.group,
                row.name,
                ratio,
                verdict,
                row.local_ms,
                row.ref_ms
            )
        end
    end
    return summary
end

"Benchmark the current working tree in place (uncommitted changes included)."
bench_worktree() = benchmarkpkg(PKG; verbose=false)

"Run `f()` with `project_dir` active and `pkgdir` developed as `QMC`."
function with_benchmark_env(
    project_dir::AbstractString,
    pkgdir::AbstractString,
    f::Function,
)
    original_project = Base.active_project()
    try
        Pkg.activate(project_dir; io=devnull)
        Pkg.develop(; path=pkgdir, io=devnull)
        Pkg.instantiate(; io=devnull)
        return f()
    finally
        if original_project !== nothing
            Pkg.activate(dirname(original_project); io=devnull)
        end
    end
end

"Benchmark a committed `rev` in a throwaway git worktree, leaving PKG untouched.
The current benchmark/benchmarks.jl is copied into the worktree first, so the
revision's own (possibly old or broken) benchmarks.jl is never used — both sides
run today's suite against their respective package source."
function bench_revision(rev::AbstractString)
    if !success(`git -C $PKG rev-parse --verify --quiet $rev`)
        error(
            "git revision \"$rev\" not found in this repository. Pass a valid " *
            "branch/tag/commit, e.g. `make bench-compare REV=HEAD` (compare " *
            "uncommitted changes against the last commit) or `REV=master`.",
        )
    end
    parent = mktempdir()
    wt = joinpath(parent, "wt")   # must not pre-exist; `git worktree add` creates it
    run(`git -C $PKG worktree add --quiet --detach $wt $rev`)
    try
        # Run the CURRENT benchmark suite against the revision's package source, so
        # an old/broken benchmarks.jl committed at `rev` doesn't break the run and
        # both sides measure the same suite.
        cp(
            joinpath(PKG, "benchmark", "benchmarks.jl"),
            joinpath(wt, "benchmark", "benchmarks.jl");
            force=true,
        )
        # Commit the synced suite inside the throwaway worktree so its working tree
        # is clean. PkgBenchmark checks out the commit it benchmarks and then tries
        # to restore the original sha; on a *dirty* detached worktree that restore
        # fails and emits "Failed to return back to original sha …". A clean tree
        # avoids the stash/checkout dance. This only moves the worktree's detached
        # HEAD (the main repo and `rev` are untouched), and the worktree is removed
        # below regardless.
        try
            run(`git -C $wt add -A`)
            run(
                pipeline(
                    `git -C $wt -c user.email=bench@localhost -c user.name=bench commit -q --allow-empty -m bench-sync-suite`;
                    stdout=devnull,
                    stderr=devnull,
                ),
            )
        catch
            # If committing fails (e.g. git identity unavailable), benchmarking
            # still works; PkgBenchmark may just re-emit its restore warning.
        end
        return with_benchmark_env(
            joinpath(wt, "benchmark"),
            wt,
            () -> benchmarkpkg(wt; verbose=false),
        )
    finally
        try
            run(`git -C $PKG worktree remove --force $wt`)
        catch
        end
        rm(parent; force=true, recursive=true)
    end
end

if length(ARGS) == 0
    result = bench_worktree()
    outfile = joinpath(RESDIR, "bench_local.md")
    write_single_run_md(outfile, result)
    println("\nWrote benchmark/results/bench_local.md (single-run summary, no comparison)")
elseif length(ARGS) == 1
    baseline_rev = ARGS[1]
    target = bench_worktree()              # current tree (dirty OK)
    baseline = bench_revision(baseline_rev)
    outfile = comparison_outfile("")
    summary = write_comparison_md(outfile, target, baseline, "local", baseline_rev)
    println("\nWrote benchmark/results/$(basename(outfile)) (local vs $(baseline_rev))")
    println("  ratio = $(baseline_rev) ÷ local  →  < 1: local slower  |  > 1: local faster")
    @printf(
        "  weighted time ratio   = %.3f  (%s total %.3f ms vs %s total %.3f ms)\n",
        summary.time_ratio,
        baseline_rev,
        summary.ref_ms,
        "local",
        summary.local_ms
    )
    @printf(
        "  weighted memory ratio = %.3f  (%s total %.1f KiB vs %s total %.1f KiB)\n",
        summary.memory_ratio,
        baseline_rev,
        summary.ref_kib,
        "local",
        summary.local_kib
    )
elseif length(ARGS) == 2
    baseline_rev, out_label = ARGS[1], ARGS[2]
    target = bench_worktree()              # current tree (dirty OK)
    baseline = bench_revision(baseline_rev)
    outfile = comparison_outfile(out_label)
    summary = write_comparison_md(outfile, target, baseline, "local", baseline_rev)
    println("\nWrote benchmark/results/$(basename(outfile)) (local vs $(baseline_rev))")
    println("  ratio = $(baseline_rev) ÷ local  →  < 1: local slower  |  > 1: local faster")
    @printf(
        "  weighted time ratio   = %.3f  (%s total %.3f ms vs %s total %.3f ms)\n",
        summary.time_ratio,
        baseline_rev,
        summary.ref_ms,
        "local",
        summary.local_ms
    )
    @printf(
        "  weighted memory ratio = %.3f  (%s total %.1f KiB vs %s total %.1f KiB)\n",
        summary.memory_ratio,
        baseline_rev,
        summary.ref_kib,
        "local",
        summary.local_kib
    )
elseif length(ARGS) == 3
    target_rev, baseline_rev = ARGS[1], ARGS[2]
    target = bench_revision(target_rev)
    baseline = bench_revision(baseline_rev)
    outfile = comparison_outfile(ARGS[3])
    summary = write_comparison_md(outfile, target, baseline, target_rev, baseline_rev)
    println(
        "\nWrote benchmark/results/$(basename(outfile)) ($(target_rev) vs $(baseline_rev))",
    )
    println(
        "  ratio = $(baseline_rev) ÷ $(target_rev)  →  < 1: $(target_rev) slower  |  > 1: $(target_rev) faster",
    )
    @printf(
        "  weighted time ratio   = %.3f  (%s total %.3f ms vs %s total %.3f ms)\n",
        summary.time_ratio,
        baseline_rev,
        summary.ref_ms,
        target_rev,
        summary.local_ms
    )
    @printf(
        "  weighted memory ratio = %.3f  (%s total %.1f KiB vs %s total %.1f KiB)\n",
        summary.memory_ratio,
        baseline_rev,
        summary.ref_kib,
        target_rev,
        summary.local_kib
    )
else
    error(
        "Usage: julia benchmark/compare.jl [baseline_rev [output_label]] or julia benchmark/compare.jl target_rev baseline_rev output_label",
    )
end
