# QMC.jl: Quasi-Monte Carlo Software in Julia

QMC.jl is a Julia port of QMCPy for Quasi-Monte Carlo (QMC) numerical
integration.

`IIDStdUniform` is Julia-native. The main low-discrepancy generators `Lattice`,
`DigitalNetB2`, and `Halton` currently rely on the QMCToolsCL shared library,
so Python is a current runtime dependency for full QMC functionality.

Most core package families are implemented. A few advanced items remain
partial: `PFGPCI` is currently a documented/exported stub that errors on
`integrate`, and `gpu_fwht!` is presently a CPU-fallback placeholder rather
than a real GPU backend.

## Overview

QMC methods approximate multivariate integrals using four main components:

1. **Discrete Distribution** — low-discrepancy point generators
2. **True Measure** — the probability measure defining the integration domain
3. **Integrand** — the function being integrated
4. **Stopping Criterion** — adaptive algorithm to determine when tolerance is met

## Quick Start

This example uses `Lattice`, so `qmctoolscl` must be installed in a Python
visible to Julia.

```julia
using QMC

# Set up a 3D integration using a lattice rule
dd = Lattice(3; randomize=true)
tm = Uniform(dd)
f = Genz(tm; kind=:continuous)
sc = CubQMCLatticeG(f; abs_tol=1e-3)

# Run integration
result = integrate(sc)
println("Estimate: $(result.solution)")
println("Error bound: $(result.data[:error_bound])")
```

## Installation

For reproducible use, prefer a tagged artifact rather than the moving default branch. Replace `vX.Y.Z` with the published release tag you want to use, for example `v0.1.0` once that tag exists:

```julia
using Pkg
Pkg.add(url="https://github.com/QMCSoftware/QMC.jl", rev="vX.Y.Z")
```

For `Lattice`, `DigitalNetB2`, and `Halton`, also install QMCToolsCL into a Python
visible to Julia:

```bash
python3 -m pip install qmctoolscl==1.2.3
```

If Julia should use a specific Python interpreter, set `ENV["QMC_PYTHON"]`
before `using QMC`.

## Contents

```@contents
Pages = ["components.md", "demos.md", "releasing.md", "contributing.md", "community.md"]
Depth = 2
```
