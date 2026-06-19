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
# Output: benchmark/results/compare_python.md by default, or compare_python_<label>.md
#
# Ratio convention (same as compare.jl):
#   ratio = reference (Python) time ÷ local (Julia) time
#   ratio < 1  →  local is SLOWER than Python  ❌
#   ratio > 1  →  local is FASTER than Python  ✅
#
# NOTE: `ms` is directly cross-comparable. Julia reports both `alloc KiB` from
# BenchmarkTools and, when available, a coarse retained `rss_delta_kib` sidecar
# captured by `runbenchmarks.jl`. Python reports `tracemalloc_peak_kib` and a
# coarse retained `rss_delta_kib` from one warmed call.
# C-kernel rows (Lattice, DigitalNetB2, Halton gen_samples) measure the same C
# library on both sides; they are NOT a language comparison (see benchmark_qmcpy.py).

using Pkg
Pkg.activate(@__DIR__)
# QMC is unregistered, so always develop it by local path — even if it is already
# listed in this project's [deps]. benchmark/Manifest.toml is gitignored, so a
# fresh CI checkout has no manifest and Pkg.resolve() below would otherwise try to
# look QMC up in a registry and fail ("expected package QMC to be registered").
Pkg.develop(; path=dirname(@__DIR__))
let deps = keys(Pkg.project().dependencies)
    "BenchmarkTools" in deps || Pkg.add("BenchmarkTools")
    "JSON3" in deps || Pkg.add("JSON3")
end
# Keep the benchmark manifest in sync when the local path package changes deps.
Pkg.resolve()
Pkg.instantiate()

using BenchmarkTools
using Dates
using JSON3
using Printf
using Random
using Statistics

resdir = joinpath(@__DIR__, "results")
compare_py_outfile(label::AbstractString) =
    isempty(label) ? joinpath(resdir, "compare_python.md") :
    joinpath(resdir, "compare_python_$(label).md")
compare_py_summary_outfile(label::AbstractString) =
    isempty(label) ? joinpath(resdir, "compare_python_summary.json") :
    joinpath(resdir, "compare_python_summary_$(label).json")
const ARTIFACT_SKEW_WARNING_SECONDS = 10 * 60
const STRICT_ACCURACY_ENV = "QMC_BENCH_REQUIRE_QMCPY_ACCURACY"
const TIME_RATIO_BOOTSTRAP_DRAWS = 1_000
const TIME_RATIO_BOOTSTRAP_SEED = 20260619

finite_or_nothing(x) = x isa Real && isfinite(x) ? x : nothing

is_c_kernel_row(name::AbstractString) = occursin(r"Lattice|DigitalNetB2|Halton", name)
is_student_t_row(name::AbstractString) = occursin("StudentT", name)

function maybe_get(obj, key, default=nothing)
    obj === nothing && return default
    for candidate in (key, Symbol(key))
        try
            haskey(obj, candidate) && return obj[candidate]
        catch
        end
    end
    return default
end

function artifact_mtime(path::AbstractString)
    secs = floor(Int, stat(path).mtime)
    return Dates.format(Dates.unix2datetime(secs), dateformat"yyyy-mm-ddTHH:MM:SS")
end

function format_seconds(seconds::Real)
    total = round(Int, seconds)
    if total < 60
        return "$(total) s"
    elseif total < 3600
        mins, secs = divrem(total, 60)
        return "$(mins) m $(secs) s"
    end
    hours, rems = divrem(total, 3600)
    mins, secs = divrem(rems, 60)
    return "$(hours) h $(mins) m $(secs) s"
end

function format_thread_env(thread_env)
    thread_env === nothing && return "n/a"
    entries = String[]
    for (key, value) in pairs(thread_env)
        push!(entries, string(key) * "=" * string(value))
    end
    isempty(entries) && return "n/a"
    return join(sort(entries), ", ")
end

function wait_for_artifact(
    path::AbstractString;
    timeout_s::Real=10.0,
    poll_interval_s::Real=0.1,
)
    deadline = time() + timeout_s
    while true
        isfile(path) && return true
        time() >= deadline && return false
        sleep(poll_interval_s)
    end
end

function lookup_py_entry(py_results, group, name)
    py_group = get(py_results, Symbol(group), nothing)
    py_group === nothing && return nothing
    return get(
        py_group,
        name,
        get(py_group, replace(name, r" d=\d+" => s -> " [C]" * s), nothing),
    )
end

function lookup_jl_memory_entry(jl_memory_results, group, name)
    jl_memory_results === nothing && return nothing
    jl_group = get(jl_memory_results, Symbol(group), nothing)
    jl_group === nothing && return nothing
    return get(jl_group, name, nothing)
end

jl_time_samples_ms(trial::BenchmarkTools.Trial) = Float64.(trial.times) ./ 1e6

function py_time_samples_ms(py_entry)
    samples = maybe_get(py_entry, "samples_ms", nothing)
    samples === nothing && return nothing
    return Float64[Float64(sample) for sample in samples]
end

function collect_comparison_rows(jl_results, jl_memory_results, py_results)
    rows = NamedTuple[]
    for group in sort(collect(keys(jl_results)))
        for name in sort(collect(keys(jl_results[group])))
            jl_raw_trial = jl_results[group][name]
            jl_trial = median(jl_raw_trial)
            jl_samples_ms = jl_time_samples_ms(jl_raw_trial)
            jl_ms = jl_trial.time / 1e6
            jl_kib = jl_trial.memory / 1024
            jl_mem_entry = lookup_jl_memory_entry(jl_memory_results, group, name)
            py_entry = lookup_py_entry(py_results, group, name)
            if py_entry !== nothing && !haskey(py_entry, "error")
                push!(
                    rows,
                    (
                        group=group,
                        name=name,
                        jl_ms=jl_ms,
                        jl_samples_ms=jl_samples_ms,
                        jl_kib=jl_kib,
                        jl_rss_delta_kib=jl_mem_entry !== nothing &&
                                         haskey(jl_mem_entry, "rss_delta_kib") ?
                                         Float64(jl_mem_entry["rss_delta_kib"]) : nothing,
                        py_ms=Float64(py_entry["median_ms"]),
                        py_samples_ms=py_time_samples_ms(py_entry),
                        py_peak_kib=haskey(py_entry, "tracemalloc_peak_kib") ?
                                    Float64(py_entry["tracemalloc_peak_kib"]) : nothing,
                        py_rss_delta_kib=haskey(py_entry, "rss_delta_kib") ?
                                         Float64(py_entry["rss_delta_kib"]) : nothing,
                        py_error=nothing,
                        c_kernel=is_c_kernel_row(name),
                        student_t=is_student_t_row(name),
                    ),
                )
            else
                push!(
                    rows,
                    (
                        group=group,
                        name=name,
                        jl_ms=jl_ms,
                        jl_samples_ms=jl_samples_ms,
                        jl_kib=jl_kib,
                        jl_rss_delta_kib=jl_mem_entry !== nothing &&
                                         haskey(jl_mem_entry, "rss_delta_kib") ?
                                         Float64(jl_mem_entry["rss_delta_kib"]) : nothing,
                        py_ms=nothing,
                        py_samples_ms=nothing,
                        py_peak_kib=nothing,
                        py_rss_delta_kib=nothing,
                        py_error=py_entry === nothing ? "no Python data" :
                                 string(py_entry["error"]),
                        c_kernel=is_c_kernel_row(name),
                        student_t=is_student_t_row(name),
                    ),
                )
            end
        end
    end
    return rows
end

function summary_metrics(rows; include=(row -> true))
    scoped_rows = filter(include, rows)
    matched = filter(row -> row.py_ms !== nothing, scoped_rows)
    total_jl_ms = sum((row.jl_ms for row in matched); init=0.0)
    total_py_ms = sum((row.py_ms for row in matched); init=0.0)
    peak_rows = filter(row -> row.py_peak_kib !== nothing, matched)
    rss_rows = filter(
        row -> row.py_rss_delta_kib !== nothing && row.jl_rss_delta_kib !== nothing,
        matched,
    )
    total_jl_peak_kib = sum((row.jl_kib for row in peak_rows); init=0.0)
    total_py_peak_kib = sum((row.py_peak_kib for row in peak_rows); init=0.0)
    total_jl_rss_kib = sum((row.jl_rss_delta_kib for row in rss_rows); init=0.0)
    total_py_rss_delta_kib = sum((row.py_rss_delta_kib for row in rss_rows); init=0.0)
    return (
        matched=length(matched),
        total=length(scoped_rows),
        jl_ms=total_jl_ms,
        py_ms=total_py_ms,
        time_ratio=total_jl_ms > 0 ? total_py_ms / total_jl_ms : NaN,
        peak_rows=length(peak_rows),
        jl_peak_kib=total_jl_peak_kib,
        py_peak_kib=total_py_peak_kib,
        peak_ratio=total_jl_peak_kib > 0 ? total_py_peak_kib / total_jl_peak_kib : NaN,
        rss_rows=length(rss_rows),
        jl_rss_kib=total_jl_rss_kib,
        py_rss_delta_kib=total_py_rss_delta_kib,
        rss_ratio=total_jl_rss_kib > 0 ? total_py_rss_delta_kib / total_jl_rss_kib : nothing,
    )
end

function bootstrap_time_ratio(
    rows;
    include=(row -> true),
    draws::Int=TIME_RATIO_BOOTSTRAP_DRAWS,
    seed::Int=TIME_RATIO_BOOTSTRAP_SEED,
)
    matched = filter(
        row ->
            include(row) &&
            row.py_ms !== nothing &&
            row.jl_samples_ms !== nothing &&
            row.py_samples_ms !== nothing,
        rows,
    )
    isempty(matched) && return nothing
    rng = MersenneTwister(seed)
    ratios = Vector{Float64}(undef, draws)
    for draw in 1:draws
        jl_total = 0.0
        py_total = 0.0
        for row in matched
            jl_total += median(rand(rng, row.jl_samples_ms, length(row.jl_samples_ms)))
            py_total += median(rand(rng, row.py_samples_ms, length(row.py_samples_ms)))
        end
        ratios[draw] = py_total / jl_total
    end
    return (
        draws=draws,
        lower=quantile(ratios, 0.025),
        median=median(ratios),
        upper=quantile(ratios, 0.975),
        matched=length(matched),
    )
end

function ci_to_dict(ci)
    ci === nothing && return nothing
    return Dict(
        "draws" => ci.draws,
        "lower" => ci.lower,
        "median" => ci.median,
        "upper" => ci.upper,
        "matched_rows" => ci.matched,
    )
end

function format_ci(ci)
    ci === nothing && return "n/a"
    return @sprintf("[%.3f, %.3f]", ci.lower, ci.upper)
end

function group_scope_description(group::AbstractString)
    group == "gen_samples" && return "generator only"
    group == "transform" && return "transform only"
    group == "evaluate" && return "integrand evaluation only"
    if group == "integrate"
        return "end-to-end adaptive integration; not isolated stopping-criterion overhead"
    end
    return group
end

function collect_group_summaries(rows)
    groups = sort(unique(string(row.group) for row in rows))
    out = NamedTuple[]
    for (idx, group) in enumerate(groups)
        summary = summary_metrics(rows; include=row -> string(row.group) == group)
        time_ci = bootstrap_time_ratio(
            rows;
            include=row -> string(row.group) == group,
            seed=TIME_RATIO_BOOTSTRAP_SEED + idx,
        )
        push!(
            out,
            (
                group=group,
                description=group_scope_description(group),
                summary=summary,
                time_ci=time_ci,
            ),
        )
    end
    return out
end

# ── Accuracy: Julia vs Python solution values ────────────────────────────────
# A stopping criterion returns an estimate within `tol` of the true integral,
# where the effective tolerance is `max(abs_tol, rel_tol*|value|)`. Two independent
# estimates (Julia, Python) should therefore agree within `2*tol` (triangle
# inequality). `accuracy_check` flags integrate cases that exceed that bound.
#   * absolute tol  →  |jl - py|        ≤ 2*abs_tol
#   * relative tol  →  |jl - py|/|py|   ≤ 2*rel_tol
function accuracy_check(jl_sol, py_sol, abs_tol, rel_tol)
    diff = abs(jl_sol - py_sol)
    eff_tol = max(abs_tol, rel_tol * abs(py_sol))
    allowed = 2 * eff_tol
    mode = (rel_tol > 0 && rel_tol * abs(py_sol) >= abs_tol) ? "rel" : "abs"
    rel_diff = py_sol != 0 ? diff / abs(py_sol) : NaN
    return (
        diff=diff,
        rel_diff=rel_diff,
        eff_tol=eff_tol,
        allowed=allowed,
        mode=mode,
        flagged=diff > allowed,
    )
end

function collect_accuracy_rows(jl_solutions, py_results)
    rows = NamedTuple[]
    jl_solutions === nothing && return rows
    py_group = get(py_results, :integrate, nothing)
    for (name, jl) in pairs(jl_solutions)
        namestr = string(name)
        haskey(jl, "error") && continue
        jl_sol = Float64(jl["solution"])
        abs_tol = Float64(jl["abs_tol"])
        rel_tol = Float64(jl["rel_tol"])
        py_entry = py_group === nothing ? nothing : get(py_group, namestr, nothing)
        py_sol =
            (py_entry !== nothing && haskey(py_entry, "solution")) ?
            Float64(py_entry["solution"]) : nothing
        check = py_sol === nothing ? nothing : accuracy_check(jl_sol, py_sol, abs_tol, rel_tol)
        push!(
            rows,
            (
                name=namestr,
                jl_sol=jl_sol,
                py_sol=py_sol,
                abs_tol=abs_tol,
                rel_tol=rel_tol,
                check=check,
            ),
        )
    end
    return sort(rows; by=r -> r.name)
end

function oracle_value_vector(entry)
    vals = maybe_get(entry, "values", nothing)
    vals === nothing && return nothing
    return Float64[Float64(v) for v in vals]
end

function oracle_tolerance(entry, key::AbstractString)
    raw = maybe_get(entry, key, 0.0)
    return Float64(raw)
end

function compare_oracle_values(jl_entry, py_entry)
    jl_values = oracle_value_vector(jl_entry)
    py_values = oracle_value_vector(py_entry)
    jl_values === nothing && return nothing
    py_values === nothing && return nothing
    atol = max(oracle_tolerance(jl_entry, "atol"), oracle_tolerance(py_entry, "atol"))
    rtol = max(oracle_tolerance(jl_entry, "rtol"), oracle_tolerance(py_entry, "rtol"))
    jl_shape = maybe_get(jl_entry, "shape", Int[])
    py_shape = maybe_get(py_entry, "shape", Int[])
    max_abs_diff = 0.0
    max_rel_diff = 0.0
    n_failed = 0
    n_compared = min(length(jl_values), length(py_values))
    for i in 1:n_compared
        diff = abs(jl_values[i] - py_values[i])
        rel = py_values[i] == 0 ? (diff == 0 ? 0.0 : Inf) : diff / abs(py_values[i])
        allowed = atol + rtol * abs(py_values[i])
        max_abs_diff = max(max_abs_diff, diff)
        max_rel_diff = max(max_rel_diff, rel)
        diff > allowed && (n_failed += 1)
    end
    shape_match = collect(jl_shape) == collect(py_shape)
    length_match = length(jl_values) == length(py_values)
    flagged = !shape_match || !length_match || n_failed > 0
    return (
        max_abs_diff=max_abs_diff,
        max_rel_diff=max_rel_diff,
        atol=atol,
        rtol=rtol,
        n_failed=n_failed,
        n_compared=n_compared,
        jl_len=length(jl_values),
        py_len=length(py_values),
        shape_match=shape_match,
        length_match=length_match,
        flagged=flagged,
    )
end

function collect_oracle_rows(jl_oracles, py_oracles)
    rows = NamedTuple[]
    jl_oracles === nothing && return rows
    py_oracles === nothing && return rows
    for group_name in ("transform", "evaluate")
        jl_group = maybe_get(jl_oracles, group_name, nothing)
        jl_group === nothing && continue
        py_group = maybe_get(py_oracles, group_name, nothing)
        for (name, jl_entry) in pairs(jl_group)
            namestr = string(name)
            haskey(jl_entry, "error") && continue
            py_entry = py_group === nothing ? nothing : get(py_group, namestr, nothing)
            check =
                (py_entry !== nothing && !haskey(py_entry, "error")) ?
                compare_oracle_values(jl_entry, py_entry) : nothing
            push!(rows, (group=group_name, name=namestr, check=check))
        end
    end
    return sort(rows; by=r -> (r.group, r.name))
end

jl_label = length(ARGS) >= 1 ? ARGS[1] : "latest"
py_label = length(ARGS) >= 2 ? ARGS[2] : jl_label
out_label = length(ARGS) >= 3 ? ARGS[3] : ""

jl_file = joinpath(resdir, "$(jl_label).json")
jl_mem_file = joinpath(resdir, "$(jl_label)_memory.json")
py_file = joinpath(resdir, "qmcpy_$(py_label).json")

wait_for_artifact(jl_file) || error(
    "Julia results not found after waiting 10s: $jl_file\nRun: make bench" *
    (jl_label == "latest" ? "" : " then julia benchmark/runbenchmarks.jl $jl_label"),
)
wait_for_artifact(py_file) || error(
    "QMCPy results not found after waiting 10s: $py_file\n" *
    "Run: python benchmark/benchmark_qmcpy.py $py_label",
)

jl_results = BenchmarkTools.load(jl_file)[1]
jl_mem_data = isfile(jl_mem_file) ? JSON3.read(read(jl_mem_file, String)) : nothing
py_data = JSON3.read(read(py_file, String))

jl_memory_results = jl_mem_data === nothing ? nothing : jl_mem_data["results"]
py_results = py_data["results"]
py_version = get(py_data, "qmcpy_version", "?")
py_python_version = maybe_get(py_data, "python_version", "?")
report_generated_at = Dates.format(Dates.now(), dateformat"yyyy-mm-ddTHH:MM:SS")
jl_generated_at = maybe_get(jl_mem_data, "generated_at", "n/a")
jl_blas_threads = maybe_get(jl_mem_data, "blas_threads", "n/a")
jl_config = maybe_get(jl_mem_data, "benchmark_config", nothing)
jl_integrate_samples = maybe_get(jl_config, "integrate_samples", "n/a")
jl_student_t_samples = maybe_get(jl_config, "student_t_samples", "n/a")
py_generated_at = maybe_get(py_data, "generated_at", "n/a")
py_config = maybe_get(py_data, "benchmark_config", nothing)
py_integrate_repeat = maybe_get(py_config, "integrate_repeat", "n/a")
py_student_t_repeat = maybe_get(py_config, "student_t_repeat", "n/a")
py_student_t_warmup_runs = maybe_get(py_config, "student_t_warmup_runs", "n/a")
py_thread_env = format_thread_env(maybe_get(py_data, "thread_env", nothing))
jl_file_mtime = artifact_mtime(jl_file)
py_file_mtime = artifact_mtime(py_file)
artifact_skew_seconds = abs(stat(jl_file).mtime - stat(py_file).mtime)
rows = collect_comparison_rows(jl_results, jl_memory_results, py_results)
summary = summary_metrics(rows)
summary_non_student_t = summary_metrics(rows; include=row -> !row.student_t)
summary_student_t = summary_metrics(rows; include=row -> row.student_t)
summary_time_ci = bootstrap_time_ratio(rows)
summary_non_student_t_time_ci = bootstrap_time_ratio(rows; include=row -> !row.student_t)
summary_student_t_time_ci =
    summary_student_t.total > 0 ? bootstrap_time_ratio(rows; include=row -> row.student_t) :
    nothing
group_summaries = collect_group_summaries(rows)

jl_sol_file = joinpath(resdir, "$(jl_label)_solutions.json")
jl_sol_data = isfile(jl_sol_file) ? JSON3.read(read(jl_sol_file, String)) : nothing
jl_solutions = jl_sol_data === nothing ? nothing : get(jl_sol_data, :solutions, nothing)
accuracy_rows = collect_accuracy_rows(jl_solutions, py_results)
checked_accuracy_rows = count(r -> r.check !== nothing, accuracy_rows)
n_flagged = count(r -> r.check !== nothing && r.check.flagged, accuracy_rows)

jl_oracle_file = joinpath(resdir, "$(jl_label)_oracles.json")
jl_oracle_data = isfile(jl_oracle_file) ? JSON3.read(read(jl_oracle_file, String)) : nothing
jl_oracles = jl_oracle_data === nothing ? nothing : get(jl_oracle_data, :oracles, nothing)
py_oracles = maybe_get(py_data, "oracles", nothing)
oracle_rows = collect_oracle_rows(jl_oracles, py_oracles)
checked_oracle_rows = count(r -> r.check !== nothing, oracle_rows)
n_flagged_oracle_rows = count(r -> r.check !== nothing && r.check.flagged, oracle_rows)
strict_accuracy = get(ENV, STRICT_ACCURACY_ENV, "0") == "1"

println("Julia vs QMCPy benchmark comparison")
println("  Julia label   : $jl_label")
println("  QMCPy label   : $py_label  (qmcpy $py_version)")
println(
    "  Julia artifact: $(basename(jl_file))  (mtime $jl_file_mtime, generated $jl_generated_at)",
)
println(
    "  QMCPy artifact: $(basename(py_file))  (mtime $py_file_mtime, generated $py_generated_at)",
)
println("  Artifact skew : $(format_seconds(artifact_skew_seconds))")
println(
    "  Julia config  : BLAS threads=$(jl_blas_threads), integrate samples=$(jl_integrate_samples)",
)
println(
    "  Python config : python $py_python_version, integrate repeat=$(py_integrate_repeat), thread env=$py_thread_env",
)
println(
    "  StudentT config: Julia samples=$(jl_student_t_samples), Python repeat=$(py_student_t_repeat), warmup runs=$(py_student_t_warmup_runs)",
)
println()
println("  NOTE: C-kernel rows [C] (Lattice/DigitalNetB2/Halton gen_samples) use the")
println("  same qmctoolscl library on both sides and are NOT a language comparison.")
if summary_student_t.total > 0
    println("  NOTE: StudentT rows are also summarized separately because they can dominate")
    println("  the weighted cross-language time ratio.")
end
if artifact_skew_seconds > ARTIFACT_SKEW_WARNING_SECONDS
    println(
        "  NOTE: input artifacts are more than 10 minutes apart; rerun `make bench-compare-py` if that was not intentional.",
    )
end
println()

header = @sprintf("  %-48s  %11s  %11s  %7s", "benchmark", "Julia (ms)", "Python (ms)", "ratio")
println("="^length(header))
println(header)
println("-"^length(header))

for group in sort(unique(row.group for row in rows))
    println("\n── $group ──")
    for row in filter(r -> r.group == group, rows)
        if row.py_ms !== nothing
            ratio = row.py_ms / row.jl_ms
            tag = row.c_kernel ? " [C]" : "    "
            @printf(
                "  %s %-44s  %11.3f  %11.3f  %6.2fx\n",
                tag,
                row.name,
                row.jl_ms,
                row.py_ms,
                ratio
            )
        else  # missing/unavailable Python data
            @printf("  ??? %-44s  %11.3f  %11s  %7s\n", row.name, row.jl_ms, "n/a", "n/a")
        end
    end
end

println()
println("="^length(header))
println(
    "ratio > 1: local (Julia) faster than Python  |  ratio < 1: local (Julia) slower than Python",
)
@printf(
    "weighted time ratio = %.3f  (Python total %.3f ms vs Julia total %.3f ms across %d/%d matched rows)\n",
    summary.time_ratio,
    summary.py_ms,
    summary.jl_ms,
    summary.matched,
    summary.total
)
if summary_time_ci !== nothing
    @printf(
        "  within-run bootstrap 95%% interval = [%.3f, %.3f] from %d draws\n",
        summary_time_ci.lower,
        summary_time_ci.upper,
        summary_time_ci.draws
    )
end
if summary_student_t.total > 0
    @printf(
        "  weighted time ratio excluding StudentT = %.3f  (Python total %.3f ms vs Julia total %.3f ms across %d/%d matched rows)\n",
        summary_non_student_t.time_ratio,
        summary_non_student_t.py_ms,
        summary_non_student_t.jl_ms,
        summary_non_student_t.matched,
        summary_non_student_t.total
    )
    if summary_non_student_t_time_ci !== nothing
        @printf(
            "    within-run bootstrap 95%% interval = [%.3f, %.3f] from %d draws\n",
            summary_non_student_t_time_ci.lower,
            summary_non_student_t_time_ci.upper,
            summary_non_student_t_time_ci.draws
        )
    end
    @printf(
        "  weighted time ratio StudentT only = %.3f  (Python total %.3f ms vs Julia total %.3f ms across %d/%d matched rows)\n",
        summary_student_t.time_ratio,
        summary_student_t.py_ms,
        summary_student_t.jl_ms,
        summary_student_t.matched,
        summary_student_t.total
    )
    if summary_student_t_time_ci !== nothing
        @printf(
            "    within-run bootstrap 95%% interval = [%.3f, %.3f] from %d draws\n",
            summary_student_t_time_ci.lower,
            summary_student_t_time_ci.upper,
            summary_student_t_time_ci.draws
        )
    end
end
if summary.peak_rows > 0
    @printf(
        "weighted approximate tracemalloc ratio = %.3f  (Python peak total %.1f KiB vs Julia alloc total %.1f KiB across %d/%d rows)\n",
        summary.peak_ratio,
        summary.py_peak_kib,
        summary.jl_peak_kib,
        summary.peak_rows,
        summary.total
    )
else
    println(
        "weighted approximate tracemalloc ratio = n/a  (QMCPy results do not record Python memory metrics)",
    )
end
if summary.rss_rows > 0 && summary.rss_ratio !== nothing
    @printf(
        "weighted approximate RSS delta ratio = %.3f  (Python RSS Δ total %.1f KiB vs Julia RSS Δ total %.1f KiB across %d/%d rows)\n",
        summary.rss_ratio,
        summary.py_rss_delta_kib,
        summary.jl_rss_kib,
        summary.rss_rows,
        summary.total
    )
elseif summary.rss_rows > 0
    println(
        "weighted approximate RSS delta ratio = n/a  (Julia RSS Δ total is 0.0 KiB across matched rows, so the weighted ratio is undefined)",
    )
else
    println(
        "weighted approximate RSS delta ratio = n/a  (missing Julia or QMCPy RSS delta sidecar data)",
    )
end
println("grouped weighted time ratios:")
for row in group_summaries
    @printf(
        "  %-10s %.3f  %s  (%d/%d rows)\n",
        row.group,
        row.summary.time_ratio,
        format_ci(row.time_ci),
        row.summary.matched,
        row.summary.total
    )
end

# ── Accuracy (integrate): Julia vs Python solution values ───────────────────────
if isempty(accuracy_rows)
    println()
    println(
        "accuracy (integrate): no solution data " *
        "(need Julia `$(jl_label)_solutions.json` + QMCPy solutions in $(basename(py_file)))",
    )
else
    println()
    println("="^length(header))
    println("Accuracy (integrate): |Julia − Python| vs 2 × tolerance")
    println("-"^length(header))
    for r in accuracy_rows
        if r.check === nothing
            @printf("  ???  %-40s  Julia=%- 12.6g  Python=n/a\n", r.name, r.jl_sol)
        else
            c = r.check
            mark = c.flagged ? "❌ DIFF" : "✅ ok  "
            @printf(
                "  %s %-40s  Julia=%- 12.6g  Python=%- 12.6g  |Δ|=%.3g  allowed(2·%s)=%.3g\n",
                mark,
                r.name,
                r.jl_sol,
                r.py_sol,
                c.diff,
                c.mode,
                c.allowed
            )
        end
    end
    @printf("%d of %d integrate case(s) exceed 2×tolerance\n", n_flagged, checked_accuracy_rows)
end

if isempty(oracle_rows)
    println()
    println(
        "deterministic oracles: no transform/evaluate sidecar data " *
        "(need Julia `$(jl_label)_oracles.json` + QMCPy `oracles` in $(basename(py_file)))",
    )
else
    println()
    println("="^length(header))
    println("Deterministic oracles (transform/evaluate): elementwise agreement")
    println("-"^length(header))
    for r in oracle_rows
        if r.check === nothing
            @printf("  ???  %-12s  %-36s  Python=n/a\n", r.group, r.name)
        else
            c = r.check
            mark = c.flagged ? "❌ DIFF" : "✅ ok  "
            @printf(
                "  %s %-12s  %-36s  max|Δ|=%.3g  tol=(%.1e, %.1e)  failed=%d/%d\n",
                mark,
                r.group,
                r.name,
                c.max_abs_diff,
                c.atol,
                c.rtol,
                c.n_failed,
                c.n_compared
            )
        end
    end
    @printf(
        "%d of %d deterministic oracle case(s) exceed elementwise tolerance\n",
        n_flagged_oracle_rows,
        checked_oracle_rows
    )
end

# ── Save machine-readable summary ─────────────────────────────────────────────
summary_outfile = compare_py_summary_outfile(out_label)
markdown_report_filename = basename(compare_py_outfile(out_label))
open(summary_outfile, "w") do io
    JSON3.pretty(
        io,
        Dict(
            "report_generated_at" => report_generated_at,
            "jl_label" => jl_label,
            "py_label" => py_label,
            "qmcpy_version" => py_version,
            "jl_generated_at" => jl_generated_at,
            "py_generated_at" => py_generated_at,
            "jl_file_mtime" => jl_file_mtime,
            "py_file_mtime" => py_file_mtime,
            "jl_artifact_filename" => basename(jl_file),
            "jl_memory_artifact_filename" => basename(jl_mem_file),
            "jl_solution_artifact_filename" => basename(jl_sol_file),
            "jl_oracle_artifact_filename" => basename(jl_oracle_file),
            "py_artifact_filename" => basename(py_file),
            "summary_filename" => basename(summary_outfile),
            "markdown_report_filename" => markdown_report_filename,
            "artifact_skew_seconds" => artifact_skew_seconds,
            "matched_rows" => summary.matched,
            "total_rows" => summary.total,
            "time_ratio" => finite_or_nothing(summary.time_ratio),
            "time_ratio_excluding_student_t" =>
                finite_or_nothing(summary_non_student_t.time_ratio),
            "time_ratio_student_t" => finite_or_nothing(summary_student_t.time_ratio),
            "time_ratio_bootstrap_95" => ci_to_dict(summary_time_ci),
            "time_ratio_excluding_student_t_bootstrap_95" =>
                ci_to_dict(summary_non_student_t_time_ci),
            "time_ratio_student_t_bootstrap_95" => ci_to_dict(summary_student_t_time_ci),
            "peak_rows" => summary.peak_rows,
            "peak_ratio" => finite_or_nothing(summary.peak_ratio),
            "rss_rows" => summary.rss_rows,
            "rss_ratio" => finite_or_nothing(summary.rss_ratio),
            "group_summaries" => Dict(
                row.group => Dict(
                    "description" => row.description,
                    "matched_rows" => row.summary.matched,
                    "total_rows" => row.summary.total,
                    "time_ratio" => finite_or_nothing(row.summary.time_ratio),
                    "time_ratio_bootstrap_95" => ci_to_dict(row.time_ci),
                    "julia_total_ms" => row.summary.jl_ms,
                    "python_total_ms" => row.summary.py_ms,
                    "peak_rows" => row.summary.peak_rows,
                    "peak_ratio" => finite_or_nothing(row.summary.peak_ratio),
                    "rss_rows" => row.summary.rss_rows,
                    "rss_ratio" => finite_or_nothing(row.summary.rss_ratio),
                ) for row in group_summaries
            ),
            "checked_oracle_rows" => checked_oracle_rows,
            "n_flagged_oracle_rows" => n_flagged_oracle_rows,
            "checked_accuracy_rows" => checked_accuracy_rows,
            "n_flagged_accuracy_rows" => n_flagged,
            "strict_accuracy_requested" => strict_accuracy,
        ),
    )
end

# ── Save markdown file ──────────────────────────────────────────────────────────
outfile = compare_py_outfile(out_label)
open(outfile, "w") do io
    println(io, "# Benchmark: Julia (local) vs QMCPy (Python)\n")
    println(io, "| | Julia (local) | Python (QMCPy) |")
    println(io, "|---|---|---|")
    println(io, "| Julia label | `$(jl_label)` | — |")
    println(io, "| Python label | — | `$(py_label)` |")
    println(io, "| Julia artifact mtime | `$(jl_file_mtime)` | — |")
    println(io, "| Python artifact mtime | — | `$(py_file_mtime)` |")
    println(io, "| Julia generated at | `$(jl_generated_at)` | — |")
    println(io, "| Python generated at | — | `$(py_generated_at)` |")
    println(io, "| Julia BLAS threads | `$(jl_blas_threads)` | — |")
    println(io, "| Python version | — | `$(py_python_version)` |")
    println(io, "| qmcpy version | — | $(py_version) |")
    println(
        io,
        "| integrate timing | `samples=$(jl_integrate_samples)` | `repeat=$(py_integrate_repeat)` |",
    )
    println(
        io,
        "| StudentT timing | `samples=$(jl_student_t_samples)` | `repeat=$(py_student_t_repeat)`, `warmup=$(py_student_t_warmup_runs)` |",
    )
    println(io, "| thread env | — | `$(py_thread_env)` |")
    println(io, "")
    println(io, "**`ratio = Python time ÷ Julia time`**  ")
    println(
        io,
        "ratio `< 1` → local (Julia) is **slower** ❌  |  ratio `> 1` → local (Julia) is **faster** ✅  ",
    )
    println(io, "")
    println(
        io,
        "> ⚠️ C-kernel rows `[C]` (Lattice/DigitalNetB2/Halton `gen_samples`) call the same",
    )
    println(
        io,
        "> `qmctoolscl` library on both sides and are **not** a Julia vs Python comparison.",
    )
    if summary_student_t.total > 0
        println(
            io,
            "> `StudentT` rows are also summarized separately below because they can dominate",
        )
        println(io, "> the weighted cross-language time ratio.")
    end
    println(
        io,
        "> Julia `alloc KiB` is allocated bytes from BenchmarkTools. Julia `RSS Δ` and Python",
    )
    println(
        io,
        "> `RSS Δ` are coarse retained-memory signals from one warmed call. Python `tracemalloc`",
    )
    println(
        io,
        "> peak is Python-managed temporary memory. These are related but not interchangeable.",
    )
    println(
        io,
        "> The 95% timing intervals below come from bootstrap resampling of the repeated timing samples already collected inside this run. They quantify within-run timing-sample variability, not cross-machine or cross-workflow reproducibility.",
    )
    println(
        io,
        "> Report generated at `$(report_generated_at)`. Input artifact skew: `$(format_seconds(artifact_skew_seconds))`.",
    )
    if artifact_skew_seconds > ARTIFACT_SKEW_WARNING_SECONDS
        println(
            io,
            "> ℹ️ The Julia and QMCPy input artifacts are more than 10 minutes apart. If that was not intentional, rerun `make bench-compare-py` to refresh both sides together.",
        )
    end
    println(io, "")
    println(io, "## Aggregate Summary\n")
    println(io, "| metric | scope | ratio | Julia total | Python total | rows |")
    println(io, "|:-------|:------|------:|------------:|-------------:|-----:|")
    println(
        io,
        "| matched benchmarks | all matched rows | $(summary.matched)/$(summary.total) | — | — | $(summary.matched) |",
    )
    @printf(
        io,
        "| weighted time ratio | all matched rows | %.3f | %.3f ms | %.3f ms | %d |\n",
        summary.time_ratio,
        summary.jl_ms,
        summary.py_ms,
        summary.matched
    )
    if summary_student_t.total > 0
        @printf(
            io,
            "| weighted time ratio | excluding StudentT | %.3f | %.3f ms | %.3f ms | %d |\n",
            summary_non_student_t.time_ratio,
            summary_non_student_t.jl_ms,
            summary_non_student_t.py_ms,
            summary_non_student_t.matched
        )
        @printf(
            io,
            "| weighted time ratio | StudentT only | %.3f | %.3f ms | %.3f ms | %d |\n",
            summary_student_t.time_ratio,
            summary_student_t.jl_ms,
            summary_student_t.py_ms,
            summary_student_t.matched
        )
    end
    if summary_time_ci !== nothing
        println(
            io,
            "| weighted time ratio 95% bootstrap CI | all matched rows | `$(format_ci(summary_time_ci))` | — | — | $(summary_time_ci.draws) |",
        )
    else
        println(
            io,
            "| weighted time ratio 95% bootstrap CI | all matched rows | n/a | — | — | 0 |",
        )
    end
    if summary_student_t.total > 0
        if summary_non_student_t_time_ci !== nothing
            println(
                io,
                "| weighted time ratio 95% bootstrap CI | excluding StudentT | `$(format_ci(summary_non_student_t_time_ci))` | — | — | $(summary_non_student_t_time_ci.draws) |",
            )
        else
            println(
                io,
                "| weighted time ratio 95% bootstrap CI | excluding StudentT | n/a | — | — | 0 |",
            )
        end
        if summary_student_t_time_ci !== nothing
            println(
                io,
                "| weighted time ratio 95% bootstrap CI | StudentT only | `$(format_ci(summary_student_t_time_ci))` | — | — | $(summary_student_t_time_ci.draws) |",
            )
        else
            println(
                io,
                "| weighted time ratio 95% bootstrap CI | StudentT only | n/a | — | — | 0 |",
            )
        end
    end
    if summary.peak_rows > 0
        @printf(
            io,
            "| weighted approximate tracemalloc ratio | all matched rows | %.3f | %.1f KiB | %.1f KiB | %d |\n",
            summary.peak_ratio,
            summary.jl_peak_kib,
            summary.py_peak_kib,
            summary.peak_rows
        )
    else
        println(
            io,
            "| weighted approximate tracemalloc ratio | all matched rows | n/a | n/a | n/a | 0 |",
        )
    end
    if summary.rss_rows > 0 && summary.rss_ratio !== nothing
        @printf(
            io,
            "| weighted approximate RSS delta ratio | all matched rows | %.3f | %.1f KiB | %.1f KiB | %d |\n\n",
            summary.rss_ratio,
            summary.jl_rss_kib,
            summary.py_rss_delta_kib,
            summary.rss_rows
        )
    elseif summary.rss_rows > 0
        @printf(
            io,
            "| weighted approximate RSS delta ratio | all matched rows | n/a | %.1f KiB | %.1f KiB | %d |\n\n",
            summary.jl_rss_kib,
            summary.py_rss_delta_kib,
            summary.rss_rows
        )
    else
        println(
            io,
            "| weighted approximate RSS delta ratio | all matched rows | n/a | n/a | n/a | 0 |\n",
        )
    end
    println(io, "")
    println(io, "## Grouped Timing Summary\n")
    println(
        io,
        "Generator, transform, integrand evaluation, and end-to-end adaptive integration are summarized separately below. The `integrate` group is mixed end-to-end cost, not isolated stopping-criterion overhead.\n",
    )
    println(
        io,
        "| group | interpretation | weighted time ratio | 95% bootstrap CI | Julia total | Python total | rows |",
    )
    println(
        io,
        "|:------|:---------------|--------------------:|:------------------|------------:|-------------:|-----:|",
    )
    for row in group_summaries
        @printf(
            io,
            "| `%s` | %s | %.3f | `%s` | %.3f ms | %.3f ms | %d |\n",
            row.group,
            row.description,
            row.summary.time_ratio,
            format_ci(row.time_ci),
            row.summary.jl_ms,
            row.summary.py_ms,
            row.summary.matched
        )
    end
    println(io, "")
    println(io, "## Detailed Results\n")
    println(
        io,
        "| benchmark | time ratio | verdict | Julia (ms) | Python (ms) | Julia alloc (KiB) | Julia RSS Δ (KiB) | Python peak (KiB) | Python RSS Δ (KiB) |",
    )
    println(
        io,
        "|:----------|-----------:|:-------:|----------:|------------:|-------------------:|------------------:|------------------:|-------------------:|",
    )
    for row in rows
        c_note = row.c_kernel ? " `[C]`" : ""
        if row.py_ms !== nothing
            ratio = row.py_ms / row.jl_ms
            verdict = ratio < 0.95 ? "❌" : ratio > 1.05 ? "✅" : "–"
            jl_rss_txt =
                row.jl_rss_delta_kib === nothing ? "n/a" :
                @sprintf("%.1f", row.jl_rss_delta_kib)
            peak_txt = row.py_peak_kib === nothing ? "n/a" : @sprintf("%.1f", row.py_peak_kib)
            rss_txt =
                row.py_rss_delta_kib === nothing ? "n/a" :
                @sprintf("%.1f", row.py_rss_delta_kib)
            @printf(
                io,
                "| `[\"%s\", \"%s\"]`%s | %.3f | %s | %.3f | %.3f | %.1f | %s | %s | %s |\n",
                row.group,
                row.name,
                c_note,
                ratio,
                verdict,
                row.jl_ms,
                row.py_ms,
                row.jl_kib,
                jl_rss_txt,
                peak_txt,
                rss_txt
            )
        else
            jl_rss_txt =
                row.jl_rss_delta_kib === nothing ? "n/a" :
                @sprintf("%.1f", row.jl_rss_delta_kib)
            @printf(
                io,
                "| `[\"%s\", \"%s\"]` | n/a | — | %.3f | n/a | %.1f | %s | n/a | n/a |\n",
                row.group,
                row.name,
                row.jl_ms,
                row.jl_kib,
                jl_rss_txt
            )
        end
    end

    # ── Accuracy (integrate) ────────────────────────────────────────────────
    println(io, "")
    println(io, "## Accuracy (integrate): solution agreement\n")
    println(io, "Each criterion converges to within `tol` of the true value, so the Julia and")
    println(
        io,
        "Python solutions should agree within **`2·tol`** (effective `tol = max(abs_tol,",
    )
    println(
        io,
        "rel_tol·|value|)`). Rows whose `|Julia − Python|` exceeds that bound are flagged ❌.\n",
    )
    if isempty(accuracy_rows)
        println(io, "_No solution data found. Re-run `make bench` (writes the Julia ")
        println(
            io,
            "`$(jl_label)_solutions.json` sidecar) and a QMCPy harness recent enough to ",
        )
        println(io, "record `solution`/`abs_tol`/`rel_tol`._")
    else
        @printf(
            io,
            "**%d of %d** matched integrate case(s) exceed 2×tolerance.\n\n",
            n_flagged,
            checked_accuracy_rows
        )
        println(
            io,
            "| integrate case | Julia | Python | abs Δ | rel Δ | tol mode | allowed 2·tol | verdict |",
        )
        println(
            io,
            "|:---------------|------:|-------:|------:|------:|:--------:|--------------:|:-------:|",
        )
        for r in accuracy_rows
            if r.check === nothing
                @printf(
                    io,
                    "| `%s` | %.6g | n/a | n/a | n/a | n/a | n/a | — |\n",
                    r.name,
                    r.jl_sol
                )
            else
                c = r.check
                verdict = c.flagged ? "❌" : "✅"
                reld = isnan(c.rel_diff) ? "n/a" : @sprintf("%.2e", c.rel_diff)
                @printf(
                    io,
                    "| `%s` | %.6g | %.6g | %.3e | %s | %s | %.3e | %s |\n",
                    r.name,
                    r.jl_sol,
                    r.py_sol,
                    c.diff,
                    reld,
                    c.mode,
                    c.allowed,
                    verdict
                )
            end
        end
    end

    println(io, "")
    println(io, "## Deterministic oracles (transform/evaluate)\n")
    println(
        io,
        "These cases compare small fixed transform/evaluate outputs against QMCPy on the exact same deterministic inputs. Rows are flagged ❌ if any element exceeds `atol + rtol * |reference|`.\n",
    )
    if isempty(oracle_rows)
        println(
            io,
            "_No oracle sidecar data found. Re-run `make bench` (writes the Julia `$(jl_label)_oracles.json` sidecar) and a QMCPy harness recent enough to record top-level `oracles`._",
        )
    else
        @printf(
            io,
            "**%d of %d** deterministic oracle case(s) exceed elementwise tolerance.\n\n",
            n_flagged_oracle_rows,
            checked_oracle_rows
        )
        println(
            io,
            "| group | case | max abs Δ | max rel Δ | atol | rtol | failed elems | verdict |",
        )
        println(
            io,
            "|:------|:-----|----------:|----------:|-----:|-----:|-------------:|:-------:|",
        )
        for r in oracle_rows
            if r.check === nothing
                println(io, "| `$(r.group)` | `$(r.name)` | n/a | n/a | n/a | n/a | n/a | — |")
            else
                c = r.check
                rel_txt = isfinite(c.max_rel_diff) ? @sprintf("%.3e", c.max_rel_diff) : "inf"
                failed_txt =
                    c.length_match && c.shape_match ? "$(c.n_failed)/$(c.n_compared)" :
                    "shape/len mismatch"
                verdict = c.flagged ? "❌" : "✅"
                @printf(
                    io,
                    "| `%s` | `%s` | %.3e | %s | %.1e | %.1e | %s | %s |\n",
                    r.group,
                    r.name,
                    c.max_abs_diff,
                    rel_txt,
                    c.atol,
                    c.rtol,
                    failed_txt,
                    verdict
                )
            end
        end
    end
end
println("\nWrote benchmark/results/$(basename(outfile))")
println("  ratio = Python ÷ Julia  →  < 1: local slower  |  > 1: local faster")
if strict_accuracy
    if checked_accuracy_rows == 0
        error(
            "Strict QMCPy accuracy check requested via $(STRICT_ACCURACY_ENV)=1, " *
            "but no comparable integrate solution rows were found.",
        )
    elseif n_flagged > 0
        error(
            "Strict QMCPy accuracy check failed: $(n_flagged) of $(checked_accuracy_rows) " *
            "integrate case(s) exceeded 2×tolerance.",
        )
    elseif checked_oracle_rows == 0
        error(
            "Strict QMCPy accuracy check requested via $(STRICT_ACCURACY_ENV)=1, " *
            "but no comparable deterministic oracle rows were found.",
        )
    elseif n_flagged_oracle_rows > 0
        error(
            "Strict QMCPy accuracy check failed: $(n_flagged_oracle_rows) of " *
            "$(checked_oracle_rows) deterministic oracle case(s) exceeded " *
            "elementwise tolerance.",
        )
    end
end
