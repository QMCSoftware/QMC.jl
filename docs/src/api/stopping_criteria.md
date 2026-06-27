# Stopping Criteria

## Abstract Type

```@docs
AbstractStoppingCriterion
```

## Algorithms

`PFGPCI` is included below for API visibility as an **experimental** stopping criterion. The constructor and deterministic helpers are supported, and end-to-end `integrate` works once the optional `AbstractGPs`/`Optim` backend extension is loaded. Until that backend path settles, the interface should be treated as experimental rather than stable.

`CubQMCNetGSingle` remains available as an exported backward-compatible alias for `CubQMCNetG`.

```@docs
CubMCCLT
CubMCCLTVec
CubMCG
CubQMCLatticeG
CubQMCNetG
CubQMCNetGRep
CubQMCBayesLatticeG
CubQMCBayesNetG
CubQMCRepStudentT
CubMLMC
CubMLMCCont
CubMLQMC
CubMLQMCCont
PFGPCI
```

## Integration

```@docs
integrate
QMCResult
QMCVecResult
set_tolerance!
```
