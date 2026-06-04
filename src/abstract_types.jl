"""Abstract base for all discrete distributions (point generators)."""
abstract type AbstractDiscreteDistribution end

"""Abstract base for all true measures."""
abstract type AbstractTrueMeasure end

"""Abstract base for all integrands."""
abstract type AbstractIntegrand end

"""Abstract base for all stopping criteria."""
abstract type AbstractStoppingCriterion end

"""
    set_tolerance!(sc::AbstractStoppingCriterion; abs_tol=nothing, rel_tol=nothing,
                   rmse_tol=nothing) -> sc

Update the error tolerance(s) on a stopping criterion in place, mirroring
QMCPy's `set_tolerance`. Only the keyword(s) you pass are changed; the others are
left untouched. The single-level `Cub*` criteria expose `abs_tol`/`rel_tol`; the
multilevel criteria expose `rmse_tol`. Throws if the criterion has no field for a
requested tolerance. Returns `sc`.

```julia
sc = CubQMCNetG(Keister(Gaussian(DigitalNetB2(3); covariance=0.5)); abs_tol=0.05)
set_tolerance!(sc; abs_tol=0.01, rel_tol=0.0)
```
"""
function set_tolerance!(
    sc::AbstractStoppingCriterion;
    abs_tol=nothing,
    rel_tol=nothing,
    rmse_tol=nothing,
)
    if abs_tol !== nothing
        hasfield(typeof(sc), :abs_tol) ||
            throw(ArgumentError("$(typeof(sc)) has no abs_tol field"))
        abs_tol >= 0 || throw(ArgumentError("abs_tol must be >= 0"))
        sc.abs_tol = Float64(abs_tol)
    end
    if rel_tol !== nothing
        hasfield(typeof(sc), :rel_tol) ||
            throw(ArgumentError("$(typeof(sc)) has no rel_tol field"))
        rel_tol >= 0 || throw(ArgumentError("rel_tol must be >= 0"))
        sc.rel_tol = Float64(rel_tol)
    end
    if rmse_tol !== nothing
        hasfield(typeof(sc), :rmse_tol) ||
            throw(ArgumentError("$(typeof(sc)) has no rmse_tol field"))
        rmse_tol >= 0 || throw(ArgumentError("rmse_tol must be >= 0"))
        sc.rmse_tol = Float64(rmse_tol)
    end
    return sc
end

"""Abstract base for all kernels."""
abstract type AbstractKernel end

# Exact zeros appear in deterministic QMC sequences, but inverse-CDF transforms
# require probabilities in the open interval.
const _OPEN01_LOW = eps(Float64)
const _OPEN01_HIGH = 1.0 - eps(Float64)
@inline _open_unit_interval(u::Float64) = clamp(u, _OPEN01_LOW, _OPEN01_HIGH)

# Common interface functions
"""
    gen_samples(dd::AbstractDiscreteDistribution, n::Int; kwargs...)

Generate `n` samples from the discrete distribution `dd`.
Returns an `n x d` matrix where `d` is the dimension.
"""
function gen_samples end

"""
    integrate(sc::AbstractStoppingCriterion)

Run the integration algorithm defined by stopping criterion `sc`.
Returns a `QMCResult` containing the estimated integral and algorithm details.
"""
function integrate end

"""
    transform(tm::AbstractTrueMeasure, x::AbstractMatrix)

Transform uniform samples `x` according to true measure `tm`.
Returns a matrix of the same shape as `x` with transformed samples.
"""
function transform end

"""
    evaluate(f::AbstractIntegrand, x::AbstractMatrix)

Evaluate integrand `f` at sample points `x`.
Returns a vector of function values, one per row of `x`.
"""
function evaluate end

"""
Result type returned by `integrate`.

# Fields
- `solution::Float64`: the estimated integral value.
- `data::Dict{Symbol,Any}`: dictionary with algorithm details such as
  `:n_total`, `:error_bound`, `:time_elapsed`, etc.
"""
struct QMCResult
    solution::Float64
    data::Dict{Symbol, Any}
end

function Base.show(io::IO, r::QMCResult)
    @printf(io, "QMCResult(solution=%.6e", r.solution)
    if haskey(r.data, :n_total)
        @printf(io, ", n_total=%d", r.data[:n_total])
    elseif haskey(r.data, :n)
        @printf(io, ", n=%d", r.data[:n])
    end
    if haskey(r.data, :error_bound)
        @printf(io, ", error_bound=%.2e", r.data[:error_bound])
    end
    print(io, ")")
end
