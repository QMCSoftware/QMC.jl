# Kernels

## Abstract Types

```@docs
AbstractKernel
AbstractStationaryKernel
```

## Shift-Invariant Kernels

```@docs
KernelShiftInvar
KernelDigShiftInvar
KernelShiftInvarCombined
KernelDigShiftInvarAdaptiveAlpha
KernelDigShiftInvarCombined
KernelShiftInvarDeriv
```

## Matérn and Gaussian Kernels

```@docs
KernelMatern12
KernelMatern32
KernelMatern52
KernelGaussian
KernelRationalQuadratic
KernelSquaredExponential
```

## Combined Kernels

```@docs
SumKernel
ProductKernel
KernelMultiTask
```

## Kernel Operations

```@docs
compute_kernel_eigenvalues
kernel_eval
kernel_matrix
kernel_eval_deriv
```
