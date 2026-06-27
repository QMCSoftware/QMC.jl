# Contributing to QMC.jl

Thank you for your interest in contributing to QMC.jl. This guide walks through the full developer setup, project conventions, and how to add new components.

Please submit **pull requests** to the `develop` branch and **issues** using a template from `.github/ISSUE_TEMPLATE/`.

Join team communications at [qmc-software@googlegroups.com](mailto:qmc-software@googlegroups.com). If you develop a new component, consider writing a blog for [qmcpy.org](https://qmcpy.org).

For release gates, versioning policy, and the maintainer release checklist, see [RELEASING.md](RELEASING.md).

## Pull Request Checklist

Before requesting review, please confirm the following:

- [ ] Mathematical correctness is justified, especially for transforms, covariance structure, error bounds, and stopping logic.
- [ ] Public API changes are intentional, backward-compatibility is considered, and any QMCPy parity impact is recorded in [sc_notes/qmcpy-parity.md](sc_notes/qmcpy-parity.md).
- [ ] Tests cover the new behavior, edge cases, invalid inputs, and at least one mathematically meaningful invariant.
- [ ] User-facing docs, docstrings, demos, and notebooks are updated when behavior, names, defaults, or workflows change.
- [ ] Performance-sensitive changes include benchmark evidence or an explicit note explaining why no benchmark update was needed.
- [ ] Reproducibility details are recorded: deterministic seeds when applicable, pinned reference versions, and exact commands for any reported benchmark or parity result.

## QMCPy Parity Policy

QMC.jl aims for behavioral parity with a pinned QMCPy reference release while keeping the implementation idiomatic Julia. The parity target for each component family is:

| Component family | Parity target | Maintainer rule |
| --- | --- | --- |
| Abstract types and result objects | Aspirational | Align names and concepts where practical, but prefer Julia-native abstract types, result structs, and dispatch over class-for-class mirroring. |
| Core API verbs and keywords | Approximate | Preserve direct call-site translation where possible, but allow Julia-specific wrappers, return structs, and dispatch-based APIs. |
| Discrete distributions | Strict | Shared generators must preserve seeded sample behavior, layout, keywords, and documented failure modes against the pinned QMCPy reference. |
| True measures | Approximate | Shared measures must preserve the mathematical transform and user-visible parameters, while allowing Julia-native numerical backends and decompositions. |
| Integrands | Strict | Shared integrands must preserve formulas, parameter semantics, and seeded oracle values within the documented tolerance budget. |
| Stopping criteria | Strict | Shared stopping criteria must preserve tolerance semantics, sample accounting, convergence behavior, and resume semantics against the pinned QMCPy reference. |
| Kernels | Approximate | Shared kernels must preserve kernel values and Bayesian behavior within tolerance, while allowing Julia-native composition, derivative helpers, and implementation details. |

Items marked as QMC.jl-only extensions in the parity map are outside strict QMCPy parity unless they are explicitly promoted to shared behavior in a future release.

## Developer Setup

### Prerequisites

| Tool | Version | Notes |
|---|---|---|
| [Julia](https://julialang.org/downloads/) | ≥ 1.10 | `brew install julia` on macOS, or download from julialang.org |
| Python | any recent | currently required for the QMCToolsCL-backed generators `Lattice`, `DigitalNetB2`, and `Halton` |
| Git | any recent | to clone the repo |

Python is currently a runtime dependency for the main low-discrepancy QMC generators `Lattice`, `DigitalNetB2`, and `Halton`, because they rely on the QMCToolsCL shared library.
Conda is optional; it is only one way to provide that Python environment and can also host an optional Jupyter frontend.

### 1. Clone and enter the project

```bash
git clone https://github.com/QMCSoftware/QMC.jl.git
```

### 2. Install Julia dependencies

```bash
julia --project=. -e 'using Pkg; Pkg.instantiate()'
```

### 3. Install QMCToolsCL for `Lattice`, `DigitalNetB2`, and `Halton`

The main low-discrepancy generators are backed by the compiled C library inside the `qmctoolscl` Python package (version ≥ 1.2.3). Install it into a Python visible to Julia:

```bash
python3 -m pip install 'qmctoolscl>=1.2.3'
```

`IIDStdUniform` and `Kronecker`, and all true measures, integrands, and stopping criteria, work without this step. Only `Lattice`, `DigitalNetB2`, and `Halton` need qmctoolscl.

If Julia should use a specific Python interpreter, set this before first use of those generators (no Julia restart needed):

```julia
ENV["QMC_PYTHON"] = "/path/to/python"
```

### 4. Optional: install IJulia and register the `QMC` notebook kernel

```bash
julia -e 'using Pkg; Pkg.add("IJulia")'
julia -e 'using IJulia; IJulia.installkernel("QMC", "--project=$(pwd())")'
```

Run those commands from the repository root. This installs IJulia and creates a `QMC` kernel pinned to this repository's Julia environment, so demo notebooks use the same Julia environment as local development and CI. This step is only needed if you plan to run notebooks.

### 5. Verify everything works

## Running Tests

Full test suite:

```bash
julia --project=. -e 'using Pkg; Pkg.test()'
```

All tests should pass with zero failures.

Interactive testing (useful during development):

```julia
using Pkg
Pkg.activate(".")
include("test/runtests.jl")
```

Individual test groups:

```julia
using QMC, Test, Statistics, LinearAlgebra, Distributions
import QMC: Uniform, Kumaraswamy  # resolve name conflicts with Distributions

include("test/test_discrete_distributions.jl")
include("test/test_true_measures.jl")
include("test/test_integrands.jl")
include("test/test_kernels.jl")
include("test/test_stopping_criteria.jl")
include("test/test_integration.jl")
```

Note: `Uniform` and `Kumaraswamy` are exported by both QMC and Distributions.jl. When using both packages, resolve the ambiguity with `import QMC: Uniform, Kumaraswamy`.

## Project Structure

```
QMC.jl/
├── Project.toml                # Julia package metadata and dependencies
├── src/
│   ├── QMC.jl                  # Main module: includes, exports
│   ├── abstract_types.jl       # Type hierarchy
│   ├── data/                   # Embedded generating vectors and direction numbers
│   │   ├── kuo_lattice_gen_vector.jl    # 9125 Kuo lattice generating vectors
│   │   └── joe_kuo_direction_numbers.jl # 1024×32 Joe-Kuo direction number matrix
│   ├── discrete_distribution/  # IIDStdUniform, Lattice, DigitalNetB2, Halton
│   ├── true_measure/           # Uniform, Gaussian, BrownianMotion, GBM, ...
│   ├── integrand/              # Keister, Genz, FinancialOption, ...
│   ├── kernel/                 # KernelShiftInvar, KernelMatern*, ...
│   ├── stopping_criterion/     # CubMCCLT, CubQMCLatticeG, Bayesian, ...
│   └── util/                   # Bernoulli polynomials, periodization, WHT, ...
├── test/
│   ├── runtests.jl             # Test entry point
│   └── test_*.jl               # Per-module test files
└── demos/
    └── *.ipynb                 # Jupyter notebook versions
```

## Running Demos

If you want the simplest path and do not need a separate Python environment, launch the notebook server from Julia:

```bash
julia -e 'using IJulia; notebook(dir="demos")'
```

If you have not created the project-bound kernel yet, run this once from the repository root:

```bash
julia -e 'using IJulia; IJulia.installkernel("QMC", "--project=$(pwd())")'
```

Then select the `QMC` kernel in Jupyter or VS Code once.

If you prefer to launch Jupyter from Python or Conda, that is also fine, but Python is only the notebook frontend in that setup. The notebook must still execute on the `QMC` Julia kernel.

Most demos use `Lattice` or `DigitalNetB2`, so they also require `qmctoolscl` to be installed in a Python visible to Julia.

To run a notebook in VS Code:

1. Install the `Julia` and `Jupyter` extensions.
2. Open this repository folder in VS Code.
3. Open a notebook from `demos/`.
4. Click the notebook kernel picker and select `QMC`.
5. Restart the notebook kernel if it was previously attached to another interpreter.

Do not use the Python `qmcpy`, or generic `Python 3.12.x` kernel for these notebooks, or Julia code such as `using QMC` will fail with a Python `SyntaxError`. A generic Julia kernel may also miss repository-specific dependencies like `Plots`.

## Code Style

We use [JuliaFormatter.jl](https://github.com/domluna/JuliaFormatter.jl) with the [SciML style](https://github.com/SciML/SciMLStyle) for consistent formatting. The style is configured in `.JuliaFormatter.toml` at the project root and is picked up automatically:

```julia
using JuliaFormatter
format("src/")
format("test/")
```

Or via `make`:

```bash
make format
```

Please format your code before submitting a pull request.

## Adding a New Component

QMC.jl uses Julia's abstract type hierarchy with multiple dispatch. To add a new component:

### Discrete Distribution

1. Create `src/discrete_distribution/my_dist.jl`
2. Define a struct that subtypes `AbstractDiscreteDistribution`
3. Implement `gen_samples(dd::MyDist, n::Int)` → `Matrix{Float64}` (n × d)
4. Add `include` and `export` in `src/QMC.jl`
5. Add tests in `test/test_discrete_distributions.jl`

### True Measure

1. Create `src/true_measure/my_measure.jl`
2. Subtype `AbstractTrueMeasure`
3. Implement `transform(tm::MyMeasure, x::Matrix{Float64})` → `Matrix{Float64}`
4. Update module file and tests

### Integrand

1. Create `src/integrand/my_integrand.jl`
2. Subtype `AbstractIntegrand`
3. Implement `evaluate(f::MyIntegrand, x::Matrix{Float64})` → `Vector{Float64}`
4. Update module file and tests

### Stopping Criterion

1. Create `src/stopping_criterion/my_criterion.jl`
2. Subtype `AbstractStoppingCriterion`
3. Implement `integrate(sc::MyCriterion)` → `QMCResult`
4. Update module file and tests

### Kernel

1. Create `src/kernel/my_kernel.jl`
2. Subtype `AbstractKernel` (or `AbstractStationaryKernel` for distance-based kernels)
3. Implement `compute_kernel_eigenvalues(k::MyKernel, x)` and/or `kernel_eval(k, r)`
4. Update module file and tests

### Checklist for all new types

- Julia docstrings (triple-quoted `"""..."""`, with arguments and examples)
- A `Base.show` method for REPL display
- Unit tests covering construction, basic operation, and edge cases
- A demo notebook if the component is user-facing
- `include` and `export` entries in `src/QMC.jl`

## API Stability

QMC.jl groups its public surface into the following stability levels:

| Status | Representative symbols | Meaning |
|---|---|---|
| **Stable** | `IIDStdUniform`, `Lattice`, `DigitalNetB2`, `Gaussian`, `BrownianMotion`, `Keister`, `Genz`, `CubMCCLT`, `CubMCG`, `CubQMCLatticeG`, `CubQMCNetG`, `CubQMCNetGRep` | Expected to remain source-compatible except for deliberate documented breaking releases |
| **Beta** | `CubQMCBayesLatticeG`, `CubQMCBayesNetG`, `CubMLMC`, `CubMLMCCont`, `CubMLQMC`, `CubMLQMCCont` | Usable and tested, but advanced interfaces may still be refined before long-term stabilization |
| **Experimental** | `PFGPCI`, `UMBridgeWrapper`, `KernelMultiTask`, `KernelMultiTaskDerivs` | Exported for early adopters; behavior and interfaces may change with limited compatibility guarantees |
| **Placeholder** | `gpu_fwht`, `gpu_fwht!` | Exported names reserved for future functionality; current implementation falls back to CPU `fwht`/`fwht!` |

## Repository Layout

Most top-level and source subdirectories contain a local `README.md` describing their purpose. Useful starting points:

- [`benchmark/README.md`](benchmark/README.md) — standalone benchmarking and Julia-vs-QMCPy comparison tooling
- [`demos/README.md`](demos/README.md) — notebook demos and how to run them
- [`docs/OVERVIEW.md`](docs/OVERVIEW.md) — Documenter build/deploy layout
- [`RELEASING.md`](RELEASING.md) — release ladder, readiness gates, and tagging process
- [`src/README.md`](src/README.md) — package source tree and component folders
- [`test/README.md`](test/README.md) — unit tests, notebook tests, and coverage commands

## Benchmark Badges

The top-level benchmark badges track the latest published `develop` run. The speed badge is the weighted `Python time ÷ Julia time` ratio from the Julia-vs-QMCPy comparison script. The peak-memory badge compares QMCPy's `tracemalloc` peak against Julia's recorded allocation totals — treat it as an approximate signal rather than a strict apples-to-apples metric. See [`benchmark/README.md`](benchmark/README.md) for the full report structure, comparison scripts, and interpretation notes.

## IDE Tips (VS Code)

[VS Code](https://code.visualstudio.com) with the [Julia extension](https://www.julia-vscode.org/) is the recommended editor.

- Open `QMC.jl/` as your workspace
- Activate the project: `Ctrl/Cmd+Shift+P` → **Julia: Activate This Environment**
- Use the integrated terminal for test runs
- The Julia extension provides inline evaluation, debugging, and profiling

Helpful extensions: Julia, Jupyter, Git Graph, Code Spell Checker.
