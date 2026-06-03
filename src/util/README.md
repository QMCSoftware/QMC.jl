# Internal Utilities

This folder contains internal helper code shared across multiple package components.

## Files

- `periodization.jl`, `transforms.jl`: periodization and auxiliary transforms
- `fwht.jl`, `bro_fft.jl`: fast transform backends
- `bernoulli.jl`: Bernoulli polynomial helpers
- `diagnostics.jl`: logging and iteration diagnostics
- `gpu_backend.jl`: GPU/backend glue
- `latnetbuilder_linker.jl`: LatNetBuilder integration
- `mlmc_test.jl`: multilevel testing helpers

These files support the public algorithms but are not generally intended as the primary user entry points.
