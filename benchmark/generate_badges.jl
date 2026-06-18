using JSON3
using Printf

resdir = joinpath(@__DIR__, "results")
badgedir = joinpath(resdir, "badges")
mkpath(badgedir)

summary_outfile(label::AbstractString) =
    isempty(label) ? joinpath(resdir, "compare_python_summary.json") :
    joinpath(resdir, "compare_python_summary_$(label).json")

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

branch_slug(branch::AbstractString) = replace(branch, '/' => '-')

function write_branch_badges(summary, branch::AbstractString)
    slug = branch_slug(branch)
    time_ratio = Float64(summary["time_ratio"])
    time_msg =
        time_ratio >= 1 ? @sprintf("%.2fx faster", time_ratio) :
        @sprintf("%.2fx slower", 1 / time_ratio)
    time_color = ratio_color(time_ratio)

    write_badge(
        joinpath(badgedir, "benchmark-speed-$slug.json"),
        "time vs QMCPy ($branch)",
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
            "memory vs QMCPy ($branch)",
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
