# QMC.jl: Quasi-Monte Carlo Community Software in Julia

[![Doc/Unit Tests](https://github.com/QMCSoftware/QMC.jl/actions/workflows/ci-full.yml/badge.svg?branch=develop)](https://github.com/QMCSoftware/QMC.jl/actions/workflows/ci-full.yml)
[![Docs and Demos](https://github.com/QMCSoftware/QMC.jl/actions/workflows/doc_demo.yml/badge.svg?branch=develop)](https://github.com/QMCSoftware/QMC.jl/actions/workflows/doc_demo.yml)
[![Benchmarking](https://github.com/QMCSoftware/QMC.jl/actions/workflows/benchmarking.yml/badge.svg?branch=develop)](https://github.com/QMCSoftware/QMC.jl/actions/workflows/benchmarking.yml)
[![Benchmark Speed](https://img.shields.io/endpoint?url=https://raw.githubusercontent.com/QMCSoftware/QMC.jl/benchmark-badges/badges/benchmark-speed-develop.json)](https://github.com/QMCSoftware/QMC.jl/actions/workflows/benchmarking.yml)
[![Benchmark Memory](https://img.shields.io/endpoint?url=https://raw.githubusercontent.com/QMCSoftware/QMC.jl/benchmark-badges/badges/benchmark-memory-develop.json)](https://github.com/QMCSoftware/QMC.jl/actions/workflows/benchmarking.yml)
[![Docs](https://img.shields.io/badge/docs-source-blue.svg)](docs/src/index.md)
[![codecov](https://codecov.io/gh/QMCSoftware/QMC.jl/branch/develop/graph/badge.svg)](https://codecov.io/gh/QMCSoftware/QMC.jl)
[![License](https://img.shields.io/badge/license-Apache%202.0-green.svg)](LICENSE)

A Julia port of [QMCPy](https://github.com/QMCSoftware/QMCSoftware) — quasi-Monte Carlo point generators, measure transforms, and adaptive stopping criteria for high-dimensional numerical integration.

The benchmark badges report the latest published `develop` branch aggregate comparison against QMCPy. The speed badge uses the weighted runtime ratio, and the memory badge uses an approximate weighted Python `tracemalloc` peak versus Julia allocation ratio from `benchmark/compare_py.jl`. The exact source snapshot behind each published badge is archived on the `benchmark-badges` branch.

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

QMC.jl provides four core building blocks, plus related kernel types:

| Component | Types |
|---|---|
| **Discrete Distribution** | `IIDStdUniform`, `Lattice`, `DigitalNetB2`, `Halton`, `Kronecker`, `DigitalNetAnyBases`, `Faure` |
| **True Measure** | `Uniform`, `Gaussian`, `BrownianMotion`, `Lebesgue`, `GeometricBrownianMotion`, `StudentT`, `Triangular`, `Kumaraswamy`, `JohnsonsSU`, `BernoulliCont`, `AcceptanceRejection`, `AcceptanceRejectionReal`, `DistributionsWrapper`, `MaternGP`, `UniformTriangle`, `ZeroInflatedExpUniform` |
| **Integrand** | `Keister`, `Genz`, `AsianOption`, `FinancialOption`, `FinancialOptionML`, `BoxIntegral`, `Linear0`, `Sin1D`, `Ishigami`, `Hartmann6D`, `Multimodal2D`, `FourBranch2D`, `SensitivityIndices`, `BayesianLRCoeffs`, `UMBridgeWrapper`, `CustomFun` |
| **Stopping Criterion** | `CubMCCLT`, `CubMCCLTVec`, `CubMCG`, `CubQMCLatticeG`, `CubQMCNetG`, `CubQMCNetGRep`, `CubQMCBayesLatticeG`, `CubQMCBayesNetG`, `CubQMCRepStudentT`, `CubMLMC`, `CubMLMCCont`, `CubMLQMC`, `CubMLQMCCont`, `PFGPCI` |
| **Kernel** | `KernelShiftInvar`, `KernelDigShiftInvar`, `KernelMatern12`, `KernelMatern32`, `KernelMatern52`, `KernelGaussian`, `KernelRationalQuadratic`, `KernelSquaredExponential`, `KernelMultiTask`, `SumKernel`, `ProductKernel` |

Additional utilities include periodization transforms, iteration diagnostics (`IterationLog`), resume/checkpoint support, Walsh-Hadamard and BRO-FFT transforms, and a LatNetBuilder linker.

Advanced status notes: `PFGPCI` is currently an exported experimental feature that depends on an optional Julia GP backend, while `gpu_fwht` and `gpu_fwht!` are placeholder exported names whose current behavior is only the CPU `fwht`/`fwht!` fallback.

## API Stability

QMC.jl currently groups its public surface into the following stability levels:

| Status | Representative symbols | Meaning |
|---|---|---|
| **Stable** | `IIDStdUniform`, `Lattice`, `DigitalNetB2`, `Gaussian`, `BrownianMotion`, `Keister`, `Genz`, `CubMCCLT`, `CubMCG`, `CubQMCLatticeG`, `CubQMCNetG`, `CubQMCNetGRep` | Expected to remain source-compatible except for deliberate documented breaking releases |
| **Beta** | `CubQMCBayesLatticeG`, `CubQMCBayesNetG`, `CubMLMC`, `CubMLMCCont`, `CubMLQMC`, `CubMLQMCCont` | Usable and tested, but advanced interfaces may still be refined before long-term stabilization |
| **Experimental** | `PFGPCI`, `UMBridgeWrapper`, `KernelMultiTask`, `KernelMultiTaskDerivs` | Exported for early adopters; behavior and interfaces may change with limited compatibility guarantees |
| **Placeholder** | `gpu_fwht`, `gpu_fwht!` | Exported names reserved for future functionality; current implementation does not provide the advertised capability |

## Installation

### Stable Tagged Install

For papers, demos, courses, and reproducible benchmarks, install QMC.jl from an immutable git tag rather than a moving branch. Replace `vX.Y.Z` with the published release tag you want to use, for example `v0.1.0` once that tag exists:

```julia
using Pkg
Pkg.add(url="https://github.com/QMCSoftware/QMC.jl", rev="vX.Y.Z")
```

For `Lattice`, `DigitalNetB2`, and `Halton`, also install the pinned QMCToolsCL runtime into a Python visible to Julia:

```bash
python3 -m pip install qmctoolscl==1.2.3
```

If Julia should use a specific Python interpreter:

```julia
ENV["QMC_PYTHON"] = "/path/to/python"
```

### Contributor And Early-Tester Setup

Use the repository checkout instructions below only when working directly from the development tree.

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
pip install qmctoolscl==1.2.3

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
# or
make notebook NOTEBOOK_JOBS=2 NOTEBOOK_THREADS=1

# Run a single demo
julia --project=. test/run_notebooks.jl quickstart
# or
make notebook-quickstart

# Launch in Jupyter
julia -e 'using IJulia; notebook(dir="demos")'

# Execute notebooks with the qmc-1.12 kernel and overwrite output cells in place
make notebook-update NOTEBOOK_KERNEL=qmc-1.12

# Update a single notebook in place
make notebook-update-quickstart NOTEBOOK_KERNEL=qmc-1.12
```

## Benchmarks

Run the benchmark suite:

```bash
make bench
# or
julia benchmark/runbenchmarks.jl
```

This benchmarks sampling, transforms, integrand evaluation, and end-to-end integration across all DD types. Results are saved under `benchmark/results/`. See [`benchmark/README.md`](benchmark/README.md) for the full workflow, comparison scripts, and the Julia-vs-QMCPy accuracy sidecars.

Remote benchmark collection is handled by `.github/workflows/benchmarking.yml`: it runs on Linux for benchmark-relevant `develop`/`master` pushes and manual dispatch, then uploads `benchmark/results/` as a workflow artifact. See [docs/src/ci-testing.md](docs/src/ci-testing.md) for the full workflow policy.

The top-level benchmark badges track the latest published `develop` run. The speed badge is the weighted `Python time ÷ Julia time` ratio from the Julia-vs-QMCPy comparison. The peak-memory badge uses QMCPy's `tracemalloc` peak versus Julia's recorded allocation totals, so it should be read as an approximate signal rather than a strict apples-to-apples memory metric. The benchmark reports also include `StudentT` split summaries, grouped totals for `gen_samples`, `transform`, `evaluate`, and end-to-end `integrate`, a within-run bootstrap interval for the headline time ratio, and an archived source snapshot for each published badge update. See [`benchmark/README.md`](benchmark/README.md) for the report structure and interpretation notes.

## Repository Layout

Most top-level and source subdirectories now include a local `README.md` describing their purpose and the files they contain. Useful starting points:

- [`benchmark/README.md`](benchmark/README.md) — standalone benchmarking and comparison tooling
- [`demos/README.md`](demos/README.md) — notebook demos and how to run them
- [`docs/OVERVIEW.md`](docs/OVERVIEW.md) — Documenter build/deploy layout
- [`RELEASING.md`](RELEASING.md) — release ladder, readiness gates, and tagging process
- [`src/README.md`](src/README.md) — package source tree and component folders
- [`test/README.md`](test/README.md) — unit tests, notebook tests, and coverage commands

## Documentation

Until GitHub Pages is enabled for this repository, use the in-repo documentation source: [docs/src/index.md](docs/src/index.md). API reference pages live under [docs/src/api/](docs/src/api/).

In the Julia REPL:

```julia
using QMC
?Lattice               # help mode
@doc CubQMCBayesNetG   # docstring
```

## Validated Examples

These checked-in notebooks are exercised by the demo workflow and are good starting points for common QMC.jl use cases:

- [demos/quickstart.ipynb](demos/quickstart.ipynb) — `Keister`, `Gaussian`, `Lattice`, `CubQMCLatticeG`
- [demos/sample_scatter_plots.ipynb](demos/sample_scatter_plots.ipynb) — `Gaussian`, `BrownianMotion`, transformed samples
- [demos/pricing_options.ipynb](demos/pricing_options.ipynb) — `BrownianMotion` path construction and option-pricing workflows
- [demos/asian_option_mlqmc.ipynb](demos/asian_option_mlqmc.ipynb) — `AsianOption`, `CubQMCNetG`, `CubMLMC`, `CubMLQMC`, continuation variants
- [demos/elliptic_pde.ipynb](demos/elliptic_pde.ipynb) — `CubQMCLatticeG`, `CubMLMCCont`, `CubMLQMCCont`

## Testing

```bash
# Unit tests
julia --project=. -e 'using Pkg; Pkg.test()'

# Unit tests with coverage instrumentation
julia --project=. -e 'using Pkg; Pkg.test(coverage=true)'
# or
make coverage

# Demo notebooks
julia --project=. test/run_notebooks.jl
# or, to overwrite notebooks with fresh executed outputs
make notebook-update NOTEBOOK_KERNEL=qmc-1.12

# Build documentation locally
julia --project=docs docs/make.jl
```

CI uploads LCOV coverage reports to Codecov and stores the generated `lcov.info` as a workflow artifact. The `develop` branch badge is fed by the Linux coverage lane in `ci-full.yml`. See [`test/README.md`](test/README.md) and [docs/src/ci-testing.md](docs/src/ci-testing.md) for details.

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
