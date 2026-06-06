# Discrete Distributions

This folder implements the low-discrepancy and IID point generators that produce samples in `[0,1)^d`.

## Main generators

- `iid_std_uniform.jl`: IID pseudo-random uniform samples.
- `lattice.jl`: rank-1 lattice rules, including custom generating vectors,
  QMCPy-style order aliases, LDData-style file/name inputs, and preserved
  custom-vector respawning for multilevel workflows.
- `digital_net_b2.jl`: Sobol'/digital net base-2 construction, including
  custom generating matrices, QMCPy-style constructor aliases, and
  higher-order interlacing through `alpha`. The built-in constructor path uses
  1024 raw Sobol' dimensions, and larger higher-order jobs can opt into
  explicit LDData-style sources when `alpha > 1` would otherwise hit that cap.
- `halton.jl`: Halton sequences.
- `kronecker.jl`: Kronecker sequences.
- `digital_net_any_bases.jl`: more general digital-net support.

## Support files

- `qmctoolscl_c.jl`: interface glue to the QMCToolsCL-backed generators used by several QMC sequences.
