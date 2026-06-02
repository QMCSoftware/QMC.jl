# Mathematical Components

QMC.jl implements a modular framework for Quasi-Monte Carlo integration. The four main components interact as follows:

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
- **`GeometricBrownianMotion`** — geometric Brownian motion paths
- **`StudentT`** — multivariate Student-t
- **`Triangular`** — triangular distribution
- **`Kumaraswamy`** — Kumaraswamy distribution
- **`JohnsonsSU`** — Johnson's SU distribution
- **`BernoulliCont`** — continuous Bernoulli

## Integrand

The function to be integrated:

- **`CustomFun`** — user-supplied function
- **`Keister`** — ``\pi^{d/2} \cos(\|x\|)`` (standard QMC test function)
- **`Genz`** — six Genz test functions (oscillatory, product peak, etc.)
- **`FinancialOption`** — financial option pricing (European, Asian, lookback, digital)
- **`BoxIntegral`**, **`Linear0`**, **`Sin1D`**, **`Ishigami`**, **`Hartmann6D`** — standard test integrands
- **`Multimodal2D`**, **`FourBranch2D`** — reliability analysis test functions

### Multilevel Integrands

For problems with a natural hierarchy of discretization levels (e.g., PDE solvers
with mesh refinement), the **`AbstractMLIntegrand`** interface supports multilevel
methods. A multilevel integrand implements:

- `ml_evaluate(f, x, level)` — returns `(Qcoarse, Qfine)` pairs for the telescoping sum
- `dimension_at_level(f, level)` — stochastic dimension at each level
- `cost_at_level(f, level)` — computational cost per sample at each level

Helper functions `spawn_dd` and `spawn_tm` create new samplers at each level with
the appropriate dimension.

## Stopping Criterion

Adaptive algorithms that determine sample size:

### Single-Level Methods

- **`CubMCCLT`** — IID Monte Carlo with CLT confidence interval
- **`CubQMCLatticeG`** — replicated randomized lattice rule
- **`CubQMCNetG`** — replicated randomized digital net
- **`CubQMCBayesLatticeG`** — Bayesian QMC for lattices (kernel-based error bound)
- **`CubQMCBayesNetG`** — Bayesian QMC for digital nets (WHT-based error bound)

### Multilevel Methods

- **`CubMLMC`** — multilevel Monte Carlo (Giles 2008) with optimal sample allocation
- **`CubMLMCCont`** — continuation MLMC with progressively tighter tolerances
- **`CubMLQMCCont`** — continuation multilevel quasi-Monte Carlo using replicated lattice/digital net rules

The multilevel methods use the telescoping sum ``E[Q_L] = E[Q_0] + \sum_{\ell=1}^{L} E[Q_\ell - Q_{\ell-1}]``
to efficiently allocate computational effort across levels, exploiting the
decreasing variance of level differences.

## Integration Pipeline

### Single-Level

```
Stopping Criterion → requests samples
    → Discrete Distribution → generates [0,1)^d points
    → True Measure → transforms to target domain
    → Integrand → evaluates function
    → Stopping Criterion → checks error bound
    → repeat or return result
```

### Multilevel

```
ML Stopping Criterion → for each level l:
    → spawn_dd / spawn_tm → create sampler at dimension d_l
    → Discrete Distribution → generates [0,1)^{d_l} points
    → True Measure → transforms to target domain
    → ml_evaluate(f, x, l) → returns (Q_coarse, Q_fine)
    → ML Stopping Criterion → estimates variance, adjusts allocation
    → repeat or add levels until convergence
```
