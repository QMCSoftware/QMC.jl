# Benchmark: `local` vs `8d8838eb97e80e743b92bf8e22359712d7f1a919`

| | local (`local`) | reference (`8d8838eb97e80e743b92bf8e22359712d7f1a919`) |
|---|---|---|
| commit | non gitrepo | non gitrepo |
| date | 2026-06-28T13:33:04.852 | 2026-06-28T13:34:54.867 |

**`ratio = reference time ÷ local time`**  
ratio `< 1` → local is **slower** ❌  |  ratio `> 1` → local is **faster** ✅

## Aggregate Summary

| metric | ratio | local total | reference total |
|:-------|------:|------------:|----------------:|
| matched benchmarks | 111 | — | — |
| weighted time ratio | 0.961 | 205.599 ms | 197.619 ms |
| weighted memory ratio | 1.000 | 173037.5 KiB | 173037.5 KiB |

| benchmark | ratio | verdict | local (ms) | reference (ms) |
|:----------|------:|:-------:|----------:|---------------:|
| `["evaluate", "BoxIntegral d=10 n=1024"]` | 1.013 | – | 0.008 | 0.008 |
| `["evaluate", "BoxIntegral d=10 n=16384"]` | 1.009 | – | 0.131 | 0.132 |
| `["evaluate", "BoxIntegral d=10 n=256"]` | 1.005 | – | 0.003 | 0.003 |
| `["evaluate", "BoxIntegral d=10 n=4096"]` | 1.026 | – | 0.034 | 0.035 |
| `["evaluate", "BoxIntegral d=200 n=1024"]` | 0.994 | – | 0.032 | 0.032 |
| `["evaluate", "BoxIntegral d=200 n=4096"]` | 1.001 | – | 0.211 | 0.211 |
| `["evaluate", "BoxIntegral d=50 n=1024"]` | 0.965 | – | 0.013 | 0.012 |
| `["evaluate", "BoxIntegral d=50 n=4096"]` | 0.995 | – | 0.078 | 0.077 |
| `["evaluate", "Genz(continuous) d=10 n=1024"]` | 1.016 | – | 0.007 | 0.008 |
| `["evaluate", "Genz(continuous) d=10 n=16384"]` | 0.993 | – | 0.121 | 0.120 |
| `["evaluate", "Genz(continuous) d=10 n=256"]` | 0.948 | ❌ | 0.003 | 0.003 |
| `["evaluate", "Genz(continuous) d=10 n=4096"]` | 0.993 | – | 0.031 | 0.031 |
| `["evaluate", "Genz(gaussian_peak) d=10 n=1024"]` | 0.987 | – | 0.007 | 0.007 |
| `["evaluate", "Genz(gaussian_peak) d=10 n=16384"]` | 0.973 | – | 0.121 | 0.118 |
| `["evaluate", "Genz(gaussian_peak) d=10 n=256"]` | 0.975 | – | 0.003 | 0.003 |
| `["evaluate", "Genz(gaussian_peak) d=10 n=4096"]` | 0.976 | – | 0.032 | 0.031 |
| `["evaluate", "Genz(gaussian_peak) d=200 n=1024"]` | 1.117 | ✅ | 0.034 | 0.038 |
| `["evaluate", "Genz(gaussian_peak) d=200 n=4096"]` | 0.998 | – | 0.212 | 0.211 |
| `["evaluate", "Genz(gaussian_peak) d=50 n=1024"]` | 0.995 | – | 0.013 | 0.012 |
| `["evaluate", "Genz(gaussian_peak) d=50 n=4096"]` | 0.989 | – | 0.071 | 0.070 |
| `["evaluate", "Genz(oscillatory) n=1024"]` | 1.015 | – | 0.008 | 0.008 |
| `["evaluate", "Genz(oscillatory) n=16384"]` | 1.017 | – | 0.121 | 0.123 |
| `["evaluate", "Genz(oscillatory) n=256"]` | 0.971 | – | 0.003 | 0.003 |
| `["evaluate", "Genz(oscillatory) n=4096"]` | 1.038 | – | 0.032 | 0.033 |
| `["evaluate", "Keister n=1024"]` | 0.978 | – | 0.011 | 0.011 |
| `["evaluate", "Keister n=16384"]` | 0.982 | – | 0.165 | 0.162 |
| `["evaluate", "Keister n=256"]` | 0.967 | – | 0.004 | 0.004 |
| `["evaluate", "Keister n=4096"]` | 0.957 | – | 0.050 | 0.048 |
| `["evaluate", "Linear0 d=10 n=1024"]` | 0.990 | – | 0.002 | 0.002 |
| `["evaluate", "Linear0 d=10 n=16384"]` | 1.027 | – | 0.050 | 0.052 |
| `["evaluate", "Linear0 d=10 n=256"]` | 1.013 | – | 0.001 | 0.001 |
| `["evaluate", "Linear0 d=10 n=4096"]` | 0.941 | ❌ | 0.010 | 0.009 |
| `["evaluate", "Linear0 d=200 n=1024"]` | 0.982 | – | 0.024 | 0.023 |
| `["evaluate", "Linear0 d=200 n=4096"]` | 0.986 | – | 0.190 | 0.187 |
| `["evaluate", "Linear0 d=50 n=1024"]` | 1.003 | – | 0.007 | 0.007 |
| `["evaluate", "Linear0 d=50 n=4096"]` | 0.914 | ❌ | 0.052 | 0.048 |
| `["gen_samples", "DigitalNetB2 d=10 n=1024"]` | 0.929 | ❌ | 0.044 | 0.041 |
| `["gen_samples", "DigitalNetB2 d=10 n=16384"]` | 1.009 | – | 1.480 | 1.494 |
| `["gen_samples", "DigitalNetB2 d=10 n=256"]` | 0.995 | – | 0.020 | 0.019 |
| `["gen_samples", "DigitalNetB2 d=10 n=4096"]` | 0.997 | – | 0.390 | 0.389 |
| `["gen_samples", "DigitalNetB2 d=3 n=1024"]` | 0.979 | – | 0.017 | 0.017 |
| `["gen_samples", "DigitalNetB2 d=3 n=16384"]` | 0.767 | ❌ | 0.483 | 0.370 |
| `["gen_samples", "DigitalNetB2 d=3 n=256"]` | 0.981 | – | 0.007 | 0.007 |
| `["gen_samples", "DigitalNetB2 d=3 n=4096"]` | 1.058 | ✅ | 0.050 | 0.053 |
| `["gen_samples", "Halton d=10 n=1024"]` | 1.060 | ✅ | 1.455 | 1.542 |
| `["gen_samples", "Halton d=10 n=16384"]` | 1.113 | ✅ | 23.645 | 26.326 |
| `["gen_samples", "Halton d=10 n=256"]` | 0.966 | – | 0.393 | 0.379 |
| `["gen_samples", "Halton d=10 n=4096"]` | 1.100 | ✅ | 5.725 | 6.295 |
| `["gen_samples", "Halton d=3 n=1024"]` | 1.098 | ✅ | 0.458 | 0.502 |
| `["gen_samples", "Halton d=3 n=16384"]` | 1.074 | ✅ | 8.073 | 8.674 |
| `["gen_samples", "Halton d=3 n=256"]` | 1.125 | ✅ | 0.109 | 0.122 |
| `["gen_samples", "Halton d=3 n=4096"]` | 1.086 | ✅ | 1.923 | 2.089 |
| `["gen_samples", "IIDStdUniform d=10 n=1024"]` | 0.792 | ❌ | 0.012 | 0.009 |
| `["gen_samples", "IIDStdUniform d=10 n=16384"]` | 0.994 | – | 0.619 | 0.616 |
| `["gen_samples", "IIDStdUniform d=10 n=256"]` | 0.971 | – | 0.003 | 0.003 |
| `["gen_samples", "IIDStdUniform d=10 n=4096"]` | 0.522 | ❌ | 0.050 | 0.026 |
| `["gen_samples", "IIDStdUniform d=3 n=1024"]` | 0.805 | ❌ | 0.004 | 0.003 |
| `["gen_samples", "IIDStdUniform d=3 n=16384"]` | 0.967 | – | 0.043 | 0.042 |
| `["gen_samples", "IIDStdUniform d=3 n=256"]` | 1.002 | – | 0.001 | 0.001 |
| `["gen_samples", "IIDStdUniform d=3 n=4096"]` | 0.931 | ❌ | 0.011 | 0.010 |
| `["gen_samples", "Kronecker d=10 n=1024"]` | 0.978 | – | 0.077 | 0.075 |
| `["gen_samples", "Kronecker d=10 n=16384"]` | 0.998 | – | 1.911 | 1.908 |
| `["gen_samples", "Kronecker d=10 n=256"]` | 0.972 | – | 0.019 | 0.018 |
| `["gen_samples", "Kronecker d=10 n=4096"]` | 0.803 | ❌ | 0.416 | 0.334 |
| `["gen_samples", "Kronecker d=3 n=1024"]` | 0.985 | – | 0.022 | 0.022 |
| `["gen_samples", "Kronecker d=3 n=16384"]` | 0.985 | – | 0.418 | 0.412 |
| `["gen_samples", "Kronecker d=3 n=256"]` | 1.009 | – | 0.006 | 0.006 |
| `["gen_samples", "Kronecker d=3 n=4096"]` | 0.992 | – | 0.096 | 0.096 |
| `["gen_samples", "Lattice d=10 n=1024"]` | 0.997 | – | 0.197 | 0.197 |
| `["gen_samples", "Lattice d=10 n=16384"]` | 1.018 | – | 4.668 | 4.753 |
| `["gen_samples", "Lattice d=10 n=256"]` | 1.023 | – | 0.052 | 0.053 |
| `["gen_samples", "Lattice d=10 n=4096"]` | 1.013 | – | 1.195 | 1.211 |
| `["gen_samples", "Lattice d=3 n=1024"]` | 1.019 | – | 0.056 | 0.057 |
| `["gen_samples", "Lattice d=3 n=16384"]` | 0.968 | – | 1.348 | 1.304 |
| `["gen_samples", "Lattice d=3 n=256"]` | 1.014 | – | 0.015 | 0.016 |
| `["gen_samples", "Lattice d=3 n=4096"]` | 0.972 | – | 0.233 | 0.227 |
| `["integrate", "CubMCCLT AsianOption"]` | 0.978 | – | 3.609 | 3.531 |
| `["integrate", "CubMCCLT EuropeanOption"]` | 1.050 | – | 6.913 | 7.257 |
| `["integrate", "CubMCCLT Keister"]` | 1.010 | – | 14.079 | 14.213 |
| `["integrate", "CubQMCLatticeG EuropeanOption"]` | 0.959 | – | 2.151 | 2.062 |
| `["integrate", "CubQMCLatticeG Keister"]` | 1.032 | – | 0.430 | 0.444 |
| `["integrate", "CubQMCNetG AsianOption"]` | 0.935 | ❌ | 1.348 | 1.261 |
| `["integrate", "CubQMCNetG EuropeanOption"]` | 0.924 | ❌ | 1.339 | 1.237 |
| `["integrate", "CubQMCNetG Keister"]` | 1.038 | – | 0.268 | 0.278 |
| `["integrate", "CubQMCNetGRep AsianOption"]` | 0.819 | ❌ | 26.318 | 21.551 |
| `["integrate", "CubQMCNetGRep EuropeanOption"]` | 0.819 | ❌ | 25.924 | 21.239 |
| `["integrate", "CubQMCNetGRep Keister"]` | 0.986 | – | 3.434 | 3.385 |
| `["transform", "Gaussian d=10 n=1024"]` | 0.993 | – | 0.122 | 0.121 |
| `["transform", "Gaussian d=10 n=16384"]` | 1.003 | – | 2.740 | 2.747 |
| `["transform", "Gaussian d=10 n=256"]` | 1.012 | – | 0.029 | 0.030 |
| `["transform", "Gaussian d=10 n=4096"]` | 1.021 | – | 0.583 | 0.595 |
| `["transform", "Gaussian d=3 n=1024"]` | 0.756 | ❌ | 0.047 | 0.035 |
| `["transform", "Gaussian d=3 n=16384"]` | 0.986 | – | 0.734 | 0.724 |
| `["transform", "Gaussian d=3 n=256"]` | 1.018 | – | 0.010 | 0.010 |
| `["transform", "Gaussian d=3 n=4096"]` | 0.988 | – | 0.152 | 0.150 |
| `["transform", "Gaussian(dense) d=200 n=1024"]` | 0.995 | – | 4.556 | 4.534 |
| `["transform", "Gaussian(dense) d=200 n=4096"]` | 0.966 | – | 19.105 | 18.463 |
| `["transform", "Gaussian(dense) d=50 n=1024"]` | 0.962 | – | 0.918 | 0.883 |
| `["transform", "Gaussian(dense) d=50 n=4096"]` | 0.968 | – | 3.865 | 3.742 |
| `["transform", "Gaussian(diag) d=200 n=1024"]` | 1.003 | – | 3.454 | 3.464 |
| `["transform", "Gaussian(diag) d=200 n=4096"]` | 0.928 | ❌ | 14.917 | 13.845 |
| `["transform", "Gaussian(diag) d=50 n=1024"]` | 1.000 | – | 0.775 | 0.774 |
| `["transform", "Gaussian(diag) d=50 n=4096"]` | 0.986 | – | 3.493 | 3.445 |
| `["transform", "JohnsonsSU d=10 n=1024"]` | 0.989 | – | 0.199 | 0.197 |
| `["transform", "JohnsonsSU d=10 n=16384"]` | 0.964 | – | 3.971 | 3.827 |
| `["transform", "JohnsonsSU d=10 n=256"]` | 0.999 | – | 0.049 | 0.048 |
| `["transform", "JohnsonsSU d=10 n=4096"]` | 0.976 | – | 0.886 | 0.865 |
| `["transform", "StudentT d=10 n=1024"]` | 0.982 | – | 0.051 | 0.050 |
| `["transform", "StudentT d=10 n=16384"]` | 0.620 | ❌ | 1.279 | 0.793 |
| `["transform", "StudentT d=10 n=256"]` | 1.001 | – | 0.013 | 0.013 |
| `["transform", "StudentT d=10 n=4096"]` | 0.999 | – | 0.199 | 0.199 |
