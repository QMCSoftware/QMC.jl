# Benchmark: `local` vs `2ad09b7ddbe40c2319cb31dd852eecd3cd5e9553`

| | local (`local`) | reference (`2ad09b7ddbe40c2319cb31dd852eecd3cd5e9553`) |
|---|---|---|
| commit | non gitrepo | non gitrepo |
| date | 2026-06-28T08:28:36.186 | 2026-06-28T08:30:12.397 |

**`ratio = reference time ÷ local time`**  
ratio `< 1` → local is **slower** ❌  |  ratio `> 1` → local is **faster** ✅

## Aggregate Summary

| metric | ratio | local total | reference total |
|:-------|------:|------------:|----------------:|
| matched benchmarks | 111 | — | — |
| weighted time ratio | 1.001 | 213.637 ms | 213.782 ms |
| weighted memory ratio | 1.000 | 173037.5 KiB | 173037.5 KiB |

| benchmark | ratio | verdict | local (ms) | reference (ms) |
|:----------|------:|:-------:|----------:|---------------:|
| `["evaluate", "BoxIntegral d=10 n=1024"]` | 1.023 | – | 0.010 | 0.010 |
| `["evaluate", "BoxIntegral d=10 n=16384"]` | 0.866 | ❌ | 0.143 | 0.124 |
| `["evaluate", "BoxIntegral d=10 n=256"]` | 0.980 | – | 0.003 | 0.003 |
| `["evaluate", "BoxIntegral d=10 n=4096"]` | 0.985 | – | 0.039 | 0.039 |
| `["evaluate", "BoxIntegral d=200 n=1024"]` | 0.871 | ❌ | 0.054 | 0.047 |
| `["evaluate", "BoxIntegral d=200 n=4096"]` | 1.018 | – | 0.165 | 0.168 |
| `["evaluate", "BoxIntegral d=50 n=1024"]` | 0.829 | ❌ | 0.019 | 0.016 |
| `["evaluate", "BoxIntegral d=50 n=4096"]` | 1.002 | – | 0.076 | 0.076 |
| `["evaluate", "Genz(continuous) d=10 n=1024"]` | 1.022 | – | 0.008 | 0.008 |
| `["evaluate", "Genz(continuous) d=10 n=16384"]` | 0.961 | – | 0.131 | 0.126 |
| `["evaluate", "Genz(continuous) d=10 n=256"]` | 0.947 | ❌ | 0.003 | 0.002 |
| `["evaluate", "Genz(continuous) d=10 n=4096"]` | 0.944 | ❌ | 0.038 | 0.036 |
| `["evaluate", "Genz(gaussian_peak) d=10 n=1024"]` | 0.940 | ❌ | 0.009 | 0.009 |
| `["evaluate", "Genz(gaussian_peak) d=10 n=16384"]` | 1.009 | – | 0.127 | 0.128 |
| `["evaluate", "Genz(gaussian_peak) d=10 n=256"]` | 0.937 | ❌ | 0.003 | 0.003 |
| `["evaluate", "Genz(gaussian_peak) d=10 n=4096"]` | 1.098 | ✅ | 0.036 | 0.040 |
| `["evaluate", "Genz(gaussian_peak) d=200 n=1024"]` | 0.883 | ❌ | 0.059 | 0.052 |
| `["evaluate", "Genz(gaussian_peak) d=200 n=4096"]` | 1.111 | ✅ | 0.169 | 0.187 |
| `["evaluate", "Genz(gaussian_peak) d=50 n=1024"]` | 0.874 | ❌ | 0.020 | 0.017 |
| `["evaluate", "Genz(gaussian_peak) d=50 n=4096"]` | 0.993 | – | 0.084 | 0.083 |
| `["evaluate", "Genz(oscillatory) n=1024"]` | 1.398 | ✅ | 0.010 | 0.014 |
| `["evaluate", "Genz(oscillatory) n=16384"]` | 0.983 | – | 0.231 | 0.227 |
| `["evaluate", "Genz(oscillatory) n=256"]` | 1.018 | – | 0.003 | 0.003 |
| `["evaluate", "Genz(oscillatory) n=4096"]` | 1.040 | – | 0.037 | 0.038 |
| `["evaluate", "Keister n=1024"]` | 1.012 | – | 0.012 | 0.012 |
| `["evaluate", "Keister n=16384"]` | 0.998 | – | 0.190 | 0.190 |
| `["evaluate", "Keister n=256"]` | 1.013 | – | 0.004 | 0.004 |
| `["evaluate", "Keister n=4096"]` | 0.988 | – | 0.055 | 0.054 |
| `["evaluate", "Linear0 d=10 n=1024"]` | 1.029 | – | 0.003 | 0.003 |
| `["evaluate", "Linear0 d=10 n=16384"]` | 0.843 | ❌ | 0.054 | 0.046 |
| `["evaluate", "Linear0 d=10 n=256"]` | 0.970 | – | 0.001 | 0.001 |
| `["evaluate", "Linear0 d=10 n=4096"]` | 1.020 | – | 0.012 | 0.012 |
| `["evaluate", "Linear0 d=200 n=1024"]` | 0.819 | ❌ | 0.045 | 0.037 |
| `["evaluate", "Linear0 d=200 n=4096"]` | 0.833 | ❌ | 0.172 | 0.144 |
| `["evaluate", "Linear0 d=50 n=1024"]` | 0.882 | ❌ | 0.011 | 0.009 |
| `["evaluate", "Linear0 d=50 n=4096"]` | 0.930 | ❌ | 0.052 | 0.048 |
| `["gen_samples", "DigitalNetB2 d=10 n=1024"]` | 0.947 | ❌ | 0.042 | 0.040 |
| `["gen_samples", "DigitalNetB2 d=10 n=16384"]` | 1.023 | – | 1.441 | 1.473 |
| `["gen_samples", "DigitalNetB2 d=10 n=256"]` | 1.028 | – | 0.021 | 0.022 |
| `["gen_samples", "DigitalNetB2 d=10 n=4096"]` | 1.697 | ✅ | 0.144 | 0.244 |
| `["gen_samples", "DigitalNetB2 d=3 n=1024"]` | 1.129 | ✅ | 0.019 | 0.021 |
| `["gen_samples", "DigitalNetB2 d=3 n=16384"]` | 0.972 | – | 0.460 | 0.447 |
| `["gen_samples", "DigitalNetB2 d=3 n=256"]` | 0.997 | – | 0.007 | 0.007 |
| `["gen_samples", "DigitalNetB2 d=3 n=4096"]` | 0.995 | – | 0.048 | 0.048 |
| `["gen_samples", "Halton d=10 n=1024"]` | 0.998 | – | 1.831 | 1.828 |
| `["gen_samples", "Halton d=10 n=16384"]` | 1.000 | – | 29.890 | 29.883 |
| `["gen_samples", "Halton d=10 n=256"]` | 0.999 | – | 0.457 | 0.456 |
| `["gen_samples", "Halton d=10 n=4096"]` | 1.000 | – | 7.324 | 7.327 |
| `["gen_samples", "Halton d=3 n=1024"]` | 1.002 | – | 0.557 | 0.558 |
| `["gen_samples", "Halton d=3 n=16384"]` | 1.000 | – | 9.069 | 9.070 |
| `["gen_samples", "Halton d=3 n=256"]` | 1.002 | – | 0.137 | 0.137 |
| `["gen_samples", "Halton d=3 n=4096"]` | 0.999 | – | 2.244 | 2.242 |
| `["gen_samples", "IIDStdUniform d=10 n=1024"]` | 0.894 | ❌ | 0.010 | 0.009 |
| `["gen_samples", "IIDStdUniform d=10 n=16384"]` | 1.039 | – | 0.562 | 0.584 |
| `["gen_samples", "IIDStdUniform d=10 n=256"]` | 0.892 | ❌ | 0.003 | 0.003 |
| `["gen_samples", "IIDStdUniform d=10 n=4096"]` | 0.844 | ❌ | 0.033 | 0.028 |
| `["gen_samples", "IIDStdUniform d=3 n=1024"]` | 1.165 | ✅ | 0.004 | 0.004 |
| `["gen_samples", "IIDStdUniform d=3 n=16384"]` | 0.814 | ❌ | 0.041 | 0.033 |
| `["gen_samples", "IIDStdUniform d=3 n=256"]` | 1.092 | ✅ | 0.001 | 0.001 |
| `["gen_samples", "IIDStdUniform d=3 n=4096"]` | 1.084 | ✅ | 0.010 | 0.011 |
| `["gen_samples", "Kronecker d=10 n=1024"]` | 0.946 | ❌ | 0.077 | 0.073 |
| `["gen_samples", "Kronecker d=10 n=16384"]` | 1.008 | – | 1.840 | 1.855 |
| `["gen_samples", "Kronecker d=10 n=256"]` | 0.997 | – | 0.018 | 0.018 |
| `["gen_samples", "Kronecker d=10 n=4096"]` | 1.025 | – | 0.321 | 0.329 |
| `["gen_samples", "Kronecker d=3 n=1024"]` | 1.059 | ✅ | 0.023 | 0.024 |
| `["gen_samples", "Kronecker d=3 n=16384"]` | 1.027 | – | 0.405 | 0.415 |
| `["gen_samples", "Kronecker d=3 n=256"]` | 1.003 | – | 0.006 | 0.006 |
| `["gen_samples", "Kronecker d=3 n=4096"]` | 1.045 | – | 0.095 | 0.099 |
| `["gen_samples", "Lattice d=10 n=1024"]` | 1.000 | – | 0.175 | 0.175 |
| `["gen_samples", "Lattice d=10 n=16384"]` | 0.999 | – | 4.279 | 4.274 |
| `["gen_samples", "Lattice d=10 n=256"]` | 0.965 | – | 0.048 | 0.046 |
| `["gen_samples", "Lattice d=10 n=4096"]` | 1.011 | – | 1.055 | 1.066 |
| `["gen_samples", "Lattice d=3 n=1024"]` | 0.960 | – | 0.052 | 0.050 |
| `["gen_samples", "Lattice d=3 n=16384"]` | 0.987 | – | 1.205 | 1.189 |
| `["gen_samples", "Lattice d=3 n=256"]` | 0.980 | – | 0.014 | 0.013 |
| `["gen_samples", "Lattice d=3 n=4096"]` | 0.995 | – | 0.201 | 0.200 |
| `["integrate", "CubMCCLT AsianOption"]` | 1.005 | – | 3.548 | 3.567 |
| `["integrate", "CubMCCLT EuropeanOption"]` | 0.974 | – | 7.266 | 7.079 |
| `["integrate", "CubMCCLT Keister"]` | 1.030 | – | 13.659 | 14.072 |
| `["integrate", "CubQMCLatticeG EuropeanOption"]` | 0.989 | – | 2.128 | 2.105 |
| `["integrate", "CubQMCLatticeG Keister"]` | 1.007 | – | 0.413 | 0.416 |
| `["integrate", "CubQMCNetG AsianOption"]` | 0.981 | – | 1.448 | 1.420 |
| `["integrate", "CubQMCNetG EuropeanOption"]` | 0.993 | – | 1.423 | 1.412 |
| `["integrate", "CubQMCNetG Keister"]` | 1.003 | – | 0.276 | 0.277 |
| `["integrate", "CubQMCNetGRep AsianOption"]` | 0.993 | – | 26.878 | 26.694 |
| `["integrate", "CubQMCNetGRep EuropeanOption"]` | 1.010 | – | 26.406 | 26.659 |
| `["integrate", "CubQMCNetGRep Keister"]` | 1.004 | – | 3.347 | 3.361 |
| `["transform", "Gaussian d=10 n=1024"]` | 1.066 | ✅ | 0.139 | 0.148 |
| `["transform", "Gaussian d=10 n=16384"]` | 0.984 | – | 2.678 | 2.635 |
| `["transform", "Gaussian d=10 n=256"]` | 1.019 | – | 0.031 | 0.031 |
| `["transform", "Gaussian d=10 n=4096"]` | 0.993 | – | 0.654 | 0.649 |
| `["transform", "Gaussian d=3 n=1024"]` | 1.138 | ✅ | 0.037 | 0.043 |
| `["transform", "Gaussian d=3 n=16384"]` | 1.002 | – | 0.787 | 0.789 |
| `["transform", "Gaussian d=3 n=256"]` | 0.986 | – | 0.010 | 0.010 |
| `["transform", "Gaussian d=3 n=4096"]` | 1.029 | – | 0.174 | 0.179 |
| `["transform", "Gaussian(dense) d=200 n=1024"]` | 1.022 | – | 4.331 | 4.428 |
| `["transform", "Gaussian(dense) d=200 n=4096"]` | 1.017 | – | 18.123 | 18.423 |
| `["transform", "Gaussian(dense) d=50 n=1024"]` | 1.027 | – | 0.961 | 0.987 |
| `["transform", "Gaussian(dense) d=50 n=4096"]` | 1.020 | – | 3.570 | 3.642 |
| `["transform", "Gaussian(diag) d=200 n=1024"]` | 1.001 | – | 3.300 | 3.303 |
| `["transform", "Gaussian(diag) d=200 n=4096"]` | 0.951 | – | 15.104 | 14.357 |
| `["transform", "Gaussian(diag) d=50 n=1024"]` | 0.987 | – | 0.825 | 0.814 |
| `["transform", "Gaussian(diag) d=50 n=4096"]` | 1.002 | – | 3.305 | 3.312 |
| `["transform", "JohnsonsSU d=10 n=1024"]` | 1.036 | – | 0.218 | 0.226 |
| `["transform", "JohnsonsSU d=10 n=16384"]` | 1.018 | – | 3.927 | 3.999 |
| `["transform", "JohnsonsSU d=10 n=256"]` | 0.990 | – | 0.053 | 0.052 |
| `["transform", "JohnsonsSU d=10 n=4096"]` | 1.000 | – | 0.959 | 0.959 |
| `["transform", "StudentT d=10 n=1024"]` | 0.996 | – | 0.045 | 0.044 |
| `["transform", "StudentT d=10 n=16384"]` | 1.001 | – | 1.174 | 1.175 |
| `["transform", "StudentT d=10 n=256"]` | 1.028 | – | 0.012 | 0.012 |
| `["transform", "StudentT d=10 n=4096"]` | 0.994 | – | 0.178 | 0.177 |
