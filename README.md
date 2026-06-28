# QuasiMC.jl: Quasi-Monte Carlo Community Software in Julia

[![Doc/Unit Tests](https://github.com/QMCSoftware/QuasiMC.jl/actions/workflows/ci-full.yml/badge.svg?branch=develop)](https://github.com/QMCSoftware/QuasiMC.jl/actions/workflows/ci-full.yml) [![Docs and Demos](https://github.com/QMCSoftware/QuasiMC.jl/actions/workflows/doc_demo.yml/badge.svg?branch=develop)](https://github.com/QMCSoftware/QuasiMC.jl/actions/workflows/doc_demo.yml) [![Benchmarking](https://github.com/QMCSoftware/QuasiMC.jl/actions/workflows/benchmarking.yml/badge.svg?branch=develop)](https://github.com/QMCSoftware/QuasiMC.jl/actions/workflows/benchmarking.yml)

[![Benchmark Speed](https://img.shields.io/endpoint?url=https://raw.githubusercontent.com/QMCSoftware/QuasiMC.jl/benchmark-badges/badges/benchmark-speed-develop.json)](https://github.com/QMCSoftware/QuasiMC.jl/actions/workflows/benchmarking.yml) [![Benchmark Memory](https://img.shields.io/endpoint?url=https://raw.githubusercontent.com/QMCSoftware/QuasiMC.jl/benchmark-badges/badges/benchmark-memory-develop.json)](https://github.com/QMCSoftware/QuasiMC.jl/actions/workflows/benchmarking.yml) [![Contributors](https://img.shields.io/github/contributors/QMCSoftware/QuasiMC.jl?label=Contributors&cacheSeconds=300)](https://github.com/QMCSoftware/QuasiMC.jl/graphs/contributors) [![GitHub Stars](https://img.shields.io/github/stars/QMCSoftware/QuasiMC.jl?style=flat&label=GitHub%20Stars)](https://github.com/QMCSoftware/QuasiMC.jl/stargazers)

[![Overall Coverage](https://img.shields.io/codecov/c/github/QMCSoftware/QuasiMC.jl/develop?label=Overall%20Coverage)](https://codecov.io/gh/QMCSoftware/QuasiMC.jl) [![Unit Test Coverage](https://img.shields.io/codecov/c/github/QMCSoftware/QuasiMC.jl/develop?flag=unit&label=Unit%20Test%20Coverage)](https://codecov.io/gh/QMCSoftware/QuasiMC.jl) [![Doctest Coverage](https://img.shields.io/codecov/c/github/QMCSoftware/QuasiMC.jl/develop?flag=doctest&label=Doctest%20Coverage)](https://codecov.io/gh/QMCSoftware/QuasiMC.jl) [![Demo Coverage](https://img.shields.io/codecov/c/github/QMCSoftware/QuasiMC.jl/develop?flag=notebook&label=Demo%20Coverage)](https://codecov.io/gh/QMCSoftware/QuasiMC.jl) [![Benchmark Coverage](https://img.shields.io/codecov/c/github/QMCSoftware/QuasiMC.jl/develop?flag=bench&label=Benchmark%20Coverage)](https://codecov.io/gh/QMCSoftware/QuasiMC.jl)


A Julia port of [QMCPy](https://github.com/QMCSoftware/QMCSoftware) — quasi-Monte Carlo point generators, measure transforms, and adaptive stopping criteria for high-dimensional numerical integration.

Quasi-Monte Carlo (QMC) methods approximate multivariate integrals using four interacting components: a **discrete distribution** (low-discrepancy sequence), a **true measure** (target probability space), an **integrand** (function to evaluate), and a **stopping criterion** (adaptive error control). QuasiMC.jl provides plug-and-play implementations of each, following the same abstract-type framework as QMCPy so that components from both libraries compose naturally.

## Quick Start

From a terminal, start Julia:

```bash
julia
```

Then run:

```julia
using Pkg; Pkg.add(url="https://github.com/QMCSoftware/QuasiMC.jl")
using QuasiMC

dd = Lattice(3; randomize=true, seed=7)
f  = Keister(Gaussian(dd; covariance=0.5))
sc = CubQMCLatticeG(f; abs_tol=1e-3)

result = integrate(sc)
println("Estimate: $(round(result.solution, digits=5))")
println("Exact:    $(round(keister_exact(3), digits=5))")
```

Quit Julia with `Ctrl-D` or `exit()`.

## Resources

The [QuasiMC.jl documentation](https://QMCSoftware.github.io/QuasiMC.jl/) contains a detailed **API reference** with doctests and a collection of rendered **demo notebooks**. Good starting points:

- [Introduction notebook](demos/quasimc.jl_intro.ipynb) and [quickstart notebook](demos/quickstart.ipynb)
- [Mathematical description of components](docs/src/components.md)
- [Full demo list](demos/README.md) — 26 notebooks covering sampling, multilevel QMC, Bayesian optimization, sensitivity analysis, and more
- Fred Hickernell's [2020 MCQMC tutorial video](https://www.youtube.com/watch?v=gL8M_7c-YUE) (QMCPy; concepts apply directly)
- Aleksei Sorokin's [2023 PyData Chicago tutorial](https://www.youtube.com/watch?v=bRcKiLA2yBQ) (QMCPy; concepts apply directly)
- [Publications on the development and use of QMCPy](https://qmcpy.org/publications/)

In the Julia REPL (Read-Eval-Print Loop, an interactive command-line environment for Julia), enter help mode by typing `?` at the `julia>` prompt. The prompt changes to `help?>`, and then you can type the object name:

```text
julia> using QuasiMC

julia> ?
help?> CubQMCLatticeG
```

From the normal Julia prompt, scripts, or notebooks, you can also inspect docstrings with:

```julia
@doc CubQMCLatticeG
@doc CubQMCBayesNetG
```

## Installation

### For users

Once QuasiMC.jl is registered in the Julia General Registry:

```julia
using Pkg
Pkg.add("QuasiMC")
```

Until then, install directly from GitHub:

```julia
using Pkg
Pkg.add(url="https://github.com/QMCSoftware/QuasiMC.jl")
```

For `Lattice`, `DigitalNetB2`, and `Halton`, also install the QMCToolsCL runtime (version ≥ 1.2.3) into a Python visible to Julia:

```bash
pip install 'qmctoolscl>=1.2.3'
```

`IIDStdUniform` and `Kronecker`, and all true measures, integrands, and stopping criteria, work without this step.

If Julia should use a specific Python interpreter, set `ENV["QUASIMC_PYTHON"] = "/path/to/python"` before first use of those generators (legacy `ENV["QMC_PYTHON"]` is still accepted).

### For contributors

See the [contributing guidelines](CONTRIBUTING.md) for the full developer setup, testing instructions, and how to add new components.

## Citation

If you find QuasiMC.jl helpful in your work, please cite:

```bibtex
@misc{qmcjl2026,
  author = {Sou-Cheng T. Choi and Fred J. Hickernell and Aleksei G. Sorokin and contributors},
  title  = {{QuasiMC.jl}: Quasi-Monte Carlo Community Software in Julia},
  year   = {2026},
  url    = {https://github.com/QMCSoftware/QuasiMC.jl}
}
```

We maintain a list of [publications on the development and use of QuasiMC.jl and QMCPy](https://qmcpy.org/publications/).

## Development

Want to contribute to QuasiMC.jl? Please see our [guidelines for contributors](CONTRIBUTING.md), which cover developer setup, running tests, building documentation, code style, and how to add new component types.

This software would not be possible without the efforts of the [QMC community](community.md) including our steering council, collaborators, contributors, and sponsors.

Some repository content was produced with the help of AI tools (Claude, GPT) and reviewed by the authors and contributors.

## License

Apache 2.0 — see [LICENSE](LICENSE) for details.
