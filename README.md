# QMC.jl: Quasi-Monte Carlo Community Software in Julia

[![CI](https://github.com/QMCSoftware/QMC.jl/actions/workflows/ci.yml/badge.svg)](https://github.com/QMCSoftware/QMC.jl/actions/workflows/ci.yml)
[![CI Full](https://github.com/QMCSoftware/QMC.jl/actions/workflows/ci-full.yml/badge.svg)](https://github.com/QMCSoftware/QMC.jl/actions/workflows/ci-full.yml)
[![Docs](https://img.shields.io/badge/docs-stable-blue.svg)](https://qmcsoftware.github.io/QMC.jl/)
[![codecov](https://codecov.io/gh/QMCSoftware/QMC.jl/branch/develop/graph/badge.svg)](https://codecov.io/gh/QMCSoftware/QMC.jl)
[![License](https://img.shields.io/badge/license-Apache%202.0-green.svg)](LICENSE)

A Julia port of [QMCPy](https://github.com/QMCSoftware/QMCSoftware) — quasi-Monte Carlo point generators, measure transforms, and adaptive stopping criteria for high-dimensional numerical integration.

## Quick Start

```julia
using QMC

dd = Lattice(3; randomize=true, seed=7)
tm = Gaussian(dd; covariance=0.5)
f  = Keister(tm)
sc = CubQMCLatticeG(f; abs_tol=1e-3)

result = integrate(sc)
println("Estimate: $(result.solution)")   # ≈ 2.168
println("Exact:    $(keister_exact(3))")
```

## Components

QMC.jl provides four building blocks that snap together:

| Component | Types |
|---|---|
| **Discrete Distribution** | `IIDStdUniform`, `Lattice`, `DigitalNetB2`, `Halton`, `Kronecker`, `DigitalNetAnyBases`, `Faure` |
| **True Measure** | `Uniform`, `Gaussian`, `BrownianMotion`, `Lebesgue`, `GeometricBrownianMotion`, `StudentT`, `Triangular`, `Kumaraswamy`, `JohnsonsSU`, `BernoulliCont`, `AcceptanceRejection`, `DistributionsWrapper`, `MaternGP`, `UniformTriangle`, `ZeroInflatedExpUniform` |
| **Integrand** | `Keister`, `Genz`, `AsianOption`, `FinancialOption`, `FinancialOptionML`, `BoxIntegral`, `Linear0`, `Sin1D`, `Ishigami`, `Hartmann6D`, `Multimodal2D`, `FourBranch2D`, `SensitivityIndices`, `BayesianLRCoeffs`, `UMBridgeWrapper`, `CustomFun` |
| **Stopping Criterion** | `CubMCCLT`, `CubMCCLTVec`, `CubMCG`, `CubQMCLatticeG`, `CubQMCNetG`, `CubQMCBayesLatticeG`, `CubQMCBayesNetG`, `CubQMCRepStudentT`, `CubMLMC`, `CubMLMCCont`, `CubMLQMC`, `CubMLQMCCont`, `PFGPCI` |
| **Kernel** | `KernelShiftInvar`, `KernelDigShiftInvar`, `KernelMatern12`, `KernelMatern32`, `KernelMatern52`, `KernelGaussian`, `KernelMultiTask`, `SumKernel`, `ProductKernel` |

Additional utilities include periodization transforms, iteration diagnostics (`IterationLog`), resume/checkpoint support, Walsh-Hadamard and BRO-FFT transforms, and a LatNetBuilder linker.

## Installation

### Prerequisites

| Tool | Version | Notes |
|---|---|---|
| [Julia](https://julialang.org/downloads/) | ≥ 1.10 | Language runtime |
| Python | ≥ 3.9 | Required for QMCToolsCL-backed generators |

### Steps

```bash
# Clone the repository
git clone https://github.com/QMCSoftware/QMC.jl.git
cd QMC.jl

# Install Julia dependencies
julia --project=. -e 'using Pkg; Pkg.instantiate()'

# Install QMCToolsCL (for Lattice, DigitalNetB2, Halton)
pip install qmctoolscl

# Run tests
julia --project=. -e 'using Pkg; Pkg.test()'
```

If Julia should use a specific Python interpreter:

```julia
ENV["QMC_PYTHON"] = "/path/to/python"
```

### Optional: Jupyter Notebook Kernel

```bash
julia -e 'using Pkg; Pkg.add("IJulia")'
julia -e 'using IJulia; IJulia.installkernel("QMC", "--project=$(pwd())")'
```

## Demos

26 Jupyter notebooks in `demos/` cover topics from basic sampling to multilevel QMC, Bayesian optimization, sensitivity analysis, and UMBridge integration. See [`demos/README.md`](demos/README.md) for the full list.

```bash
# Run all demos
julia --project=. test/run_notebooks.jl

# Run a single demo
julia --project=. test/run_notebooks.jl quickstart

# Launch in Jupyter
julia -e 'using IJulia; notebook(dir="demos")'
```

## Benchmarks

Run the benchmark suite:

```bash
julia --project=. benchmark/benchmarks.jl
```

This benchmarks sampling, transforms, integrand evaluation, and end-to-end integration across all DD types. Results are saved to `benchmark/results/latest.json`.

## Documentation

Full API documentation: [qmcsoftware.github.io/QMC.jl](https://qmcsoftware.github.io/QMC.jl/)

In the Julia REPL:

```julia
using QMC
?Lattice               # help mode
@doc CubQMCBayesNetG   # docstring
```

## Testing

```bash
# Unit tests
julia --project=. -e 'using Pkg; Pkg.test()'

# Demo notebooks
julia --project=. test/run_notebooks.jl

# Build documentation locally
julia --project=docs docs/make.jl
```

See [CI/CD Testing](https://qmcsoftware.github.io/QMC.jl/ci-testing/) for workflow details.

## Citation

```bibtex
@misc{qmcjl2026,
  author = {Sou-Cheng T. Choi and Fred J. Hickernell and Aleksei G. Sorokin and contributors},
  title  = {{QMC.jl}: Quasi-Monte Carlo Community Software in Julia},
  year   = {2026},
  url    = {https://github.com/QMCSoftware/QMC.jl}
}
```

## Editorial Note

Some repository content was partially produced with the help of AI tools (e.g., Claude and GPT) and was reviewed by the authors and contributors.

## License

Apache 2.0 — see [LICENSE](LICENSE) for details.
