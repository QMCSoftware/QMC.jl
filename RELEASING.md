# Releasing QuasiMC.jl

This document defines the release ladder, readiness criteria, and release procedure for QuasiMC.jl.

Current target: cut the first public tag from a green commit as `v0.1.0`, then use tagged installs rather than `develop` for user-facing examples, papers, and benchmarks.

## Release Ladder

- `v0.1.0`: internal alpha. The package is usable by project contributors and close collaborators, but the API and install story are still being hardened.
- `v0.2.0`: public prerelease. The package has a documented install path, tagged artifacts, archived benchmarks, and reproducible core examples suitable for broader external testing.
- `v1.0.0`: stable public release. The public API is intentionally maintained, upgrade notes are documented, and external users should be able to depend on the package without following moving branches.

## Release Gates

Every tagged release must satisfy all of the following:

- Documentation is built successfully and published online.
- Required CI workflows are green on the release commit.
- The benchmark workflow has produced an archived report for the release commit.
- The quickstart example and core examples are reproducible from the tagged artifact.
- `Project.toml` version matches the intended git tag exactly.
- The packaged QMCToolsCL backend version and refresh procedure are documented, including the staged Windows binary source.

Additional gates by milestone:

### `v0.1.0` internal alpha

- Core package load path works on a clean Julia environment.
- Unit tests, doctests, and notebook regression pass on the release commit.
- Installation instructions clearly distinguish contributor setup from stable tagged installation.

### `v0.2.0` public prerelease

- At least one public GitHub release has been published.
- A versioned install command using `Pkg.add(..., rev="vX.Y.Z")` is documented.
- Release notes summarize major features, known limitations, and the current staged-vs-published `QMCToolsCL_jll` status.
- Benchmark summaries for time and memory versus QMCPy are archived with the release.

### `v1.0.0` stable public release

- Public APIs and extension points have explicit stability expectations.
- Migration notes exist for any breaking changes since the latest prerelease.
- Registration in Julia General has been completed, or the project has explicitly documented why it remains unregistered.

## Registration Decision

QuasiMC.jl should decide before `v0.2.0` whether it will be registered in Julia General.

- If QuasiMC.jl is registered, audit `[compat]` bounds, package metadata, and install instructions before filing the registration PR.
- If QuasiMC.jl remains unregistered, every public install command and citation example must use an immutable git tag rather than a branch name.

## Release Procedure

1. Select the release commit on `develop`.
2. Ensure the version in `Project.toml` matches the intended tag.
3. Run the required validation locally or in CI:
   - `julia --project=. -e 'using Pkg; Pkg.build("QMCToolsCL_jll"); Pkg.test()'`
   - `julia --project=. -e 'using QuasiMC; println(size(gen_samples(Lattice(3; seed=7), 4))); println(size(gen_samples(DigitalNetB2(3; seed=7), 4))); println(size(gen_samples(Halton(3; seed=7), 4)))'`
   - `make doctest`
   - `make notebook NOTEBOOK_JOBS=2 NOTEBOOK_THREADS=1`
   - `julia --project=docs docs/make.jl`
   - `make bench-all REV=HEAD~1 BENCH_BLAS_THREADS=2`
4. Archive the benchmark outputs and note the report location in the release notes.
5. Create an annotated git tag such as `v0.1.0`.
6. Publish a GitHub release that links the documentation, benchmark report, and install instructions for that tag.
7. Verify that the tagged install command works in a clean environment.

## Reproducibility Notes

- A branch name such as `develop` is not a reproducible public artifact.
- A release tag is the minimum artifact that papers, courses, and benchmark reports should cite.
- Core QuasiMC runtime no longer depends on Python. Only QMCPy benchmark and notebook-frontend workflows should mention pinned Python requirements.
- Until `QMCToolsCL_jll` is published outside this repository, release notes should state that the current package uses a staged in-repo binary package and should record the exact upstream C-source snapshot plus the Windows wheel/binary provenance used for validation.
