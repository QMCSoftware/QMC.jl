# Discrete Distributions

This folder implements the low-discrepancy and IID point generators that produce samples in `[0,1)^d`.

## Main generators

- `iid_std_uniform.jl`: IID pseudo-random uniform samples.
- `lattice.jl`: rank-1 lattice rules.
- `digital_net_b2.jl`: Sobol'/digital net base-2 construction.
- `halton.jl`: Halton sequences.
- `kronecker.jl`: Kronecker sequences.
- `digital_net_any_bases.jl`: more general digital-net support.

## Support files

- `qmctoolscl_c.jl`: interface glue to the QMCToolsCL-backed generators used by several QMC sequences.
