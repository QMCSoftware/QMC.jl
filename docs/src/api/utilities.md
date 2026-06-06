# Utilities

## Bernoulli Polynomials

```@docs
bernoulli_poly
```

## Diagnostics

```@docs
IterationLog
iterations(::IterationLog)
```

## Periodization

```@docs
periodize
```

## Binary Transforms

```@docs
to_bin
to_float
```

## Fast Walsh-Hadamard Transform

`gpu_fwht!` is currently a CPU-fallback placeholder. Its docstring is listed
here for API completeness, but it does not yet provide true GPU acceleration.

```@docs
fwht!
fwht
ifwht!
gpu_fwht!(::Vector{Float64})
bro_fft(::Vector{Float64})
bro_ifft(::Vector{ComplexF64})
```

## Construction Helpers

```@docs
latnetbuilder_linker(::String)
```

## Multilevel Utilities

```@docs
mlmc_test(::AbstractMLIntegrand)
```
