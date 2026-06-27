# Benchmark: `local` vs `42b124c0c5aec61bb4266f49462e87a6f4149976`

| | local (`local`) | reference (`42b124c0c5aec61bb4266f49462e87a6f4149976`) |
|---|---|---|
| commit | non gitrepo | non gitrepo |
| date | 2026-06-27T08:30:47.941 | 2026-06-27T08:32:23.722 |

**`ratio = reference time ÷ local time`**  
ratio `< 1` → local is **slower** ❌  |  ratio `> 1` → local is **faster** ✅

## Aggregate Summary

| metric | ratio | local total | reference total |
|:-------|------:|------------:|----------------:|
| matched benchmarks | 111 | — | — |
| weighted time ratio | 1.020 | 197.147 ms | 201.016 ms |
| weighted memory ratio | 1.000 | 173042.7 KiB | 173035.1 KiB |

| benchmark | ratio | verdict | local (ms) | reference (ms) |
|:----------|------:|:-------:|----------:|---------------:|
| `["evaluate", "BoxIntegral d=10 n=1024"]` | 1.401 | ✅ | 0.010 | 0.015 |
| `["evaluate", "BoxIntegral d=10 n=16384"]` | 0.980 | – | 0.140 | 0.137 |
| `["evaluate", "BoxIntegral d=10 n=256"]` | 1.132 | ✅ | 0.003 | 0.003 |
| `["evaluate", "BoxIntegral d=10 n=4096"]` | 1.231 | ✅ | 0.040 | 0.050 |
| `["evaluate", "BoxIntegral d=200 n=1024"]` | 0.771 | ❌ | 0.061 | 0.047 |
| `["evaluate", "BoxIntegral d=200 n=4096"]` | 1.035 | – | 0.167 | 0.173 |
| `["evaluate", "BoxIntegral d=50 n=1024"]` | 1.069 | ✅ | 0.020 | 0.021 |
| `["evaluate", "BoxIntegral d=50 n=4096"]` | 0.723 | ❌ | 0.099 | 0.072 |
| `["evaluate", "Genz(continuous) d=10 n=1024"]` | 1.092 | ✅ | 0.009 | 0.010 |
| `["evaluate", "Genz(continuous) d=10 n=16384"]` | 1.229 | ✅ | 0.122 | 0.150 |
| `["evaluate", "Genz(continuous) d=10 n=256"]` | 0.994 | – | 0.003 | 0.003 |
| `["evaluate", "Genz(continuous) d=10 n=4096"]` | 0.962 | – | 0.038 | 0.037 |
| `["evaluate", "Genz(gaussian_peak) d=10 n=1024"]` | 0.932 | ❌ | 0.010 | 0.009 |
| `["evaluate", "Genz(gaussian_peak) d=10 n=16384"]` | 1.000 | – | 0.133 | 0.133 |
| `["evaluate", "Genz(gaussian_peak) d=10 n=256"]` | 0.949 | ❌ | 0.003 | 0.003 |
| `["evaluate", "Genz(gaussian_peak) d=10 n=4096"]` | 1.043 | – | 0.036 | 0.038 |
| `["evaluate", "Genz(gaussian_peak) d=200 n=1024"]` | 0.903 | ❌ | 0.061 | 0.055 |
| `["evaluate", "Genz(gaussian_peak) d=200 n=4096"]` | 0.961 | – | 0.178 | 0.171 |
| `["evaluate", "Genz(gaussian_peak) d=50 n=1024"]` | 0.946 | ❌ | 0.019 | 0.018 |
| `["evaluate", "Genz(gaussian_peak) d=50 n=4096"]` | 1.004 | – | 0.090 | 0.091 |
| `["evaluate", "Genz(oscillatory) n=1024"]` | 1.086 | ✅ | 0.010 | 0.011 |
| `["evaluate", "Genz(oscillatory) n=16384"]` | 0.975 | – | 0.231 | 0.225 |
| `["evaluate", "Genz(oscillatory) n=256"]` | 1.153 | ✅ | 0.003 | 0.003 |
| `["evaluate", "Genz(oscillatory) n=4096"]` | 1.057 | ✅ | 0.040 | 0.042 |
| `["evaluate", "Keister n=1024"]` | 0.892 | ❌ | 0.013 | 0.012 |
| `["evaluate", "Keister n=16384"]` | 1.011 | – | 0.191 | 0.193 |
| `["evaluate", "Keister n=256"]` | 0.997 | – | 0.004 | 0.004 |
| `["evaluate", "Keister n=4096"]` | 1.039 | – | 0.057 | 0.059 |
| `["evaluate", "Linear0 d=10 n=1024"]` | 1.042 | – | 0.002 | 0.003 |
| `["evaluate", "Linear0 d=10 n=16384"]` | 1.072 | ✅ | 0.049 | 0.053 |
| `["evaluate", "Linear0 d=10 n=256"]` | 0.833 | ❌ | 0.001 | 0.001 |
| `["evaluate", "Linear0 d=10 n=4096"]` | 0.781 | ❌ | 0.015 | 0.012 |
| `["evaluate", "Linear0 d=200 n=1024"]` | 0.960 | – | 0.043 | 0.041 |
| `["evaluate", "Linear0 d=200 n=4096"]` | 1.007 | – | 0.150 | 0.151 |
| `["evaluate", "Linear0 d=50 n=1024"]` | 0.795 | ❌ | 0.014 | 0.011 |
| `["evaluate", "Linear0 d=50 n=4096"]` | 1.065 | ✅ | 0.054 | 0.057 |
| `["gen_samples", "DigitalNetB2 d=10 n=1024"]` | 1.074 | ✅ | 0.040 | 0.043 |
| `["gen_samples", "DigitalNetB2 d=10 n=16384"]` | 0.984 | – | 1.478 | 1.454 |
| `["gen_samples", "DigitalNetB2 d=10 n=256"]` | 1.204 | ✅ | 0.019 | 0.023 |
| `["gen_samples", "DigitalNetB2 d=10 n=4096"]` | 1.757 | ✅ | 0.171 | 0.300 |
| `["gen_samples", "DigitalNetB2 d=3 n=1024"]` | 0.861 | ❌ | 0.021 | 0.018 |
| `["gen_samples", "DigitalNetB2 d=3 n=16384"]` | 2.272 | ✅ | 0.209 | 0.475 |
| `["gen_samples", "DigitalNetB2 d=3 n=256"]` | 0.940 | ❌ | 0.007 | 0.007 |
| `["gen_samples", "DigitalNetB2 d=3 n=4096"]` | 1.062 | ✅ | 0.046 | 0.049 |
| `["gen_samples", "Halton d=10 n=1024"]` | 0.998 | – | 1.829 | 1.826 |
| `["gen_samples", "Halton d=10 n=16384"]` | 1.000 | – | 29.906 | 29.906 |
| `["gen_samples", "Halton d=10 n=256"]` | 1.002 | – | 0.457 | 0.458 |
| `["gen_samples", "Halton d=10 n=4096"]` | 0.999 | – | 7.330 | 7.323 |
| `["gen_samples", "Halton d=3 n=1024"]` | 1.001 | – | 0.558 | 0.558 |
| `["gen_samples", "Halton d=3 n=16384"]` | 0.999 | – | 9.078 | 9.069 |
| `["gen_samples", "Halton d=3 n=256"]` | 0.997 | – | 0.137 | 0.137 |
| `["gen_samples", "Halton d=3 n=4096"]` | 1.000 | – | 2.243 | 2.242 |
| `["gen_samples", "IIDStdUniform d=10 n=1024"]` | 0.847 | ❌ | 0.010 | 0.008 |
| `["gen_samples", "IIDStdUniform d=10 n=16384"]` | 0.990 | – | 0.589 | 0.583 |
| `["gen_samples", "IIDStdUniform d=10 n=256"]` | 1.183 | ✅ | 0.003 | 0.003 |
| `["gen_samples", "IIDStdUniform d=10 n=4096"]` | 1.122 | ✅ | 0.031 | 0.034 |
| `["gen_samples", "IIDStdUniform d=3 n=1024"]` | 1.049 | – | 0.003 | 0.003 |
| `["gen_samples", "IIDStdUniform d=3 n=16384"]` | 1.174 | ✅ | 0.033 | 0.039 |
| `["gen_samples", "IIDStdUniform d=3 n=256"]` | 0.971 | – | 0.001 | 0.001 |
| `["gen_samples", "IIDStdUniform d=3 n=4096"]` | 1.160 | ✅ | 0.010 | 0.011 |
| `["gen_samples", "Kronecker d=10 n=1024"]` | 1.011 | – | 0.074 | 0.075 |
| `["gen_samples", "Kronecker d=10 n=16384"]` | 1.014 | – | 1.835 | 1.861 |
| `["gen_samples", "Kronecker d=10 n=256"]` | 1.094 | ✅ | 0.019 | 0.021 |
| `["gen_samples", "Kronecker d=10 n=4096"]` | 1.004 | – | 0.327 | 0.329 |
| `["gen_samples", "Kronecker d=3 n=1024"]` | 0.989 | – | 0.022 | 0.022 |
| `["gen_samples", "Kronecker d=3 n=16384"]` | 0.999 | – | 0.407 | 0.407 |
| `["gen_samples", "Kronecker d=3 n=256"]` | 1.091 | ✅ | 0.006 | 0.006 |
| `["gen_samples", "Kronecker d=3 n=4096"]` | 1.005 | – | 0.104 | 0.105 |
| `["gen_samples", "Lattice d=10 n=1024"]` | 0.990 | – | 0.177 | 0.175 |
| `["gen_samples", "Lattice d=10 n=16384"]` | 0.995 | – | 4.272 | 4.251 |
| `["gen_samples", "Lattice d=10 n=256"]` | 1.040 | – | 0.047 | 0.049 |
| `["gen_samples", "Lattice d=10 n=4096"]` | 1.120 | ✅ | 0.948 | 1.062 |
| `["gen_samples", "Lattice d=3 n=1024"]` | 0.991 | – | 0.051 | 0.050 |
| `["gen_samples", "Lattice d=3 n=16384"]` | 0.992 | – | 1.217 | 1.207 |
| `["gen_samples", "Lattice d=3 n=256"]` | 0.997 | – | 0.013 | 0.013 |
| `["gen_samples", "Lattice d=3 n=4096"]` | 0.991 | – | 0.201 | 0.199 |
| `["integrate", "CubMCCLT AsianOption"]` | 1.004 | – | 3.521 | 3.536 |
| `["integrate", "CubMCCLT EuropeanOption"]` | 0.952 | – | 6.932 | 6.598 |
| `["integrate", "CubMCCLT Keister"]` | 1.124 | ✅ | 12.095 | 13.594 |
| `["integrate", "CubQMCLatticeG EuropeanOption"]` | 0.937 | ❌ | 2.126 | 1.993 |
| `["integrate", "CubQMCLatticeG Keister"]` | 1.015 | – | 0.418 | 0.424 |
| `["integrate", "CubQMCNetG AsianOption"]` | 0.943 | ❌ | 1.409 | 1.329 |
| `["integrate", "CubQMCNetG EuropeanOption"]` | 0.968 | – | 1.389 | 1.345 |
| `["integrate", "CubQMCNetG Keister"]` | 0.993 | – | 0.278 | 0.276 |
| `["integrate", "CubQMCNetGRep AsianOption"]` | 1.002 | – | 21.338 | 21.381 |
| `["integrate", "CubQMCNetGRep EuropeanOption"]` | 1.093 | ✅ | 20.967 | 22.908 |
| `["integrate", "CubQMCNetGRep Keister"]` | 1.008 | – | 3.344 | 3.370 |
| `["transform", "Gaussian d=10 n=1024"]` | 1.014 | – | 0.139 | 0.141 |
| `["transform", "Gaussian d=10 n=16384"]` | 1.009 | – | 2.633 | 2.658 |
| `["transform", "Gaussian d=10 n=256"]` | 0.952 | – | 0.033 | 0.032 |
| `["transform", "Gaussian d=10 n=4096"]` | 1.021 | – | 0.643 | 0.657 |
| `["transform", "Gaussian d=3 n=1024"]` | 0.992 | – | 0.038 | 0.037 |
| `["transform", "Gaussian d=3 n=16384"]` | 1.019 | – | 0.773 | 0.787 |
| `["transform", "Gaussian d=3 n=256"]` | 0.946 | ❌ | 0.010 | 0.010 |
| `["transform", "Gaussian d=3 n=4096"]` | 1.028 | – | 0.169 | 0.173 |
| `["transform", "Gaussian(dense) d=200 n=1024"]` | 0.999 | – | 4.344 | 4.342 |
| `["transform", "Gaussian(dense) d=200 n=4096"]` | 1.016 | – | 17.384 | 17.657 |
| `["transform", "Gaussian(dense) d=50 n=1024"]` | 0.929 | ❌ | 0.967 | 0.898 |
| `["transform", "Gaussian(dense) d=50 n=4096"]` | 0.988 | – | 3.607 | 3.565 |
| `["transform", "Gaussian(diag) d=200 n=1024"]` | 1.011 | – | 3.274 | 3.310 |
| `["transform", "Gaussian(diag) d=200 n=4096"]` | 1.009 | – | 13.157 | 13.277 |
| `["transform", "Gaussian(diag) d=50 n=1024"]` | 1.018 | – | 0.809 | 0.823 |
| `["transform", "Gaussian(diag) d=50 n=4096"]` | 1.013 | – | 3.269 | 3.312 |
| `["transform", "JohnsonsSU d=10 n=1024"]` | 0.984 | – | 0.222 | 0.218 |
| `["transform", "JohnsonsSU d=10 n=16384"]` | 1.005 | – | 3.861 | 3.882 |
| `["transform", "JohnsonsSU d=10 n=256"]` | 0.985 | – | 0.052 | 0.052 |
| `["transform", "JohnsonsSU d=10 n=4096"]` | 1.014 | – | 0.960 | 0.973 |
| `["transform", "StudentT d=10 n=1024"]` | 1.009 | – | 0.044 | 0.045 |
| `["transform", "StudentT d=10 n=16384"]` | 1.006 | – | 0.701 | 0.705 |
| `["transform", "StudentT d=10 n=256"]` | 1.015 | – | 0.012 | 0.012 |
| `["transform", "StudentT d=10 n=4096"]` | 1.008 | – | 0.177 | 0.178 |
