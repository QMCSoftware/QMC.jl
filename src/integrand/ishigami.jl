"""
    Ishigami(tm::AbstractTrueMeasure; a=7.0, b=0.1)

Ishigami test function for sensitivity analysis:

    f(t₁, t₂, t₃) = sin(t₁) + a sin²(t₂) + b t₃⁴ sin(t₁)

where t ∈ U(-π, π)³.

The true measure should map uniform [0,1]³ samples to (-π, π)³.

# Exact Sobol' indices (known analytically)
The exact mean, variance, and Sobol' indices are computable in closed form
for given a, b.

# Examples
```jldoctest
julia> using QuasiMC, Statistics

julia> f = Ishigami(Uniform(DigitalNetB2(3; seed=7); lower_bound=-π, upper_bound=π))
Ishigami(a=7.0, b=0.1)

julia> y = sample_and_evaluate(f, 2^12);

julia> round(mean(y); digits=4)
3.5

julia> ref = ishigami_exact();

julia> round(ref.mean; digits=4)
3.5

julia> round.(ref.closed; digits=4)
3-element Vector{Float64}:
 0.3139
 0.4424
 0.0

julia> round.(ref.total; digits=4)
3-element Vector{Float64}:
 0.5576
 0.4424
 0.2437
```
"""
struct Ishigami{TM <: AbstractTrueMeasure} <: AbstractIntegrand
    true_measure::TM
    dimension::Int
    a::Float64
    b::Float64
end

function Ishigami(tm::AbstractTrueMeasure; a::Float64=7.0, b::Float64=0.1)
    d = dimension(tm)
    d >= 3 || throw(ArgumentError("Ishigami requires dimension at least 3, got $d"))
    return Ishigami(tm, 3, a, b)
end

function evaluate(f::Ishigami, x::AbstractMatrix)
    n = size(x, 1)
    a = f.a
    b = f.b
    y = Vector{Float64}(undef, n)
    @inbounds for i in 1:n
        t1 = x[i, 1]
        t2 = x[i, 2]
        t3 = x[i, 3]
        y[i] = sin(t1) + a * sin(t2)^2 + b * t3^4 * sin(t1)
    end
    return y
end

Base.show(io::IO, f::Ishigami) = print(io, "Ishigami(a=$(f.a), b=$(f.b))")

"""
    ishigami_exact(; a=7.0, b=0.1) -> NamedTuple

Closed-form reference values for the Ishigami function with parameters `a`, `b`
on U(-π, π)³: the `mean`, `variance`, and the first-order (`closed`) and `total`
Sobol' sensitivity indices for the three inputs (as length-3 vectors).

Mirrors QMCPy's `Ishigami._exact_sensitivity_indices` for the singleton subsets.
Useful as an analytical reference when validating [`SensitivityIndices`](@ref).

```jldoctest
julia> using QuasiMC

julia> ref = ishigami_exact();

julia> round(ref.mean; digits=4)
3.5

julia> round.(ref.closed; digits=4)
3-element Vector{Float64}:
 0.3139
 0.4424
 0.0

julia> round.(ref.total; digits=4)
3-element Vector{Float64}:
 0.5576
 0.4424
 0.2437
```
"""
function ishigami_exact(; a::Float64=7.0, b::Float64=0.1)
    mu = a / 2
    m2 = 1 / 2 + 3 / 8 * a^2 + π^4 / 5 * b + π^8 / 18 * b^2
    var = m2 - mu^2
    closed = [(5 + π^4 * b)^2 / 50, a^2 / 8, 0.0] ./ var
    total = [(45 + 18 * π^4 * b + 5 * π^8 * b^2) / 90, a^2 / 8, 8 * π^8 / 225 * b^2] ./ var
    return (mean=mu, variance=var, closed=closed, total=total)
end

export ishigami_exact
