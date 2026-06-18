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

```jldoctest
julia> using QMC

julia> dd = IIDStdUniform(3; seed=42);

julia> f = Keister(Gaussian(dd; covariance=0.5));

julia> sc = CubMCCLT(f; abs_tol=0.05);

julia> set_tolerance!(sc; abs_tol=0.2, rel_tol=0.01) === sc
true

julia> sc.abs_tol
0.2

julia> sc.rel_tol
0.01
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
    dimension(obj)

Return the stochastic dimension associated with a QMC component.

- For a discrete distribution, this is the point dimension.
- For a true measure, this is the transformed-domain dimension.
- For an integrand, this is the input dimension expected by `evaluate`.

Concrete subtypes may either store a `dimension` field or overload this method.
The latter enables alternative internal layouts while preserving framework
interoperability.
"""
function dimension end

dimension(dd::AbstractDiscreteDistribution) =
    hasfield(typeof(dd), :dimension) ? getfield(dd, :dimension) :
    throw(
        ArgumentError(
            "dimension(::$(typeof(dd))) is not defined; add a `dimension` field or overload `QMC.dimension`",
        ),
    )

"""
    discrete_distribution(obj)

Return the underlying point generator associated with `obj`.

- For a discrete distribution, returns `obj`.
- For a true measure, returns the discrete distribution that drives it.
- For an integrand, returns the discrete distribution of its true measure.

Concrete subtypes may either store a `dd` field or overload this method.
"""
function discrete_distribution end

discrete_distribution(dd::AbstractDiscreteDistribution) = dd

discrete_distribution(tm::AbstractTrueMeasure) =
    hasfield(typeof(tm), :dd) ? getfield(tm, :dd) :
    throw(
        ArgumentError(
            "discrete_distribution(::$(typeof(tm))) is not defined; add a `dd` field or overload `QMC.discrete_distribution`",
        ),
    )

discrete_distribution(f::AbstractIntegrand) = discrete_distribution(true_measure(f))

"""
    true_measure(f::AbstractIntegrand)

Return the true measure associated with an integrand. Concrete integrands may
either store a `true_measure` field or overload this method.
"""
function true_measure end

true_measure(f::AbstractIntegrand) =
    hasfield(typeof(f), :true_measure) ? getfield(f, :true_measure) :
    throw(
        ArgumentError(
            "true_measure(::$(typeof(f))) is not defined; add a `true_measure` field or overload `QMC.true_measure`",
        ),
    )

dimension(tm::AbstractTrueMeasure) =
    hasfield(typeof(tm), :dimension) ? getfield(tm, :dimension) :
    dimension(discrete_distribution(tm))

dimension(f::AbstractIntegrand) =
    hasfield(typeof(f), :dimension) ? getfield(f, :dimension) : dimension(true_measure(f))

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
    transform(tm::AbstractTrueMeasure, x)

Transform uniform samples `x` according to true measure `tm`.

- For matrix input `x::AbstractMatrix`, returns a transformed matrix.
- For replicated input `x::AbstractArray{<:Real,3}` with shape `(R, n, d)`,
  fixed-shape transforms return a dense `(R, n, d_out)` array obtained by
  transforming each replication independently.
"""
function transform end

function transform(tm::AbstractTrueMeasure, x::AbstractArray{T, 3}) where {T <: Real}
    R, n, d = size(x)
    y_flat = transform(tm, reshape(x, R * n, d))
    y_flat isa AbstractMatrix || throw(
        ArgumentError(
            "Replicated transform for $(typeof(tm)) requires the matrix method to return " *
            "an AbstractMatrix, got $(typeof(y_flat))",
        ),
    )
    size(y_flat, 1) == R * n || throw(
        ArgumentError(
            "Replicated transform for $(typeof(tm)) produced $(size(y_flat, 1)) rows " *
            "from $R replications of $n points. This true measure has variable-length " *
            "output per replication and needs a custom replicated transform method.",
        ),
    )
    return reshape(y_flat, R, n, size(y_flat, 2))
end

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
    evaluate(f::AbstractIntegrand, x, compute_flags) -> y

Flag-aware evaluation used by multi-output stopping criteria: `compute_flags`
marks which individual outputs still need to be computed (converged outputs are
frozen). The default ignores the flags and computes every output — the criterion
simply discards the frozen columns — so existing two-argument `evaluate` methods
keep working unchanged. Integrands whose outputs are expensive may override this
three-argument form to skip the frozen outputs. Mirrors QMCPy threading
`compute_flags` into the integrand.
"""
evaluate(f::AbstractIntegrand, x::AbstractMatrix, compute_flags) = evaluate(f, x)

"""
    _combined_bounds_stats(abs_tol, rel_tol, comb_low, comb_high)

Internal helper shared by vector-valued stopping criteria. Given lower and upper
bounds on the combined outputs, compute the QMCPy-style reported solution,
per-output convergence flags, the worst half-width, and the largest effective
tolerance under the "EITHER" rule `max(abs_tol, rel_tol*abs(s))`.
"""
function _combined_bounds_stats(abs_tol::Float64, rel_tol::Float64, comb_low, comb_high)
    low = vec(collect(Float64, comb_low))
    high = vec(collect(Float64, comb_high))
    mc = length(low)
    sol = Vector{Float64}(undef, mc)
    flags = falses(mc)
    err = 0.0
    tol = 0.0
    @inbounds for k in 1:mc
        lo = low[k]
        hi = high[k]
        if isfinite(lo) && isfinite(hi)
            el = max(abs_tol, abs(lo) * rel_tol)
            eh = max(abs_tol, abs(hi) * rel_tol)
            sol[k] = 0.5 * (lo + hi + el - eh)
            hw = (hi - lo) / 2
            tol_k = (el + eh) / 2
            flags[k] = hw <= tol_k
            hw > err && (err = hw)
            tol_k > tol && (tol = tol_k)
        else
            sol[k] = NaN
            flags[k] = false
        end
    end
    return low, high, sol, flags, err, tol
end

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
