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
