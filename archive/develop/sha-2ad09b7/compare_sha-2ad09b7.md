# Benchmark: `local` vs `7af483956642f91878f990c058faee0a15c5cdec`

| | local (`local`) | reference (`7af483956642f91878f990c058faee0a15c5cdec`) |
|---|---|---|
| commit | non gitrepo | non gitrepo |
| date | 2026-06-28T06:16:12.135 | 2026-06-28T06:17:50.436 |

**`ratio = reference time ÷ local time`**  
ratio `< 1` → local is **slower** ❌  |  ratio `> 1` → local is **faster** ✅

## Aggregate Summary

| metric | ratio | local total | reference total |
|:-------|------:|------------:|----------------:|
| matched benchmarks | 111 | — | — |
| weighted time ratio | 1.020 | 200.639 ms | 204.574 ms |
| weighted memory ratio | 1.000 | 173042.7 KiB | 173042.7 KiB |

| benchmark | ratio | verdict | local (ms) | reference (ms) |
|:----------|------:|:-------:|----------:|---------------:|
| `["evaluate", "BoxIntegral d=10 n=1024"]` | 1.392 | ✅ | 0.010 | 0.014 |
| `["evaluate", "BoxIntegral d=10 n=16384"]` | 1.107 | ✅ | 0.126 | 0.140 |
| `["evaluate", "BoxIntegral d=10 n=256"]` | 1.010 | – | 0.003 | 0.003 |
| `["evaluate", "BoxIntegral d=10 n=4096"]` | 1.011 | – | 0.040 | 0.040 |
| `["evaluate", "BoxIntegral d=200 n=1024"]` | 0.869 | ❌ | 0.058 | 0.051 |
| `["evaluate", "BoxIntegral d=200 n=4096"]` | 1.112 | ✅ | 0.168 | 0.187 |
| `["evaluate", "BoxIntegral d=50 n=1024"]` | 1.131 | ✅ | 0.018 | 0.021 |
| `["evaluate", "BoxIntegral d=50 n=4096"]` | 1.006 | – | 0.081 | 0.081 |
| `["evaluate", "Genz(continuous) d=10 n=1024"]` | 0.936 | ❌ | 0.009 | 0.008 |
| `["evaluate", "Genz(continuous) d=10 n=16384"]` | 0.857 | ❌ | 0.142 | 0.122 |
| `["evaluate", "Genz(continuous) d=10 n=256"]` | 0.962 | – | 0.003 | 0.003 |
| `["evaluate", "Genz(continuous) d=10 n=4096"]` | 0.989 | – | 0.037 | 0.037 |
| `["evaluate", "Genz(gaussian_peak) d=10 n=1024"]` | 1.071 | ✅ | 0.009 | 0.009 |
| `["evaluate", "Genz(gaussian_peak) d=10 n=16384"]` | 0.992 | – | 0.127 | 0.126 |
| `["evaluate", "Genz(gaussian_peak) d=10 n=256"]` | 0.916 | ❌ | 0.003 | 0.003 |
| `["evaluate", "Genz(gaussian_peak) d=10 n=4096"]` | 0.978 | – | 0.037 | 0.036 |
| `["evaluate", "Genz(gaussian_peak) d=200 n=1024"]` | 0.848 | ❌ | 0.061 | 0.052 |
| `["evaluate", "Genz(gaussian_peak) d=200 n=4096"]` | 1.188 | ✅ | 0.170 | 0.201 |
| `["evaluate", "Genz(gaussian_peak) d=50 n=1024"]` | 0.853 | ❌ | 0.020 | 0.017 |
| `["evaluate", "Genz(gaussian_peak) d=50 n=4096"]` | 0.904 | ❌ | 0.092 | 0.083 |
| `["evaluate", "Genz(oscillatory) n=1024"]` | 0.942 | ❌ | 0.010 | 0.009 |
| `["evaluate", "Genz(oscillatory) n=16384"]` | 1.021 | – | 0.226 | 0.231 |
| `["evaluate", "Genz(oscillatory) n=256"]` | 0.902 | ❌ | 0.003 | 0.003 |
| `["evaluate", "Genz(oscillatory) n=4096"]` | 1.067 | ✅ | 0.036 | 0.038 |
| `["evaluate", "Keister n=1024"]` | 0.965 | – | 0.013 | 0.012 |
| `["evaluate", "Keister n=16384"]` | 1.015 | – | 0.188 | 0.190 |
| `["evaluate", "Keister n=256"]` | 0.911 | ❌ | 0.004 | 0.004 |
| `["evaluate", "Keister n=4096"]` | 1.023 | – | 0.054 | 0.055 |
| `["evaluate", "Linear0 d=10 n=1024"]` | 0.997 | – | 0.003 | 0.003 |
| `["evaluate", "Linear0 d=10 n=16384"]` | 1.017 | – | 0.049 | 0.050 |
| `["evaluate", "Linear0 d=10 n=256"]` | 0.990 | – | 0.001 | 0.001 |
| `["evaluate", "Linear0 d=10 n=4096"]` | 1.048 | – | 0.012 | 0.012 |
| `["evaluate", "Linear0 d=200 n=1024"]` | 0.861 | ❌ | 0.045 | 0.039 |
| `["evaluate", "Linear0 d=200 n=4096"]` | 1.172 | ✅ | 0.154 | 0.180 |
| `["evaluate", "Linear0 d=50 n=1024"]` | 1.037 | – | 0.010 | 0.010 |
| `["evaluate", "Linear0 d=50 n=4096"]` | 0.893 | ❌ | 0.057 | 0.051 |
| `["gen_samples", "DigitalNetB2 d=10 n=1024"]` | 1.061 | ✅ | 0.041 | 0.043 |
| `["gen_samples", "DigitalNetB2 d=10 n=16384"]` | 1.000 | – | 1.452 | 1.453 |
| `["gen_samples", "DigitalNetB2 d=10 n=256"]` | 0.791 | ❌ | 0.025 | 0.020 |
| `["gen_samples", "DigitalNetB2 d=10 n=4096"]` | 0.645 | ❌ | 0.230 | 0.148 |
| `["gen_samples", "DigitalNetB2 d=3 n=1024"]` | 1.094 | ✅ | 0.017 | 0.019 |
| `["gen_samples", "DigitalNetB2 d=3 n=16384"]` | 0.899 | ❌ | 0.221 | 0.198 |
| `["gen_samples", "DigitalNetB2 d=3 n=256"]` | 0.889 | ❌ | 0.008 | 0.007 |
| `["gen_samples", "DigitalNetB2 d=3 n=4096"]` | 1.202 | ✅ | 0.049 | 0.058 |
| `["gen_samples", "Halton d=10 n=1024"]` | 1.000 | – | 1.827 | 1.826 |
| `["gen_samples", "Halton d=10 n=16384"]` | 1.000 | – | 29.897 | 29.892 |
| `["gen_samples", "Halton d=10 n=256"]` | 0.999 | – | 0.458 | 0.458 |
| `["gen_samples", "Halton d=10 n=4096"]` | 0.999 | – | 7.337 | 7.328 |
| `["gen_samples", "Halton d=3 n=1024"]` | 1.002 | – | 0.557 | 0.558 |
| `["gen_samples", "Halton d=3 n=16384"]` | 0.998 | – | 9.088 | 9.068 |
| `["gen_samples", "Halton d=3 n=256"]` | 0.983 | – | 0.140 | 0.137 |
| `["gen_samples", "Halton d=3 n=4096"]` | 1.001 | – | 2.244 | 2.246 |
| `["gen_samples", "IIDStdUniform d=10 n=1024"]` | 1.238 | ✅ | 0.008 | 0.010 |
| `["gen_samples", "IIDStdUniform d=10 n=16384"]` | 1.000 | – | 0.559 | 0.559 |
| `["gen_samples", "IIDStdUniform d=10 n=256"]` | 1.286 | ✅ | 0.003 | 0.003 |
| `["gen_samples", "IIDStdUniform d=10 n=4096"]` | 1.096 | ✅ | 0.029 | 0.032 |
| `["gen_samples", "IIDStdUniform d=3 n=1024"]` | 1.677 | ✅ | 0.003 | 0.005 |
| `["gen_samples", "IIDStdUniform d=3 n=16384"]` | 1.118 | ✅ | 0.034 | 0.038 |
| `["gen_samples", "IIDStdUniform d=3 n=256"]` | 2.496 | ✅ | 0.001 | 0.003 |
| `["gen_samples", "IIDStdUniform d=3 n=4096"]` | 1.036 | – | 0.012 | 0.012 |
| `["gen_samples", "Kronecker d=10 n=1024"]` | 1.003 | – | 0.073 | 0.074 |
| `["gen_samples", "Kronecker d=10 n=16384"]` | 1.003 | – | 1.843 | 1.849 |
| `["gen_samples", "Kronecker d=10 n=256"]` | 1.060 | ✅ | 0.018 | 0.019 |
| `["gen_samples", "Kronecker d=10 n=4096"]` | 1.000 | – | 0.327 | 0.327 |
| `["gen_samples", "Kronecker d=3 n=1024"]` | 1.081 | ✅ | 0.022 | 0.024 |
| `["gen_samples", "Kronecker d=3 n=16384"]` | 0.998 | – | 0.406 | 0.406 |
| `["gen_samples", "Kronecker d=3 n=256"]` | 1.043 | – | 0.006 | 0.006 |
| `["gen_samples", "Kronecker d=3 n=4096"]` | 1.002 | – | 0.095 | 0.095 |
| `["gen_samples", "Lattice d=10 n=1024"]` | 1.003 | – | 0.176 | 0.176 |
| `["gen_samples", "Lattice d=10 n=16384"]` | 1.006 | – | 4.254 | 4.281 |
| `["gen_samples", "Lattice d=10 n=256"]` | 1.030 | – | 0.046 | 0.048 |
| `["gen_samples", "Lattice d=10 n=4096"]` | 0.871 | ❌ | 0.969 | 0.844 |
| `["gen_samples", "Lattice d=3 n=1024"]` | 1.088 | ✅ | 0.050 | 0.054 |
| `["gen_samples", "Lattice d=3 n=16384"]` | 0.984 | – | 1.194 | 1.175 |
| `["gen_samples", "Lattice d=3 n=256"]` | 0.998 | – | 0.014 | 0.014 |
| `["gen_samples", "Lattice d=3 n=4096"]` | 0.995 | – | 0.200 | 0.199 |
| `["integrate", "CubMCCLT AsianOption"]` | 1.048 | – | 3.568 | 3.738 |
| `["integrate", "CubMCCLT EuropeanOption"]` | 1.036 | – | 7.139 | 7.395 |
| `["integrate", "CubMCCLT Keister"]` | 0.896 | ❌ | 14.049 | 12.588 |
| `["integrate", "CubQMCLatticeG EuropeanOption"]` | 1.020 | – | 2.025 | 2.066 |
| `["integrate", "CubQMCLatticeG Keister"]` | 1.015 | – | 0.415 | 0.421 |
| `["integrate", "CubQMCNetG AsianOption"]` | 0.952 | – | 1.422 | 1.354 |
| `["integrate", "CubQMCNetG EuropeanOption"]` | 1.024 | – | 1.298 | 1.328 |
| `["integrate", "CubQMCNetG Keister"]` | 0.996 | – | 0.278 | 0.277 |
| `["integrate", "CubQMCNetGRep AsianOption"]` | 1.042 | – | 21.325 | 22.223 |
| `["integrate", "CubQMCNetGRep EuropeanOption"]` | 1.239 | ✅ | 21.453 | 26.571 |
| `["integrate", "CubQMCNetGRep Keister"]` | 0.996 | – | 3.383 | 3.370 |
| `["transform", "Gaussian d=10 n=1024"]` | 0.993 | – | 0.142 | 0.140 |
| `["transform", "Gaussian d=10 n=16384"]` | 0.987 | – | 2.648 | 2.614 |
| `["transform", "Gaussian d=10 n=256"]` | 0.960 | – | 0.033 | 0.032 |
| `["transform", "Gaussian d=10 n=4096"]` | 0.988 | – | 0.658 | 0.651 |
| `["transform", "Gaussian d=3 n=1024"]` | 0.963 | – | 0.040 | 0.039 |
| `["transform", "Gaussian d=3 n=16384"]` | 0.986 | – | 0.787 | 0.776 |
| `["transform", "Gaussian d=3 n=256"]` | 0.696 | ❌ | 0.014 | 0.010 |
| `["transform", "Gaussian d=3 n=4096"]` | 1.007 | – | 0.172 | 0.174 |
| `["transform", "Gaussian(dense) d=200 n=1024"]` | 1.005 | – | 4.364 | 4.387 |
| `["transform", "Gaussian(dense) d=200 n=4096"]` | 0.979 | – | 17.914 | 17.529 |
| `["transform", "Gaussian(dense) d=50 n=1024"]` | 0.883 | ❌ | 1.044 | 0.922 |
| `["transform", "Gaussian(dense) d=50 n=4096"]` | 0.997 | – | 3.614 | 3.602 |
| `["transform", "Gaussian(diag) d=200 n=1024"]` | 0.993 | – | 3.313 | 3.289 |
| `["transform", "Gaussian(diag) d=200 n=4096"]` | 0.989 | – | 13.293 | 13.147 |
| `["transform", "Gaussian(diag) d=50 n=1024"]` | 0.915 | ❌ | 0.885 | 0.810 |
| `["transform", "Gaussian(diag) d=50 n=4096"]` | 0.987 | – | 3.312 | 3.270 |
| `["transform", "JohnsonsSU d=10 n=1024"]` | 0.985 | – | 0.221 | 0.218 |
| `["transform", "JohnsonsSU d=10 n=16384"]` | 0.996 | – | 3.869 | 3.853 |
| `["transform", "JohnsonsSU d=10 n=256"]` | 1.025 | – | 0.053 | 0.054 |
| `["transform", "JohnsonsSU d=10 n=4096"]` | 0.998 | – | 0.959 | 0.957 |
| `["transform", "StudentT d=10 n=1024"]` | 1.002 | – | 0.045 | 0.045 |
| `["transform", "StudentT d=10 n=16384"]` | 0.994 | – | 0.705 | 0.701 |
| `["transform", "StudentT d=10 n=256"]` | 1.017 | – | 0.011 | 0.012 |
| `["transform", "StudentT d=10 n=4096"]` | 0.992 | – | 0.178 | 0.176 |
