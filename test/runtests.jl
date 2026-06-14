using Test
using QMC
using Statistics
using LinearAlgebra
using Distributions
# Resolve name conflicts: prefer QMC's versions in tests
import QMC: Uniform, Kumaraswamy

const TEST_FILES = [
    "test_discrete_distributions.jl",
    "test_true_measures.jl",
    "test_integrands.jl",
    "test_kernels.jl",
    "test_stopping_criteria.jl",
    "test_pf_gp_ci.jl",
    "test_integration.jl",
    "test_multilevel.jl",
    "test_utils.jl",
    "test_aqua.jl",
]

"Format a duration in seconds as a short string."
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

function select_test_files(selectors::Vector{String})
    isempty(selectors) && return copy(TEST_FILES)
    files = String[]
    seen = Set{String}()
    for selector in selectors
        candidate = endswith(selector, ".jl") ? selector : "$(selector).jl"
        if candidate ∉ TEST_FILES
            throw(
                ArgumentError(
                    "unknown test file $(repr(selector)); expected one of $(join(TEST_FILES, ", "))",
                ),
            )
        end
        if candidate ∉ seen
            push!(files, candidate)
            push!(seen, candidate)
        end
    end
    return files
end

function run_serial(files::Vector{String})
    times = Dict{String, Float64}()
    @testset "QMC" begin
        for test_file in files
            elapsed = @elapsed begin
                try
                    include(joinpath(@__DIR__, test_file))
                catch err
                    println("  x failed in $(test_file)")
                    rethrow(err)
                end
            end
            times[test_file] = elapsed
            println("  time $(test_file): $(fmt_duration(elapsed))")
        end
    end
    total_time = sum(values(times); init=0.0)
    println("Ran $(length(files)) test file(s) in $(fmt_duration(total_time)).")
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

coverage_flags() = Base.JLOptions().code_coverage == 0 ? String[] : ["--code-coverage=user"]

function child_cmd(files::Vector{String})
    script = joinpath(@__DIR__, "runtests.jl")
    base_argv = collect(Base.julia_cmd())
    argv = vcat(base_argv, coverage_flags(), [script, "--jobs=1"], files)
    cmd = Cmd(argv)
    return addenv(
        cmd,
        "JULIA_PROJECT" => current_project_dir(),
        "JULIA_NUM_THREADS" => string(Threads.nthreads()),
    )
end

function run_child_shard(files::Vector{String}, shard_idx::Int, shard_count::Int)
    output = ""
    ok = false
    elapsed = @elapsed begin
        mktemp() do _, io
            proc = run(pipeline(ignorestatus(child_cmd(files)), stdout=io, stderr=io))
            flush(io)
            seekstart(io)
            output = read(io, String)
            ok = success(proc)
        end
    end
    return (
        idx=shard_idx,
        count=shard_count,
        files=files,
        ok=ok,
        output=output,
        elapsed=elapsed,
    )
end

function print_shard_result(result)
    println()
    println(
        "[test shard $(result.idx)/$(result.count)] $(join(result.files, ", ")) " *
        "($(fmt_duration(result.elapsed)))",
    )
    if !isempty(strip(result.output))
        print(result.output)
        endswith(result.output, '\n') || println()
    end
end

function run_parallel(files::Vector{String}, jobs::Int)
    shards = split_work(files, jobs)
    println(
        "Running $(length(files)) test file(s) across $(length(shards)) " *
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
            print_shard_result(result)
            failed |= !result.ok
        end
        failed && exit(1)
    end
    println()
    println(
        "Completed parallel test run for $(length(files)) file(s) in " *
        "$(fmt_duration(wall)).",
    )
end

jobs, selectors = parse_jobs(ARGS)
files = select_test_files(selectors)

if jobs == 1 || length(files) <= 1
    run_serial(files)
else
    run_parallel(files, jobs)
end
