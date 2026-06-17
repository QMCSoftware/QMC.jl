"""
    IterationLog

Simple iteration-history tracker for stopping criteria. Stores per-iteration
snapshots (n, solution estimate, error bound, elapsed time, etc.) and can
print a formatted table or return a vector of NamedTuples.

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
2-element Vector{@NamedTuple{iter::Int64, n::Int64, solution::Float64, error_bound::Float64, tol::Float64, elapsed::Float64}}:
 (iter = 1, n = 128, solution = 1.25, error_bound = 0.1, tol = 0.2, elapsed = 0.5)
 (iter = 2, n = 256, solution = 1.2, error_bound = 0.05, tol = 0.2, elapsed = 0.8)
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

Return all iteration records as a `Vector{NamedTuple}`.
"""
iterations(log::IterationLog) = log.records

Base.length(log::IterationLog) = length(log.records)
Base.isempty(log::IterationLog) = isempty(log.records)

function Base.show(io::IO, log::IterationLog)
    if isempty(log.records)
        print(io, "IterationLog (empty)")
        return
    end
    # Header
    @printf(io, "IterationLog (%d iterations)\n", length(log.records))
    @printf(
        io,
        " %5s  %10s  %14s  %10s  %10s  %8s\n",
        "iter",
        "n",
        "solution",
        "err_bound",
        "tol",
        "time(s)"
    )
    @printf(
        io,
        " %5s  %10s  %14s  %10s  %10s  %8s\n",
        "-----",
        "----------",
        "--------------",
        "----------",
        "----------",
        "--------"
    )
    for r in log.records
        tol_str = isnan(r.tol) ? "     —" : @sprintf("%.4e", r.tol)
        t_str = isnan(r.elapsed) ? "    —" : @sprintf("%.3f", r.elapsed)
        @printf(
            io,
            " %5d  %10d  %14.8e  %10.4e  %10s  %8s\n",
            r.iter,
            r.n,
            r.solution,
            r.error_bound,
            tol_str,
            t_str
        )
    end
end
