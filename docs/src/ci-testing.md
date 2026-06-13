# CI/CD Testing

QMC.jl uses GitHub Actions for continuous integration. Four workflow files
live in `.github/workflows/` and serve distinct purposes.

## Workflow Overview

| Workflow | File | Trigger | Platforms | Scope |
|----------|------|---------|-----------|-------|
| **CI** | `ci.yml` | Feature-branch pushes, PRs, manual | Linux | Unit tests + notebooks + coverage |
| **CI Full** | `ci-full.yml` | PRs to `develop`/`master` | Linux, macOS, Windows | Unit tests |
| **Nightly** | `nightly.yml` | Daily at 05:30 UTC | macOS, Windows | Unit tests |
| **Docs** | `docs.yml` | Push to `develop`/`master` (docs/src paths) | Linux | Documenter build + deploy |

All workflows use **concurrency groups** with `cancel-in-progress: true`
so that superseded pushes do not waste CI minutes.

## CI (`ci.yml`)

The primary fast-feedback workflow, triggered on feature-branch pushes
(`develop`/`master` are handled by the other workflows), on all pull requests,
and via manual dispatch.

**Unit tests job:**

- Runs on `ubuntu-latest` with Julia 1.12.
- Installs Python 3.13 and `qmctoolscl` (required by `DigitalNetB2`, `Lattice`, etc.).
- Executes `make coverage`, which runs `test/runtests.jl` with Julia coverage instrumentation enabled.
- Shards whole test files across `TEST_JOBS` Julia subprocesses (default GitHub Actions variable fallback: `2`) while keeping `TEST_THREADS=1` inside each shard to avoid oversubscription.
- Processes the resulting coverage data into `lcov.info`.
- Uploads `lcov.info` both to Codecov and as a GitHub Actions artifact.

**Notebooks job:**

- Runs after the unit tests pass.
- Only executes when `demos/`, `src/`, or `test/run_notebooks.jl` changed
  in the triggering commit, keeping CI fast for documentation-only or
  workflow-only changes.
- Runs all `.ipynb` demo notebooks via `make notebook`.
- Shards notebooks across `NOTEBOOK_JOBS` Julia subprocesses (default GitHub Actions variable fallback: `2`) while keeping `NOTEBOOK_THREADS=1` inside each shard.

## CI Full (`ci-full.yml`)

A cross-platform sweep triggered on pull requests targeting `develop` or `master`.

- Tests Julia 1.10 and 1.11 on Linux, macOS, and Windows (6 jobs total).
- Runs unit tests only (no notebooks or doctests) to keep macOS/Windows
  jobs fast and avoid platform-specific rendering issues.

## Nightly (`nightly.yml`)

A scheduled workflow that runs daily at 05:30 UTC, testing macOS and Windows
with Julia 1.11. This catches breakages from upstream Julia or dependency
updates without blocking day-to-day development.

Can also be triggered manually via `workflow_dispatch`.

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

**Build documentation:**

```bash
julia --project=docs docs/make.jl
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
