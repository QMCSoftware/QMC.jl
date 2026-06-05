# Discrete Distributions

`IIDStdUniform` is Julia-native. `Lattice`, `DigitalNetB2`, and `Halton`
currently require the QMCToolsCL shared library, so Python is a current
runtime dependency for those generators.

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

`DigitalNetB2` now covers the main QMCPy-style constructor surface used in
this repository: direct custom matrices, LDData-format files or names, order
aliases, widened `t` precision, `msb` handling, and higher-order interlacing
through `alpha`.

## Sampling

```@docs
gen_samples
spawn_dd(::IIDStdUniform, ::Int)
spawn_dd(::Lattice, ::Int)
spawn_dd(::DigitalNetB2, ::Int)
spawn_dd(::Halton, ::Int)
```
