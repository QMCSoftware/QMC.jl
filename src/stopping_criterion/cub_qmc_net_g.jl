"""
    CubQMCNetG(integrand; abs_tol=0.01, rel_tol=0.0,
               n_init=2^10, n_max=2^30, n_reps=16, alpha=0.01,
               trace_iterations=false)

Guaranteed QMC cubature using replicated randomized digital nets.

Supports **resume** and optional **iteration logging** (`trace_iterations=true`).

# Example
```julia
dd = DigitalNetB2(3; randomize="LMS_DS")
tm = Uniform(dd)
f = Genz(tm; kind=:oscillatory)
sc = CubQMCNetG(f; abs_tol=1e-4)
result = integrate(sc)
```
"""
mutable struct CubQMCNetG{I <: AbstractIntegrand} <: AbstractStoppingCriterion
    integrand::I
    abs_tol::Float64
    rel_tol::Float64
    n_init::Int
    n_max::Int
    n_reps::Int
    alpha::Float64
    trace_iterations::Bool
end

function CubQMCNetG(
    integrand::AbstractIntegrand;
    abs_tol::Float64=0.01,
    rel_tol::Float64=0.0,
    n_init::Int=2^10,
    n_max::Int=2^30,
    n_reps::Int=16,
    alpha::Float64=0.01,
    trace_iterations::Bool=false,
)
    return CubQMCNetG(
        integrand,
        abs_tol,
        rel_tol,
        n_init,
        n_max,
        n_reps,
        alpha,
        trace_iterations,
    )
end

function integrate(sc::CubQMCNetG; resume::Union{Nothing, Dict{Symbol, Any}}=nothing)
    R = sc.n_reps
    t_crit = quantile(TDist(R - 1), 1.0 - sc.alpha / 2.0)

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
    n_iter = 0
    log = IterationLog()

    while n <= sc.n_max
        n_iter += 1
        estimates = Vector{Float64}(undef, R)

        # Batch the R replicates' transform + evaluate into a single pass.
        # The R independent randomizations are drawn exactly as before (R
        # `gen_samples` calls on the integrand's discrete distribution, in the
        # same order, advancing the same RNG), so the points — and therefore the
        # per-replicate means, `mu_hat`, and the error bound — are unchanged.
        # The only difference is that the (dense, O(n·d²) for GBM) transform and
        # the integrand evaluation run once over the stacked R·n rows instead of
        # R times over n rows: one large BLAS GEMM rather than R small ones, with
        # far less per-call dispatch/allocation overhead. `transform` and
        # `evaluate` act row-by-row, so each replicate's block is identical to
        # what the per-replicate call produced.
        dd = sc.integrand.true_measure.dd
        blocks = Vector{AbstractMatrix{Float64}}(undef, R)
        @inbounds for r in 1:R
            xu = gen_samples(dd, n)
            blocks[r] = if ndims(xu) == 3
                reshape(xu, size(xu, 1) * size(xu, 2), size(xu, 3))
            else
                xu
            end
        end
        x_uniform = reduce(vcat, blocks)
        y_all = evaluate(sc.integrand, transform(sc.integrand.true_measure, x_uniform))
        off = 0
        @inbounds for r in 1:R
            m = size(blocks[r], 1)
            estimates[r] = mean(@view y_all[(off + 1):(off + m)])
            off += m
        end

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
        n = min(2n, sc.n_max + 1)
    end

    converged = err <= max(sc.abs_tol, sc.rel_tol * abs(mu_hat))
    if !converged
        @warn "CubQMCNetG: did not converge within n_max=$(sc.n_max)."
    end

    t_elapsed = time() - t_start
    n_per_rep = n > sc.n_max ? sc.n_max : n
    data = Dict{Symbol, Any}(
        :n => n_per_rep,
        :n_per_rep => n_per_rep,
        :n_total => n_per_rep * R,
        :n_reps => R,
        :error_bound => err,
        :n_iterations => n_iter,
        :converged => converged,
        :time_integrate => prev_time + t_elapsed,
    )
    if sc.trace_iterations
        data[:iteration_log] = log
    end
    return QMCResult(mu_hat, data)
end

function Base.show(io::IO, sc::CubQMCNetG)
    print(io, "CubQMCNetG(abs_tol=$(sc.abs_tol), n_reps=$(sc.n_reps))")
end
