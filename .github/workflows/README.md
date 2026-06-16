# GitHub Actions Workflows

This folder contains the repository's GitHub Actions workflows.

## Files

- `ci.yml` (`Fast CI`): fast Linux feedback for feature branches; runs unit tests with coverage.
- `ci-full.yml` (`Full CI`): broader cross-platform validation for `develop`/`master`; runs unit tests on Linux, macOS, and Windows.
- `docs.yml`: Linux workflow for Documenter build/deploy plus demo-notebook regression runs on `develop`/`master`.
- `TagBot.yml`: release-tag automation.
- `benchmarking.yml`: Linux benchmark collection for benchmark-relevant `develop`/`master` pushes and manual runs.

### Disabled

- `format.yml.disabled`: disabled formatter workflow kept for reference.
- `CompatHelper.yml.disabled`: dependency update automation. 


See [`../../docs/src/ci-testing.md`](../../docs/src/ci-testing.md) for the user-facing workflow overview and policy details.
