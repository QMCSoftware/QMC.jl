# Test Suite

This directory contains the automated test suite for QMC.jl.

## Entry points

- `runtests.jl`: master test runner used by `Pkg.test()`.
- `run_notebooks.jl`: executes the demo notebooks as regression tests.

## Test files

- `test_discrete_distributions.jl`
- `test_true_measures.jl`
- `test_integrands.jl`
- `test_kernels.jl`
- `test_stopping_criteria.jl`
- `test_integration.jl`
- `test_multilevel.jl`
- `test_aqua.jl`

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
