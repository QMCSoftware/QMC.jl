# Mathematical Components

QMCJu.jl implements a modular framework for Quasi-Monte Carlo integration. The four main components interact as follows:

## Discrete Distribution

Generates low-discrepancy point sets in ``[0,1)^d``. Available generators:

- **`IIDStdUniform`** — pseudo-random (IID) uniform samples
- **`Lattice`** — rank-1 integration lattice with optional random shift
- **`DigitalNetB2`** — Sobol' digital net (base 2) with optional scrambling
- **`Halton`** — Halton sequence using prime bases

`Lattice`, `DigitalNetB2`, and `Halton` currently rely on the QMCToolsCL
shared library, so Python is a current runtime dependency for these QMC generators.

## True Measure

Transforms ``[0,1)^d`` samples to the desired probability domain:

- **`Uniform`** — uniform on ``[a,b]^d``
- **`Gaussian`** — multivariate normal (PCA or Cholesky decomposition)
- **`BrownianMotion`** — standard Brownian motion paths
- **`Lebesgue`** — Lebesgue measure on ``[a,b]^d``

## Integrand

The function to be integrated:

- **`CustomFun`** — user-supplied function
- **`Keister`** — ``\\pi^{d/2} \\cos(\\|x\\|)`` (standard QMC test function)
- **`Genz`** — six Genz test functions (oscillatory, product peak, etc.)
- **`AsianOption`** — Asian option pricing under geometric Brownian motion

## Stopping Criterion

Adaptive algorithms that determine sample size:

- **`CubMCCLT`** — IID Monte Carlo with CLT confidence interval
- **`CubQMCLatticeG`** — replicated randomized lattice rule
- **`CubQMCNetG`** — replicated randomized digital net
- **`CubQMCBayesLatticeG`** — Bayesian QMC for lattices (kernel-based error bound)
- **`CubQMCBayesNetG`** — Bayesian QMC for digital nets (WHT-based error bound)

## Integration Pipeline

```
Stopping Criterion → requests samples
    → Discrete Distribution → generates [0,1)^d points
    → True Measure → transforms to target domain
    → Integrand → evaluates function
    → Stopping Criterion → checks error bound
    → repeat or return result
```
