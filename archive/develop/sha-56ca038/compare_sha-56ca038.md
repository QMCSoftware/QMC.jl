# Benchmark: `local` vs `821815d4bff579a9e0cb1ee5369a18701190a73c`

| | local (`local`) | reference (`821815d4bff579a9e0cb1ee5369a18701190a73c`) |
|---|---|---|
| commit | non gitrepo | non gitrepo |
| date | 2026-06-29T13:19:21.765 | 2026-06-29T13:21:16.944 |

**`ratio = reference time ÷ local time`**  
ratio `< 1` → local is **slower** ❌  |  ratio `> 1` → local is **faster** ✅

## Aggregate Summary

| metric | ratio | local total | reference total |
|:-------|------:|------------:|----------------:|
| matched benchmarks | 111 | — | — |
| weighted time ratio | 1.161 | 176.206 ms | 204.583 ms |
| weighted memory ratio | 1.427 | 121290.9 KiB | 173037.5 KiB |

| benchmark | ratio | verdict | local (ms) | reference (ms) |
|:----------|------:|:-------:|----------:|---------------:|
| `["evaluate", "BoxIntegral d=10 n=1024"]` | 1.042 | – | 0.008 | 0.009 |
| `["evaluate", "BoxIntegral d=10 n=16384"]` | 1.029 | – | 0.135 | 0.139 |
| `["evaluate", "BoxIntegral d=10 n=256"]` | 1.012 | – | 0.003 | 0.003 |
| `["evaluate", "BoxIntegral d=10 n=4096"]` | 0.987 | – | 0.035 | 0.034 |
| `["evaluate", "BoxIntegral d=200 n=1024"]` | 1.019 | – | 0.032 | 0.033 |
| `["evaluate", "BoxIntegral d=200 n=4096"]` | 0.986 | – | 0.214 | 0.211 |
| `["evaluate", "BoxIntegral d=50 n=1024"]` | 0.996 | – | 0.013 | 0.013 |
| `["evaluate", "BoxIntegral d=50 n=4096"]` | 1.022 | – | 0.073 | 0.074 |
| `["evaluate", "Genz(continuous) d=10 n=1024"]` | 1.015 | – | 0.007 | 0.007 |
| `["evaluate", "Genz(continuous) d=10 n=16384"]` | 0.950 | – | 0.123 | 0.117 |
| `["evaluate", "Genz(continuous) d=10 n=256"]` | 0.957 | – | 0.003 | 0.003 |
| `["evaluate", "Genz(continuous) d=10 n=4096"]` | 1.038 | – | 0.029 | 0.031 |
| `["evaluate", "Genz(gaussian_peak) d=10 n=1024"]` | 1.007 | – | 0.007 | 0.007 |
| `["evaluate", "Genz(gaussian_peak) d=10 n=16384"]` | 0.985 | – | 0.122 | 0.120 |
| `["evaluate", "Genz(gaussian_peak) d=10 n=256"]` | 1.040 | – | 0.003 | 0.003 |
| `["evaluate", "Genz(gaussian_peak) d=10 n=4096"]` | 1.036 | – | 0.030 | 0.031 |
| `["evaluate", "Genz(gaussian_peak) d=200 n=1024"]` | 0.862 | ❌ | 0.040 | 0.035 |
| `["evaluate", "Genz(gaussian_peak) d=200 n=4096"]` | 1.011 | – | 0.211 | 0.213 |
| `["evaluate", "Genz(gaussian_peak) d=50 n=1024"]` | 0.999 | – | 0.013 | 0.013 |
| `["evaluate", "Genz(gaussian_peak) d=50 n=4096"]` | 1.018 | – | 0.070 | 0.071 |
| `["evaluate", "Genz(oscillatory) n=1024"]` | 1.011 | – | 0.008 | 0.008 |
| `["evaluate", "Genz(oscillatory) n=16384"]` | 0.966 | – | 0.116 | 0.112 |
| `["evaluate", "Genz(oscillatory) n=256"]` | 0.783 | ❌ | 0.003 | 0.003 |
| `["evaluate", "Genz(oscillatory) n=4096"]` | 1.039 | – | 0.030 | 0.031 |
| `["evaluate", "Keister n=1024"]` | 1.049 | – | 0.011 | 0.011 |
| `["evaluate", "Keister n=16384"]` | 0.998 | – | 0.160 | 0.159 |
| `["evaluate", "Keister n=256"]` | 1.040 | – | 0.004 | 0.004 |
| `["evaluate", "Keister n=4096"]` | 1.114 | ✅ | 0.043 | 0.048 |
| `["evaluate", "Linear0 d=10 n=1024"]` | 0.951 | – | 0.002 | 0.002 |
| `["evaluate", "Linear0 d=10 n=16384"]` | 0.864 | ❌ | 0.053 | 0.046 |
| `["evaluate", "Linear0 d=10 n=256"]` | 0.955 | – | 0.001 | 0.001 |
| `["evaluate", "Linear0 d=10 n=4096"]` | 1.027 | – | 0.010 | 0.010 |
| `["evaluate", "Linear0 d=200 n=1024"]` | 1.019 | – | 0.026 | 0.026 |
| `["evaluate", "Linear0 d=200 n=4096"]` | 0.995 | – | 0.191 | 0.190 |
| `["evaluate", "Linear0 d=50 n=1024"]` | 0.989 | – | 0.007 | 0.006 |
| `["evaluate", "Linear0 d=50 n=4096"]` | 1.033 | – | 0.048 | 0.049 |
| `["gen_samples", "DigitalNetB2 d=10 n=1024"]` | 0.883 | ❌ | 0.044 | 0.038 |
| `["gen_samples", "DigitalNetB2 d=10 n=16384"]` | 1.011 | – | 1.504 | 1.521 |
| `["gen_samples", "DigitalNetB2 d=10 n=256"]` | 1.015 | – | 0.018 | 0.018 |
| `["gen_samples", "DigitalNetB2 d=10 n=4096"]` | 1.262 | ✅ | 0.289 | 0.364 |
| `["gen_samples", "DigitalNetB2 d=3 n=1024"]` | 0.838 | ❌ | 0.020 | 0.016 |
| `["gen_samples", "DigitalNetB2 d=3 n=16384"]` | 0.831 | ❌ | 0.424 | 0.353 |
| `["gen_samples", "DigitalNetB2 d=3 n=256"]` | 1.078 | ✅ | 0.006 | 0.007 |
| `["gen_samples", "DigitalNetB2 d=3 n=4096"]` | 0.873 | ❌ | 0.054 | 0.047 |
| `["gen_samples", "Halton d=10 n=1024"]` | 1.748 | ✅ | 0.833 | 1.456 |
| `["gen_samples", "Halton d=10 n=16384"]` | 1.678 | ✅ | 14.094 | 23.645 |
| `["gen_samples", "Halton d=10 n=256"]` | 1.863 | ✅ | 0.211 | 0.392 |
| `["gen_samples", "Halton d=10 n=4096"]` | 1.682 | ✅ | 3.382 | 5.688 |
| `["gen_samples", "Halton d=3 n=1024"]` | 1.717 | ✅ | 0.267 | 0.458 |
| `["gen_samples", "Halton d=3 n=16384"]` | 1.677 | ✅ | 4.756 | 7.975 |
| `["gen_samples", "Halton d=3 n=256"]` | 1.735 | ✅ | 0.065 | 0.112 |
| `["gen_samples", "Halton d=3 n=4096"]` | 1.690 | ✅ | 1.135 | 1.918 |
| `["gen_samples", "IIDStdUniform d=10 n=1024"]` | 1.025 | – | 0.011 | 0.011 |
| `["gen_samples", "IIDStdUniform d=10 n=16384"]` | 1.010 | – | 0.589 | 0.595 |
| `["gen_samples", "IIDStdUniform d=10 n=256"]` | 0.967 | – | 0.003 | 0.003 |
| `["gen_samples", "IIDStdUniform d=10 n=4096"]` | 0.984 | – | 0.026 | 0.026 |
| `["gen_samples", "IIDStdUniform d=3 n=1024"]` | 1.064 | ✅ | 0.003 | 0.004 |
| `["gen_samples", "IIDStdUniform d=3 n=16384"]` | 1.247 | ✅ | 0.031 | 0.039 |
| `["gen_samples", "IIDStdUniform d=3 n=256"]` | 0.943 | ❌ | 0.001 | 0.001 |
| `["gen_samples", "IIDStdUniform d=3 n=4096"]` | 0.831 | ❌ | 0.011 | 0.009 |
| `["gen_samples", "Kronecker d=10 n=1024"]` | 2.510 | ✅ | 0.029 | 0.074 |
| `["gen_samples", "Kronecker d=10 n=16384"]` | 2.073 | ✅ | 0.920 | 1.907 |
| `["gen_samples", "Kronecker d=10 n=256"]` | 2.521 | ✅ | 0.007 | 0.018 |
| `["gen_samples", "Kronecker d=10 n=4096"]` | 2.888 | ✅ | 0.115 | 0.333 |
| `["gen_samples", "Kronecker d=3 n=1024"]` | 2.597 | ✅ | 0.008 | 0.022 |
| `["gen_samples", "Kronecker d=3 n=16384"]` | 3.088 | ✅ | 0.136 | 0.420 |
| `["gen_samples", "Kronecker d=3 n=256"]` | 2.443 | ✅ | 0.002 | 0.006 |
| `["gen_samples", "Kronecker d=3 n=4096"]` | 2.725 | ✅ | 0.035 | 0.096 |
| `["gen_samples", "Lattice d=10 n=1024"]` | 2.903 | ✅ | 0.068 | 0.198 |
| `["gen_samples", "Lattice d=10 n=16384"]` | 1.844 | ✅ | 2.539 | 4.682 |
| `["gen_samples", "Lattice d=10 n=256"]` | 2.559 | ✅ | 0.020 | 0.052 |
| `["gen_samples", "Lattice d=10 n=4096"]` | 1.830 | ✅ | 0.633 | 1.159 |
| `["gen_samples", "Lattice d=3 n=1024"]` | 2.200 | ✅ | 0.026 | 0.057 |
| `["gen_samples", "Lattice d=3 n=16384"]` | 1.622 | ✅ | 0.829 | 1.344 |
| `["gen_samples", "Lattice d=3 n=256"]` | 1.928 | ✅ | 0.008 | 0.015 |
| `["gen_samples", "Lattice d=3 n=4096"]` | 2.186 | ✅ | 0.103 | 0.225 |
| `["integrate", "CubMCCLT AsianOption"]` | 0.974 | – | 3.680 | 3.583 |
| `["integrate", "CubMCCLT EuropeanOption"]` | 0.970 | – | 7.466 | 7.242 |
| `["integrate", "CubMCCLT Keister"]` | 0.943 | ❌ | 14.666 | 13.830 |
| `["integrate", "CubQMCLatticeG EuropeanOption"]` | 1.481 | ✅ | 1.451 | 2.149 |
| `["integrate", "CubQMCLatticeG Keister"]` | 1.309 | ✅ | 0.332 | 0.434 |
| `["integrate", "CubQMCNetG AsianOption"]` | 0.977 | – | 1.372 | 1.341 |
| `["integrate", "CubQMCNetG EuropeanOption"]` | 0.682 | ❌ | 1.949 | 1.329 |
| `["integrate", "CubQMCNetG Keister"]` | 0.979 | – | 0.276 | 0.271 |
| `["integrate", "CubQMCNetGRep AsianOption"]` | 1.187 | ✅ | 21.876 | 25.978 |
| `["integrate", "CubQMCNetGRep EuropeanOption"]` | 1.186 | ✅ | 21.758 | 25.816 |
| `["integrate", "CubQMCNetGRep Keister"]` | 1.040 | – | 3.308 | 3.440 |
| `["transform", "Gaussian d=10 n=1024"]` | 0.900 | ❌ | 0.134 | 0.121 |
| `["transform", "Gaussian d=10 n=16384"]` | 0.997 | – | 2.762 | 2.754 |
| `["transform", "Gaussian d=10 n=256"]` | 1.020 | – | 0.029 | 0.030 |
| `["transform", "Gaussian d=10 n=4096"]` | 0.990 | – | 0.587 | 0.581 |
| `["transform", "Gaussian d=3 n=1024"]` | 0.989 | – | 0.036 | 0.036 |
| `["transform", "Gaussian d=3 n=16384"]` | 0.956 | – | 0.756 | 0.723 |
| `["transform", "Gaussian d=3 n=256"]` | 0.993 | – | 0.009 | 0.009 |
| `["transform", "Gaussian d=3 n=4096"]` | 1.004 | – | 0.147 | 0.147 |
| `["transform", "Gaussian(dense) d=200 n=1024"]` | 0.803 | ❌ | 5.725 | 4.596 |
| `["transform", "Gaussian(dense) d=200 n=4096"]` | 1.014 | – | 18.843 | 19.113 |
| `["transform", "Gaussian(dense) d=50 n=1024"]` | 1.004 | – | 0.924 | 0.927 |
| `["transform", "Gaussian(dense) d=50 n=4096"]` | 1.003 | – | 3.852 | 3.863 |
| `["transform", "Gaussian(diag) d=200 n=1024"]` | 0.997 | – | 3.457 | 3.447 |
| `["transform", "Gaussian(diag) d=200 n=4096"]` | 0.998 | – | 14.944 | 14.920 |
| `["transform", "Gaussian(diag) d=50 n=1024"]` | 0.977 | – | 0.774 | 0.756 |
| `["transform", "Gaussian(diag) d=50 n=4096"]` | 1.004 | – | 3.442 | 3.455 |
| `["transform", "JohnsonsSU d=10 n=1024"]` | 0.991 | – | 0.199 | 0.197 |
| `["transform", "JohnsonsSU d=10 n=16384"]` | 1.006 | – | 3.858 | 3.879 |
| `["transform", "JohnsonsSU d=10 n=256"]` | 1.005 | – | 0.048 | 0.048 |
| `["transform", "JohnsonsSU d=10 n=4096"]` | 0.978 | – | 0.871 | 0.851 |
| `["transform", "StudentT d=10 n=1024"]` | 1.003 | – | 0.050 | 0.051 |
| `["transform", "StudentT d=10 n=16384"]` | 1.001 | – | 1.273 | 1.275 |
| `["transform", "StudentT d=10 n=256"]` | 1.030 | – | 0.013 | 0.013 |
| `["transform", "StudentT d=10 n=4096"]` | 0.999 | – | 0.199 | 0.199 |
