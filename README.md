# QMCJu: Quasi-Monte Carlo Community Software in Julia

> A Julia translation of [QMCJu](https://github.com/QMCSoftware/QMCSoftware) (v2.3) — quasi-Monte Carlo point generators, measure transforms, and adaptive stopping criteria for high-dimensional numerical integration.

## Overview

QMCJu provides four building blocks that snap together to solve integration problems:

| Component | Purpose | Available types |
|---|---|---|
| **Discrete Distribution** | Low-discrepancy point generators | `IIDStdUniform`, `Lattice`, `DigitalNetB2`, `Halton` |
| **True Measure** | Probability measure / variable transform | `Uniform`, `Gaussian`, `BrownianMotion`, `Lebesgue`, `GeometricBrownianMotion`, `StudentT`, `Triangular`, `Kumaraswamy`, `JohnsonsSU`, `BernoulliCont` |
| **Integrand** | Function to integrate | `Keister`, `Genz`, `AsianOption`, `FinancialOption`, `BoxIntegral`, `Linear0`, `Sin1D`, `Ishigami`, `Hartmann6D`, `Multimodal2D`, `FourBranch2D`, `CustomFun` |
| **Stopping Criterion** | Adaptive error control | `CubMCCLT`, `CubQMCLatticeG`, `CubQMCNetG`, `CubQMCBayesLatticeG`, `CubQMCBayesNetG` |

Additional modules provide shift-invariant and Matérn kernels (`KernelShiftInvar`, `KernelMatern12/32/52`, `KernelGaussian`), periodization transforms, and utility functions.

## Prerequisites

| Tool | Version | Notes |
|---|---|---|
| [Conda](https://docs.conda.io/en/latest/miniconda.html) (Miniconda or Anaconda) | any recent | manages the Python environment |
| [Julia](https://julialang.org/downloads/) | ≥ 1.10 | the language runtime |
| Git | any recent | to clone the repo |

## Setup (from scratch)

### 1. Clone the repository

```bash
git clone https://github.com/QMCSoftware/QMCSoftware.git
cd QMCSoftware/qmcju_software
```

### 2. Create and activate a Conda environment

If your project sits alongside the Python QMCJu package, reuse its environment. Otherwise create a fresh one:

```bash
conda create -n qmcju python=3.12 -y
conda activate qmcju
```

### 3. Install Julia (if not already installed)

On macOS (Homebrew):

```bash
brew install julia
```

Or download from [julialang.org](https://julialang.org/downloads/). Verify:

```bash
julia --version   # should print 1.10+
```

### 4. Install Julia package dependencies

```bash
julia --project=. -e 'using Pkg; Pkg.instantiate()'
```

This reads `Project.toml` and installs all Julia dependencies (Distributions, FFTW, SpecialFunctions, etc.).

### 5. Install IJulia (for Jupyter notebooks)

```bash
julia -e 'using Pkg; Pkg.add("IJulia")'
```

This registers the Julia kernel with Jupyter so you can run the demo notebooks.

### 6. Verify the installation

```bash
julia --project=. -e 'using Pkg; Pkg.test()'
```

All tests should pass.

## Quick Start

```julia
using QMCJu

# Integrate the Keister function over a 3D Gaussian measure
dd = Lattice(3; randomize=true, seed=7)
tm = Gaussian(dd; covariance=0.5)
f  = Keister(tm)
sc = CubQMCLatticeG(f; abs_tol=1e-3)

result = integrate(sc)
println("Estimate: $(result.solution)")
println("Exact:    $(keister_exact(3))")
```

## Demos

Nine demo notebooks live in `demos/`. Launch them with:

```bash
conda activate qmcju
julia -e 'using IJulia; notebook(dir="demos")'
```

Or open any `.ipynb` file directly in VS Code (with the Jupyter extension and Julia kernel).

| Notebook | Topic |
|---|---|
| `quickstart.ipynb` | Keister integral with all 5 stopping criteria |
| `pricing_options.ipynb` | European, Asian, Lookback, Digital options |
| `digital_net_b2.ipynb` | Sobol' sequences, scrambling, replications |
| `lattice.ipynb` | Lattice orderings, shifts, Kuo vectors |
| `lebesgue_integration.ipynb` | Lebesgue measure integration |
| `some_true_measures.ipynb` | All 10 true measures demonstrated |
| `gbm_demo.ipynb` | Geometric Brownian Motion for finance |
| `qmcju_intro.ipynb` | Package tour: building blocks explained |
| `sample_scatter_plots.ipynb` | Point set visualizations and statistics |

## Documentation

See the [QMCJu documentation](https://qmcsoftware.github.io/QMCSoftware/) for mathematical background. Julia-specific API docs are available via `?` in the Julia REPL:

```julia
julia> using QMCJu
julia> ?Lattice
julia> ?CubQMCBayesLatticeG
```

## Citation

```bibtex
@misc{qmcju2026,
  author = {Sou-Cheng T. Choi and Fred J. Hickernell and contributors},
  title  = {{QMCJu}: Quasi-Monte Carlo Community Software in Julia},
  year   = {2026},
  url    = {https://github.com/QMCSoftware/QMCSoftware}
}
```

## License

Apache 2.0 — see [LICENSE](LICENSE) for details.
