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
multilevel criteria expose `rmse_tol` or `target_tol`. Throws if the criterion
has no field for a requested tolerance. Returns `sc`.

```julia
sc = CubQMCNetG(
    Keister(Gaussian(DigitalNetB2(3; randomize="LMS_DS", graycode=false, seed=7); covariance=0.5));
    abs_tol=0.05,
)
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
        rmse_tol >= 0 || throw(ArgumentError("rmse_tol must be >= 0"))
        if hasfield(typeof(sc), :rmse_tol)
            sc.rmse_tol = Float64(rmse_tol)
        elseif hasfield(typeof(sc), :target_tol)
            sc.target_tol = Float64(rmse_tol)
        else
            throw(ArgumentError("$(typeof(sc)) has no rmse_tol/target_tol field"))
        end
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
@inline _open_unit_interval(u::T) where {T <: AbstractFloat} = clamp(u, eps(T), one(T) - eps(T))
@inline _open_unit_interval(u::Real) = _open_unit_interval(Float64(u))

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

# ── Multi-output (vector-valued) integrand interface ──────────────────────────
# Foundation for driving vector-valued integrands to per-output tolerance,
# mirroring QMCPy 2.3's `d_indv` machinery. Scalar integrands need no changes:
# the defaults below describe a single scalar output (so `evaluate` keeps
# returning an `n`-vector) and every map is the identity. A vector-valued
# integrand whose `evaluate` returns an `n × s₁ × … × sₖ` array overrides
# `d_indv` to return `(s₁, …, sₖ)`; the stopping criteria can then loop over the
# individual outputs, apply `bound_fun`, and report `combine_fun` of the result.
# These are intentionally unexported (access as `QMC.d_indv`, etc.) while the
# interface stabilizes through the staged roll-out.

"""
    d_indv(f::AbstractIntegrand) -> Tuple

Shape of the individual (per-point) outputs of `f`: `evaluate(f, x)` returns an
array of shape `(n, d_indv(f)...)`. Defaults to `()` — a single scalar output, so
`evaluate` returns an `n`-vector. Mirrors QMCPy's `d_indv`.
"""
d_indv(::AbstractIntegrand) = ()

"""
    d_comb(f::AbstractIntegrand) -> Tuple

Shape of the combined solution produced by `combine_fun`. Defaults to `d_indv(f)`
(identity combine). Mirrors QMCPy's `d_comb`.
"""
d_comb(f::AbstractIntegrand) = d_indv(f)

"""
    combine_fun(f::AbstractIntegrand, solution_indv)

Reduce the individual-output solution(s) to the reported solution(s). Default is
the identity. Mirrors QMCPy's `combine_fun`.
"""
combine_fun(::AbstractIntegrand, solution_indv) = solution_indv

"""
    bound_fun(f::AbstractIntegrand, bound_low, bound_high) -> (low, high)

Map per-individual-output error bounds to bounds on the combined solution.
Default is the identity (returns `(bound_low, bound_high)`). Mirrors QMCPy's
`bound_fun`.
"""
bound_fun(::AbstractIntegrand, bound_low, bound_high) = (bound_low, bound_high)

"""
    dependency(f::AbstractIntegrand, comb_flags) -> indv_flags

Given which combined outputs still need work (`comb_flags`), return which
individual outputs must keep being computed. Default is the identity. Mirrors
QMCPy's `dependency`.
"""
dependency(::AbstractIntegrand, comb_flags) = comb_flags

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

"""
Result type returned by `integrate` for vector-valued (multi-output) stopping
criteria, the array analogue of [`QMCResult`](@ref).

# Fields
- `solution::Array{Float64}`: estimated solution per combined output, shaped
  `d_comb(integrand)`.
- `data::Dict{Symbol,Any}`: algorithm details such as `:n_total`, `:error_bound`
  (the worst-output half-width), `:solution_indv`, and the per-output combined
  bounds `:comb_bound_low` / `:comb_bound_high`.
"""
struct QMCVecResult
    solution::Array{Float64}
    data::Dict{Symbol, Any}
end

function Base.show(io::IO, r::QMCVecResult)
    print(io, "QMCVecResult(solution=", r.solution)
    if haskey(r.data, :n_total)
        @printf(io, ", n_total=%d", r.data[:n_total])
    end
    if haskey(r.data, :error_bound)
        @printf(io, ", error_bound=%.2e", r.data[:error_bound])
    end
    print(io, ")")
end
