# Benchmark: `local` vs `c7544f36d27ba344cbc633f0b798b29abe4e9fdf`

| | local (`local`) | reference (`c7544f36d27ba344cbc633f0b798b29abe4e9fdf`) |
|---|---|---|
| commit | non gitrepo | non gitrepo |
| date | 2026-06-26T13:32:27.158 | 2026-06-26T13:34:32.038 |

**`ratio = reference time ÷ local time`**  
ratio `< 1` → local is **slower** ❌  |  ratio `> 1` → local is **faster** ✅

## Aggregate Summary

| metric | ratio | local total | reference total |
|:-------|------:|------------:|----------------:|
| matched benchmarks | 111 | — | — |
| weighted time ratio | 0.998 | 207.296 ms | 206.983 ms |
| weighted memory ratio | 1.000 | 173029.9 KiB | 173029.9 KiB |

| benchmark | ratio | verdict | local (ms) | reference (ms) |
|:----------|------:|:-------:|----------:|---------------:|
| `["evaluate", "BoxIntegral d=10 n=1024"]` | 0.973 | – | 0.008 | 0.008 |
| `["evaluate", "BoxIntegral d=10 n=16384"]` | 1.099 | ✅ | 0.127 | 0.140 |
| `["evaluate", "BoxIntegral d=10 n=256"]` | 1.018 | – | 0.003 | 0.003 |
| `["evaluate", "BoxIntegral d=10 n=4096"]` | 1.091 | ✅ | 0.032 | 0.035 |
| `["evaluate", "BoxIntegral d=200 n=1024"]` | 1.034 | – | 0.030 | 0.031 |
| `["evaluate", "BoxIntegral d=200 n=4096"]` | 1.010 | – | 0.211 | 0.213 |
| `["evaluate", "BoxIntegral d=50 n=1024"]` | 1.005 | – | 0.013 | 0.013 |
| `["evaluate", "BoxIntegral d=50 n=4096"]` | 1.174 | ✅ | 0.070 | 0.082 |
| `["evaluate", "Genz(continuous) d=10 n=1024"]` | 0.969 | – | 0.008 | 0.007 |
| `["evaluate", "Genz(continuous) d=10 n=16384"]` | 1.174 | ✅ | 0.121 | 0.142 |
| `["evaluate", "Genz(continuous) d=10 n=256"]` | 1.055 | ✅ | 0.003 | 0.003 |
| `["evaluate", "Genz(continuous) d=10 n=4096"]` | 1.014 | – | 0.030 | 0.030 |
| `["evaluate", "Genz(gaussian_peak) d=10 n=1024"]` | 0.990 | – | 0.008 | 0.008 |
| `["evaluate", "Genz(gaussian_peak) d=10 n=16384"]` | 1.062 | ✅ | 0.119 | 0.127 |
| `["evaluate", "Genz(gaussian_peak) d=10 n=256"]` | 1.094 | ✅ | 0.003 | 0.003 |
| `["evaluate", "Genz(gaussian_peak) d=10 n=4096"]` | 0.974 | – | 0.031 | 0.030 |
| `["evaluate", "Genz(gaussian_peak) d=200 n=1024"]` | 1.014 | – | 0.034 | 0.034 |
| `["evaluate", "Genz(gaussian_peak) d=200 n=4096"]` | 1.038 | – | 0.211 | 0.219 |
| `["evaluate", "Genz(gaussian_peak) d=50 n=1024"]` | 0.968 | – | 0.013 | 0.013 |
| `["evaluate", "Genz(gaussian_peak) d=50 n=4096"]` | 0.971 | – | 0.072 | 0.070 |
| `["evaluate", "Genz(oscillatory) n=1024"]` | 1.502 | ✅ | 0.008 | 0.012 |
| `["evaluate", "Genz(oscillatory) n=16384"]` | 1.092 | ✅ | 0.117 | 0.128 |
| `["evaluate", "Genz(oscillatory) n=256"]` | 1.085 | ✅ | 0.003 | 0.003 |
| `["evaluate", "Genz(oscillatory) n=4096"]` | 1.010 | – | 0.030 | 0.031 |
| `["evaluate", "Keister n=1024"]` | 0.999 | – | 0.011 | 0.011 |
| `["evaluate", "Keister n=16384"]` | 0.970 | – | 0.163 | 0.159 |
| `["evaluate", "Keister n=256"]` | 1.014 | – | 0.004 | 0.004 |
| `["evaluate", "Keister n=4096"]` | 1.070 | ✅ | 0.048 | 0.051 |
| `["evaluate", "Linear0 d=10 n=1024"]` | 1.001 | – | 0.002 | 0.002 |
| `["evaluate", "Linear0 d=10 n=16384"]` | 1.048 | – | 0.044 | 0.046 |
| `["evaluate", "Linear0 d=10 n=256"]` | 1.065 | ✅ | 0.001 | 0.001 |
| `["evaluate", "Linear0 d=10 n=4096"]` | 1.267 | ✅ | 0.010 | 0.012 |
| `["evaluate", "Linear0 d=200 n=1024"]` | 0.919 | ❌ | 0.027 | 0.024 |
| `["evaluate", "Linear0 d=200 n=4096"]` | 0.997 | – | 0.188 | 0.188 |
| `["evaluate", "Linear0 d=50 n=1024"]` | 0.941 | ❌ | 0.007 | 0.007 |
| `["evaluate", "Linear0 d=50 n=4096"]` | 1.223 | ✅ | 0.052 | 0.063 |
| `["gen_samples", "DigitalNetB2 d=10 n=1024"]` | 0.996 | – | 0.039 | 0.039 |
| `["gen_samples", "DigitalNetB2 d=10 n=16384"]` | 0.970 | – | 1.536 | 1.490 |
| `["gen_samples", "DigitalNetB2 d=10 n=256"]` | 0.794 | ❌ | 0.022 | 0.018 |
| `["gen_samples", "DigitalNetB2 d=10 n=4096"]` | 0.430 | ❌ | 0.375 | 0.161 |
| `["gen_samples", "DigitalNetB2 d=3 n=1024"]` | 0.960 | – | 0.017 | 0.016 |
| `["gen_samples", "DigitalNetB2 d=3 n=16384"]` | 0.911 | ❌ | 0.485 | 0.442 |
| `["gen_samples", "DigitalNetB2 d=3 n=256"]` | 1.074 | ✅ | 0.007 | 0.007 |
| `["gen_samples", "DigitalNetB2 d=3 n=4096"]` | 0.992 | – | 0.049 | 0.049 |
| `["gen_samples", "Halton d=10 n=1024"]` | 0.999 | – | 1.453 | 1.451 |
| `["gen_samples", "Halton d=10 n=16384"]` | 1.001 | – | 23.627 | 23.660 |
| `["gen_samples", "Halton d=10 n=256"]` | 0.994 | – | 0.396 | 0.394 |
| `["gen_samples", "Halton d=10 n=4096"]` | 0.996 | – | 5.721 | 5.697 |
| `["gen_samples", "Halton d=3 n=1024"]` | 0.999 | – | 0.457 | 0.457 |
| `["gen_samples", "Halton d=3 n=16384"]` | 0.979 | – | 8.156 | 7.988 |
| `["gen_samples", "Halton d=3 n=256"]` | 1.015 | – | 0.110 | 0.112 |
| `["gen_samples", "Halton d=3 n=4096"]` | 0.998 | – | 1.912 | 1.908 |
| `["gen_samples", "IIDStdUniform d=10 n=1024"]` | 1.056 | ✅ | 0.008 | 0.009 |
| `["gen_samples", "IIDStdUniform d=10 n=16384"]` | 1.003 | – | 0.640 | 0.642 |
| `["gen_samples", "IIDStdUniform d=10 n=256"]` | 0.887 | ❌ | 0.003 | 0.003 |
| `["gen_samples", "IIDStdUniform d=10 n=4096"]` | 0.585 | ❌ | 0.045 | 0.026 |
| `["gen_samples", "IIDStdUniform d=3 n=1024"]` | 0.992 | – | 0.004 | 0.004 |
| `["gen_samples", "IIDStdUniform d=3 n=16384"]` | 0.184 | ❌ | 0.174 | 0.032 |
| `["gen_samples", "IIDStdUniform d=3 n=256"]` | 0.903 | ❌ | 0.002 | 0.001 |
| `["gen_samples", "IIDStdUniform d=3 n=4096"]` | 0.891 | ❌ | 0.011 | 0.009 |
| `["gen_samples", "Kronecker d=10 n=1024"]` | 1.037 | – | 0.073 | 0.075 |
| `["gen_samples", "Kronecker d=10 n=16384"]` | 1.007 | – | 1.928 | 1.940 |
| `["gen_samples", "Kronecker d=10 n=256"]` | 1.001 | – | 0.019 | 0.019 |
| `["gen_samples", "Kronecker d=10 n=4096"]` | 0.750 | ❌ | 0.466 | 0.349 |
| `["gen_samples", "Kronecker d=3 n=1024"]` | 0.992 | – | 0.022 | 0.022 |
| `["gen_samples", "Kronecker d=3 n=16384"]` | 1.018 | – | 0.418 | 0.425 |
| `["gen_samples", "Kronecker d=3 n=256"]` | 1.011 | – | 0.006 | 0.006 |
| `["gen_samples", "Kronecker d=3 n=4096"]` | 0.988 | – | 0.098 | 0.097 |
| `["gen_samples", "Lattice d=10 n=1024"]` | 1.009 | – | 0.197 | 0.198 |
| `["gen_samples", "Lattice d=10 n=16384"]` | 0.995 | – | 4.716 | 4.694 |
| `["gen_samples", "Lattice d=10 n=256"]` | 0.999 | – | 0.050 | 0.050 |
| `["gen_samples", "Lattice d=10 n=4096"]` | 1.010 | – | 1.168 | 1.180 |
| `["gen_samples", "Lattice d=3 n=1024"]` | 0.993 | – | 0.057 | 0.056 |
| `["gen_samples", "Lattice d=3 n=16384"]` | 0.989 | – | 1.363 | 1.349 |
| `["gen_samples", "Lattice d=3 n=256"]` | 0.804 | ❌ | 0.019 | 0.015 |
| `["gen_samples", "Lattice d=3 n=4096"]` | 1.008 | – | 0.224 | 0.226 |
| `["integrate", "CubMCCLT AsianOption"]` | 0.998 | – | 3.648 | 3.641 |
| `["integrate", "CubMCCLT EuropeanOption"]` | 1.060 | ✅ | 7.100 | 7.526 |
| `["integrate", "CubMCCLT Keister"]` | 1.025 | – | 13.942 | 14.291 |
| `["integrate", "CubQMCLatticeG EuropeanOption"]` | 1.030 | – | 2.170 | 2.235 |
| `["integrate", "CubQMCLatticeG Keister"]` | 1.015 | – | 0.432 | 0.438 |
| `["integrate", "CubQMCNetG AsianOption"]` | 1.054 | ✅ | 1.332 | 1.404 |
| `["integrate", "CubQMCNetG EuropeanOption"]` | 1.002 | – | 1.336 | 1.338 |
| `["integrate", "CubQMCNetG Keister"]` | 0.994 | – | 0.272 | 0.270 |
| `["integrate", "CubQMCNetGRep AsianOption"]` | 1.008 | – | 26.414 | 26.626 |
| `["integrate", "CubQMCNetGRep EuropeanOption"]` | 0.996 | – | 26.408 | 26.294 |
| `["integrate", "CubQMCNetGRep Keister"]` | 0.991 | – | 3.487 | 3.457 |
| `["transform", "Gaussian d=10 n=1024"]` | 0.984 | – | 0.124 | 0.122 |
| `["transform", "Gaussian d=10 n=16384"]` | 0.997 | – | 2.753 | 2.744 |
| `["transform", "Gaussian d=10 n=256"]` | 0.989 | – | 0.030 | 0.029 |
| `["transform", "Gaussian d=10 n=4096"]` | 1.159 | ✅ | 0.563 | 0.652 |
| `["transform", "Gaussian d=3 n=1024"]` | 1.112 | ✅ | 0.036 | 0.040 |
| `["transform", "Gaussian d=3 n=16384"]` | 1.069 | ✅ | 0.725 | 0.775 |
| `["transform", "Gaussian d=3 n=256"]` | 0.984 | – | 0.009 | 0.009 |
| `["transform", "Gaussian d=3 n=4096"]` | 0.957 | – | 0.154 | 0.147 |
| `["transform", "Gaussian(dense) d=200 n=1024"]` | 0.937 | ❌ | 5.069 | 4.750 |
| `["transform", "Gaussian(dense) d=200 n=4096"]` | 0.996 | – | 19.144 | 19.075 |
| `["transform", "Gaussian(dense) d=50 n=1024"]` | 0.993 | – | 0.927 | 0.921 |
| `["transform", "Gaussian(dense) d=50 n=4096"]` | 1.007 | – | 3.916 | 3.945 |
| `["transform", "Gaussian(diag) d=200 n=1024"]` | 0.986 | – | 3.477 | 3.429 |
| `["transform", "Gaussian(diag) d=200 n=4096"]` | 0.976 | – | 15.122 | 14.765 |
| `["transform", "Gaussian(diag) d=50 n=1024"]` | 0.993 | – | 0.780 | 0.774 |
| `["transform", "Gaussian(diag) d=50 n=4096"]` | 0.994 | – | 3.473 | 3.452 |
| `["transform", "JohnsonsSU d=10 n=1024"]` | 1.022 | – | 0.195 | 0.199 |
| `["transform", "JohnsonsSU d=10 n=16384"]` | 1.005 | – | 3.847 | 3.868 |
| `["transform", "JohnsonsSU d=10 n=256"]` | 1.006 | – | 0.048 | 0.049 |
| `["transform", "JohnsonsSU d=10 n=4096"]` | 1.056 | ✅ | 0.854 | 0.902 |
| `["transform", "StudentT d=10 n=1024"]` | 0.986 | – | 0.050 | 0.050 |
| `["transform", "StudentT d=10 n=16384"]` | 0.975 | – | 1.312 | 1.280 |
| `["transform", "StudentT d=10 n=256"]` | 0.996 | – | 0.014 | 0.013 |
| `["transform", "StudentT d=10 n=4096"]` | 1.001 | – | 0.199 | 0.199 |
