# `QMCToolsCL_jll`

This is a staged in-repo binary package used to remove QuasiMC.jl's core Python
runtime dependency before a standalone published `QMCToolsCL_jll` exists.

## Layout

- `upstream/qmctoolscl-1.2.3/qmctoolscl/c_funcs/`: vendored upstream C sources
  used for Unix builds
- `vendor/windows/c_lib.cp312-win_amd64.pyd`: vendored Windows shared library
  extracted from the upstream `qmctoolscl` wheel
- `deps/build.jl`: build/install logic

## Current platform strategy

- Linux and macOS build `libqmctoolscl` from the vendored C sources.
- Windows installs the vendored `.pyd` directly because upstream does not yet
  ship a standalone Windows `.dll` artifact.

The Windows binary was chosen only after verifying that it exports the symbols
QuasiMC uses and does not import `python312.dll`, so it can be loaded as a
plain shared library.

## Refresh procedure

When bumping the backend version:

1. Replace the vendored upstream source snapshot under `upstream/`.
2. Refresh the vendored Windows binary from the matching upstream wheel.
3. Update `QMCTOOLSCL_VERSION` in `deps/build.jl` and the package version in
   `Project.toml`.
4. Run `julia --project=. -e 'using Pkg; Pkg.build("QMCToolsCL_jll"); Pkg.test(; test_args=["test_qmctoolscl_backend", "test_discrete_distributions"])'`.
5. Run the install smoke workflow on Linux, macOS, and Windows.

## Future target

The intended end state is a published `QMCToolsCL_jll` maintained outside the
QuasiMC repository. At that point, QuasiMC should drop the in-repo `[sources]`
override and depend on the published package directly.
