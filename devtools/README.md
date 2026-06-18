# Developer Tools

This directory holds developer-only helper environments and scripts that are not part of the public QMC.jl API.

## Contents

- `formatter/`: isolated Julia environment for code-formatting tools.
- `generate_uml.jl`: scans `src/` and generates UML-style Graphviz/Mermaid
  diagrams for the current type hierarchy and selected field associations.
- `environment-workflow-tools.yml`: Conda manifest for local GitHub Actions
  workflow-debug tools such as `actionlint`, `shellcheck`, `pyflakes`,
  `yamllint`, and `act`.

These tools are intentionally separate from the main package and docs environments.
