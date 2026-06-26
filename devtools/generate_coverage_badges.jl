#!/usr/bin/env julia

using Dates
using Printf

branch_slug(branch::AbstractString) = replace(branch, '/' => '-')
scope_slug(scope::AbstractString) = replace(lowercase(scope), r"[^a-z0-9]+" => "-")

function scope_label(scope::AbstractString)
    labels = Dict(
        "unit" => "Unit Coverage",
        "doctest" => "Doctest Coverage",
        "notebook" => "Notebook Coverage",
        "bench" => "Benchmark Coverage",
    )
    return get(labels, lowercase(scope), string(titlecase(scope), " Coverage"))
end

function json_escape(text::AbstractString)
    return replace(
        text,
        "\\" => "\\\\",
        "\"" => "\\\"",
        "\n" => "\\n",
        "\r" => "\\r",
        "\t" => "\\t",
    )
end

json_value(value::Nothing) = "null"
json_value(value::Bool) = value ? "true" : "false"
json_value(value::Integer) = string(value)
json_value(value::AbstractFloat) = @sprintf("%.6f", value)
json_value(value::AbstractString) = "\"" * json_escape(value) * "\""

function write_json(path::AbstractString, pairs::Vector{Pair{String, Any}})
    open(path, "w") do io
        println(io, "{")
        for (idx, (key, value)) in enumerate(pairs)
            suffix = idx == length(pairs) ? "" : ","
            println(io, "  ", json_value(key), ": ", json_value(value), suffix)
        end
        println(io, "}")
    end
end

function parse_lcov(path::AbstractString)
    covered = 0
    executable = 0
    files = 0
    for line in eachline(path)
        startswith(line, "SF:") && (files += 1)
        startswith(line, "LH:") && (covered += parse(Int, line[4:end]))
        startswith(line, "LF:") && (executable += parse(Int, line[4:end]))
    end
    executable > 0 || error("No executable lines found in $path")
    return (
        covered=covered,
        executable=executable,
        pct=100 * covered / executable,
        files=files,
    )
end

function coverage_color(pct::Real)
    pct >= 95 && return "brightgreen"
    pct >= 90 && return "green"
    pct >= 80 && return "yellowgreen"
    pct >= 70 && return "yellow"
    pct >= 60 && return "orange"
    return "red"
end

function main(args)
    3 <= length(args) <= 4 || error(
        "Usage: julia --project=. devtools/generate_coverage_badges.jl <lcov.info> <scope> <branch> [outdir]",
    )
    lcov_path, scope, branch = args[1:3]
    outdir = length(args) == 4 ? args[4] : "coverage_badges"
    stats = parse_lcov(lcov_path)
    label = scope_label(scope)
    scope_key = scope_slug(scope)
    branch_key = branch_slug(branch)
    mkpath(outdir)

    badge_path = joinpath(outdir, "coverage-$(scope_key)-$(branch_key).json")
    manifest_path = joinpath(outdir, "coverage-source-$(scope_key)-$(branch_key).json")
    message = @sprintf("%.2f%%", stats.pct)
    color = coverage_color(stats.pct)
    generated_at =
        Dates.format(Dates.now(Dates.UTC), dateformat"yyyy-mm-ddTHH:MM:SS") * "Z"

    write_json(
        badge_path,
        [
            "schemaVersion" => 1,
            "label" => label,
            "message" => message,
            "color" => color,
            "namedLogo" => "julia",
        ],
    )

    write_json(
        manifest_path,
        [
            "branch" => branch,
            "scope" => scope_key,
            "label" => label,
            "generated_at" => generated_at,
            "coverage_pct" => stats.pct,
            "covered_lines" => stats.covered,
            "executable_lines" => stats.executable,
            "source_files" => stats.files,
            "lcov_filename" => basename(lcov_path),
            "badge_file" => "badges/" * basename(badge_path),
        ],
    )

    println("Wrote ", badge_path)
    println("Wrote ", manifest_path)
end

main(ARGS)
