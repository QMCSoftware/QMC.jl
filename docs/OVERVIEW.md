# Documentation Build

This directory contains the Documenter.jl configuration and source files for the QMC.jl documentation site.

## Files

- `Project.toml`: docs-only dependency environment.
- `Manifest.toml`: docs environment lockfile.
- `make.jl`: Documenter build and deploy entry point.
- `src/`: Markdown source pages consumed by Documenter.

## Local Build

```bash
julia --project=docs docs/make.jl
```

The generated static site is written to `docs/build/`, which is a build artifact rather than hand-edited source.
