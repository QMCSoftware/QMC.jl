# CI/CD Testing

QuasiMC.jl uses GitHub Actions for continuous integration and benchmark collection. The main feedback paths live in four active workflow files under `.github/workflows/` plus `TagBot.yml`. For local linting and repeatable smoke runs of those workflows, see [Workflow Debugging](workflow-debugging.md).

## Workflow Overview

| Workflow | File | Trigger | Platforms | Scope |
|----------|------|---------|-----------|-------|
| **CI** | `ci-full.yml` | all `push` events; PRs into `develop`/`master`; manual | Linux-only fast mode on feature branches; Linux/macOS/Windows/nightly full mode on protected branches and PRs | Unit tests across the declared Julia compat window, Linux doctests, and one protected-branch unit-coverage lane |
| **Benchmarking** | `benchmarking.yml` | `push` to `develop`/`master` on benchmark-relevant paths; manual | Linux | Julia-vs-Julia + Julia-vs-QMCPy benchmarks + benchmark-driven `src/` coverage |
| **Docs and Demos** | `doc_demo.yml` | `push` on docs, demo, and source paths; docs-smoke PRs on docs/source changes; manual | Linux | Documenter build + deploy + notebook regression + develop/master doctest/notebook coverage |
| **Install Test** | `install-test.yml` | `push` to `develop`/`master`; PRs touching `src/` or `Project.toml`; manual | Linux | Clean install without Python — verifies pure-Julia generators work and qmctoolscl-backed generators give actionable errors |

## Policy

- The main CI workflow borrows QMCPy’s current `develop`-branch `alltests.yml` pattern: one workflow file chooses a smaller feature-branch matrix or a larger protected-branch/PR matrix internally, instead of maintaining separate fast and full workflow files.
- Linux is the default fast-feedback path. Feature-branch pushes run only the Linux Julia 1.10/1.11/1.12 lanes, which keeps the full declared compat window (`julia = "1.10"`) gate-verified on every push while leaving exact doctest matching to the Julia 1.11/1.12 lanes.
- macOS, Windows, and the nightly Julia lane are reserved for the full CI mode used by pushes to `develop`/`master`, pull requests into those branches, and manual dispatches.
- Benchmark collection is separated from unit testing. `benchmarking.yml` is Linux-only, path-filtered, and uploads `benchmark/results/` as an artifact.
- The repository also has a fast fixture-based QMCPy release-parity gate (`make release-parity`) that complements the benchmark parity checks. It lives in the unit-test tree rather than the benchmark workflow so curated parity failures are easier to see and reproduce locally.
- Coverage uploads and coverage badge publication are restricted to `develop` and `master` push/manual runs. Feature-branch CI and pull-request CI still run correctness checks, but they do not publish `lcov.info` or coverage badges.
- Coverage badges are served by repo-hosted Shields JSON on the `benchmark-badges` branch (`unit`, `doctest`, `notebook`, `bench`). Codecov uploads are retained as a best-effort secondary sink, but the repository README no longer depends on live Codecov badge resolution.
- The benchmarking workflow pins its Python dependencies through `benchmark/requirements.txt` so cross-commit comparisons are not invalidated by unrelated upstream package releases. Changes to the shared `test/requirements.txt` pin file also retrigger the benchmark workflow.
- On push-triggered benchmark runs, the Julia-vs-Julia comparison uses the previous pushed commit as the reference revision when GitHub provides one; manual runs fall back to `REV=HEAD`.
- `concurrency` cancels superseded runs, and the CI and benchmarking groups include the event name so a pull request run does not cancel the sibling push run for the same ref.
- There is no nightly CI schedule.

## CI (`ci-full.yml`)

This repository now uses one adaptive test workflow instead of separate fast and full CI files.

### Fast mode

Feature-branch pushes run the fast Linux-only mode:

- `ubuntu-latest` with Julia 1.10, 1.11, and 1.12 (one lane per version; `fail-fast: false`).
- `make test` runs on all three Julia versions.
- `make doctest` runs on the Julia 1.11 and 1.12 lanes. Julia 1.10 remains in the matrix for package-functionality compatibility testing.
- This mode keeps the full declared compat window (`julia = "1.10"` in `Project.toml`) gate-verified on every feature-branch push.
- It installs Python 3.13 plus pinned `qmctoolscl` from `test/requirements.txt`.
- It uses `make test`, so Linux fast-mode lanes keep the existing sharded test execution (`TEST_JOBS`, `TEST_THREADS`) rather than falling back to a single monolithic `Pkg.test()` process.
- It does not upload `lcov.info`; coverage publication is reserved for protected-branch push/manual runs.

### Full mode

Pushes to `develop` or `master`, pull requests into those branches, and manual dispatches expand into the full sweep:

- Linux (`ubuntu-latest`) on Julia 1.10, 1.11, and 1.12.
- macOS on Julia 1.12.
- Windows on Julia 1.12.
- Linux on `nightly` with `continue-on-error: true` (see [The `nightly` Julia version](#the-nightly-julia-version) below).
- The Linux Julia 1.11 lane is the unit-coverage lane. On `develop`/`master` push/manual runs it executes `make coverage`, uploads `lcov.info`, and publishes the develop/master repo-hosted `unit` coverage badge. On pull requests, that same lane falls back to plain test execution so coverage stays branch-only.
- Linux Julia 1.11 and 1.12 still run `make doctest`, so the full mode subsumes the previous fast-workflow doctest coverage of current stable Julia versions.
- Non-Linux lanes run plain `Pkg.test()` rather than the Linux sharded `make test` wrapper.

### The `nightly` Julia version

The full-sweep CI matrix includes one entry with `julia-version: 'nightly'`. **This is not a scheduled overnight run.** It is the name of a special Julia version keyword accepted by `julia-actions/setup-julia@v2`.

When `version: nightly` is specified, the action downloads the **latest pre-release development build of Julia** — currently the 1.14-DEV series — compiled and published by the Julia project every day from the `master` branch of the Julia compiler. In other words, `nightly` is a rolling target that always tracks the bleeding edge of Julia development, not a fixed version number.

Why is `nightly` in the matrix?

- It gives early warning of breaking changes before a new Julia version is officially released. For example, Julia 1.14 tightened the `ccall` ABI so that the library name must be a compile-time `Symbol` rather than a runtime expression; the nightly job caught this before 1.14 was released.
- It cannot be replaced with a concrete stable version such as `1.13` or `1.14` because those versions do not yet exist as official releases.

Because pre-release builds can introduce breaking changes that are still under discussion upstream, the nightly job is marked `continue-on-error: true`. This means a failure in the nightly job is reported in the CI summary but does **not** block a pull request from being merged. It serves as a signal worth investigating, not an automatic blocker.

> **Summary:** In this repository, `nightly` = "test against tomorrow's Julia, non-blocking."

## Benchmarking (`benchmarking.yml`)

The benchmark workflow is separate from the test workflows.

- Triggers on pushes to `develop` or `master` when benchmark-relevant files change, and via manual dispatch.
- Runs on `ubuntu-latest` with Julia 1.12 and Python 3.13.
- Checks out full git history so `make bench-all REV=<previous-commit>` can materialize the baseline revision in a temporary worktree.
- Installs pinned benchmark Python dependencies from `benchmark/requirements.txt`; the QMCPy benchmark version pin itself lives in `benchmark/qmcpy-requirements.txt`.
- Runs `make bench-all`, not the broader `make ci`, so benchmark artifacts measure the checked-in sources rather than a formatter-mutated worktree.
- Uses `BENCH_BLAS_THREADS` for both Julia and Python-side native-kernel thread settings.
- Treats the seeded Julia-vs-QMCPy parity checks as a guard: `make bench-compare-py` fails if no comparable `integrate` or deterministic transform/evaluate oracle rows are found or if any matched row exceeds its configured agreement bound.
- Those benchmark parity checks are timing-artifact-driven. For a smaller release-style regression gate that does not require running the full benchmark harness, use `make release-parity`, which replays a checked-in QMCPy 2.3 fixture from the unit-test tree.
- Uploads the generated `benchmark/results/` directory as a GitHub Actions artifact for later inspection.
- Publishes Shields badge JSON plus an archived snapshot of the exact result files behind each published benchmark badge on the `benchmark-badges` branch.
- Runs a separate `make bench-all-coverage` job on `develop`/`master` push/manual events so the `bench` coverage badge covers the standalone benchmark suite plus the Julia-vs-Julia and Julia-vs-QMCPy comparison paths, without affecting the benchmark speed/memory badges.
- When `BENCH_COVERAGE=1`, the benchmark harness also runs a small coverage-only probe pass over uncovered `src/` branches such as control variates, additional `FinancialOption` variants, `DigitalNetB2` validation paths, and lattice resume/diagnostics flows. Those probes are coverage-only and are not part of the published timing or memory badges. In that mode the standalone Julia runner also disables BenchmarkTools' per-benchmark GC scrubs and skips the RSS sidecar pass, because the coverage job is a code-exercise workflow rather than a production timing/memory measurement path.
- The published Julia-vs-QMCPy report now exposes the headline weighted time ratio, a 95% within-run bootstrap interval, `StudentT` split summaries, grouped timing totals for `gen_samples` / `transform` / `evaluate` / end-to-end `integrate`, and approximate memory ratios with explicit provenance manifests.

## Docs and Demos (`doc_demo.yml`)

Builds the Documenter.jl documentation and runs the checked-in demo notebooks.

- Triggered on pushes to `develop`/`master` when `docs/`, `demos/`, `src/`, `test/run_notebooks.jl`, `Makefile`, `Project.toml`, `Manifest.toml`, `test/requirements.txt`, or the workflow file itself changes.
- Also triggered on pull requests into `develop`/`master` when `docs/`, `src/`, `Project.toml`, `Manifest.toml`, `Makefile`, `test/requirements.txt`, or the workflow file itself changes.
- The documentation job uses `julia --project=docs` to resolve the docs-specific dependency set and deploys via `deploydocs()` only on push events.
- The demos job remains push/manual only and does not run on pull requests.
- On `develop`/`master` push/manual runs, additional jobs run `make doctest-coverage` and the notebook-coverage job body, upload their `lcov.info` files as artifacts, and publish dedicated repo-hosted `doctest`/`notebook` coverage badges.

## Install Test (`install-test.yml`)

Guards against the qmctoolscl external-dependency hazard: Julia users expect `Pkg.add` to fully instantiate a package, but `Lattice`, `DigitalNetB2`, and `Halton` require a separately installed Python package with a compiled C library.

- Triggers on pushes to `develop`/`master`, on pull requests that touch `src/` or `Project.toml`, and via manual dispatch.
- Runs on `ubuntu-latest` with Julia 1.10 and 1.12. **Intentionally installs no Python and no qmctoolscl.**
- Asserts that `using QuasiMC` succeeds and that pure-Julia generators (`IIDStdUniform`, `Kronecker`) produce correct output without the C library.
- Asserts that `gen_samples(Lattice(3), 4)`, `gen_samples(DigitalNetB2(3), 4)`, and `gen_samples(Halton(3), 4)` each throw an error whose message mentions `qmctoolscl`, `pip install`, and the minimum version `1.2.3` — so a first-time user sees an actionable remediation rather than a cryptic symbol-lookup failure.
- Does not run `Pkg.test()` — the full test suite requires qmctoolscl and is covered by the other CI workflows.

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

**Curated QMCPy release parity:**

```bash
make release-parity PYTHON=/path/to/python-with-qmcpy
```

This target uses the checked-in `test/qmcpy23_release_parity_fixture.jl` fixture. It is intentionally much smaller than `make bench-compare-py`:

- deterministic low-discrepancy generator samples and `spawn_dd` outputs
- deterministic true-measure transform and integrand-evaluation oracles
- fast seeded stopping-criterion solution/accounting checks
- multilevel level-accounting checks
- one resume case and one continuation case

When the pinned QMCPy reference version changes, regenerate the fixture with:

```bash
make release-parity-refresh PYTHON=/path/to/python-with-qmcpy
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
- `make bench-coverage`, `make bench-compare-coverage`, `make bench-compare-py-coverage`, and `make bench-all-coverage` now also summarize `src/` only, even though the benchmark harness itself may emit temporary `benchmark/*.cov` files during the run.
- The benchmark coverage targets additionally enable a `BENCH_COVERAGE=1` probe pass so the benchmark Codecov flag can target at least `80%` package coverage without polluting the plain benchmark speed/memory badge runs.

All user-facing `*-coverage` targets now report package coverage with respect to `src/`. The `covered/executable` totals are still intentionally target-specific. `devtools/process_coverage.jl` only counts executable lines that appear in the `src/*.cov` files generated by the current run, so different entry points can produce different denominators. In particular, `make doctest-coverage` measures only the code reached while Documenter runs the doctests, after the docs environment has already been resolved separately, so its `(... executable lines)` total should not be expected to match `make coverage`.

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
make notebook-update NOTEBOOK_JOBS=2 NOTEBOOK_THREADS=1 NOTEBOOK_KERNEL=quasimc-1.12
# or
make notebook-update-quickstart NOTEBOOK_KERNEL=quasimc-1.12
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

QuasiMC.jl publishes coverage only from `develop`/`master` push/manual lanes.

- The repository README publishes four scope-specific coverage badges from the `benchmark-badges` branch: `unit`, `doctest`, `notebook`, and `bench`.
- No merged `Overall Coverage` badge is published. The protected-branch coverage workflows intentionally exercise different slices of `src/`, so the public badges remain scope-specific rather than pretending to be a single aggregate number.
- The Linux Julia 1.11 lane in `ci-full.yml` runs `make coverage` for `develop` and `master`, uploads `lcov.info` to Codecov, and publishes the `unit` badge.
- `doc_demo.yml` publishes separate develop/master `doctest` and `notebook` badges for `make doctest-coverage` and notebook coverage, while still attempting Codecov uploads.
- `benchmarking.yml` publishes the develop/master `bench` badge from `make bench-all-coverage`, which exercises the standalone benchmark suite together with the Julia-vs-Julia and Julia-vs-QMCPy comparison flows and the `BENCH_COVERAGE=1` probe pass, while keeping the benchmark speed/memory badges tied to plain `make bench-all`.
- Each coverage-producing workflow also uploads its `lcov.info` as a GitHub Actions artifact.

The local `Pkg.test(coverage=true)` command is the same instrumentation mode used by CI.
`make coverage` additionally processes the raw `*.cov` files into `lcov.info` and prints a source-coverage summary for `src/`. The other `*-coverage` targets reuse the same post-processing script, now also report against `src/` only, and still measure different execution slices, so they may report different `executable lines` totals.

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
2. If testing a new component category, create a new file and add an `include()` line in `runtests.jl`.
3. Push — CI will run the tests automatically.

## Secrets

- `CODECOV_TOKEN` — used for Codecov upload when required by the repository configuration; CI is configured not to fail if upload is unavailable.
- `GITHUB_TOKEN` — provided automatically by GitHub; used for docs deployment.
