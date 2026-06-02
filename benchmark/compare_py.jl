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
py_python  = get(py_data, "python", "?")

println("Julia vs QMCPy benchmark comparison")
println("  Julia results : $jl_file")
println("  QMCPy results : $py_file  (qmcpy $py_version, python $py_python)")
println()
println("  NOTE: C-kernel rows [C] (Lattice/DigitalNetB2/Halton gen_samples) use the")
println("  same qmctoolscl library on both sides and are NOT a language comparison.")
println()

header = @sprintf("  %-48s  %11s  %11s  %7s", "benchmark", "Julia (ms)", "Python (ms)", "ratio")
println("="^length(header))
println(header)
println("-"^length(header))

for group in sort(collect(keys(jl_results)))
    println("\n── $group ──")
    py_group = get(py_results, Symbol(group), nothing)
    for name in sort(collect(keys(jl_results[group])))
        jl_ms = median(jl_results[group][name]).time / 1e6

        # Python key may have " [C]" suffix for C-kernel variants; try both.
        py_entry = nothing
        if py_group !== nothing
            py_entry = get(py_group, name, get(py_group, replace(name, r" d=\d+" => s -> " [C]" * s), nothing))
        end

        if py_entry !== nothing && !haskey(py_entry, "error")
            py_ms  = Float64(py_entry["median_ms"])
            ratio  = py_ms / jl_ms
            tag    = occursin(r"Lattice|DigitalNetB2|Halton", name) ? " [C]" : "    "
            @printf("  %s %-44s  %11.3f  %11.3f  %6.2fx\n", tag, name, jl_ms, py_ms, ratio)
        else
            err = py_entry !== nothing ? string(py_entry["error"]) : "no Python data"
            @printf("  ??? %-44s  %11.3f  %11s  %7s\n", name, jl_ms, "n/a", "n/a")
        end
    end
end

println()
println("="^length(header))
println("ratio > 1: Python is slower   ratio < 1: Python is faster")
