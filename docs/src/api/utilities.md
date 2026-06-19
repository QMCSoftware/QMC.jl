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

`gpu_fwht` and `gpu_fwht!` are currently **placeholder** exported names. Their docstrings are listed here for API completeness, but the current implementation is only the CPU `fwht`/`fwht!` fallback and does not provide true GPU acceleration.

```@docs
fwht!
fwht
ifwht!
gpu_fwht(::Vector{Float64})
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
