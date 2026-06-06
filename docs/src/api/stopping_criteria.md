# Stopping Criteria

## Abstract Type

```@docs
AbstractStoppingCriterion
```

## Algorithms

`PFGPCI` is included below for API visibility, but it is currently a stub:
constructing it works and `integrate` throws a descriptive "not yet
implemented" error until a Julia GP backend is added.

`CubQMCNetGSingle` remains available as an exported backward-compatible alias
for `CubQMCNetG`.

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
set_tolerance!
```
