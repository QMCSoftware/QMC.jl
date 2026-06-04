"""
    CustomFun(tm::AbstractTrueMeasure, g::Function)

User-supplied integrand. Wraps any function `g(x)` where `x` is a matrix
of transformed sample points (n×d). Returns a vector of length n.

# Example
```julia
dd = IIDStdUniform(2)
tm = Uniform(dd; lower_bound=0.0, upper_bound=1.0)
f = CustomFun(tm, x -> sum(x .^ 2, dims=2)[:])
```
"""
struct CustomFun{TM <: AbstractTrueMeasure, G} <: AbstractIntegrand
    true_measure::TM
    g::G
    dimension::Int
end

CustomFun(tm::AbstractTrueMeasure, g::Function) = CustomFun(tm, g, tm.dimension)

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
function sample_and_evaluate(f::AbstractIntegrand, n::Int; kwargs...)
    dd = f.true_measure.dd
    x_uniform = gen_samples(dd, n; kwargs...)
    if ndims(x_uniform) == 3
        # Replicated sampler: (R, n, d) → (R*n, d) so transform accepts a matrix.
        R, m, d = size(x_uniform)
        x_uniform = reshape(x_uniform, R * m, d)
    end
    x_transformed = transform(f.true_measure, x_uniform)
    return evaluate(f, x_transformed)
end
