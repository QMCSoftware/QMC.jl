"""
    CubQMCLatticeG(integrand; abs_tol=0.01, rel_tol=0.0,
                   n_init=2^10, n_limit=2^30, fft_error_bound=true,
                   n_reps=16, alpha=0.01, trace_iterations=false)

Guaranteed QMC cubature using a randomized lattice rule.

When `fft_error_bound=true` (default), uses a single randomized lattice draw
and a Fourier-coefficient error bound (matching QMCPy's algorithm).  This is
fast: one batch of n function evaluations, one FFT, done.

When `fft_error_bound=false`, uses `n_reps` independent randomized replicates
and a Student-t confidence interval. Control variates always use the replication
path regardless of `fft_error_bound`.

For vector-valued integrands (`QuasiMC.d_indv(f) != ()`), returns a
[`QMCVecResult`](@ref) whose combined bounds are built through
`QuasiMC.bound_fun(f, low, high)`.

Pass `control_variates` (an integrand or vector of integrands sharing the main
integrand's discrete distribution and dimension) with their known
`control_variate_means` to apply linear control variates. Because control
variates are replication-based, the coefficients β are fit once on a dedicated
pilot draw and frozen, so the R per-replicate means stay i.i.d. and the
t-confidence interval remains valid.

Supports **resume** and optional **iteration logging** (`trace_iterations=true`).

# Example
```jldoctest
julia> using QuasiMC

julia> k = Keister(Gaussian(Lattice(1; seed=7); covariance=0.5));

julia> sc = CubQMCLatticeG(k; abs_tol=1e-3, rel_tol=0.0);

julia> result = integrate(sc);

julia> isapprox(result.solution, 1.38037385; atol=5e-3) # QMCPy reference
true
```

```jldoctest
julia> using QuasiMC

julia> f = BoxIntegral(QuasiMC.Uniform(Lattice(3; seed=11)); s=-1.0);

julia> abs_tol = 1e-3;

julia> sc = QuasiMC.CubQMCLatticeG(f; abs_tol=abs_tol, rel_tol=0.0);

julia> solution = QuasiMC.integrate(sc).solution;

julia> isapprox(solution, 1.18947477; atol=2e-3) # QMCPy doctest reference
true
```

```jldoctest
julia> using QuasiMC

julia> dd = Lattice(2; randomize=true, seed=77);

julia> g = CustomFun(Uniform(dd), x -> x[:, 1].^2 .+ x[:, 2])
CustomFun(d=2)

julia> result = integrate(CubQMCLatticeG(g; abs_tol=1e-3, control_variates=g, control_variate_means=5 / 6));

julia> isapprox(result.solution, 5 / 6; atol=1e-10)
true

julia> result.data[:error_bound] < 1e-10
true
```
"""
mutable struct CubQMCLatticeG{I <: AbstractIntegrand} <: AbstractStoppingCriterion
    integrand::I
    abs_tol::Float64
    rel_tol::Float64
    n_init::Int
    n_limit::Int
    n_reps::Int
    fft_error_bound::Bool
    alpha::Float64
    trace_iterations::Bool
    cv_spec::Union{Nothing, _ControlVariateSpec}
end

function CubQMCLatticeG(
    integrand::AbstractIntegrand;
    abs_tol::Float64=0.01,
    rel_tol::Float64=0.0,
    n_init::Int=2^10,
    n_limit::Int=2^30,
    n_reps::Int=16,
    fft_error_bound::Bool=true,
    alpha::Float64=0.01,
    trace_iterations::Bool=false,
    control_variates=nothing,
    control_variate_means=nothing,
)
    cv_spec = _make_control_variate_spec(integrand, control_variates, control_variate_means)
    return CubQMCLatticeG(
        integrand,
        abs_tol,
        rel_tol,
        n_init,
        n_limit,
        n_reps,
        fft_error_bound,
        alpha,
        trace_iterations,
        cv_spec,
    )
end

# ---------------------------------------------------------------------------
# FFT-based single-pass error bound (matches QMCPy's CubQMCLatticeG algorithm)
# ---------------------------------------------------------------------------

const _FFT_R_LAG = 4  # must be >= 1

# Reorder kappanumap so that within each level's window [nllstart, 2*nllstart),
# the most-energetic Fourier coefficients are surfaced first.
# Matches QMCPy's `_update_kappanumap` (1D case, 0-based kappanumap values).
#
# Algorithm per level l (mfrom down to mto+1):
#   1. Compare |ytilde[kappanumap[k]]| vs |ytilde[kappanumap[nl+k]]|
#      for k = 1..nl-1 using the first period before any swaps this level.
#   2. Apply the same swap pattern to every period of length 2*nl.
function _kappanumap_update!(
    kappanumap::Vector{Int},
    ytilde::Vector{ComplexF64},
    mfrom::Int,
    mto::Int,
    m::Int,
    flip_mask::Vector{Bool},
)
    n = 1 << m
    @inbounds for l in mfrom:-1:(mto + 1)
        nl = 1 << l
        period = nl << 1
        # Step 1: determine which k positions flip (from first period, before any swaps)
        for k in 1:(nl - 1)
            v1 = kappanumap[k + 1]      # 0-based value → ytilde[v+1]
            v2 = kappanumap[nl + k + 1]
            flip_mask[k] = abs(ytilde[v2 + 1]) > abs(ytilde[v1 + 1])
        end
        # Step 2: apply same flips to every period
        for k in 1:(nl - 1)
            flip_mask[k] || continue
            p = 0
            while p + nl + k < n
                pos1 = p + k + 1
                pos2 = p + nl + k + 1
                kappanumap[pos1], kappanumap[pos2] = kappanumap[pos2], kappanumap[pos1]
                p += period
            end
        end
    end
end

function _fft_error_bound_scalar(y::AbstractVector{<:Real})
    n = length(y)
    m = trailing_zeros(n)
    yvec = y isa Vector{Float64} ? y : Vector{Float64}(y)
    ytilde = bro_fft(yvec) ./ n

    kappanumap = collect(0:(n - 1))
    flip_mask = Vector{Bool}(undef, n >> 1)
    _kappanumap_update!(kappanumap, ytilde, m - 1, 0, m, flip_mask)

    nllstart = 1 << max(0, m - _FFT_R_LAG - 1)
    fudge = 5.0 * exp2(-m)
    # Python 0-indexed [nllstart:2*nllstart] → Julia 1-indexed [nllstart+1:2*nllstart]
    err = 0.0
    @inbounds for j in (nllstart + 1):(2 * nllstart)
        err += abs(ytilde[kappanumap[j] + 1])
    end
    err *= fudge

    mu = real(ytilde[1])
    return mu, err
end

function _integrate_cubqmclatticeg_fft(
    sc::CubQMCLatticeG,
    resume::Union{Nothing, Dict{Symbol, Any}},
)
    if resume !== nothing
        n_prev = haskey(resume, :n_per_rep) ? Int(resume[:n_per_rep]) : Int(resume[:n])
        n = 2 * n_prev
        prev_time = Float64(get(resume, :time_integrate, 0.0))
    else
        n = sc.n_init
        prev_time = 0.0
    end

    t_start = time()
    f = sc.integrand
    dd = discrete_distribution(f)
    tm = true_measure(f)
    log = IterationLog()

    mu_hat = 0.0
    err = Inf
    n_iter = 0
    converged = false
    # All iterations must use the SAME random shift for the FFT bound to be valid.
    locked_shift = nothing
    # kappanumap is updated INCREMENTALLY (QMCPy style): first call runs all levels
    # m-1..0; each subsequent doubling extends the map and runs only the new top level.
    kappanumap = Int[]
    ytilde = ComplexF64[]
    flip_mask = Vector{Bool}(undef, 0)

    while n <= sc.n_limit
        n_iter += 1

        # Apply locked shift (prevents gen_samples from regenerating a new one)
        if locked_shift !== nothing && dd isa Lattice
            dd.randomize = false
            dd.shift .= locked_shift
        end
        xu = gen_samples(dd, n)
        if dd isa Lattice
            dd.randomize = true
            locked_shift === nothing && (locked_shift = copy(dd.shift))
        end
        xu = ndims(xu) == 3 ? reshape(xu, size(xu, 1) * size(xu, 2), size(xu, 3)) : xu
        y_raw = evaluate(f, transform(tm, xu))
        y = y_raw isa Vector{Float64} ? y_raw : Vector{Float64}(vec(y_raw))

        m = trailing_zeros(n)
        ytilde_new = bro_fft(y) ./ n

        if isempty(kappanumap)
            # First call: initialize identity kappanumap and run ALL levels (mto=0)
            kappanumap = collect(0:(n - 1))
            length(flip_mask) < (n >> 1) && resize!(flip_mask, n >> 1)
            _kappanumap_update!(kappanumap, ytilde_new, m - 1, 0, m, flip_mask)
        else
            # Subsequent doubling: extend and update r_lag levels (mto = mllstart)
            n_old = length(kappanumap)
            append!(kappanumap, n_old .+ kappanumap)
            length(flip_mask) < (n >> 1) && resize!(flip_mask, n >> 1)
            mllstart = max(0, m - _FFT_R_LAG - 1)
            _kappanumap_update!(kappanumap, ytilde_new, m - 1, mllstart, m, flip_mask)
        end
        ytilde = ytilde_new

        nllstart = 1 << max(0, m - _FFT_R_LAG - 1)
        fudge = 5.0 * exp2(-m)
        err = 0.0
        @inbounds for j in (nllstart + 1):(2 * nllstart)
            err += abs(ytilde[kappanumap[j] + 1])
        end
        err *= fudge
        mu_hat = real(ytilde[1])
        tol = max(sc.abs_tol, sc.rel_tol * abs(mu_hat))

        if sc.trace_iterations
            push!(log; n=n, solution=mu_hat, error_bound=err, tol=tol, elapsed=time() - t_start)
        end

        converged = err <= tol
        converged && break
        n = min(2n, sc.n_limit + 1)
    end

    !converged && @warn "CubQMCLatticeG: did not converge within n_limit=$(sc.n_limit)."

    t_elapsed = time() - t_start
    data = Dict{Symbol, Any}(
        :n => n,
        :n_per_rep => n,
        :n_total => n,
        :n_reps => 1,
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

function _integrate_cubqmclatticeg_fft_multi(
    sc::CubQMCLatticeG,
    resume::Union{Nothing, Dict{Symbol, Any}},
)
    if resume !== nothing
        n_prev = haskey(resume, :n_per_rep) ? Int(resume[:n_per_rep]) : Int(resume[:n])
        n = 2 * n_prev
        prev_time = Float64(get(resume, :time_integrate, 0.0))
    else
        n = sc.n_init
        prev_time = 0.0
    end

    t_start = time()
    f = sc.integrand
    ishape = d_indv(f)
    cshape = d_comb(f)
    m_indv = prod(ishape)
    dd = discrete_distribution(f)
    tm = true_measure(f)
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
    locked_shift = nothing
    # Per-output kappanumap updated incrementally (one vector per integrand output)
    kappanumaps = [Int[] for _ in 1:m_indv]
    flip_mask = Vector{Bool}(undef, 0)

    while n <= sc.n_limit
        n_iter += 1

        if locked_shift !== nothing && dd isa Lattice
            dd.randomize = false
            dd.shift .= locked_shift
        end
        xu = gen_samples(dd, n)
        if dd isa Lattice
            dd.randomize = true
            locked_shift === nothing && (locked_shift = copy(dd.shift))
        end
        xu = ndims(xu) == 3 ? reshape(xu, size(xu, 1) * size(xu, 2), size(xu, 3)) : xu
        y_mat = reshape(evaluate(f, transform(tm, xu)), size(xu, 1), m_indv)

        m_bits = trailing_zeros(n)
        nllstart = 1 << max(0, m_bits - _FFT_R_LAG - 1)
        fudge = 5.0 * exp2(-m_bits)
        length(flip_mask) < (n >> 1) && resize!(flip_mask, n >> 1)
        first_iter = isempty(kappanumaps[1])

        @inbounds for j in 1:m_indv
            yj = @view y_mat[:, j]
            ytilde = bro_fft(collect(Float64, yj)) ./ n
            km = kappanumaps[j]
            if first_iter
                resize!(km, n)
                km .= 0:(n - 1)
                _kappanumap_update!(km, ytilde, m_bits - 1, 0, m_bits, flip_mask)
            else
                n_old = length(km)
                append!(km, n_old .+ km)
                mllstart_j = max(0, m_bits - _FFT_R_LAG - 1)
                _kappanumap_update!(km, ytilde, m_bits - 1, mllstart_j, m_bits, flip_mask)
            end
            err_j = 0.0
            for k in (nllstart + 1):(2 * nllstart)
                err_j += abs(ytilde[km[k] + 1])
            end
            err_j *= fudge
            solution_indv[j] = real(ytilde[1])
            indv_low[j] = solution_indv[j] - err_j
            indv_high[j] = solution_indv[j] + err_j
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
        n = min(2n, sc.n_limit + 1)
    end

    !converged && @warn "CubQMCLatticeG: did not converge within n_limit=$(sc.n_limit)."

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

# ---------------------------------------------------------------------------
# Replication-based multi-integrand path (used by control variates and when
# fft_error_bound=false)
# ---------------------------------------------------------------------------

function _integrate_cubqmclatticeg_multi(
    sc::CubQMCLatticeG,
    resume::Union{Nothing, Dict{Symbol, Any}},
)
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
    f = sc.integrand
    ishape = d_indv(f)
    cshape = d_comb(f)
    m_indv = prod(ishape)
    dd = discrete_distribution(f)
    tm = true_measure(f)
    log = IterationLog()
    cv = sc.cv_spec
    cv_beta = nothing

    if cv !== nothing
        xu_pilot = _sample_uniform_points(dd, sc.n_init)
        y_pilot = reshape(evaluate_on_uniform(f, xu_pilot), size(xu_pilot, 1), m_indv)
        ycv_pilot = _control_variate_values(cv, xu_pilot)
        cv_beta = _fit_control_variate_beta(y_pilot, ycv_pilot)
    end

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

    while n <= sc.n_limit
        n_iter += 1
        estimates = Matrix{Float64}(undef, R, m_indv)

        group_size = 4
        r0 = 1
        while r0 <= R
            g = min(group_size, R - r0 + 1)
            first = gen_samples(dd, n)
            first =
                ndims(first) == 3 ?
                reshape(first, size(first, 1) * size(first, 2), size(first, 3)) : first
            m_rows = size(first, 1)
            x_group = Matrix{Float64}(undef, g * m_rows, size(first, 2))
            @inbounds x_group[1:m_rows, :] .= first
            @inbounds for k in 2:g
                xu = gen_samples(dd, n)
                xu = ndims(xu) == 3 ? reshape(xu, size(xu, 1) * size(xu, 2), size(xu, 3)) : xu
                x_group[((k - 1) * m_rows + 1):(k * m_rows), :] .= xu
            end
            y_group = reshape(evaluate(f, transform(tm, x_group)), g * m_rows, m_indv)
            ycv_group = cv === nothing ? nothing : _control_variate_values(cv, x_group)
            @inbounds for k in 1:g
                rows = ((k - 1) * m_rows + 1):(k * m_rows)
                if cv === nothing
                    for j in 1:m_indv
                        estimates[r0 + k - 1, j] = mean(@view y_group[rows, j])
                    end
                else
                    cv_shift = vec(mean(@view ycv_group[rows, :]; dims=1)) .- cv.means
                    for j in 1:m_indv
                        est = mean(@view y_group[rows, j])
                        for ell in eachindex(cv.means)
                            est -= cv_beta[ell, j] * cv_shift[ell]
                        end
                        estimates[r0 + k - 1, j] = est
                    end
                end
            end
            r0 += g
        end

        @inbounds for j in 1:m_indv
            mu = mean(@view estimates[:, j])
            sigma_reps = std(@view estimates[:, j]; corrected=true)
            ci = t_crit * sigma_reps / sqrt(R)
            solution_indv[j] = mu
            indv_low[j] = mu - ci
            indv_high[j] = mu + ci
        end

        cl, ch = bound_fun(f, indv_low, indv_high)
        comb_low, comb_high, sol_comb, comb_flags, err_comb, tol_max =
            _combined_bounds_stats(sc.abs_tol, sc.rel_tol, cl, ch)
        converged = all(comb_flags)
        n_final = n

        if sc.trace_iterations
            push!(
                log;
                n=n * R,
                solution=sol_comb[1],
                error_bound=err_comb,
                tol=tol_max,
                elapsed=time() - t_start,
            )
        end

        converged && break
        n = min(2n, sc.n_limit + 1)
    end

    if !converged
        @warn "CubQMCLatticeG: did not converge within n_limit=$(sc.n_limit)."
    end

    t_elapsed = time() - t_start
    n_total = n_final * R
    data = Dict{Symbol, Any}(
        :n => n_final,
        :n_per_rep => n_final,
        :n_total => n_total,
        :n_reps => R,
        :n_indv => Array{Int}(reshape(fill(n_total, m_indv), ishape)),
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
    if cv_beta !== nothing
        data[:control_variate_beta] =
            Array{Float64}(reshape(vec(permutedims(cv_beta)), ishape..., length(cv.means)))
    end
    return QMCVecResult(Array{Float64}(reshape(sol_comb, cshape)), data)
end

function integrate(sc::CubQMCLatticeG; resume::Union{Nothing, Dict{Symbol, Any}}=nothing)
    # Control variates always use the replication path (they require i.i.d. replicates).
    use_reps = !sc.fft_error_bound || sc.cv_spec !== nothing

    if d_indv(sc.integrand) != ()
        return use_reps ? _integrate_cubqmclatticeg_multi(sc, resume) :
               _integrate_cubqmclatticeg_fft_multi(sc, resume)
    end

    use_reps && return _integrate_cubqmclatticeg_replication(sc, resume)
    return _integrate_cubqmclatticeg_fft(sc, resume)
end

# ---------------------------------------------------------------------------
# Replication-based scalar path
# ---------------------------------------------------------------------------

function _integrate_cubqmclatticeg_replication(
    sc::CubQMCLatticeG,
    resume::Union{Nothing, Dict{Symbol, Any}},
)
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
    f = sc.integrand
    tm = true_measure(f)
    dd = discrete_distribution(f)

    cv = sc.cv_spec
    cv_beta = nothing
    if cv !== nothing
        xu_pilot = _sample_uniform_points(dd, sc.n_init)
        y_pilot = evaluate_on_uniform(f, xu_pilot)
        ycv_pilot = _control_variate_values(cv, xu_pilot)
        cv_beta = _fit_control_variate_beta(y_pilot, ycv_pilot)
    end

    while n <= sc.n_limit
        n_iter += 1
        estimates = Vector{Float64}(undef, R)

        group_size = 4
        r0 = 1
        while r0 <= R
            g = min(group_size, R - r0 + 1)
            first = gen_samples(dd, n)
            first =
                ndims(first) == 3 ?
                reshape(first, size(first, 1) * size(first, 2), size(first, 3)) : first
            m = size(first, 1)
            x_group = Matrix{Float64}(undef, g * m, size(first, 2))
            @inbounds x_group[1:m, :] .= first
            @inbounds for k in 2:g
                xu = gen_samples(dd, n)
                xu = ndims(xu) == 3 ? reshape(xu, size(xu, 1) * size(xu, 2), size(xu, 3)) : xu
                x_group[((k - 1) * m + 1):(k * m), :] .= xu
            end
            y_group = evaluate(f, transform(tm, x_group))
            if cv === nothing
                @inbounds for k in 1:g
                    estimates[r0 + k - 1] = mean(@view y_group[((k - 1) * m + 1):(k * m)])
                end
            else
                ycv_group = _control_variate_values(cv, x_group)
                @inbounds for k in 1:g
                    rows = ((k - 1) * m + 1):(k * m)
                    est = mean(@view y_group[rows])
                    for j in eachindex(cv.means)
                        est -= cv_beta[j] * (mean(@view ycv_group[rows, j]) - cv.means[j])
                    end
                    estimates[r0 + k - 1] = est
                end
            end
            r0 += g
        end

        mu_hat = mean(estimates)
        sigma_reps = std(estimates; corrected=true)
        err = t_crit * sigma_reps / sqrt(R)
        tol = max(sc.abs_tol, sc.rel_tol * abs(mu_hat))

        if sc.trace_iterations
            push!(
                log;
                n=n * R,
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
        @warn "CubQMCLatticeG: did not converge within n_limit=$(sc.n_limit)."
    end

    t_elapsed = time() - t_start
    n_per_rep = n > sc.n_limit ? sc.n_limit : n
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
    if cv_beta !== nothing
        data[:control_variate_beta] = cv_beta
    end
    if sc.trace_iterations
        data[:iteration_log] = log
    end
    return QMCResult(mu_hat, data)
end

function Base.show(io::IO, sc::CubQMCLatticeG)
    mode = sc.fft_error_bound ? "fft" : "reps=$(sc.n_reps)"
    print(io, "CubQMCLatticeG(abs_tol=$(sc.abs_tol), $mode)")
end
