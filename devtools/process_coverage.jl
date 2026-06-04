#!/usr/bin/env julia

const COVERAGE_ROOTS = ("src",)

function cov_to_source_path(path::AbstractString)
    return replace(path, r"\.(?:\d+\.)?cov$" => "")
end

function parse_cov_file(path::AbstractString)
    counts = Int[]
    for line in eachline(path)
        m = match(r"^\s*([0-9]+|-)\s+(.*)$", line)
        isnothing(m) && error("Unrecognized coverage line in $path: $line")
        token = m.captures[1]
        push!(counts, token == "-" ? -1 : parse(Int, token))
    end
    return counts
end

function merge_counts!(merged::Dict{String, Vector{Int}}, cov_path::AbstractString)
    source_path = cov_to_source_path(cov_path)
    counts = parse_cov_file(cov_path)
    dest = get!(merged, source_path) do
        fill(-1, length(counts))
    end
    length(dest) == length(counts) || error(
        "Coverage file length mismatch for $source_path",
    )
    @inbounds for i in eachindex(counts)
        count = counts[i]
        if count >= 0
            dest[i] = max(dest[i], 0) + count
        end
    end
    return merged
end

function collect_coverage(roots)
    merged = Dict{String, Vector{Int}}()
    cov_files = String[]
    for root in roots
        isdir(root) || continue
        for (dir, _, files) in walkdir(root)
            for file in files
                endswith(file, ".cov") || continue
                path = joinpath(dir, file)
                push!(cov_files, path)
                merge_counts!(merged, path)
            end
        end
    end
    isempty(cov_files) && error("No coverage files found under $(join(roots, ", "))")
    return merged, sort(cov_files)
end

function summarize_file(counts::AbstractVector{Int})
    exec_lines = count(>=(0), counts)
    covered_lines = count(>(0), counts)
    pct = exec_lines == 0 ? 100.0 : 100 * covered_lines / exec_lines
    return covered_lines, exec_lines, pct
end

function write_lcov(path::AbstractString, merged::Dict{String, Vector{Int}})
    open(path, "w") do io
        for source in sort(collect(keys(merged)))
            counts = merged[source]
            println(io, "TN:")
            println(io, "SF:$(normpath(source))")
            covered, exec, _ = summarize_file(counts)
            for (line_no, count) in enumerate(counts)
                count < 0 && continue
                println(io, "DA:$line_no,$count")
            end
            println(io, "LF:$exec")
            println(io, "LH:$covered")
            println(io, "end_of_record")
        end
    end
end

function print_summary(merged::Dict{String, Vector{Int}})
    rows = Tuple{String, Int, Int, Float64}[]
    total_covered = 0
    total_exec = 0
    for source in sort(collect(keys(merged)))
        covered, exec, pct = summarize_file(merged[source])
        total_covered += covered
        total_exec += exec
        push!(rows, (source, covered, exec, pct))
    end
    total_pct = total_exec == 0 ? 100.0 : 100 * total_covered / total_exec
    println("Coverage summary (src):")
    for (source, covered, exec, pct) in rows
        pct_str = string(round(pct; digits=2), "%")
        println("  $(rpad(source, 56)) $(lpad(pct_str, 8))  ($covered/$exec)")
    end
    println("Wrote lcov.info")
    println("  total: $(round(total_pct; digits=2))% ($total_covered/$total_exec executable lines)")
end

merged, _ = collect_coverage(COVERAGE_ROOTS)
write_lcov("lcov.info", merged)
print_summary(merged)
