# Source Tree

This directory contains the implementation of the QMC.jl package.

## Files

- `QMC.jl`: package entry point; includes source files and exports the public API.
- `abstract_types.jl`: shared abstract interfaces such as integrands, measures, and stopping criteria.

## Subdirectories

- `data/`: static tables for generators.
- `discrete_distribution/`: point generators and related wrappers.
- `true_measure/`: transforms from uniform points to target measures.
- `integrand/`: test functions, financial models, and multilevel integrands.
- `kernel/`: kernels used by Bayesian QMC and related methods.
- `stopping_criterion/`: adaptive integration algorithms.
- `util/`: internal numerical helpers, transforms, and diagnostics.
