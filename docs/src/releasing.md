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
- The packaged QMCToolsCL backend version for `Lattice`, `DigitalNetB2`, and
  `Halton` is documented and kept in sync with the staged binary package.

## Maintaining the Staged `QMCToolsCL_jll`

Until `QMCToolsCL_jll` is published as an external package, QuasiMC carries a
staged in-repo package under `jll/QMCToolsCL_jll`.

- Unix builds compile the vendored upstream `qmctoolscl` C sources during `Pkg.build("QMCToolsCL_jll")`.
- Windows currently ships a vendored `c_lib.cp312-win_amd64.pyd` extracted from
  the upstream `qmctoolscl` wheel because upstream does not yet provide a
  standalone Windows shared-library release.
- When bumping the backend version, refresh both the upstream source snapshot
  and the Windows vendored binary together, then rerun the install-test matrix
  on Linux, macOS, and Windows.
- The long-term release target remains a published `QMCToolsCL_jll`; until then,
  public install notes should avoid claiming that downstream `Pkg.add(...)`
  users are consuming a registry-published JLL.

## Installation Guidance

For reproducible use, prefer a tag-specific install. Replace `vX.Y.Z` with the published release tag you want to use, for example `v0.1.0` once that tag exists:

```julia
using Pkg
Pkg.add(url="https://github.com/QMCSoftware/QuasiMC.jl", rev="vX.Y.Z")
```

`Lattice`, `DigitalNetB2`, and `Halton` use the packaged QMCToolsCL shared
library supplied through QuasiMC's staged `QMCToolsCL_jll` dependency.

For advanced debugging, you can point QuasiMC at a custom shared library before
`using QuasiMC`:

```julia
ENV["QUASIMC_QMCTOOLSCL_LIB"] = "/absolute/path/to/library"
```

## Registration

Before `v0.2.0`, QuasiMC.jl should decide whether it will be registered in Julia General.

- If registered, public install instructions can use `Pkg.add("QuasiMC")` after registration.
- If unregistered, public install instructions should always use a git tag such as `rev="vX.Y.Z"` rather than `develop`.
