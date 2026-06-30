# QuasiMC.jl — Package Extensions (`ext/`)

This directory contains [Julia package extensions](https://docs.julialang.org/en/v1/manual/code-loading/#man-extensions) (Julia 1.9+). Each extension is loaded automatically when the listed optional package(s) are present in the user's environment alongside `QuasiMC`. No action is required from the user; the enhanced behaviour activates transparently.

## Extensions

### `QuasiMCAbstractGPsExt.jl`

**Triggered by:** `AbstractGPs` + `Optim`

Provides the Gaussian-process surrogate backend for [`PFGPCI`](@ref). Implements `_pfgpci_fit` / `_pfgpci_predict` using a zero-mean GP with a scaled Matérn-5/2 kernel whose hyperparameters are fit by maximising the log marginal likelihood.  Mirrors QMCPy's default `ScaleKernel(MaternKernel(nu=2.5))`.

Without this extension `PFGPCI` construction will throw an informative error asking the user to `using AbstractGPs, Optim`.

### `QuasiMCLoopVectorizationExt.jl`

**Triggered by:** `LoopVectorization`

On **x86 / AVX2** systems, overrides the internal `_erfinv_into!` helper with a `@turbo`-vectorised loop backed by SLEEFPirates' AVX erfinv implementation, giving **2–4× speedup** for the dense Gaussian transform inner loop (the bottleneck in `CubQMCNetGRep` / `CubMCCLT` with `BrownianMotion` or `GeometricBrownianMotion`).

On **ARM / AARCH64** (Apple Silicon, etc.) SLEEFPirates does not supply a SIMD `erfinv` intrinsic.  The extension detects this at load time (`Sys.ARCH`) and leaves the default `@simd` scalar path in place, so loading `LoopVectorization` on Apple Silicon has no adverse effect.

## Layout requirement

`ext/` must remain at the **package root** (next to `src/` and `Project.toml`). Julia's package loader resolves extension files as `<PkgRoot>/ext/<ExtName>.jl`; moving this directory elsewhere will silently prevent extensions from loading.
