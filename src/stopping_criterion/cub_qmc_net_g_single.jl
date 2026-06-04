"""
    CubQMCNetGSingle(integrand; abs_tol=0.01, rel_tol=0.0,
                     n_init=2^10, n_max=2^30, trace_iterations=false)

Single-net digital-net cubature using one randomized `DigitalNetB2` in natural
order (`graycode=false`). The estimate is refined by doubling the sample size
and comparing consecutive nested-net means while holding the scramble fixed.

This is a minimal single-net companion to [`CubQMCNetG`](@ref): it keeps the
same public tolerance/reporting shape, but uses `n_reps = 1`.
"""
mutable struct CubQMCNetGSingle{I <: AbstractIntegrand} <: AbstractStoppingCriterion
    integrand::I
    abs_tol::Float64
    rel_tol::Float64
    n_init::Int
    n_max::Int
    trace_iterations::Bool
end

function _validate_single_net_dd(integrand::AbstractIntegrand)
    dd = integrand.true_measure.dd
    dd isa DigitalNetB2 ||
        error("CubQMCNetGSingle requires a DigitalNetB2 discrete distribution")
    isnothing(dd.replications) ||
        error("CubQMCNetGSingle requires replications=nothing on DigitalNetB2")
    dd.graycode == false ||
        error("CubQMCNetGSingle requires graycode=false (natural/radical-inverse order)")
    return dd
end

function CubQMCNetGSingle(
    integrand::AbstractIntegrand;
    abs_tol::Float64=0.01,
    rel_tol::Float64=0.0,
    n_init::Int=2^10,
    n_max::Int=2^30,
    trace_iterations::Bool=false,
)
    _validate_single_net_dd(integrand)
    abs_tol >= 0 || throw(ArgumentError("abs_tol must be >= 0"))
    rel_tol >= 0 || throw(ArgumentError("rel_tol must be >= 0"))
    n_init > 0 || throw(ArgumentError("n_init must be positive"))
    n_max >= n_init || throw(ArgumentError("n_max must be >= n_init"))
    ispow2(n_init) || throw(ArgumentError("n_init must be a power of 2"))
    ispow2(n_max) || throw(ArgumentError("n_max must be a power of 2"))
    return CubQMCNetGSingle(integrand, abs_tol, rel_tol, n_init, n_max, trace_iterations)
end

function _single_net_mean(integrand::AbstractIntegrand, n::Int)
    # Re-evaluate from a deep-copied base integrand so the randomization state of
    # the underlying DigitalNetB2 is identical across doublings.
    return mean(sample_and_evaluate(deepcopy(integrand), n))
end

function integrate(sc::CubQMCNetGSingle; resume::Union{Nothing, Dict{Symbol, Any}}=nothing)
    resume === nothing || error("CubQMCNetGSingle does not support resume yet")

    t_start = time()
    mu_prev = _single_net_mean(sc.integrand, sc.n_init)
    n_prev = sc.n_init
    err = Inf
    converged = false
    n_iter = 0
    log = IterationLog()
    mu_hat = mu_prev
    n_cur = n_prev

    while n_prev < sc.n_max
        n_cur = min(2 * n_prev, sc.n_max)
        mu_hat = _single_net_mean(sc.integrand, n_cur)
        err = abs(mu_hat - mu_prev)
        tol = max(sc.abs_tol, sc.rel_tol * abs(mu_hat))
        n_iter += 1

        if sc.trace_iterations
            push!(
                log;
                n=n_cur,
                solution=mu_hat,
                error_bound=err,
                tol=tol,
                elapsed=time() - t_start,
            )
        end

        if err <= tol
            converged = true
            break
        end
        mu_prev = mu_hat
        n_prev = n_cur
    end

    if !converged
        @warn "CubQMCNetGSingle: did not converge within n_max=$(sc.n_max)."
    end

    data = Dict{Symbol, Any}(
        :n => n_cur,
        :n_per_rep => n_cur,
        :n_total => n_cur,
        :n_reps => 1,
        :error_bound => err,
        :n_iterations => n_iter,
        :converged => converged,
        :time_integrate => time() - t_start,
    )
    if sc.trace_iterations
        data[:iteration_log] = log
    end
    return QMCResult(mu_hat, data)
end

Base.show(io::IO, sc::CubQMCNetGSingle) = print(io, "CubQMCNetGSingle(abs_tol=$(sc.abs_tol))")
