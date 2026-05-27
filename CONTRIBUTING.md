# Contributing to QMCJu

Thank you for your interest in contributing to QMCJu! This guide walks through the full developer setup, project conventions, and how to add new components.

Please submit **pull requests** to the `develop` branch and **issues** using a template from `.github/ISSUE_TEMPLATE/`.

Join team communications at [qmc-software@googlegroups.com](mailto:qmc-software@googlegroups.com). If you develop a new component, consider writing a blog for [qmcju.org](https://qmcju.org).

## Developer Setup

### Prerequisites

| Tool | Version | Notes |
|---|---|---|
| [Conda](https://docs.conda.io/en/latest/miniconda.html) | any recent | manages the Python environment |
| [Julia](https://julialang.org/downloads/) | ≥ 1.10 | `brew install julia` on macOS, or download from julialang.org |
| Git | any recent | to clone the repo |

### 1. Clone and enter the project

```bash
git clone https://github.com/QMCSoftware/QMCSoftware.git
cd QMCSoftware/qmcju_software
```

### 2. Create the Conda environment

If you also work on the Python QMCJu package, reuse its environment. Otherwise:

```bash
conda create -n qmcju python=3.12 -y
conda activate qmcju
```

### 3. Install Julia dependencies

```bash
julia --project=. -e 'using Pkg; Pkg.instantiate()'
```

### 4. Install IJulia for notebooks

```bash
julia -e 'using Pkg; Pkg.add("IJulia")'
```

This registers the Julia 1.10 kernel with Jupyter so you can run and edit demo notebooks.

### 5. Verify everything works

```bash
julia --project=. -e 'using Pkg; Pkg.test()'
```

All tests should pass with zero failures.

## Running Tests

Full test suite:

```bash
julia --project=. -e 'using Pkg; Pkg.test()'
```

Interactive testing (useful during development):

```julia
using Pkg
Pkg.activate(".")
include("test/runtests.jl")
```

Individual test groups:

```julia
using QMCJu, Test, Statistics, LinearAlgebra, Distributions
import QMCJu: Uniform, Kumaraswamy  # resolve name conflicts with Distributions

include("test/test_discrete_distributions.jl")
include("test/test_true_measures.jl")
include("test/test_integrands.jl")
include("test/test_kernels.jl")
include("test/test_stopping_criteria.jl")
include("test/test_integration.jl")
```

Note: `Uniform` and `Kumaraswamy` are exported by both QMCJu and Distributions.jl. When using both packages, resolve the ambiguity with `import QMCJu: Uniform, Kumaraswamy`.

## Project Structure

```
qmcju_software/
├── Project.toml                # Julia package metadata and dependencies
├── src/
│   ├── QMCJu.jl                # Main module: includes, exports
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
    ├── *.jl                    # Julia script versions
    └── *.ipynb                 # Jupyter notebook versions
```

## Running Demos

Launch the Jupyter notebook server:

```bash
conda activate qmcju
julia -e 'using IJulia; notebook(dir="demos")'
```

Or open any `.ipynb` in VS Code with the Jupyter extension, then select the Julia 1.10 kernel.

## Code Style

We use [JuliaFormatter.jl](https://github.com/domluna/JuliaFormatter.jl) for consistent formatting:

```julia
using JuliaFormatter
format("src/")
format("test/")
```

Please format your code before submitting a pull request.

## Adding a New Component

QMCJu uses Julia's abstract type hierarchy with multiple dispatch. To add a new component:

### Discrete Distribution

1. Create `src/discrete_distribution/my_dist.jl`
2. Define a struct that subtypes `AbstractDiscreteDistribution`
3. Implement `gen_samples(dd::MyDist, n::Int)` → `Matrix{Float64}` (n × d)
4. Add `include` and `export` in `src/QMCJu.jl`
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
- `include` and `export` entries in `src/QMCJu.jl`

## IDE Tips (VS Code)

[VS Code](https://code.visualstudio.com) with the [Julia extension](https://www.julia-vscode.org/) is the recommended editor.

- Open `qmcju_software/` as your workspace
- Activate the project: `Ctrl/Cmd+Shift+P` → **Julia: Activate This Environment**
- Use the integrated terminal for test runs
- The Julia extension provides inline evaluation, debugging, and profiling

Helpful extensions: Julia, Jupyter, Git Graph, Code Spell Checker.
