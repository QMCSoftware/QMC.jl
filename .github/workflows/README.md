# GitHub Actions Workflows

This folder contains the repository's GitHub Actions workflows.

## Files

- `ci.yml`: fast Linux CI for unit tests, notebooks, and coverage upload.
- `ci-full.yml`: broader matrix CI for pull requests to `develop` and `master`.
- `docs.yml`: Documenter build and deployment workflow.
- `nightly.yml`: scheduled regression sweep on non-Linux platforms.
- `CompatHelper.yml`: dependency update automation.
- `TagBot.yml`: release-tag automation.
- `format.yml.disabled`: disabled formatter workflow kept for reference.

See [`../../docs/src/ci-testing.md`](../../docs/src/ci-testing.md) for the user-facing workflow overview.
