# Benchmark: `local` vs `aeae336f684030d259bcde66c16dc7418f82be52`

| | local (`local`) | reference (`aeae336f684030d259bcde66c16dc7418f82be52`) |
|---|---|---|
| commit | non gitrepo | non gitrepo |
| date | 2026-06-28T09:42:31.371 | 2026-06-28T09:44:05.359 |

**`ratio = reference time ÷ local time`**  
ratio `< 1` → local is **slower** ❌  |  ratio `> 1` → local is **faster** ✅

## Aggregate Summary

| metric | ratio | local total | reference total |
|:-------|------:|------------:|----------------:|
| matched benchmarks | 111 | — | — |
| weighted time ratio | 1.057 | 202.352 ms | 213.975 ms |
| weighted memory ratio | 1.000 | 173042.7 KiB | 173042.7 KiB |

| benchmark | ratio | verdict | local (ms) | reference (ms) |
|:----------|------:|:-------:|----------:|---------------:|
| `["evaluate", "BoxIntegral d=10 n=1024"]` | 0.962 | – | 0.010 | 0.009 |
| `["evaluate", "BoxIntegral d=10 n=16384"]` | 0.847 | ❌ | 0.150 | 0.127 |
| `["evaluate", "BoxIntegral d=10 n=256"]` | 1.085 | ✅ | 0.003 | 0.003 |
| `["evaluate", "BoxIntegral d=10 n=4096"]` | 0.872 | ❌ | 0.047 | 0.041 |
| `["evaluate", "BoxIntegral d=200 n=1024"]` | 1.104 | ✅ | 0.049 | 0.054 |
| `["evaluate", "BoxIntegral d=200 n=4096"]` | 1.022 | – | 0.172 | 0.175 |
| `["evaluate", "BoxIntegral d=50 n=1024"]` | 0.910 | ❌ | 0.019 | 0.017 |
| `["evaluate", "BoxIntegral d=50 n=4096"]` | 1.063 | ✅ | 0.081 | 0.087 |
| `["evaluate", "Genz(continuous) d=10 n=1024"]` | 0.909 | ❌ | 0.010 | 0.009 |
| `["evaluate", "Genz(continuous) d=10 n=16384"]` | 0.968 | – | 0.133 | 0.129 |
| `["evaluate", "Genz(continuous) d=10 n=256"]` | 0.946 | ❌ | 0.003 | 0.003 |
| `["evaluate", "Genz(continuous) d=10 n=4096"]` | 1.025 | – | 0.036 | 0.037 |
| `["evaluate", "Genz(gaussian_peak) d=10 n=1024"]` | 1.148 | ✅ | 0.009 | 0.010 |
| `["evaluate", "Genz(gaussian_peak) d=10 n=16384"]` | 0.945 | ❌ | 0.131 | 0.124 |
| `["evaluate", "Genz(gaussian_peak) d=10 n=256"]` | 0.956 | – | 0.003 | 0.003 |
| `["evaluate", "Genz(gaussian_peak) d=10 n=4096"]` | 0.942 | ❌ | 0.040 | 0.038 |
| `["evaluate", "Genz(gaussian_peak) d=200 n=1024"]` | 1.031 | – | 0.060 | 0.062 |
| `["evaluate", "Genz(gaussian_peak) d=200 n=4096"]` | 1.010 | – | 0.167 | 0.169 |
| `["evaluate", "Genz(gaussian_peak) d=50 n=1024"]` | 1.000 | – | 0.020 | 0.020 |
| `["evaluate", "Genz(gaussian_peak) d=50 n=4096"]` | 0.872 | ❌ | 0.088 | 0.077 |
| `["evaluate", "Genz(oscillatory) n=1024"]` | 0.982 | – | 0.010 | 0.010 |
| `["evaluate", "Genz(oscillatory) n=16384"]` | 1.003 | – | 0.226 | 0.227 |
| `["evaluate", "Genz(oscillatory) n=256"]` | 0.838 | ❌ | 0.003 | 0.003 |
| `["evaluate", "Genz(oscillatory) n=4096"]` | 0.904 | ❌ | 0.044 | 0.040 |
| `["evaluate", "Keister n=1024"]` | 1.017 | – | 0.013 | 0.013 |
| `["evaluate", "Keister n=16384"]` | 0.988 | – | 0.193 | 0.190 |
| `["evaluate", "Keister n=256"]` | 1.002 | – | 0.004 | 0.004 |
| `["evaluate", "Keister n=4096"]` | 1.039 | – | 0.054 | 0.056 |
| `["evaluate", "Linear0 d=10 n=1024"]` | 0.998 | – | 0.003 | 0.003 |
| `["evaluate", "Linear0 d=10 n=16384"]` | 0.971 | – | 0.052 | 0.050 |
| `["evaluate", "Linear0 d=10 n=256"]` | 1.042 | – | 0.001 | 0.001 |
| `["evaluate", "Linear0 d=10 n=4096"]` | 0.762 | ❌ | 0.017 | 0.013 |
| `["evaluate", "Linear0 d=200 n=1024"]` | 1.029 | – | 0.042 | 0.043 |
| `["evaluate", "Linear0 d=200 n=4096"]` | 0.942 | ❌ | 0.159 | 0.150 |
| `["evaluate", "Linear0 d=50 n=1024"]` | 1.021 | – | 0.011 | 0.011 |
| `["evaluate", "Linear0 d=50 n=4096"]` | 1.167 | ✅ | 0.048 | 0.056 |
| `["gen_samples", "DigitalNetB2 d=10 n=1024"]` | 1.049 | – | 0.041 | 0.043 |
| `["gen_samples", "DigitalNetB2 d=10 n=16384"]` | 1.012 | – | 1.449 | 1.466 |
| `["gen_samples", "DigitalNetB2 d=10 n=256"]` | 0.950 | – | 0.020 | 0.019 |
| `["gen_samples", "DigitalNetB2 d=10 n=4096"]` | 1.126 | ✅ | 0.307 | 0.345 |
| `["gen_samples", "DigitalNetB2 d=3 n=1024"]` | 1.153 | ✅ | 0.016 | 0.018 |
| `["gen_samples", "DigitalNetB2 d=3 n=16384"]` | 1.027 | – | 0.452 | 0.464 |
| `["gen_samples", "DigitalNetB2 d=3 n=256"]` | 1.085 | ✅ | 0.007 | 0.007 |
| `["gen_samples", "DigitalNetB2 d=3 n=4096"]` | 1.203 | ✅ | 0.048 | 0.057 |
| `["gen_samples", "Halton d=10 n=1024"]` | 0.988 | – | 1.852 | 1.830 |
| `["gen_samples", "Halton d=10 n=16384"]` | 0.999 | – | 29.929 | 29.914 |
| `["gen_samples", "Halton d=10 n=256"]` | 0.999 | – | 0.457 | 0.457 |
| `["gen_samples", "Halton d=10 n=4096"]` | 1.000 | – | 7.326 | 7.328 |
| `["gen_samples", "Halton d=3 n=1024"]` | 1.002 | – | 0.558 | 0.559 |
| `["gen_samples", "Halton d=3 n=16384"]` | 1.000 | – | 9.072 | 9.073 |
| `["gen_samples", "Halton d=3 n=256"]` | 1.005 | – | 0.140 | 0.141 |
| `["gen_samples", "Halton d=3 n=4096"]` | 0.998 | – | 2.248 | 2.244 |
| `["gen_samples", "IIDStdUniform d=10 n=1024"]` | 1.138 | ✅ | 0.009 | 0.010 |
| `["gen_samples", "IIDStdUniform d=10 n=16384"]` | 0.996 | – | 0.576 | 0.573 |
| `["gen_samples", "IIDStdUniform d=10 n=256"]` | 0.985 | – | 0.003 | 0.003 |
| `["gen_samples", "IIDStdUniform d=10 n=4096"]` | 1.877 | ✅ | 0.028 | 0.052 |
| `["gen_samples", "IIDStdUniform d=3 n=1024"]` | 1.221 | ✅ | 0.003 | 0.004 |
| `["gen_samples", "IIDStdUniform d=3 n=16384"]` | 1.034 | – | 0.043 | 0.044 |
| `["gen_samples", "IIDStdUniform d=3 n=256"]` | 0.954 | – | 0.001 | 0.001 |
| `["gen_samples", "IIDStdUniform d=3 n=4096"]` | 1.113 | ✅ | 0.009 | 0.011 |
| `["gen_samples", "Kronecker d=10 n=1024"]` | 0.990 | – | 0.075 | 0.074 |
| `["gen_samples", "Kronecker d=10 n=16384"]` | 1.000 | – | 1.844 | 1.845 |
| `["gen_samples", "Kronecker d=10 n=256"]` | 1.031 | – | 0.018 | 0.019 |
| `["gen_samples", "Kronecker d=10 n=4096"]` | 1.008 | – | 0.325 | 0.328 |
| `["gen_samples", "Kronecker d=3 n=1024"]` | 1.021 | – | 0.022 | 0.022 |
| `["gen_samples", "Kronecker d=3 n=16384"]` | 1.008 | – | 0.405 | 0.408 |
| `["gen_samples", "Kronecker d=3 n=256"]` | 1.006 | – | 0.006 | 0.006 |
| `["gen_samples", "Kronecker d=3 n=4096"]` | 1.010 | – | 0.094 | 0.095 |
| `["gen_samples", "Lattice d=10 n=1024"]` | 1.015 | – | 0.175 | 0.178 |
| `["gen_samples", "Lattice d=10 n=16384"]` | 0.992 | – | 4.306 | 4.274 |
| `["gen_samples", "Lattice d=10 n=256"]` | 0.967 | – | 0.048 | 0.046 |
| `["gen_samples", "Lattice d=10 n=4096"]` | 1.001 | – | 1.060 | 1.061 |
| `["gen_samples", "Lattice d=3 n=1024"]` | 0.996 | – | 0.050 | 0.050 |
| `["gen_samples", "Lattice d=3 n=16384"]` | 0.980 | – | 1.237 | 1.213 |
| `["gen_samples", "Lattice d=3 n=256"]` | 1.030 | – | 0.013 | 0.014 |
| `["gen_samples", "Lattice d=3 n=4096"]` | 0.999 | – | 0.199 | 0.199 |
| `["integrate", "CubMCCLT AsianOption"]` | 0.985 | – | 3.632 | 3.577 |
| `["integrate", "CubMCCLT EuropeanOption"]` | 1.004 | – | 7.346 | 7.378 |
| `["integrate", "CubMCCLT Keister"]` | 1.176 | ✅ | 12.569 | 14.775 |
| `["integrate", "CubQMCLatticeG EuropeanOption"]` | 0.781 | ❌ | 2.719 | 2.124 |
| `["integrate", "CubQMCLatticeG Keister"]` | 1.003 | – | 0.410 | 0.411 |
| `["integrate", "CubQMCNetG AsianOption"]` | 1.085 | ✅ | 1.323 | 1.435 |
| `["integrate", "CubQMCNetG EuropeanOption"]` | 1.084 | ✅ | 1.311 | 1.421 |
| `["integrate", "CubQMCNetG Keister"]` | 0.937 | ❌ | 0.294 | 0.275 |
| `["integrate", "CubQMCNetGRep AsianOption"]` | 1.172 | ✅ | 22.771 | 26.687 |
| `["integrate", "CubQMCNetGRep EuropeanOption"]` | 1.174 | ✅ | 22.489 | 26.403 |
| `["integrate", "CubQMCNetGRep Keister"]` | 0.998 | – | 3.355 | 3.350 |
| `["transform", "Gaussian d=10 n=1024"]` | 1.041 | – | 0.142 | 0.147 |
| `["transform", "Gaussian d=10 n=16384"]` | 1.000 | – | 2.627 | 2.628 |
| `["transform", "Gaussian d=10 n=256"]` | 0.993 | – | 0.033 | 0.032 |
| `["transform", "Gaussian d=10 n=4096"]` | 1.002 | – | 0.647 | 0.648 |
| `["transform", "Gaussian d=3 n=1024"]` | 0.971 | – | 0.041 | 0.039 |
| `["transform", "Gaussian d=3 n=16384"]` | 0.997 | – | 0.780 | 0.778 |
| `["transform", "Gaussian d=3 n=256"]` | 0.922 | ❌ | 0.011 | 0.010 |
| `["transform", "Gaussian d=3 n=4096"]` | 0.979 | – | 0.179 | 0.175 |
| `["transform", "Gaussian(dense) d=200 n=1024"]` | 1.013 | – | 4.296 | 4.350 |
| `["transform", "Gaussian(dense) d=200 n=4096"]` | 1.015 | – | 17.706 | 17.972 |
| `["transform", "Gaussian(dense) d=50 n=1024"]` | 1.084 | ✅ | 0.902 | 0.978 |
| `["transform", "Gaussian(dense) d=50 n=4096"]` | 1.006 | – | 3.600 | 3.620 |
| `["transform", "Gaussian(diag) d=200 n=1024"]` | 1.001 | – | 3.278 | 3.281 |
| `["transform", "Gaussian(diag) d=200 n=4096"]` | 1.081 | ✅ | 13.188 | 14.259 |
| `["transform", "Gaussian(diag) d=50 n=1024"]` | 0.997 | – | 0.812 | 0.810 |
| `["transform", "Gaussian(diag) d=50 n=4096"]` | 1.001 | – | 3.285 | 3.290 |
| `["transform", "JohnsonsSU d=10 n=1024"]` | 0.995 | – | 0.222 | 0.221 |
| `["transform", "JohnsonsSU d=10 n=16384"]` | 1.019 | – | 3.858 | 3.931 |
| `["transform", "JohnsonsSU d=10 n=256"]` | 0.925 | ❌ | 0.056 | 0.051 |
| `["transform", "JohnsonsSU d=10 n=4096"]` | 0.997 | – | 0.960 | 0.957 |
| `["transform", "StudentT d=10 n=1024"]` | 1.019 | – | 0.044 | 0.045 |
| `["transform", "StudentT d=10 n=16384"]` | 1.671 | ✅ | 0.701 | 1.172 |
| `["transform", "StudentT d=10 n=256"]` | 1.002 | – | 0.012 | 0.012 |
| `["transform", "StudentT d=10 n=4096"]` | 1.007 | – | 0.177 | 0.178 |
