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
struct CustomFun <: AbstractIntegrand
    true_measure::AbstractTrueMeasure
    g::Function
    dimension::Int
end

function CustomFun(tm::AbstractTrueMeasure, g::Function)
    return CustomFun(tm, g, tm.dimension)
end

function evaluate(f::CustomFun, x::AbstractMatrix)
    y = f.g(x)
    if y isa AbstractMatrix
        return vec(y)
    end
    return y isa Number ? fill(y, size(x, 1)) : collect(y)
end

function Base.show(io::IO, f::CustomFun)
    print(io, "CustomFun(d=$(f.dimension))")
end

"""
    sample_and_evaluate(f::AbstractIntegrand, n::Int)

Generate `n` samples, transform, and evaluate the integrand. Returns a vector of function values.
"""
function sample_and_evaluate(f::AbstractIntegrand, n::Int)
    dd = f.true_measure.dd
    x_uniform = gen_samples(dd, n)
    x_transformed = transform(f.true_measure, x_uniform)
    return evaluate(f, x_transformed)
end
