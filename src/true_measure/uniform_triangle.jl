"""
    UniformTriangle(dd)

Uniform distribution on the triangle {(x,y) : 0 ≤ y ≤ x ≤ 1}.

Transforms 2D uniform samples to the simplex using the standard
square-root transformation.

Requires `dimension(dd) == 2`.

# Examples
```jldoctest
julia> using QuasiMC

julia> tm = UniformTriangle(IIDStdUniform(2; seed=7))
UniformTriangle()

julia> round.(transform(tm, gen_samples(tm.dd, 4)); digits=6)
4×2 Matrix{Float64}:
 0.601137  0.5536
 0.943441  0.631885
 0.717708  0.099473
 0.357784  0.240963
```
"""
struct UniformTriangle{D <: AbstractDiscreteDistribution} <: AbstractTrueMeasure
    dd::D
    function UniformTriangle(dd::D) where {D <: AbstractDiscreteDistribution}
        dimension(dd) == 2 || throw(ArgumentError("UniformTriangle requires dimension=2"))
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

Base.show(io::IO, ::UniformTriangle) = print(io, "UniformTriangle()")
