# Side-by-side Julia vs QMCPy benchmark comparison.
#
# Usage (from the repository root):
#   julia benchmark/compare_py.jl                             # latest.json vs qmcpy_latest.json
#   julia benchmark/compare_py.jl mylabel                     # latest.json vs qmcpy_mylabel.json
#   julia benchmark/compare_py.jl jl_label py_label           # jl_label.json vs qmcpy_py_label.json
#
# Both files must exist in benchmark/results/ — run `make bench` then
# `python benchmark/benchmark_qmcpy.py [label]` first.
#
# Output: benchmark/results/compare_python.md
#
# Ratio convention (same as compare.jl):
#   ratio = reference (Python) time ÷ local (Julia) time
#   ratio < 1  →  local is SLOWER than Python  ❌
#   ratio > 1  →  local is FASTER than Python  ✅
#
# NOTE: only the `ms` column is cross-comparable. `allocs`/`KiB` are Julia-only.
# C-kernel rows (Lattice, DigitalNetB2, Halton gen_samples) measure the same C
# library on both sides; they are NOT a language comparison (see benchmark_qmcpy.py).

using Pkg
Pkg.activate(@__DIR__)
let deps = keys(Pkg.project().dependencies)
    "QMC" in deps || Pkg.develop(; path = dirname(@__DIR__))
    "BenchmarkTools" in deps || Pkg.add("BenchmarkTools")
    "JSON3" in deps || Pkg.add("JSON3")
end
Pkg.instantiate()

using BenchmarkTools
using JSON3
using Statistics
using Printf

resdir = joinpath(@__DIR__, "results")

is_c_kernel_row(name::AbstractString) = occursin(r"Lattice|DigitalNetB2|Halton", name)

function lookup_py_entry(py_results, group, name)
    py_group = get(py_results, Symbol(group), nothing)
    py_group === nothing && return nothing
    return get(py_group, name, get(py_group, replace(name, r" d=\d+" => s -> " [C]" * s), nothing))
end

function collect_comparison_rows(jl_results, py_results)
    rows = NamedTuple[]
    for group in sort(collect(keys(jl_results)))
        for name in sort(collect(keys(jl_results[group])))
            jl_trial = median(jl_results[group][name])
            jl_ms = jl_trial.time / 1e6
            jl_kib = jl_trial.memory / 1024
            py_entry = lookup_py_entry(py_results, group, name)
            if py_entry !== nothing && !haskey(py_entry, "error")
                push!(rows, (
                    group = group,
                    name = name,
                    jl_ms = jl_ms,
                    jl_kib = jl_kib,
                    py_ms = Float64(py_entry["median_ms"]),
                    py_error = nothing,
                    c_kernel = is_c_kernel_row(name),
                ))
            else
                push!(rows, (
                    group = group,
                    name = name,
                    jl_ms = jl_ms,
                    jl_kib = jl_kib,
                    py_ms = nothing,
                    py_error = py_entry === nothing ? "no Python data" : string(py_entry["error"]),
                    c_kernel = is_c_kernel_row(name),
                ))
            end
        end
    end
    return rows
end

function summary_metrics(rows)
    matched = filter(row -> row.py_ms !== nothing, rows)
    total_jl_ms = sum(row.jl_ms for row in matched)
    total_py_ms = sum(row.py_ms for row in matched)
    total_jl_kib = sum(row.jl_kib for row in matched)
    return (
        matched = length(matched),
        total = length(rows),
        jl_ms = total_jl_ms,
        py_ms = total_py_ms,
        time_ratio = total_jl_ms > 0 ? total_py_ms / total_jl_ms : NaN,
        jl_kib = total_jl_kib,
    )
end

jl_label = length(ARGS) >= 1 ? ARGS[1] : "latest"
py_label = length(ARGS) >= 2 ? ARGS[2] : jl_label

jl_file = joinpath(resdir, "$(jl_label).json")
py_file = joinpath(resdir, "qmcpy_$(py_label).json")

isfile(jl_file) || error("Julia results not found: $jl_file\nRun: make bench" *
                         (jl_label == "latest" ? "" : " then julia benchmark/runbenchmarks.jl $jl_label"))
isfile(py_file) || error("QMCPy results not found: $py_file\n" *
                         "Run: python benchmark/benchmark_qmcpy.py $py_label")

jl_results = BenchmarkTools.load(jl_file)[1]
py_data    = JSON3.read(read(py_file, String))

py_results = py_data["results"]
py_version = get(py_data, "qmcpy_version", "?")
rows = collect_comparison_rows(jl_results, py_results)
summary = summary_metrics(rows)

println("Julia vs QMCPy benchmark comparison")
println("  Julia label   : $jl_label")
println("  QMCPy label   : $py_label  (qmcpy $py_version)")
println()
println("  NOTE: C-kernel rows [C] (Lattice/DigitalNetB2/Halton gen_samples) use the")
println("  same qmctoolscl library on both sides and are NOT a language comparison.")
println()

header = @sprintf("  %-48s  %11s  %11s  %7s", "benchmark", "Julia (ms)", "Python (ms)", "ratio")
println("="^length(header))
println(header)
println("-"^length(header))

for group in sort(unique(row.group for row in rows))
    println("\n── $group ──")
    for row in filter(r -> r.group == group, rows)
        if row.py_ms !== nothing
            ratio = row.py_ms / row.jl_ms
            tag = row.c_kernel ? " [C]" : "    "
            @printf("  %s %-44s  %11.3f  %11.3f  %6.2fx\n", tag, row.name, row.jl_ms, row.py_ms, ratio)
        else
            @printf("  ??? %-44s  %11.3f  %11s  %7s\n", row.name, row.jl_ms, "n/a", "n/a")
        end
    end
end

println()
println("="^length(header))
println("ratio > 1: local (Julia) faster than Python  |  ratio < 1: local (Julia) slower than Python")
@printf("weighted time ratio = %.3f  (Python total %.3f ms vs Julia total %.3f ms across %d/%d matched rows)\n",
        summary.time_ratio, summary.py_ms, summary.jl_ms, summary.matched, summary.total)
println("weighted memory ratio = n/a  (QMCPy results do not record comparable Python memory)")

# ── Save markdown file ──────────────────────────────────────────────────────────
outfile = joinpath(resdir, "compare_python.md")
open(outfile, "w") do io
    println(io, "# Benchmark: Julia (local) vs QMCPy (Python)\n")
    println(io, "| | Julia (local) | Python (QMCPy) |")
    println(io, "|---|---|---|")
    println(io, "| Julia label | `$(jl_label)` | — |")
    println(io, "| Python label | — | `$(py_label)` |")
    println(io, "| qmcpy version | — | $(py_version) |")
    println(io, "")
    println(io, "**`ratio = Python time ÷ Julia time`**  ")
    println(io, "ratio `< 1` → local (Julia) is **slower** ❌  |  ratio `> 1` → local (Julia) is **faster** ✅  ")
    println(io, "")
    println(io, "> ⚠️ C-kernel rows `[C]` (Lattice/DigitalNetB2/Halton `gen_samples`) call the same")
    println(io, "> `qmctoolscl` library on both sides and are **not** a Julia vs Python comparison.")
    println(io, "")
    println(io, "## Aggregate Summary\n")
    println(io, "| metric | ratio | Julia total | Python total |")
    println(io, "|:-------|------:|------------:|-------------:|")
    println(io, "| matched benchmarks | $(summary.matched)/$(summary.total) | — | — |")
    @printf(io, "| weighted time ratio | %.3f | %.3f ms | %.3f ms |\n",
            summary.time_ratio, summary.jl_ms, summary.py_ms)
    @printf(io, "| weighted memory ratio | %s | %.1f KiB | %s |\n\n",
            "n/a", summary.jl_kib, "n/a")
    println(io, "> Python memory is not summarized here because the QMCPy harness currently records")
    println(io, "> timing only; there is no comparable cross-language allocation/RSS measure in the results.")
    println(io, "")
    println(io, "| benchmark | ratio | verdict | Julia (ms) | Python (ms) |")
    println(io, "|:----------|------:|:-------:|----------:|------------:|")
    for row in rows
        c_note = row.c_kernel ? " `[C]`" : ""
        if row.py_ms !== nothing
                ratio   = row.py_ms / row.jl_ms
                verdict = ratio < 0.95 ? "❌" : ratio > 1.05 ? "✅" : "–"
                @printf(io, "| `[\"%s\", \"%s\"]`%s | %.3f | %s | %.3f | %.3f |\n",
                        row.group, row.name, c_note, ratio, verdict, row.jl_ms, row.py_ms)
        else
            @printf(io, "| `[\"%s\", \"%s\"]` | n/a | — | %.3f | n/a |\n",
                    row.group, row.name, row.jl_ms)
        end
    end
end
println("\nWrote benchmark/results/compare_python.md")
println("  ratio = Python ÷ Julia  →  < 1: local slower  |  > 1: local faster")
