# True Measures

## Abstract Type

```@docs
AbstractTrueMeasure
```

## Measures

```@docs
Uniform
Gaussian
BrownianMotion
Lebesgue
GeometricBrownianMotion
StudentT
Triangular
Kumaraswamy
JohnsonsSU
BernoulliCont
```

## Transform

```@docs
transform
spawn_tm(::Gaussian, ::AbstractDiscreteDistribution)
spawn_tm(::Uniform, ::AbstractDiscreteDistribution)
spawn_tm(::BrownianMotion, ::AbstractDiscreteDistribution)
spawn_tm(::GeometricBrownianMotion, ::AbstractDiscreteDistribution)
```
