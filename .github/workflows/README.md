# GitHub Actions Workflows

This folder contains the repository's GitHub Actions workflows.

## Files

- `ci.yml`: fast Linux CI for unit tests, notebooks, and coverage upload.
- `ci-full.yml`: broader matrix CI for pull requests to `develop` and `master`.
- `docs.yml`: Documenter build and deployment workflow.
- `TagBot.yml`: release-tag automation.
- `nightly.yml`: scheduled benchmarking on non-Linux platforms.

### Disabled

- `format.yml.disabled`: disabled formatter workflow kept for reference.
- `CompatHelper.yml.disabled`: dependency update automation. 


See [`../../docs/src/ci-testing.md`](../../docs/src/ci-testing.md) for the user-facing workflow overview.
