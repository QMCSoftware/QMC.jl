# Release Policy

QuasiMC.jl should be installed and cited from tagged releases, not moving branches. This page summarizes the release ladder. The full maintainer checklist lives in the repository root `RELEASING.md` file.

## Release Ladder

- `v0.1.0`: internal alpha
- `v0.2.0`: public prerelease
- `v1.0.0`: stable public release after API stabilization

## Minimum Release Criteria

Every release must satisfy all of the following:

- Documentation builds successfully and is published online.
- Required CI workflows are green on the release commit.
- The benchmark workflow has produced an archived report for the release commit.
- The quickstart example and core examples are reproducible from the tagged artifact.
- `Project.toml` version matches the git tag.
- Python requirements for QMCToolsCL-backed generators are documented with pinned versions.

## Installation Guidance

For reproducible use, prefer a tag-specific install. Replace `vX.Y.Z` with the published release tag you want to use, for example `v0.1.0` once that tag exists:

```julia
using Pkg
Pkg.add(url="https://github.com/QMCSoftware/QuasiMC.jl", rev="vX.Y.Z")
```

If you need `Lattice`, `DigitalNetB2`, or `Halton`, also install the pinned Python dependency:

```bash
python3 -m pip install qmctoolscl==1.2.3
```

Set `ENV["QUASIMC_PYTHON"]` before `using QuasiMC` if Julia should use a non-default Python interpreter (legacy `ENV["QMC_PYTHON"]` is still accepted).

## Registration

Before `v0.2.0`, QuasiMC.jl should decide whether it will be registered in Julia General.

- If registered, public install instructions can use `Pkg.add("QuasiMC")` after registration.
- If unregistered, public install instructions should always use a git tag such as `rev="vX.Y.Z"` rather than `develop`.
