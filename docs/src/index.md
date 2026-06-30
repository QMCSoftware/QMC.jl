# QuasiMC.jl: Quasi-Monte Carlo Software in Julia

QuasiMC.jl is a Julia port of QMCPy for Quasi-Monte Carlo (QMC) numerical integration.

`IIDStdUniform` is Julia-native. The main low-discrepancy generators `Lattice`, `DigitalNetB2`, and `Halton` currently rely on the QMCToolsCL shared library shipped with QuasiMC's staged `QMCToolsCL_jll` dependency, so no Python setup is required for full core QMC functionality.

Most core package families are implemented. A few advanced items remain partial: `PFGPCI` is currently an exported experimental feature that depends on an optional Julia GP backend, and `gpu_fwht`/`gpu_fwht!` are presently placeholder names whose implementation is only the CPU `fwht`/`fwht!` fallback.

## API Stability

QuasiMC.jl currently groups its public surface into the following stability levels:

| Status | Representative symbols | Meaning |
|---|---|---|
| **Stable** | `IIDStdUniform`, `Lattice`, `DigitalNetB2`, `Gaussian`, `BrownianMotion`, `Keister`, `Genz`, `CubMCCLT`, `CubMCG`, `CubQMCLatticeG`, `CubQMCNetG`, `CubQMCNetGRep` | Expected to remain source-compatible except for deliberate documented breaking releases |
| **Beta** | `CubQMCBayesLatticeG`, `CubQMCBayesNetG`, `CubMLMC`, `CubMLMCCont`, `CubMLQMC`, `CubMLQMCCont` | Usable and tested, but advanced interfaces may still be refined before long-term stabilization |
| **Experimental** | `PFGPCI`, `UMBridgeWrapper`, `KernelMultiTask`, `KernelMultiTaskDerivs` | Exported for early adopters; behavior and interfaces may change with limited compatibility guarantees |
| **Placeholder** | `gpu_fwht`, `gpu_fwht!` | Exported names reserved for future functionality; current implementation does not provide the advertised capability |

### Name conflicts with Distributions.jl

`Uniform` and `Kumaraswamy` are exported by both QuasiMC.jl and [Distributions.jl](https://github.com/JuliaStats/Distributions.jl). If you load both packages in the same session you will see an ambiguity warning. Resolve it with a qualified import:

```julia
using QuasiMC, Distributions
import QuasiMC: Uniform, Kumaraswamy   # prefer QuasiMC's versions
```

or by fully qualifying whichever variant you need at the call site (`QuasiMC.Uniform(...)` vs. `Distributions.Uniform(...)`).

## Overview

QMC methods approximate multivariate integrals using four main components:

1. **Discrete Distribution** — low-discrepancy point generators
2. **True Measure** — the probability measure defining the integration domain
3. **Integrand** — the function being integrated
4. **Stopping Criterion** — adaptive algorithm to determine when tolerance is met

## Quick Start

This example uses `Lattice`, which now works through QuasiMC's packaged QMCToolsCL backend.

```jldoctest
julia> using QuasiMC

julia> dd = Lattice(3; randomize=true, seed=7);

julia> f = Genz(Uniform(dd); kind=:continuous);

julia> result = integrate(CubQMCLatticeG(f; abs_tol=1e-3));

julia> isapprox(result.solution, genz_exact(f); atol=1e-3)
true
```

## Installation

For reproducible use, prefer a tagged artifact rather than the moving default branch. Replace `vX.Y.Z` with the published release tag you want to use, for example `v0.1.0` once that tag exists:

```julia
using Pkg
Pkg.add(url="https://github.com/QMCSoftware/QuasiMC.jl", rev="vX.Y.Z")
```

`IIDStdUniform` is fully Julia-native. `Lattice`, `DigitalNetB2`, and `Halton` use the packaged QMCToolsCL shared library supplied through QuasiMC's staged `QMCToolsCL_jll` dependency, so no Python setup is required for core use.

Advanced users can override the library path before `using QuasiMC`:

```julia
ENV["QUASIMC_QMCTOOLSCL_LIB"] = "/absolute/path/to/library"
```

## Contents

```@contents
Pages = ["components.md", "demos.md", "releasing.md", "contributing.md", "community.md"]
Depth = 2
```
