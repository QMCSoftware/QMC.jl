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
# Output: benchmark/results/compare_python.md by default, or compare_python_<label>.md
#
# Ratio convention (same as compare.jl):
#   ratio = reference (Python) time ÷ local (Julia) time
#   ratio < 1  →  local is SLOWER than Python  ❌
#   ratio > 1  →  local is FASTER than Python  ✅
#
# NOTE: `ms` is directly cross-comparable. Julia reports both `alloc KiB` from
# BenchmarkTools and, when available, a coarse retained `rss_delta_kib` sidecar
# captured by `runbenchmarks.jl`. Python reports `tracemalloc_peak_kib` and a
# coarse retained `rss_delta_kib` from one warmed call.
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
compare_py_outfile(label::AbstractString) =
    isempty(label) ? joinpath(resdir, "compare_python.md") :
    joinpath(resdir, "compare_python_$(label).md")

is_c_kernel_row(name::AbstractString) = occursin(r"Lattice|DigitalNetB2|Halton", name)

function lookup_py_entry(py_results, group, name)
    py_group = get(py_results, Symbol(group), nothing)
    py_group === nothing && return nothing
    return get(py_group, name, get(py_group, replace(name, r" d=\d+" => s -> " [C]" * s), nothing))
end

function lookup_jl_memory_entry(jl_memory_results, group, name)
    jl_memory_results === nothing && return nothing
    jl_group = get(jl_memory_results, Symbol(group), nothing)
    jl_group === nothing && return nothing
    return get(jl_group, name, nothing)
end

function collect_comparison_rows(jl_results, jl_memory_results, py_results)
    rows = NamedTuple[]
    for group in sort(collect(keys(jl_results)))
        for name in sort(collect(keys(jl_results[group])))
            jl_trial = median(jl_results[group][name])
            jl_ms = jl_trial.time / 1e6
            jl_kib = jl_trial.memory / 1024
            jl_mem_entry = lookup_jl_memory_entry(jl_memory_results, group, name)
            py_entry = lookup_py_entry(py_results, group, name)
            if py_entry !== nothing && !haskey(py_entry, "error")
                push!(rows, (
                    group = group,
                    name = name,
                    jl_ms = jl_ms,
                    jl_kib = jl_kib,
                    jl_rss_delta_kib = jl_mem_entry !== nothing && haskey(jl_mem_entry, "rss_delta_kib") ?
                        Float64(jl_mem_entry["rss_delta_kib"]) : nothing,
                    py_ms = Float64(py_entry["median_ms"]),
                    py_peak_kib = haskey(py_entry, "tracemalloc_peak_kib") ?
                        Float64(py_entry["tracemalloc_peak_kib"]) : nothing,
                    py_rss_delta_kib = haskey(py_entry, "rss_delta_kib") ?
                        Float64(py_entry["rss_delta_kib"]) : nothing,
                    py_error = nothing,
                    c_kernel = is_c_kernel_row(name),
                ))
            else
                push!(rows, (
                    group = group,
                    name = name,
                    jl_ms = jl_ms,
                    jl_kib = jl_kib,
                    jl_rss_delta_kib = jl_mem_entry !== nothing && haskey(jl_mem_entry, "rss_delta_kib") ?
                        Float64(jl_mem_entry["rss_delta_kib"]) : nothing,
                    py_ms = nothing,
                    py_peak_kib = nothing,
                    py_rss_delta_kib = nothing,
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
    total_jl_ms = sum((row.jl_ms for row in matched); init = 0.0)
    total_py_ms = sum((row.py_ms for row in matched); init = 0.0)
    peak_rows = filter(row -> row.py_peak_kib !== nothing, matched)
    rss_rows = filter(row -> row.py_rss_delta_kib !== nothing && row.jl_rss_delta_kib !== nothing, matched)
    total_jl_peak_kib = sum((row.jl_kib for row in peak_rows); init = 0.0)
    total_py_peak_kib = sum((row.py_peak_kib for row in peak_rows); init = 0.0)
    total_jl_rss_kib = sum((row.jl_rss_delta_kib for row in rss_rows); init = 0.0)
    total_py_rss_delta_kib = sum((row.py_rss_delta_kib for row in rss_rows); init = 0.0)
    return (
        matched = length(matched),
        total = length(rows),
        jl_ms = total_jl_ms,
        py_ms = total_py_ms,
        time_ratio = total_jl_ms > 0 ? total_py_ms / total_jl_ms : NaN,
        peak_rows = length(peak_rows),
        jl_peak_kib = total_jl_peak_kib,
        py_peak_kib = total_py_peak_kib,
        peak_ratio = total_jl_peak_kib > 0 ? total_py_peak_kib / total_jl_peak_kib : NaN,
        rss_rows = length(rss_rows),
        jl_rss_kib = total_jl_rss_kib,
        py_rss_delta_kib = total_py_rss_delta_kib,
        rss_ratio = total_jl_rss_kib > 0 ? total_py_rss_delta_kib / total_jl_rss_kib : NaN,
    )
end

jl_label = length(ARGS) >= 1 ? ARGS[1] : "latest"
py_label = length(ARGS) >= 2 ? ARGS[2] : jl_label
out_label = length(ARGS) >= 3 ? ARGS[3] : ""

jl_file = joinpath(resdir, "$(jl_label).json")
jl_mem_file = joinpath(resdir, "$(jl_label)_memory.json")
py_file = joinpath(resdir, "qmcpy_$(py_label).json")

isfile(jl_file) || error("Julia results not found: $jl_file\nRun: make bench" *
                         (jl_label == "latest" ? "" : " then julia benchmark/runbenchmarks.jl $jl_label"))
isfile(py_file) || error("QMCPy results not found: $py_file\n" *
                         "Run: python benchmark/benchmark_qmcpy.py $py_label")

jl_results = BenchmarkTools.load(jl_file)[1]
jl_mem_data = isfile(jl_mem_file) ? JSON3.read(read(jl_mem_file, String)) : nothing
py_data    = JSON3.read(read(py_file, String))

jl_memory_results = jl_mem_data === nothing ? nothing : jl_mem_data["results"]
py_results = py_data["results"]
py_version = get(py_data, "qmcpy_version", "?")
rows = collect_comparison_rows(jl_results, jl_memory_results, py_results)
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
        else  # missing/unavailable Python data
            @printf("  ??? %-44s  %11.3f  %11s  %7s\n", row.name, row.jl_ms, "n/a", "n/a")
        end
    end
end

println()
println("="^length(header))
println("ratio > 1: local (Julia) faster than Python  |  ratio < 1: local (Julia) slower than Python")
@printf("weighted time ratio = %.3f  (Python total %.3f ms vs Julia total %.3f ms across %d/%d matched rows)\n",
        summary.time_ratio, summary.py_ms, summary.jl_ms, summary.matched, summary.total)
if summary.peak_rows > 0
    @printf("weighted tracemalloc ratio = %.3f  (Python peak total %.1f KiB vs Julia alloc total %.1f KiB across %d/%d rows)\n",
            summary.peak_ratio, summary.py_peak_kib, summary.jl_peak_kib, summary.peak_rows, summary.total)
else
    println("weighted tracemalloc ratio = n/a  (QMCPy results do not record Python memory metrics)")
end
if summary.rss_rows > 0
    @printf("weighted RSS delta ratio   = %.3f  (Python RSS Δ total %.1f KiB vs Julia RSS Δ total %.1f KiB across %d/%d rows)\n",
            summary.rss_ratio, summary.py_rss_delta_kib, summary.jl_rss_kib, summary.rss_rows, summary.total)
else
    println("weighted RSS delta ratio   = n/a  (missing Julia or QMCPy RSS delta sidecar data)")
end

# ── Save markdown file ──────────────────────────────────────────────────────────
outfile = compare_py_outfile(out_label)
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
    println(io, "> Julia `alloc KiB` is allocated bytes from BenchmarkTools. Julia `RSS Δ` and Python")
    println(io, "> `RSS Δ` are coarse retained-memory signals from one warmed call. Python `tracemalloc`")
    println(io, "> peak is Python-managed temporary memory. These are related but not interchangeable.")
    println(io, "")
    println(io, "## Aggregate Summary\n")
    println(io, "| metric | ratio | Julia total | Python total | rows |")
    println(io, "|:-------|------:|------------:|-------------:|-----:|")
    println(io, "| matched benchmarks | $(summary.matched)/$(summary.total) | — | — | $(summary.matched) |")
    @printf(io, "| weighted time ratio | %.3f | %.3f ms | %.3f ms | %d |\n",
            summary.time_ratio, summary.jl_ms, summary.py_ms, summary.matched)
    if summary.peak_rows > 0
        @printf(io, "| weighted tracemalloc ratio | %.3f | %.1f KiB | %.1f KiB | %d |\n",
                summary.peak_ratio, summary.jl_peak_kib, summary.py_peak_kib, summary.peak_rows)
    else
        println(io, "| weighted tracemalloc ratio | n/a | n/a | n/a | 0 |")
    end
    if summary.rss_rows > 0
        @printf(io, "| weighted RSS delta ratio | %.3f | %.1f KiB | %.1f KiB | %d |\n\n",
                summary.rss_ratio, summary.jl_rss_kib, summary.py_rss_delta_kib, summary.rss_rows)
    else
        println(io, "| weighted RSS delta ratio | n/a | n/a | n/a | 0 |\n")
    end
    println(io, "")
    println(io, "| benchmark | time ratio | verdict | Julia (ms) | Python (ms) | Julia alloc (KiB) | Julia RSS Δ (KiB) | Python peak (KiB) | Python RSS Δ (KiB) |")
    println(io, "|:----------|-----------:|:-------:|----------:|------------:|-------------------:|------------------:|------------------:|-------------------:|")
    for row in rows
        c_note = row.c_kernel ? " `[C]`" : ""
        if row.py_ms !== nothing
                ratio   = row.py_ms / row.jl_ms
                verdict = ratio < 0.95 ? "❌" : ratio > 1.05 ? "✅" : "–"
                jl_rss_txt = row.jl_rss_delta_kib === nothing ? "n/a" : @sprintf("%.1f", row.jl_rss_delta_kib)
                peak_txt = row.py_peak_kib === nothing ? "n/a" : @sprintf("%.1f", row.py_peak_kib)
                rss_txt = row.py_rss_delta_kib === nothing ? "n/a" : @sprintf("%.1f", row.py_rss_delta_kib)
                @printf(io, "| `[\"%s\", \"%s\"]`%s | %.3f | %s | %.3f | %.3f | %.1f | %s | %s | %s |\n",
                        row.group, row.name, c_note, ratio, verdict, row.jl_ms, row.py_ms,
                        row.jl_kib, jl_rss_txt, peak_txt, rss_txt)
        else
            jl_rss_txt = row.jl_rss_delta_kib === nothing ? "n/a" : @sprintf("%.1f", row.jl_rss_delta_kib)
            @printf(io, "| `[\"%s\", \"%s\"]` | n/a | — | %.3f | n/a | %.1f | %s | n/a | n/a |\n",
                    row.group, row.name, row.jl_ms, row.jl_kib, jl_rss_txt)
        end
    end
end
println("\nWrote benchmark/results/$(basename(outfile))")
println("  ratio = Python ÷ Julia  →  < 1: local slower  |  > 1: local faster")
