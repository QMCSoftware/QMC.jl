# Run all demo notebooks end-to-end (analogous to Python's booktest).
#
# Usage:
#     julia --project=. test/run_notebooks.jl                            # run all
#     julia --project=. test/run_notebooks.jl quickstart                 # run one by name
#     julia --project=. test/run_notebooks.jl --jobs=2                   # shard notebooks
#     julia --project=. test/run_notebooks.jl --overwrite=1              # execute with Jupyter and write outputs back
#     julia --project=. test/run_notebooks.jl --overwrite=1 --kernel=qmc-1.12

using Pkg
if get(ENV, "QMC_SKIP_PKG_SETUP", "0") != "1"
    Pkg.resolve()
    Pkg.instantiate()
end

import NBInclude: @nbinclude
using Logging

# NBInclude executes notebook display calls through Base.display, which can hit
# backend-specific rendering assertions in headless CI. Suppress display during
# regression runs so we still execute the plotting code without requiring a GUI.
struct NullNotebookDisplay <: AbstractDisplay end
Base.display(::NullNotebookDisplay, @nospecialize x) = nothing

function with_suppressed_display(f::F) where {F <: Function}
    notebook_display = NullNotebookDisplay()
    pushdisplay(notebook_display)
    try
        return f()
    finally
        popdisplay(notebook_display)
    end
end

Base.@kwdef struct NotebookOptions
    jobs::Int = 1
    overwrite::Bool = false
    kernel::String = "qmc-1.12"
    timeout::Int = 1800
end

function with_updates(
    opts::NotebookOptions;
    jobs::Int=opts.jobs,
    overwrite::Bool=opts.overwrite,
    kernel::String=opts.kernel,
    timeout::Int=opts.timeout,
)
    return NotebookOptions(; jobs, overwrite, kernel, timeout)
end

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

function parse_args(argv::Vector{String})
    opts = NotebookOptions()
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
            opts = with_updates(opts; jobs)
        elseif startswith(arg, "--overwrite=")
            raw = lowercase(split(arg, "="; limit=2)[2])
            overwrite =
                raw in ("1", "true", "yes") ? true :
                raw in ("0", "false", "no") ? false :
                throw(
                    ArgumentError(
                        "invalid --overwrite value $(repr(raw)); expected 0/1 or true/false",
                    ),
                )
            opts = with_updates(opts; overwrite)
        elseif startswith(arg, "--kernel=")
            kernel = String(split(arg, "="; limit=2)[2])
            isempty(kernel) && throw(ArgumentError("--kernel must not be empty"))
            opts = with_updates(opts; kernel)
        elseif startswith(arg, "--timeout=")
            raw = split(arg, "="; limit=2)[2]
            timeout = try
                parse(Int, raw)
            catch
                throw(
                    ArgumentError(
                        "invalid --timeout value $(repr(raw)); expected a positive integer",
                    ),
                )
            end
            timeout > 0 || throw(ArgumentError("--timeout must be >= 1, got $timeout"))
            opts = with_updates(opts; timeout)
        else
            push!(selectors, arg)
        end
    end
    return opts, selectors
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

function child_cmd(notebooks::Vector{String}, opts::NotebookOptions)
    script = joinpath(@__DIR__, "run_notebooks.jl")
    base_argv = collect(Base.julia_cmd())
    argv = vcat(
        base_argv,
        [
            script,
            "--jobs=1",
            "--overwrite=$(Int(opts.overwrite))",
            "--kernel=$(opts.kernel)",
            "--timeout=$(opts.timeout)",
        ],
        notebooks,
    )
    cmd = Cmd(argv)
    return addenv(
        cmd,
        "JULIA_PROJECT" => current_project_dir(),
        "JULIA_NUM_THREADS" => string(Threads.nthreads()),
        "QMC_SKIP_PKG_SETUP" => "1",
        "QMC_NOTEBOOK_VERBOSE" => get(ENV, "QMC_NOTEBOOK_VERBOSE", "0"),
    )
end

Base.@kwdef mutable struct ShardRun
    idx::Int
    count::Int
    notebooks::Vector{String}
    log_path::String
    task::Task
    started_at::Float64 = time()
    last_pos::Int = 0
    last_output_at::Float64 = time()
    last_heartbeat_at::Float64 = 0.0
    announced::Bool = false
end

function start_child_shard(
    notebooks::Vector{String},
    shard_idx::Int,
    shard_count::Int,
    opts::NotebookOptions,
)
    log_path, io = mktemp()
    close(io)
    task = @async begin
        ok = false
        elapsed = @elapsed begin
            open(log_path, "w") do log_io
                proc = run(
                    pipeline(ignorestatus(child_cmd(notebooks, opts)), stdout=log_io, stderr=log_io),
                )
                ok = success(proc)
            end
        end
        return (
            idx=shard_idx,
            count=shard_count,
            notebooks=notebooks,
            ok=ok,
            log_path=log_path,
            elapsed=elapsed,
        )
    end
    return ShardRun(; idx=shard_idx, count=shard_count, notebooks, log_path, task)
end

function announce_shard!(shard::ShardRun)
    shard.announced && return
    println()
    println(
        "[notebook shard $(shard.idx)/$(shard.count)] " *
        "$(join(shard.notebooks, ", "))",
    )
    shard.announced = true
end

function drain_shard_output!(shard::ShardRun)
    ispath(shard.log_path) || return false
    filesize(shard.log_path) > shard.last_pos || return false
    announce_shard!(shard)
    open(shard.log_path, "r") do io
        seek(io, shard.last_pos)
        chunk = read(io, String)
        if !isempty(chunk)
            print(chunk)
            endswith(chunk, '\n') || println()
            shard.last_pos = position(io)
            shard.last_output_at = time()
            return true
        end
    end
    return false
end

function maybe_print_shard_heartbeat!(shard::ShardRun; interval::Real=30)
    istaskdone(shard.task) && return
    now = time()
    since_output = now - shard.last_output_at
    since_heartbeat = shard.last_heartbeat_at == 0.0 ? Inf : now - shard.last_heartbeat_at
    if since_output >= interval && since_heartbeat >= interval
        announce_shard!(shard)
        println(
            "  ... still running after $(fmt_duration(now - shard.started_at)) " *
            "($(length(shard.notebooks)) notebook(s))",
        )
        shard.last_heartbeat_at = now
    end
end

function notebook_python()
    py = get(ENV, "QMC_NOTEBOOK_PYTHON", "")
    return isempty(py) ? "python3" : py
end

function notebook_jupyter()
    py = notebook_python()
    sibling = joinpath(dirname(py), "jupyter")
    return isfile(sibling) ? sibling : "jupyter"
end

function run_one_notebook_inplace(
    nb::String,
    demos_dir::AbstractString,
    kernel::AbstractString,
    timeout::Int,
)
    print("Executing ", nb, " with kernel ", kernel, " ... ")
    notebook_path = joinpath(demos_dir, nb)
    captured = ""
    failed = false
    err_text = ""
    elapsed = @elapsed try
        mktempdir() do ipython_dir
            mktemp() do _, io
                cmd = Cmd([
                    notebook_jupyter(),
                    "nbconvert",
                    "--to",
                    "notebook",
                    "--execute",
                    "--inplace",
                    "--ExecutePreprocessor.kernel_name=$(kernel)",
                    "--ExecutePreprocessor.timeout=$(timeout)",
                    basename(notebook_path),
                ],)
                cmd = Cmd(cmd; dir=dirname(notebook_path))
                proc = run(
                    pipeline(
                        ignorestatus(addenv(cmd, "IPYTHONDIR" => ipython_dir)),
                        stdout=io,
                        stderr=io,
                    ),
                )
                flush(io)
                seekstart(io)
                captured = read(io, String)
                success(proc) || error("nbconvert exited with code $(proc.exitcode)")
            end
        end
    catch e
        failed = true
        err_text = sprint(io -> showerror(io, e, catch_backtrace()))
    end

    if failed
        println("FAILED")
        if !isempty(strip(captured))
            println("---- captured nbconvert output ----")
            print(captured)
            endswith(captured, '\n') || println()
            println("---- end captured nbconvert output ----")
        end
        println("  x FAILED: ", err_text)
        println("  time: ", fmt_duration(elapsed))
        return false, elapsed, 0
    end

    println("ok [$(fmt_duration(elapsed))]")
    return true, elapsed, 0
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
            with_suppressed_display() do
                runner()
            end
        else
            mktemp() do _, io
                with_suppressed_display() do
                    redirect_stdout(runner, io)
                end
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

function run_serial(notebooks::Vector{String}, demos_dir::AbstractString, opts::NotebookOptions)
    times = Dict{String, Float64}()
    warnings_by_notebook = Dict{String, Int}()
    errors = String[]
    clogger = CountingLogger()
    verbose = get(ENV, "QMC_NOTEBOOK_VERBOSE", "0") == "1"

    for nb in notebooks
        ok, elapsed, warnings =
            opts.overwrite ?
            run_one_notebook_inplace(nb, demos_dir, opts.kernel, opts.timeout) :
            run_one_notebook(nb, demos_dir, clogger, verbose)
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

function run_parallel(notebooks::Vector{String}, opts::NotebookOptions)
    shard_notebooks = split_work(notebooks, opts.jobs)
    println(
        "Running $(length(notebooks)) notebook(s) across $(length(shard_notebooks)) " *
        "parallel shard(s)...",
    )
    wall = @elapsed begin
        shards = [
            start_child_shard(shard, idx, length(shard_notebooks), opts) for
            (idx, shard) in enumerate(shard_notebooks)
        ]
        while any(!istaskdone(shard.task) for shard in shards)
            for shard in shards
                drain_shard_output!(shard)
                maybe_print_shard_heartbeat!(shard)
            end
            sleep(1)
        end
        results = map(fetch, getfield.(shards, :task))
        failed = false
        for (shard, result) in zip(shards, results)
            drain_shard_output!(shard)
            failed |= !result.ok
            rm(result.log_path; force=true)
        end
        println()
        println("Parallel shard summary")
        println("-"^60)
        for result in results
            status = result.ok ? "passed" : "FAILED"
            println(
                "  shard $(result.idx)/$(result.count): $status " *
                "($(length(result.notebooks)) notebook(s), $(fmt_duration(result.elapsed)))",
            )
        end
        if failed
            println("-"^60)
            println("One or more notebook shards failed; see shard logs above.")
            exit(1)
        end
    end
    println()
    println(
        "Completed parallel notebook run for $(length(notebooks)) notebook(s) in " *
        "$(fmt_duration(wall)).",
    )
end

function collect_notebooks(demos_dir::AbstractString)
    notebooks = String[]
    for (root, _, files) in walkdir(demos_dir)
        rel_root = relpath(root, demos_dir)
        path_parts =
            rel_root == "." ? String[] : split(rel_root, Base.Filesystem.path_separator)
        any(startswith(part, ".") for part in path_parts) && continue
        for file in files
            endswith(file, ".ipynb") || continue
            startswith(file, ".") && continue
            endswith(file, "-checkpoint.ipynb") && continue
            push!(notebooks, relpath(joinpath(root, file), demos_dir))
        end
    end
    return sort(notebooks)
end

demos_dir = joinpath(@__DIR__, "..", "demos")
all_notebooks = collect_notebooks(demos_dir)
opts, selectors = parse_args(ARGS)
notebooks = select_notebooks(all_notebooks, selectors)

if opts.jobs == 1 || length(notebooks) <= 1
    run_serial(notebooks, demos_dir, opts)
else
    run_parallel(notebooks, opts)
end
