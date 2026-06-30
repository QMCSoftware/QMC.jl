# Discrete Distributions

`IIDStdUniform` is Julia-native. `Lattice`, `DigitalNetB2`, and `Halton` currently require the QMCToolsCL shared library shipped with QuasiMC's staged `QMCToolsCL_jll` dependency, so no Python setup is required for those generators.

## Abstract Type

```@docs
AbstractDiscreteDistribution
```

## Generators

```@docs
IIDStdUniform
Lattice
DigitalNetB2
Halton
Kronecker
DigitalNetAnyBases
Faure
```

`DigitalNetB2` now covers the main QMCPy-style constructor surface used in this repository: direct custom matrices, LDData-format files or names, order aliases, widened `t` precision, `msb` handling, and higher-order interlacing through `alpha`. The bundled constructor path still uses 1024 raw Sobol' dimensions, so `alpha > 1` reduces the default effective-dimension cap to `floor(1024 / alpha)` unless you provide a larger LDData-style matrix source explicitly.

`Lattice` likewise covers the main QMCPy-style constructor surface used here: direct custom generating vectors, the integer shortcut for random odd vectors, order aliases, and LDData-format file/name/URL inputs. Local LDData-style files are validated against their declared `d_limit` / `n_limit` metadata, and multilevel `spawn_dd` preserves explicit custom vectors when the stored source is long enough for the requested dimension.

## Sampling

```@docs
gen_samples
spawn_dd(::IIDStdUniform, ::Int)
spawn_dd(::Lattice, ::Int)
spawn_dd(::DigitalNetB2, ::Int)
spawn_dd(::Halton, ::Int)
```
