# GitHub Configuration

This directory holds GitHub-specific repository automation and metadata.

## Contents

- `ISSUE_TEMPLATE/`: issue templates for bugs, features, algorithm ports, docs, and performance regressions.
- `pull_request_template.md`: contributor checklist used when opening pull requests.
- `CODEOWNERS`: default review routing for the main scientific components plus CI and docs.
- `workflows/`: GitHub Actions CI, docs, release, and maintenance workflows.

## Notes

- Workflow behavior is documented in [`../docs/src/ci-testing.md`](../docs/src/ci-testing.md).
- Generated macOS metadata files such as `.DS_Store` are not meaningful project content.
