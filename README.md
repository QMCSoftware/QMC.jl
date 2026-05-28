# QMCJu.jl: Quasi-Monte Carlo Community Software in Julia

> QMCJu.jl is a Julia translation of the original QMCJu package, with quasi-Monte Carlo point generators, measure transforms, and adaptive stopping criteria for high-dimensional numerical integration.

## Overview

QMCJu.jl provides four building blocks that snap together to solve integration problems:

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
| [Julia](https://julialang.org/downloads/) | ≥ 1.10 | the language runtime |
| Python | any recent | currently required for the QMCToolsCL-backed generators `Lattice`, `DigitalNetB2`, and `Halton` |
| Git | any recent | to clone the repo |

Python is currently a runtime dependency for the main low-discrepancy QMC generators
`Lattice`, `DigitalNetB2`, and `Halton`, because they rely on the QMCToolsCL shared library.
Conda is optional; it is only one way to provide that Python environment and can also host
an optional Jupyter frontend.

## Setup (from scratch)

### 1. Clone the repository

```bash
git clone https://github.com/QMCSoftware/qmcju.jl.git
cd QMCSoftware/qmcju.jl
```

### 2. Install Julia (if not already installed)

On macOS (Homebrew):

```bash
brew install julia
```

Or download from [julialang.org](https://julialang.org/downloads/). Verify:

```bash
julia --version   # should print 1.10+
```

### 3. Install Julia package dependencies

```bash
julia --project=. -e 'using Pkg; Pkg.instantiate()'
```

This reads `Project.toml` and installs all Julia dependencies (Distributions, FFTW, SpecialFunctions, etc.).

### 4. Install QMCToolsCL for `Lattice`, `DigitalNetB2`, and `Halton`

The main low-discrepancy generators are backed by QMCToolsCL. Install it into a Python
visible to Julia:

```bash
python3 -m pip install qmctoolscl
```

If Julia should use a specific Python interpreter, set this before first use of those generators:

```julia
ENV["QMCJU_PYTHON"] = "/path/to/python"
```

### 5. Optional: install IJulia and register the `QMCJu` notebook kernel

```bash
julia -e 'using Pkg; Pkg.add("IJulia")'
julia -e 'using IJulia; IJulia.installkernel("QMCJu", "--project=$(pwd())")'
```

Run those commands from the repository root. This installs IJulia and creates a `QMCJu` kernel pinned to this repository's Julia environment, so notebooks can load the `QMCJu` module, `Plots`, and the rest of the project dependencies. This step is only needed if you plan to run the demo notebooks.

### 6. Verify the installation

```bash
julia --project=. -e 'using Pkg; Pkg.test()'
```

All tests should pass.

## Quick Start

In terminal, start Julia:

```bash
julia
```

In Julia, run the following commands:

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

Demo notebooks live in `demos/`. They contain Julia code and should run on the `QMCJu` Julia kernel.
Most of them use `Lattice` or `DigitalNetB2`, so they also require `qmctoolscl`
to be installed in a Python visible to Julia.

If you want the simplest path and do not need a separate Jupyter Python environment, launch them directly from Julia with:

```bash
julia -e 'using IJulia; notebook(dir="demos")'
```

If you have not created the project-bound kernel yet, run this once from the repository root:

```bash
julia -e 'using IJulia; IJulia.installkernel("QMCJu", "--project=$(pwd())")'
```

Then select the `QMCJu` kernel in Jupyter or VS Code once.

If you prefer to launch Jupyter from Python or Conda, that is also fine, but Python is only the notebook frontend in that setup. The notebook must still execute on the `QMCJu` Julia kernel.

To run a notebook in VS Code:

1. Install the VS Code `Julia` and `Jupyter` extensions.
2. Open this repository in VS Code and open a notebook from `demos/`.
3. Click the notebook kernel picker in the top-right corner.
4. Select `QMCJu`.
5. Restart the notebook kernel if the notebook was previously attached to another kernel.

If VS Code selects `qmcju (Python 3.12.x)`, `qmcpy (Python 3.12.x)`, `Python 3.12.x`, or another non-`QMCJu` kernel, switch it before running cells. Julia code such as `using QMCJu` will fail under a Python kernel, and a generic Julia kernel may miss this repository's dependencies.

See [`demos/README.md`](demos/README.md) for the notebook list and topic summaries.

## Documentation

See the [QMCJu.jl documentation](https://qmcsoftware.github.io/qmcju.jl/) for mathematical background. Julia-specific API docs are available via `@doc` in scripts and notebooks:

```julia
using QMCJu
@doc Lattice
@doc CubQMCBayesLatticeG
```

In the interactive Julia REPL, press `?` to enter help mode, then type `Lattice` or `CubQMCBayesLatticeG`.

## Citation

```bibtex
@misc{qmcju2026,
  author = {Sou-Cheng T. Choi and Fred J. Hickernell and Aleksei G. Sorokin and contributors},
  title  = {{QMCJu.jl}: Quasi-Monte Carlo Community Software in Julia},
  year   = {2026},
  url    = {https://github.com/QMCSoftware/qmcju.jl}
}
```

## Editorial Note

Some repository content was partially produced with the help of AI tools Claude and was reviewed by the authors and contributors.

## License

Apache 2.0 — see [LICENSE](LICENSE) for details.
