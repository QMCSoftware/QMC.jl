# Benchmark: `local` vs `e256459cc374afacdf2690804beecdf8e7dac353`

| | local (`local`) | reference (`e256459cc374afacdf2690804beecdf8e7dac353`) |
|---|---|---|
| commit | non gitrepo | non gitrepo |
| date | 2026-06-19T09:17:25.313 | 2026-06-19T09:19:10.925 |

**`ratio = reference time ÷ local time`**  
ratio `< 1` → local is **slower** ❌  |  ratio `> 1` → local is **faster** ✅

## Aggregate Summary

| metric | ratio | local total | reference total |
|:-------|------:|------------:|----------------:|
| matched benchmarks | 111 | — | — |
| weighted time ratio | 0.939 | 206.397 ms | 193.723 ms |
| weighted memory ratio | 1.085 | 164010.8 KiB | 177946.0 KiB |

| benchmark | ratio | verdict | local (ms) | reference (ms) |
|:----------|------:|:-------:|----------:|---------------:|
| `["evaluate", "BoxIntegral d=10 n=1024"]` | 0.940 | ❌ | 0.008 | 0.008 |
| `["evaluate", "BoxIntegral d=10 n=16384"]` | 1.043 | – | 0.131 | 0.136 |
| `["evaluate", "BoxIntegral d=10 n=256"]` | 1.036 | – | 0.003 | 0.003 |
| `["evaluate", "BoxIntegral d=10 n=4096"]` | 0.991 | – | 0.034 | 0.034 |
| `["evaluate", "BoxIntegral d=200 n=1024"]` | 1.067 | ✅ | 0.031 | 0.033 |
| `["evaluate", "BoxIntegral d=200 n=4096"]` | 1.036 | – | 0.209 | 0.216 |
| `["evaluate", "BoxIntegral d=50 n=1024"]` | 1.000 | – | 0.013 | 0.013 |
| `["evaluate", "BoxIntegral d=50 n=4096"]` | 1.015 | – | 0.072 | 0.073 |
| `["evaluate", "Genz(continuous) d=10 n=1024"]` | 0.991 | – | 0.007 | 0.007 |
| `["evaluate", "Genz(continuous) d=10 n=16384"]` | 0.995 | – | 0.119 | 0.119 |
| `["evaluate", "Genz(continuous) d=10 n=256"]` | 1.074 | ✅ | 0.002 | 0.003 |
| `["evaluate", "Genz(continuous) d=10 n=4096"]` | 0.996 | – | 0.030 | 0.030 |
| `["evaluate", "Genz(gaussian_peak) d=10 n=1024"]` | 1.000 | – | 0.007 | 0.007 |
| `["evaluate", "Genz(gaussian_peak) d=10 n=16384"]` | 0.996 | – | 0.119 | 0.118 |
| `["evaluate", "Genz(gaussian_peak) d=10 n=256"]` | 0.945 | ❌ | 0.003 | 0.002 |
| `["evaluate", "Genz(gaussian_peak) d=10 n=4096"]` | 0.962 | – | 0.032 | 0.030 |
| `["evaluate", "Genz(gaussian_peak) d=200 n=1024"]` | 0.925 | ❌ | 0.037 | 0.034 |
| `["evaluate", "Genz(gaussian_peak) d=200 n=4096"]` | 0.984 | – | 0.213 | 0.209 |
| `["evaluate", "Genz(gaussian_peak) d=50 n=1024"]` | 0.996 | – | 0.012 | 0.012 |
| `["evaluate", "Genz(gaussian_peak) d=50 n=4096"]` | 0.965 | – | 0.072 | 0.069 |
| `["evaluate", "Genz(oscillatory) n=1024"]` | 0.988 | – | 0.008 | 0.008 |
| `["evaluate", "Genz(oscillatory) n=16384"]` | 0.994 | – | 0.114 | 0.114 |
| `["evaluate", "Genz(oscillatory) n=256"]` | 1.027 | – | 0.003 | 0.003 |
| `["evaluate", "Genz(oscillatory) n=4096"]` | 1.036 | – | 0.031 | 0.032 |
| `["evaluate", "Keister n=1024"]` | 1.081 | ✅ | 0.011 | 0.012 |
| `["evaluate", "Keister n=16384"]` | 1.008 | – | 0.155 | 0.156 |
| `["evaluate", "Keister n=256"]` | 0.950 | ❌ | 0.004 | 0.004 |
| `["evaluate", "Keister n=4096"]` | 0.993 | – | 0.045 | 0.045 |
| `["evaluate", "Linear0 d=10 n=1024"]` | 0.925 | ❌ | 0.002 | 0.002 |
| `["evaluate", "Linear0 d=10 n=16384"]` | 0.954 | – | 0.047 | 0.045 |
| `["evaluate", "Linear0 d=10 n=256"]` | 1.090 | ✅ | 0.001 | 0.001 |
| `["evaluate", "Linear0 d=10 n=4096"]` | 1.056 | ✅ | 0.009 | 0.010 |
| `["evaluate", "Linear0 d=200 n=1024"]` | 0.927 | ❌ | 0.025 | 0.024 |
| `["evaluate", "Linear0 d=200 n=4096"]` | 0.991 | – | 0.189 | 0.188 |
| `["evaluate", "Linear0 d=50 n=1024"]` | 1.017 | – | 0.006 | 0.006 |
| `["evaluate", "Linear0 d=50 n=4096"]` | 1.049 | – | 0.048 | 0.050 |
| `["gen_samples", "DigitalNetB2 d=10 n=1024"]` | 0.957 | – | 0.041 | 0.039 |
| `["gen_samples", "DigitalNetB2 d=10 n=16384"]` | 0.997 | – | 1.485 | 1.480 |
| `["gen_samples", "DigitalNetB2 d=10 n=256"]` | 1.080 | ✅ | 0.018 | 0.019 |
| `["gen_samples", "DigitalNetB2 d=10 n=4096"]` | 1.142 | ✅ | 0.288 | 0.330 |
| `["gen_samples", "DigitalNetB2 d=3 n=1024"]` | 0.947 | ❌ | 0.019 | 0.018 |
| `["gen_samples", "DigitalNetB2 d=3 n=16384"]` | 1.016 | – | 0.360 | 0.365 |
| `["gen_samples", "DigitalNetB2 d=3 n=256"]` | 1.010 | – | 0.007 | 0.007 |
| `["gen_samples", "DigitalNetB2 d=3 n=4096"]` | 0.943 | ❌ | 0.050 | 0.047 |
| `["gen_samples", "Halton d=10 n=1024"]` | 1.014 | – | 1.534 | 1.555 |
| `["gen_samples", "Halton d=10 n=16384"]` | 1.000 | – | 26.269 | 26.272 |
| `["gen_samples", "Halton d=10 n=256"]` | 0.986 | – | 0.379 | 0.373 |
| `["gen_samples", "Halton d=10 n=4096"]` | 0.999 | – | 6.292 | 6.286 |
| `["gen_samples", "Halton d=3 n=1024"]` | 1.003 | – | 0.502 | 0.503 |
| `["gen_samples", "Halton d=3 n=16384"]` | 0.999 | – | 8.674 | 8.662 |
| `["gen_samples", "Halton d=3 n=256"]` | 1.002 | – | 0.119 | 0.119 |
| `["gen_samples", "Halton d=3 n=4096"]` | 0.997 | – | 2.093 | 2.088 |
| `["gen_samples", "IIDStdUniform d=10 n=1024"]` | 1.210 | ✅ | 0.008 | 0.010 |
| `["gen_samples", "IIDStdUniform d=10 n=16384"]` | 0.992 | – | 0.611 | 0.607 |
| `["gen_samples", "IIDStdUniform d=10 n=256"]` | 1.020 | – | 0.003 | 0.003 |
| `["gen_samples", "IIDStdUniform d=10 n=4096"]` | 0.985 | – | 0.026 | 0.026 |
| `["gen_samples", "IIDStdUniform d=3 n=1024"]` | 0.970 | – | 0.003 | 0.003 |
| `["gen_samples", "IIDStdUniform d=3 n=16384"]` | 0.621 | ❌ | 0.050 | 0.031 |
| `["gen_samples", "IIDStdUniform d=3 n=256"]` | 1.059 | ✅ | 0.001 | 0.001 |
| `["gen_samples", "IIDStdUniform d=3 n=4096"]` | 1.023 | – | 0.011 | 0.011 |
| `["gen_samples", "Kronecker d=10 n=1024"]` | 1.007 | – | 0.076 | 0.076 |
| `["gen_samples", "Kronecker d=10 n=16384"]` | 1.026 | – | 1.864 | 1.912 |
| `["gen_samples", "Kronecker d=10 n=256"]` | 1.021 | – | 0.018 | 0.019 |
| `["gen_samples", "Kronecker d=10 n=4096"]` | 1.022 | – | 0.339 | 0.346 |
| `["gen_samples", "Kronecker d=3 n=1024"]` | 1.020 | – | 0.021 | 0.022 |
| `["gen_samples", "Kronecker d=3 n=16384"]` | 1.045 | – | 0.413 | 0.432 |
| `["gen_samples", "Kronecker d=3 n=256"]` | 1.048 | – | 0.006 | 0.006 |
| `["gen_samples", "Kronecker d=3 n=4096"]` | 1.027 | – | 0.096 | 0.099 |
| `["gen_samples", "Lattice d=10 n=1024"]` | 0.964 | – | 0.203 | 0.196 |
| `["gen_samples", "Lattice d=10 n=16384"]` | 1.003 | – | 4.644 | 4.657 |
| `["gen_samples", "Lattice d=10 n=256"]` | 1.033 | – | 0.050 | 0.052 |
| `["gen_samples", "Lattice d=10 n=4096"]` | 0.997 | – | 1.169 | 1.166 |
| `["gen_samples", "Lattice d=3 n=1024"]` | 0.962 | – | 0.058 | 0.056 |
| `["gen_samples", "Lattice d=3 n=16384"]` | 1.005 | – | 1.328 | 1.335 |
| `["gen_samples", "Lattice d=3 n=256"]` | 1.000 | – | 0.015 | 0.015 |
| `["gen_samples", "Lattice d=3 n=4096"]` | 1.002 | – | 0.225 | 0.225 |
| `["integrate", "CubMCCLT AsianOption"]` | 0.988 | – | 3.393 | 3.352 |
| `["integrate", "CubMCCLT EuropeanOption"]` | 0.917 | ❌ | 6.169 | 5.655 |
| `["integrate", "CubMCCLT Keister"]` | 0.780 | ❌ | 13.072 | 10.192 |
| `["integrate", "CubQMCLatticeG EuropeanOption"]` | 0.931 | ❌ | 2.190 | 2.038 |
| `["integrate", "CubQMCLatticeG Keister"]` | 1.001 | – | 0.425 | 0.425 |
| `["integrate", "CubQMCNetG AsianOption"]` | 0.913 | ❌ | 1.364 | 1.245 |
| `["integrate", "CubQMCNetG EuropeanOption"]` | 0.931 | ❌ | 1.313 | 1.223 |
| `["integrate", "CubQMCNetG Keister"]` | 1.010 | – | 0.272 | 0.275 |
| `["integrate", "CubQMCNetGRep AsianOption"]` | 0.779 | ❌ | 25.962 | 20.221 |
| `["integrate", "CubQMCNetGRep EuropeanOption"]` | 0.985 | – | 25.774 | 25.388 |
| `["integrate", "CubQMCNetGRep Keister"]` | 1.087 | ✅ | 3.370 | 3.665 |
| `["transform", "Gaussian d=10 n=1024"]` | 1.006 | – | 0.121 | 0.122 |
| `["transform", "Gaussian d=10 n=16384"]` | 0.996 | – | 2.756 | 2.745 |
| `["transform", "Gaussian d=10 n=256"]` | 0.996 | – | 0.030 | 0.030 |
| `["transform", "Gaussian d=10 n=4096"]` | 1.006 | – | 0.563 | 0.567 |
| `["transform", "Gaussian d=3 n=1024"]` | 0.996 | – | 0.036 | 0.036 |
| `["transform", "Gaussian d=3 n=16384"]` | 0.955 | – | 0.768 | 0.734 |
| `["transform", "Gaussian d=3 n=256"]` | 1.003 | – | 0.009 | 0.009 |
| `["transform", "Gaussian d=3 n=4096"]` | 0.953 | – | 0.156 | 0.148 |
| `["transform", "Gaussian(dense) d=200 n=1024"]` | 0.979 | – | 4.575 | 4.480 |
| `["transform", "Gaussian(dense) d=200 n=4096"]` | 0.943 | ❌ | 19.014 | 17.935 |
| `["transform", "Gaussian(dense) d=50 n=1024"]` | 0.909 | ❌ | 0.920 | 0.836 |
| `["transform", "Gaussian(dense) d=50 n=4096"]` | 0.978 | – | 3.769 | 3.685 |
| `["transform", "Gaussian(diag) d=200 n=1024"]` | 0.991 | – | 3.468 | 3.436 |
| `["transform", "Gaussian(diag) d=200 n=4096"]` | 0.922 | ❌ | 14.948 | 13.775 |
| `["transform", "Gaussian(diag) d=50 n=1024"]` | 0.991 | – | 0.767 | 0.760 |
| `["transform", "Gaussian(diag) d=50 n=4096"]` | 0.992 | – | 3.462 | 3.435 |
| `["transform", "JohnsonsSU d=10 n=1024"]` | 1.007 | – | 0.196 | 0.197 |
| `["transform", "JohnsonsSU d=10 n=16384"]` | 0.990 | – | 3.873 | 3.835 |
| `["transform", "JohnsonsSU d=10 n=256"]` | 0.994 | – | 0.048 | 0.048 |
| `["transform", "JohnsonsSU d=10 n=4096"]` | 1.005 | – | 0.852 | 0.856 |
| `["transform", "StudentT d=10 n=1024"]` | 1.002 | – | 0.050 | 0.050 |
| `["transform", "StudentT d=10 n=16384"]` | 0.619 | ❌ | 1.278 | 0.790 |
| `["transform", "StudentT d=10 n=256"]` | 0.985 | – | 0.013 | 0.013 |
| `["transform", "StudentT d=10 n=4096"]` | 1.000 | – | 0.199 | 0.199 |
