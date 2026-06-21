# Benchmark: `local` vs `11aca0cec45ca202f4e8c1578982ad06744296f9`

| | local (`local`) | reference (`11aca0cec45ca202f4e8c1578982ad06744296f9`) |
|---|---|---|
| commit | non gitrepo | non gitrepo |
| date | 2026-06-21T11:53:48.825 | 2026-06-21T11:55:31.183 |

**`ratio = reference time ÷ local time`**  
ratio `< 1` → local is **slower** ❌  |  ratio `> 1` → local is **faster** ✅

## Aggregate Summary

| metric | ratio | local total | reference total |
|:-------|------:|------------:|----------------:|
| matched benchmarks | 111 | — | — |
| weighted time ratio | 1.058 | 200.564 ms | 212.121 ms |
| weighted memory ratio | 0.948 | 173029.9 KiB | 164010.8 KiB |

| benchmark | ratio | verdict | local (ms) | reference (ms) |
|:----------|------:|:-------:|----------:|---------------:|
| `["evaluate", "BoxIntegral d=10 n=1024"]` | 1.048 | – | 0.008 | 0.008 |
| `["evaluate", "BoxIntegral d=10 n=16384"]` | 0.995 | – | 0.136 | 0.136 |
| `["evaluate", "BoxIntegral d=10 n=256"]` | 1.000 | – | 0.003 | 0.003 |
| `["evaluate", "BoxIntegral d=10 n=4096"]` | 0.556 | ❌ | 0.061 | 0.034 |
| `["evaluate", "BoxIntegral d=200 n=1024"]` | 1.070 | ✅ | 0.048 | 0.052 |
| `["evaluate", "BoxIntegral d=200 n=4096"]` | 0.919 | ❌ | 0.185 | 0.170 |
| `["evaluate", "BoxIntegral d=50 n=1024"]` | 0.824 | ❌ | 0.017 | 0.014 |
| `["evaluate", "BoxIntegral d=50 n=4096"]` | 1.085 | ✅ | 0.073 | 0.080 |
| `["evaluate", "Genz(continuous) d=10 n=1024"]` | 1.003 | – | 0.008 | 0.008 |
| `["evaluate", "Genz(continuous) d=10 n=16384"]` | 0.997 | – | 0.124 | 0.124 |
| `["evaluate", "Genz(continuous) d=10 n=256"]` | 0.995 | – | 0.003 | 0.003 |
| `["evaluate", "Genz(continuous) d=10 n=4096"]` | 0.945 | ❌ | 0.035 | 0.033 |
| `["evaluate", "Genz(gaussian_peak) d=10 n=1024"]` | 0.980 | – | 0.008 | 0.008 |
| `["evaluate", "Genz(gaussian_peak) d=10 n=16384"]` | 1.070 | ✅ | 0.129 | 0.138 |
| `["evaluate", "Genz(gaussian_peak) d=10 n=256"]` | 1.023 | – | 0.003 | 0.003 |
| `["evaluate", "Genz(gaussian_peak) d=10 n=4096"]` | 0.933 | ❌ | 0.036 | 0.033 |
| `["evaluate", "Genz(gaussian_peak) d=200 n=1024"]` | 0.961 | – | 0.059 | 0.057 |
| `["evaluate", "Genz(gaussian_peak) d=200 n=4096"]` | 1.083 | ✅ | 0.175 | 0.189 |
| `["evaluate", "Genz(gaussian_peak) d=50 n=1024"]` | 0.772 | ❌ | 0.020 | 0.015 |
| `["evaluate", "Genz(gaussian_peak) d=50 n=4096"]` | 0.906 | ❌ | 0.082 | 0.075 |
| `["evaluate", "Genz(oscillatory) n=1024"]` | 0.934 | ❌ | 0.009 | 0.008 |
| `["evaluate", "Genz(oscillatory) n=16384"]` | 0.988 | – | 0.234 | 0.232 |
| `["evaluate", "Genz(oscillatory) n=256"]` | 0.996 | – | 0.003 | 0.003 |
| `["evaluate", "Genz(oscillatory) n=4096"]` | 1.005 | – | 0.033 | 0.034 |
| `["evaluate", "Keister n=1024"]` | 1.004 | – | 0.011 | 0.011 |
| `["evaluate", "Keister n=16384"]` | 0.997 | – | 0.195 | 0.195 |
| `["evaluate", "Keister n=256"]` | 1.356 | ✅ | 0.004 | 0.005 |
| `["evaluate", "Keister n=4096"]` | 1.014 | – | 0.046 | 0.047 |
| `["evaluate", "Linear0 d=10 n=1024"]` | 0.898 | ❌ | 0.003 | 0.002 |
| `["evaluate", "Linear0 d=10 n=16384"]` | 1.095 | ✅ | 0.045 | 0.049 |
| `["evaluate", "Linear0 d=10 n=256"]` | 0.832 | ❌ | 0.001 | 0.001 |
| `["evaluate", "Linear0 d=10 n=4096"]` | 0.969 | – | 0.012 | 0.011 |
| `["evaluate", "Linear0 d=200 n=1024"]` | 1.063 | ✅ | 0.046 | 0.048 |
| `["evaluate", "Linear0 d=200 n=4096"]` | 1.015 | – | 0.147 | 0.150 |
| `["evaluate", "Linear0 d=50 n=1024"]` | 0.788 | ❌ | 0.009 | 0.007 |
| `["evaluate", "Linear0 d=50 n=4096"]` | 0.930 | ❌ | 0.053 | 0.050 |
| `["gen_samples", "DigitalNetB2 d=10 n=1024"]` | 1.035 | – | 0.039 | 0.041 |
| `["gen_samples", "DigitalNetB2 d=10 n=16384"]` | 0.990 | – | 1.518 | 1.503 |
| `["gen_samples", "DigitalNetB2 d=10 n=256"]` | 0.857 | ❌ | 0.020 | 0.017 |
| `["gen_samples", "DigitalNetB2 d=10 n=4096"]` | 1.692 | ✅ | 0.135 | 0.228 |
| `["gen_samples", "DigitalNetB2 d=3 n=1024"]` | 1.072 | ✅ | 0.016 | 0.017 |
| `["gen_samples", "DigitalNetB2 d=3 n=16384"]` | 1.013 | – | 0.190 | 0.192 |
| `["gen_samples", "DigitalNetB2 d=3 n=256"]` | 1.042 | – | 0.006 | 0.007 |
| `["gen_samples", "DigitalNetB2 d=3 n=4096"]` | 0.971 | – | 0.047 | 0.046 |
| `["gen_samples", "Halton d=10 n=1024"]` | 0.992 | – | 1.842 | 1.827 |
| `["gen_samples", "Halton d=10 n=16384"]` | 0.999 | – | 29.926 | 29.902 |
| `["gen_samples", "Halton d=10 n=256"]` | 1.003 | – | 0.456 | 0.457 |
| `["gen_samples", "Halton d=10 n=4096"]` | 0.997 | – | 7.342 | 7.323 |
| `["gen_samples", "Halton d=3 n=1024"]` | 0.986 | – | 0.565 | 0.557 |
| `["gen_samples", "Halton d=3 n=16384"]` | 0.999 | – | 9.082 | 9.077 |
| `["gen_samples", "Halton d=3 n=256"]` | 0.975 | – | 0.140 | 0.137 |
| `["gen_samples", "Halton d=3 n=4096"]` | 1.000 | – | 2.245 | 2.246 |
| `["gen_samples", "IIDStdUniform d=10 n=1024"]` | 0.849 | ❌ | 0.009 | 0.008 |
| `["gen_samples", "IIDStdUniform d=10 n=16384"]` | 0.987 | – | 0.590 | 0.582 |
| `["gen_samples", "IIDStdUniform d=10 n=256"]` | 0.973 | – | 0.003 | 0.003 |
| `["gen_samples", "IIDStdUniform d=10 n=4096"]` | 1.026 | – | 0.026 | 0.026 |
| `["gen_samples", "IIDStdUniform d=3 n=1024"]` | 1.042 | – | 0.003 | 0.003 |
| `["gen_samples", "IIDStdUniform d=3 n=16384"]` | 0.941 | ❌ | 0.034 | 0.032 |
| `["gen_samples", "IIDStdUniform d=3 n=256"]` | 1.018 | – | 0.001 | 0.001 |
| `["gen_samples", "IIDStdUniform d=3 n=4096"]` | 1.003 | – | 0.010 | 0.010 |
| `["gen_samples", "Kronecker d=10 n=1024"]` | 1.014 | – | 0.072 | 0.073 |
| `["gen_samples", "Kronecker d=10 n=16384"]` | 0.984 | – | 1.868 | 1.839 |
| `["gen_samples", "Kronecker d=10 n=256"]` | 1.010 | – | 0.018 | 0.018 |
| `["gen_samples", "Kronecker d=10 n=4096"]` | 0.973 | – | 0.335 | 0.326 |
| `["gen_samples", "Kronecker d=3 n=1024"]` | 1.037 | – | 0.022 | 0.022 |
| `["gen_samples", "Kronecker d=3 n=16384"]` | 1.004 | – | 0.407 | 0.409 |
| `["gen_samples", "Kronecker d=3 n=256"]` | 1.005 | – | 0.006 | 0.006 |
| `["gen_samples", "Kronecker d=3 n=4096"]` | 1.002 | – | 0.095 | 0.095 |
| `["gen_samples", "Lattice d=10 n=1024"]` | 1.024 | – | 0.176 | 0.181 |
| `["gen_samples", "Lattice d=10 n=16384"]` | 0.989 | – | 4.370 | 4.321 |
| `["gen_samples", "Lattice d=10 n=256"]` | 0.995 | – | 0.048 | 0.048 |
| `["gen_samples", "Lattice d=10 n=4096"]` | 0.655 | ❌ | 1.082 | 0.709 |
| `["gen_samples", "Lattice d=3 n=1024"]` | 1.053 | ✅ | 0.050 | 0.053 |
| `["gen_samples", "Lattice d=3 n=16384"]` | 0.789 | ❌ | 1.220 | 0.963 |
| `["gen_samples", "Lattice d=3 n=256"]` | 1.134 | ✅ | 0.013 | 0.015 |
| `["gen_samples", "Lattice d=3 n=4096"]` | 1.008 | – | 0.199 | 0.201 |
| `["integrate", "CubMCCLT AsianOption"]` | 0.905 | ❌ | 3.588 | 3.247 |
| `["integrate", "CubMCCLT EuropeanOption"]` | 0.907 | ❌ | 7.021 | 6.365 |
| `["integrate", "CubMCCLT Keister"]` | 1.060 | ✅ | 12.415 | 13.161 |
| `["integrate", "CubQMCLatticeG EuropeanOption"]` | 1.077 | ✅ | 2.037 | 2.193 |
| `["integrate", "CubQMCLatticeG Keister"]` | 0.998 | – | 0.411 | 0.410 |
| `["integrate", "CubQMCNetG AsianOption"]` | 1.118 | ✅ | 1.319 | 1.474 |
| `["integrate", "CubQMCNetG EuropeanOption"]` | 1.056 | ✅ | 1.323 | 1.397 |
| `["integrate", "CubQMCNetG Keister"]` | 1.124 | ✅ | 0.274 | 0.308 |
| `["integrate", "CubQMCNetGRep AsianOption"]` | 1.165 | ✅ | 22.848 | 26.615 |
| `["integrate", "CubQMCNetGRep EuropeanOption"]` | 1.211 | ✅ | 21.832 | 26.437 |
| `["integrate", "CubQMCNetGRep Keister"]` | 0.982 | – | 3.395 | 3.334 |
| `["transform", "Gaussian d=10 n=1024"]` | 0.988 | – | 0.143 | 0.141 |
| `["transform", "Gaussian d=10 n=16384"]` | 1.009 | – | 2.612 | 2.635 |
| `["transform", "Gaussian d=10 n=256"]` | 1.006 | – | 0.030 | 0.031 |
| `["transform", "Gaussian d=10 n=4096"]` | 1.020 | – | 0.647 | 0.660 |
| `["transform", "Gaussian d=3 n=1024"]` | 1.007 | – | 0.037 | 0.037 |
| `["transform", "Gaussian d=3 n=16384"]` | 1.007 | – | 0.777 | 0.782 |
| `["transform", "Gaussian d=3 n=256"]` | 1.003 | – | 0.010 | 0.010 |
| `["transform", "Gaussian d=3 n=4096"]` | 0.706 | ❌ | 0.253 | 0.179 |
| `["transform", "Gaussian(dense) d=200 n=1024"]` | 1.275 | ✅ | 4.399 | 5.609 |
| `["transform", "Gaussian(dense) d=200 n=4096"]` | 1.043 | – | 17.819 | 18.588 |
| `["transform", "Gaussian(dense) d=50 n=1024"]` | 1.146 | ✅ | 0.899 | 1.030 |
| `["transform", "Gaussian(dense) d=50 n=4096"]` | 1.033 | – | 3.570 | 3.687 |
| `["transform", "Gaussian(diag) d=200 n=1024"]` | 1.013 | – | 3.275 | 3.317 |
| `["transform", "Gaussian(diag) d=200 n=4096"]` | 1.083 | ✅ | 13.210 | 14.307 |
| `["transform", "Gaussian(diag) d=50 n=1024"]` | 0.986 | – | 0.827 | 0.816 |
| `["transform", "Gaussian(diag) d=50 n=4096"]` | 1.004 | – | 3.279 | 3.292 |
| `["transform", "JohnsonsSU d=10 n=1024"]` | 0.999 | – | 0.221 | 0.221 |
| `["transform", "JohnsonsSU d=10 n=16384"]` | 1.003 | – | 3.858 | 3.871 |
| `["transform", "JohnsonsSU d=10 n=256"]` | 0.998 | – | 0.051 | 0.051 |
| `["transform", "JohnsonsSU d=10 n=4096"]` | 0.996 | – | 0.955 | 0.951 |
| `["transform", "StudentT d=10 n=1024"]` | 0.999 | – | 0.044 | 0.044 |
| `["transform", "StudentT d=10 n=16384"]` | 1.678 | ✅ | 0.704 | 1.181 |
| `["transform", "StudentT d=10 n=256"]` | 1.011 | – | 0.011 | 0.012 |
| `["transform", "StudentT d=10 n=4096"]` | 0.999 | – | 0.177 | 0.177 |
