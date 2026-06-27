# Benchmark: `local` vs `8508c5233e77de0494c11eac19fff89283dc5c70`

| | local (`local`) | reference (`8508c5233e77de0494c11eac19fff89283dc5c70`) |
|---|---|---|
| commit | non gitrepo | non gitrepo |
| date | 2026-06-27T00:00:16.740 | 2026-06-27T00:01:54.200 |

**`ratio = reference time ÷ local time`**  
ratio `< 1` → local is **slower** ❌  |  ratio `> 1` → local is **faster** ✅

## Aggregate Summary

| metric | ratio | local total | reference total |
|:-------|------:|------------:|----------------:|
| matched benchmarks | 111 | — | — |
| weighted time ratio | 1.048 | 199.217 ms | 208.750 ms |
| weighted memory ratio | 1.000 | 173029.9 KiB | 173035.1 KiB |

| benchmark | ratio | verdict | local (ms) | reference (ms) |
|:----------|------:|:-------:|----------:|---------------:|
| `["evaluate", "BoxIntegral d=10 n=1024"]` | 1.001 | – | 0.009 | 0.009 |
| `["evaluate", "BoxIntegral d=10 n=16384"]` | 1.036 | – | 0.127 | 0.132 |
| `["evaluate", "BoxIntegral d=10 n=256"]` | 0.918 | ❌ | 0.003 | 0.003 |
| `["evaluate", "BoxIntegral d=10 n=4096"]` | 0.919 | ❌ | 0.042 | 0.039 |
| `["evaluate", "BoxIntegral d=200 n=1024"]` | 1.152 | ✅ | 0.041 | 0.048 |
| `["evaluate", "BoxIntegral d=200 n=4096"]` | 1.006 | – | 0.170 | 0.171 |
| `["evaluate", "BoxIntegral d=50 n=1024"]` | 0.991 | – | 0.017 | 0.017 |
| `["evaluate", "BoxIntegral d=50 n=4096"]` | 1.243 | ✅ | 0.064 | 0.079 |
| `["evaluate", "Genz(continuous) d=10 n=1024"]` | 0.918 | ❌ | 0.009 | 0.008 |
| `["evaluate", "Genz(continuous) d=10 n=16384"]` | 1.084 | ✅ | 0.119 | 0.129 |
| `["evaluate", "Genz(continuous) d=10 n=256"]` | 0.709 | ❌ | 0.004 | 0.003 |
| `["evaluate", "Genz(continuous) d=10 n=4096"]` | 0.953 | – | 0.039 | 0.038 |
| `["evaluate", "Genz(gaussian_peak) d=10 n=1024"]` | 1.016 | – | 0.008 | 0.009 |
| `["evaluate", "Genz(gaussian_peak) d=10 n=16384"]` | 1.000 | – | 0.133 | 0.133 |
| `["evaluate", "Genz(gaussian_peak) d=10 n=256"]` | 0.997 | – | 0.003 | 0.003 |
| `["evaluate", "Genz(gaussian_peak) d=10 n=4096"]` | 1.026 | – | 0.037 | 0.038 |
| `["evaluate", "Genz(gaussian_peak) d=200 n=1024"]` | 0.805 | ❌ | 0.059 | 0.048 |
| `["evaluate", "Genz(gaussian_peak) d=200 n=4096"]` | 1.003 | – | 0.169 | 0.170 |
| `["evaluate", "Genz(gaussian_peak) d=50 n=1024"]` | 1.065 | ✅ | 0.017 | 0.018 |
| `["evaluate", "Genz(gaussian_peak) d=50 n=4096"]` | 1.092 | ✅ | 0.078 | 0.085 |
| `["evaluate", "Genz(oscillatory) n=1024"]` | 0.948 | ❌ | 0.010 | 0.009 |
| `["evaluate", "Genz(oscillatory) n=16384"]` | 1.033 | – | 0.224 | 0.232 |
| `["evaluate", "Genz(oscillatory) n=256"]` | 0.926 | ❌ | 0.003 | 0.003 |
| `["evaluate", "Genz(oscillatory) n=4096"]` | 0.924 | ❌ | 0.041 | 0.038 |
| `["evaluate", "Keister n=1024"]` | 0.941 | ❌ | 0.013 | 0.012 |
| `["evaluate", "Keister n=16384"]` | 0.923 | ❌ | 0.210 | 0.194 |
| `["evaluate", "Keister n=256"]` | 0.786 | ❌ | 0.005 | 0.004 |
| `["evaluate", "Keister n=4096"]` | 0.886 | ❌ | 0.055 | 0.049 |
| `["evaluate", "Linear0 d=10 n=1024"]` | 1.069 | ✅ | 0.003 | 0.003 |
| `["evaluate", "Linear0 d=10 n=16384"]` | 0.872 | ❌ | 0.054 | 0.047 |
| `["evaluate", "Linear0 d=10 n=256"]` | 0.916 | ❌ | 0.001 | 0.001 |
| `["evaluate", "Linear0 d=10 n=4096"]` | 1.150 | ✅ | 0.010 | 0.012 |
| `["evaluate", "Linear0 d=200 n=1024"]` | 0.781 | ❌ | 0.045 | 0.035 |
| `["evaluate", "Linear0 d=200 n=4096"]` | 0.996 | – | 0.145 | 0.144 |
| `["evaluate", "Linear0 d=50 n=1024"]` | 0.837 | ❌ | 0.012 | 0.010 |
| `["evaluate", "Linear0 d=50 n=4096"]` | 1.050 | – | 0.045 | 0.047 |
| `["gen_samples", "DigitalNetB2 d=10 n=1024"]` | 1.052 | ✅ | 0.038 | 0.040 |
| `["gen_samples", "DigitalNetB2 d=10 n=16384"]` | 1.004 | – | 1.443 | 1.449 |
| `["gen_samples", "DigitalNetB2 d=10 n=256"]` | 1.053 | ✅ | 0.018 | 0.019 |
| `["gen_samples", "DigitalNetB2 d=10 n=4096"]` | 1.429 | ✅ | 0.142 | 0.203 |
| `["gen_samples", "DigitalNetB2 d=3 n=1024"]` | 1.047 | – | 0.015 | 0.016 |
| `["gen_samples", "DigitalNetB2 d=3 n=16384"]` | 0.463 | ❌ | 0.420 | 0.195 |
| `["gen_samples", "DigitalNetB2 d=3 n=256"]` | 0.982 | – | 0.007 | 0.006 |
| `["gen_samples", "DigitalNetB2 d=3 n=4096"]` | 1.023 | – | 0.048 | 0.049 |
| `["gen_samples", "Halton d=10 n=1024"]` | 1.001 | – | 1.827 | 1.829 |
| `["gen_samples", "Halton d=10 n=16384"]` | 1.000 | – | 29.895 | 29.902 |
| `["gen_samples", "Halton d=10 n=256"]` | 1.003 | – | 0.456 | 0.457 |
| `["gen_samples", "Halton d=10 n=4096"]` | 1.000 | – | 7.323 | 7.324 |
| `["gen_samples", "Halton d=3 n=1024"]` | 1.000 | – | 0.558 | 0.558 |
| `["gen_samples", "Halton d=3 n=16384"]` | 1.000 | – | 9.076 | 9.074 |
| `["gen_samples", "Halton d=3 n=256"]` | 1.011 | – | 0.140 | 0.141 |
| `["gen_samples", "Halton d=3 n=4096"]` | 0.994 | – | 2.256 | 2.243 |
| `["gen_samples", "IIDStdUniform d=10 n=1024"]` | 0.887 | ❌ | 0.010 | 0.009 |
| `["gen_samples", "IIDStdUniform d=10 n=16384"]` | 1.013 | – | 0.565 | 0.572 |
| `["gen_samples", "IIDStdUniform d=10 n=256"]` | 1.112 | ✅ | 0.002 | 0.003 |
| `["gen_samples", "IIDStdUniform d=10 n=4096"]` | 1.033 | – | 0.029 | 0.030 |
| `["gen_samples", "IIDStdUniform d=3 n=1024"]` | 0.855 | ❌ | 0.003 | 0.003 |
| `["gen_samples", "IIDStdUniform d=3 n=16384"]` | 0.927 | ❌ | 0.034 | 0.032 |
| `["gen_samples", "IIDStdUniform d=3 n=256"]` | 1.057 | ✅ | 0.001 | 0.001 |
| `["gen_samples", "IIDStdUniform d=3 n=4096"]` | 1.388 | ✅ | 0.009 | 0.013 |
| `["gen_samples", "Kronecker d=10 n=1024"]` | 1.033 | – | 0.073 | 0.076 |
| `["gen_samples", "Kronecker d=10 n=16384"]` | 0.996 | – | 1.856 | 1.849 |
| `["gen_samples", "Kronecker d=10 n=256"]` | 1.007 | – | 0.018 | 0.018 |
| `["gen_samples", "Kronecker d=10 n=4096"]` | 0.993 | – | 0.329 | 0.327 |
| `["gen_samples", "Kronecker d=3 n=1024"]` | 1.019 | – | 0.021 | 0.022 |
| `["gen_samples", "Kronecker d=3 n=16384"]` | 1.003 | – | 0.407 | 0.408 |
| `["gen_samples", "Kronecker d=3 n=256"]` | 1.031 | – | 0.006 | 0.006 |
| `["gen_samples", "Kronecker d=3 n=4096"]` | 1.013 | – | 0.093 | 0.094 |
| `["gen_samples", "Lattice d=10 n=1024"]` | 1.005 | – | 0.176 | 0.177 |
| `["gen_samples", "Lattice d=10 n=16384"]` | 1.004 | – | 4.252 | 4.271 |
| `["gen_samples", "Lattice d=10 n=256"]` | 1.027 | – | 0.046 | 0.048 |
| `["gen_samples", "Lattice d=10 n=4096"]` | 0.662 | ❌ | 1.064 | 0.704 |
| `["gen_samples", "Lattice d=3 n=1024"]` | 0.997 | – | 0.051 | 0.050 |
| `["gen_samples", "Lattice d=3 n=16384"]` | 0.880 | ❌ | 1.203 | 1.058 |
| `["gen_samples", "Lattice d=3 n=256"]` | 1.004 | – | 0.013 | 0.013 |
| `["gen_samples", "Lattice d=3 n=4096"]` | 1.009 | – | 0.198 | 0.200 |
| `["integrate", "CubMCCLT AsianOption"]` | 1.005 | – | 3.531 | 3.548 |
| `["integrate", "CubMCCLT EuropeanOption"]` | 1.130 | ✅ | 6.549 | 7.402 |
| `["integrate", "CubMCCLT Keister"]` | 1.082 | ✅ | 12.786 | 13.834 |
| `["integrate", "CubQMCLatticeG EuropeanOption"]` | 1.049 | – | 1.990 | 2.088 |
| `["integrate", "CubQMCLatticeG Keister"]` | 0.988 | – | 0.411 | 0.406 |
| `["integrate", "CubQMCNetG AsianOption"]` | 1.077 | ✅ | 1.315 | 1.417 |
| `["integrate", "CubQMCNetG EuropeanOption"]` | 1.077 | ✅ | 1.331 | 1.433 |
| `["integrate", "CubQMCNetG Keister"]` | 0.995 | – | 0.273 | 0.271 |
| `["integrate", "CubQMCNetGRep AsianOption"]` | 1.240 | ✅ | 21.271 | 26.373 |
| `["integrate", "CubQMCNetGRep EuropeanOption"]` | 1.073 | ✅ | 21.181 | 22.721 |
| `["integrate", "CubQMCNetGRep Keister"]` | 0.996 | – | 3.379 | 3.366 |
| `["transform", "Gaussian d=10 n=1024"]` | 0.985 | – | 0.141 | 0.139 |
| `["transform", "Gaussian d=10 n=16384"]` | 1.023 | – | 2.616 | 2.677 |
| `["transform", "Gaussian d=10 n=256"]` | 1.023 | – | 0.031 | 0.031 |
| `["transform", "Gaussian d=10 n=4096"]` | 1.005 | – | 0.678 | 0.681 |
| `["transform", "Gaussian d=3 n=1024"]` | 1.023 | – | 0.037 | 0.038 |
| `["transform", "Gaussian d=3 n=16384"]` | 1.055 | ✅ | 0.782 | 0.825 |
| `["transform", "Gaussian d=3 n=256"]` | 0.991 | – | 0.010 | 0.010 |
| `["transform", "Gaussian d=3 n=4096"]` | 1.007 | – | 0.172 | 0.173 |
| `["transform", "Gaussian(dense) d=200 n=1024"]` | 1.001 | – | 4.370 | 4.372 |
| `["transform", "Gaussian(dense) d=200 n=4096"]` | 1.013 | – | 18.033 | 18.265 |
| `["transform", "Gaussian(dense) d=50 n=1024"]` | 1.057 | ✅ | 0.904 | 0.955 |
| `["transform", "Gaussian(dense) d=50 n=4096"]` | 1.086 | ✅ | 3.589 | 3.897 |
| `["transform", "Gaussian(diag) d=200 n=1024"]` | 0.851 | ❌ | 3.912 | 3.329 |
| `["transform", "Gaussian(diag) d=200 n=4096"]` | 1.047 | – | 13.622 | 14.266 |
| `["transform", "Gaussian(diag) d=50 n=1024"]` | 1.019 | – | 0.810 | 0.826 |
| `["transform", "Gaussian(diag) d=50 n=4096"]` | 1.017 | – | 3.296 | 3.351 |
| `["transform", "JohnsonsSU d=10 n=1024"]` | 0.978 | – | 0.223 | 0.218 |
| `["transform", "JohnsonsSU d=10 n=16384"]` | 1.007 | – | 3.882 | 3.909 |
| `["transform", "JohnsonsSU d=10 n=256"]` | 1.001 | – | 0.052 | 0.052 |
| `["transform", "JohnsonsSU d=10 n=4096"]` | 1.006 | – | 0.957 | 0.963 |
| `["transform", "StudentT d=10 n=1024"]` | 1.002 | – | 0.044 | 0.044 |
| `["transform", "StudentT d=10 n=16384"]` | 1.671 | ✅ | 0.702 | 1.173 |
| `["transform", "StudentT d=10 n=256"]` | 1.011 | – | 0.012 | 0.012 |
| `["transform", "StudentT d=10 n=4096"]` | 1.005 | – | 0.177 | 0.178 |
