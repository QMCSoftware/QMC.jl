"""
    CubQMCNetG(integrand; abs_tol=0.01, rel_tol=0.0,
               n_init=2^10, n_max=2^30, r_lag=4,
               trace_iterations=false)

Guaranteed QMC cubature on a **single randomized digital net** (no replications),
porting QMCPy's `CubQMCNetG`. The error bound comes from the decay of the
orthonormal Walsh coefficients of the integrand rather than a replication-based
confidence interval, so it samples far fewer points than the replicated
[`CubQMCNetGRep`](@ref).

For vector-valued integrands (`QMC.d_indv(f) != ()`), returns a
[`QMCVecResult`](@ref) whose combined bounds are built through
`QMC.bound_fun(f, low, high)`.

At each step the net of size `n = 2^m` is drawn, the integrand is evaluated, the
scaled Walsh coefficients `ytilde` are formed, their indices are decay-ordered
(`kappanumap`), and the half-width bound is

    fudge(m) · Σ |ytilde[kappanumap[nllstart : 2·nllstart]]|,
    fudge(m) = 5·2⁻ᵐ,   nllstart = 2^(m − r_lag − 1).

Sampling doubles until the bound meets the tolerance or `n_max` is reached.

The discrete distribution must be a non-replicated [`DigitalNetB2`](@ref) in
**natural (radical-inverse) order**, i.e. constructed with `graycode=false` and
`replications=nothing` (matching QMCPy's "RADICAL INVERSE" requirement). A
randomized net (e.g. `randomize="LMS_DS"`) is expected.

Pass `control_variates` (an integrand or vector of integrands sharing the main
integrand's discrete distribution and dimension) with their known
`control_variate_means` to apply linear control variates. Following QMC v2.3,
the coefficients β are fit in the Walsh-coefficient domain on the decay-ordered
tail and the correction is subtracted from `ytilde` before the bound is formed;
the mean is recovered as `mean(y − Σ β·g) + Σ β·μ`. The fitted coefficients are
returned in `result.data[:control_variate_beta]`.

# Examples
```jldoctest
julia> using QMC

julia> dd = DigitalNetB2(3; randomize="LMS_DS", graycode=false, seed=2024);

julia> f = Keister(Gaussian(dd; covariance=0.5))
Keister(d=3)

julia> sc = CubQMCNetG(f; abs_tol=0.01, n_init=2^10)
CubQMCNetG(abs_tol=0.01)

julia> result = integrate(sc);

julia> round(result.solution; digits=4)
2.1685

julia> result.data[:converged]
true
```

```jldoctest
julia> using QMC

julia> dd = DigitalNetB2(2; randomize="LMS_DS", graycode=false, seed=77);

julia> g = CustomFun(Uniform(dd), x -> x[:, 1].^2 .+ x[:, 2])
CustomFun(d=2)

julia> result = integrate(CubQMCNetG(g; abs_tol=1e-3, control_variates=g, control_variate_means=5 / 6));

julia> isapprox(result.solution, 5 / 6; atol=1e-10)
true

julia> result.data[:error_bound] < 1e-10
true
```
"""
mutable struct CubQMCNetG{I <: AbstractIntegrand} <: AbstractStoppingCriterion
    integrand::I
    abs_tol::Float64
    rel_tol::Float64
    n_init::Int
    n_max::Int
    r_lag::Int
    trace_iterations::Bool
    cv_spec::Union{Nothing, _ControlVariateSpec}
end

function CubQMCNetG(
    integrand::AbstractIntegrand;
    abs_tol::Float64=0.01,
    rel_tol::Float64=0.0,
    n_init::Int=2^10,
    n_max::Int=2^30,
    r_lag::Int=4,
    trace_iterations::Bool=false,
    control_variates=nothing,
    control_variate_means=nothing,
)
    dd = integrand.true_measure.dd
    dd isa DigitalNetB2 || error("CubQMCNetG requires a DigitalNetB2 discrete distribution.")
    dd.replications === nothing || error(
        "CubQMCNetG requires a non-replicated net (construct DigitalNetB2 with replications=nothing).",
    )
    !dd.graycode || error(
        "CubQMCNetG requires natural (radical-inverse) order: construct DigitalNetB2 with graycode=false.",
    )
    ispow2(n_init) || error("CubQMCNetG: n_init must be a power of two.")
    n_floor = 2^max(r_lag + 1, 8)
    if n_init < n_floor
        @warn "CubQMCNetG: n_init bumped up to $n_floor (the guaranteed bound needs n_init ≥ 2^max(r_lag+1, 8))."
        n_init = n_floor
    end
    cv_spec = _make_control_variate_spec(integrand, control_variates, control_variate_means)
    if cv_spec !== nothing && d_indv(integrand) != ()
        throw(
            ArgumentError(
                "CubQMCNetG currently supports control variates only for scalar integrands.",
            ),
        )
    end
    return CubQMCNetG(
        integrand,
        abs_tol,
        rel_tol,
        n_init,
        n_max,
        r_lag,
        trace_iterations,
        cv_spec,
    )
end

function _integrate_cubqmcnetg_multi(sc::CubQMCNetG, resume::Union{Nothing, Dict{Symbol, Any}})
    r_lag = sc.r_lag
    n = resume !== nothing ? 2 * Int(get(resume, :n, sc.n_init)) : sc.n_init
    prev_time = resume !== nothing ? Float64(get(resume, :time_integrate, 0.0)) : 0.0

    t_start = time()
    f = sc.integrand
    dd = f.true_measure.dd
    ishape = d_indv(f)
    cshape = d_comb(f)
    m_indv = prod(ishape)
    log = IterationLog()

    solution_indv = zeros(Float64, m_indv)
    indv_low = zeros(Float64, m_indv)
    indv_high = zeros(Float64, m_indv)
    comb_low = zeros(Float64, prod(cshape))
    comb_high = zeros(Float64, prod(cshape))
    sol_comb = zeros(Float64, prod(cshape))
    comb_flags = falses(prod(cshape))
    err_comb = Inf
    converged = false
    n_iter = 0
    n_final = n

    while n <= sc.n_max
        n_iter += 1
        m = round(Int, log2(n))

        x_unit = gen_samples(dd, n)
        if ndims(x_unit) == 3
            size(x_unit, 1) == 1 || error("CubQMCNetG requires a non-replicated net.")
            x_unit = reshape(x_unit, size(x_unit, 2), size(x_unit, 3))
        end
        Y = reshape(evaluate(f, transform(f.true_measure, x_unit)), n, m_indv)
        kappanumap0 = collect(0:(n - 1))

        mllstart = m - r_lag - 1
        nllstart = 2^mllstart
        fudge = 5.0 * 2.0^(-m)
        @inbounds for j in 1:m_indv
            y = @view Y[:, j]
            ytilde = _ytilde_init(y)
            kappanumap = _update_kappanumap!(copy(kappanumap0), ytilde, m - 1, 0, m)
            s = 0.0
            for p in (nllstart + 1):(2 * nllstart)
                s += abs(ytilde[kappanumap[p] + 1])
            end
            mu = mean(y)
            err = fudge * s
            solution_indv[j] = mu
            indv_low[j] = mu - err
            indv_high[j] = mu + err
        end

        cl, ch = bound_fun(f, indv_low, indv_high)
        comb_low, comb_high, sol_comb, comb_flags, err_comb, tol_max =
            _combined_bounds_stats(sc.abs_tol, sc.rel_tol, cl, ch)
        converged = all(comb_flags)
        n_final = n

        if sc.trace_iterations
            push!(
                log;
                n=n,
                solution=sol_comb[1],
                error_bound=err_comb,
                tol=tol_max,
                elapsed=time() - t_start,
            )
        end

        converged && break
        n *= 2
    end

    if !converged
        @warn "CubQMCNetG: did not converge within n_max=$(sc.n_max)."
    end

    t_elapsed = time() - t_start
    data = Dict{Symbol, Any}(
        :n => n_final,
        :n_per_rep => n_final,
        :n_total => n_final,
        :n_reps => 1,
        :n_indv => Array{Int}(reshape(fill(n_final, m_indv), ishape)),
        :error_bound => err_comb,
        :n_iterations => n_iter,
        :converged => converged,
        :time_integrate => prev_time + t_elapsed,
        :solution_indv => Array{Float64}(reshape(copy(solution_indv), ishape)),
        :comb_bound_low => Array{Float64}(reshape(comb_low, cshape)),
        :comb_bound_high => Array{Float64}(reshape(comb_high, cshape)),
    )
    if sc.trace_iterations
        data[:iteration_log] = log
    end
    return QMCVecResult(Array{Float64}(reshape(sol_comb, cshape)), data)
end

function integrate(sc::CubQMCNetG; resume::Union{Nothing, Dict{Symbol, Any}}=nothing)
    if d_indv(sc.integrand) != ()
        return _integrate_cubqmcnetg_multi(sc, resume)
    end
    r_lag = sc.r_lag
    n = resume !== nothing ? 2 * Int(get(resume, :n, sc.n_init)) : sc.n_init
    prev_time = resume !== nothing ? Float64(get(resume, :time_integrate, 0.0)) : 0.0

    t_start = time()
    dd = sc.integrand.true_measure.dd

    mu_hat = 0.0
    err = Inf
    n_iter = 0
    n_final = n
    cv = sc.cv_spec
    cv_beta = nothing
    log = IterationLog()

    while n <= sc.n_max
        n_iter += 1
        m = round(Int, log2(n))

        # One fresh randomized net per doubling (single net, no replications).
        x_unit = gen_samples(dd, n)
        if ndims(x_unit) == 3
            size(x_unit, 1) == 1 || error("CubQMCNetG requires a non-replicated net.")
            x_unit = reshape(x_unit, size(x_unit, 2), size(x_unit, 3))
        end
        y = evaluate(sc.integrand, transform(sc.integrand.true_measure, x_unit))

        # Estimate and guaranteed half-width from the Walsh-coefficient decay.
        ytilde = _ytilde_init(y)
        mu_hat = mean(y)
        kappanumap = _update_kappanumap!(collect(0:(n - 1)), ytilde, m - 1, 0, m)

        mllstart = m - r_lag - 1

        # Control variates (transform domain): fit β on the decay-ordered tail,
        # subtract β·ỹcv from the coefficients, then re-order on the corrected
        # coefficients. The mean is recovered as mean(y − Σβ·g) + Σβ·μ.
        if cv !== nothing
            gvals = [evaluate_on_uniform(g, x_unit) for g in cv.integrands]
            ycvtilde = [_ytilde_init(gv) for gv in gvals]
            cv_beta =
                _fit_control_variate_beta_transform(ytilde, ycvtilde, kappanumap, mllstart)
            @inbounds for i in 1:n
                acc = 0.0
                for k in eachindex(ycvtilde)
                    acc += cv_beta[k] * ycvtilde[k][i]
                end
                ytilde[i] -= acc
            end
            kappanumap = _update_kappanumap!(collect(0:(n - 1)), ytilde, m - 1, 0, m)
            yadj = copy(y)
            for k in eachindex(gvals)
                yadj .-= cv_beta[k] .* gvals[k]
            end
            mu_hat = mean(yadj) + sum(cv_beta .* cv.means)
        end

        nllstart = 2^mllstart
        fudge = 5.0 * 2.0^(-m)
        s = 0.0
        @inbounds for p in (nllstart + 1):(2 * nllstart)
            s += abs(ytilde[kappanumap[p] + 1])
        end
        err = fudge * s

        tol = max(sc.abs_tol, sc.rel_tol * abs(mu_hat))
        n_final = n
        if sc.trace_iterations
            push!(log; n=n, solution=mu_hat, error_bound=err, tol=tol, elapsed=time() - t_start)
        end

        err <= tol && break
        # Only ever sample at powers of two; the `while` guard stops once the
        # next doubling would exceed n_max (so n_max need not be a power of two).
        n *= 2
    end

    converged = err <= max(sc.abs_tol, sc.rel_tol * abs(mu_hat))
    if !converged
        @warn "CubQMCNetG: did not converge within n_max=$(sc.n_max)."
    end

    t_elapsed = time() - t_start
    n_per_rep = n > sc.n_max ? sc.n_max : n
    data = Dict{Symbol, Any}(
        :n => n_final,
        :n_per_rep => n_final,
        :n_total => n_final,
        :n_reps => 1,
        :error_bound => err,
        :n_iterations => n_iter,
        :converged => converged,
        :time_integrate => prev_time + t_elapsed,
    )
    if cv_beta !== nothing
        data[:control_variate_beta] = cv_beta
    end
    if sc.trace_iterations
        data[:iteration_log] = log
    end
    return QMCResult(mu_hat, data)
end

Base.show(io::IO, sc::CubQMCNetG) = print(io, "CubQMCNetG(abs_tol=$(sc.abs_tol))")

# Backward-compatible alias for the earlier explicit single-net name.
const CubQMCNetGSingle = CubQMCNetG
