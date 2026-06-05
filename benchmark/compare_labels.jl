# Compare two saved Julia benchmark result labels.
#
# Usage (from the repository root):
#   julia benchmark/compare_labels.jl a b          # -> compare_labels_a_vs_b.md
#   julia benchmark/compare_labels.jl a b report   # -> compare_labels_report.md
#
# Input files:
#   benchmark/results/a.json
#   benchmark/results/b.json
#
# Ratio convention:
#   ratio = B ÷ A
#   ratio > 1  →  A is better
#   ratio < 1  →  B is better
#
# "Better" is decided from aggregate weighted totals:
#   * weighted time ratio   = total_B_ms  / total_A_ms
#   * weighted memory ratio = total_B_kib / total_A_kib
# If one label wins both time and memory beyond tolerance, it wins overall.
# Otherwise a combined score sqrt(time_ratio * memory_ratio) breaks the tie.

using Pkg
Pkg.activate(@__DIR__)
let deps = keys(Pkg.project().dependencies)
    "BenchmarkTools" in deps || Pkg.add("BenchmarkTools")
end
Pkg.instantiate()

using BenchmarkTools: load, median
using Printf

const RESDIR = joinpath(@__DIR__, "results")
const TOL = 0.05

compare_labels_outfile(
    label_a::AbstractString,
    label_b::AbstractString,
    out_label::AbstractString,
) =
    isempty(out_label) ? joinpath(RESDIR, "compare_labels_$(label_a)_vs_$(label_b).md") :
    joinpath(RESDIR, "compare_labels_$(out_label).md")

function collect_label_rows(results_a, results_b)
    rows = NamedTuple[]
    for group in sort(collect(keys(results_a)))
        haskey(results_b, group) || continue
        for name in sort(collect(keys(results_a[group])))
            haskey(results_b[group], name) || continue
            trial_a = median(results_a[group][name])
            trial_b = median(results_b[group][name])
            push!(
                rows,
                (
                    group=group,
                    name=name,
                    a_ms=(trial_a.time / 1e6),
                    b_ms=(trial_b.time / 1e6),
                    a_kib=(trial_a.memory / 1024),
                    b_kib=(trial_b.memory / 1024),
                ),
            )
        end
    end
    return rows
end

function summary_metrics(rows)
    total_a_ms = sum(row.a_ms for row in rows)
    total_b_ms = sum(row.b_ms for row in rows)
    total_a_kib = sum(row.a_kib for row in rows)
    total_b_kib = sum(row.b_kib for row in rows)
    return (
        matched=length(rows),
        a_ms=total_a_ms,
        b_ms=total_b_ms,
        time_ratio=total_a_ms > 0 ? total_b_ms / total_a_ms : NaN,
        a_kib=total_a_kib,
        b_kib=total_b_kib,
        memory_ratio=total_a_kib > 0 ? total_b_kib / total_a_kib : NaN,
        combined_ratio=(total_a_ms > 0 && total_a_kib > 0) ?
                       sqrt((total_b_ms / total_a_ms) * (total_b_kib / total_a_kib)) : NaN,
    )
end

ratio_winner(ratio::Real, label_a::AbstractString, label_b::AbstractString) =
    ratio > 1 + TOL ? label_a : ratio < 1 - TOL ? label_b : "tie"

function overall_decision(summary, label_a::AbstractString, label_b::AbstractString)
    time_winner = ratio_winner(summary.time_ratio, label_a, label_b)
    memory_winner = ratio_winner(summary.memory_ratio, label_a, label_b)

    if time_winner == label_a && memory_winner == label_a
        return (
            winner=label_a,
            reason="$(label_a) is faster and uses less memory overall.",
            time_winner=time_winner,
            memory_winner=memory_winner,
            combined_winner=label_a,
        )
    elseif time_winner == label_b && memory_winner == label_b
        return (
            winner=label_b,
            reason="$(label_b) is faster and uses less memory overall.",
            time_winner=time_winner,
            memory_winner=memory_winner,
            combined_winner=label_b,
        )
    end

    combined_winner = ratio_winner(summary.combined_ratio, label_a, label_b)
    if combined_winner == "tie"
        return (
            winner="tie",
            reason="No clear overall winner: time and memory trade off within the 5% tolerance.",
            time_winner=time_winner,
            memory_winner=memory_winner,
            combined_winner=combined_winner,
        )
    else
        return (
            winner=combined_winner,
            reason="$(combined_winner) wins the combined time/memory score, but time and memory trade off.",
            time_winner=time_winner,
            memory_winner=memory_winner,
            combined_winner=combined_winner,
        )
    end
end

row_verdict(ratio::Real, label_a::AbstractString, label_b::AbstractString) =
    ratio > 1 + TOL ? label_a : ratio < 1 - TOL ? label_b : "–"

function write_comparison_md(outfile, rows, summary, decision, label_a, label_b)
    open(outfile, "w") do io
        println(io, "# Benchmark Labels: `$(label_a)` vs `$(label_b)`\n")
        println(io, "**`ratio = $(label_b) ÷ $(label_a)`**  ")
        println(
            io,
            "ratio `> 1` → `$(label_a)` is better  |  ratio `< 1` → `$(label_b)` is better",
        )
        println(io, "")
        println(io, "## Decision\n")
        if decision.winner == "tie"
            println(io, "**Overall result:** no clear winner  ")
        else
            println(io, "**Overall winner:** `$(decision.winner)`  ")
        end
        println(io, decision.reason)
        println(io, "")
        println(io, "## Aggregate Summary\n")
        println(io, "| metric | ratio | better | $(label_a) total | $(label_b) total |")
        println(io, "|:-------|------:|:------:|-----------------:|-----------------:|")
        println(io, "| matched benchmarks | $(summary.matched) | — | — | — |")
        @printf(
            io,
            "| weighted time ratio | %.3f | %s | %.3f ms | %.3f ms |\n",
            summary.time_ratio,
            decision.time_winner,
            summary.a_ms,
            summary.b_ms
        )
        @printf(
            io,
            "| weighted memory ratio | %.3f | %s | %.1f KiB | %.1f KiB |\n",
            summary.memory_ratio,
            decision.memory_winner,
            summary.a_kib,
            summary.b_kib
        )
        @printf(
            io,
            "| combined score | %.3f | %s | — | — |\n\n",
            summary.combined_ratio,
            decision.combined_winner
        )
        println(
            io,
            "| benchmark | time ratio | time better | memory ratio | memory better | $(label_a) (ms) | $(label_b) (ms) | $(label_a) (KiB) | $(label_b) (KiB) |",
        )
        println(
            io,
            "|:----------|-----------:|:-----------:|-------------:|:-------------:|----------------:|----------------:|-----------------:|-----------------:|",
        )
        for row in rows
            time_ratio = row.b_ms / row.a_ms
            memory_ratio = row.b_kib / row.a_kib
            @printf(
                io,
                "| `[\"%s\", \"%s\"]` | %.3f | %s | %.3f | %s | %.3f | %.3f | %.1f | %.1f |\n",
                row.group,
                row.name,
                time_ratio,
                row_verdict(time_ratio, label_a, label_b),
                memory_ratio,
                row_verdict(memory_ratio, label_a, label_b),
                row.a_ms,
                row.b_ms,
                row.a_kib,
                row.b_kib
            )
        end
    end
end

length(ARGS) >= 2 ||
    error("Usage: julia benchmark/compare_labels.jl label_a label_b [output_label]")

label_a = ARGS[1]
label_b = ARGS[2]
out_label = length(ARGS) >= 3 ? ARGS[3] : ""

file_a = joinpath(RESDIR, "$(label_a).json")
file_b = joinpath(RESDIR, "$(label_b).json")

isfile(file_a) || error("Benchmark results not found: $file_a\nRun: make bench $(label_a)")
isfile(file_b) || error("Benchmark results not found: $file_b\nRun: make bench $(label_b)")

results_a = load(file_a)[1]
results_b = load(file_b)[1]

rows = collect_label_rows(results_a, results_b)
isempty(rows) &&
    error("No overlapping benchmarks found between labels \"$(label_a)\" and \"$(label_b)\".")

summary = summary_metrics(rows)
decision = overall_decision(summary, label_a, label_b)
outfile = compare_labels_outfile(label_a, label_b, out_label)

write_comparison_md(outfile, rows, summary, decision, label_a, label_b)

println("Julia benchmark label comparison")
println("  label A : $label_a")
println("  label B : $label_b")
@printf("  weighted time ratio   = %.3f\n", summary.time_ratio)
@printf("  weighted memory ratio = %.3f\n", summary.memory_ratio)
@printf("  combined score        = %.3f\n", summary.combined_ratio)
if decision.winner == "tie"
    println("  overall result        = no clear winner")
else
    println("  overall winner        = $(decision.winner)")
end
println("\nWrote benchmark/results/$(basename(outfile))")
