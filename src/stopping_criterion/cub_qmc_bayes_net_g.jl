"""
    CubQMCBayesNetG(integrand; abs_tol=0.01, rel_tol=0.0,
                    n_init=2^8, n_max=2^22, order=2,
                    ptransform=:NONE, errbd_type=:MLE, alpha=0.01,
                    trace_iterations=false)

Bayesian QMC cubature for digital net (Sobol') rules with digitally
shift-invariant kernels, diagonalized by the Walsh-Hadamard Transform.

Set `trace_iterations=true` to record an `IterationLog` in
`result.data[:iteration_log]`.

# Example
```julia
dd = DigitalNetB2(3; randomize="LMS_DS", seed=7)
tm = Uniform(dd)
f = Genz(tm; kind=:continuous)
sc = CubQMCBayesNetG(f; abs_tol=1e-4)
result = integrate(sc)
```
"""
mutable struct CubQMCBayesNetG{I <: AbstractIntegrand} <: AbstractStoppingCriterion
    integrand::I
    abs_tol::Float64
    rel_tol::Float64
    n_init::Int
    n_max::Int
    order::Int
    ptransform::Symbol
    errbd_type::Symbol
    alpha::Float64
    trace_iterations::Bool
end

function CubQMCBayesNetG(
    integrand::AbstractIntegrand;
    abs_tol::Float64=0.01,
    rel_tol::Float64=0.0,
    n_init::Int=2^8,
    n_max::Int=2^22,
    order::Int=2,
    ptransform::Symbol=:NONE,
    errbd_type::Symbol=:MLE,
    alpha::Float64=0.01,
    trace_iterations::Bool=false,
)
    @assert ispow2(n_init) "n_init must be a power of 2"
    @assert ispow2(n_max) "n_max must be a power of 2"
    @assert order in (1, 2, 3)
    @assert errbd_type in (:MLE, :GCV, :FULL)
    @assert 0 < alpha < 1
    return CubQMCBayesNetG(
        integrand,
        abs_tol,
        rel_tol,
        n_init,
        n_max,
        order,
        ptransform,
        errbd_type,
        alpha,
        trace_iterations,
    )
end

# ── Digitally shift-invariant kernel for digital nets ────────────────────────

"""
Compute DSI kernel eigenvalues via Walsh-Hadamard Transform with
cancellation avoidance, analogous to the lattice FFT version.
"""
function _dsi_kernel_eigenvalues(xun::AbstractMatrix, order::Int, theta::Float64)
    n, d = size(xun)
    @assert ispow2(n)
    b_order = 2 * order
    const_mult = -(-1.0)^(b_order ÷ 2)

    bern = if b_order == 2
        x -> -x*(1.0-x) + 1.0/6.0
    elseif b_order == 4
        x -> (x*(1.0-x))^2 - 1.0/30.0
    else
        x -> let t = mod(x, 1.0)
            t^6 - 3t^5 + 2.5t^4 - 0.5t^2 + 1.0/42.0
        end
    end

    # For DSI kernels we XOR each point with the first point before evaluating
    bvals = Matrix{Float64}(undef, n, d)
    nbits = 30
    scale = 2^nbits
    @inbounds for j in 1:d
        x1j = floor(Int64, xun[1, j] * scale)
        for i in 1:n
            xij = floor(Int64, xun[i, j] * scale)
            diff = (xij ⊻ x1j) / scale
            bvals[i, j] = bern(diff)
        end
    end

    # Cancellation-safe product
    Km1 = theta * const_mult .* bvals[:, 1]
    Kj = 1.0 .+ Km1
    for j in 2:d
        Km1 = theta * const_mult .* bvals[:, j] .* Kj .+ Km1
        Kj = 1.0 .+ Km1
    end

    lf = max(maximum(abs, Km1), eps(Float64))
    Km1 ./= lf

    # WHT eigenvalues (normalized)
    lam_ring = fwht(Km1)
    lam = copy(lam_ring)
    lam[1] += n / lf

    return abs.(lam), lam_ring, lf
end

# ── MLE objective (same structure as lattice, different kernel) ──────────────

function _mle_objective_net(
    theta::Float64,
    xun::AbstractMatrix,
    ftilde::Vector{Float64},
    order::Int,
    errbd_type::Symbol,
)
    n = length(ftilde)
    fudge = 100eps(Float64)

    lam, lam_ring, lf = _dsi_kernel_eigenvalues(xun, order, theta)

    temp = zeros(n)
    @inbounds for k in 1:n
        lam[k] > fudge && (temp[k] = ftilde[k]^2 / lam[k])
    end

    if errbd_type == :GCV
        temp_gcv = zeros(n)
        @inbounds for k in 1:n
            lam[k] > fudge && (temp_gcv[k] = (ftilde[k] / lam[k])^2)
        end
        RKHS_norm = sum(@view temp_gcv[2:end]) / (lf * n)
        loss =
            log(max(sum(@view temp_gcv[2:end]), eps(Float64))) -
            2log(max(sum(1.0/l for l in lam if l > fudge), eps(Float64)))
    else
        RKHS_norm = sum(@view temp[2:end]) / (lf * n)
        temp_1 = sum(@view temp[2:end]) / lf
        loss1 = sum(log(abs(lf * l)) for l in lam if l > fudge)
        loss2 = n * log(max(temp_1, eps(Float64)))
        loss = loss1 + loss2
    end

    return loss, lam .* lf, lam_ring .* lf, RKHS_norm
end

# ── Stopping criterion ───────────────────────────────────────────────────────

function _bayes_net_stop(xun, ftilde, n, order, errbd_type, alpha)
    uncert = errbd_type == :FULL ? -quantile(TDist(n-1), alpha/2) : -quantile(Normal(), alpha/2)

    best_lna, best_loss = -5.0, Inf
    for lna in range(-5.0, 0.0; length=21)
        l, _, _, _ = _mle_objective_net(exp(lna), xun, ftilde, order, errbd_type)
        isfinite(l) && l < best_loss && (best_loss=l; best_lna=lna)
    end
    step = 5.0 / 21
    for lna in range(best_lna - step, best_lna + step; length=21)
        l, _, _, _ = _mle_objective_net(exp(lna), xun, ftilde, order, errbd_type)
        isfinite(l) && l < best_loss && (best_loss=l; best_lna=lna)
    end

    _, lam, lam_ring, rkhs = _mle_objective_net(exp(best_lna), xun, ftilde, order, errbd_type)

    DSC = errbd_type == :FULL ? abs(lam_ring[1] / n) : abs(lam_ring[1] / (n + lam_ring[1]))

    err_bd =
        errbd_type == :FULL ? uncert * sqrt(abs(DSC * rkhs / (n - 1))) :
        uncert * sqrt(abs(DSC * rkhs / n))

    # `ftilde` is normalized as fwht(y) / sqrt(n), so the first coefficient is
    # sum(y) / sqrt(n). Divide by sqrt(n) again to recover the sample mean.
    return real(ftilde[1]) / sqrt(n), err_bd
end

# ── integrate ────────────────────────────────────────────────────────────────

function integrate(sc::CubQMCBayesNetG; resume::Union{Nothing, Dict{Symbol, Any}}=nothing)
    t_start = time()
    if resume !== nothing
        n_prev =
            haskey(resume, :n_per_rep) ? Int(resume[:n_per_rep]) :
            haskey(resume, :n) ? Int(resume[:n]) : Int(resume[:n_total])
        n = 2 * n_prev
    else
        n = sc.n_init
    end
    mu_hat = 0.0;
    err = Inf;
    n_iter = 0
    log = IterationLog()

    while n <= sc.n_max
        n_iter += 1
        dd = sc.integrand.true_measure.dd
        x_uniform = gen_samples(dd, n)

        x_period, weight = _periodize_with_weight(x_uniform, sc.ptransform)
        x_trans = transform(sc.integrand.true_measure, x_period)
        y = evaluate(sc.integrand, x_trans) .* weight

        # WHT of function values (normalized)
        ftilde = fwht(y) ./ sqrt(n)

        mu_hat, err = _bayes_net_stop(x_uniform, ftilde, n, sc.order, sc.errbd_type, sc.alpha)

        tol = max(sc.abs_tol, sc.rel_tol * abs(mu_hat))
        if sc.trace_iterations
            push!(log; n=n, solution=mu_hat, error_bound=err, tol=tol, elapsed=time() - t_start)
        end
        err <= tol && break

        2n > sc.n_max &&
            (@warn "CubQMCBayesNetG: n_max=$(sc.n_max) reached. err=$err tol=$tol"; break)
        n *= 2
    end

    data = Dict{Symbol, Any}(
        :n => n,
        :n_per_rep => n,
        :n_total => n,
        :error_bound => err,
        :n_iterations => n_iter,
        :converged => err <= max(sc.abs_tol, sc.rel_tol * abs(mu_hat)),
        :order => sc.order,
        :ptransform => sc.ptransform,
        :errbd_type => sc.errbd_type,
    )
    if sc.trace_iterations
        data[:iteration_log] = log
    end
    return QMCResult(mu_hat, data)
end

function Base.show(io::IO, sc::CubQMCBayesNetG)
    print(
        io,
        "CubQMCBayesNetG(abs_tol=$(sc.abs_tol), order=$(sc.order), ptransform=$(sc.ptransform))",
    )
end
