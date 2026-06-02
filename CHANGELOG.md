# Changelog

All notable changes to QMC.jl will be documented in this file.

The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.1.0] - 2026-05-29

Initial release — a full Julia port of QMCPy v2.3.

### Discrete Distributions

- `IIDStdUniform` — i.i.d. uniform sampling (pure Julia)
- `Lattice` — rank-1 lattice with Kuo generating vectors, shift randomization, radical-inverse/Gray-code ordering, replications
- `DigitalNetB2` — Sobol digital nets with LMS, DS, NUS, Owen scrambling, replications
- `Halton` — Halton sequence with Owen scrambling
- `Kronecker` — Kronecker/golden-ratio low-discrepancy sequence
- `DigitalNetAnyBases` / `Faure` — generalized digital nets
- Windowed sampling (`n_start` parameter) for all generators

### True Measures

- `Uniform`, `Gaussian`, `BrownianMotion`, `Lebesgue`, `GeometricBrownianMotion`
- `StudentT`, `Triangular`, `Kumaraswamy`, `JohnsonsSU`, `BernoulliCont`
- `AcceptanceRejection` — rejection sampling with custom PDF
- `DistributionsWrapper` — bridge to Distributions.jl marginals
- `MaternGP`, `UniformTriangle`, `ZeroInflatedExpUniform`

### Integrands

- `Keister`, `Genz`, `BoxIntegral`, `Linear0`, `Sin1D`
- `Ishigami`, `Hartmann6D`, `Multimodal2D`, `FourBranch2D`
- `AsianOption`, `FinancialOption` (European, Asian, lookback, digital, barrier)
- `FinancialOptionML` — multilevel financial option
- `SensitivityIndices` — Sobol sensitivity indices via pick-freeze
- `BayesianLRCoeffs` — Bayesian logistic regression posterior
- `UMBridgeWrapper` — UMBridge.jl model integration
- `CustomFun` — user-defined integrand

### Stopping Criteria

- `CubMCCLT` — MC with CLT confidence interval
- `CubMCCLTVec` — vectorized MC with CLT, resume/checkpoint support
- `CubMCG` — MC with guaranteed error (kurtosis-based)
- `CubQMCLatticeG` / `CubQMCNetG` — QMC with guaranteed error
- `CubQMCBayesLatticeG` / `CubQMCBayesNetG` — Bayesian QMC
- `CubQMCRepStudentT` — replicated QMC with Student-t CI
- `CubMLMC` / `CubMLMCCont` — multilevel MC
- `CubMLQMC` / `CubMLQMCCont` — multilevel QMC
- `PFGPCI` — stub (requires AbstractGPs.jl backend)
- `rel_tol` support across all criteria
- Resume/checkpoint support for iterative criteria
- `IterationLog` diagnostics framework

### Kernels

- `KernelShiftInvar`, `KernelDigShiftInvar`
- `KernelMatern12`, `KernelMatern32`, `KernelMatern52`, `KernelGaussian`
- `KernelMultiTask`, `SumKernel`, `ProductKernel`

### Utilities

- Fast Walsh-Hadamard transform (`fwht!`, `ifwht!`)
- BRO-FFT transform
- Periodization transforms (Baker, C1, C2, C3, C2SIN)
- Bernoulli polynomials
- LatNetBuilder linker
- `mlmc_test` multilevel diagnostic utility
- GPU backend stub

### Demos

- 26 Jupyter notebooks covering: quickstart, sampling, lattices, digital nets, Halton, Kronecker, financial options, multilevel QMC, sensitivity analysis, Bayesian optimization, ray tracing, UMBridge, and more

### Infrastructure

- Documenter.jl documentation with full API reference
- CI/CD: fast Linux CI, cross-platform full sweep, nightly compatibility, docs build
- JuliaFormatter configuration
- Benchmark suite with BenchmarkTools.jl
- Concurrency cancellation on all CI workflows
