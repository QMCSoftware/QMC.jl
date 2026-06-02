"""
    UniformTriangle(dd)

Uniform distribution on the triangle {(x,y) : 0 ≤ y ≤ x ≤ 1}.

Transforms 2D uniform samples to the simplex using the standard
square-root transformation.

Requires `dd.dimension == 2`.

# Example
```julia
dd = IIDStdUniform(2; seed=7)
tm = UniformTriangle(dd)
x = transform(tm, gen_samples(dd, 1000))
# x[:,1] >= x[:,2] and both in [0,1]
```
"""
struct UniformTriangle{D <: AbstractDiscreteDistribution} <: AbstractTrueMeasure
    dd::D
    function UniformTriangle(dd::D) where {D <: AbstractDiscreteDistribution}
        dd.dimension == 2 || throw(ArgumentError("UniformTriangle requires dimension=2"))
        return new{D}(dd)
    end
end

function transform(tm::UniformTriangle, x::AbstractMatrix)
    u1 = x[:, 1]
    u2 = x[:, 2]
    # Standard simplex transform: x = max(u1,u2), y = min(u1,u2)
    out = similar(x)
    out[:, 1] = max.(u1, u2)
    out[:, 2] = min.(u1, u2)
    return out
end

function Base.show(io::IO, ::UniformTriangle)
    print(io, "UniformTriangle()")
end
