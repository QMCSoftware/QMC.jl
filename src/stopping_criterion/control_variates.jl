"""
Linear control variates, matching QMC v2.3 (`CubMCCLT` / `CubMCG`).

Given a main integrand ``f`` and control variates ``g_1, …, g_k`` with *known*
means ``μ_1, …, μ_k``, the control-variate estimator replaces each sample value
``y = f(x)`` with

```math
\\hat{y} = y - \\sum_{j=1}^{k} β_j \\,\\bigl(g_j(x) - μ_j\\bigr),
```

where the coefficients ``β`` are fit once on the pilot sample by ordinary least
squares of the centered integrand values on the centered control-variate values.
Because ``E[g_j(x) - μ_j] = 0``, the estimator stays unbiased while its variance
drops whenever the control variates are correlated with ``f``.

This mirrors QMCPy, where the control variates are passed to the stopping
criterion as a list of integrands sharing the main integrand's discrete
distribution together with their known means.
"""

"""
    _ControlVariateSpec

Validated bundle of control-variate integrands and their known means. Construct
via [`_make_control_variate_spec`](@ref); a `nothing` spec means "no control
variates" and the caller takes its ordinary path.
"""
struct _ControlVariateSpec
    integrands::Vector{AbstractIntegrand}
    means::Vector{Float64}
end

"""
    _make_control_variate_spec(integrand, control_variates, control_variate_means)

Normalize and validate the user-supplied control variates against the main
`integrand`, returning a [`_ControlVariateSpec`](@ref) or `nothing` when no
control variates were requested.

Each control variate must be an `AbstractIntegrand` that shares the main
integrand's discrete distribution (so the same point stream drives all of them)
and dimension, mirroring QMCPy's compatibility checks. The number of supplied
means must match the number of control variates.
"""
function _make_control_variate_spec(
    integrand::AbstractIntegrand,
    control_variates,
    control_variate_means,
)
    control_variates === nothing && return nothing
    cvs =
        control_variates isa AbstractIntegrand ? AbstractIntegrand[control_variates] :
        collect(AbstractIntegrand, control_variates)
    isempty(cvs) && return nothing

    control_variate_means === nothing && throw(
        ArgumentError("control_variate_means must be supplied alongside control_variates"),
    )
    means =
        control_variate_means isa Number ? Float64[Float64(control_variate_means)] :
        Float64.(collect(control_variate_means))
    length(means) == length(cvs) || throw(
        ArgumentError(
            "control_variate_means has length $(length(means)) but there are $(length(cvs)) control variates",
        ),
    )

    d = integrand.true_measure.dimension
    dd = integrand.true_measure.dd
    for cv in cvs
        cv.true_measure.dimension == d || throw(
            ArgumentError(
                "each control variate must share the main integrand's dimension ($d)",
            ),
        )
        cv.true_measure.dd === dd || throw(
            ArgumentError(
                "each control variate must share the main integrand's discrete distribution",
            ),
        )
    end
    return _ControlVariateSpec(cvs, means)
end

"""
    _control_variate_values(spec, x_uniform) -> n × ncv matrix

Evaluate every control variate on the shared uniform point set `x_uniform`,
returning a column per control variate.
"""
function _control_variate_values(spec::_ControlVariateSpec, x_uniform::AbstractMatrix)
    ncv = length(spec.integrands)
    n = size(x_uniform, 1)
    out = Matrix{Float64}(undef, n, ncv)
    for j in 1:ncv
        out[:, j] .= evaluate_on_uniform(spec.integrands[j], x_uniform)
    end
    return out
end

"""
    _fit_control_variate_beta(y_pilot, ycv_pilot) -> β

Ordinary-least-squares regression coefficients of the centered pilot integrand
values `y_pilot` on the centered pilot control-variate values `ycv_pilot`
(an `n × ncv` matrix). Matches QMCPy's `lstsq` fit.
"""
function _fit_control_variate_beta(y_pilot::AbstractVector, ycv_pilot::AbstractMatrix)
    G = ycv_pilot .- sum(ycv_pilot; dims=1) ./ size(ycv_pilot, 1)
    yc = y_pilot .- (sum(y_pilot) / length(y_pilot))
    return G \ yc
end

"""
    _apply_control_variates(y, ycv, means, β) -> ŷ

Return the control-variate-adjusted values `ŷ = y - (ycv .- means') * β`.
"""
function _apply_control_variates(
    y::AbstractVector,
    ycv::AbstractMatrix,
    means::AbstractVector,
    beta::AbstractVector,
)
    return y .- (ycv .- reshape(means, 1, :)) * beta
end

"""
    _draw_adjusted(integrand, dd, n, cv_spec, beta) -> y

Draw `n` points from `dd`, evaluate `integrand`, and—when `cv_spec` is non-`nothing`—
subtract the control-variate correction using the already-fitted `beta`. Used by
the iterative criteria (e.g. `CubMCG`) where the regression coefficients are fit
on the pilot sample and then reused for every subsequent batch. Passing `beta`
explicitly (rather than capturing it in a closure) keeps the call type-stable.
"""
function _draw_adjusted(
    integrand::AbstractIntegrand,
    dd::AbstractDiscreteDistribution,
    n::Int,
    cv_spec::Union{Nothing, _ControlVariateSpec},
    beta,
)
    x_uniform = _sample_uniform_points(dd, n)
    y = evaluate_on_uniform(integrand, x_uniform)
    cv_spec === nothing && return y
    ycv = _control_variate_values(cv_spec, x_uniform)
    return _apply_control_variates(y, ycv, cv_spec.means, beta)
end
