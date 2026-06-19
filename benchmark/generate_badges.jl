using JSON3
using Printf

resdir = joinpath(@__DIR__, "results")
badgedir = joinpath(resdir, "badges")
mkpath(badgedir)

summary_outfile(label::AbstractString) =
    isempty(label) ? joinpath(resdir, "compare_python_summary.json") :
    joinpath(resdir, "compare_python_summary_$(label).json")

requirements_file() = joinpath(@__DIR__, "qmcpy-requirements.txt")

function resolve_summary_outfile(label::AbstractString)
    primary = summary_outfile(label)
    if isfile(primary)
        return primary
    end
    if label == "latest"
        fallback = summary_outfile("")
        isfile(fallback) && return fallback
    end
    return primary
end

function ratio_color(ratio)
    ratio >= 4.0 && return "brightgreen"
    ratio >= 2.0 && return "green"
    ratio >= 1.1 && return "yellowgreen"
    ratio >= 0.9 && return "yellow"
    ratio >= 0.75 && return "orange"
    return "red"
end

function badge_payload(label, message, color; named_logo=nothing)
    payload = Dict{String, Any}(
        "schemaVersion" => 1,
        "label" => label,
        "message" => message,
        "color" => color,
    )
    named_logo === nothing || (payload["namedLogo"] = named_logo)
    return payload
end

function write_badge(path, label, message, color; named_logo=nothing)
    open(path, "w") do io
        JSON3.pretty(io, badge_payload(label, message, color; named_logo))
    end
end

function pinned_qmcpy_version()
    isfile(requirements_file()) || return nothing
    for line in eachline(requirements_file())
        m = match(r"^qmcpy==([A-Za-z0-9._+-]+)$", strip(line))
        m === nothing || return m.captures[1]
    end
    return nothing
end

function qmcpy_badge_label(summary, metric::AbstractString)
    version = haskey(summary, "qmcpy_version") ? summary["qmcpy_version"] : nothing
    version === nothing && (version = pinned_qmcpy_version())
    suffix = version === nothing ? "QMCPy" : "QMCPy v$(version)"
    return "$(metric) vs $(suffix)"
end

branch_slug(branch::AbstractString) = replace(branch, '/' => '-')

function maybe_get(summary, key::AbstractString, default=nothing)
    for candidate in (key, Symbol(key))
        haskey(summary, candidate) && return summary[candidate]
    end
    return default
end

function write_source_manifest(summary, label::AbstractString, branch::AbstractString)
    slug = branch_slug(branch)
    manifest = Dict(
        "branch" => branch,
        "label" => label,
        "report_generated_at" => maybe_get(summary, "report_generated_at", nothing),
        "jl_label" => maybe_get(summary, "jl_label", nothing),
        "py_label" => maybe_get(summary, "py_label", nothing),
        "qmcpy_version" => maybe_get(summary, "qmcpy_version", pinned_qmcpy_version()),
        "summary_filename" => maybe_get(
            summary,
            "summary_filename",
            basename(resolve_summary_outfile(label)),
        ),
        "markdown_report_filename" =>
            maybe_get(summary, "markdown_report_filename", nothing),
        "jl_artifact_filename" => maybe_get(summary, "jl_artifact_filename", nothing),
        "jl_memory_artifact_filename" =>
            maybe_get(summary, "jl_memory_artifact_filename", nothing),
        "jl_solution_artifact_filename" =>
            maybe_get(summary, "jl_solution_artifact_filename", nothing),
        "jl_oracle_artifact_filename" =>
            maybe_get(summary, "jl_oracle_artifact_filename", nothing),
        "py_artifact_filename" => maybe_get(summary, "py_artifact_filename", nothing),
        "time_ratio" => maybe_get(summary, "time_ratio", nothing),
        "time_ratio_bootstrap_95" => maybe_get(summary, "time_ratio_bootstrap_95", nothing),
        "peak_ratio" => maybe_get(summary, "peak_ratio", nothing),
        "rss_ratio" => maybe_get(summary, "rss_ratio", nothing),
        "badge_files" => Dict(
            "speed" => "badges/benchmark-speed-$slug.json",
            "memory" => "badges/benchmark-memory-$slug.json",
            "peak_memory" => "badges/benchmark-peak-$slug.json",
        ),
    )
    open(joinpath(badgedir, "benchmark-source-$slug.json"), "w") do io
        JSON3.pretty(io, manifest)
    end
end

function write_branch_badges(summary, branch::AbstractString)
    slug = branch_slug(branch)
    time_ratio = Float64(summary["time_ratio"])
    time_msg =
        time_ratio >= 1 ? @sprintf("%.2fx faster", time_ratio) :
        @sprintf("%.2fx slower", 1 / time_ratio)
    time_color = ratio_color(time_ratio)

    write_badge(
        joinpath(badgedir, "benchmark-speed-$slug.json"),
        qmcpy_badge_label(summary, "Time"),
        time_msg,
        time_color;
        named_logo="julia",
    )

    haskey(summary, "peak_ratio") && summary["peak_ratio"] !== nothing || return
    peak_ratio = Float64(summary["peak_ratio"])
    peak_msg =
        peak_ratio >= 1 ? @sprintf("%.2fx lower", peak_ratio) :
        @sprintf("%.2fx higher", 1 / peak_ratio)
    peak_color = ratio_color(peak_ratio)
    for filename in ("benchmark-memory-$slug.json", "benchmark-peak-$slug.json")
        write_badge(
            joinpath(badgedir, filename),
            qmcpy_badge_label(summary, "Memory"),
            peak_msg,
            peak_color;
            named_logo="julia",
        )
    end
end

label =
    isempty(ARGS) ?
    error("Usage: julia --project=benchmark benchmark/generate_badges.jl <label> [branch]") :
    ARGS[1]
branch = length(ARGS) >= 2 ? ARGS[2] : "develop"

summary = JSON3.read(read(resolve_summary_outfile(label), String))
write_branch_badges(summary, branch)
write_source_manifest(summary, label, branch)
