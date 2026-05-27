# QMCJu: Quasi-Monte Carlo Software in Julia

QMCJu is the Julia implementation of the [QMCJu](https://github.com/QMCSoftware/QMCSoftware) framework for Quasi-Monte Carlo (QMC) numerical integration.

## Overview

QMC methods approximate multivariate integrals using four main components:

1. **Discrete Distribution** — low-discrepancy point generators
2. **True Measure** — the probability measure defining the integration domain
3. **Integrand** — the function being integrated
4. **Stopping Criterion** — adaptive algorithm to determine when tolerance is met

## Quick Start

```julia
using QMCJu

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

```julia
using Pkg
Pkg.add(url="https://github.com/QMCSoftware/QMCSoftware", subdir="qmcju")
```

## Contents

```@contents
Pages = ["components.md", "demos.md", "contributing.md", "community.md"]
Depth = 2
```
