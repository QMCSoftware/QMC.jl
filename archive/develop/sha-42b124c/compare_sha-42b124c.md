# Benchmark: `local` vs `dda10763e7dfca13656cdbbb196a6c1f2f569675`

| | local (`local`) | reference (`dda10763e7dfca13656cdbbb196a6c1f2f569675`) |
|---|---|---|
| commit | non gitrepo | non gitrepo |
| date | 2026-06-27T01:11:19.364 | 2026-06-27T01:13:01.509 |

**`ratio = reference time ÷ local time`**  
ratio `< 1` → local is **slower** ❌  |  ratio `> 1` → local is **faster** ✅

## Aggregate Summary

| metric | ratio | local total | reference total |
|:-------|------:|------------:|----------------:|
| matched benchmarks | 111 | — | — |
| weighted time ratio | 0.993 | 223.248 ms | 221.590 ms |
| weighted memory ratio | 1.000 | 173029.9 KiB | 173029.9 KiB |

| benchmark | ratio | verdict | local (ms) | reference (ms) |
|:----------|------:|:-------:|----------:|---------------:|
| `["evaluate", "BoxIntegral d=10 n=1024"]` | 0.766 | ❌ | 0.011 | 0.009 |
| `["evaluate", "BoxIntegral d=10 n=16384"]` | 0.983 | – | 0.150 | 0.148 |
| `["evaluate", "BoxIntegral d=10 n=256"]` | 0.927 | ❌ | 0.004 | 0.004 |
| `["evaluate", "BoxIntegral d=10 n=4096"]` | 0.958 | – | 0.041 | 0.040 |
| `["evaluate", "BoxIntegral d=200 n=1024"]` | 0.994 | – | 0.054 | 0.053 |
| `["evaluate", "BoxIntegral d=200 n=4096"]` | 0.986 | – | 0.279 | 0.275 |
| `["evaluate", "BoxIntegral d=50 n=1024"]` | 1.340 | ✅ | 0.018 | 0.024 |
| `["evaluate", "BoxIntegral d=50 n=4096"]` | 0.975 | – | 0.090 | 0.088 |
| `["evaluate", "Genz(continuous) d=10 n=1024"]` | 2.276 | ✅ | 0.008 | 0.018 |
| `["evaluate", "Genz(continuous) d=10 n=16384"]` | 0.971 | – | 0.136 | 0.132 |
| `["evaluate", "Genz(continuous) d=10 n=256"]` | 0.999 | – | 0.006 | 0.006 |
| `["evaluate", "Genz(continuous) d=10 n=4096"]` | 0.788 | ❌ | 0.041 | 0.032 |
| `["evaluate", "Genz(gaussian_peak) d=10 n=1024"]` | 0.964 | – | 0.022 | 0.021 |
| `["evaluate", "Genz(gaussian_peak) d=10 n=16384"]` | 0.965 | – | 0.138 | 0.133 |
| `["evaluate", "Genz(gaussian_peak) d=10 n=256"]` | 1.041 | – | 0.006 | 0.006 |
| `["evaluate", "Genz(gaussian_peak) d=10 n=4096"]` | 0.954 | – | 0.035 | 0.033 |
| `["evaluate", "Genz(gaussian_peak) d=200 n=1024"]` | 1.035 | – | 0.056 | 0.058 |
| `["evaluate", "Genz(gaussian_peak) d=200 n=4096"]` | 0.989 | – | 0.276 | 0.273 |
| `["evaluate", "Genz(gaussian_peak) d=50 n=1024"]` | 0.697 | ❌ | 0.020 | 0.014 |
| `["evaluate", "Genz(gaussian_peak) d=50 n=4096"]` | 1.001 | – | 0.084 | 0.084 |
| `["evaluate", "Genz(oscillatory) n=1024"]` | 1.008 | – | 0.017 | 0.017 |
| `["evaluate", "Genz(oscillatory) n=16384"]` | 0.997 | – | 0.247 | 0.246 |
| `["evaluate", "Genz(oscillatory) n=256"]` | 1.078 | ✅ | 0.005 | 0.005 |
| `["evaluate", "Genz(oscillatory) n=4096"]` | 0.947 | ❌ | 0.047 | 0.044 |
| `["evaluate", "Keister n=1024"]` | 1.029 | – | 0.012 | 0.012 |
| `["evaluate", "Keister n=16384"]` | 0.983 | – | 0.185 | 0.182 |
| `["evaluate", "Keister n=256"]` | 1.057 | ✅ | 0.005 | 0.005 |
| `["evaluate", "Keister n=4096"]` | 0.986 | – | 0.055 | 0.054 |
| `["evaluate", "Linear0 d=10 n=1024"]` | 0.989 | – | 0.005 | 0.005 |
| `["evaluate", "Linear0 d=10 n=16384"]` | 1.094 | ✅ | 0.057 | 0.062 |
| `["evaluate", "Linear0 d=10 n=256"]` | 0.942 | ❌ | 0.002 | 0.002 |
| `["evaluate", "Linear0 d=10 n=4096"]` | 0.990 | – | 0.017 | 0.017 |
| `["evaluate", "Linear0 d=200 n=1024"]` | 1.013 | – | 0.044 | 0.045 |
| `["evaluate", "Linear0 d=200 n=4096"]` | 0.989 | – | 0.253 | 0.250 |
| `["evaluate", "Linear0 d=50 n=1024"]` | 0.988 | – | 0.018 | 0.018 |
| `["evaluate", "Linear0 d=50 n=4096"]` | 0.910 | ❌ | 0.064 | 0.058 |
| `["gen_samples", "DigitalNetB2 d=10 n=1024"]` | 0.959 | – | 0.063 | 0.060 |
| `["gen_samples", "DigitalNetB2 d=10 n=16384"]` | 0.945 | ❌ | 1.580 | 1.494 |
| `["gen_samples", "DigitalNetB2 d=10 n=256"]` | 0.998 | – | 0.029 | 0.029 |
| `["gen_samples", "DigitalNetB2 d=10 n=4096"]` | 0.840 | ❌ | 0.377 | 0.317 |
| `["gen_samples", "DigitalNetB2 d=3 n=1024"]` | 0.981 | – | 0.024 | 0.024 |
| `["gen_samples", "DigitalNetB2 d=3 n=16384"]` | 1.113 | ✅ | 0.439 | 0.488 |
| `["gen_samples", "DigitalNetB2 d=3 n=256"]` | 1.075 | ✅ | 0.010 | 0.011 |
| `["gen_samples", "DigitalNetB2 d=3 n=4096"]` | 1.046 | – | 0.072 | 0.075 |
| `["gen_samples", "Halton d=10 n=1024"]` | 0.972 | – | 2.000 | 1.944 |
| `["gen_samples", "Halton d=10 n=16384"]` | 0.975 | – | 31.680 | 30.896 |
| `["gen_samples", "Halton d=10 n=256"]` | 0.969 | – | 0.502 | 0.487 |
| `["gen_samples", "Halton d=10 n=4096"]` | 0.972 | – | 7.940 | 7.721 |
| `["gen_samples", "Halton d=3 n=1024"]` | 0.976 | – | 0.570 | 0.556 |
| `["gen_samples", "Halton d=3 n=16384"]` | 0.985 | – | 9.026 | 8.894 |
| `["gen_samples", "Halton d=3 n=256"]` | 0.984 | – | 0.145 | 0.143 |
| `["gen_samples", "Halton d=3 n=4096"]` | 0.974 | – | 2.290 | 2.232 |
| `["gen_samples", "IIDStdUniform d=10 n=1024"]` | 0.989 | – | 0.013 | 0.012 |
| `["gen_samples", "IIDStdUniform d=10 n=16384"]` | 0.986 | – | 0.519 | 0.512 |
| `["gen_samples", "IIDStdUniform d=10 n=256"]` | 1.080 | ✅ | 0.004 | 0.004 |
| `["gen_samples", "IIDStdUniform d=10 n=4096"]` | 0.814 | ❌ | 0.050 | 0.041 |
| `["gen_samples", "IIDStdUniform d=3 n=1024"]` | 1.007 | – | 0.004 | 0.004 |
| `["gen_samples", "IIDStdUniform d=3 n=16384"]` | 1.474 | ✅ | 0.102 | 0.151 |
| `["gen_samples", "IIDStdUniform d=3 n=256"]` | 0.936 | ❌ | 0.002 | 0.002 |
| `["gen_samples", "IIDStdUniform d=3 n=4096"]` | 0.987 | – | 0.014 | 0.014 |
| `["gen_samples", "Kronecker d=10 n=1024"]` | 1.053 | ✅ | 0.081 | 0.086 |
| `["gen_samples", "Kronecker d=10 n=16384"]` | 1.004 | – | 1.987 | 1.996 |
| `["gen_samples", "Kronecker d=10 n=256"]` | 0.948 | ❌ | 0.023 | 0.022 |
| `["gen_samples", "Kronecker d=10 n=4096"]` | 0.984 | – | 0.402 | 0.396 |
| `["gen_samples", "Kronecker d=3 n=1024"]` | 1.006 | – | 0.025 | 0.025 |
| `["gen_samples", "Kronecker d=3 n=16384"]` | 1.001 | – | 0.498 | 0.498 |
| `["gen_samples", "Kronecker d=3 n=256"]` | 1.020 | – | 0.007 | 0.007 |
| `["gen_samples", "Kronecker d=3 n=4096"]` | 1.064 | ✅ | 0.110 | 0.117 |
| `["gen_samples", "Lattice d=10 n=1024"]` | 0.997 | – | 0.229 | 0.228 |
| `["gen_samples", "Lattice d=10 n=16384"]` | 0.817 | ❌ | 5.919 | 4.837 |
| `["gen_samples", "Lattice d=10 n=256"]` | 0.968 | – | 0.061 | 0.059 |
| `["gen_samples", "Lattice d=10 n=4096"]` | 1.012 | – | 1.192 | 1.207 |
| `["gen_samples", "Lattice d=3 n=1024"]` | 1.015 | – | 0.073 | 0.074 |
| `["gen_samples", "Lattice d=3 n=16384"]` | 1.005 | – | 1.518 | 1.525 |
| `["gen_samples", "Lattice d=3 n=256"]` | 0.980 | – | 0.020 | 0.019 |
| `["gen_samples", "Lattice d=3 n=4096"]` | 1.013 | – | 0.293 | 0.296 |
| `["integrate", "CubMCCLT AsianOption"]` | 1.041 | – | 3.362 | 3.499 |
| `["integrate", "CubMCCLT EuropeanOption"]` | 0.991 | – | 7.077 | 7.016 |
| `["integrate", "CubMCCLT Keister"]` | 1.009 | – | 16.430 | 16.580 |
| `["integrate", "CubQMCLatticeG EuropeanOption"]` | 0.966 | – | 2.540 | 2.454 |
| `["integrate", "CubQMCLatticeG Keister"]` | 1.027 | – | 0.511 | 0.525 |
| `["integrate", "CubQMCNetG AsianOption"]` | 1.154 | ✅ | 1.610 | 1.858 |
| `["integrate", "CubQMCNetG EuropeanOption"]` | 1.180 | ✅ | 1.590 | 1.876 |
| `["integrate", "CubQMCNetG Keister"]` | 1.046 | – | 0.306 | 0.320 |
| `["integrate", "CubQMCNetGRep AsianOption"]` | 1.018 | – | 28.365 | 28.863 |
| `["integrate", "CubQMCNetGRep EuropeanOption"]` | 0.972 | – | 28.859 | 28.039 |
| `["integrate", "CubQMCNetGRep Keister"]` | 1.018 | – | 3.840 | 3.909 |
| `["transform", "Gaussian d=10 n=1024"]` | 1.042 | – | 0.155 | 0.162 |
| `["transform", "Gaussian d=10 n=16384"]` | 0.998 | – | 2.515 | 2.510 |
| `["transform", "Gaussian d=10 n=256"]` | 1.033 | – | 0.035 | 0.036 |
| `["transform", "Gaussian d=10 n=4096"]` | 0.997 | – | 0.634 | 0.632 |
| `["transform", "Gaussian d=3 n=1024"]` | 0.954 | – | 0.046 | 0.044 |
| `["transform", "Gaussian d=3 n=16384"]` | 0.989 | – | 0.765 | 0.757 |
| `["transform", "Gaussian d=3 n=256"]` | 0.973 | – | 0.026 | 0.025 |
| `["transform", "Gaussian d=3 n=4096"]` | 0.947 | ❌ | 0.191 | 0.181 |
| `["transform", "Gaussian(dense) d=200 n=1024"]` | 1.024 | – | 3.998 | 4.093 |
| `["transform", "Gaussian(dense) d=200 n=4096"]` | 1.011 | – | 16.102 | 16.282 |
| `["transform", "Gaussian(dense) d=50 n=1024"]` | 0.989 | – | 1.081 | 1.069 |
| `["transform", "Gaussian(dense) d=50 n=4096"]` | 1.008 | – | 3.598 | 3.629 |
| `["transform", "Gaussian(diag) d=200 n=1024"]` | 1.002 | – | 3.145 | 3.150 |
| `["transform", "Gaussian(diag) d=200 n=4096"]` | 1.007 | – | 13.523 | 13.612 |
| `["transform", "Gaussian(diag) d=50 n=1024"]` | 0.999 | – | 0.785 | 0.785 |
| `["transform", "Gaussian(diag) d=50 n=4096"]` | 1.010 | – | 3.140 | 3.170 |
| `["transform", "JohnsonsSU d=10 n=1024"]` | 0.978 | – | 0.256 | 0.251 |
| `["transform", "JohnsonsSU d=10 n=16384"]` | 0.985 | – | 4.203 | 4.140 |
| `["transform", "JohnsonsSU d=10 n=256"]` | 1.132 | ✅ | 0.057 | 0.065 |
| `["transform", "JohnsonsSU d=10 n=4096"]` | 0.988 | – | 1.038 | 1.026 |
| `["transform", "StudentT d=10 n=1024"]` | 1.001 | – | 0.031 | 0.031 |
| `["transform", "StudentT d=10 n=16384"]` | 0.998 | – | 0.901 | 0.899 |
| `["transform", "StudentT d=10 n=256"]` | 0.992 | – | 0.008 | 0.008 |
| `["transform", "StudentT d=10 n=4096"]` | 0.991 | – | 0.121 | 0.120 |
