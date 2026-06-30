# Benchmark: `local` vs `ff1a4d13647616e527d78381e50b63c9bb7eaab5`

| | local (`local`) | reference (`ff1a4d13647616e527d78381e50b63c9bb7eaab5`) |
|---|---|---|
| commit | non gitrepo | non gitrepo |
| date | 2026-06-30T15:15:45.506 | 2026-06-30T15:17:29.066 |

**`ratio = reference time ÷ local time`**  
ratio `< 1` → local is **slower** ❌  |  ratio `> 1` → local is **faster** ✅

## Aggregate Summary

| metric | ratio | local total | reference total |
|:-------|------:|------------:|----------------:|
| matched benchmarks | 111 | — | — |
| weighted time ratio | 1.031 | 165.878 ms | 171.059 ms |
| weighted memory ratio | 1.000 | 118918.9 KiB | 118924.1 KiB |

| benchmark | ratio | verdict | local (ms) | reference (ms) |
|:----------|------:|:-------:|----------:|---------------:|
| `["evaluate", "BoxIntegral d=10 n=1024"]` | 0.985 | – | 0.009 | 0.009 |
| `["evaluate", "BoxIntegral d=10 n=16384"]` | 1.018 | – | 0.133 | 0.135 |
| `["evaluate", "BoxIntegral d=10 n=256"]` | 0.875 | ❌ | 0.003 | 0.003 |
| `["evaluate", "BoxIntegral d=10 n=4096"]` | 0.738 | ❌ | 0.050 | 0.037 |
| `["evaluate", "BoxIntegral d=200 n=1024"]` | 1.081 | ✅ | 0.051 | 0.056 |
| `["evaluate", "BoxIntegral d=200 n=4096"]` | 1.152 | ✅ | 0.173 | 0.199 |
| `["evaluate", "BoxIntegral d=50 n=1024"]` | 1.061 | ✅ | 0.018 | 0.019 |
| `["evaluate", "BoxIntegral d=50 n=4096"]` | 1.024 | – | 0.088 | 0.090 |
| `["evaluate", "Genz(continuous) d=10 n=1024"]` | 0.986 | – | 0.009 | 0.009 |
| `["evaluate", "Genz(continuous) d=10 n=16384"]` | 1.076 | ✅ | 0.120 | 0.129 |
| `["evaluate", "Genz(continuous) d=10 n=256"]` | 0.999 | – | 0.003 | 0.003 |
| `["evaluate", "Genz(continuous) d=10 n=4096"]` | 0.831 | ❌ | 0.041 | 0.034 |
| `["evaluate", "Genz(gaussian_peak) d=10 n=1024"]` | 0.896 | ❌ | 0.009 | 0.008 |
| `["evaluate", "Genz(gaussian_peak) d=10 n=16384"]` | 0.985 | – | 0.124 | 0.123 |
| `["evaluate", "Genz(gaussian_peak) d=10 n=256"]` | 0.941 | ❌ | 0.003 | 0.003 |
| `["evaluate", "Genz(gaussian_peak) d=10 n=4096"]` | 0.880 | ❌ | 0.041 | 0.036 |
| `["evaluate", "Genz(gaussian_peak) d=200 n=1024"]` | 0.967 | – | 0.061 | 0.059 |
| `["evaluate", "Genz(gaussian_peak) d=200 n=4096"]` | 1.063 | ✅ | 0.192 | 0.204 |
| `["evaluate", "Genz(gaussian_peak) d=50 n=1024"]` | 1.054 | ✅ | 0.017 | 0.018 |
| `["evaluate", "Genz(gaussian_peak) d=50 n=4096"]` | 1.023 | – | 0.088 | 0.091 |
| `["evaluate", "Genz(oscillatory) n=1024"]` | 1.012 | – | 0.009 | 0.009 |
| `["evaluate", "Genz(oscillatory) n=16384"]` | 1.005 | – | 0.229 | 0.230 |
| `["evaluate", "Genz(oscillatory) n=256"]` | 1.073 | ✅ | 0.003 | 0.003 |
| `["evaluate", "Genz(oscillatory) n=4096"]` | 0.890 | ❌ | 0.047 | 0.041 |
| `["evaluate", "Keister n=1024"]` | 1.046 | – | 0.012 | 0.013 |
| `["evaluate", "Keister n=16384"]` | 1.011 | – | 0.190 | 0.193 |
| `["evaluate", "Keister n=256"]` | 0.929 | ❌ | 0.004 | 0.004 |
| `["evaluate", "Keister n=4096"]` | 1.046 | – | 0.052 | 0.055 |
| `["evaluate", "Linear0 d=10 n=1024"]` | 0.865 | ❌ | 0.003 | 0.003 |
| `["evaluate", "Linear0 d=10 n=16384"]` | 0.852 | ❌ | 0.057 | 0.048 |
| `["evaluate", "Linear0 d=10 n=256"]` | 0.891 | ❌ | 0.001 | 0.001 |
| `["evaluate", "Linear0 d=10 n=4096"]` | 1.097 | ✅ | 0.012 | 0.013 |
| `["evaluate", "Linear0 d=200 n=1024"]` | 1.016 | – | 0.049 | 0.049 |
| `["evaluate", "Linear0 d=200 n=4096"]` | 1.113 | ✅ | 0.143 | 0.159 |
| `["evaluate", "Linear0 d=50 n=1024"]` | 0.987 | – | 0.010 | 0.010 |
| `["evaluate", "Linear0 d=50 n=4096"]` | 1.046 | – | 0.051 | 0.054 |
| `["gen_samples", "DigitalNetB2 d=10 n=1024"]` | 1.036 | – | 0.042 | 0.043 |
| `["gen_samples", "DigitalNetB2 d=10 n=16384"]` | 1.035 | – | 1.468 | 1.519 |
| `["gen_samples", "DigitalNetB2 d=10 n=256"]` | 1.064 | ✅ | 0.017 | 0.018 |
| `["gen_samples", "DigitalNetB2 d=10 n=4096"]` | 1.039 | – | 0.342 | 0.355 |
| `["gen_samples", "DigitalNetB2 d=3 n=1024"]` | 1.272 | ✅ | 0.018 | 0.023 |
| `["gen_samples", "DigitalNetB2 d=3 n=16384"]` | 0.660 | ❌ | 0.400 | 0.264 |
| `["gen_samples", "DigitalNetB2 d=3 n=256"]` | 0.605 | ❌ | 0.011 | 0.007 |
| `["gen_samples", "DigitalNetB2 d=3 n=4096"]` | 1.017 | – | 0.057 | 0.058 |
| `["gen_samples", "Halton d=10 n=1024"]` | 1.001 | – | 0.723 | 0.723 |
| `["gen_samples", "Halton d=10 n=16384"]` | 1.001 | – | 12.529 | 12.547 |
| `["gen_samples", "Halton d=10 n=256"]` | 0.997 | – | 0.180 | 0.179 |
| `["gen_samples", "Halton d=10 n=4096"]` | 0.999 | – | 2.947 | 2.943 |
| `["gen_samples", "Halton d=3 n=1024"]` | 1.001 | – | 0.234 | 0.234 |
| `["gen_samples", "Halton d=3 n=16384"]` | 1.000 | – | 3.992 | 3.992 |
| `["gen_samples", "Halton d=3 n=256"]` | 1.015 | – | 0.056 | 0.057 |
| `["gen_samples", "Halton d=3 n=4096"]` | 1.001 | – | 0.964 | 0.965 |
| `["gen_samples", "IIDStdUniform d=10 n=1024"]` | 0.887 | ❌ | 0.010 | 0.009 |
| `["gen_samples", "IIDStdUniform d=10 n=16384"]` | 1.040 | – | 0.585 | 0.609 |
| `["gen_samples", "IIDStdUniform d=10 n=256"]` | 1.137 | ✅ | 0.002 | 0.003 |
| `["gen_samples", "IIDStdUniform d=10 n=4096"]` | 1.366 | ✅ | 0.026 | 0.035 |
| `["gen_samples", "IIDStdUniform d=3 n=1024"]` | 1.120 | ✅ | 0.003 | 0.003 |
| `["gen_samples", "IIDStdUniform d=3 n=16384"]` | 0.963 | – | 0.036 | 0.034 |
| `["gen_samples", "IIDStdUniform d=3 n=256"]` | 0.966 | – | 0.001 | 0.001 |
| `["gen_samples", "IIDStdUniform d=3 n=4096"]` | 1.005 | – | 0.009 | 0.009 |
| `["gen_samples", "Kronecker d=10 n=1024"]` | 0.973 | – | 0.025 | 0.024 |
| `["gen_samples", "Kronecker d=10 n=16384"]` | 1.018 | – | 0.817 | 0.831 |
| `["gen_samples", "Kronecker d=10 n=256"]` | 0.989 | – | 0.006 | 0.006 |
| `["gen_samples", "Kronecker d=10 n=4096"]` | 0.967 | – | 0.093 | 0.090 |
| `["gen_samples", "Kronecker d=3 n=1024"]` | 1.024 | – | 0.007 | 0.007 |
| `["gen_samples", "Kronecker d=3 n=16384"]` | 1.003 | – | 0.109 | 0.110 |
| `["gen_samples", "Kronecker d=3 n=256"]` | 1.081 | ✅ | 0.002 | 0.002 |
| `["gen_samples", "Kronecker d=3 n=4096"]` | 0.980 | – | 0.028 | 0.028 |
| `["gen_samples", "Lattice d=10 n=1024"]` | 0.978 | – | 0.066 | 0.065 |
| `["gen_samples", "Lattice d=10 n=16384"]` | 0.981 | – | 2.551 | 2.504 |
| `["gen_samples", "Lattice d=10 n=256"]` | 1.084 | ✅ | 0.018 | 0.020 |
| `["gen_samples", "Lattice d=10 n=4096"]` | 0.799 | ❌ | 0.624 | 0.499 |
| `["gen_samples", "Lattice d=3 n=1024"]` | 1.006 | – | 0.027 | 0.027 |
| `["gen_samples", "Lattice d=3 n=16384"]` | 0.964 | – | 0.810 | 0.781 |
| `["gen_samples", "Lattice d=3 n=256"]` | 0.964 | – | 0.008 | 0.007 |
| `["gen_samples", "Lattice d=3 n=4096"]` | 0.972 | – | 0.101 | 0.098 |
| `["integrate", "CubMCCLT AsianOption"]` | 0.991 | – | 3.776 | 3.741 |
| `["integrate", "CubMCCLT EuropeanOption"]` | 1.076 | ✅ | 6.542 | 7.037 |
| `["integrate", "CubMCCLT Keister"]` | 1.026 | – | 14.012 | 14.371 |
| `["integrate", "CubQMCLatticeG EuropeanOption"]` | 0.992 | – | 1.523 | 1.512 |
| `["integrate", "CubQMCLatticeG Keister"]` | 1.022 | – | 0.339 | 0.346 |
| `["integrate", "CubQMCNetG AsianOption"]` | 0.999 | – | 1.427 | 1.425 |
| `["integrate", "CubQMCNetG EuropeanOption"]` | 1.007 | – | 1.403 | 1.413 |
| `["integrate", "CubQMCNetG Keister"]` | 1.046 | – | 0.264 | 0.276 |
| `["integrate", "CubQMCNetGRep AsianOption"]` | 1.234 | ✅ | 19.538 | 24.114 |
| `["integrate", "CubQMCNetGRep EuropeanOption"]` | 1.009 | – | 19.538 | 19.717 |
| `["integrate", "CubQMCNetGRep Keister"]` | 0.990 | – | 3.226 | 3.194 |
| `["transform", "Gaussian d=10 n=1024"]` | 0.934 | ❌ | 0.149 | 0.139 |
| `["transform", "Gaussian d=10 n=16384"]` | 0.997 | – | 2.657 | 2.650 |
| `["transform", "Gaussian d=10 n=256"]` | 0.860 | ❌ | 0.036 | 0.031 |
| `["transform", "Gaussian d=10 n=4096"]` | 0.998 | – | 0.648 | 0.646 |
| `["transform", "Gaussian d=3 n=1024"]` | 0.916 | ❌ | 0.043 | 0.040 |
| `["transform", "Gaussian d=3 n=16384"]` | 0.998 | – | 0.785 | 0.783 |
| `["transform", "Gaussian d=3 n=256"]` | 1.135 | ✅ | 0.010 | 0.012 |
| `["transform", "Gaussian d=3 n=4096"]` | 1.009 | – | 0.175 | 0.177 |
| `["transform", "Gaussian(dense) d=200 n=1024"]` | 1.006 | – | 5.529 | 5.561 |
| `["transform", "Gaussian(dense) d=200 n=4096"]` | 1.002 | – | 18.218 | 18.246 |
| `["transform", "Gaussian(dense) d=50 n=1024"]` | 1.018 | – | 0.999 | 1.017 |
| `["transform", "Gaussian(dense) d=50 n=4096"]` | 0.972 | – | 4.653 | 4.523 |
| `["transform", "Gaussian(diag) d=200 n=1024"]` | 0.991 | – | 3.309 | 3.278 |
| `["transform", "Gaussian(diag) d=200 n=4096"]` | 1.008 | – | 14.125 | 14.243 |
| `["transform", "Gaussian(diag) d=50 n=1024"]` | 0.982 | – | 0.827 | 0.812 |
| `["transform", "Gaussian(diag) d=50 n=4096"]` | 0.950 | – | 3.474 | 3.301 |
| `["transform", "JohnsonsSU d=10 n=1024"]` | 0.987 | – | 0.224 | 0.221 |
| `["transform", "JohnsonsSU d=10 n=16384"]` | 0.999 | – | 3.929 | 3.923 |
| `["transform", "JohnsonsSU d=10 n=256"]` | 0.907 | ❌ | 0.057 | 0.052 |
| `["transform", "JohnsonsSU d=10 n=4096"]` | 0.983 | – | 0.976 | 0.959 |
| `["transform", "StudentT d=10 n=1024"]` | 1.025 | – | 0.044 | 0.045 |
| `["transform", "StudentT d=10 n=16384"]` | 1.001 | – | 1.182 | 1.183 |
| `["transform", "StudentT d=10 n=256"]` | 1.015 | – | 0.012 | 0.012 |
| `["transform", "StudentT d=10 n=4096"]` | 1.002 | – | 0.178 | 0.179 |
