# CI/CD Testing

QMC.jl uses GitHub Actions for continuous integration and benchmark collection.
Four workflow files in `.github/workflows/` handle the main feedback paths.
For local linting and repeatable smoke runs of those workflows, see
[Workflow Debugging](workflow-debugging.md).

## Workflow Overview

| Workflow | File | Trigger | Platforms | Scope |
|----------|------|---------|-----------|-------|
| **CI** | `ci.yml` | Every `push`; every `pull_request`; manual | Linux | Unit tests + notebooks + coverage |
| **CI Full** | `ci-full.yml` | `push` to `develop`/`master`; PR into `develop`/`master`; manual | Linux, macOS, Windows | Unit tests |
| **Benchmarking** | `benchmarking.yml` | `push` to `develop`/`master` on benchmark-relevant paths; manual | Linux | Julia-vs-Julia + Julia-vs-QMCPy benchmarks |
| **Docs** | `docs.yml` | `push` / PR on docs-related paths; manual | Linux | Documenter build + deploy |

## Policy

- Linux is the default feedback path and runs on every push via `ci.yml`.
- macOS and Windows are reserved for `develop`/`master` pushes, pull requests
  into those branches, and manual runs via `ci-full.yml`.
- Notebook regression tests run only on Linux. They are skipped unless
  `demos/`, `src/`, or `test/run_notebooks.jl` changed.
- Benchmark collection is separated from unit testing. `benchmarking.yml` is
  Linux-only, path-filtered, and uploads `benchmark/results/` as an artifact.
- The benchmarking workflow pins its Python dependencies through
  `benchmark/requirements.txt` so cross-commit comparisons are not invalidated
  by unrelated upstream package releases. Changes to the shared
  `test/requirements.txt` pin file also retrigger the benchmark workflow.
- On push-triggered benchmark runs, the Julia-vs-Julia comparison uses the
  previous pushed commit as the reference revision when GitHub provides one;
  manual runs fall back to `REV=HEAD`.
- `concurrency` cancels superseded runs, and the `ci.yml`, `ci-full.yml`, and
  `benchmarking.yml` groups include the event name so a pull request run does
  not cancel the sibling push run for the same ref.
- There is no nightly CI schedule.

## CI (`ci.yml`)

The primary fast-feedback workflow runs on every push, every pull request, and
manual dispatch.

**Unit tests job:**

- Runs on `ubuntu-latest` with Julia 1.12.
- Installs Python 3.13 and pinned `qmctoolscl` from `test/requirements.txt`.
- Executes `make coverage`, which runs `test/runtests.jl` with Julia coverage
  instrumentation enabled.
- Shards whole test files across `TEST_JOBS` Julia subprocesses (default GitHub
  Actions variable fallback: `2`) while keeping `TEST_THREADS=1` inside each
  shard to avoid oversubscription.
- Processes the resulting coverage data into `lcov.info`.
- Uploads `lcov.info` both to Codecov and as a GitHub Actions artifact.

**Notebooks job:**

- Runs after the unit tests pass.
- Only executes when `demos/`, `src/`, or `test/run_notebooks.jl` changed in
  the triggering commit, keeping CI fast for documentation-only or
  workflow-only changes.
- Runs all `.ipynb` demo notebooks via `make notebook`.
- Shards notebooks across `NOTEBOOK_JOBS` Julia subprocesses (default GitHub
  Actions variable fallback: `2`) while keeping `NOTEBOOK_THREADS=1` inside
  each shard.

## CI Full (`ci-full.yml`)

A cross-platform sweep for protected branches.

- Triggers on pushes to `develop` or `master`, on pull requests targeting those
  branches, and via manual dispatch.
- Tests Julia 1.10 and 1.11 on Linux, macOS, and Windows.
- Runs unit tests only. Notebook regression tests stay in the Linux `ci.yml`
  path so macOS/Windows jobs remain relatively fast and less brittle.

## Benchmarking (`benchmarking.yml`)

The benchmark workflow is separate from the test workflows.

- Triggers on pushes to `develop` or `master` when benchmark-relevant files
  change, and via manual dispatch.
- Runs on `ubuntu-latest` with Julia 1.12 and Python 3.13.
- Checks out full git history so `make bench-all REV=<previous-commit>` can
  materialize the baseline revision in a temporary worktree.
- Installs pinned benchmark Python dependencies from
  `benchmark/requirements.txt`, including `qmcpy==2.3`.
- Runs `make bench-all`, not the broader `make ci`, so benchmark artifacts
  measure the checked-in sources rather than a formatter-mutated worktree.
- Uses `BENCH_BLAS_THREADS` for both Julia and Python-side native-kernel thread
  settings.
- Uploads the generated `benchmark/results/` directory as a GitHub Actions
  artifact for later inspection.

## Docs (`docs.yml`)

Builds the Documenter.jl documentation and deploys to GitHub Pages.

- Triggered on pushes to `develop`/`master` when `docs/`, `src/`,
  `Project.toml`, or the workflow file itself changes.
- Also runs on matching PRs (build-only, no deploy).
- Uses `julia --project=docs` to resolve the docs-specific dependency set.
- Deploys via `deploydocs()` when `CI=true` (only on push, not PR).

## Running Tests Locally

**Unit tests:**

```bash
julia --project=. -e 'using Pkg; Pkg.test()'
# or
make test TEST_JOBS=2 TEST_THREADS=1
```

**Unit tests with coverage instrumentation:**

```bash
julia --project=. -e 'using Pkg; Pkg.test(coverage=true)'
# or
make coverage TEST_JOBS=2 TEST_THREADS=1
```

**A single demo notebook:**

```bash
julia --project=. test/run_notebooks.jl quickstart
```

**All demo notebooks:**

```bash
julia --project=. test/run_notebooks.jl
# or
make notebook NOTEBOOK_JOBS=2 NOTEBOOK_THREADS=1
```

**Overwrite notebooks with fresh executed outputs:**

```bash
make notebook-update NOTEBOOK_JOBS=2 NOTEBOOK_THREADS=1 NOTEBOOK_KERNEL=qmc-1.12
# or
make notebook-update-quickstart NOTEBOOK_KERNEL=qmc-1.12
```

`NOTEBOOK_JOBS` shards the runnable notebook list across separate Julia
processes. If there are 34 runnable notebooks and `NOTEBOOK_JOBS=2`, the run is
split into two 17-notebook shards. Set `NOTEBOOK_JOBS=1` when you want one
sequential pass over the entire notebook set.

**Build documentation:**

```bash
julia --project=docs docs/make.jl
```

**Benchmark locally:**

```bash
pip install -r benchmark/requirements.txt
make bench-all REV=HEAD~1 BENCH_BLAS_THREADS=2
```

## Coverage Reports

QMC.jl publishes test coverage through the fast Linux CI workflow.

- The repository README badge points at the Codecov report for the default branch.
- `ci.yml` converts Julia's `*.cov` outputs into `lcov.info`.
- The resulting LCOV file is uploaded to Codecov and also attached to the workflow run as an artifact.

The local `Pkg.test(coverage=true)` command is the same instrumentation mode used by CI.
`make coverage` additionally processes the raw `*.cov` files into `lcov.info`
and prints a source-coverage summary for `src/`.

## Test File Structure

Tests are organized to mirror the Python QMCSoftware test suite:

| File | Coverage |
|------|----------|
| `test_discrete_distributions.jl` | IIDStdUniform, Lattice, DigitalNetB2, Halton, Kronecker, scrambling, windowed sampling |
| `test_true_measures.jl` | All true measures including AcceptanceRejection, AcceptanceRejectionReal, DistributionsWrapper |
| `test_integrands.jl` | All integrands including FinancialOption variants, SensitivityIndices, BayesianLRCoeffs |
| `test_kernels.jl` | Shift-invariant, digital-shift-invariant, Matern, Gaussian, combined kernels |
| `test_stopping_criteria.jl` | All stopping criteria, rel\_tol, resume/checkpoint, IterationLog |
| `test_integration.jl` | End-to-end integration pipelines |
| `test_multilevel.jl` | Multilevel interface, CubMLMC, CubMLMCCont, CubMLQMCCont |
| `run_notebooks.jl` | Executes all demo notebooks, reports errors and warnings |

## Prerequisites

All CI jobs require:

- **Julia** 1.10+ (pinned versions in each workflow matrix)
- **Python** 3.13 with `qmctoolscl` (`pip install qmctoolscl`)
- Julia package dependencies installed via `Pkg.instantiate()`

## Adding a New Test

1. Add your `@testset` block to the appropriate `test_*.jl` file.
2. If testing a new component category, create a new file and add an
   `include()` line in `runtests.jl`.
3. Push — CI will run the tests automatically.

## Secrets

- `CODECOV_TOKEN` — used for Codecov upload when required by the repository configuration; CI is configured not to fail if upload is unavailable.
- `GITHUB_TOKEN` — provided automatically by GitHub; used for docs deployment.
