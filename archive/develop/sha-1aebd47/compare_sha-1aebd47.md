# Benchmark: `local` vs `db8aea61879a91b9a74110ae385ec820533261e5`

| | local (`local`) | reference (`db8aea61879a91b9a74110ae385ec820533261e5`) |
|---|---|---|
| commit | non gitrepo | non gitrepo |
| date | 2026-06-30T10:25:57.621 | 2026-06-30T10:27:34.104 |

**`ratio = reference time ÷ local time`**  
ratio `< 1` → local is **slower** ❌  |  ratio `> 1` → local is **faster** ✅

## Aggregate Summary

| metric | ratio | local total | reference total |
|:-------|------:|------------:|----------------:|
| matched benchmarks | 111 | — | — |
| weighted time ratio | 1.026 | 166.752 ms | 171.113 ms |
| weighted memory ratio | 1.000 | 121291.7 KiB | 121291.7 KiB |

| benchmark | ratio | verdict | local (ms) | reference (ms) |
|:----------|------:|:-------:|----------:|---------------:|
| `["evaluate", "BoxIntegral d=10 n=1024"]` | 1.051 | ✅ | 0.008 | 0.008 |
| `["evaluate", "BoxIntegral d=10 n=16384"]` | 1.116 | ✅ | 0.128 | 0.143 |
| `["evaluate", "BoxIntegral d=10 n=256"]` | 1.092 | ✅ | 0.003 | 0.003 |
| `["evaluate", "BoxIntegral d=10 n=4096"]` | 0.922 | ❌ | 0.038 | 0.035 |
| `["evaluate", "BoxIntegral d=200 n=1024"]` | 1.050 | ✅ | 0.042 | 0.044 |
| `["evaluate", "BoxIntegral d=200 n=4096"]` | 1.050 | – | 0.171 | 0.179 |
| `["evaluate", "BoxIntegral d=50 n=1024"]` | 1.241 | ✅ | 0.014 | 0.017 |
| `["evaluate", "BoxIntegral d=50 n=4096"]` | 0.998 | – | 0.067 | 0.067 |
| `["evaluate", "Genz(continuous) d=10 n=1024"]` | 1.066 | ✅ | 0.008 | 0.008 |
| `["evaluate", "Genz(continuous) d=10 n=16384"]` | 1.037 | – | 0.116 | 0.121 |
| `["evaluate", "Genz(continuous) d=10 n=256"]` | 1.000 | – | 0.003 | 0.003 |
| `["evaluate", "Genz(continuous) d=10 n=4096"]` | 0.987 | – | 0.036 | 0.036 |
| `["evaluate", "Genz(gaussian_peak) d=10 n=1024"]` | 1.025 | – | 0.008 | 0.008 |
| `["evaluate", "Genz(gaussian_peak) d=10 n=16384"]` | 0.991 | – | 0.130 | 0.129 |
| `["evaluate", "Genz(gaussian_peak) d=10 n=256"]` | 1.055 | ✅ | 0.003 | 0.003 |
| `["evaluate", "Genz(gaussian_peak) d=10 n=4096"]` | 0.918 | ❌ | 0.036 | 0.033 |
| `["evaluate", "Genz(gaussian_peak) d=200 n=1024"]` | 1.146 | ✅ | 0.045 | 0.052 |
| `["evaluate", "Genz(gaussian_peak) d=200 n=4096"]` | 0.992 | – | 0.176 | 0.174 |
| `["evaluate", "Genz(gaussian_peak) d=50 n=1024"]` | 1.081 | ✅ | 0.014 | 0.016 |
| `["evaluate", "Genz(gaussian_peak) d=50 n=4096"]` | 0.970 | – | 0.070 | 0.068 |
| `["evaluate", "Genz(oscillatory) n=1024"]` | 1.138 | ✅ | 0.008 | 0.009 |
| `["evaluate", "Genz(oscillatory) n=16384"]` | 1.017 | – | 0.228 | 0.231 |
| `["evaluate", "Genz(oscillatory) n=256"]` | 1.250 | ✅ | 0.002 | 0.003 |
| `["evaluate", "Genz(oscillatory) n=4096"]` | 1.102 | ✅ | 0.034 | 0.038 |
| `["evaluate", "Keister n=1024"]` | 0.986 | – | 0.011 | 0.011 |
| `["evaluate", "Keister n=16384"]` | 1.005 | – | 0.192 | 0.193 |
| `["evaluate", "Keister n=256"]` | 0.950 | – | 0.004 | 0.003 |
| `["evaluate", "Keister n=4096"]` | 1.097 | ✅ | 0.049 | 0.054 |
| `["evaluate", "Linear0 d=10 n=1024"]` | 1.036 | – | 0.002 | 0.002 |
| `["evaluate", "Linear0 d=10 n=16384"]` | 1.042 | – | 0.039 | 0.041 |
| `["evaluate", "Linear0 d=10 n=256"]` | 1.374 | ✅ | 0.001 | 0.001 |
| `["evaluate", "Linear0 d=10 n=4096"]` | 0.926 | ❌ | 0.011 | 0.010 |
| `["evaluate", "Linear0 d=200 n=1024"]` | 1.072 | ✅ | 0.032 | 0.035 |
| `["evaluate", "Linear0 d=200 n=4096"]` | 1.067 | ✅ | 0.150 | 0.160 |
| `["evaluate", "Linear0 d=50 n=1024"]` | 1.404 | ✅ | 0.008 | 0.012 |
| `["evaluate", "Linear0 d=50 n=4096"]` | 0.948 | ❌ | 0.042 | 0.040 |
| `["gen_samples", "DigitalNetB2 d=10 n=1024"]` | 0.993 | – | 0.038 | 0.037 |
| `["gen_samples", "DigitalNetB2 d=10 n=16384"]` | 1.008 | – | 1.426 | 1.437 |
| `["gen_samples", "DigitalNetB2 d=10 n=256"]` | 1.000 | – | 0.016 | 0.016 |
| `["gen_samples", "DigitalNetB2 d=10 n=4096"]` | 0.784 | ❌ | 0.349 | 0.274 |
| `["gen_samples", "DigitalNetB2 d=3 n=1024"]` | 0.870 | ❌ | 0.019 | 0.017 |
| `["gen_samples", "DigitalNetB2 d=3 n=16384"]` | 0.982 | – | 0.462 | 0.453 |
| `["gen_samples", "DigitalNetB2 d=3 n=256"]` | 1.099 | ✅ | 0.006 | 0.006 |
| `["gen_samples", "DigitalNetB2 d=3 n=4096"]` | 0.816 | ❌ | 0.063 | 0.051 |
| `["gen_samples", "Halton d=10 n=1024"]` | 1.006 | – | 0.720 | 0.724 |
| `["gen_samples", "Halton d=10 n=16384"]` | 1.001 | – | 12.502 | 12.519 |
| `["gen_samples", "Halton d=10 n=256"]` | 0.997 | – | 0.179 | 0.179 |
| `["gen_samples", "Halton d=10 n=4096"]` | 0.999 | – | 2.956 | 2.952 |
| `["gen_samples", "Halton d=3 n=1024"]` | 1.000 | – | 0.234 | 0.234 |
| `["gen_samples", "Halton d=3 n=16384"]` | 1.000 | – | 3.996 | 3.996 |
| `["gen_samples", "Halton d=3 n=256"]` | 0.844 | ❌ | 0.067 | 0.056 |
| `["gen_samples", "Halton d=3 n=4096"]` | 1.004 | – | 0.964 | 0.968 |
| `["gen_samples", "IIDStdUniform d=10 n=1024"]` | 0.913 | ❌ | 0.009 | 0.008 |
| `["gen_samples", "IIDStdUniform d=10 n=16384"]` | 1.056 | ✅ | 0.548 | 0.579 |
| `["gen_samples", "IIDStdUniform d=10 n=256"]` | 1.130 | ✅ | 0.002 | 0.003 |
| `["gen_samples", "IIDStdUniform d=10 n=4096"]` | 1.064 | ✅ | 0.031 | 0.033 |
| `["gen_samples", "IIDStdUniform d=3 n=1024"]` | 0.926 | ❌ | 0.003 | 0.003 |
| `["gen_samples", "IIDStdUniform d=3 n=16384"]` | 1.735 | ✅ | 0.039 | 0.068 |
| `["gen_samples", "IIDStdUniform d=3 n=256"]` | 1.085 | ✅ | 0.001 | 0.001 |
| `["gen_samples", "IIDStdUniform d=3 n=4096"]` | 0.964 | – | 0.010 | 0.009 |
| `["gen_samples", "Kronecker d=10 n=1024"]` | 0.989 | – | 0.024 | 0.024 |
| `["gen_samples", "Kronecker d=10 n=16384"]` | 1.025 | – | 0.817 | 0.838 |
| `["gen_samples", "Kronecker d=10 n=256"]` | 1.177 | ✅ | 0.006 | 0.007 |
| `["gen_samples", "Kronecker d=10 n=4096"]` | 1.073 | ✅ | 0.093 | 0.099 |
| `["gen_samples", "Kronecker d=3 n=1024"]` | 0.974 | – | 0.007 | 0.007 |
| `["gen_samples", "Kronecker d=3 n=16384"]` | 1.000 | – | 0.114 | 0.114 |
| `["gen_samples", "Kronecker d=3 n=256"]` | 0.987 | – | 0.002 | 0.002 |
| `["gen_samples", "Kronecker d=3 n=4096"]` | 0.986 | – | 0.029 | 0.028 |
| `["gen_samples", "Lattice d=10 n=1024"]` | 0.959 | – | 0.067 | 0.064 |
| `["gen_samples", "Lattice d=10 n=16384"]` | 1.011 | – | 2.416 | 2.443 |
| `["gen_samples", "Lattice d=10 n=256"]` | 0.905 | ❌ | 0.020 | 0.018 |
| `["gen_samples", "Lattice d=10 n=4096"]` | 1.027 | – | 0.592 | 0.608 |
| `["gen_samples", "Lattice d=3 n=1024"]` | 0.994 | – | 0.026 | 0.025 |
| `["gen_samples", "Lattice d=3 n=16384"]` | 1.012 | – | 0.785 | 0.794 |
| `["gen_samples", "Lattice d=3 n=256"]` | 1.016 | – | 0.007 | 0.007 |
| `["gen_samples", "Lattice d=3 n=4096"]` | 0.993 | – | 0.098 | 0.097 |
| `["integrate", "CubMCCLT AsianOption"]` | 1.015 | – | 3.613 | 3.669 |
| `["integrate", "CubMCCLT EuropeanOption"]` | 1.058 | ✅ | 6.459 | 6.834 |
| `["integrate", "CubMCCLT Keister"]` | 0.995 | – | 13.638 | 13.565 |
| `["integrate", "CubQMCLatticeG EuropeanOption"]` | 1.018 | – | 1.469 | 1.496 |
| `["integrate", "CubQMCLatticeG Keister"]` | 0.998 | – | 0.336 | 0.335 |
| `["integrate", "CubQMCNetG AsianOption"]` | 1.015 | – | 1.371 | 1.392 |
| `["integrate", "CubQMCNetG EuropeanOption"]` | 0.993 | – | 1.366 | 1.356 |
| `["integrate", "CubQMCNetG Keister"]` | 0.974 | – | 0.276 | 0.269 |
| `["integrate", "CubQMCNetGRep AsianOption"]` | 0.990 | – | 20.745 | 20.547 |
| `["integrate", "CubQMCNetGRep EuropeanOption"]` | 0.991 | – | 20.669 | 20.484 |
| `["integrate", "CubQMCNetGRep Keister"]` | 0.995 | – | 3.230 | 3.215 |
| `["transform", "Gaussian d=10 n=1024"]` | 1.096 | ✅ | 0.138 | 0.151 |
| `["transform", "Gaussian d=10 n=16384"]` | 1.086 | ✅ | 2.667 | 2.898 |
| `["transform", "Gaussian d=10 n=256"]` | 1.157 | ✅ | 0.031 | 0.036 |
| `["transform", "Gaussian d=10 n=4096"]` | 1.086 | ✅ | 0.661 | 0.718 |
| `["transform", "Gaussian d=3 n=1024"]` | 1.080 | ✅ | 0.037 | 0.040 |
| `["transform", "Gaussian d=3 n=16384"]` | 1.085 | ✅ | 0.796 | 0.863 |
| `["transform", "Gaussian d=3 n=256"]` | 1.454 | ✅ | 0.010 | 0.014 |
| `["transform", "Gaussian d=3 n=4096"]` | 1.034 | – | 0.178 | 0.184 |
| `["transform", "Gaussian(dense) d=200 n=1024"]` | 1.056 | ✅ | 5.512 | 5.822 |
| `["transform", "Gaussian(dense) d=200 n=4096"]` | 1.067 | ✅ | 18.166 | 19.387 |
| `["transform", "Gaussian(dense) d=50 n=1024"]` | 1.078 | ✅ | 0.976 | 1.052 |
| `["transform", "Gaussian(dense) d=50 n=4096"]` | 1.069 | ✅ | 4.501 | 4.814 |
| `["transform", "Gaussian(diag) d=200 n=1024"]` | 1.076 | ✅ | 3.358 | 3.614 |
| `["transform", "Gaussian(diag) d=200 n=4096"]` | 1.091 | ✅ | 14.216 | 15.513 |
| `["transform", "Gaussian(diag) d=50 n=1024"]` | 1.083 | ✅ | 0.828 | 0.897 |
| `["transform", "Gaussian(diag) d=50 n=4096"]` | 1.083 | ✅ | 3.343 | 3.620 |
| `["transform", "JohnsonsSU d=10 n=1024"]` | 0.993 | – | 0.217 | 0.216 |
| `["transform", "JohnsonsSU d=10 n=16384"]` | 1.011 | – | 3.867 | 3.910 |
| `["transform", "JohnsonsSU d=10 n=256"]` | 1.047 | – | 0.051 | 0.054 |
| `["transform", "JohnsonsSU d=10 n=4096"]` | 0.995 | – | 0.964 | 0.959 |
| `["transform", "StudentT d=10 n=1024"]` | 0.986 | – | 0.044 | 0.044 |
| `["transform", "StudentT d=10 n=16384"]` | 1.008 | – | 1.158 | 1.167 |
| `["transform", "StudentT d=10 n=256"]` | 1.012 | – | 0.012 | 0.012 |
| `["transform", "StudentT d=10 n=4096"]` | 0.999 | – | 0.177 | 0.177 |
