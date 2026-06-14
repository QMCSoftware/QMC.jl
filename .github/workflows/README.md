# GitHub Actions Workflows

This folder contains the repository's GitHub Actions workflows.

## Files

- `ci.yml`: fast Linux CI for unit tests, notebooks, and coverage upload on every push and pull request.
- `ci-full.yml`: broader cross-platform unit-test matrix for `develop`/`master` pushes, pull requests into those branches, and manual runs.
- `docs.yml`: Documenter build and deployment workflow.
- `TagBot.yml`: release-tag automation.
- `benchmarking.yml`: Linux benchmark collection for benchmark-relevant `develop`/`master` pushes and manual runs.

### Disabled

- `format.yml.disabled`: disabled formatter workflow kept for reference.
- `CompatHelper.yml.disabled`: dependency update automation. 


See [`../../docs/src/ci-testing.md`](../../docs/src/ci-testing.md) for the user-facing workflow overview and policy details.
