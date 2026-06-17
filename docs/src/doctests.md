# Doctests

This page contains small `jldoctest` examples that mirror common QMCPy-style
usage patterns, but in Julia syntax. The examples use deterministic seeds and
either exact printed values or numerical checks against known references.

## Digital Net Samples

This is the Julia analogue of drawing a small Sobol'-style digital net sample
set from QMCPy.

```jldoctest
julia> using QMC

julia> dd = DigitalNetB2(3; seed=7);

julia> round.(gen_samples(dd, 4); digits=6)
4×3 Matrix{Float64}:
 0.848245  0.354704  0.359693
 0.348245  0.854704  0.859693
 0.598245  0.104704  0.609693
 0.098245  0.604704  0.109693
```

## Gaussian Transform

This mirrors the QMCPy pattern of drawing uniform samples first and then
transforming them through a true measure.

```jldoctest
julia> using QMC

julia> dd = IIDStdUniform(2; seed=42);

julia> tm = Gaussian(dd; mean=[1.0, 2.0], covariance=[1.0 0.5; 0.5 1.0]);

julia> x = gen_samples(dd, 3);

julia> round.(transform(tm, x); digits=6)
3×2 Matrix{Float64}:
  1.01927   2.9434
 -1.1206    1.49104
  0.694113  2.20964
```

## Keister Integral

This is the Julia version of a standard QMCPy integration workflow: construct a
discrete distribution, wrap it in a true measure, choose an integrand, and
compare the estimate against a known exact value.

```jldoctest
julia> using QMC

julia> dd = Lattice(3; randomize=true, seed=7);

julia> tm = Gaussian(dd; covariance=0.5);

julia> f = Keister(tm);

julia> sc = CubQMCLatticeG(f; abs_tol=1e-3);

julia> result = integrate(sc);

julia> round(result.solution; digits=6)
2.168409

julia> round(keister_exact(3); digits=6)
2.168309

julia> isapprox(result.solution, keister_exact(3); atol=5e-3)
true
```
