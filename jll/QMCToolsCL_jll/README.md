# `QMCToolsCL_jll`

This is a staged in-repo binary package used to remove QuasiMC.jl's core Python runtime dependency before a standalone published `QMCToolsCL_jll` exists.

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

The Windows binary was chosen only after verifying that it exports the symbols QuasiMC uses and does not import `python312.dll`, so it can be loaded as a plain shared library.

## Refresh procedure

When bumping the backend to a new `X.Y.Z` release of qmctoolscl:

### 1. Obtain the upstream artifacts

Download the matching source distribution and wheel from PyPI or the qmctoolscl GitHub release page:

```bash
pip download qmctoolscl==X.Y.Z --no-deps -d /tmp/qmc_dl
```

This drops both the `.tar.gz` source distribution and the platform wheels into `/tmp/qmc_dl`.

### 2. Replace the vendored C sources

Extract the source tarball and replace the `upstream/` snapshot:

```bash
tar xzf /tmp/qmc_dl/qmctoolscl-X.Y.Z.tar.gz -C /tmp/
rm -rf jll/QMCToolsCL_jll/upstream/
mkdir  jll/QMCToolsCL_jll/upstream/
cp -r /tmp/qmctoolscl-X.Y.Z jll/QMCToolsCL_jll/upstream/
```

Only the C sources under `qmctoolscl/c_funcs/` are used at build time; the rest of the Python package is ignored.

### 3. Refresh the vendored Windows binary

Extract the Windows `.pyd` from the matching `cp312-win_amd64` wheel:

```bash
pip download qmctoolscl==X.Y.Z --no-deps --platform win_amd64 \
    --python-version 312 --only-binary :all: -d /tmp/qmc_dl
cd /tmp && unzip -o qmc_dl/qmctoolscl-X.Y.Z-cp312-cp312-win_amd64.whl
cp /tmp/qmctoolscl/c_funcs/c_lib.cp312-win_amd64.pyd \
   /path/to/QuasiMC.jl/jll/QMCToolsCL_jll/vendor/windows/
```

Verify the file does **not** import `python312.dll` (it must load as a plain shared library without a Python runtime):

```bash
dumpbin /imports vendor/windows/c_lib.cp312-win_amd64.pyd | grep -i python
# should produce no output
```

### 4. Update version strings

Four places reference the version and must all agree:

| File | What to change |
|---|---|
| `jll/QMCToolsCL_jll/deps/build.jl` | `QMCTOOLSCL_VERSION = "X.Y.Z"` constant and the `upstream/qmctoolscl-X.Y.Z/...` path in `source_root`; keep `-march=native` and `-ffast-math` unless the new release adds numerically sensitive float reductions |
| `jll/QMCToolsCL_jll/src/QMCToolsCL_jll.jl` | `qmctoolscl_version = "X.Y.Z"` fallback constant |
| `jll/QMCToolsCL_jll/Project.toml` | `version = "X.Y.Z+0"` |
| `Project.toml` (repo root) | `[compat] QMCToolsCL_jll = "X.Y.Z"` |

### 5. Check for new C API surface

Compare the C function list in `upstream/qmctoolscl-X.Y.Z/qmctoolscl/c_funcs/` against the previous version. If new functions were added that QuasiMC should use, wire them up in `src/discrete_distribution/qmctoolscl_c.jl`. If new fused or vectorised variants appeared, check whether the `_HAS_DNB2_FUSED` probe in that file still applies or needs a matching update.

### 6. Rebuild and test

From the repository root:

```bash
julia --project=. -e 'using Pkg; Pkg.build("QMCToolsCL_jll")'
julia --project=. -e 'using Pkg; Pkg.test(; test_args=["test_qmctoolscl_backend", "test_discrete_distributions"])'
```

Then run the full suite to catch regressions:

```bash
make test
```

### 7. Smoke-test the install path on all platforms

Trigger the `install-test.yml` workflow (or run it locally via `make workflow-smoke`) on Linux, macOS, and Windows to confirm a clean install with no Python dependency still works end-to-end.

### 8. Update benchmark environment

Regenerate the benchmark `Manifest.toml` so the lock file reflects the new jll version:

```bash
julia --project=benchmark -e 'using Pkg; Pkg.resolve(); Pkg.instantiate()'
```

Commit the updated `Manifest.toml` if it changed.

## Future target

The intended end state is a published `QMCToolsCL_jll` maintained outside the QuasiMC repository. At that point, QuasiMC should drop the in-repo `[sources]` override and depend on the published package directly.
