# Benchmark: `local` vs `61f724450627420351f51aaa554b327862ef2e32`

| | local (`local`) | reference (`61f724450627420351f51aaa554b327862ef2e32`) |
|---|---|---|
| commit | non gitrepo | non gitrepo |
| date | 2026-06-28T14:11:40.200 | 2026-06-28T14:13:31.767 |

**`ratio = reference time ÷ local time`**  
ratio `< 1` → local is **slower** ❌  |  ratio `> 1` → local is **faster** ✅

## Aggregate Summary

| metric | ratio | local total | reference total |
|:-------|------:|------------:|----------------:|
| matched benchmarks | 111 | — | — |
| weighted time ratio | 0.923 | 205.214 ms | 189.395 ms |
| weighted memory ratio | 1.000 | 173037.5 KiB | 173037.5 KiB |

| benchmark | ratio | verdict | local (ms) | reference (ms) |
|:----------|------:|:-------:|----------:|---------------:|
| `["evaluate", "BoxIntegral d=10 n=1024"]` | 1.033 | – | 0.008 | 0.008 |
| `["evaluate", "BoxIntegral d=10 n=16384"]` | 1.061 | ✅ | 0.131 | 0.139 |
| `["evaluate", "BoxIntegral d=10 n=256"]` | 1.083 | ✅ | 0.003 | 0.003 |
| `["evaluate", "BoxIntegral d=10 n=4096"]` | 1.042 | – | 0.034 | 0.036 |
| `["evaluate", "BoxIntegral d=200 n=1024"]` | 1.007 | – | 0.032 | 0.032 |
| `["evaluate", "BoxIntegral d=200 n=4096"]` | 0.993 | – | 0.212 | 0.211 |
| `["evaluate", "BoxIntegral d=50 n=1024"]` | 1.038 | – | 0.012 | 0.013 |
| `["evaluate", "BoxIntegral d=50 n=4096"]` | 1.014 | – | 0.071 | 0.072 |
| `["evaluate", "Genz(continuous) d=10 n=1024"]` | 1.010 | – | 0.007 | 0.007 |
| `["evaluate", "Genz(continuous) d=10 n=16384"]` | 0.986 | – | 0.120 | 0.118 |
| `["evaluate", "Genz(continuous) d=10 n=256"]` | 0.984 | – | 0.003 | 0.003 |
| `["evaluate", "Genz(continuous) d=10 n=4096"]` | 1.008 | – | 0.032 | 0.032 |
| `["evaluate", "Genz(gaussian_peak) d=10 n=1024"]` | 1.026 | – | 0.007 | 0.007 |
| `["evaluate", "Genz(gaussian_peak) d=10 n=16384"]` | 0.967 | – | 0.120 | 0.116 |
| `["evaluate", "Genz(gaussian_peak) d=10 n=256"]` | 1.012 | – | 0.003 | 0.003 |
| `["evaluate", "Genz(gaussian_peak) d=10 n=4096"]` | 0.954 | – | 0.032 | 0.031 |
| `["evaluate", "Genz(gaussian_peak) d=200 n=1024"]` | 0.999 | – | 0.034 | 0.034 |
| `["evaluate", "Genz(gaussian_peak) d=200 n=4096"]` | 0.996 | – | 0.211 | 0.210 |
| `["evaluate", "Genz(gaussian_peak) d=50 n=1024"]` | 0.984 | – | 0.013 | 0.012 |
| `["evaluate", "Genz(gaussian_peak) d=50 n=4096"]` | 1.013 | – | 0.072 | 0.073 |
| `["evaluate", "Genz(oscillatory) n=1024"]` | 1.008 | – | 0.008 | 0.008 |
| `["evaluate", "Genz(oscillatory) n=16384"]` | 0.958 | – | 0.115 | 0.110 |
| `["evaluate", "Genz(oscillatory) n=256"]` | 0.925 | ❌ | 0.003 | 0.003 |
| `["evaluate", "Genz(oscillatory) n=4096"]` | 0.981 | – | 0.033 | 0.032 |
| `["evaluate", "Keister n=1024"]` | 1.005 | – | 0.011 | 0.011 |
| `["evaluate", "Keister n=16384"]` | 0.957 | – | 0.165 | 0.158 |
| `["evaluate", "Keister n=256"]` | 1.007 | – | 0.004 | 0.004 |
| `["evaluate", "Keister n=4096"]` | 1.052 | ✅ | 0.045 | 0.048 |
| `["evaluate", "Linear0 d=10 n=1024"]` | 1.039 | – | 0.002 | 0.002 |
| `["evaluate", "Linear0 d=10 n=16384"]` | 0.907 | ❌ | 0.051 | 0.046 |
| `["evaluate", "Linear0 d=10 n=256"]` | 1.057 | ✅ | 0.001 | 0.001 |
| `["evaluate", "Linear0 d=10 n=4096"]` | 1.018 | – | 0.010 | 0.010 |
| `["evaluate", "Linear0 d=200 n=1024"]` | 1.105 | ✅ | 0.024 | 0.026 |
| `["evaluate", "Linear0 d=200 n=4096"]` | 1.005 | – | 0.188 | 0.189 |
| `["evaluate", "Linear0 d=50 n=1024"]` | 1.005 | – | 0.007 | 0.007 |
| `["evaluate", "Linear0 d=50 n=4096"]` | 1.027 | – | 0.048 | 0.049 |
| `["gen_samples", "DigitalNetB2 d=10 n=1024"]` | 0.998 | – | 0.039 | 0.039 |
| `["gen_samples", "DigitalNetB2 d=10 n=16384"]` | 1.006 | – | 1.495 | 1.504 |
| `["gen_samples", "DigitalNetB2 d=10 n=256"]` | 0.993 | – | 0.019 | 0.019 |
| `["gen_samples", "DigitalNetB2 d=10 n=4096"]` | 0.380 | ❌ | 0.378 | 0.144 |
| `["gen_samples", "DigitalNetB2 d=3 n=1024"]` | 1.015 | – | 0.016 | 0.017 |
| `["gen_samples", "DigitalNetB2 d=3 n=16384"]` | 0.482 | ❌ | 0.383 | 0.185 |
| `["gen_samples", "DigitalNetB2 d=3 n=256"]` | 0.977 | – | 0.007 | 0.007 |
| `["gen_samples", "DigitalNetB2 d=3 n=4096"]` | 1.003 | – | 0.048 | 0.048 |
| `["gen_samples", "Halton d=10 n=1024"]` | 0.949 | ❌ | 1.534 | 1.456 |
| `["gen_samples", "Halton d=10 n=16384"]` | 0.897 | ❌ | 26.294 | 23.592 |
| `["gen_samples", "Halton d=10 n=256"]` | 1.058 | ✅ | 0.373 | 0.394 |
| `["gen_samples", "Halton d=10 n=4096"]` | 0.897 | ❌ | 6.339 | 5.684 |
| `["gen_samples", "Halton d=3 n=1024"]` | 0.913 | ❌ | 0.501 | 0.458 |
| `["gen_samples", "Halton d=3 n=16384"]` | 0.919 | ❌ | 8.674 | 7.969 |
| `["gen_samples", "Halton d=3 n=256"]` | 0.912 | ❌ | 0.119 | 0.109 |
| `["gen_samples", "Halton d=3 n=4096"]` | 0.914 | ❌ | 2.090 | 1.911 |
| `["gen_samples", "IIDStdUniform d=10 n=1024"]` | 1.218 | ✅ | 0.008 | 0.010 |
| `["gen_samples", "IIDStdUniform d=10 n=16384"]` | 0.972 | – | 0.604 | 0.586 |
| `["gen_samples", "IIDStdUniform d=10 n=256"]` | 1.035 | – | 0.003 | 0.003 |
| `["gen_samples", "IIDStdUniform d=10 n=4096"]` | 0.412 | ❌ | 0.063 | 0.026 |
| `["gen_samples", "IIDStdUniform d=3 n=1024"]` | 0.963 | – | 0.003 | 0.003 |
| `["gen_samples", "IIDStdUniform d=3 n=16384"]` | 0.382 | ❌ | 0.081 | 0.031 |
| `["gen_samples", "IIDStdUniform d=3 n=256"]` | 1.036 | – | 0.001 | 0.002 |
| `["gen_samples", "IIDStdUniform d=3 n=4096"]` | 1.015 | – | 0.010 | 0.010 |
| `["gen_samples", "Kronecker d=10 n=1024"]` | 0.967 | – | 0.077 | 0.074 |
| `["gen_samples", "Kronecker d=10 n=16384"]` | 0.998 | – | 1.911 | 1.907 |
| `["gen_samples", "Kronecker d=10 n=256"]` | 1.002 | – | 0.018 | 0.018 |
| `["gen_samples", "Kronecker d=10 n=4096"]` | 0.902 | ❌ | 0.365 | 0.329 |
| `["gen_samples", "Kronecker d=3 n=1024"]` | 0.987 | – | 0.022 | 0.022 |
| `["gen_samples", "Kronecker d=3 n=16384"]` | 0.978 | – | 0.422 | 0.412 |
| `["gen_samples", "Kronecker d=3 n=256"]` | 0.993 | – | 0.006 | 0.006 |
| `["gen_samples", "Kronecker d=3 n=4096"]` | 0.993 | – | 0.098 | 0.097 |
| `["gen_samples", "Lattice d=10 n=1024"]` | 0.992 | – | 0.198 | 0.196 |
| `["gen_samples", "Lattice d=10 n=16384"]` | 0.999 | – | 4.693 | 4.688 |
| `["gen_samples", "Lattice d=10 n=256"]` | 0.998 | – | 0.050 | 0.050 |
| `["gen_samples", "Lattice d=10 n=4096"]` | 0.845 | ❌ | 1.172 | 0.991 |
| `["gen_samples", "Lattice d=3 n=1024"]` | 0.998 | – | 0.057 | 0.057 |
| `["gen_samples", "Lattice d=3 n=16384"]` | 0.985 | – | 1.320 | 1.300 |
| `["gen_samples", "Lattice d=3 n=256"]` | 1.003 | – | 0.015 | 0.015 |
| `["gen_samples", "Lattice d=3 n=4096"]` | 0.985 | – | 0.228 | 0.225 |
| `["integrate", "CubMCCLT AsianOption"]` | 0.991 | – | 3.577 | 3.544 |
| `["integrate", "CubMCCLT EuropeanOption"]` | 0.889 | ❌ | 7.466 | 6.638 |
| `["integrate", "CubMCCLT Keister"]` | 0.935 | ❌ | 14.088 | 13.171 |
| `["integrate", "CubQMCLatticeG EuropeanOption"]` | 0.915 | ❌ | 2.235 | 2.045 |
| `["integrate", "CubQMCLatticeG Keister"]` | 0.999 | – | 0.434 | 0.434 |
| `["integrate", "CubQMCNetG AsianOption"]` | 0.923 | ❌ | 1.373 | 1.268 |
| `["integrate", "CubQMCNetG EuropeanOption"]` | 0.893 | ❌ | 1.378 | 1.230 |
| `["integrate", "CubQMCNetG Keister"]` | 0.990 | – | 0.280 | 0.277 |
| `["integrate", "CubQMCNetGRep AsianOption"]` | 0.780 | ❌ | 26.450 | 20.634 |
| `["integrate", "CubQMCNetGRep EuropeanOption"]` | 0.990 | – | 20.714 | 20.498 |
| `["integrate", "CubQMCNetGRep Keister"]` | 0.998 | – | 3.424 | 3.417 |
| `["transform", "Gaussian d=10 n=1024"]` | 1.011 | – | 0.122 | 0.124 |
| `["transform", "Gaussian d=10 n=16384"]` | 1.026 | – | 2.719 | 2.789 |
| `["transform", "Gaussian d=10 n=256"]` | 1.014 | – | 0.029 | 0.030 |
| `["transform", "Gaussian d=10 n=4096"]` | 0.895 | ❌ | 0.633 | 0.567 |
| `["transform", "Gaussian d=3 n=1024"]` | 1.057 | ✅ | 0.036 | 0.038 |
| `["transform", "Gaussian d=3 n=16384"]` | 0.895 | ❌ | 0.814 | 0.728 |
| `["transform", "Gaussian d=3 n=256"]` | 1.007 | – | 0.009 | 0.010 |
| `["transform", "Gaussian d=3 n=4096"]` | 1.009 | – | 0.146 | 0.147 |
| `["transform", "Gaussian(dense) d=200 n=1024"]` | 0.978 | – | 4.637 | 4.535 |
| `["transform", "Gaussian(dense) d=200 n=4096"]` | 0.963 | – | 19.346 | 18.627 |
| `["transform", "Gaussian(dense) d=50 n=1024"]` | 0.903 | ❌ | 0.925 | 0.835 |
| `["transform", "Gaussian(dense) d=50 n=4096"]` | 0.977 | – | 3.835 | 3.747 |
| `["transform", "Gaussian(diag) d=200 n=1024"]` | 1.005 | – | 3.427 | 3.443 |
| `["transform", "Gaussian(diag) d=200 n=4096"]` | 0.942 | ❌ | 14.777 | 13.917 |
| `["transform", "Gaussian(diag) d=50 n=1024"]` | 0.986 | – | 0.774 | 0.763 |
| `["transform", "Gaussian(diag) d=50 n=4096"]` | 1.012 | – | 3.429 | 3.469 |
| `["transform", "JohnsonsSU d=10 n=1024"]` | 1.010 | – | 0.197 | 0.199 |
| `["transform", "JohnsonsSU d=10 n=16384"]` | 1.001 | – | 3.852 | 3.857 |
| `["transform", "JohnsonsSU d=10 n=256"]` | 1.035 | – | 0.048 | 0.050 |
| `["transform", "JohnsonsSU d=10 n=4096"]` | 0.981 | – | 0.868 | 0.851 |
| `["transform", "StudentT d=10 n=1024"]` | 0.993 | – | 0.050 | 0.050 |
| `["transform", "StudentT d=10 n=16384"]` | 0.609 | ❌ | 1.300 | 0.792 |
| `["transform", "StudentT d=10 n=256"]` | 0.992 | – | 0.013 | 0.013 |
| `["transform", "StudentT d=10 n=4096"]` | 1.001 | – | 0.199 | 0.199 |
