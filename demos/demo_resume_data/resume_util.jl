# Shared utilities for Julia resume-check scripts.
# Mirrors QMCPy/demos/demo_resume_data/resume_util.py

import Pkg
Pkg.activate(joinpath(@__DIR__, "..", ".."); io=devnull)

using QuasiMC, Printf, Dates

# ── Data extraction ────────────────────────────────────────────────────────────

function _half_width(data)
    haskey(data, :error_bound) && return Float64(data[:error_bound])
    if haskey(data, :iteration_log)
        log = data[:iteration_log]
        !isempty(log) && return Float64(iterations(log)[end].error_bound)
    end
    return NaN
end

function _iters(data)
    haskey(data, :iteration_log) || return nothing
    log = data[:iteration_log]
    isempty(log) && return nothing
    return iterations(log)[end].iter
end

function _iteration_log_str(data)
    haskey(data, :iteration_log) || return ""
    log = data[:iteration_log]
    isempty(log) && return ""
    return sprint(show, iterations(log))
end

# Format one cell of an iteration-log row, matching Julia's IterationLog display.
function _fmt_iter_cell(key::Symbol, value)
    key in (:iter, :n) && return string(value)
    key == :solution   && return @sprintf("%.8g", value)
    if key in (:error_bound, :tol)
        isnan(value) && return "-"
        return @sprintf("%.3e", value)
    end
    if key == :elapsed
        isnan(value) && return "-"
        (abs(value) < 1e-3 || abs(value) >= 1e3) && return @sprintf("%.3e", value)
        return @sprintf("%.3f", value)
    end
    return string(value)
end

const _ITER_COLS = ((:iter,"iter"),(:n,"n"),(:solution,"solution"),
                    (:error_bound,"err_bound"),(:tol,"tol"),(:elapsed,"time(s)"))

function _format_iter_rows(rows)
    isempty(rows) && return ""
    fmted = [[_fmt_iter_cell(k, getfield(r, k)) for (k,_) in _ITER_COLS] for r in rows]
    widths = [maximum(length, vcat([hdr], [row[i] for row in fmted]))
              for (i, (_, hdr)) in enumerate(_ITER_COLS)]
    io = IOBuffer()
    println(io, join([lpad(_ITER_COLS[i][2], widths[i]) for i in eachindex(_ITER_COLS)], "  "))
    for row in fmted
        println(io, join([lpad(row[i], widths[i]) for i in eachindex(_ITER_COLS)], "  "))
    end
    return rstrip(String(take!(io)))
end

# Build the resume iteration log: last loose row (as checkpoint) + resumed rows
# with iter numbers continuing from the loose run's final count.
function _resume_log_str(loose_data, resume_data)
    has_loose  = haskey(loose_data,  :iteration_log) && !isempty(loose_data[:iteration_log])
    has_resume = haskey(resume_data, :iteration_log) && !isempty(resume_data[:iteration_log])
    !has_resume && return ""
    !has_loose  && return _iteration_log_str(resume_data)

    loose_rows  = collect(iterations(loose_data[:iteration_log]))
    resume_rows = collect(iterations(resume_data[:iteration_log]))
    last_loose  = last(loose_rows)
    offset      = last_loose.iter

    combined = vcat(
        [last_loose],
        [(iter=r.iter + offset, n=r.n, solution=r.solution,
          error_bound=r.error_bound, tol=r.tol, elapsed=r.elapsed) for r in resume_rows],
    )
    return _format_iter_rows(combined)
end

function _sc_primary_tol(sc, tol_name::String)
    tol_name == "abs_tol" && hasfield(typeof(sc), :abs_tol) && return Float64(sc.abs_tol)
    tol_name == "rel_tol" && hasfield(typeof(sc), :rel_tol) && return Float64(sc.rel_tol)
    if tol_name == "rmse_tol"
        hasfield(typeof(sc), :rmse_tol)  && return Float64(sc.rmse_tol)
        hasfield(typeof(sc), :target_tol) && return Float64(sc.target_tol)
    end
    return NaN
end

function _copy_tol!(sc_dst, sc_src, tol_name::String)
    if tol_name == "abs_tol"
        set_tolerance!(sc_dst; abs_tol=_sc_primary_tol(sc_src, "abs_tol"))
    elseif tol_name == "rel_tol"
        set_tolerance!(sc_dst; rel_tol=_sc_primary_tol(sc_src, "rel_tol"))
    elseif tol_name == "rmse_tol"
        set_tolerance!(sc_dst; rmse_tol=_sc_primary_tol(sc_src, "rmse_tol"))
    end
end

function _format_inputs(sc)
    lines = String[]
    for fname in (:abs_tol, :rel_tol, :rmse_tol, :target_tol,
                  :n_init, :n_max, :n_limit, :n_reps, :replications,
                  :levels_min, :levels_max, :n_tols)
        hasfield(typeof(sc), fname) || continue
        v = getfield(sc, fname)
        v === nothing && continue
        push!(lines, "$(fname): $(v isa Float64 ? @sprintf("%.2e", v) : v)")
    end
    if hasfield(typeof(sc), :integrand)
        f = sc.integrand
        try; push!(lines, "dimension: $(QuasiMC.dimension(f))"); catch; end
    end
    return join(lines, "\n")
end

# ── Stage record ───────────────────────────────────────────────────────────────

struct StageInfo
    label::String
    tol::Float64
    total_n::Int
    new_n::Int
    iters::Union{Int,Nothing}
    solution::Float64
    half_width::Float64
    time_sec::Float64
    inputs_str::String
    log_str::String
end

function _make_stage(label, sc, result, previous_n, tol_name;
                     time_sec=nothing, log_str_override=nothing)
    data = result.data
    n    = data[:n_total]
    sol  = result.solution
    t    = time_sec !== nothing ? time_sec :
               Float64(get(data, :time_integrate, NaN))
    ls   = log_str_override !== nothing ? log_str_override : _iteration_log_str(data)
    StageInfo(
        label,
        _sc_primary_tol(sc, tol_name),
        n, n - previous_n,
        _iters(data),
        Float64(sol isa Number ? sol : first(sol)),
        _half_width(data),
        t,
        _format_inputs(sc),
        ls,
    )
end

# ── Case runner ────────────────────────────────────────────────────────────────

function run_case(name, loose_factory, tight_factory; tol_name="abs_tol")
    try
        sc_loose = loose_factory()
        t0 = time(); result_loose = integrate(sc_loose)
        loose = _make_stage("Loose", sc_loose, result_loose, 0, tol_name;
            time_sec=Float64(get(result_loose.data, :time_integrate, time() - t0)))

        tight_ref = tight_factory()
        _copy_tol!(sc_loose, tight_ref, tol_name)
        t0 = time(); result_resume = integrate(sc_loose; resume=result_loose.data)
        resume = _make_stage("Resumed", sc_loose, result_resume, loose.total_n, tol_name;
            time_sec=Float64(get(result_resume.data, :time_integrate, time() - t0)),
            log_str_override=_resume_log_str(result_loose.data, result_resume.data))

        sc_fresh = tight_factory()
        t0 = time(); result_fresh = integrate(sc_fresh)
        fresh = _make_stage("Fresh", sc_fresh, result_fresh, 0, tol_name;
            time_sec=Float64(get(result_fresh.data, :time_integrate, time() - t0)))

        return (name=name, status=:ok, tol_header=tol_name,
                stages=StageInfo[loose, resume, fresh], error_msg="")
    catch e
        msg = sprint(showerror, e)
        @warn "run_case $name failed" exception=e
        return (name=name, status=:error, tol_header=tol_name,
                stages=StageInfo[], error_msg=msg)
    end
end

# ── Formatting ─────────────────────────────────────────────────────────────────

function _comma_int(n::Int)
    s = string(n); len = length(s)
    buf = IOBuffer()
    for (i, c) in enumerate(s)
        i > 1 && (len - i + 1) % 3 == 0 && print(buf, ',')
        print(buf, c)
    end
    return String(take!(buf))
end

function format_stage_summary(stages::Vector{StageInfo};
                               title="Stage summary", tol_header="abs_tol")
    isempty(stages) && return "\n$title\n(no stages)"
    tol_vals = [s.tol for s in stages if isfinite(s.tol) && s.tol > 0]
    sol_dec = isempty(tol_vals) ? 8 : clamp(Int(ceil(-log10(minimum(tol_vals)))) + 1, 7, 12)
    sol_w   = sol_dec + 4

    stage_w   = 7
    tol_w     = max(7, length(tol_header) + (tol_header == "rmse_tol" ? 1 : 0))
    total_ns  = [_comma_int(s.total_n) for s in stages]
    new_ns    = [_comma_int(s.new_n)   for s in stages]
    total_n_w = max(9, maximum(length, total_ns))
    new_n_w   = max(9, maximum(length, new_ns))
    iters_w   = 6
    hw_w      = 10
    time_w    = 8
    sep_len   = stage_w + tol_w + total_n_w + new_n_w + iters_w + sol_w + hw_w + time_w + 7
    sep       = "-"^sep_len

    io = IOBuffer()
    println(io, "\n", title)
    println(io, sep)
    println(io,
        rpad("Stage", stage_w), " ",
        lpad(tol_header, tol_w), " ",
        lpad("total n", total_n_w), " ",
        lpad("new n", new_n_w), " ",
        lpad("iters", iters_w), " ",
        lpad("solution", sol_w), " ",
        lpad("half-width", hw_w), " ",
        lpad("time (s)", time_w))
    println(io, sep)
    for (s, tn, nn) in zip(stages, total_ns, new_ns)
        tol_str  = isfinite(s.tol) ? @sprintf("%.0e", s.tol) : "---"
        sol_str  = @sprintf("%.*f", sol_dec, s.solution)
        iter_str = s.iters === nothing ? "-" : string(s.iters)
        hw_str   = isnan(s.half_width) ? lpad("nan", hw_w) : lpad(@sprintf("%.2e", s.half_width), hw_w)
        println(io,
            rpad(s.label, stage_w), " ",
            lpad(tol_str, tol_w), " ",
            lpad(tn, total_n_w), " ",
            lpad(nn, new_n_w), " ",
            lpad(iter_str, iters_w), " ",
            lpad(sol_str, sol_w), " ",
            hw_str, " ",
            lpad(isnan(s.time_sec) ? "-" : @sprintf("%.4f", s.time_sec), time_w))
    end
    print(io, sep)
    return String(take!(io))
end

# ── Warnings ───────────────────────────────────────────────────────────────────

function _collect_warnings(name, resume::StageInfo, fresh::StageInfo)
    warnings = String[]
    resume.total_n != fresh.total_n && push!(warnings,
        "WARNING: $name: Inconsistent total samples " *
        "(resume_n=$(resume.total_n), fresh_n=$(fresh.total_n))")
    ri, fi = resume.iters, fresh.iters
    if !startswith(name, "CubML") && ri !== nothing && fi !== nothing && ri != fi
        push!(warnings,
            "WARNING: $name: Inconsistent iterations " *
            "(resume_iters=$ri, fresh_iters=$fi)")
    end
    rs, fs, rt = resume.solution, fresh.solution, resume.tol
    if all(isfinite, (rs, fs, rt)) && abs(rs - fs) > 2 * rt
        push!(warnings,
            "WARNING: $name: Resume and fresh solutions differ by >2×tol " *
            "(resume=$rs, fresh=$fs, tol=$rt)")
    end
    return warnings
end

# ── Report writer ──────────────────────────────────────────────────────────────

function _indent_lines(text, prefix="    ")
    join([prefix * l for l in split(text, '\n')], '\n')
end

function write_combined_report(path, title, cases)
    sep = "~"^60
    io = IOBuffer()
    println(io, title)
    println(io, "generated: ", Dates.format(now(), "yyyy-mm-dd HH:MM:SS"))
    println(io)

    stage_labels = ["loose", "resume", "fresh"]

    for (i, case) in enumerate(cases)
        i > 1 && println(io, sep, "\n")
        println(io, "[$(case.name)] status=$(case.status)")

        if case.status != :ok
            println(io, "  error: ", case.error_msg)
            println(io)
            continue
        end

        stages = case.stages

        for (lbl, st) in zip(stage_labels, stages)
            isempty(st.inputs_str) && continue
            println(io)
            println(io, "  $(lbl)_inputs:")
            println(io, _indent_lines(st.inputs_str))
        end

        for (lbl, st) in zip(stage_labels, stages)
            isempty(st.log_str) && continue
            println(io)
            println(io, "  $(lbl)_iteration_log:")
            println(io, _indent_lines(st.log_str))
        end

        if length(stages) == 3
            summary = format_stage_summary(stages;
                title="Stage summary of $(case.name)",
                tol_header=case.tol_header)
            println(io)
            println(io, _indent_lines(strip(summary), "  "))

            for w in _collect_warnings(case.name, stages[2], stages[3])
                println(io)
                println(io, "  ", w)
            end
        end
        println(io)
    end

    write(path, String(take!(io)))
    println("wrote: ", path)
end
