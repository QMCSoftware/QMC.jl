"""
    IterationLog

Simple iteration-history tracker for stopping criteria. Stores per-iteration
snapshots (n, solution estimate, error bound, elapsed time, etc.) and can
print a formatted table or return a vector-like view of the recorded rows.

# Usage inside a stopping criterion
```text
log = IterationLog()

# Inside the doubling loop:
push!(log; n=n_total, solution=mu_hat, error_bound=err, elapsed=t)

# After integration:
data[:iteration_log] = log
```

# User-facing
```jldoctest
julia> using QMC

julia> log = IterationLog()
IterationLog (empty)

julia> push!(log; n=128, solution=1.25, error_bound=0.1, tol=0.2, elapsed=0.5);

julia> push!(log; n=256, solution=1.2, error_bound=0.05, tol=0.2, elapsed=0.8);

julia> length(log)
2

julia> iterations(log)
iter    n  solution  err_bound        tol  time(s)
   1  128      1.25  1.000e-01  2.000e-01    0.500
   2  256       1.2  5.000e-02  2.000e-01    0.800
```
"""
mutable struct IterationLog
    records::Vector{
        NamedTuple{
            (:iter, :n, :solution, :error_bound, :tol, :elapsed),
            Tuple{Int, Int, Float64, Float64, Float64, Float64},
        },
    }
    count::Int
end

IterationLog() = IterationLog([], 0)

struct IterationRows{T} <: AbstractVector{T}
    records::Vector{T}
end

Base.size(rows::IterationRows) = (length(rows.records),)
Base.length(rows::IterationRows) = length(rows.records)
Base.isempty(rows::IterationRows) = isempty(rows.records)
Base.IndexStyle(::Type{<:IterationRows}) = IndexLinear()
Base.getindex(rows::IterationRows, i::Int) = rows.records[i]
Base.iterate(rows::IterationRows, state...) = iterate(rows.records, state...)
Base.eltype(::Type{IterationRows{T}}) where {T} = T
Base.parent(rows::IterationRows) = rows.records

function Base.push!(
    log::IterationLog;
    n::Int,
    solution::Float64,
    error_bound::Float64,
    tol::Float64=NaN,
    elapsed::Float64=NaN,
)
    log.count += 1
    row = (
        iter=log.count,
        n=n,
        solution=solution,
        error_bound=error_bound,
        tol=tol,
        elapsed=elapsed,
    )
    push!(log.records, row)
    return log
end

"""
    iterations(log::IterationLog)

Return all iteration records as a vector-like collection of `NamedTuple` rows.
"""
iterations(log::IterationLog) = IterationRows(log.records)

Base.length(log::IterationLog) = length(log.records)
Base.isempty(log::IterationLog) = isempty(log.records)

const _ITERATION_LOG_COLUMNS = (
    (:iter, "iter"),
    (:n, "n"),
    (:solution, "solution"),
    (:error_bound, "err_bound"),
    (:tol, "tol"),
    (:elapsed, "time(s)"),
)

_iteration_is_right_aligned(::Symbol) = true

function _format_iteration_entry(key::Symbol, value)
    if key === :iter || key === :n
        return string(value)
    elseif key === :solution
        return @sprintf("%.8g", value)
    elseif key === :error_bound || key === :tol
        return isnan(value) ? "-" : @sprintf("%.3e", value)
    elseif key === :elapsed
        if isnan(value)
            return "-"
        elseif abs(value) < 1e-3 || abs(value) >= 1e3
            return @sprintf("%.3e", value)
        else
            return @sprintf("%.3f", value)
        end
    end
    return string(value)
end

function _iteration_row_strings(row)
    return ntuple(
        i -> _format_iteration_entry(
            _ITERATION_LOG_COLUMNS[i][1],
            getfield(row, _ITERATION_LOG_COLUMNS[i][1]),
        ),
        length(_ITERATION_LOG_COLUMNS),
    )
end

function _iteration_column_widths(data_rows)
    return ntuple(
        i -> maximum(length, (_ITERATION_LOG_COLUMNS[i][2], (row[i] for row in data_rows)...)),
        length(_ITERATION_LOG_COLUMNS),
    )
end

function _print_iteration_table_plain(
    io::IO,
    rows::IterationRows;
    title::Union{Nothing, String}=nothing,
)
    if title !== nothing
        print(io, title)
        isempty(rows) || print(io, '\n')
    end
    isempty(rows) && return
    data_rows = map(_iteration_row_strings, rows.records)
    widths = _iteration_column_widths(data_rows)
    headers = ntuple(
        i -> lpad(_ITERATION_LOG_COLUMNS[i][2], widths[i]),
        length(_ITERATION_LOG_COLUMNS),
    )
    print(io, join(headers, "  "))
    for row in data_rows
        print(io, '\n')
        cells = ntuple(i -> lpad(row[i], widths[i]), length(_ITERATION_LOG_COLUMNS))
        print(io, join(cells, "  "))
    end
end

function _print_iteration_table_html(
    io::IO,
    rows::IterationRows;
    caption::Union{Nothing, String}=nothing,
)
    print(io, "<table>")
    if caption !== nothing
        print(io, "<caption>", caption, "</caption>")
    end
    print(io, "<thead><tr>")
    for (_, header) in _ITERATION_LOG_COLUMNS
        print(io, "<th>", header, "</th>")
    end
    print(io, "</tr></thead><tbody>")
    for row in rows.records
        print(io, "<tr>")
        for (key, _) in _ITERATION_LOG_COLUMNS
            print(
                io,
                "<td style=\"text-align:right\">",
                _format_iteration_entry(key, getfield(row, key)),
                "</td>",
            )
        end
        print(io, "</tr>")
    end
    print(io, "</tbody></table>")
end

function Base.show(io::IO, rows::IterationRows)
    if isempty(rows)
        print(io, "IterationRows (empty)")
        return
    end
    _print_iteration_table_plain(io, rows)
end

Base.show(io::IO, ::MIME"text/plain", rows::IterationRows) = show(io, rows)

function Base.show(io::IO, ::MIME"text/html", rows::IterationRows)
    if isempty(rows)
        print(io, "<p>IterationRows (empty)</p>")
        return
    end
    _print_iteration_table_html(io, rows)
end

function Base.show(io::IO, log::IterationLog)
    if isempty(log.records)
        print(io, "IterationLog (empty)")
        return
    end
    _print_iteration_table_plain(
        io,
        IterationRows(log.records);
        title="IterationLog ($(length(log.records)) iterations)",
    )
end

Base.show(io::IO, ::MIME"text/plain", log::IterationLog) = show(io, log)

function Base.show(io::IO, ::MIME"text/html", log::IterationLog)
    caption =
        isempty(log.records) ? "IterationLog (empty)" :
        "IterationLog ($(length(log.records)) iterations)"
    _print_iteration_table_html(io, IterationRows(log.records); caption=caption)
end

"""
    DisplayTable

Display object returned by [`display_table`](@ref). It renders as an aligned
plain-text table in terminals and as an HTML table in notebook frontends.
"""
struct DisplayTable{R, C, H, F}
    rows::R
    columns::C
    headers::H
    formatters::F
    caption::Union{Nothing, String}
end

"""
    display_table(rows; columns=nothing, headers=nothing, formatters=NamedTuple(), caption=nothing)

Create a compact table with aligned terminal output and an HTML representation for notebooks.
Each row must be a `NamedTuple` with the same fields.

`columns` controls field order, `headers` supplies display names, and `formatters`
is a `NamedTuple` mapping fields to single-argument formatting functions. Numeric
columns are right-aligned and other columns are left-aligned.

# Examples
```jldoctest
julia> using QMC, Printf

julia> rows = [(n=64, error=0.012345), (n=128, error=0.001234)];

julia> display_table(rows; headers=["N", "error"], formatters=(error=x -> @sprintf("%.3e", x),))
  N      error
 64  1.235e-02
128  1.234e-03
```
"""
function display_table(
    rows;
    columns=nothing,
    headers=nothing,
    formatters=NamedTuple(),
    caption=nothing,
)
    collected = collect(rows)
    if isempty(collected)
        columns === nothing &&
            throw(ArgumentError("columns must be provided when rows is empty"))
        selected_columns = Symbol.(collect(columns))
    else
        first_row = first(collected)
        first_row isa NamedTuple ||
            throw(ArgumentError("display_table rows must be NamedTuples"))
        selected_columns =
            columns === nothing ? collect(keys(first_row)) : Symbol.(collect(columns))
        expected = keys(first_row)
        all(row -> row isa NamedTuple && keys(row) == expected, collected) ||
            throw(ArgumentError("display_table rows must have identical fields"))
        all(column -> column in expected, selected_columns) ||
            throw(ArgumentError("display_table columns must name row fields"))
    end
    selected_headers =
        headers === nothing ? string.(selected_columns) : string.(collect(headers))
    length(selected_headers) == length(selected_columns) ||
        throw(ArgumentError("headers and columns must have the same length"))
    formatters isa NamedTuple || throw(ArgumentError("formatters must be a NamedTuple"))
    normalized_caption = caption === nothing ? nothing : string(caption)
    return DisplayTable(
        collected,
        selected_columns,
        selected_headers,
        formatters,
        normalized_caption,
    )
end

function _display_table_format(table::DisplayTable, column::Symbol, value)
    if hasproperty(table.formatters, column)
        return string(getproperty(table.formatters, column)(value))
    end
    return string(value)
end

function _display_table_rows(table::DisplayTable)
    return [
        [
            _display_table_format(table, column, getproperty(row, column)) for
            column in table.columns
        ] for row in table.rows
    ]
end

function _display_table_right_aligned(table::DisplayTable, index::Int)
    isempty(table.rows) && return false
    return all(row -> getproperty(row, table.columns[index]) isa Number, table.rows)
end

_display_table_pad(value, width, right) = right ? lpad(value, width) : rpad(value, width)

function Base.show(io::IO, table::DisplayTable)
    table.caption === nothing || print(io, table.caption, isempty(table.rows) ? "" : "\n")
    isempty(table.rows) && return
    data_rows = _display_table_rows(table)
    widths = [
        maximum(length, (table.headers[i], (row[i] for row in data_rows)...)) for
        i in eachindex(table.columns)
    ]
    align_right = [_display_table_right_aligned(table, i) for i in eachindex(table.columns)]
    headers = [
        _display_table_pad(table.headers[i], widths[i], align_right[i]) for
        i in eachindex(table.columns)
    ]
    print(io, join(headers, "  "))
    for row in data_rows
        print(io, '\n')
        cells = [
            _display_table_pad(row[i], widths[i], align_right[i]) for
            i in eachindex(table.columns)
        ]
        print(io, join(cells, "  "))
    end
end

Base.show(io::IO, ::MIME"text/plain", table::DisplayTable) = show(io, table)

function _display_table_escape(value)
    return replace(
        string(value),
        '&' => "&amp;",
        '<' => "&lt;",
        '>' => "&gt;",
        '"' => "&quot;",
        '\'' => "&#39;",
    )
end

function Base.show(io::IO, ::MIME"text/html", table::DisplayTable)
    print(io, "<table>")
    table.caption === nothing ||
        print(io, "<caption>", _display_table_escape(table.caption), "</caption>")
    print(io, "<thead><tr>")
    for header in table.headers
        print(io, "<th>", _display_table_escape(header), "</th>")
    end
    print(io, "</tr></thead><tbody>")
    formatted_rows = _display_table_rows(table)
    for (row, formatted) in zip(table.rows, formatted_rows)
        print(io, "<tr>")
        for i in eachindex(table.columns)
            alignment = getproperty(row, table.columns[i]) isa Number ? "right" : "left"
            print(
                io,
                "<td style=\"text-align:",
                alignment,
                "\">",
                _display_table_escape(formatted[i]),
                "</td>",
            )
        end
        print(io, "</tr>")
    end
    print(io, "</tbody></table>")
end

# ── Resume iteration log helpers ───────────────────────────────────────────────

function _build_iteration_display(loose_data, resume_data; full::Bool)
    has_loose  = haskey(loose_data,  :iteration_log) && !isempty(loose_data[:iteration_log])
    has_resume = haskey(resume_data, :iteration_log) && !isempty(resume_data[:iteration_log])

    Row = NamedTuple{(:stage, :iter, :n, :solution, :error_bound, :tol, :elapsed),
                     Tuple{String, Int, Int, Float64, Float64, Float64, Float64}}
    rows = Row[]

    offset = 0
    last_loose_row = nothing

    if has_loose
        loose_iters = collect(iterations(loose_data[:iteration_log]))
        if full
            for r in loose_iters
                push!(rows, Row(("ITER", r.iter, r.n, r.solution,
                                 r.error_bound, r.tol, r.elapsed)))
            end
        end
        last_loose_row = last(loose_iters)
        offset = last_loose_row.iter
    end

    if has_resume
        if last_loose_row !== nothing
            r = last_loose_row
            push!(rows, Row(("RESUME", r.iter, r.n, r.solution,
                             r.error_bound, r.tol, r.elapsed)))
        end
        for r in collect(iterations(resume_data[:iteration_log]))
            push!(rows, Row(("ITER", r.iter + offset, r.n, r.solution,
                             r.error_bound, r.tol, r.elapsed)))
        end
    end

    fmts = (
        solution    = x -> @sprintf("%.8g", x),
        error_bound = x -> isnan(x) ? "-" : @sprintf("%.3e", x),
        tol         = x -> isnan(x) ? "-" : @sprintf("%.3e", x),
        elapsed     = x -> isnan(x) ? "-" :
            (abs(x) < 1e-3 || abs(x) >= 1e3 ? @sprintf("%.3e", x) : @sprintf("%.3f", x)),
    )

    return display_table(
        rows;
        columns    = (:stage, :iter, :n, :solution, :error_bound, :tol, :elapsed),
        headers    = ["stage", "iter", "n", "solution", "err_bound", "tol", "time(s)"],
        formatters = fmts,
    )
end

"""
    resume_iteration_log(loose_data, resume_data)

Build an iteration table for a resumed integration. The last row of the loose run
appears as a `RESUME` checkpoint, followed by resumed iteration rows with iter
numbers continuing from the loose run's final count.

Accepts the data dictionaries returned by `integrate` (i.e. `result.data`).
Returns a `DisplayTable` that renders as aligned text in terminals and as an HTML
table in notebook frontends.
"""
resume_iteration_log(loose_data, resume_data) =
    _build_iteration_display(loose_data, resume_data; full=false)

"""
    combined_iteration_log(loose_data, resume_data)

Build an iteration table combining all stages of a resumed integration: loose `ITER`
rows, a `RESUME` checkpoint (the last loose row repeated), and resumed `ITER` rows
with iter numbers continuing from the loose run's final count.

Accepts the data dictionaries returned by `integrate` (i.e. `result.data`).
Returns a `DisplayTable` that renders as aligned text in terminals and as an HTML
table in notebook frontends.
"""
combined_iteration_log(loose_data, resume_data) =
    _build_iteration_display(loose_data, resume_data; full=true)
