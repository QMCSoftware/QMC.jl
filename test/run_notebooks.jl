# Run all demo notebooks end-to-end (analogous to Python's booktest).
#
# Usage:
#     julia --project=. test/run_notebooks.jl                  # run all
#     julia --project=. test/run_notebooks.jl quickstart       # run one by name
#     julia --project=. test/run_notebooks.jl --jobs=2         # shard notebooks

using Pkg
if get(ENV, "QMC_SKIP_PKG_SETUP", "0") != "1"
    Pkg.resolve()
    Pkg.instantiate()
end

import NBInclude: @nbinclude
using Logging

# A logger that counts warnings while forwarding them to the console
struct CountingLogger <: AbstractLogger
    inner::ConsoleLogger
    counts::Dict{String, Int}  # notebook name -> warning count
    current_nb::Ref{String}
end

function CountingLogger()
    CountingLogger(ConsoleLogger(stderr, Logging.Warn), Dict{String, Int}(), Ref(""))
end

Logging.min_enabled_level(cl::CountingLogger) = Logging.min_enabled_level(cl.inner)
Logging.shouldlog(cl::CountingLogger, args...) = Logging.shouldlog(cl.inner, args...)
Logging.catch_exceptions(cl::CountingLogger) = Logging.catch_exceptions(cl.inner)

function Logging.handle_message(
    cl::CountingLogger,
    level,
    message,
    _module,
    group,
    id,
    file,
    line;
    kwargs...,
)
    if level >= Logging.Warn
        nb = cl.current_nb[]
        cl.counts[nb] = get(cl.counts, nb, 0) + 1
    end
    Logging.handle_message(cl.inner, level, message, _module, group, id, file, line; kwargs...)
end

# Format a duration in seconds as a short string.
fmt_duration(s::Real) =
    if s >= 60
        m = floor(Int, s / 60)
        return "$(m)m $(round(s - 60m; digits = 1))s"
    else
        return "$(round(s; digits = 2))s"
    end

function parse_jobs(argv::Vector{String})
    jobs = 1
    selectors = String[]
    for arg in argv
        if startswith(arg, "--jobs=")
            raw = split(arg, "="; limit=2)[2]
            jobs = try
                parse(Int, raw)
            catch
                throw(
                    ArgumentError(
                        "invalid --jobs value $(repr(raw)); expected a positive integer",
                    ),
                )
            end
            jobs > 0 || throw(ArgumentError("--jobs must be >= 1, got $jobs"))
        else
            push!(selectors, arg)
        end
    end
    return jobs, selectors
end

function select_notebooks(all_notebooks::Vector{String}, selectors::Vector{String})
    isempty(selectors) && return all_notebooks
    selected = String[]
    seen = Set{String}()
    for selector in selectors
        matches =
            endswith(selector, ".ipynb") ? filter(nb -> nb == selector, all_notebooks) :
            filter(nb -> occursin(selector, nb), all_notebooks)
        if isempty(matches)
            throw(ArgumentError("no notebook matching $(repr(selector)) found in demos/"))
        end
        for notebook in matches
            if notebook ∉ seen
                push!(selected, notebook)
                push!(seen, notebook)
            end
        end
    end
    return selected
end

function split_work(items::Vector{String}, jobs::Int)
    nshards = min(jobs, length(items))
    shards = [String[] for _ in 1:nshards]
    for (idx, item) in enumerate(items)
        push!(shards[1 + mod(idx - 1, nshards)], item)
    end
    return shards
end

function current_project_dir()
    active_project = Base.active_project()
    active_project === nothing && return dirname(@__DIR__)
    return dirname(active_project)
end

function child_cmd(notebooks::Vector{String})
    script = joinpath(@__DIR__, "run_notebooks.jl")
    cmd = `$(Base.julia_cmd()) $script --jobs=1 $(notebooks...)`
    return addenv(
        cmd,
        "JULIA_PROJECT" => current_project_dir(),
        "JULIA_NUM_THREADS" => string(Threads.nthreads()),
        "QMC_SKIP_PKG_SETUP" => "1",
        "QMC_NOTEBOOK_VERBOSE" => get(ENV, "QMC_NOTEBOOK_VERBOSE", "0"),
    )
end

function run_child_shard(notebooks::Vector{String}, shard_idx::Int, shard_count::Int)
    output = ""
    ok = false
    elapsed = @elapsed begin
        mktemp() do _, io
            proc = run(pipeline(ignorestatus(child_cmd(notebooks)), stdout=io, stderr=io))
            flush(io)
            seekstart(io)
            output = read(io, String)
            ok = success(proc)
        end
    end
    return (
        idx=shard_idx,
        count=shard_count,
        notebooks=notebooks,
        ok=ok,
        output=output,
        elapsed=elapsed,
    )
end

function print_child_result(result)
    println()
    println(
        "[notebook shard $(result.idx)/$(result.count)] " *
        "$(join(result.notebooks, ", ")) ($(fmt_duration(result.elapsed)))",
    )
    if !isempty(strip(result.output))
        print(result.output)
        endswith(result.output, '\n') || println()
    end
end

function run_one_notebook(
    nb::String,
    demos_dir::AbstractString,
    clogger::CountingLogger,
    verbose::Bool,
)
    print("Running ", nb, " ... ")
    clogger.current_nb[] = nb
    captured = ""
    failed = false
    err_text = ""
    elapsed = @elapsed try
        runner = () -> with_logger(clogger) do
            @nbinclude(joinpath(demos_dir, nb))
        end
        if verbose
            runner()
        else
            mktemp() do _, io
                redirect_stdout(runner, io)
                flush(io)
                seekstart(io)
                captured = read(io, String)
            end
        end
    catch e
        failed = true
        err_text = sprint(io -> showerror(io, e, catch_backtrace()))
    end

    warnings = get(clogger.counts, nb, 0)
    if failed
        println("FAILED")
        if !isempty(captured)
            println("---- captured notebook stdout ----")
            print(captured)
            endswith(captured, '\n') || println()
            println("---- end captured stdout ----")
        end
        println("  x FAILED: ", err_text)
        println("  time: ", fmt_duration(elapsed))
        return false, elapsed, warnings
    end

    wtxt = warnings > 0 ? ", $warnings warning(s)" : ""
    println("ok [$(fmt_duration(elapsed))]$wtxt")
    return true, elapsed, warnings
end

function run_serial(notebooks::Vector{String}, demos_dir::AbstractString)
    times = Dict{String, Float64}()
    warnings_by_notebook = Dict{String, Int}()
    errors = String[]
    clogger = CountingLogger()
    verbose = get(ENV, "QMC_NOTEBOOK_VERBOSE", "0") == "1"

    for nb in notebooks
        ok, elapsed, warnings = run_one_notebook(nb, demos_dir, clogger, verbose)
        times[nb] = elapsed
        warnings_by_notebook[nb] = warnings
        ok || push!(errors, nb)
    end

    total_warnings = sum(values(warnings_by_notebook); init=0)
    total_time = sum(values(times); init=0.0)
    n_pass = length(notebooks) - length(errors)

    println("\n", "="^60)
    println("Summary")
    println("="^60)
    for nb in errors
        w = get(warnings_by_notebook, nb, 0)
        t = get(times, nb, 0.0)
        wtxt = w > 0 ? ", $w warning(s)" : ""
        println("  x FAILED  $nb  [$(fmt_duration(t))]$wtxt")
    end
    println("-"^60)
    println(
        "Ran $(length(notebooks)) notebook(s): $(n_pass) passed, $(length(errors)) failed, " *
        "$(total_warnings) warning(s) in $(fmt_duration(total_time)).",
    )

    if !isempty(errors)
        exit(1)
    else
        println("All notebooks passed.")
    end
end

function run_parallel(notebooks::Vector{String}, jobs::Int)
    shards = split_work(notebooks, jobs)
    println(
        "Running $(length(notebooks)) notebook(s) across $(length(shards)) " *
        "parallel shard(s)...",
    )
    wall = @elapsed begin
        tasks = [
            @async run_child_shard(shard, idx, length(shards)) for
            (idx, shard) in enumerate(shards)
        ]
        results = fetch.(tasks)
        failed = false
        for result in results
            print_child_result(result)
            failed |= !result.ok
        end
        failed && exit(1)
    end
    println()
    println(
        "Completed parallel notebook run for $(length(notebooks)) notebook(s) in " *
        "$(fmt_duration(wall)).",
    )
end

demos_dir = joinpath(@__DIR__, "..", "demos")
all_notebooks = sort(filter(f -> endswith(f, ".ipynb"), readdir(demos_dir)))
jobs, selectors = parse_jobs(ARGS)
notebooks = select_notebooks(all_notebooks, selectors)

if jobs == 1 || length(notebooks) <= 1
    run_serial(notebooks, demos_dir)
else
    run_parallel(notebooks, jobs)
end
