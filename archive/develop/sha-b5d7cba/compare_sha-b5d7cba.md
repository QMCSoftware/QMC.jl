# Benchmark: `local` vs `365da35adde29c849005a3cd2975122da9b63b78`

| | local (`local`) | reference (`365da35adde29c849005a3cd2975122da9b63b78`) |
|---|---|---|
| commit | non gitrepo | non gitrepo |
| date | 2026-06-23T09:23:04.443 | 2026-06-23T09:24:36.532 |

**`ratio = reference time ÷ local time`**  
ratio `< 1` → local is **slower** ❌  |  ratio `> 1` → local is **faster** ✅

## Aggregate Summary

| metric | ratio | local total | reference total |
|:-------|------:|------------:|----------------:|
| matched benchmarks | 111 | — | — |
| weighted time ratio | 0.984 | 159.617 ms | 157.135 ms |
| weighted memory ratio | 1.000 | 173029.9 KiB | 173035.1 KiB |

| benchmark | ratio | verdict | local (ms) | reference (ms) |
|:----------|------:|:-------:|----------:|---------------:|
| `["evaluate", "BoxIntegral d=10 n=1024"]` | 1.043 | – | 0.007 | 0.007 |
| `["evaluate", "BoxIntegral d=10 n=16384"]` | 1.027 | – | 0.101 | 0.103 |
| `["evaluate", "BoxIntegral d=10 n=256"]` | 1.033 | – | 0.002 | 0.002 |
| `["evaluate", "BoxIntegral d=10 n=4096"]` | 0.835 | ❌ | 0.032 | 0.027 |
| `["evaluate", "BoxIntegral d=200 n=1024"]` | 1.019 | – | 0.025 | 0.025 |
| `["evaluate", "BoxIntegral d=200 n=4096"]` | 0.975 | – | 0.160 | 0.156 |
| `["evaluate", "BoxIntegral d=50 n=1024"]` | 0.944 | ❌ | 0.011 | 0.010 |
| `["evaluate", "BoxIntegral d=50 n=4096"]` | 0.941 | ❌ | 0.059 | 0.055 |
| `["evaluate", "Genz(continuous) d=10 n=1024"]` | 1.024 | – | 0.006 | 0.006 |
| `["evaluate", "Genz(continuous) d=10 n=16384"]` | 0.987 | – | 0.091 | 0.090 |
| `["evaluate", "Genz(continuous) d=10 n=256"]` | 1.050 | ✅ | 0.002 | 0.002 |
| `["evaluate", "Genz(continuous) d=10 n=4096"]` | 0.921 | ❌ | 0.027 | 0.025 |
| `["evaluate", "Genz(gaussian_peak) d=10 n=1024"]` | 1.025 | – | 0.006 | 0.006 |
| `["evaluate", "Genz(gaussian_peak) d=10 n=16384"]` | 0.996 | – | 0.091 | 0.091 |
| `["evaluate", "Genz(gaussian_peak) d=10 n=256"]` | 1.082 | ✅ | 0.002 | 0.002 |
| `["evaluate", "Genz(gaussian_peak) d=10 n=4096"]` | 0.849 | ❌ | 0.028 | 0.024 |
| `["evaluate", "Genz(gaussian_peak) d=200 n=1024"]` | 1.082 | ✅ | 0.024 | 0.026 |
| `["evaluate", "Genz(gaussian_peak) d=200 n=4096"]` | 1.004 | – | 0.158 | 0.158 |
| `["evaluate", "Genz(gaussian_peak) d=50 n=1024"]` | 1.238 | ✅ | 0.009 | 0.012 |
| `["evaluate", "Genz(gaussian_peak) d=50 n=4096"]` | 0.966 | – | 0.055 | 0.053 |
| `["evaluate", "Genz(oscillatory) n=1024"]` | 0.997 | – | 0.006 | 0.006 |
| `["evaluate", "Genz(oscillatory) n=16384"]` | 1.015 | – | 0.087 | 0.088 |
| `["evaluate", "Genz(oscillatory) n=256"]` | 1.096 | ✅ | 0.002 | 0.003 |
| `["evaluate", "Genz(oscillatory) n=4096"]` | 0.892 | ❌ | 0.027 | 0.024 |
| `["evaluate", "Keister n=1024"]` | 1.019 | – | 0.009 | 0.009 |
| `["evaluate", "Keister n=16384"]` | 1.025 | – | 0.121 | 0.124 |
| `["evaluate", "Keister n=256"]` | 1.015 | – | 0.003 | 0.003 |
| `["evaluate", "Keister n=4096"]` | 1.039 | – | 0.036 | 0.037 |
| `["evaluate", "Linear0 d=10 n=1024"]` | 1.055 | ✅ | 0.002 | 0.002 |
| `["evaluate", "Linear0 d=10 n=16384"]` | 0.997 | – | 0.035 | 0.035 |
| `["evaluate", "Linear0 d=10 n=256"]` | 1.048 | – | 0.001 | 0.001 |
| `["evaluate", "Linear0 d=10 n=4096"]` | 0.971 | – | 0.008 | 0.008 |
| `["evaluate", "Linear0 d=200 n=1024"]` | 1.012 | – | 0.019 | 0.019 |
| `["evaluate", "Linear0 d=200 n=4096"]` | 0.992 | – | 0.140 | 0.139 |
| `["evaluate", "Linear0 d=50 n=1024"]` | 0.975 | – | 0.005 | 0.005 |
| `["evaluate", "Linear0 d=50 n=4096"]` | 0.947 | ❌ | 0.038 | 0.036 |
| `["gen_samples", "DigitalNetB2 d=10 n=1024"]` | 1.017 | – | 0.058 | 0.059 |
| `["gen_samples", "DigitalNetB2 d=10 n=16384"]` | 1.005 | – | 1.190 | 1.196 |
| `["gen_samples", "DigitalNetB2 d=10 n=256"]` | 1.016 | – | 0.038 | 0.038 |
| `["gen_samples", "DigitalNetB2 d=10 n=4096"]` | 0.409 | ❌ | 0.317 | 0.130 |
| `["gen_samples", "DigitalNetB2 d=3 n=1024"]` | 1.000 | – | 0.021 | 0.021 |
| `["gen_samples", "DigitalNetB2 d=3 n=16384"]` | 0.509 | ❌ | 0.309 | 0.157 |
| `["gen_samples", "DigitalNetB2 d=3 n=256"]` | 0.982 | – | 0.012 | 0.012 |
| `["gen_samples", "DigitalNetB2 d=3 n=4096"]` | 1.000 | – | 0.045 | 0.045 |
| `["gen_samples", "Halton d=10 n=1024"]` | 1.000 | – | 1.201 | 1.201 |
| `["gen_samples", "Halton d=10 n=16384"]` | 1.000 | – | 20.437 | 20.432 |
| `["gen_samples", "Halton d=10 n=256"]` | 0.999 | – | 0.290 | 0.290 |
| `["gen_samples", "Halton d=10 n=4096"]` | 0.991 | – | 4.914 | 4.869 |
| `["gen_samples", "Halton d=3 n=1024"]` | 1.009 | – | 0.390 | 0.394 |
| `["gen_samples", "Halton d=3 n=16384"]` | 1.000 | – | 6.723 | 6.723 |
| `["gen_samples", "Halton d=3 n=256"]` | 1.005 | – | 0.093 | 0.093 |
| `["gen_samples", "Halton d=3 n=4096"]` | 0.998 | – | 1.625 | 1.622 |
| `["gen_samples", "IIDStdUniform d=10 n=1024"]` | 1.007 | – | 0.009 | 0.009 |
| `["gen_samples", "IIDStdUniform d=10 n=16384"]` | 1.070 | ✅ | 0.461 | 0.493 |
| `["gen_samples", "IIDStdUniform d=10 n=256"]` | 0.936 | ❌ | 0.003 | 0.003 |
| `["gen_samples", "IIDStdUniform d=10 n=4096"]` | 0.421 | ❌ | 0.051 | 0.021 |
| `["gen_samples", "IIDStdUniform d=3 n=1024"]` | 1.058 | ✅ | 0.003 | 0.003 |
| `["gen_samples", "IIDStdUniform d=3 n=16384"]` | 0.891 | ❌ | 0.033 | 0.030 |
| `["gen_samples", "IIDStdUniform d=3 n=256"]` | 0.947 | ❌ | 0.001 | 0.001 |
| `["gen_samples", "IIDStdUniform d=3 n=4096"]` | 0.875 | ❌ | 0.010 | 0.009 |
| `["gen_samples", "Kronecker d=10 n=1024"]` | 1.003 | – | 0.061 | 0.061 |
| `["gen_samples", "Kronecker d=10 n=16384"]` | 1.014 | – | 1.494 | 1.515 |
| `["gen_samples", "Kronecker d=10 n=256"]` | 0.990 | – | 0.015 | 0.015 |
| `["gen_samples", "Kronecker d=10 n=4096"]` | 0.892 | ❌ | 0.292 | 0.260 |
| `["gen_samples", "Kronecker d=3 n=1024"]` | 0.822 | ❌ | 0.022 | 0.018 |
| `["gen_samples", "Kronecker d=3 n=16384"]` | 0.988 | – | 0.328 | 0.324 |
| `["gen_samples", "Kronecker d=3 n=256"]` | 0.982 | – | 0.005 | 0.005 |
| `["gen_samples", "Kronecker d=3 n=4096"]` | 0.984 | – | 0.079 | 0.078 |
| `["gen_samples", "Lattice d=10 n=1024"]` | 0.993 | – | 0.155 | 0.154 |
| `["gen_samples", "Lattice d=10 n=16384"]` | 0.998 | – | 3.656 | 3.650 |
| `["gen_samples", "Lattice d=10 n=256"]` | 1.016 | – | 0.040 | 0.040 |
| `["gen_samples", "Lattice d=10 n=4096"]` | 0.708 | ❌ | 0.905 | 0.640 |
| `["gen_samples", "Lattice d=3 n=1024"]` | 0.998 | – | 0.045 | 0.045 |
| `["gen_samples", "Lattice d=3 n=16384"]` | 0.921 | ❌ | 1.063 | 0.980 |
| `["gen_samples", "Lattice d=3 n=256"]` | 0.993 | – | 0.012 | 0.012 |
| `["gen_samples", "Lattice d=3 n=4096"]` | 0.987 | – | 0.178 | 0.176 |
| `["integrate", "CubMCCLT AsianOption"]` | 0.984 | – | 2.758 | 2.715 |
| `["integrate", "CubMCCLT EuropeanOption"]` | 0.959 | – | 5.604 | 5.373 |
| `["integrate", "CubMCCLT Keister"]` | 0.911 | ❌ | 11.391 | 10.374 |
| `["integrate", "CubQMCLatticeG EuropeanOption"]` | 0.948 | ❌ | 1.671 | 1.584 |
| `["integrate", "CubQMCLatticeG Keister"]` | 0.996 | – | 0.342 | 0.340 |
| `["integrate", "CubQMCNetG AsianOption"]` | 0.918 | ❌ | 1.160 | 1.065 |
| `["integrate", "CubQMCNetG EuropeanOption"]` | 0.995 | – | 1.071 | 1.066 |
| `["integrate", "CubQMCNetG Keister"]` | 0.992 | – | 0.223 | 0.221 |
| `["integrate", "CubQMCNetGRep AsianOption"]` | 1.042 | – | 18.283 | 19.045 |
| `["integrate", "CubQMCNetGRep EuropeanOption"]` | 1.049 | – | 17.916 | 18.792 |
| `["integrate", "CubQMCNetGRep Keister"]` | 0.994 | – | 2.905 | 2.889 |
| `["transform", "Gaussian d=10 n=1024"]` | 1.064 | ✅ | 0.096 | 0.102 |
| `["transform", "Gaussian d=10 n=16384"]` | 0.994 | – | 2.179 | 2.165 |
| `["transform", "Gaussian d=10 n=256"]` | 0.979 | – | 0.024 | 0.023 |
| `["transform", "Gaussian d=10 n=4096"]` | 0.993 | – | 0.456 | 0.452 |
| `["transform", "Gaussian d=3 n=1024"]` | 1.008 | – | 0.028 | 0.028 |
| `["transform", "Gaussian d=3 n=16384"]` | 1.003 | – | 0.580 | 0.582 |
| `["transform", "Gaussian d=3 n=256"]` | 1.021 | – | 0.007 | 0.008 |
| `["transform", "Gaussian d=3 n=4096"]` | 0.999 | – | 0.116 | 0.116 |
| `["transform", "Gaussian(dense) d=200 n=1024"]` | 0.987 | – | 3.500 | 3.456 |
| `["transform", "Gaussian(dense) d=200 n=4096"]` | 0.983 | – | 14.348 | 14.110 |
| `["transform", "Gaussian(dense) d=50 n=1024"]` | 0.911 | ❌ | 0.699 | 0.637 |
| `["transform", "Gaussian(dense) d=50 n=4096"]` | 0.970 | – | 2.962 | 2.872 |
| `["transform", "Gaussian(diag) d=200 n=1024"]` | 0.996 | – | 2.727 | 2.717 |
| `["transform", "Gaussian(diag) d=200 n=4096"]` | 0.925 | ❌ | 11.857 | 10.964 |
| `["transform", "Gaussian(diag) d=50 n=1024"]` | 1.003 | – | 0.612 | 0.614 |
| `["transform", "Gaussian(diag) d=50 n=4096"]` | 0.986 | – | 2.745 | 2.707 |
| `["transform", "JohnsonsSU d=10 n=1024"]` | 0.980 | – | 0.159 | 0.156 |
| `["transform", "JohnsonsSU d=10 n=16384"]` | 0.993 | – | 3.190 | 3.168 |
| `["transform", "JohnsonsSU d=10 n=256"]` | 0.982 | – | 0.039 | 0.038 |
| `["transform", "JohnsonsSU d=10 n=4096"]` | 0.930 | ❌ | 0.747 | 0.695 |
| `["transform", "StudentT d=10 n=1024"]` | 1.006 | – | 0.039 | 0.039 |
| `["transform", "StudentT d=10 n=16384"]` | 0.615 | ❌ | 0.998 | 0.614 |
| `["transform", "StudentT d=10 n=256"]` | 1.032 | – | 0.010 | 0.011 |
| `["transform", "StudentT d=10 n=4096"]` | 1.000 | – | 0.154 | 0.154 |
