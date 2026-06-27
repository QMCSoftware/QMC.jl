# Benchmark: `local` vs `HEAD`

| | local (`local`) | reference (`HEAD`) |
|---|---|---|
| commit | non gitrepo | non gitrepo |
| date | 2026-06-27T09:08:55.793 | 2026-06-27T09:10:49.466 |

**`ratio = reference time ÷ local time`**  
ratio `< 1` → local is **slower** ❌  |  ratio `> 1` → local is **faster** ✅

## Aggregate Summary

| metric | ratio | local total | reference total |
|:-------|------:|------------:|----------------:|
| matched benchmarks | 111 | — | — |
| weighted time ratio | 1.016 | 203.567 ms | 206.784 ms |
| weighted memory ratio | 1.000 | 173037.5 KiB | 173037.5 KiB |

| benchmark | ratio | verdict | local (ms) | reference (ms) |
|:----------|------:|:-------:|----------:|---------------:|
| `["evaluate", "BoxIntegral d=10 n=1024"]` | 1.027 | – | 0.008 | 0.008 |
| `["evaluate", "BoxIntegral d=10 n=16384"]` | 0.985 | – | 0.137 | 0.135 |
| `["evaluate", "BoxIntegral d=10 n=256"]` | 0.993 | – | 0.003 | 0.003 |
| `["evaluate", "BoxIntegral d=10 n=4096"]` | 0.944 | ❌ | 0.036 | 0.034 |
| `["evaluate", "BoxIntegral d=200 n=1024"]` | 0.916 | ❌ | 0.033 | 0.030 |
| `["evaluate", "BoxIntegral d=200 n=4096"]` | 0.986 | – | 0.212 | 0.209 |
| `["evaluate", "BoxIntegral d=50 n=1024"]` | 0.964 | – | 0.012 | 0.012 |
| `["evaluate", "BoxIntegral d=50 n=4096"]` | 0.937 | ❌ | 0.074 | 0.070 |
| `["evaluate", "Genz(continuous) d=10 n=1024"]` | 0.985 | – | 0.007 | 0.007 |
| `["evaluate", "Genz(continuous) d=10 n=16384"]` | 1.039 | – | 0.117 | 0.121 |
| `["evaluate", "Genz(continuous) d=10 n=256"]` | 0.944 | ❌ | 0.003 | 0.003 |
| `["evaluate", "Genz(continuous) d=10 n=4096"]` | 0.978 | – | 0.032 | 0.031 |
| `["evaluate", "Genz(gaussian_peak) d=10 n=1024"]` | 1.029 | – | 0.007 | 0.007 |
| `["evaluate", "Genz(gaussian_peak) d=10 n=16384"]` | 0.990 | – | 0.121 | 0.119 |
| `["evaluate", "Genz(gaussian_peak) d=10 n=256"]` | 0.961 | – | 0.003 | 0.002 |
| `["evaluate", "Genz(gaussian_peak) d=10 n=4096"]` | 0.947 | ❌ | 0.032 | 0.031 |
| `["evaluate", "Genz(gaussian_peak) d=200 n=1024"]` | 1.052 | ✅ | 0.034 | 0.036 |
| `["evaluate", "Genz(gaussian_peak) d=200 n=4096"]` | 0.992 | – | 0.212 | 0.210 |
| `["evaluate", "Genz(gaussian_peak) d=50 n=1024"]` | 1.007 | – | 0.012 | 0.013 |
| `["evaluate", "Genz(gaussian_peak) d=50 n=4096"]` | 0.942 | ❌ | 0.074 | 0.070 |
| `["evaluate", "Genz(oscillatory) n=1024"]` | 1.014 | – | 0.008 | 0.008 |
| `["evaluate", "Genz(oscillatory) n=16384"]` | 1.017 | – | 0.114 | 0.116 |
| `["evaluate", "Genz(oscillatory) n=256"]` | 0.974 | – | 0.003 | 0.003 |
| `["evaluate", "Genz(oscillatory) n=4096"]` | 0.907 | ❌ | 0.034 | 0.031 |
| `["evaluate", "Keister n=1024"]` | 1.006 | – | 0.011 | 0.011 |
| `["evaluate", "Keister n=16384"]` | 1.187 | ✅ | 0.159 | 0.188 |
| `["evaluate", "Keister n=256"]` | 0.992 | – | 0.004 | 0.004 |
| `["evaluate", "Keister n=4096"]` | 0.922 | ❌ | 0.049 | 0.045 |
| `["evaluate", "Linear0 d=10 n=1024"]` | 0.981 | – | 0.002 | 0.002 |
| `["evaluate", "Linear0 d=10 n=16384"]` | 1.090 | ✅ | 0.048 | 0.053 |
| `["evaluate", "Linear0 d=10 n=256"]` | 1.032 | – | 0.001 | 0.001 |
| `["evaluate", "Linear0 d=10 n=4096"]` | 0.883 | ❌ | 0.011 | 0.009 |
| `["evaluate", "Linear0 d=200 n=1024"]` | 1.102 | ✅ | 0.026 | 0.029 |
| `["evaluate", "Linear0 d=200 n=4096"]` | 0.995 | – | 0.187 | 0.186 |
| `["evaluate", "Linear0 d=50 n=1024"]` | 1.016 | – | 0.007 | 0.007 |
| `["evaluate", "Linear0 d=50 n=4096"]` | 0.983 | – | 0.050 | 0.049 |
| `["gen_samples", "DigitalNetB2 d=10 n=1024"]` | 1.026 | – | 0.040 | 0.041 |
| `["gen_samples", "DigitalNetB2 d=10 n=16384"]` | 0.996 | – | 1.509 | 1.503 |
| `["gen_samples", "DigitalNetB2 d=10 n=256"]` | 0.902 | ❌ | 0.020 | 0.018 |
| `["gen_samples", "DigitalNetB2 d=10 n=4096"]` | 0.678 | ❌ | 0.373 | 0.253 |
| `["gen_samples", "DigitalNetB2 d=3 n=1024"]` | 0.950 | – | 0.017 | 0.017 |
| `["gen_samples", "DigitalNetB2 d=3 n=16384"]` | 1.000 | – | 0.470 | 0.470 |
| `["gen_samples", "DigitalNetB2 d=3 n=256"]` | 1.002 | – | 0.007 | 0.007 |
| `["gen_samples", "DigitalNetB2 d=3 n=4096"]` | 0.966 | – | 0.050 | 0.048 |
| `["gen_samples", "Halton d=10 n=1024"]` | 0.997 | – | 1.456 | 1.452 |
| `["gen_samples", "Halton d=10 n=16384"]` | 0.999 | – | 23.636 | 23.623 |
| `["gen_samples", "Halton d=10 n=256"]` | 1.010 | – | 0.394 | 0.397 |
| `["gen_samples", "Halton d=10 n=4096"]` | 0.996 | – | 5.710 | 5.690 |
| `["gen_samples", "Halton d=3 n=1024"]` | 1.007 | – | 0.458 | 0.461 |
| `["gen_samples", "Halton d=3 n=16384"]` | 0.986 | – | 8.089 | 7.979 |
| `["gen_samples", "Halton d=3 n=256"]` | 0.999 | – | 0.110 | 0.110 |
| `["gen_samples", "Halton d=3 n=4096"]` | 1.000 | – | 1.912 | 1.912 |
| `["gen_samples", "IIDStdUniform d=10 n=1024"]` | 1.185 | ✅ | 0.010 | 0.011 |
| `["gen_samples", "IIDStdUniform d=10 n=16384"]` | 1.055 | ✅ | 0.591 | 0.623 |
| `["gen_samples", "IIDStdUniform d=10 n=256"]` | 0.902 | ❌ | 0.003 | 0.003 |
| `["gen_samples", "IIDStdUniform d=10 n=4096"]` | 0.398 | ❌ | 0.065 | 0.026 |
| `["gen_samples", "IIDStdUniform d=3 n=1024"]` | 0.887 | ❌ | 0.004 | 0.003 |
| `["gen_samples", "IIDStdUniform d=3 n=16384"]` | 1.308 | ✅ | 0.031 | 0.041 |
| `["gen_samples", "IIDStdUniform d=3 n=256"]` | 1.007 | – | 0.001 | 0.001 |
| `["gen_samples", "IIDStdUniform d=3 n=4096"]` | 1.059 | ✅ | 0.010 | 0.011 |
| `["gen_samples", "Kronecker d=10 n=1024"]` | 0.992 | – | 0.076 | 0.075 |
| `["gen_samples", "Kronecker d=10 n=16384"]` | 0.986 | – | 1.930 | 1.902 |
| `["gen_samples", "Kronecker d=10 n=256"]` | 0.973 | – | 0.019 | 0.018 |
| `["gen_samples", "Kronecker d=10 n=4096"]` | 0.803 | ❌ | 0.417 | 0.335 |
| `["gen_samples", "Kronecker d=3 n=1024"]` | 0.956 | – | 0.022 | 0.021 |
| `["gen_samples", "Kronecker d=3 n=16384"]` | 0.957 | – | 0.439 | 0.420 |
| `["gen_samples", "Kronecker d=3 n=256"]` | 0.987 | – | 0.006 | 0.006 |
| `["gen_samples", "Kronecker d=3 n=4096"]` | 0.993 | – | 0.099 | 0.099 |
| `["gen_samples", "Lattice d=10 n=1024"]` | 0.991 | – | 0.199 | 0.198 |
| `["gen_samples", "Lattice d=10 n=16384"]` | 1.003 | – | 4.656 | 4.667 |
| `["gen_samples", "Lattice d=10 n=256"]` | 0.930 | ❌ | 0.054 | 0.050 |
| `["gen_samples", "Lattice d=10 n=4096"]` | 1.024 | – | 1.167 | 1.194 |
| `["gen_samples", "Lattice d=3 n=1024"]` | 1.011 | – | 0.056 | 0.057 |
| `["gen_samples", "Lattice d=3 n=16384"]` | 1.006 | – | 1.353 | 1.361 |
| `["gen_samples", "Lattice d=3 n=256"]` | 0.966 | – | 0.016 | 0.015 |
| `["gen_samples", "Lattice d=3 n=4096"]` | 0.997 | – | 0.225 | 0.224 |
| `["integrate", "CubMCCLT AsianOption"]` | 0.980 | – | 3.648 | 3.575 |
| `["integrate", "CubMCCLT EuropeanOption"]` | 0.993 | – | 7.071 | 7.022 |
| `["integrate", "CubMCCLT Keister"]` | 0.994 | – | 14.161 | 14.071 |
| `["integrate", "CubQMCLatticeG EuropeanOption"]` | 1.018 | – | 2.159 | 2.197 |
| `["integrate", "CubQMCLatticeG Keister"]` | 1.021 | – | 0.423 | 0.432 |
| `["integrate", "CubQMCNetG AsianOption"]` | 0.977 | – | 1.367 | 1.335 |
| `["integrate", "CubQMCNetG EuropeanOption"]` | 0.990 | – | 1.352 | 1.339 |
| `["integrate", "CubQMCNetG Keister"]` | 0.987 | – | 0.280 | 0.276 |
| `["integrate", "CubQMCNetGRep AsianOption"]` | 1.045 | – | 25.493 | 26.629 |
| `["integrate", "CubQMCNetGRep EuropeanOption"]` | 1.029 | – | 25.195 | 25.922 |
| `["integrate", "CubQMCNetGRep Keister"]` | 0.985 | – | 3.444 | 3.391 |
| `["transform", "Gaussian d=10 n=1024"]` | 1.037 | – | 0.124 | 0.129 |
| `["transform", "Gaussian d=10 n=16384"]` | 1.002 | – | 2.749 | 2.754 |
| `["transform", "Gaussian d=10 n=256"]` | 0.997 | – | 0.030 | 0.030 |
| `["transform", "Gaussian d=10 n=4096"]` | 0.962 | – | 0.612 | 0.589 |
| `["transform", "Gaussian d=3 n=1024"]` | 0.999 | – | 0.036 | 0.036 |
| `["transform", "Gaussian d=3 n=16384"]` | 0.972 | – | 0.744 | 0.723 |
| `["transform", "Gaussian d=3 n=256"]` | 1.004 | – | 0.009 | 0.009 |
| `["transform", "Gaussian d=3 n=4096"]` | 1.008 | – | 0.148 | 0.149 |
| `["transform", "Gaussian(dense) d=200 n=1024"]` | 1.231 | ✅ | 4.589 | 5.648 |
| `["transform", "Gaussian(dense) d=200 n=4096"]` | 1.018 | – | 18.838 | 19.168 |
| `["transform", "Gaussian(dense) d=50 n=1024"]` | 1.544 | ✅ | 0.918 | 1.417 |
| `["transform", "Gaussian(dense) d=50 n=4096"]` | 1.021 | – | 3.775 | 3.854 |
| `["transform", "Gaussian(diag) d=200 n=1024"]` | 1.002 | – | 3.428 | 3.433 |
| `["transform", "Gaussian(diag) d=200 n=4096"]` | 1.003 | – | 14.635 | 14.677 |
| `["transform", "Gaussian(diag) d=50 n=1024"]` | 1.019 | – | 0.775 | 0.789 |
| `["transform", "Gaussian(diag) d=50 n=4096"]` | 1.004 | – | 3.451 | 3.464 |
| `["transform", "JohnsonsSU d=10 n=1024"]` | 0.973 | – | 0.200 | 0.195 |
| `["transform", "JohnsonsSU d=10 n=16384"]` | 1.003 | – | 3.839 | 3.850 |
| `["transform", "JohnsonsSU d=10 n=256"]` | 1.010 | – | 0.049 | 0.049 |
| `["transform", "JohnsonsSU d=10 n=4096"]` | 0.948 | ❌ | 0.915 | 0.868 |
| `["transform", "StudentT d=10 n=1024"]` | 1.003 | – | 0.050 | 0.050 |
| `["transform", "StudentT d=10 n=16384"]` | 0.998 | – | 1.271 | 1.268 |
| `["transform", "StudentT d=10 n=256"]` | 0.975 | – | 0.013 | 0.013 |
| `["transform", "StudentT d=10 n=4096"]` | 0.999 | – | 0.199 | 0.199 |
