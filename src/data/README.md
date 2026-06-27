# Static Data Tables

This folder contains precomputed constant tables used by low-discrepancy generators.

## Files

- `joe_kuo_direction_numbers.jl`: direction numbers for Sobol'/digital-net constructions.
- `joe_kuo.6.21201.bin`: compact little-endian `UInt32` extension of the Joe-Kuo direction numbers to 21201 dimensions (dim-major, 21201 × 32), read lazily for `DigitalNetB2` dimensions above the embedded 1024. Its first 1024 dimensions are bit-for-bit identical to `joe_kuo_direction_numbers.jl`. Mirrors QMCPy's bundled `joe_kuo.6.21201.npy`.
- `kuo_lattice_gen_vector.jl`: generator-vector data for lattice rules.

These files are effectively package data and should be edited with care.
