"""
    CustomFun(tm::AbstractTrueMeasure, g::Function)

User-supplied integrand. Wraps any function `g(x)` where `x` is a matrix
of transformed sample points (n×d). Returns a vector of length n.

# Examples
```jldoctest
julia> using QMC, Statistics

julia> f = CustomFun(
           Gaussian(DigitalNetB2(2; seed=7); mean=[1, 2]),
           t -> t[:, 1].^2 .* t[:, 2],
       )
CustomFun(d=2)

julia> y = sample_and_evaluate(f, 2^10);

julia> round(mean(y); digits=4)
3.9986
```

```jldoctest
julia> using QMC

julia> dd = IIDStdUniform(2; seed=7);

julia> tm = Uniform(dd; lower_bound=0.0, upper_bound=1.0);

julia> f = CustomFun(tm, x -> sum(x .^ 2, dims=2)[:])
CustomFun(d=2)

julia> round.(sample_and_evaluate(f, 3); digits=4)
3-element Vector{Float64}:
 0.4194
 1.1966
 0.9144
```
"""
struct CustomFun{TM <: AbstractTrueMeasure, G} <: AbstractIntegrand
    true_measure::TM
    g::G
    dimension::Int
end

CustomFun(tm::AbstractTrueMeasure, g::Function) = CustomFun(tm, g, dimension(tm))

function evaluate(f::CustomFun, x::AbstractMatrix)
    y = f.g(x)
    if y isa AbstractMatrix
        return vec(y)
    end
    return y isa Number ? fill(y, size(x, 1)) : collect(y)
end

Base.show(io::IO, f::CustomFun) = print(io, "CustomFun(d=$(f.dimension))")

"""
    sample_and_evaluate(f::AbstractIntegrand, n::Int; kwargs...)

Generate `n` samples, transform, and evaluate the integrand. Keyword arguments
are forwarded to `gen_samples`, e.g. `n_start` for extensible generators.
Returns a vector of function values.
"""
@inline function sample_and_evaluate(f::AbstractIntegrand, n::Int; kwargs...)
    x_uniform = _sample_uniform_points(discrete_distribution(f), n; kwargs...)
    return evaluate_on_uniform(f, x_uniform)
end

"""
    _sample_uniform_points(dd::AbstractDiscreteDistribution, n::Int; kwargs...)

Draw `n` points from the discrete distribution and flatten any replicated
`(R, n, d)` block to a plain `(R*n) × d` matrix. Exposed separately from
`sample_and_evaluate` so that several integrands (e.g. a main integrand and its
control variates) can be evaluated on the *same* point set.
"""
@inline function _sample_uniform_points(dd::AbstractDiscreteDistribution, n::Int; kwargs...)
    x_uniform = gen_samples(dd, n; kwargs...)
    if ndims(x_uniform) == 3
        R, m, d = size(x_uniform)
        x_uniform = reshape(x_uniform, R * m, d)
    end
    return x_uniform
end

"""
    evaluate_on_uniform(f::AbstractIntegrand, x_uniform::AbstractMatrix)

Apply the integrand's own true-measure transform to already-drawn uniform points
and evaluate. Pairs with [`_sample_uniform_points`](@ref) so the main integrand
and any control variates share an identical underlying point stream.
"""
@inline function evaluate_on_uniform(f::AbstractIntegrand, x_uniform::AbstractMatrix)
    x_transformed = transform(true_measure(f), x_uniform)
    return evaluate(f, x_transformed)
end
