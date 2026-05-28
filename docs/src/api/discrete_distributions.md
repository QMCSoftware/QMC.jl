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
```

## Sampling

```@docs
gen_samples
```
