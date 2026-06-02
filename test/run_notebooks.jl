# Run all demo notebooks end-to-end (analogous to Python's booktest).
#
# Usage:
#     julia --project=. test/run_notebooks.jl              # run all
#     julia --project=. test/run_notebooks.jl quickstart    # run one by name

using Pkg
Pkg.instantiate()

import NBInclude: @nbinclude
using Logging

# A logger that counts warnings while forwarding them to the console
struct CountingLogger <: AbstractLogger
    inner::ConsoleLogger
    counts::Dict{String, Int}  # notebook name → warning count
    current_nb::Ref{String}
end

function CountingLogger()
    CountingLogger(
        ConsoleLogger(stderr, Logging.Warn),
        Dict{String, Int}(),
        Ref(""),
    )
end

Logging.min_enabled_level(cl::CountingLogger) = Logging.min_enabled_level(cl.inner)
Logging.shouldlog(cl::CountingLogger, args...) = Logging.shouldlog(cl.inner, args...)
Logging.catch_exceptions(cl::CountingLogger) = Logging.catch_exceptions(cl.inner)

function Logging.handle_message(
    cl::CountingLogger, level, message, _module, group, id, file, line; kwargs...)
    if level >= Logging.Warn
        nb = cl.current_nb[]
        cl.counts[nb] = get(cl.counts, nb, 0) + 1
    end
    Logging.handle_message(
        cl.inner, level, message, _module, group, id, file, line; kwargs...)
end

# ── Main ─────────────────────────────────────────────────
demos_dir = joinpath(@__DIR__, "..", "demos")
notebooks = sort(filter(f -> endswith(f, ".ipynb"), readdir(demos_dir)))

if !isempty(ARGS)
    pattern = ARGS[1]
    notebooks = filter(nb -> occursin(pattern, nb), notebooks)
    if isempty(notebooks)
        println("No notebook matching '$pattern' found in demos/")
        exit(1)
    end
end

errors = String[]
clogger = CountingLogger()

for nb in notebooks
    println("\n", "="^60)
    println("Running: ", nb)
    println("="^60)
    clogger.current_nb[] = nb
    try
        with_logger(clogger) do
            @nbinclude(joinpath(demos_dir, nb))
        end
    catch e
        push!(errors, nb)
        println("  ✗ FAILED: ", sprint(showerror, e))
    end
end

# ── Summary ──────────────────────────────────────────────
total_warnings = sum(values(clogger.counts); init = 0)
n_pass = length(notebooks) - length(errors)

println("\n", "="^60)
println(
    "Ran $(length(notebooks)) notebook(s): $(n_pass) passed, $(length(errors)) failed, $(total_warnings) warning(s).",
)

if total_warnings > 0
    for nb in notebooks
        w = get(clogger.counts, nb, 0)
        w > 0 && println("  ⚠  $nb: $w warning(s)")
    end
end

if !isempty(errors)
    for nb in errors
        println("  ✗  $nb: FAILED")
    end
    exit(1)
else
    println("All notebooks passed.")
end
