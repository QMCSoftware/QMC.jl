# Test Suite

This directory contains the automated test suite for QMC.jl.

## Entry points

- `runtests.jl`: master test runner used by `Pkg.test()`.
- `run_notebooks.jl`: executes the demo notebooks as regression tests.

## Test files

- `test_discrete_distributions.jl`: tests discrete distribution constructions and sampling behavior.
- `test_true_measures.jl`: validates true-measure definitions and related properties.
- `test_integrands.jl`: checks integrand setup, transformations, and evaluations.
- `test_kernels.jl`: verifies kernel implementations and expected numerical behavior.
- `test_stopping_criteria.jl`: tests stopping rules and convergence-trigger logic.
- `test_integration.jl`: exercises end-to-end integration workflows and outputs.
- `test_multilevel.jl`: covers multilevel algorithms and level-coupling behavior.
- `test_aqua.jl`: runs Aqua automatic quality checks.

## Local commands

```bash
# Standard unit tests
julia --project=. -e 'using Pkg; Pkg.test()'

# Unit tests with coverage instrumentation
julia --project=. -e 'using Pkg; Pkg.test(coverage=true)'
# or
make coverage

# Notebook regression tests
julia --project=. test/run_notebooks.jl
```

`make coverage` also processes the raw `*.cov` files locally, writes
`lcov.info`, and prints a source-coverage summary for `src/`.
CI uploads the same LCOV-style output to Codecov and stores it as a workflow
artifact.
