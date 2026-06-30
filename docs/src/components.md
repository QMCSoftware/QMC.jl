# Mathematical Components

QuasiMC.jl implements a modular framework for Quasi-Monte Carlo integration. The four main components interact as follows:

## Discrete Distribution

Generates low-discrepancy point sets in ``[0,1)^d``. Available generators:

- **`IIDStdUniform`** — pseudo-random (IID) uniform samples
- **`Lattice`** — rank-1 integration lattice with optional random shift
- **`DigitalNetB2`** — Sobol' digital net (base 2) with optional scrambling
- **`Halton`** — Halton sequence using prime bases
- **`Kronecker`** — Kronecker / irrational-rotation low-discrepancy sequence
- **`DigitalNetAnyBases`** / **`Faure`** — more general digital-net constructions

`DigitalNetB2` also supports QMCPy-style constructor options such as custom generating matrices, `order` aliases, widened `t` bit depth, `msb` handling for custom matrices, and higher-order interlacing via `alpha > 1`.

`Lattice` also supports QMCPy-style constructor inputs such as direct custom generating vectors, the integer shortcut for random odd vectors, order aliases, and LDData-format files, names, or URLs. In multilevel workflows, `spawn_dd` now preserves explicit lattice-vector sources when they carry enough entries for the requested dimension.

`Lattice`, `DigitalNetB2`, and `Halton` currently rely on the QMCToolsCL shared library supplied through QuasiMC's staged `QMCToolsCL_jll` dependency, so no Python setup is required for these QMC generators.

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
- **`AcceptanceRejection`** / **`AcceptanceRejectionReal`** — deterministic acceptance-rejection samplers on the cube / real space
- **`DistributionsWrapper`** — bridge to Distributions.jl marginals
- **`MaternGP`** — Matern Gaussian-process prior measure
- **`UniformTriangle`** — uniform sampling on a reference triangle
- **`ZeroInflatedExpUniform`** — mixed zero-inflated / exponential-uniform measure

## Integrand

The function to be integrated:

- **`CustomFun`** — user-supplied function
- **`Keister`** — ``\pi^{d/2} \cos(\|x\|)`` (standard QMC test function)
- **`Genz`** — six Genz test functions (oscillatory, product peak, etc.)
- **`AsianOption`** / **`FinancialOption`** — financial option pricing (European, Asian, lookback, digital, barrier)
- **`FinancialOptionML`** — multilevel financial option interface
- **`BoxIntegral`**, **`Linear0`**, **`Sin1D`**, **`Ishigami`**, **`Hartmann6D`** — standard test integrands
- **`Multimodal2D`**, **`FourBranch2D`** — reliability analysis test functions
- **`SensitivityIndices`** — Sobol sensitivity-index estimator
- **`BayesianLRCoeffs`** — Bayesian logistic-regression coefficient posterior
- **`UMBridgeWrapper`** — UMBridge.jl-backed external model integrand

### Multilevel Integrands

For problems with a natural hierarchy of discretization levels (e.g., PDE solvers with mesh refinement), the **`AbstractMLIntegrand`** interface supports multilevel methods. A multilevel integrand implements:

- `ml_evaluate(f, x, level)` — returns `(Qcoarse, Qfine)` pairs for the telescoping sum
- `dimension_at_level(f, level)` — stochastic dimension at each level
- `cost_at_level(f, level)` — computational cost per sample at each level

Helper functions `spawn_dd` and `spawn_tm` create new samplers at each level with the appropriate dimension.

## Extensibility Contract

QuasiMC.jl follows the same four-component architecture as QMCPy: discrete distributions, true measures, integrands, and stopping criteria. For extension work, the key framework contract is method-based rather than field-based:

- `QuasiMC.dimension(obj)` returns the stochastic dimension of a discrete distribution, true measure, or integrand.
- `QuasiMC.discrete_distribution(obj)` returns the underlying point generator.
- `QuasiMC.true_measure(f)` returns the integrand's true measure.

Existing built-in types satisfy this contract through their stored fields, but new subtype authors may overload these methods instead of reproducing the same field layout. That preserves encapsulation while letting the generic sampling, transform, and stopping-criterion pipeline remain plug-and-play.

Built-in constructors on abstract arguments are expected to honor this contract as well. In practice, that means methods like `Uniform(dd::AbstractDiscreteDistribution)` or `Keister(tm::AbstractTrueMeasure)` should query `dimension(dd)` or `dimension(tm)` instead of assuming a concrete `.dimension` field exists.

## API Stability

QuasiMC.jl uses four package-level stability labels for exported names:

| Status | Representative symbols | Meaning |
|---|---|---|
| **Stable** | `IIDStdUniform`, `Lattice`, `DigitalNetB2`, `Gaussian`, `BrownianMotion`, `Keister`, `Genz`, `CubMCCLT`, `CubMCG`, `CubQMCLatticeG`, `CubQMCNetG`, `CubQMCNetGRep` | Expected to remain source-compatible except for deliberate documented breaking releases |
| **Beta** | `CubQMCBayesLatticeG`, `CubQMCBayesNetG`, `CubMLMC`, `CubMLMCCont`, `CubMLQMC`, `CubMLQMCCont` | Usable and tested, but advanced interfaces may still be refined before long-term stabilization |
| **Experimental** | `PFGPCI`, `UMBridgeWrapper`, `KernelMultiTask`, `KernelMultiTaskDerivs` | Exported for early adopters; behavior and interfaces may change with limited compatibility guarantees |
| **Placeholder** | `gpu_fwht`, `gpu_fwht!` | Exported names reserved for future functionality; current implementation does not provide the advertised capability |

## Stopping Criterion

Adaptive algorithms that determine sample size:

### Single-Level Methods

- **`CubMCCLT`** — IID Monte Carlo with CLT confidence interval
- **`CubMCCLTVec`** — vectorized IID Monte Carlo with CLT-based doubling
- **`CubMCG`** — guaranteed IID Monte Carlo using Berry-Esseen-style bounds
- **`CubQMCLatticeG`** — replicated randomized lattice rule
- **`CubQMCNetG`** — single randomized digital net in natural (radical-inverse) order
- **`CubQMCNetGRep`** — replicated randomized digital net
- **`CubQMCBayesLatticeG`** — Bayesian QMC for lattices (kernel-based error bound)
- **`CubQMCBayesNetG`** — Bayesian QMC for digital nets (WHT-based error bound)
- **`CubQMCRepStudentT`** — replicated QMC with Student's *t* confidence intervals
- **`PFGPCI`** — experimental probability-of-failure GP criterion with an optional Julia GP backend

### Multilevel Methods

- **`CubMLMC`** — multilevel Monte Carlo (Giles 2008) with optimal sample allocation
- **`CubMLMCCont`** — continuation MLMC with progressively tighter tolerances
- **`CubMLQMC`** — multilevel quasi-Monte Carlo with replicated low-discrepancy rules
- **`CubMLQMCCont`** — continuation multilevel quasi-Monte Carlo using replicated lattice/digital net rules

The multilevel methods use the telescoping sum ``E[Q_L] = E[Q_0] + \sum_{\ell=1}^{L} E[Q_\ell - Q_{\ell-1}]`` to efficiently allocate computational effort across levels, exploiting the decreasing variance of level differences.

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
