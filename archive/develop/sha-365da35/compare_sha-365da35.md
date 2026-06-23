# Benchmark: `local` vs `c1a889acfd8243cdcde2d05c6a08be0dd418de2f`

| | local (`local`) | reference (`c1a889acfd8243cdcde2d05c6a08be0dd418de2f`) |
|---|---|---|
| commit | non gitrepo | non gitrepo |
| date | 2026-06-23T02:13:29.725 | 2026-06-23T02:15:06.464 |

**`ratio = reference time ÷ local time`**  
ratio `< 1` → local is **slower** ❌  |  ratio `> 1` → local is **faster** ✅

## Aggregate Summary

| metric | ratio | local total | reference total |
|:-------|------:|------------:|----------------:|
| matched benchmarks | 111 | — | — |
| weighted time ratio | 0.936 | 212.875 ms | 199.291 ms |
| weighted memory ratio | 1.000 | 173035.1 KiB | 173035.1 KiB |

| benchmark | ratio | verdict | local (ms) | reference (ms) |
|:----------|------:|:-------:|----------:|---------------:|
| `["evaluate", "BoxIntegral d=10 n=1024"]` | 1.154 | ✅ | 0.008 | 0.009 |
| `["evaluate", "BoxIntegral d=10 n=16384"]` | 1.024 | – | 0.130 | 0.133 |
| `["evaluate", "BoxIntegral d=10 n=256"]` | 1.031 | – | 0.003 | 0.003 |
| `["evaluate", "BoxIntegral d=10 n=4096"]` | 2.511 | ✅ | 0.038 | 0.096 |
| `["evaluate", "BoxIntegral d=200 n=1024"]` | 1.014 | – | 0.047 | 0.048 |
| `["evaluate", "BoxIntegral d=200 n=4096"]` | 0.939 | ❌ | 0.184 | 0.173 |
| `["evaluate", "BoxIntegral d=50 n=1024"]` | 1.114 | ✅ | 0.015 | 0.017 |
| `["evaluate", "BoxIntegral d=50 n=4096"]` | 1.044 | – | 0.068 | 0.071 |
| `["evaluate", "Genz(continuous) d=10 n=1024"]` | 1.018 | – | 0.008 | 0.008 |
| `["evaluate", "Genz(continuous) d=10 n=16384"]` | 1.028 | – | 0.126 | 0.129 |
| `["evaluate", "Genz(continuous) d=10 n=256"]` | 1.011 | – | 0.002 | 0.003 |
| `["evaluate", "Genz(continuous) d=10 n=4096"]` | 0.929 | ❌ | 0.037 | 0.035 |
| `["evaluate", "Genz(gaussian_peak) d=10 n=1024"]` | 1.002 | – | 0.008 | 0.008 |
| `["evaluate", "Genz(gaussian_peak) d=10 n=16384"]` | 1.048 | – | 0.121 | 0.127 |
| `["evaluate", "Genz(gaussian_peak) d=10 n=256"]` | 0.966 | – | 0.003 | 0.003 |
| `["evaluate", "Genz(gaussian_peak) d=10 n=4096"]` | 1.029 | – | 0.038 | 0.039 |
| `["evaluate", "Genz(gaussian_peak) d=200 n=1024"]` | 0.896 | ❌ | 0.055 | 0.050 |
| `["evaluate", "Genz(gaussian_peak) d=200 n=4096"]` | 1.197 | ✅ | 0.175 | 0.210 |
| `["evaluate", "Genz(gaussian_peak) d=50 n=1024"]` | 1.060 | ✅ | 0.016 | 0.017 |
| `["evaluate", "Genz(gaussian_peak) d=50 n=4096"]` | 1.045 | – | 0.079 | 0.083 |
| `["evaluate", "Genz(oscillatory) n=1024"]` | 0.961 | – | 0.008 | 0.008 |
| `["evaluate", "Genz(oscillatory) n=16384"]` | 1.001 | – | 0.228 | 0.228 |
| `["evaluate", "Genz(oscillatory) n=256"]` | 1.114 | ✅ | 0.003 | 0.003 |
| `["evaluate", "Genz(oscillatory) n=4096"]` | 0.928 | ❌ | 0.036 | 0.034 |
| `["evaluate", "Keister n=1024"]` | 1.051 | ✅ | 0.011 | 0.011 |
| `["evaluate", "Keister n=16384"]` | 0.994 | – | 0.196 | 0.195 |
| `["evaluate", "Keister n=256"]` | 1.054 | ✅ | 0.004 | 0.004 |
| `["evaluate", "Keister n=4096"]` | 0.975 | – | 0.048 | 0.047 |
| `["evaluate", "Linear0 d=10 n=1024"]` | 1.080 | ✅ | 0.003 | 0.003 |
| `["evaluate", "Linear0 d=10 n=16384"]` | 0.991 | – | 0.047 | 0.047 |
| `["evaluate", "Linear0 d=10 n=256"]` | 1.068 | ✅ | 0.001 | 0.001 |
| `["evaluate", "Linear0 d=10 n=4096"]` | 1.031 | – | 0.010 | 0.011 |
| `["evaluate", "Linear0 d=200 n=1024"]` | 1.011 | – | 0.040 | 0.040 |
| `["evaluate", "Linear0 d=200 n=4096"]` | 1.040 | – | 0.153 | 0.159 |
| `["evaluate", "Linear0 d=50 n=1024"]` | 1.018 | – | 0.009 | 0.009 |
| `["evaluate", "Linear0 d=50 n=4096"]` | 1.004 | – | 0.046 | 0.046 |
| `["gen_samples", "DigitalNetB2 d=10 n=1024"]` | 0.977 | – | 0.041 | 0.040 |
| `["gen_samples", "DigitalNetB2 d=10 n=16384"]` | 1.019 | – | 1.476 | 1.503 |
| `["gen_samples", "DigitalNetB2 d=10 n=256"]` | 0.960 | – | 0.019 | 0.018 |
| `["gen_samples", "DigitalNetB2 d=10 n=4096"]` | 0.846 | ❌ | 0.160 | 0.135 |
| `["gen_samples", "DigitalNetB2 d=3 n=1024"]` | 1.193 | ✅ | 0.016 | 0.020 |
| `["gen_samples", "DigitalNetB2 d=3 n=16384"]` | 0.970 | – | 0.189 | 0.183 |
| `["gen_samples", "DigitalNetB2 d=3 n=256"]` | 1.018 | – | 0.006 | 0.006 |
| `["gen_samples", "DigitalNetB2 d=3 n=4096"]` | 1.015 | – | 0.046 | 0.047 |
| `["gen_samples", "Halton d=10 n=1024"]` | 1.003 | – | 1.829 | 1.835 |
| `["gen_samples", "Halton d=10 n=16384"]` | 1.001 | – | 29.894 | 29.927 |
| `["gen_samples", "Halton d=10 n=256"]` | 1.006 | – | 0.454 | 0.457 |
| `["gen_samples", "Halton d=10 n=4096"]` | 1.001 | – | 7.321 | 7.328 |
| `["gen_samples", "Halton d=3 n=1024"]` | 1.000 | – | 0.558 | 0.558 |
| `["gen_samples", "Halton d=3 n=16384"]` | 1.000 | – | 9.066 | 9.068 |
| `["gen_samples", "Halton d=3 n=256"]` | 0.998 | – | 0.140 | 0.140 |
| `["gen_samples", "Halton d=3 n=4096"]` | 1.000 | – | 2.243 | 2.243 |
| `["gen_samples", "IIDStdUniform d=10 n=1024"]` | 1.102 | ✅ | 0.008 | 0.009 |
| `["gen_samples", "IIDStdUniform d=10 n=16384"]` | 1.028 | – | 0.562 | 0.578 |
| `["gen_samples", "IIDStdUniform d=10 n=256"]` | 0.952 | – | 0.003 | 0.003 |
| `["gen_samples", "IIDStdUniform d=10 n=4096"]` | 1.001 | – | 0.026 | 0.026 |
| `["gen_samples", "IIDStdUniform d=3 n=1024"]` | 0.908 | ❌ | 0.003 | 0.003 |
| `["gen_samples", "IIDStdUniform d=3 n=16384"]` | 0.992 | – | 0.032 | 0.032 |
| `["gen_samples", "IIDStdUniform d=3 n=256"]` | 1.113 | ✅ | 0.001 | 0.001 |
| `["gen_samples", "IIDStdUniform d=3 n=4096"]` | 0.969 | – | 0.010 | 0.009 |
| `["gen_samples", "Kronecker d=10 n=1024"]` | 1.023 | – | 0.072 | 0.074 |
| `["gen_samples", "Kronecker d=10 n=16384"]` | 1.008 | – | 1.849 | 1.865 |
| `["gen_samples", "Kronecker d=10 n=256"]` | 0.990 | – | 0.018 | 0.018 |
| `["gen_samples", "Kronecker d=10 n=4096"]` | 0.989 | – | 0.325 | 0.321 |
| `["gen_samples", "Kronecker d=3 n=1024"]` | 0.991 | – | 0.021 | 0.021 |
| `["gen_samples", "Kronecker d=3 n=16384"]` | 0.994 | – | 0.404 | 0.402 |
| `["gen_samples", "Kronecker d=3 n=256"]` | 0.967 | – | 0.006 | 0.006 |
| `["gen_samples", "Kronecker d=3 n=4096"]` | 0.974 | – | 0.095 | 0.092 |
| `["gen_samples", "Lattice d=10 n=1024"]` | 0.990 | – | 0.177 | 0.175 |
| `["gen_samples", "Lattice d=10 n=16384"]` | 1.012 | – | 4.273 | 4.325 |
| `["gen_samples", "Lattice d=10 n=256"]` | 1.038 | – | 0.046 | 0.047 |
| `["gen_samples", "Lattice d=10 n=4096"]` | 0.821 | ❌ | 0.936 | 0.768 |
| `["gen_samples", "Lattice d=3 n=1024"]` | 0.970 | – | 0.051 | 0.050 |
| `["gen_samples", "Lattice d=3 n=16384"]` | 0.924 | ❌ | 1.199 | 1.108 |
| `["gen_samples", "Lattice d=3 n=256"]` | 1.011 | – | 0.013 | 0.013 |
| `["gen_samples", "Lattice d=3 n=4096"]` | 1.000 | – | 0.199 | 0.199 |
| `["integrate", "CubMCCLT AsianOption"]` | 1.027 | – | 3.543 | 3.638 |
| `["integrate", "CubMCCLT EuropeanOption"]` | 1.044 | – | 7.086 | 7.396 |
| `["integrate", "CubMCCLT Keister"]` | 0.832 | ❌ | 14.439 | 12.017 |
| `["integrate", "CubQMCLatticeG EuropeanOption"]` | 0.964 | – | 2.093 | 2.018 |
| `["integrate", "CubQMCLatticeG Keister"]` | 0.968 | – | 0.422 | 0.408 |
| `["integrate", "CubQMCNetG AsianOption"]` | 0.954 | – | 1.370 | 1.306 |
| `["integrate", "CubQMCNetG EuropeanOption"]` | 0.931 | ❌ | 1.397 | 1.301 |
| `["integrate", "CubQMCNetG Keister"]` | 1.076 | ✅ | 0.270 | 0.291 |
| `["integrate", "CubQMCNetGRep AsianOption"]` | 0.828 | ❌ | 26.816 | 22.208 |
| `["integrate", "CubQMCNetGRep EuropeanOption"]` | 0.842 | ❌ | 26.093 | 21.976 |
| `["integrate", "CubQMCNetGRep Keister"]` | 1.006 | – | 3.333 | 3.352 |
| `["transform", "Gaussian d=10 n=1024"]` | 1.042 | – | 0.138 | 0.144 |
| `["transform", "Gaussian d=10 n=16384"]` | 1.000 | – | 2.634 | 2.633 |
| `["transform", "Gaussian d=10 n=256"]` | 0.978 | – | 0.031 | 0.031 |
| `["transform", "Gaussian d=10 n=4096"]` | 0.994 | – | 0.650 | 0.646 |
| `["transform", "Gaussian d=3 n=1024"]` | 1.019 | – | 0.037 | 0.038 |
| `["transform", "Gaussian d=3 n=16384"]` | 1.000 | – | 0.782 | 0.782 |
| `["transform", "Gaussian d=3 n=256"]` | 1.009 | – | 0.010 | 0.010 |
| `["transform", "Gaussian d=3 n=4096"]` | 0.974 | – | 0.182 | 0.177 |
| `["transform", "Gaussian(dense) d=200 n=1024"]` | 0.844 | ❌ | 5.172 | 4.364 |
| `["transform", "Gaussian(dense) d=200 n=4096"]` | 0.992 | – | 17.888 | 17.743 |
| `["transform", "Gaussian(dense) d=50 n=1024"]` | 0.928 | ❌ | 0.969 | 0.899 |
| `["transform", "Gaussian(dense) d=50 n=4096"]` | 0.979 | – | 3.628 | 3.552 |
| `["transform", "Gaussian(diag) d=200 n=1024"]` | 1.000 | – | 3.280 | 3.281 |
| `["transform", "Gaussian(diag) d=200 n=4096"]` | 0.926 | ❌ | 14.231 | 13.176 |
| `["transform", "Gaussian(diag) d=50 n=1024"]` | 1.004 | – | 0.813 | 0.816 |
| `["transform", "Gaussian(diag) d=50 n=4096"]` | 0.996 | – | 3.297 | 3.284 |
| `["transform", "JohnsonsSU d=10 n=1024"]` | 1.025 | – | 0.218 | 0.224 |
| `["transform", "JohnsonsSU d=10 n=16384"]` | 1.005 | – | 3.856 | 3.876 |
| `["transform", "JohnsonsSU d=10 n=256"]` | 0.977 | – | 0.052 | 0.051 |
| `["transform", "JohnsonsSU d=10 n=4096"]` | 1.007 | – | 0.953 | 0.960 |
| `["transform", "StudentT d=10 n=1024"]` | 0.992 | – | 0.044 | 0.044 |
| `["transform", "StudentT d=10 n=16384"]` | 0.602 | ❌ | 1.166 | 0.702 |
| `["transform", "StudentT d=10 n=256"]` | 0.988 | – | 0.011 | 0.011 |
| `["transform", "StudentT d=10 n=4096"]` | 0.995 | – | 0.178 | 0.177 |
