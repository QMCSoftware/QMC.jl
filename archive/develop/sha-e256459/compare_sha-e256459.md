# Benchmark: `local` vs `69111faa57f428551469ce942e844bf430c24e99`

| | local (`local`) | reference (`69111faa57f428551469ce942e844bf430c24e99`) |
|---|---|---|
| commit | non gitrepo | non gitrepo |
| date | 2026-06-19T02:18:44.034 | 2026-06-19T02:20:26.744 |

**`ratio = reference time ÷ local time`**  
ratio `< 1` → local is **slower** ❌  |  ratio `> 1` → local is **faster** ✅

## Aggregate Summary

| metric | ratio | local total | reference total |
|:-------|------:|------------:|----------------:|
| matched benchmarks | 111 | — | — |
| weighted time ratio | 1.028 | 195.250 ms | 200.689 ms |
| weighted memory ratio | 1.000 | 177946.0 KiB | 177951.3 KiB |

| benchmark | ratio | verdict | local (ms) | reference (ms) |
|:----------|------:|:-------:|----------:|---------------:|
| `["evaluate", "BoxIntegral d=10 n=1024"]` | 0.968 | – | 0.008 | 0.008 |
| `["evaluate", "BoxIntegral d=10 n=16384"]` | 0.975 | – | 0.137 | 0.133 |
| `["evaluate", "BoxIntegral d=10 n=256"]` | 0.990 | – | 0.003 | 0.003 |
| `["evaluate", "BoxIntegral d=10 n=4096"]` | 0.967 | – | 0.035 | 0.034 |
| `["evaluate", "BoxIntegral d=200 n=1024"]` | 1.003 | – | 0.032 | 0.032 |
| `["evaluate", "BoxIntegral d=200 n=4096"]` | 1.006 | – | 0.211 | 0.213 |
| `["evaluate", "BoxIntegral d=50 n=1024"]` | 1.010 | – | 0.012 | 0.013 |
| `["evaluate", "BoxIntegral d=50 n=4096"]` | 0.986 | – | 0.072 | 0.071 |
| `["evaluate", "Genz(continuous) d=10 n=1024"]` | 1.009 | – | 0.007 | 0.007 |
| `["evaluate", "Genz(continuous) d=10 n=16384"]` | 0.996 | – | 0.120 | 0.120 |
| `["evaluate", "Genz(continuous) d=10 n=256"]` | 1.012 | – | 0.003 | 0.003 |
| `["evaluate", "Genz(continuous) d=10 n=4096"]` | 1.036 | – | 0.030 | 0.031 |
| `["evaluate", "Genz(gaussian_peak) d=10 n=1024"]` | 0.988 | – | 0.007 | 0.007 |
| `["evaluate", "Genz(gaussian_peak) d=10 n=16384"]` | 1.025 | – | 0.116 | 0.119 |
| `["evaluate", "Genz(gaussian_peak) d=10 n=256"]` | 1.013 | – | 0.003 | 0.003 |
| `["evaluate", "Genz(gaussian_peak) d=10 n=4096"]` | 0.948 | ❌ | 0.032 | 0.030 |
| `["evaluate", "Genz(gaussian_peak) d=200 n=1024"]` | 1.012 | – | 0.034 | 0.034 |
| `["evaluate", "Genz(gaussian_peak) d=200 n=4096"]` | 0.998 | – | 0.209 | 0.208 |
| `["evaluate", "Genz(gaussian_peak) d=50 n=1024"]` | 0.990 | – | 0.012 | 0.012 |
| `["evaluate", "Genz(gaussian_peak) d=50 n=4096"]` | 1.006 | – | 0.070 | 0.071 |
| `["evaluate", "Genz(oscillatory) n=1024"]` | 0.979 | – | 0.008 | 0.008 |
| `["evaluate", "Genz(oscillatory) n=16384"]` | 0.976 | – | 0.115 | 0.113 |
| `["evaluate", "Genz(oscillatory) n=256"]` | 0.991 | – | 0.003 | 0.003 |
| `["evaluate", "Genz(oscillatory) n=4096"]` | 1.001 | – | 0.030 | 0.030 |
| `["evaluate", "Keister n=1024"]` | 0.994 | – | 0.011 | 0.011 |
| `["evaluate", "Keister n=16384"]` | 1.002 | – | 0.157 | 0.157 |
| `["evaluate", "Keister n=256"]` | 1.003 | – | 0.004 | 0.004 |
| `["evaluate", "Keister n=4096"]` | 0.917 | ❌ | 0.048 | 0.044 |
| `["evaluate", "Linear0 d=10 n=1024"]` | 0.999 | – | 0.002 | 0.002 |
| `["evaluate", "Linear0 d=10 n=16384"]` | 0.970 | – | 0.043 | 0.042 |
| `["evaluate", "Linear0 d=10 n=256"]` | 0.996 | – | 0.001 | 0.001 |
| `["evaluate", "Linear0 d=10 n=4096"]` | 0.971 | – | 0.010 | 0.009 |
| `["evaluate", "Linear0 d=200 n=1024"]` | 0.940 | ❌ | 0.028 | 0.026 |
| `["evaluate", "Linear0 d=200 n=4096"]` | 1.001 | – | 0.187 | 0.187 |
| `["evaluate", "Linear0 d=50 n=1024"]` | 1.009 | – | 0.006 | 0.006 |
| `["evaluate", "Linear0 d=50 n=4096"]` | 0.999 | – | 0.047 | 0.047 |
| `["gen_samples", "DigitalNetB2 d=10 n=1024"]` | 0.937 | ❌ | 0.041 | 0.039 |
| `["gen_samples", "DigitalNetB2 d=10 n=16384"]` | 1.011 | – | 1.461 | 1.476 |
| `["gen_samples", "DigitalNetB2 d=10 n=256"]` | 0.986 | – | 0.018 | 0.017 |
| `["gen_samples", "DigitalNetB2 d=10 n=4096"]` | 1.035 | – | 0.362 | 0.374 |
| `["gen_samples", "DigitalNetB2 d=3 n=1024"]` | 0.963 | – | 0.016 | 0.016 |
| `["gen_samples", "DigitalNetB2 d=3 n=16384"]` | 0.987 | – | 0.377 | 0.372 |
| `["gen_samples", "DigitalNetB2 d=3 n=256"]` | 1.012 | – | 0.007 | 0.007 |
| `["gen_samples", "DigitalNetB2 d=3 n=4096"]` | 0.988 | – | 0.047 | 0.046 |
| `["gen_samples", "Halton d=10 n=1024"]` | 0.943 | ❌ | 1.538 | 1.450 |
| `["gen_samples", "Halton d=10 n=16384"]` | 0.901 | ❌ | 26.187 | 23.606 |
| `["gen_samples", "Halton d=10 n=256"]` | 1.063 | ✅ | 0.373 | 0.396 |
| `["gen_samples", "Halton d=10 n=4096"]` | 0.897 | ❌ | 6.333 | 5.682 |
| `["gen_samples", "Halton d=3 n=1024"]` | 0.906 | ❌ | 0.503 | 0.455 |
| `["gen_samples", "Halton d=3 n=16384"]` | 0.918 | ❌ | 8.708 | 7.989 |
| `["gen_samples", "Halton d=3 n=256"]` | 0.895 | ❌ | 0.122 | 0.109 |
| `["gen_samples", "Halton d=3 n=4096"]` | 0.912 | ❌ | 2.095 | 1.910 |
| `["gen_samples", "IIDStdUniform d=10 n=1024"]` | 0.796 | ❌ | 0.010 | 0.008 |
| `["gen_samples", "IIDStdUniform d=10 n=16384"]` | 0.944 | ❌ | 0.604 | 0.570 |
| `["gen_samples", "IIDStdUniform d=10 n=256"]` | 0.961 | – | 0.003 | 0.003 |
| `["gen_samples", "IIDStdUniform d=10 n=4096"]` | 0.422 | ❌ | 0.061 | 0.026 |
| `["gen_samples", "IIDStdUniform d=3 n=1024"]` | 1.075 | ✅ | 0.003 | 0.003 |
| `["gen_samples", "IIDStdUniform d=3 n=16384"]` | 1.237 | ✅ | 0.031 | 0.039 |
| `["gen_samples", "IIDStdUniform d=3 n=256"]` | 1.032 | – | 0.001 | 0.001 |
| `["gen_samples", "IIDStdUniform d=3 n=4096"]` | 0.822 | ❌ | 0.011 | 0.009 |
| `["gen_samples", "Kronecker d=10 n=1024"]` | 0.979 | – | 0.076 | 0.074 |
| `["gen_samples", "Kronecker d=10 n=16384"]` | 1.006 | – | 1.912 | 1.923 |
| `["gen_samples", "Kronecker d=10 n=256"]` | 0.999 | – | 0.019 | 0.019 |
| `["gen_samples", "Kronecker d=10 n=4096"]` | 0.928 | ❌ | 0.369 | 0.343 |
| `["gen_samples", "Kronecker d=3 n=1024"]` | 1.010 | – | 0.022 | 0.023 |
| `["gen_samples", "Kronecker d=3 n=16384"]` | 1.019 | – | 0.425 | 0.434 |
| `["gen_samples", "Kronecker d=3 n=256"]` | 1.018 | – | 0.006 | 0.006 |
| `["gen_samples", "Kronecker d=3 n=4096"]` | 0.999 | – | 0.100 | 0.100 |
| `["gen_samples", "Lattice d=10 n=1024"]` | 1.000 | – | 0.196 | 0.196 |
| `["gen_samples", "Lattice d=10 n=16384"]` | 0.999 | – | 4.619 | 4.615 |
| `["gen_samples", "Lattice d=10 n=256"]` | 1.005 | – | 0.050 | 0.050 |
| `["gen_samples", "Lattice d=10 n=4096"]` | 0.982 | – | 1.174 | 1.154 |
| `["gen_samples", "Lattice d=3 n=1024"]` | 1.016 | – | 0.056 | 0.057 |
| `["gen_samples", "Lattice d=3 n=16384"]` | 0.980 | – | 1.345 | 1.318 |
| `["gen_samples", "Lattice d=3 n=256"]` | 0.991 | – | 0.015 | 0.015 |
| `["gen_samples", "Lattice d=3 n=4096"]` | 0.991 | – | 0.224 | 0.222 |
| `["integrate", "CubMCCLT AsianOption"]` | 0.990 | – | 3.298 | 3.265 |
| `["integrate", "CubMCCLT EuropeanOption"]` | 0.924 | ❌ | 6.301 | 5.821 |
| `["integrate", "CubMCCLT Keister"]` | 1.348 | ✅ | 10.311 | 13.897 |
| `["integrate", "CubQMCLatticeG EuropeanOption"]` | 1.006 | – | 2.058 | 2.070 |
| `["integrate", "CubQMCLatticeG Keister"]` | 0.976 | – | 0.440 | 0.429 |
| `["integrate", "CubQMCNetG AsianOption"]` | 1.029 | – | 1.261 | 1.297 |
| `["integrate", "CubQMCNetG EuropeanOption"]` | 1.009 | – | 1.246 | 1.256 |
| `["integrate", "CubQMCNetG Keister"]` | 1.003 | – | 0.260 | 0.261 |
| `["integrate", "CubQMCNetGRep AsianOption"]` | 1.269 | ✅ | 20.195 | 25.622 |
| `["integrate", "CubQMCNetGRep EuropeanOption"]` | 0.994 | – | 25.466 | 25.322 |
| `["integrate", "CubQMCNetGRep Keister"]` | 0.995 | – | 3.581 | 3.563 |
| `["transform", "Gaussian d=10 n=1024"]` | 1.006 | – | 0.125 | 0.126 |
| `["transform", "Gaussian d=10 n=16384"]` | 1.000 | – | 2.754 | 2.754 |
| `["transform", "Gaussian d=10 n=256"]` | 1.003 | – | 0.029 | 0.029 |
| `["transform", "Gaussian d=10 n=4096"]` | 0.837 | ❌ | 0.660 | 0.552 |
| `["transform", "Gaussian d=3 n=1024"]` | 0.994 | – | 0.036 | 0.035 |
| `["transform", "Gaussian d=3 n=16384"]` | 0.929 | ❌ | 0.775 | 0.721 |
| `["transform", "Gaussian d=3 n=256"]` | 0.987 | – | 0.009 | 0.009 |
| `["transform", "Gaussian d=3 n=4096"]` | 0.955 | – | 0.153 | 0.146 |
| `["transform", "Gaussian(dense) d=200 n=1024"]` | 1.002 | – | 4.472 | 4.481 |
| `["transform", "Gaussian(dense) d=200 n=4096"]` | 1.052 | ✅ | 17.995 | 18.936 |
| `["transform", "Gaussian(dense) d=50 n=1024"]` | 1.025 | – | 0.881 | 0.903 |
| `["transform", "Gaussian(dense) d=50 n=4096"]` | 0.967 | – | 3.826 | 3.700 |
| `["transform", "Gaussian(diag) d=200 n=1024"]` | 0.997 | – | 3.453 | 3.442 |
| `["transform", "Gaussian(diag) d=200 n=4096"]` | 1.041 | – | 13.839 | 14.401 |
| `["transform", "Gaussian(diag) d=50 n=1024"]` | 0.949 | ❌ | 0.813 | 0.772 |
| `["transform", "Gaussian(diag) d=50 n=4096"]` | 0.955 | – | 3.614 | 3.451 |
| `["transform", "JohnsonsSU d=10 n=1024"]` | 0.979 | – | 0.199 | 0.195 |
| `["transform", "JohnsonsSU d=10 n=16384"]` | 0.991 | – | 3.856 | 3.823 |
| `["transform", "JohnsonsSU d=10 n=256"]` | 0.994 | – | 0.048 | 0.048 |
| `["transform", "JohnsonsSU d=10 n=4096"]` | 0.978 | – | 0.867 | 0.847 |
| `["transform", "StudentT d=10 n=1024"]` | 0.970 | – | 0.051 | 0.049 |
| `["transform", "StudentT d=10 n=16384"]` | 1.585 | ✅ | 0.793 | 1.257 |
| `["transform", "StudentT d=10 n=256"]` | 0.984 | – | 0.013 | 0.013 |
| `["transform", "StudentT d=10 n=4096"]` | 1.001 | – | 0.199 | 0.199 |
