"""Abstract base for all discrete distributions (point generators)."""
abstract type AbstractDiscreteDistribution end

"""Abstract base for all true measures."""
abstract type AbstractTrueMeasure end

"""Abstract base for all integrands."""
abstract type AbstractIntegrand end

"""Abstract base for all stopping criteria."""
abstract type AbstractStoppingCriterion end

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
