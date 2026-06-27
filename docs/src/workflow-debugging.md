# Workflow Debugging

Use local commands to debug workflow changes before pushing. In this repository, the workflow YAML files are thin orchestration layers around `make` targets and checked-in Julia scripts, so the most useful local check is to run the same job bodies directly.

## YAML Linting

For local workflow debugging on macOS, installing the full Conda tool bundle is useful:

- `actionlint` checks GitHub Actions syntax, expressions, and structure
- `shellcheck` lets `actionlint` lint Bash inside `run:` blocks
- `pyflakes` lets `actionlint` lint embedded Python snippets
- `yamllint` adds a generic YAML-focused pass
- `act` can execute many GitHub Actions jobs locally

Those are developer-only local tools, not package/runtime dependencies, so they live in a dedicated Conda manifest under `devtools/`.

If `actionlint` is on `PATH`, lint all workflow files with:

```bash
actionlint .github/workflows/*.yml
```

One simple Conda-based install path is:

```bash
conda create -n gha-tools -c conda-forge actionlint -y
conda run -n gha-tools actionlint .github/workflows/*.yml
```

To install it into an existing environment such as `qmcpy`:

```bash
conda install -n qmcpy conda-forge::actionlint -y
conda run -n qmcpy actionlint .github/workflows/*.yml
```

To install the whole local workflow-debug bundle into `qmcpy`:

```bash
conda env update -n qmcpy -f devtools/environment-workflow-tools.yml
conda run -n qmcpy actionlint .github/workflows/*.yml
conda run -n qmcpy yamllint .github/workflows
```

`actionlint` catches YAML, expression, and common shell mistakes, but it does not execute the jobs.

## Optional Local Runner

If you want to execute GitHub Actions jobs locally instead of only linting the workflow files, install `act`:

```bash
conda install -n qmcpy conda-forge::act -y
conda run -n qmcpy act --version
```

Or install it through the shared Conda manifest shown above.

`act` usually runs jobs through the Docker Engine API. On macOS that generally means Docker Desktop must also be installed and running. If Docker is not available, use `actionlint` plus the local `make` targets below as the primary workflow-debug path.

## Repeatable Smoke Run

The repository provides a local smoke target:

```bash
make workflow-smoke
```

By default this:

- runs `actionlint` when available
- runs the Linux CI coverage body via `make coverage`
- skips notebooks, docs, and benchmarks to keep the default pass reasonably fast

Enable the slower workflow legs only when you are working on them:

```bash
make workflow-smoke WORKFLOW_SMOKE_NOTEBOOKS=1
make workflow-smoke WORKFLOW_SMOKE_DOCS=1
make workflow-smoke WORKFLOW_SMOKE_BENCH=1 WORKFLOW_SMOKE_REV=HEAD~1 BENCH_BLAS_THREADS=2
```

The benchmark example above mirrors the benchmark workflow more closely by comparing against the previous commit. If you only want to compare your dirty working tree against `HEAD`, leave `WORKFLOW_SMOKE_REV=HEAD`.

## Direct Job Commands

Run a specific workflow body directly when you only need one path:

```bash
make coverage TEST_JOBS=2 TEST_THREADS=1
make notebook NOTEBOOK_JOBS=2 NOTEBOOK_THREADS=1
make bench-all REV=HEAD~1 BENCH_BLAS_THREADS=2
julia --project=docs docs/make.jl
```

## Scope

Local smoke runs validate job bodies well, but they do not fully emulate GitHub Actions trigger filters, matrix expansion, or context variables such as `github.event.before`. For those issues, combine local smoke runs with targeted temporary logging in the workflow `run:` blocks.
