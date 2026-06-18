"""
    JohnsonsSU(dd; xi=1.0, lambda=2.0, gamma=1.0, delta=2.0)

Johnson's SU distribution measure via inverse CDF.

Transform:  z = ξ + λ sinh((Φ⁻¹(u) - γ) / δ)

where Φ⁻¹ is the standard normal quantile function.

# Arguments
- `dd`: discrete distribution.
- `xi`: location parameter ξ (scalar or d-vector). Default `1.0`.
- `lambda`: scale parameter λ > 0 (scalar or d-vector). Default `2.0`
  (QMCPy's `lam`).
- `gamma`: shape parameter γ (scalar or d-vector). Default `1.0`.
- `delta`: shape parameter δ > 0 (scalar or d-vector). Default `2.0`.

The defaults match QMC v2.3 (`gamma=1, xi=1, delta=2, lam=2`); QMC.jl's `lambda`
corresponds to QMCPy's `lam`.

# Examples
```jldoctest
julia> using QMC

julia> dd = DigitalNetB2(2; seed=7);

julia> tm = JohnsonsSU(dd; xi=2.0, lambda=4.0, gamma=1.0, delta=3.0)
JohnsonsSU(d=2)

julia> round.(transform(tm, gen_samples(dd, 4)); digits=6)
4×2 Matrix{Float64}:
  2.03858    0.105267
  0.079548   2.07577
  0.987912  -1.29824
 -1.36142    1.01091
```
"""
struct JohnsonsSU{D <: AbstractDiscreteDistribution} <: AbstractTrueMeasure
    dd::D
    dimension::Int
    xi::Vector{Float64}
    lambda::Vector{Float64}
    gamma::Vector{Float64}
    delta::Vector{Float64}
end

function JohnsonsSU(dd::AbstractDiscreteDistribution; xi=1.0, lambda=2.0, gamma=1.0, delta=2.0)
    d = dimension(dd)
    _xi = xi isa Number ? fill(Float64(xi), d) : Float64.(collect(xi))
    _lam = lambda isa Number ? fill(Float64(lambda), d) : Float64.(collect(lambda))
    _gam = gamma isa Number ? fill(Float64(gamma), d) : Float64.(collect(gamma))
    _del = delta isa Number ? fill(Float64(delta), d) : Float64.(collect(delta))
    all(_lam .> 0) || throw(ArgumentError("lambda must be positive"))
    all(_del .> 0) || throw(ArgumentError("delta must be positive"))
    return JohnsonsSU(dd, d, _xi, _lam, _gam, _del)
end

function transform(tm::JohnsonsSU, x::AbstractMatrix)
    # Phi^-1(u) = sqrt(2) * erfinv(2u - 1): the same fast standard-normal quantile the Gaussian
    # transform uses, applied over the whole n x d input as a fused broadcast rather
    # than a per-element Distributions.quantile call. The Johnson S_u map
    # y = xi + lambda * sinh((Phi^-1(u) - gamma)/delta) is then broadcast column-wise
    # (parameters are 1 x d rows). Numerically equivalent to the scalar form.
    xi = transpose(tm.xi)
    lam = transpose(tm.lambda)
    gam = transpose(tm.gamma)
    del = transpose(tm.delta)
    z = @. sqrt(2.0) * SpecialFunctions.erfinv(2.0 * _open_unit_interval(x) - 1.0)
    return @. xi + lam * sinh((z - gam) / del)
end

Base.show(io::IO, tm::JohnsonsSU) = print(io, "JohnsonsSU(d=$(tm.dimension))")
