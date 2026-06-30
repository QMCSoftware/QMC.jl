# Benchmark: `local` vs `cbe8b05acd18ac737a8780b7be6e9cffd35e5559`

| | local (`local`) | reference (`cbe8b05acd18ac737a8780b7be6e9cffd35e5559`) |
|---|---|---|
| commit | non gitrepo | non gitrepo |
| date | 2026-06-30T01:46:18.506 | 2026-06-30T01:48:01.526 |

**`ratio = reference time ÷ local time`**  
ratio `< 1` → local is **slower** ❌  |  ratio `> 1` → local is **faster** ✅

## Aggregate Summary

| metric | ratio | local total | reference total |
|:-------|------:|------------:|----------------:|
| matched benchmarks | 111 | — | — |
| weighted time ratio | 1.006 | 167.409 ms | 168.387 ms |
| weighted memory ratio | 1.000 | 121290.9 KiB | 121296.2 KiB |

| benchmark | ratio | verdict | local (ms) | reference (ms) |
|:----------|------:|:-------:|----------:|---------------:|
| `["evaluate", "BoxIntegral d=10 n=1024"]` | 0.891 | ❌ | 0.010 | 0.009 |
| `["evaluate", "BoxIntegral d=10 n=16384"]` | 0.944 | ❌ | 0.138 | 0.130 |
| `["evaluate", "BoxIntegral d=10 n=256"]` | 0.965 | – | 0.003 | 0.003 |
| `["evaluate", "BoxIntegral d=10 n=4096"]` | 0.824 | ❌ | 0.044 | 0.036 |
| `["evaluate", "BoxIntegral d=200 n=1024"]` | 1.081 | ✅ | 0.047 | 0.051 |
| `["evaluate", "BoxIntegral d=200 n=4096"]` | 0.978 | – | 0.178 | 0.174 |
| `["evaluate", "BoxIntegral d=50 n=1024"]` | 0.893 | ❌ | 0.019 | 0.017 |
| `["evaluate", "BoxIntegral d=50 n=4096"]` | 0.872 | ❌ | 0.081 | 0.071 |
| `["evaluate", "Genz(continuous) d=10 n=1024"]` | 0.988 | – | 0.008 | 0.008 |
| `["evaluate", "Genz(continuous) d=10 n=16384"]` | 0.973 | – | 0.133 | 0.129 |
| `["evaluate", "Genz(continuous) d=10 n=256"]` | 1.046 | – | 0.002 | 0.003 |
| `["evaluate", "Genz(continuous) d=10 n=4096"]` | 0.948 | ❌ | 0.035 | 0.033 |
| `["evaluate", "Genz(gaussian_peak) d=10 n=1024"]` | 1.008 | – | 0.008 | 0.008 |
| `["evaluate", "Genz(gaussian_peak) d=10 n=16384"]` | 0.926 | ❌ | 0.133 | 0.123 |
| `["evaluate", "Genz(gaussian_peak) d=10 n=256"]` | 1.005 | – | 0.003 | 0.003 |
| `["evaluate", "Genz(gaussian_peak) d=10 n=4096"]` | 0.841 | ❌ | 0.040 | 0.034 |
| `["evaluate", "Genz(gaussian_peak) d=200 n=1024"]` | 0.910 | ❌ | 0.056 | 0.051 |
| `["evaluate", "Genz(gaussian_peak) d=200 n=4096"]` | 0.834 | ❌ | 0.202 | 0.169 |
| `["evaluate", "Genz(gaussian_peak) d=50 n=1024"]` | 0.990 | – | 0.018 | 0.017 |
| `["evaluate", "Genz(gaussian_peak) d=50 n=4096"]` | 0.870 | ❌ | 0.096 | 0.083 |
| `["evaluate", "Genz(oscillatory) n=1024"]` | 1.023 | – | 0.009 | 0.009 |
| `["evaluate", "Genz(oscillatory) n=16384"]` | 0.990 | – | 0.230 | 0.228 |
| `["evaluate", "Genz(oscillatory) n=256"]` | 1.017 | – | 0.003 | 0.003 |
| `["evaluate", "Genz(oscillatory) n=4096"]` | 0.930 | ❌ | 0.035 | 0.033 |
| `["evaluate", "Keister n=1024"]` | 1.021 | – | 0.012 | 0.012 |
| `["evaluate", "Keister n=16384"]` | 0.985 | – | 0.193 | 0.190 |
| `["evaluate", "Keister n=256"]` | 0.975 | – | 0.004 | 0.004 |
| `["evaluate", "Keister n=4096"]` | 1.037 | – | 0.046 | 0.048 |
| `["evaluate", "Linear0 d=10 n=1024"]` | 1.316 | ✅ | 0.003 | 0.003 |
| `["evaluate", "Linear0 d=10 n=16384"]` | 1.045 | – | 0.047 | 0.049 |
| `["evaluate", "Linear0 d=10 n=256"]` | 1.740 | ✅ | 0.001 | 0.001 |
| `["evaluate", "Linear0 d=10 n=4096"]` | 1.080 | ✅ | 0.011 | 0.012 |
| `["evaluate", "Linear0 d=200 n=1024"]` | 0.972 | – | 0.043 | 0.042 |
| `["evaluate", "Linear0 d=200 n=4096"]` | 0.972 | – | 0.153 | 0.149 |
| `["evaluate", "Linear0 d=50 n=1024"]` | 1.065 | ✅ | 0.009 | 0.010 |
| `["evaluate", "Linear0 d=50 n=4096"]` | 0.999 | – | 0.049 | 0.049 |
| `["gen_samples", "DigitalNetB2 d=10 n=1024"]` | 0.993 | – | 0.042 | 0.041 |
| `["gen_samples", "DigitalNetB2 d=10 n=16384"]` | 1.024 | – | 1.489 | 1.525 |
| `["gen_samples", "DigitalNetB2 d=10 n=256"]` | 0.958 | – | 0.020 | 0.019 |
| `["gen_samples", "DigitalNetB2 d=10 n=4096"]` | 0.589 | ❌ | 0.281 | 0.165 |
| `["gen_samples", "DigitalNetB2 d=3 n=1024"]` | 0.927 | ❌ | 0.020 | 0.019 |
| `["gen_samples", "DigitalNetB2 d=3 n=16384"]` | 0.556 | ❌ | 0.409 | 0.228 |
| `["gen_samples", "DigitalNetB2 d=3 n=256"]` | 0.958 | – | 0.007 | 0.007 |
| `["gen_samples", "DigitalNetB2 d=3 n=4096"]` | 1.008 | – | 0.059 | 0.059 |
| `["gen_samples", "Halton d=10 n=1024"]` | 0.999 | – | 0.721 | 0.720 |
| `["gen_samples", "Halton d=10 n=16384"]` | 1.004 | – | 12.519 | 12.563 |
| `["gen_samples", "Halton d=10 n=256"]` | 1.001 | – | 0.179 | 0.179 |
| `["gen_samples", "Halton d=10 n=4096"]` | 1.008 | – | 2.941 | 2.963 |
| `["gen_samples", "Halton d=3 n=1024"]` | 1.002 | – | 0.234 | 0.234 |
| `["gen_samples", "Halton d=3 n=16384"]` | 0.999 | – | 3.995 | 3.991 |
| `["gen_samples", "Halton d=3 n=256"]` | 0.980 | – | 0.058 | 0.057 |
| `["gen_samples", "Halton d=3 n=4096"]` | 1.002 | – | 0.963 | 0.965 |
| `["gen_samples", "IIDStdUniform d=10 n=1024"]` | 0.953 | – | 0.009 | 0.009 |
| `["gen_samples", "IIDStdUniform d=10 n=16384"]` | 1.052 | ✅ | 0.565 | 0.594 |
| `["gen_samples", "IIDStdUniform d=10 n=256"]` | 0.965 | – | 0.003 | 0.002 |
| `["gen_samples", "IIDStdUniform d=10 n=4096"]` | 0.935 | ❌ | 0.028 | 0.026 |
| `["gen_samples", "IIDStdUniform d=3 n=1024"]` | 1.001 | – | 0.003 | 0.003 |
| `["gen_samples", "IIDStdUniform d=3 n=16384"]` | 1.045 | – | 0.031 | 0.033 |
| `["gen_samples", "IIDStdUniform d=3 n=256"]` | 0.984 | – | 0.001 | 0.001 |
| `["gen_samples", "IIDStdUniform d=3 n=4096"]` | 0.813 | ❌ | 0.013 | 0.010 |
| `["gen_samples", "Kronecker d=10 n=1024"]` | 1.011 | – | 0.025 | 0.025 |
| `["gen_samples", "Kronecker d=10 n=16384"]` | 1.009 | – | 0.840 | 0.848 |
| `["gen_samples", "Kronecker d=10 n=256"]` | 0.951 | – | 0.006 | 0.006 |
| `["gen_samples", "Kronecker d=10 n=4096"]` | 0.931 | ❌ | 0.097 | 0.090 |
| `["gen_samples", "Kronecker d=3 n=1024"]` | 1.039 | – | 0.007 | 0.007 |
| `["gen_samples", "Kronecker d=3 n=16384"]` | 0.932 | ❌ | 0.115 | 0.107 |
| `["gen_samples", "Kronecker d=3 n=256"]` | 0.714 | ❌ | 0.003 | 0.002 |
| `["gen_samples", "Kronecker d=3 n=4096"]` | 1.055 | ✅ | 0.028 | 0.029 |
| `["gen_samples", "Lattice d=10 n=1024"]` | 0.942 | ❌ | 0.071 | 0.067 |
| `["gen_samples", "Lattice d=10 n=16384"]` | 0.997 | – | 2.530 | 2.522 |
| `["gen_samples", "Lattice d=10 n=256"]` | 0.878 | ❌ | 0.024 | 0.021 |
| `["gen_samples", "Lattice d=10 n=4096"]` | 0.839 | ❌ | 0.610 | 0.512 |
| `["gen_samples", "Lattice d=3 n=1024"]` | 0.900 | ❌ | 0.029 | 0.026 |
| `["gen_samples", "Lattice d=3 n=16384"]` | 1.033 | – | 0.792 | 0.818 |
| `["gen_samples", "Lattice d=3 n=256"]` | 0.995 | – | 0.008 | 0.008 |
| `["gen_samples", "Lattice d=3 n=4096"]` | 0.981 | – | 0.100 | 0.098 |
| `["integrate", "CubMCCLT AsianOption"]` | 0.990 | – | 3.771 | 3.732 |
| `["integrate", "CubMCCLT EuropeanOption"]` | 0.893 | ❌ | 7.592 | 6.783 |
| `["integrate", "CubMCCLT Keister"]` | 1.008 | – | 13.621 | 13.724 |
| `["integrate", "CubQMCLatticeG EuropeanOption"]` | 1.027 | – | 1.513 | 1.554 |
| `["integrate", "CubQMCLatticeG Keister"]` | 1.003 | – | 0.342 | 0.344 |
| `["integrate", "CubQMCNetG AsianOption"]` | 1.049 | – | 1.376 | 1.443 |
| `["integrate", "CubQMCNetG EuropeanOption"]` | 1.032 | – | 1.405 | 1.451 |
| `["integrate", "CubQMCNetG Keister"]` | 1.008 | – | 0.274 | 0.277 |
| `["integrate", "CubQMCNetGRep AsianOption"]` | 1.012 | – | 21.105 | 21.352 |
| `["integrate", "CubQMCNetGRep EuropeanOption"]` | 0.991 | – | 21.290 | 21.090 |
| `["integrate", "CubQMCNetGRep Keister"]` | 1.005 | – | 3.251 | 3.267 |
| `["transform", "Gaussian d=10 n=1024"]` | 1.012 | – | 0.139 | 0.141 |
| `["transform", "Gaussian d=10 n=16384"]` | 1.014 | – | 2.652 | 2.689 |
| `["transform", "Gaussian d=10 n=256"]` | 1.004 | – | 0.031 | 0.031 |
| `["transform", "Gaussian d=10 n=4096"]` | 1.026 | – | 0.641 | 0.658 |
| `["transform", "Gaussian d=3 n=1024"]` | 1.005 | – | 0.037 | 0.037 |
| `["transform", "Gaussian d=3 n=16384"]` | 1.012 | – | 0.780 | 0.789 |
| `["transform", "Gaussian d=3 n=256"]` | 1.037 | – | 0.010 | 0.010 |
| `["transform", "Gaussian d=3 n=4096"]` | 0.699 | ❌ | 0.249 | 0.174 |
| `["transform", "Gaussian(dense) d=200 n=1024"]` | 1.175 | ✅ | 4.496 | 5.283 |
| `["transform", "Gaussian(dense) d=200 n=4096"]` | 0.991 | – | 18.190 | 18.023 |
| `["transform", "Gaussian(dense) d=50 n=1024"]` | 1.003 | – | 0.987 | 0.989 |
| `["transform", "Gaussian(dense) d=50 n=4096"]` | 1.215 | ✅ | 3.681 | 4.471 |
| `["transform", "Gaussian(diag) d=200 n=1024"]` | 1.011 | – | 3.273 | 3.311 |
| `["transform", "Gaussian(diag) d=200 n=4096"]` | 1.022 | – | 14.048 | 14.361 |
| `["transform", "Gaussian(diag) d=50 n=1024"]` | 1.008 | – | 0.813 | 0.819 |
| `["transform", "Gaussian(diag) d=50 n=4096"]` | 1.055 | ✅ | 3.278 | 3.459 |
| `["transform", "JohnsonsSU d=10 n=1024"]` | 1.020 | – | 0.218 | 0.223 |
| `["transform", "JohnsonsSU d=10 n=16384"]` | 0.980 | – | 3.969 | 3.890 |
| `["transform", "JohnsonsSU d=10 n=256"]` | 0.992 | – | 0.052 | 0.051 |
| `["transform", "JohnsonsSU d=10 n=4096"]` | 1.010 | – | 0.951 | 0.960 |
| `["transform", "StudentT d=10 n=1024"]` | 1.022 | – | 0.044 | 0.045 |
| `["transform", "StudentT d=10 n=16384"]` | 1.004 | – | 1.168 | 1.173 |
| `["transform", "StudentT d=10 n=256"]` | 0.973 | – | 0.012 | 0.012 |
| `["transform", "StudentT d=10 n=4096"]` | 1.009 | – | 0.177 | 0.178 |
