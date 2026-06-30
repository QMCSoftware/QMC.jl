# Benchmark: `local` vs `f46a121c228bcd161f44f42deb4729638d869062`

| | local (`local`) | reference (`f46a121c228bcd161f44f42deb4729638d869062`) |
|---|---|---|
| commit | non gitrepo | non gitrepo |
| date | 2026-06-30T14:17:24.197 | 2026-06-30T14:19:11.851 |

**`ratio = reference time ÷ local time`**  
ratio `< 1` → local is **slower** ❌  |  ratio `> 1` → local is **faster** ✅

## Aggregate Summary

| metric | ratio | local total | reference total |
|:-------|------:|------------:|----------------:|
| matched benchmarks | 111 | — | — |
| weighted time ratio | 1.009 | 175.599 ms | 177.184 ms |
| weighted memory ratio | 1.020 | 118918.9 KiB | 121291.7 KiB |

| benchmark | ratio | verdict | local (ms) | reference (ms) |
|:----------|------:|:-------:|----------:|---------------:|
| `["evaluate", "BoxIntegral d=10 n=1024"]` | 1.025 | – | 0.010 | 0.011 |
| `["evaluate", "BoxIntegral d=10 n=16384"]` | 1.044 | – | 0.145 | 0.151 |
| `["evaluate", "BoxIntegral d=10 n=256"]` | 0.979 | – | 0.004 | 0.004 |
| `["evaluate", "BoxIntegral d=10 n=4096"]` | 0.913 | ❌ | 0.042 | 0.038 |
| `["evaluate", "BoxIntegral d=200 n=1024"]` | 0.994 | – | 0.052 | 0.052 |
| `["evaluate", "BoxIntegral d=200 n=4096"]` | 1.001 | – | 0.280 | 0.280 |
| `["evaluate", "BoxIntegral d=50 n=1024"]` | 0.872 | ❌ | 0.024 | 0.021 |
| `["evaluate", "BoxIntegral d=50 n=4096"]` | 1.119 | ✅ | 0.085 | 0.095 |
| `["evaluate", "Genz(continuous) d=10 n=1024"]` | 0.935 | ❌ | 0.018 | 0.017 |
| `["evaluate", "Genz(continuous) d=10 n=16384"]` | 0.996 | – | 0.136 | 0.136 |
| `["evaluate", "Genz(continuous) d=10 n=256"]` | 1.080 | ✅ | 0.006 | 0.007 |
| `["evaluate", "Genz(continuous) d=10 n=4096"]` | 0.719 | ❌ | 0.051 | 0.037 |
| `["evaluate", "Genz(gaussian_peak) d=10 n=1024"]` | 1.433 | ✅ | 0.016 | 0.023 |
| `["evaluate", "Genz(gaussian_peak) d=10 n=16384"]` | 1.000 | – | 0.134 | 0.134 |
| `["evaluate", "Genz(gaussian_peak) d=10 n=256"]` | 1.001 | – | 0.006 | 0.006 |
| `["evaluate", "Genz(gaussian_peak) d=10 n=4096"]` | 1.285 | ✅ | 0.032 | 0.041 |
| `["evaluate", "Genz(gaussian_peak) d=200 n=1024"]` | 0.935 | ❌ | 0.061 | 0.057 |
| `["evaluate", "Genz(gaussian_peak) d=200 n=4096"]` | 1.008 | – | 0.276 | 0.278 |
| `["evaluate", "Genz(gaussian_peak) d=50 n=1024"]` | 0.880 | ❌ | 0.018 | 0.016 |
| `["evaluate", "Genz(gaussian_peak) d=50 n=4096"]` | 1.044 | – | 0.084 | 0.088 |
| `["evaluate", "Genz(oscillatory) n=1024"]` | 1.357 | ✅ | 0.013 | 0.018 |
| `["evaluate", "Genz(oscillatory) n=16384"]` | 1.026 | – | 0.248 | 0.254 |
| `["evaluate", "Genz(oscillatory) n=256"]` | 0.898 | ❌ | 0.005 | 0.005 |
| `["evaluate", "Genz(oscillatory) n=4096"]` | 1.179 | ✅ | 0.045 | 0.053 |
| `["evaluate", "Keister n=1024"]` | 1.016 | – | 0.012 | 0.012 |
| `["evaluate", "Keister n=16384"]` | 1.012 | – | 0.186 | 0.188 |
| `["evaluate", "Keister n=256"]` | 1.049 | – | 0.004 | 0.005 |
| `["evaluate", "Keister n=4096"]` | 0.949 | ❌ | 0.053 | 0.050 |
| `["evaluate", "Linear0 d=10 n=1024"]` | 1.002 | – | 0.005 | 0.005 |
| `["evaluate", "Linear0 d=10 n=16384"]` | 0.988 | – | 0.061 | 0.060 |
| `["evaluate", "Linear0 d=10 n=256"]` | 0.963 | – | 0.002 | 0.002 |
| `["evaluate", "Linear0 d=10 n=4096"]` | 0.996 | – | 0.017 | 0.017 |
| `["evaluate", "Linear0 d=200 n=1024"]` | 1.048 | – | 0.067 | 0.070 |
| `["evaluate", "Linear0 d=200 n=4096"]` | 1.010 | – | 0.256 | 0.259 |
| `["evaluate", "Linear0 d=50 n=1024"]` | 0.978 | – | 0.018 | 0.018 |
| `["evaluate", "Linear0 d=50 n=4096"]` | 1.057 | ✅ | 0.063 | 0.066 |
| `["gen_samples", "DigitalNetB2 d=10 n=1024"]` | 1.024 | – | 0.049 | 0.050 |
| `["gen_samples", "DigitalNetB2 d=10 n=16384"]` | 0.979 | – | 1.439 | 1.408 |
| `["gen_samples", "DigitalNetB2 d=10 n=256"]` | 1.026 | – | 0.019 | 0.019 |
| `["gen_samples", "DigitalNetB2 d=10 n=4096"]` | 1.099 | ✅ | 0.317 | 0.348 |
| `["gen_samples", "DigitalNetB2 d=3 n=1024"]` | 0.943 | ❌ | 0.023 | 0.022 |
| `["gen_samples", "DigitalNetB2 d=3 n=16384"]` | 1.164 | ✅ | 0.403 | 0.468 |
| `["gen_samples", "DigitalNetB2 d=3 n=256"]` | 1.107 | ✅ | 0.008 | 0.008 |
| `["gen_samples", "DigitalNetB2 d=3 n=4096"]` | 0.967 | – | 0.071 | 0.069 |
| `["gen_samples", "Halton d=10 n=1024"]` | 0.998 | – | 0.683 | 0.681 |
| `["gen_samples", "Halton d=10 n=16384"]` | 1.002 | – | 11.756 | 11.774 |
| `["gen_samples", "Halton d=10 n=256"]` | 1.013 | – | 0.168 | 0.170 |
| `["gen_samples", "Halton d=10 n=4096"]` | 1.007 | – | 2.775 | 2.796 |
| `["gen_samples", "Halton d=3 n=1024"]` | 1.000 | – | 0.222 | 0.222 |
| `["gen_samples", "Halton d=3 n=16384"]` | 1.008 | – | 3.812 | 3.842 |
| `["gen_samples", "Halton d=3 n=256"]` | 1.006 | – | 0.054 | 0.054 |
| `["gen_samples", "Halton d=3 n=4096"]` | 1.000 | – | 0.915 | 0.915 |
| `["gen_samples", "IIDStdUniform d=10 n=1024"]` | 0.882 | ❌ | 0.014 | 0.012 |
| `["gen_samples", "IIDStdUniform d=10 n=16384"]` | 1.008 | – | 0.495 | 0.499 |
| `["gen_samples", "IIDStdUniform d=10 n=256"]` | 0.764 | ❌ | 0.004 | 0.003 |
| `["gen_samples", "IIDStdUniform d=10 n=4096"]` | 1.294 | ✅ | 0.041 | 0.053 |
| `["gen_samples", "IIDStdUniform d=3 n=1024"]` | 0.775 | ❌ | 0.005 | 0.004 |
| `["gen_samples", "IIDStdUniform d=3 n=16384"]` | 0.987 | – | 0.057 | 0.056 |
| `["gen_samples", "IIDStdUniform d=3 n=256"]` | 1.416 | ✅ | 0.001 | 0.002 |
| `["gen_samples", "IIDStdUniform d=3 n=4096"]` | 0.985 | – | 0.013 | 0.013 |
| `["gen_samples", "Kronecker d=10 n=1024"]` | 0.969 | – | 0.034 | 0.033 |
| `["gen_samples", "Kronecker d=10 n=16384"]` | 0.999 | – | 0.901 | 0.900 |
| `["gen_samples", "Kronecker d=10 n=256"]` | 0.965 | – | 0.008 | 0.008 |
| `["gen_samples", "Kronecker d=10 n=4096"]` | 1.153 | ✅ | 0.131 | 0.151 |
| `["gen_samples", "Kronecker d=3 n=1024"]` | 1.024 | – | 0.010 | 0.010 |
| `["gen_samples", "Kronecker d=3 n=16384"]` | 1.021 | – | 0.155 | 0.158 |
| `["gen_samples", "Kronecker d=3 n=256"]` | 0.999 | – | 0.003 | 0.003 |
| `["gen_samples", "Kronecker d=3 n=4096"]` | 0.994 | – | 0.039 | 0.038 |
| `["gen_samples", "Lattice d=10 n=1024"]` | 1.016 | – | 0.119 | 0.121 |
| `["gen_samples", "Lattice d=10 n=16384"]` | 0.975 | – | 2.939 | 2.867 |
| `["gen_samples", "Lattice d=10 n=256"]` | 1.037 | – | 0.033 | 0.035 |
| `["gen_samples", "Lattice d=10 n=4096"]` | 1.019 | – | 0.714 | 0.728 |
| `["gen_samples", "Lattice d=3 n=1024"]` | 0.946 | ❌ | 0.038 | 0.036 |
| `["gen_samples", "Lattice d=3 n=16384"]` | 1.009 | – | 0.832 | 0.839 |
| `["gen_samples", "Lattice d=3 n=256"]` | 0.916 | ❌ | 0.012 | 0.011 |
| `["gen_samples", "Lattice d=3 n=4096"]` | 0.946 | ❌ | 0.140 | 0.132 |
| `["integrate", "CubMCCLT AsianOption"]` | 0.999 | – | 4.080 | 4.075 |
| `["integrate", "CubMCCLT EuropeanOption"]` | 0.947 | ❌ | 7.617 | 7.210 |
| `["integrate", "CubMCCLT Keister"]` | 1.007 | – | 16.828 | 16.951 |
| `["integrate", "CubQMCLatticeG EuropeanOption"]` | 0.985 | – | 2.257 | 2.223 |
| `["integrate", "CubQMCLatticeG Keister"]` | 1.212 | ✅ | 0.361 | 0.437 |
| `["integrate", "CubQMCNetG AsianOption"]` | 1.031 | – | 1.743 | 1.797 |
| `["integrate", "CubQMCNetG EuropeanOption"]` | 0.996 | – | 1.658 | 1.651 |
| `["integrate", "CubQMCNetG Keister"]` | 1.000 | – | 0.308 | 0.308 |
| `["integrate", "CubQMCNetGRep AsianOption"]` | 1.036 | – | 23.726 | 24.571 |
| `["integrate", "CubQMCNetGRep EuropeanOption"]` | 1.037 | – | 23.257 | 24.119 |
| `["integrate", "CubQMCNetGRep Keister"]` | 1.034 | – | 3.338 | 3.451 |
| `["transform", "Gaussian d=10 n=1024"]` | 0.985 | – | 0.156 | 0.153 |
| `["transform", "Gaussian d=10 n=16384"]` | 1.007 | – | 2.476 | 2.493 |
| `["transform", "Gaussian d=10 n=256"]` | 1.234 | ✅ | 0.033 | 0.041 |
| `["transform", "Gaussian d=10 n=4096"]` | 1.008 | – | 0.626 | 0.631 |
| `["transform", "Gaussian d=3 n=1024"]` | 0.826 | ❌ | 0.047 | 0.039 |
| `["transform", "Gaussian d=3 n=16384"]` | 1.009 | – | 0.745 | 0.751 |
| `["transform", "Gaussian d=3 n=256"]` | 1.017 | – | 0.025 | 0.026 |
| `["transform", "Gaussian d=3 n=4096"]` | 0.992 | – | 0.184 | 0.182 |
| `["transform", "Gaussian(dense) d=200 n=1024"]` | 0.982 | – | 5.131 | 5.038 |
| `["transform", "Gaussian(dense) d=200 n=4096"]` | 1.008 | – | 16.397 | 16.535 |
| `["transform", "Gaussian(dense) d=50 n=1024"]` | 1.009 | – | 1.121 | 1.131 |
| `["transform", "Gaussian(dense) d=50 n=4096"]` | 0.967 | – | 4.425 | 4.277 |
| `["transform", "Gaussian(diag) d=200 n=1024"]` | 0.998 | – | 3.093 | 3.087 |
| `["transform", "Gaussian(diag) d=200 n=4096"]` | 0.995 | – | 13.387 | 13.314 |
| `["transform", "Gaussian(diag) d=50 n=1024"]` | 1.005 | – | 0.782 | 0.786 |
| `["transform", "Gaussian(diag) d=50 n=4096"]` | 1.002 | – | 3.091 | 3.099 |
| `["transform", "JohnsonsSU d=10 n=1024"]` | 0.950 | – | 0.262 | 0.249 |
| `["transform", "JohnsonsSU d=10 n=16384"]` | 1.005 | – | 4.256 | 4.277 |
| `["transform", "JohnsonsSU d=10 n=256"]` | 0.649 | ❌ | 0.100 | 0.065 |
| `["transform", "JohnsonsSU d=10 n=4096"]` | 0.986 | – | 1.038 | 1.023 |
| `["transform", "StudentT d=10 n=1024"]` | 1.034 | – | 0.031 | 0.032 |
| `["transform", "StudentT d=10 n=16384"]` | 0.998 | – | 0.904 | 0.902 |
| `["transform", "StudentT d=10 n=256"]` | 1.040 | – | 0.008 | 0.008 |
| `["transform", "StudentT d=10 n=4096"]` | 0.986 | – | 0.123 | 0.121 |
