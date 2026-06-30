"""
    CubQMCNetGRep(integrand; abs_tol=0.01, rel_tol=0.0,
                  n_init=2^10, n_limit=2^30, n_reps=16, alpha=0.01,
                  trace_iterations=false)

Guaranteed QMC cubature using replicated randomized digital nets.

This is Julia's replicated companion to the single-net [`CubQMCNetG`](@ref).
It estimates the mean from `n_reps` independently randomized digital nets and
uses a Student's t half-width across the replication means as its stopping rule.

Supports **resume** and optional **iteration logging** (`trace_iterations=true`).
The returned `result.data` also includes the final `:replicate_means` vector so
fixed-seed runs can be audited for exact reproducibility across execution modes.

# Examples
```jldoctest
julia> using QuasiMC

julia> f = Genz(Uniform(DigitalNetB2(2; randomize="DS", seed=700)); kind=:gaussian_peak, a=[1.0, 1.0], u=[0.5, 0.5])
Genz(:gaussian_peak, d=2)

julia> sc = CubQMCNetGRep(f; abs_tol=0.1, n_init=2^10, n_reps=16)
CubQMCNetGRep(abs_tol=0.1, n_reps=16)

julia> result = integrate(sc);

julia> abs(result.solution - genz_exact(f)) < 0.05
true

julia> result.data[:n_total] > 0
true
```
"""
mutable struct CubQMCNetGRep{I <: AbstractIntegrand} <: AbstractStoppingCriterion
    integrand::I
    abs_tol::Float64
    rel_tol::Float64
    n_init::Int
    n_limit::Int
    n_reps::Int
    alpha::Float64
    _t_crit::Float64
    trace_iterations::Bool
end

function CubQMCNetGRep(
    integrand::AbstractIntegrand;
    abs_tol::Float64=0.01,
    rel_tol::Float64=0.0,
    n_init::Int=2^10,
    n_limit::Int=2^30,
    n_reps::Int=16,
    alpha::Float64=0.01,
    trace_iterations::Bool=false,
)
    return CubQMCNetGRep(
        integrand,
        abs_tol,
        rel_tol,
        n_init,
        n_limit,
        n_reps,
        alpha,
        quantile(TDist(n_reps - 1), 1.0 - alpha / 2.0),
        trace_iterations,
    )
end

function _replicate_means!(
    estimates::Vector{Float64},
    f::AbstractIntegrand,
    tm::AbstractTrueMeasure,
    dd,
    n::Int,
)
    R = length(estimates)

    if Threads.nthreads() == 1
        # On the single-threaded benchmark path it is cheaper to stream each
        # replicate through transform/evaluate immediately than to retain all R
        # sample matrices and revisit them in a second pass.
        @inbounds for r in 1:R
            xu = gen_samples(dd, n)
            xu = ndims(xu) == 3 ? reshape(xu, size(xu, 1) * size(xu, 2), size(xu, 3)) : xu
            estimates[r] = mean(evaluate(f, transform(tm, xu)))
        end
        return nothing
    end

    # With multiple Julia threads, keep the original two-pass structure so the
    # transform/evaluate work can still be distributed across replicates.
    samples = Vector{Matrix{Float64}}(undef, R)
    for r in 1:R
        xu = gen_samples(dd, n)
        samples[r] = ndims(xu) == 3 ? reshape(xu, size(xu, 1) * size(xu, 2), size(xu, 3)) : xu
    end

    Threads.@threads for r in 1:R
        y = evaluate(f, transform(tm, samples[r]))
        @inbounds estimates[r] = mean(y)
    end
    return nothing
end

# Specialization for DigitalNetB2: on the single-threaded path, pre-allocate the
# C output buffer and sample matrix once and reuse them across all R replicates,
# avoiding 2×R large n×d allocations for the LMS_DS/LMS graycode alpha=1 case.
function _replicate_means!(
    estimates::Vector{Float64},
    f::AbstractIntegrand,
    tm::AbstractTrueMeasure,
    dd::DigitalNetB2,
    n::Int,
)
    R = length(estimates)

    if Threads.nthreads() == 1
        if (dd.randomize == "LMS_DS" || dd.randomize == "LMS") &&
           dd.alpha == 1 &&
           isnothing(dd.replications) &&
           dd.graycode
            x_buf = Vector{Float64}(undef, n * dd.dimension)
            xu = Matrix{Float64}(undef, n, dd.dimension)
            # Pre-allocate LMS setup buffers once instead of per replicate.
            mmax = size(dd.direction_nums, 2)
            V_scr_buf = Matrix{UInt64}(undef, dd.dimension, mmax)
            L_buf = Vector{UInt64}(undef, dd.t)
            C_flat_buf = Vector{UInt64}(undef, dd.dimension * mmax)
            shiftsb_buf = Vector{UInt64}(undef, dd.dimension)
            lshifts_buf = [UInt64(0)]     # curr_bits == dd.t ⟹ shift is always 0
            tmaxes_buf = [UInt64(dd.t)]
            if _supports_transform_into(tm)
                tm_dim = dimension(tm)
                z_scratch = Matrix{Float64}(undef, n, tm_dim)
                xy = Matrix{Float64}(undef, n, tm_dim)
                if _supports_evaluate_into(f)
                    y_buf = Vector{Float64}(undef, n)
                    @inbounds for r in 1:R
                        _gen_samples_lms_into!(
                            dd,
                            n,
                            x_buf,
                            xu,
                            V_scr_buf,
                            L_buf,
                            C_flat_buf,
                            shiftsb_buf,
                            lshifts_buf,
                            tmaxes_buf,
                        )
                        _transform_into!(tm, xu, z_scratch, xy)
                        _evaluate_into!(f, xy, y_buf)
                        estimates[r] = mean(y_buf)
                    end
                else
                    @inbounds for r in 1:R
                        _gen_samples_lms_into!(
                            dd,
                            n,
                            x_buf,
                            xu,
                            V_scr_buf,
                            L_buf,
                            C_flat_buf,
                            shiftsb_buf,
                            lshifts_buf,
                            tmaxes_buf,
                        )
                        _transform_into!(tm, xu, z_scratch, xy)
                        estimates[r] = mean(evaluate(f, xy))
                    end
                end
            else
                @inbounds for r in 1:R
                    _gen_samples_lms_into!(
                        dd,
                        n,
                        x_buf,
                        xu,
                        V_scr_buf,
                        L_buf,
                        C_flat_buf,
                        shiftsb_buf,
                        lshifts_buf,
                        tmaxes_buf,
                    )
                    estimates[r] = mean(evaluate(f, transform(tm, xu)))
                end
            end
            return nothing
        end
        @inbounds for r in 1:R
            xu = gen_samples(dd, n)
            xu = ndims(xu) == 3 ? reshape(xu, size(xu, 1) * size(xu, 2), size(xu, 3)) : xu
            estimates[r] = mean(evaluate(f, transform(tm, xu)))
        end
        return nothing
    end

    samples = Vector{Matrix{Float64}}(undef, R)
    for r in 1:R
        xu = gen_samples(dd, n)
        samples[r] = ndims(xu) == 3 ? reshape(xu, size(xu, 1) * size(xu, 2), size(xu, 3)) : xu
    end

    Threads.@threads for r in 1:R
        y = evaluate(f, transform(tm, samples[r]))
        @inbounds estimates[r] = mean(y)
    end
    return nothing
end

function integrate(sc::CubQMCNetGRep; resume::Union{Nothing, Dict{Symbol, Any}}=nothing)
    R = sc.n_reps
    t_crit = sc._t_crit

    if resume !== nothing
        n_prev = haskey(resume, :n_per_rep) ? Int(resume[:n_per_rep]) : Int(resume[:n])
        n = 2 * n_prev
        prev_time = Float64(get(resume, :time_integrate, 0.0))
    else
        n = sc.n_init
        prev_time = 0.0
    end

    t_start = time()
    mu_hat = 0.0
    err = Inf
    sigma_reps = NaN
    n_iter = 0
    log = IterationLog()
    f = sc.integrand
    dd = discrete_distribution(f)
    tm = true_measure(f)
    estimates = Vector{Float64}(undef, R)

    while n <= sc.n_limit
        n_iter += 1
        _replicate_means!(estimates, f, tm, dd, n)

        mu_hat = mean(estimates)
        sigma_reps = std(estimates; corrected=true)
        err = t_crit * sigma_reps / sqrt(R)
        tol = max(sc.abs_tol, sc.rel_tol * abs(mu_hat))

        if sc.trace_iterations
            push!(
                log;
                n=n*R,
                solution=mu_hat,
                error_bound=err,
                tol=tol,
                elapsed=time() - t_start,
            )
        end

        err <= tol && break
        n = min(2n, sc.n_limit + 1)
    end

    converged = err <= max(sc.abs_tol, sc.rel_tol * abs(mu_hat))
    if !converged
        @warn "CubQMCNetGRep: did not converge within n_limit=$(sc.n_limit)."
    end

    t_elapsed = time() - t_start
    n_per_rep = n > sc.n_limit ? sc.n_limit : n
    data = Dict{Symbol, Any}(
        :n => n_per_rep,
        :n_per_rep => n_per_rep,
        :n_total => n_per_rep * R,
        :n_reps => R,
        :error_bound => err,
        :replicate_means => copy(estimates),
        :replicate_std => sigma_reps,
        :n_iterations => n_iter,
        :converged => converged,
        :time_integrate => prev_time + t_elapsed,
    )
    if sc.trace_iterations
        data[:iteration_log] = log
    end
    return QMCResult(mu_hat, data)
end

function Base.show(io::IO, sc::CubQMCNetGRep)
    print(io, "CubQMCNetGRep(abs_tol=$(sc.abs_tol), n_reps=$(sc.n_reps))")
end
