# GitHub Actions Workflows

This folder contains the repository's GitHub Actions workflows.

## Files

| Workflow | Description | Local equivalent |
|---|---|---|
| `ci.yml` (`Fast CI`) | Fast Linux feedback for feature-branch pushes; runs unit tests with coverage, then doctests. | `make coverage` · `make doctest` |
| `ci-full.yml` (`Full CI`) | Cross-platform validation for `develop`/`master`; one Linux lane also uploads branch coverage for Codecov. | `make test` or `make coverage` *(current Julia/OS only)* |
| `doc_demo.yml` | Documenter build/deploy plus demo-notebook regression runs on `develop`/`master`. | `make doc; make notebook; make ci-doc-demo` |
| `benchmarking.yml` | Benchmark collection for benchmark-relevant `develop`/`master` pushes and manual runs. | `make ci-bench` |
| `TagBot.yml` | Release-tag automation. |  |

### New local targets

- **`make doctest`** — runs Documenter doctests (manual pages + src docstrings) without a full render; faster than `make doc` when you only want to check docstring examples.
- **`make ci-doc-demo`** — runs `make doc` then `make notebook` in sequence.
- **`make ci-bench`** — runs `make bench-all` comparing the working tree against `HEAD~1` (the pre-push baseline CI uses). Override with `CI_BENCH_REV=<sha>`.

See [`../../docs/src/ci-testing.md`](../../docs/src/ci-testing.md) for the user-facing workflow overview and policy details.
