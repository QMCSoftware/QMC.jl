# Benchmark: `local` vs `63ecfcddbcafd7d9f261ac53d344a7ddaa8ea00f`

| | local (`local`) | reference (`63ecfcddbcafd7d9f261ac53d344a7ddaa8ea00f`) |
|---|---|---|
| commit | non gitrepo | non gitrepo |
| date | 2026-06-30T10:02:03.172 | 2026-06-30T10:03:53.090 |

**`ratio = reference time ÷ local time`**  
ratio `< 1` → local is **slower** ❌  |  ratio `> 1` → local is **faster** ✅

## Aggregate Summary

| metric | ratio | local total | reference total |
|:-------|------:|------------:|----------------:|
| matched benchmarks | 111 | — | — |
| weighted time ratio | 1.049 | 169.532 ms | 177.756 ms |
| weighted memory ratio | 1.000 | 121291.7 KiB | 121296.2 KiB |

| benchmark | ratio | verdict | local (ms) | reference (ms) |
|:----------|------:|:-------:|----------:|---------------:|
| `["evaluate", "BoxIntegral d=10 n=1024"]` | 0.937 | ❌ | 0.009 | 0.009 |
| `["evaluate", "BoxIntegral d=10 n=16384"]` | 1.015 | – | 0.128 | 0.130 |
| `["evaluate", "BoxIntegral d=10 n=256"]` | 0.985 | – | 0.003 | 0.003 |
| `["evaluate", "BoxIntegral d=10 n=4096"]` | 0.994 | – | 0.037 | 0.037 |
| `["evaluate", "BoxIntegral d=200 n=1024"]` | 0.994 | – | 0.049 | 0.049 |
| `["evaluate", "BoxIntegral d=200 n=4096"]` | 0.966 | – | 0.190 | 0.184 |
| `["evaluate", "BoxIntegral d=50 n=1024"]` | 1.035 | – | 0.015 | 0.015 |
| `["evaluate", "BoxIntegral d=50 n=4096"]` | 1.125 | ✅ | 0.071 | 0.080 |
| `["evaluate", "Genz(continuous) d=10 n=1024"]` | 0.936 | ❌ | 0.008 | 0.008 |
| `["evaluate", "Genz(continuous) d=10 n=16384"]` | 1.035 | – | 0.123 | 0.127 |
| `["evaluate", "Genz(continuous) d=10 n=256"]` | 1.094 | ✅ | 0.003 | 0.003 |
| `["evaluate", "Genz(continuous) d=10 n=4096"]` | 0.950 | ❌ | 0.037 | 0.035 |
| `["evaluate", "Genz(gaussian_peak) d=10 n=1024"]` | 0.997 | – | 0.008 | 0.008 |
| `["evaluate", "Genz(gaussian_peak) d=10 n=16384"]` | 1.045 | – | 0.124 | 0.130 |
| `["evaluate", "Genz(gaussian_peak) d=10 n=256"]` | 1.045 | – | 0.003 | 0.003 |
| `["evaluate", "Genz(gaussian_peak) d=10 n=4096"]` | 1.027 | – | 0.036 | 0.037 |
| `["evaluate", "Genz(gaussian_peak) d=200 n=1024"]` | 1.028 | – | 0.050 | 0.051 |
| `["evaluate", "Genz(gaussian_peak) d=200 n=4096"]` | 1.012 | – | 0.176 | 0.178 |
| `["evaluate", "Genz(gaussian_peak) d=50 n=1024"]` | 0.981 | – | 0.017 | 0.017 |
| `["evaluate", "Genz(gaussian_peak) d=50 n=4096"]` | 0.980 | – | 0.078 | 0.076 |
| `["evaluate", "Genz(oscillatory) n=1024"]` | 1.077 | ✅ | 0.009 | 0.009 |
| `["evaluate", "Genz(oscillatory) n=16384"]` | 1.024 | – | 0.230 | 0.236 |
| `["evaluate", "Genz(oscillatory) n=256"]` | 1.018 | – | 0.003 | 0.003 |
| `["evaluate", "Genz(oscillatory) n=4096"]` | 1.159 | ✅ | 0.033 | 0.039 |
| `["evaluate", "Keister n=1024"]` | 1.028 | – | 0.011 | 0.012 |
| `["evaluate", "Keister n=16384"]` | 1.023 | – | 0.190 | 0.194 |
| `["evaluate", "Keister n=256"]` | 0.998 | – | 0.004 | 0.004 |
| `["evaluate", "Keister n=4096"]` | 0.930 | ❌ | 0.055 | 0.051 |
| `["evaluate", "Linear0 d=10 n=1024"]` | 0.997 | – | 0.002 | 0.002 |
| `["evaluate", "Linear0 d=10 n=16384"]` | 1.101 | ✅ | 0.045 | 0.050 |
| `["evaluate", "Linear0 d=10 n=256"]` | 0.912 | ❌ | 0.001 | 0.001 |
| `["evaluate", "Linear0 d=10 n=4096"]` | 1.191 | ✅ | 0.010 | 0.012 |
| `["evaluate", "Linear0 d=200 n=1024"]` | 0.949 | ❌ | 0.043 | 0.041 |
| `["evaluate", "Linear0 d=200 n=4096"]` | 1.112 | ✅ | 0.154 | 0.172 |
| `["evaluate", "Linear0 d=50 n=1024"]` | 1.095 | ✅ | 0.008 | 0.009 |
| `["evaluate", "Linear0 d=50 n=4096"]` | 1.045 | – | 0.047 | 0.049 |
| `["gen_samples", "DigitalNetB2 d=10 n=1024"]` | 1.032 | – | 0.040 | 0.041 |
| `["gen_samples", "DigitalNetB2 d=10 n=16384"]` | 1.015 | – | 1.447 | 1.468 |
| `["gen_samples", "DigitalNetB2 d=10 n=256"]` | 1.110 | ✅ | 0.016 | 0.018 |
| `["gen_samples", "DigitalNetB2 d=10 n=4096"]` | 1.733 | ✅ | 0.143 | 0.248 |
| `["gen_samples", "DigitalNetB2 d=3 n=1024"]` | 1.034 | – | 0.019 | 0.019 |
| `["gen_samples", "DigitalNetB2 d=3 n=16384"]` | 0.885 | ❌ | 0.470 | 0.416 |
| `["gen_samples", "DigitalNetB2 d=3 n=256"]` | 0.973 | – | 0.007 | 0.007 |
| `["gen_samples", "DigitalNetB2 d=3 n=4096"]` | 0.930 | ❌ | 0.059 | 0.054 |
| `["gen_samples", "Halton d=10 n=1024"]` | 1.002 | – | 0.720 | 0.721 |
| `["gen_samples", "Halton d=10 n=16384"]` | 1.000 | – | 12.514 | 12.509 |
| `["gen_samples", "Halton d=10 n=256"]` | 0.998 | – | 0.180 | 0.179 |
| `["gen_samples", "Halton d=10 n=4096"]` | 0.999 | – | 2.947 | 2.945 |
| `["gen_samples", "Halton d=3 n=1024"]` | 0.993 | – | 0.236 | 0.235 |
| `["gen_samples", "Halton d=3 n=16384"]` | 1.000 | – | 3.993 | 3.993 |
| `["gen_samples", "Halton d=3 n=256"]` | 1.038 | – | 0.056 | 0.059 |
| `["gen_samples", "Halton d=3 n=4096"]` | 1.000 | – | 0.969 | 0.968 |
| `["gen_samples", "IIDStdUniform d=10 n=1024"]` | 0.986 | – | 0.008 | 0.007 |
| `["gen_samples", "IIDStdUniform d=10 n=16384"]` | 0.985 | – | 0.573 | 0.564 |
| `["gen_samples", "IIDStdUniform d=10 n=256"]` | 1.014 | – | 0.003 | 0.003 |
| `["gen_samples", "IIDStdUniform d=10 n=4096"]` | 1.032 | – | 0.026 | 0.027 |
| `["gen_samples", "IIDStdUniform d=3 n=1024"]` | 1.265 | ✅ | 0.003 | 0.004 |
| `["gen_samples", "IIDStdUniform d=3 n=16384"]` | 0.857 | ❌ | 0.039 | 0.033 |
| `["gen_samples", "IIDStdUniform d=3 n=256"]` | 0.906 | ❌ | 0.001 | 0.001 |
| `["gen_samples", "IIDStdUniform d=3 n=4096"]` | 0.789 | ❌ | 0.012 | 0.009 |
| `["gen_samples", "Kronecker d=10 n=1024"]` | 0.978 | – | 0.023 | 0.023 |
| `["gen_samples", "Kronecker d=10 n=16384"]` | 1.016 | – | 0.829 | 0.843 |
| `["gen_samples", "Kronecker d=10 n=256"]` | 0.907 | ❌ | 0.007 | 0.006 |
| `["gen_samples", "Kronecker d=10 n=4096"]` | 1.006 | – | 0.089 | 0.090 |
| `["gen_samples", "Kronecker d=3 n=1024"]` | 0.948 | ❌ | 0.008 | 0.007 |
| `["gen_samples", "Kronecker d=3 n=16384"]` | 0.948 | ❌ | 0.115 | 0.109 |
| `["gen_samples", "Kronecker d=3 n=256"]` | 1.026 | – | 0.002 | 0.002 |
| `["gen_samples", "Kronecker d=3 n=4096"]` | 1.004 | – | 0.028 | 0.028 |
| `["gen_samples", "Lattice d=10 n=1024"]` | 0.916 | ❌ | 0.072 | 0.066 |
| `["gen_samples", "Lattice d=10 n=16384"]` | 1.008 | – | 2.486 | 2.505 |
| `["gen_samples", "Lattice d=10 n=256"]` | 0.961 | – | 0.021 | 0.020 |
| `["gen_samples", "Lattice d=10 n=4096"]` | 0.916 | ❌ | 0.614 | 0.562 |
| `["gen_samples", "Lattice d=3 n=1024"]` | 1.006 | – | 0.026 | 0.026 |
| `["gen_samples", "Lattice d=3 n=16384"]` | 0.999 | – | 0.793 | 0.792 |
| `["gen_samples", "Lattice d=3 n=256"]` | 0.980 | – | 0.008 | 0.007 |
| `["gen_samples", "Lattice d=3 n=4096"]` | 1.020 | – | 0.098 | 0.100 |
| `["integrate", "CubMCCLT AsianOption"]` | 1.008 | – | 3.695 | 3.726 |
| `["integrate", "CubMCCLT EuropeanOption"]` | 0.898 | ❌ | 7.357 | 6.606 |
| `["integrate", "CubMCCLT Keister"]` | 0.989 | – | 14.500 | 14.338 |
| `["integrate", "CubQMCLatticeG EuropeanOption"]` | 1.042 | – | 1.517 | 1.580 |
| `["integrate", "CubQMCLatticeG Keister"]` | 1.012 | – | 0.336 | 0.340 |
| `["integrate", "CubQMCNetG AsianOption"]` | 1.037 | – | 1.392 | 1.443 |
| `["integrate", "CubQMCNetG EuropeanOption"]` | 1.069 | ✅ | 1.355 | 1.448 |
| `["integrate", "CubQMCNetG Keister"]` | 0.998 | – | 0.295 | 0.295 |
| `["integrate", "CubQMCNetGRep AsianOption"]` | 0.997 | – | 21.346 | 21.284 |
| `["integrate", "CubQMCNetGRep EuropeanOption"]` | 1.407 | ✅ | 20.695 | 29.124 |
| `["integrate", "CubQMCNetGRep Keister"]` | 1.004 | – | 3.235 | 3.248 |
| `["transform", "Gaussian d=10 n=1024"]` | 1.008 | – | 0.138 | 0.140 |
| `["transform", "Gaussian d=10 n=16384"]` | 0.989 | – | 2.686 | 2.656 |
| `["transform", "Gaussian d=10 n=256"]` | 1.037 | – | 0.031 | 0.032 |
| `["transform", "Gaussian d=10 n=4096"]` | 0.983 | – | 0.661 | 0.650 |
| `["transform", "Gaussian d=3 n=1024"]` | 1.033 | – | 0.038 | 0.039 |
| `["transform", "Gaussian d=3 n=16384"]` | 0.975 | – | 0.801 | 0.782 |
| `["transform", "Gaussian d=3 n=256"]` | 1.039 | – | 0.010 | 0.010 |
| `["transform", "Gaussian d=3 n=4096"]` | 0.974 | – | 0.175 | 0.171 |
| `["transform", "Gaussian(dense) d=200 n=1024"]` | 0.986 | – | 5.502 | 5.426 |
| `["transform", "Gaussian(dense) d=200 n=4096"]` | 1.031 | – | 18.153 | 18.706 |
| `["transform", "Gaussian(dense) d=50 n=1024"]` | 1.099 | ✅ | 0.978 | 1.075 |
| `["transform", "Gaussian(dense) d=50 n=4096"]` | 0.844 | ❌ | 4.504 | 3.800 |
| `["transform", "Gaussian(diag) d=200 n=1024"]` | 0.994 | – | 3.318 | 3.297 |
| `["transform", "Gaussian(diag) d=200 n=4096"]` | 1.053 | ✅ | 14.385 | 15.141 |
| `["transform", "Gaussian(diag) d=50 n=1024"]` | 0.990 | – | 0.825 | 0.816 |
| `["transform", "Gaussian(diag) d=50 n=4096"]` | 0.988 | – | 3.328 | 3.286 |
| `["transform", "JohnsonsSU d=10 n=1024"]` | 0.954 | – | 0.229 | 0.219 |
| `["transform", "JohnsonsSU d=10 n=16384"]` | 0.992 | – | 3.916 | 3.885 |
| `["transform", "JohnsonsSU d=10 n=256"]` | 0.987 | – | 0.052 | 0.051 |
| `["transform", "JohnsonsSU d=10 n=4096"]` | 0.999 | – | 0.963 | 0.962 |
| `["transform", "StudentT d=10 n=1024"]` | 0.994 | – | 0.044 | 0.044 |
| `["transform", "StudentT d=10 n=16384"]` | 0.996 | – | 1.172 | 1.167 |
| `["transform", "StudentT d=10 n=256"]` | 0.991 | – | 0.012 | 0.011 |
| `["transform", "StudentT d=10 n=4096"]` | 0.994 | – | 0.179 | 0.178 |
