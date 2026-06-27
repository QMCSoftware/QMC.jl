# GitHub Actions Workflows

This folder contains the repository's GitHub Actions workflows.

## Files

| Workflow | Description | Local equivalent |
|---|---|---|
| `ci.yml` (`Fast CI`) | Fast Linux feedback for feature-branch pushes; runs plain unit tests plus doctests, with no coverage upload. | `make test` · `make doctest` |
| `ci-full.yml` (`Full CI`) | Cross-platform validation for `develop`/`master`; one Linux lane also runs unit coverage and updates the develop/master Codecov `unit` flag badge. | `make test` or `make coverage` *(current Julia/OS only)* |
| `doc_demo.yml` | Documenter build/deploy plus demo-notebook regression runs on `develop`/`master`; push/manual runs there also publish Codecov `doctest` and `notebook` flag badges. | `make doc; make notebook; make doctest-coverage; make notebook-coverage` |
| `benchmarking.yml` | Benchmark collection for benchmark-relevant `develop`/`master` pushes and manual runs; separate jobs publish benchmark speed/memory badges and update the Codecov `bench` flag badge. | `make ci-bench` |
| `install-test.yml` | Clean-environment install test without Python: verifies `using QMC` works, pure-Julia generators produce correct output, and qmctoolscl-backed generators (`Lattice`, `DigitalNetB2`, `Halton`) emit actionable errors when the library is absent. | *(runs in an isolated environment with no qmctoolscl)* |
| `TagBot.yml` | Release-tag automation. |  |

### New local targets

- **`make doctest`** — runs Documenter doctests (manual pages + src docstrings) without a full render; faster than `make doc` when you only want to check docstring examples.
- **`make ci-doc-demo`** — runs `make doc` then `make notebook` in sequence.
- **`make ci-bench`** — runs `make bench-all` comparing the working tree against `HEAD~1` (the pre-push baseline CI uses). Override with `CI_BENCH_REV=<sha>`.

See [`../../docs/src/ci-testing.md`](../../docs/src/ci-testing.md) for the user-facing workflow overview and policy details.
