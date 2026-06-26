# CI/CD Testing

QMC.jl uses GitHub Actions for continuous integration and benchmark collection. Four workflow files in `.github/workflows/` handle the main feedback paths. For local linting and repeatable smoke runs of those workflows, see [Workflow Debugging](workflow-debugging.md).

## Workflow Overview

| Workflow | File | Trigger | Platforms | Scope |
|----------|------|---------|-----------|-------|
| **Fast CI** | `ci.yml` | feature-branch `push`; every PR into `develop`/`master`; manual | Linux | Unit tests + coverage + doctests |
| **Full CI** | `ci-full.yml` | `push` to `develop`/`master`; PRs with code/docs/workflow changes; manual | Linux, macOS, Windows | Unit tests + one Linux coverage lane |
| **Benchmarking** | `benchmarking.yml` | `push` to `develop`/`master` on benchmark-relevant paths; manual | Linux | Julia-vs-Julia + Julia-vs-QMCPy benchmarks |
| **Docs and Demos** | `doc_demo.yml` | `push` on docs, demo, and source paths; docs-smoke PRs on docs/source changes; manual | Linux | Documenter build + deploy + notebook regression |

## Policy

- Linux is the default fast-feedback path and runs on feature-branch pushes plus all pull requests into `develop`/`master` via `ci.yml`.
- macOS and Windows are reserved for `develop`/`master` pushes, selected pull requests, and manual runs via `ci-full.yml`.
- Benchmark collection is separated from unit testing. `benchmarking.yml` is Linux-only, path-filtered, and uploads `benchmark/results/` as an artifact.
- The benchmarking workflow pins its Python dependencies through `benchmark/requirements.txt` so cross-commit comparisons are not invalidated by unrelated upstream package releases. Changes to the shared `test/requirements.txt` pin file also retrigger the benchmark workflow.
- On push-triggered benchmark runs, the Julia-vs-Julia comparison uses the previous pushed commit as the reference revision when GitHub provides one; manual runs fall back to `REV=HEAD`.
- `concurrency` cancels superseded runs, and the `ci.yml`, `ci-full.yml`, and `benchmarking.yml` groups include the event name so a pull request run does not cancel the sibling push run for the same ref.
- There is no nightly CI schedule.

## Fast CI (`ci.yml`)

The primary fast-feedback workflow runs on non-`develop`/`master` pushes, on pull requests targeting `develop` or `master`, and via manual dispatch.

**Unit tests job:**

- Runs on `ubuntu-latest` with Julia 1.12.
- Installs Python 3.13 and pinned `qmctoolscl` from `test/requirements.txt`.
- Executes `make coverage`, which runs `test/runtests.jl` with Julia coverage instrumentation enabled.
- Executes `make doctest`, which runs the Documenter `jldoctest` examples from the package docstrings under `src/` and any docs pages that contain doctests, without a full docs render.
- Shards whole test files across `TEST_JOBS` Julia subprocesses (default GitHub Actions variable fallback: `2`) while keeping `TEST_THREADS=1` inside each shard to avoid oversubscription.
- Processes the resulting coverage data into `lcov.info`.
- Uploads `lcov.info` both to Codecov and as a GitHub Actions artifact.

## Full CI (`ci-full.yml`)

A cross-platform sweep for protected branches.

- Triggers on pushes to `develop` or `master`, on pull requests that touch `src/`, `test/`, `docs/`, `benchmark/`, `.github/`, `Project.toml`, `Manifest.toml`, or `Makefile`, and via manual dispatch.
- Uses an orthogonal matrix: Linux on Julia 1.10 and 1.11, plus macOS and Windows on Julia 1.12.
- Runs unit tests on every lane.
- The Linux Julia 1.11 lane runs `make coverage`, uploads `lcov.info`, and feeds the `develop` branch Codecov badge; the other lanes run plain `Pkg.test()`.
- Does not run `make doctest`; doctest and full docs validation for `develop`/`master` live in `doc_demo.yml`, which already builds the documentation and therefore exercises the Documenter doctests there.

## Benchmarking (`benchmarking.yml`)

The benchmark workflow is separate from the test workflows.

- Triggers on pushes to `develop` or `master` when benchmark-relevant files change, and via manual dispatch.
- Runs on `ubuntu-latest` with Julia 1.12 and Python 3.13.
- Checks out full git history so `make bench-all REV=<previous-commit>` can materialize the baseline revision in a temporary worktree.
- Installs pinned benchmark Python dependencies from `benchmark/requirements.txt`; the QMCPy benchmark version pin itself lives in `benchmark/qmcpy-requirements.txt`.
- Runs `make bench-all`, not the broader `make ci`, so benchmark artifacts measure the checked-in sources rather than a formatter-mutated worktree.
- Uses `BENCH_BLAS_THREADS` for both Julia and Python-side native-kernel thread settings.
- Treats the seeded Julia-vs-QMCPy parity checks as a guard: `make bench-compare-py` fails if no comparable `integrate` or deterministic transform/evaluate oracle rows are found or if any matched row exceeds its configured agreement bound.
- Uploads the generated `benchmark/results/` directory as a GitHub Actions artifact for later inspection.
- Publishes Shields badge JSON plus an archived snapshot of the exact result files behind each published benchmark badge on the `benchmark-badges` branch.
- The published Julia-vs-QMCPy report now exposes the headline weighted time ratio, a 95% within-run bootstrap interval, `StudentT` split summaries, grouped timing totals for `gen_samples` / `transform` / `evaluate` / end-to-end `integrate`, and approximate memory ratios with explicit provenance manifests.

## Docs and Demos (`doc_demo.yml`)

Builds the Documenter.jl documentation and runs the checked-in demo notebooks.

- Triggered on pushes to `develop`/`master` when `docs/`, `demos/`, `src/`, `test/run_notebooks.jl`, `Makefile`, `Project.toml`, `Manifest.toml`, `test/requirements.txt`, or the workflow file itself changes.
- Also triggered on pull requests into `develop`/`master` when `docs/`, `src/`, `Project.toml`, `Manifest.toml`, `Makefile`, `test/requirements.txt`, or the workflow file itself changes.
- The documentation job uses `julia --project=docs` to resolve the docs-specific dependency set and deploys via `deploydocs()` only on push events.
- The demos job remains push/manual only and does not run on pull requests.

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

**Documenter doctests:**

```bash
make doctest
```

**Coverage-focused local targets:**

```bash
make coverage TEST_JOBS=2 TEST_THREADS=1
make doctest-coverage DOC_DEPOT="$HOME/.julia"
make notebook-coverage NOTEBOOK_JOBS=2 NOTEBOOK_THREADS=1
make bench-coverage BENCH_BLAS_THREADS=2
make bench-compare-coverage REV=HEAD~1 BENCH_BLAS_THREADS=2
make bench-compare-py-coverage LABEL=base BENCH_BLAS_THREADS=2
make bench-all-coverage REV=HEAD~1 LABEL=base BENCH_BLAS_THREADS=2
```

- `make coverage` wraps `Pkg.test(coverage=true)`, converts the resulting `src/*.cov` files into `lcov.info`, and prints a `src/` summary.
- `make doctest-coverage` runs `docs/make.jl doctest=only` with coverage enabled and then summarizes the `src/` coverage files produced by that doctest-only execution.
- `make notebook-coverage` executes the checked-in demo notebooks with coverage enabled and summarizes `src/`.
- `make bench-coverage`, `make bench-compare-coverage`,
  `make bench-compare-py-coverage`, and `make bench-all-coverage` summarize both `src/` and `benchmark/`.

The `covered/executable` totals reported by these targets are intentionally target-specific. `devtools/process_coverage.jl` only counts executable lines that appear in the `*.cov` files generated by the current run, so different entry points can produce different denominators. In particular, `make doctest-coverage` measures only the code reached while Documenter runs the doctests, after the docs environment has already been resolved separately, so its `(... executable lines)` total should not be expected to match `make coverage`.

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

`NOTEBOOK_JOBS` shards the runnable notebook list across separate Julia processes. If there are 34 runnable notebooks and `NOTEBOOK_JOBS=2`, the run is split into two 17-notebook shards. Set `NOTEBOOK_JOBS=1` when you want one sequential pass over the entire notebook set.

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

QMC.jl publishes test coverage through Linux coverage lanes in both `ci.yml` and `ci-full.yml`.

- The repository README badge points at the Codecov report for `develop`.
- `ci.yml` converts Julia's `*.cov` outputs into `lcov.info` for feature branches.
- The Linux Julia 1.11 lane in `ci-full.yml` does the same for `develop` and `master`.
- The resulting LCOV file is uploaded to Codecov and also attached to the workflow run as an artifact.

The local `Pkg.test(coverage=true)` command is the same instrumentation mode used by CI.
`make coverage` additionally processes the raw `*.cov` files into `lcov.info` and prints a source-coverage summary for `src/`. The other `*-coverage` targets reuse the same post-processing script, but they measure different execution slices and may therefore report different `executable lines` totals.

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
