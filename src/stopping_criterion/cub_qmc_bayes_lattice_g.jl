"""
    CubQMCBayesLatticeG(integrand; abs_tol=0.01, rel_tol=0.0,
                        n_init=2^8, n_max=2^22, order=2,
                        ptransform=:C1SIN, errbd_type=:MLE, alpha=0.01,
                        trace_iterations=false)

Bayesian QMC cubature for lattice rules with shift-invariant kernels.

Uses a Bernoulli-polynomial-based shift-invariant kernel diagonalized by FFT.
The shape parameter θ is estimated via MLE or GCV. A periodization transform
(default C1SIN) is applied to improve convergence for non-periodic integrands.

For vector-valued integrands (`QMC.d_indv(f) != ()`), returns a
[`QMCVecResult`](@ref) whose combined bounds are built through
`QMC.bound_fun(f, low, high)`.

Set `trace_iterations=true` to record an `IterationLog` in
`result.data[:iteration_log]`.

# Examples
```jldoctest
julia> using QMC

julia> k = Keister(Gaussian(Lattice(2; seed=123456789); covariance=0.5))
Keister(d=2)

julia> result = integrate(CubQMCBayesLatticeG(k; abs_tol=1e-4));

julia> abs(result.solution - keister_exact(2)) < 5e-4
true
```

```jldoctest
julia> using QMC

julia> f = Genz(Uniform(Lattice(2; randomize=true, seed=7)); kind=:continuous, a=[1.0, 1.0], u=[0.5, 0.5])
Genz(:continuous, d=2)

julia> sc = CubQMCBayesLatticeG(f; abs_tol=0.1, n_init=2^8, n_max=2^12)
CubQMCBayesLatticeG(abs_tol=0.1, order=2, ptransform=C1SIN)

julia> result = integrate(sc);

julia> abs(result.solution - genz_exact(f)) < 0.1
true

julia> result.data[:converged]
true
```

```jldoctest
julia> using QMC

julia> f = Genz(Uniform(Lattice(2; randomize=true, seed=7)); kind=:continuous, a=[1.0, 1.0], u=[0.5, 0.5]);

julia> r1 = integrate(CubQMCBayesLatticeG(f; abs_tol=0.1, n_init=2^8, n_max=2^12, ptransform=:C1));

julia> isfinite(r1.solution)
true

julia> r2 = integrate(CubQMCBayesLatticeG(f; abs_tol=0.1, n_init=2^8, n_max=2^12, ptransform=:C2SIN));

julia> isfinite(r2.solution)
true

julia> r3 = integrate(CubQMCBayesLatticeG(f; abs_tol=0.1, n_init=2^8, n_max=2^12, ptransform=:C3));

julia> isfinite(r3.solution)
true
```
"""
mutable struct CubQMCBayesLatticeG{I <: AbstractIntegrand} <: AbstractStoppingCriterion
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

function CubQMCBayesLatticeG(
    integrand::AbstractIntegrand;
    abs_tol::Float64=0.01,
    rel_tol::Float64=0.0,
    n_init::Int=2^8,
    n_max::Int=2^22,
    order::Int=2,
    ptransform::Symbol=:C1SIN,
    errbd_type::Symbol=:MLE,
    alpha::Float64=0.01,
    trace_iterations::Bool=false,
)
    @assert ispow2(n_init) "n_init must be a power of 2"
    @assert ispow2(n_max) "n_max must be a power of 2"
    @assert order in (1, 2, 3) "order must be 1, 2, or 3"
    @assert errbd_type in (:MLE, :GCV, :FULL) "errbd_type must be :MLE, :GCV, or :FULL"
    @assert 0 < alpha < 1
    return CubQMCBayesLatticeG(
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

# ── Shift-invariant kernel for lattice rules ─────────────────────────────────

"""
Compute kernel eigenvalues with cancellation-avoidance.

Returns `(vec_lambda, vec_lambda_ring, lambda_factor)`.
`vec_lambda_ring` = eigenvalues of (K - 1) before rescaling.
"""
function _si_kernel_eigenvalues(xun::AbstractMatrix, order::Int, theta::Float64)
    n, d = size(xun)
    b_order = 2 * order
    const_mult = -(-1.0)^(b_order ÷ 2)

    bern = if b_order == 2
        x -> -x*(1.0-x) + 1.0/6.0
    elseif b_order == 4
        x -> (x*(1.0-x))^2 - 1.0/30.0
    else  # b_order == 6
        x -> let t = mod(x, 1.0)
            t^6 - 3t^5 + 2.5t^4 - 0.5t^2 + 1.0/42.0
        end
    end

    # Evaluate Bernoulli on each coordinate
    bvals = Matrix{Float64}(undef, n, d)
    @inbounds for j in 1:d, i in 1:n
        bvals[i, j] = bern(mod(xun[i, j], 1.0))
    end

    # Cancellation-safe product: ∏(1 + θ·c·B_j) decomposed as 1 + Km1
    Km1 = theta * const_mult .* bvals[:, 1]
    Kj = 1.0 .+ Km1
    for j in 2:d
        Km1_prev = Km1
        Kj_prev = Kj
        Km1 = theta * const_mult .* bvals[:, j] .* Kj_prev .+ Km1_prev
        Kj = 1.0 .+ Km1
    end

    lf = max(maximum(abs, Km1), eps(Float64))
    Km1 ./= lf

    lam_ring = real.(FFTW.fft(Km1)) .* sqrt(n)
    lam = copy(lam_ring)
    lam[1] += n / lf

    return abs.(lam), lam_ring, lf
end

# ── MLE / GCV objective ─────────────────────────────────────────────────────

function _mle_objective(
    theta::Float64,
    xun::AbstractMatrix,
    ftilde::Vector{Float64},
    order::Int,
    errbd_type::Symbol,
)
    n = length(ftilde)
    fudge = 100eps(Float64)

    lam, lam_ring, lf = _si_kernel_eigenvalues(xun, order, theta)

    # Squared-ratio vector
    temp = zeros(n)
    @inbounds for k in 1:n
        if lam[k] > fudge
            temp[k] = ftilde[k]^2 / lam[k]
        end
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
    else  # MLE (default)
        RKHS_norm = sum(@view temp[2:end]) / (lf * n)
        temp_1 = sum(@view temp[2:end]) / lf
        loss1 = sum(log(abs(lf * l)) for l in lam if l > fudge)
        loss2 = n * log(max(temp_1, eps(Float64)))
        loss = loss1 + loss2
    end

    return loss, lam .* lf, lam_ring .* lf, RKHS_norm
end

# ── Stopping criterion ───────────────────────────────────────────────────────

function _bayes_lattice_stop(xun, ftilde, n, order, errbd_type, alpha)
    uncert = errbd_type == :FULL ? -quantile(TDist(n-1), alpha/2) : -quantile(Normal(), alpha/2)

    # Grid search for optimal log(θ) in [-5, 0]
    best_lna, best_loss = -5.0, Inf
    for lna in range(-5.0, 0.0; length=21)
        l, _, _, _ = _mle_objective(exp(lna), xun, ftilde, order, errbd_type)
        if isfinite(l) && l < best_loss
            best_loss = l;
            best_lna = lna
        end
    end
    step = 5.0 / 21
    for lna in range(best_lna - step, best_lna + step; length=21)
        l, _, _, _ = _mle_objective(exp(lna), xun, ftilde, order, errbd_type)
        if isfinite(l) && l < best_loss
            best_loss = l;
            best_lna = lna
        end
    end

    _, lam, lam_ring, rkhs = _mle_objective(exp(best_lna), xun, ftilde, order, errbd_type)

    DSC = if errbd_type == :FULL
        abs(lam_ring[1] / n)
    else
        abs(lam_ring[1] / (n + lam_ring[1]))
    end

    err_bd = if errbd_type == :FULL
        uncert * sqrt(abs(DSC * rkhs / (n - 1)))
    else
        uncert * sqrt(abs(DSC * rkhs / n))
    end

    # `ftilde` is normalized as fft(y) / sqrt(n), so the zero-frequency term is
    # sum(y) / sqrt(n). Divide by sqrt(n) again to recover the sample mean.
    muhat = real(ftilde[1]) / sqrt(n)
    return muhat, err_bd
end

# ── integrate ────────────────────────────────────────────────────────────────

function _integrate_cubqmcbayeslatticeg_multi(
    sc::CubQMCBayesLatticeG,
    resume::Union{Nothing, Dict{Symbol, Any}},
)
    t_start = time()
    if resume !== nothing
        n_prev =
            haskey(resume, :n_per_rep) ? Int(resume[:n_per_rep]) :
            haskey(resume, :n) ? Int(resume[:n]) : Int(resume[:n_total])
        n = 2 * n_prev
        prev_time = Float64(get(resume, :time_integrate, 0.0))
    else
        n = sc.n_init
        prev_time = 0.0
    end
    f = sc.integrand
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
        dd = discrete_distribution(f)
        x_uniform = gen_samples(dd, n)

        x_period, weight = _periodize_with_weight(x_uniform, sc.ptransform)
        x_trans = transform(true_measure(f), x_period)
        Y = reshape(evaluate(f, x_trans), n, m_indv)
        Y .*= reshape(weight, n, 1)

        @inbounds for j in 1:m_indv
            ftilde = real.(FFTW.fft(@view Y[:, j])) ./ sqrt(n)
            mu, err =
                _bayes_lattice_stop(x_uniform, ftilde, n, sc.order, sc.errbd_type, sc.alpha)
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
        2n > sc.n_max && (
            @warn "CubQMCBayesLatticeG: n_max=$(sc.n_max) reached. err=$err_comb tol=$tol_max";
            break
        )
        n *= 2
    end

    t_elapsed = time() - t_start
    data = Dict{Symbol, Any}(
        :n => n_final,
        :n_per_rep => n_final,
        :n_total => n_final,
        :n_indv => Array{Int}(reshape(fill(n_final, m_indv), ishape)),
        :error_bound => err_comb,
        :n_iterations => n_iter,
        :converged => converged,
        :time_integrate => prev_time + t_elapsed,
        :order => sc.order,
        :ptransform => sc.ptransform,
        :errbd_type => sc.errbd_type,
        :solution_indv => Array{Float64}(reshape(copy(solution_indv), ishape)),
        :comb_bound_low => Array{Float64}(reshape(comb_low, cshape)),
        :comb_bound_high => Array{Float64}(reshape(comb_high, cshape)),
    )
    if sc.trace_iterations
        data[:iteration_log] = log
    end
    return QMCVecResult(Array{Float64}(reshape(sol_comb, cshape)), data)
end

function integrate(sc::CubQMCBayesLatticeG; resume::Union{Nothing, Dict{Symbol, Any}}=nothing)
    if d_indv(sc.integrand) != ()
        return _integrate_cubqmcbayeslatticeg_multi(sc, resume)
    end
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
    f = sc.integrand
    dd = discrete_distribution(f)
    tm = true_measure(f)

    while n <= sc.n_max
        n_iter += 1
        x_uniform = gen_samples(dd, n)

        # Periodization changes variables in the unit cube, so preserve the
        # original integral by multiplying the integrand by the product Jacobian.
        x_period, weight = _periodize_with_weight(x_uniform, sc.ptransform)
        x_trans = transform(tm, x_period)
        y = evaluate(f, x_trans) .* weight

        ftilde = real.(FFTW.fft(y)) ./ sqrt(n)

        mu_hat, err =
            _bayes_lattice_stop(x_uniform, ftilde, n, sc.order, sc.errbd_type, sc.alpha)

        tol = max(sc.abs_tol, sc.rel_tol * abs(mu_hat))
        if sc.trace_iterations
            push!(log; n=n, solution=mu_hat, error_bound=err, tol=tol, elapsed=time() - t_start)
        end
        err <= tol && break

        2n > sc.n_max &&
            (@warn "CubQMCBayesLatticeG: n_max=$(sc.n_max) reached. err=$err tol=$tol"; break)
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

function Base.show(io::IO, sc::CubQMCBayesLatticeG)
    print(
        io,
        "CubQMCBayesLatticeG(abs_tol=$(sc.abs_tol), order=$(sc.order), ptransform=$(sc.ptransform))",
    )
end
