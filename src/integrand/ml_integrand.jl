"""
    AbstractMLIntegrand <: AbstractIntegrand

Abstract base for multilevel integrands used with multilevel Monte Carlo
and multilevel quasi-Monte Carlo stopping criteria.

A multilevel integrand must implement:

- `ml_evaluate(f, x, level)` — evaluate the integrand at transformed sample
  points `x` (n×d matrix) and return `(Qcoarse, Qfine)` where each is a
  vector of length n. At level 0, `Qcoarse` should be zero.

- `dimension_at_level(f, level)` — return the stochastic dimension needed
  at the given level.

- `cost_at_level(f, level)` — return the computational cost per sample at
  the given level (default: `2^level`).

The multilevel stopping criteria use the telescoping sum:
    E[Q_L] = E[Q_0] + Σ_{l=1}^{L} E[Q_l - Q_{l-1}]

Each term E[Q_l - Q_{l-1}] is estimated independently using the
level-difference samples returned by `ml_evaluate`.
"""
abstract type AbstractMLIntegrand <: AbstractIntegrand end

"""
    ml_evaluate(f::AbstractMLIntegrand, x::AbstractMatrix, level::Int)

Evaluate the multilevel integrand at level `level` with transformed sample
points `x` (n×d matrix). Returns `(Qcoarse, Qfine)` vectors of length n.

At level 0, `Qcoarse` must be a zero vector.
"""
function ml_evaluate end

"""
    dimension_at_level(f::AbstractMLIntegrand, level::Int)

Return the stochastic dimension needed at the given level.
Default implementation returns `f.dimension` (same dimension at all levels).
"""
dimension_at_level(f::AbstractMLIntegrand, level::Int) = f.dimension

"""
    cost_at_level(f::AbstractMLIntegrand, level::Int)

Return the computational cost per sample at the given level.
Default: `2^level` (doubling cost per level).
"""
cost_at_level(f::AbstractMLIntegrand, level::Int) = Float64(2^level)

# ── Discrete Distribution Spawning ──

"""
    spawn_dd(dd::IIDStdUniform, dimension::Int)

Create a new IID uniform sampler with the given dimension and a fresh seed.
"""
spawn_dd(dd::IIDStdUniform, dimension::Int) = IIDStdUniform(dimension)

"""
    spawn_dd(dd::Lattice, dimension::Int)

Create a new Lattice sampler with the given dimension, preserving randomize
and replications settings but with a fresh seed.
"""
function spawn_dd(dd::Lattice, dimension::Int)
    R = isnothing(dd.replications) ? nothing : dd.replications
    return Lattice(dimension; randomize=dd.randomize, replications=R)
end

"""
    spawn_dd(dd::DigitalNetB2, dimension::Int)

Create a new DigitalNetB2 sampler with the given dimension, preserving
randomize and replications settings but with a fresh seed.
"""
function spawn_dd(dd::DigitalNetB2, dimension::Int)
    R = isnothing(dd.replications) ? nothing : dd.replications
    raw_dimension = Base.checked_mul(dimension, dd.alpha)
    if raw_dimension <= size(dd.direction_nums, 1)
        return DigitalNetB2(
            dimension;
            randomize=dd.randomize,
            graycode=dd.graycode,
            replications=R,
            t=dd.t,
            alpha=dd.alpha,
            generating_matrices=dd.direction_nums,
        )
    end
    return DigitalNetB2(
        dimension;
        randomize=dd.randomize,
        graycode=dd.graycode,
        replications=R,
        t=dd.t,
        alpha=dd.alpha,
    )
end

"""
    spawn_dd(dd::Halton, dimension::Int)

Create a new Halton sampler with the given dimension and fresh seed.
"""
spawn_dd(dd::Halton, dimension::Int) = Halton(dimension; randomize=dd.randomize)

# ── True Measure Spawning ──

"""
    spawn_tm(tm::Gaussian, dd_new::AbstractDiscreteDistribution)

Create a new Gaussian true measure wrapping `dd_new` with standard parameters
(mean=0, covariance=I, PCA decomposition).
"""
spawn_tm(tm::Gaussian, dd_new::AbstractDiscreteDistribution) = Gaussian(dd_new)

"""
    spawn_tm(tm::Uniform, dd_new::AbstractDiscreteDistribution)

Create a new Uniform true measure wrapping `dd_new` with matching bounds.
"""
function spawn_tm(tm::Uniform, dd_new::AbstractDiscreteDistribution)
    d_new = dd_new.dimension
    lb = length(tm.lower_bound) == 1 ? tm.lower_bound[1] : tm.lower_bound[1]
    ub = length(tm.upper_bound) == 1 ? tm.upper_bound[1] : tm.upper_bound[1]
    return Uniform(dd_new; lower_bound=lb, upper_bound=ub)
end

"""
    spawn_tm(tm::BrownianMotion, dd_new::AbstractDiscreteDistribution)

Create a new BrownianMotion true measure wrapping `dd_new`.
"""
function spawn_tm(tm::BrownianMotion, dd_new::AbstractDiscreteDistribution)
    t_final = tm.time_vector[end]
    tv_new = collect(range(t_final / dd_new.dimension, t_final; length=dd_new.dimension))
    return BrownianMotion(dd_new; time_vector=tv_new, drift=tm.drift)
end

"""
    spawn_tm(tm::GeometricBrownianMotion, dd_new::AbstractDiscreteDistribution)

Create a new GeometricBrownianMotion true measure wrapping `dd_new`.
"""
function spawn_tm(tm::GeometricBrownianMotion, dd_new::AbstractDiscreteDistribution)
    return GeometricBrownianMotion(
        dd_new;
        t_final=tm.time_vector[end],
        initial_value=tm.initial_value,
        drift=tm.drift,
        diffusion=tm.diffusion,
    )
end

# ── Spawning a Multilevel Integrand at a Specific Level ──

"""
    spawn_integrand(f::AbstractMLIntegrand, level::Int)

Create a new instance of the multilevel integrand at the given level.
This creates a new discrete distribution and true measure with the
appropriate dimension for that level.

Returns `(integrand_at_level, true_measure_at_level, dd_at_level)`.
"""
function spawn_integrand(f::AbstractMLIntegrand, level::Int)
    d_level = dimension_at_level(f, level)
    dd_new = spawn_dd(f.true_measure.dd, d_level)
    tm_new = spawn_tm(f.true_measure, dd_new)
    return dd_new, tm_new
end

# ── Multilevel sample_and_evaluate ──

"""
    ml_sample_and_evaluate(f::AbstractMLIntegrand, dd, tm, n::Int, level::Int)

Generate `n` samples from `dd`, transform via `tm`, and evaluate the
multilevel integrand at the given level. Returns `(dp, cost)` where
`dp = Qfine - Qcoarse` is the level-difference vector of length n,
and `cost` is the total cost for this batch.
"""
function ml_sample_and_evaluate(
    f::AbstractMLIntegrand,
    dd::AbstractDiscreteDistribution,
    tm::AbstractTrueMeasure,
    n::Int,
    level::Int,
)
    x_uniform = gen_samples(dd, n)
    if ndims(x_uniform) == 3
        R, m, d = size(x_uniform)
        x_uniform = reshape(x_uniform, R * m, d)
    end
    x_transformed = transform(tm, x_uniform)
    Qc, Qf = ml_evaluate(f, x_transformed, level)
    dp = Qf .- Qc
    cost = cost_at_level(f, level) * n
    return dp, cost
end

"""
    ml_sample_and_evaluate_reps(f::AbstractMLIntegrand,
                                 dd::AbstractDiscreteDistribution,
                                 tm::AbstractTrueMeasure,
                                 n::Int, level::Int, R::Int)

Generate `R` replications of `n` samples each, transform via `tm`, and
evaluate the multilevel integrand. Returns `(rep_means, cost)` where
`rep_means` is a length-R vector of replication means of Q_fine - Q_coarse,
and `cost` is the total cost.
"""
function ml_sample_and_evaluate_reps(
    f::AbstractMLIntegrand,
    dd::AbstractDiscreteDistribution,
    tm::AbstractTrueMeasure,
    n::Int,
    level::Int,
    R::Int,
)
    rep_means = zeros(R)
    total_cost = 0.0
    for r in 1:R
        dp, c = ml_sample_and_evaluate(f, dd, tm, n, level)
        rep_means[r] = mean(dp)
        total_cost += c
    end
    return rep_means, total_cost
end
