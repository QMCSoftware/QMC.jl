# Test Suite

This directory contains the automated test suite for QMC.jl.

## Entry points

- `runtests.jl`: master test runner used by `Pkg.test()`.
- `run_notebooks.jl`: executes the demo notebooks as regression tests.
- `release_parity.jl`: curated QMCPy 2.3 release-parity gate backed by a checked-in golden fixture.

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
# or, via the Makefile with file-level process sharding
make test TEST_JOBS=2 TEST_THREADS=1

# Unit tests with coverage instrumentation
julia --project=. -e 'using Pkg; Pkg.test(coverage=true)'
# or
make coverage TEST_JOBS=2 TEST_THREADS=1

# Curated QMCPy 2.3 release-parity checks
make release-parity PYTHON=/path/to/python-with-qmcpy

# Documenter doctests only
make doctest

# Notebook regression tests
julia --project=. test/run_notebooks.jl
# or, sharded across multiple Julia processes
make notebook NOTEBOOK_JOBS=2 NOTEBOOK_THREADS=1

# Execute notebooks with Jupyter and overwrite output cells in place
make notebook-update NOTEBOOK_JOBS=2 NOTEBOOK_THREADS=1 NOTEBOOK_KERNEL=qmc-1.12

# Update a single notebook in place
make notebook-update-quickstart NOTEBOOK_KERNEL=qmc-1.12
```

`make coverage` also processes the raw `*.cov` files locally, writes `lcov.info`, and prints a source-coverage summary for `src/`.
`make release-parity` is intentionally narrower than `make test`: it runs a small checked-in QMCPy 2.3 fixture that covers deterministic low-discrepancy samples/spawns, true-measure transforms, integrand values, stopping-criterion sample accounting, multilevel level accounting, and one resume case. Exact bit-level parity is required for the deterministic cases; seeded stopping criteria compare solutions within the same `2 * max(abs_tol, rel_tol * |value|)` agreement budget used by the benchmark parity harness.
`make doctest` runs the `jldoctest` examples in the package docstrings under `src/` and any docs pages that contain doctests, without rendering the full HTML docs.
CI uploads the same LCOV-style output to Codecov and stores it as a workflow artifact.

`TEST_JOBS` and `NOTEBOOK_JOBS` shard whole test files or notebooks across multiple Julia processes. `TEST_THREADS` and `NOTEBOOK_THREADS` control Julia threads inside each shard. The conservative default is `1` thread per shard to avoid oversubscribing CI runners.

`make notebook` is the fast regression-test path and does not modify `.ipynb` files. `make notebook-update` switches to Jupyter `nbconvert --execute --inplace` using the kernel named by `NOTEBOOK_KERNEL` and writes fresh output cells back into the notebooks. Both commands shard the runnable notebook list across `NOTEBOOK_JOBS` Julia processes; for example, if there are 34 runnable notebooks and `NOTEBOOK_JOBS=2`, each shard handles 17 notebooks. Use `NOTEBOOK_JOBS=1` to force one sequential pass over the full list.

When the pinned QMCPy reference changes, refresh the fixture with:

```bash
make release-parity-refresh PYTHON=/path/to/python-with-qmcpy
```
