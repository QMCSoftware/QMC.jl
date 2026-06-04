# Kernels

This folder implements kernels used by Bayesian QMC and Gaussian-process-style models.

## Files

- `shift_invariant.jl`: lattice-style shift-invariant kernels.
- `dig_shift_invariant.jl`: digital-shift-invariant kernels.
- `matern.jl`: Matern kernel family.
- `multitask.jl`: multitask/composite kernel support.

These kernels are primarily consumed by the Bayesian stopping criteria and related utilities.
