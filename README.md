# QMC.jl: Quasi-Monte Carlo Community Software in Julia

[![Doc/Unit Tests](https://github.com/QMCSoftware/QMC.jl/actions/workflows/ci-full.yml/badge.svg?branch=develop)](https://github.com/QMCSoftware/QMC.jl/actions/workflows/ci-full.yml)
[![Docs and Demos](https://github.com/QMCSoftware/QMC.jl/actions/workflows/doc_demo.yml/badge.svg?branch=develop)](https://github.com/QMCSoftware/QMC.jl/actions/workflows/doc_demo.yml)
[![Benchmarking](https://github.com/QMCSoftware/QMC.jl/actions/workflows/benchmarking.yml/badge.svg?branch=develop)](https://github.com/QMCSoftware/QMC.jl/actions/workflows/benchmarking.yml)
[![Benchmark Speed](https://img.shields.io/endpoint?url=https://raw.githubusercontent.com/QMCSoftware/QMC.jl/benchmark-badges/badges/benchmark-speed-develop.json)](https://github.com/QMCSoftware/QMC.jl/actions/workflows/benchmarking.yml)
[![Benchmark Memory](https://img.shields.io/endpoint?url=https://raw.githubusercontent.com/QMCSoftware/QMC.jl/benchmark-badges/badges/benchmark-memory-develop.json)](https://github.com/QMCSoftware/QMC.jl/actions/workflows/benchmarking.yml)
[![codecov](https://codecov.io/gh/QMCSoftware/QMC.jl/branch/develop/graph/badge.svg)](https://codecov.io/gh/QMCSoftware/QMC.jl)
[![License](https://img.shields.io/badge/license-Apache%202.0-green.svg)](LICENSE)

[![Unit Coverage](https://img.shields.io/endpoint?url=https://raw.githubusercontent.com/QMCSoftware/QMC.jl/benchmark-badges/badges/coverage-unit-develop.json)](https://github.com/QMCSoftware/QMC.jl/actions/workflows/ci-full.yml)
[![Doctest Coverage](https://img.shields.io/endpoint?url=https://raw.githubusercontent.com/QMCSoftware/QMC.jl/benchmark-badges/badges/coverage-doctest-develop.json)](https://github.com/QMCSoftware/QMC.jl/actions/workflows/doc_demo.yml)
[![Notebook Coverage](https://img.shields.io/endpoint?url=https://raw.githubusercontent.com/QMCSoftware/QMC.jl/benchmark-badges/badges/coverage-notebook-develop.json)](https://github.com/QMCSoftware/QMC.jl/actions/workflows/doc_demo.yml)
[![Benchmark Coverage](https://img.shields.io/endpoint?url=https://raw.githubusercontent.com/QMCSoftware/QMC.jl/benchmark-badges/badges/coverage-bench-develop.json)](https://github.com/QMCSoftware/QMC.jl/actions/workflows/benchmarking.yml)

A Julia port of [QMCPy](https://github.com/QMCSoftware/QMCSoftware) — quasi-Monte Carlo point generators, measure transforms, and adaptive stopping criteria for high-dimensional numerical integration.

Quasi-Monte Carlo (QMC) methods approximate multivariate integrals using four interacting components: a **discrete distribution** (low-discrepancy sequence), a **true measure** (target probability space), an **integrand** (function to evaluate), and a **stopping criterion** (adaptive error control). QMC.jl provides plug-and-play implementations of each, following the same abstract-type framework as QMCPy so that components from both libraries compose naturally.

## Quick Start

```julia
using Pkg; Pkg.add(url="https://github.com/QMCSoftware/QMC.jl")
using QMC

dd = Lattice(3; randomize=true, seed=7)
f  = Keister(Gaussian(dd; covariance=0.5))
sc = CubQMCLatticeG(f; abs_tol=1e-3)

result = integrate(sc)
println("Estimate: $(result.solution)")   # ≈ 2.168
println("Exact:    $(keister_exact(3))")
```

## Resources

The [QMC.jl documentation](https://QMCSoftware.github.io/QMC.jl/) contains a detailed **API reference** with doctests and a collection of rendered **demo notebooks**. Good starting points:

- [Introduction notebook](demos/qmc.jl_intro.ipynb) and [quickstart notebook](demos/quickstart.ipynb)
- [Mathematical description of components](docs/src/components.md)
- [Full demo list](demos/README.md) — 26 notebooks covering sampling, multilevel QMC, Bayesian optimization, sensitivity analysis, and more
- Aleksei Sorokin's [2023 PyData Chicago tutorial](https://www.youtube.com/watch?v=bRcKiLA2yBQ) (QMCPy; concepts apply directly)

In the Julia REPL, help is always one keystroke away:

```julia
using QMC
?CubQMCLatticeG       # help mode
@doc CubQMCBayesNetG  # full docstring
```

## Installation

### For users

Once QMC.jl is registered in the Julia General Registry:

```julia
using Pkg
Pkg.add("QMC")
```

Until then, install directly from GitHub:

```julia
using Pkg
Pkg.add(url="https://github.com/QMCSoftware/QMC.jl")
```

For `Lattice`, `DigitalNetB2`, and `Halton`, also install the QMCToolsCL runtime into a Python visible to Julia:

```bash
pip install qmctoolscl
```

If Julia should use a specific Python interpreter, set `ENV["QMC_PYTHON"] = "/path/to/python"` before loading QMC.

### For contributors

See the [contributing guidelines](CONTRIBUTING.md) for the full developer setup, testing instructions, and how to add new components.

## Citation

If you find QMC.jl helpful in your work, please cite:

```bibtex
@misc{qmcjl2026,
  author = {Sou-Cheng T. Choi and Fred J. Hickernell and Aleksei G. Sorokin and contributors},
  title  = {{QMC.jl}: Quasi-Monte Carlo Community Software in Julia},
  year   = {2026},
  url    = {https://github.com/QMCSoftware/QMC.jl}
}
```

We maintain a list of [publications on the development and use of QMC.jl and QMCPy](https://qmcpy.org/publications/).

## Development

Want to contribute to QMC.jl? Please see our [guidelines for contributors](CONTRIBUTING.md), which cover developer setup, running tests, building documentation, code style, and how to add new component types.

This software would not be possible without the efforts of the [QMC community](community.md) including our steering council, collaborators, contributors, and sponsors.

Some repository content was produced with the help of AI tools (Claude, GPT) and reviewed by the authors and contributors.

## License

Apache 2.0 — see [LICENSE](LICENSE) for details.
