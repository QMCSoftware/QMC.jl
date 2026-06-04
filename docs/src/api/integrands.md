# Integrands

## Abstract Type

```@docs
AbstractIntegrand
AbstractMLIntegrand
```

## Test Functions

```@docs
CustomFun
Keister
Genz
AsianOption
FinancialOption
FinancialOptionML
BoxIntegral
Linear0
Sin1D
Ishigami
Hartmann6D
Multimodal2D
FourBranch2D
SensitivityIndices
BayesianLRCoeffs
UMBridgeWrapper
```

## Evaluation

```@docs
evaluate
sample_and_evaluate
ml_evaluate
dimension_at_level(::AbstractMLIntegrand, ::Int)
cost_at_level(::AbstractMLIntegrand, ::Int)
spawn_integrand(::AbstractMLIntegrand, ::Int)
ml_sample_and_evaluate(::AbstractMLIntegrand, ::AbstractDiscreteDistribution, ::AbstractTrueMeasure, ::Int, ::Int)
ml_sample_and_evaluate_reps(::AbstractMLIntegrand, ::AbstractDiscreteDistribution, ::AbstractTrueMeasure, ::Int, ::Int, ::Int)
compute_sensitivity_indices(::SensitivityIndices, ::AbstractMatrix)
```

## Exact Values

```@docs
keister_exact
genz_exact
ishigami_exact
get_exact_value(::AsianOption)
get_exact_value(::FinancialOption)
```
