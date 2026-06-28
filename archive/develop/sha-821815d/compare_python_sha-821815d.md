# Benchmark: Julia (local) vs QMCPy (Python)

| | Julia (local) | Python (QMCPy) |
|---|---|---|
| Julia label | `sha-821815d` | — |
| Python label | — | `sha-821815d` |
| Julia artifact mtime | `2026-06-28T14:21:42` | — |
| Python artifact mtime | — | `2026-06-28T14:27:30` |
| Julia generated at | `2026-06-28T14:13:43` | — |
| Python generated at | — | `2026-06-28T14:27:30` |
| Julia BLAS threads | `2` | — |
| Python version | — | `3.13.14` |
| qmcpy version | — | 2.3 |
| integrate timing | `samples=9` | `repeat=9` |
| StudentT timing | `samples=21` | `repeat=21`, `warmup=3` |
| thread env | — | `MKL_NUM_THREADS=2, NUMEXPR_NUM_THREADS=2, OMP_NUM_THREADS=2, OPENBLAS_NUM_THREADS=2, QUASIMC_BENCH_BLAS_THREADS=2` |

**`ratio = Python time ÷ Julia time`**  
ratio `< 1` → local (Julia) is **slower** ❌  |  ratio `> 1` → local (Julia) is **faster** ✅  

> ⚠️ C-kernel rows `[C]` (Lattice/DigitalNetB2/Halton `gen_samples`) call the same
> `qmctoolscl` library on both sides and are **not** a Julia vs Python comparison.
> `StudentT` rows are also summarized separately below because they can dominate
> the weighted cross-language time ratio.
> Julia `alloc KiB` is allocated bytes from BenchmarkTools. Julia `RSS Δ` and Python
> `RSS Δ` are coarse retained-memory signals from one warmed call. Python `tracemalloc`
> peak is Python-managed temporary memory. These are related but not interchangeable.
> The 95% timing intervals below come from bootstrap resampling of the repeated timing samples already collected inside this run. They quantify within-run timing-sample variability, not cross-machine or cross-workflow reproducibility.
> Report generated at `2026-06-28T14:27:35`. Input artifact skew: `5 m 48 s`.

## Aggregate Summary

| metric | scope | ratio | Julia total | Python total | rows |
|:-------|:------|------:|------------:|-------------:|-----:|
| matched benchmarks | all matched rows | 111/111 | — | — | 111 |
| weighted time ratio | all matched rows | 4.707 | 197.247 ms | 928.389 ms | 111 |
| weighted time ratio | excluding StudentT | 4.246 | 196.194 ms | 833.020 ms | 107 |
| weighted time ratio | StudentT only | 90.547 | 1.053 ms | 95.369 ms | 4 |
| weighted time ratio 95% bootstrap CI | all matched rows | `[4.651, 4.801]` | — | — | 1000 |
| weighted time ratio 95% bootstrap CI | excluding StudentT | `[4.196, 4.337]` | — | — | 1000 |
| weighted time ratio 95% bootstrap CI | StudentT only | `[90.178, 90.913]` | — | — | 1000 |
| weighted approximate tracemalloc ratio | all matched rows | 4.377 | 173037.5 KiB | 757321.4 KiB | 111 |
| weighted approximate RSS delta ratio | all matched rows | 156.220 | 492.0 KiB | 76860.0 KiB | 111 |

> ℹ️ RSS delta ratio compares retained process RSS after one warmed call; ratio < 1 means Python retained less RSS than Julia, and ratio > 1 means Python retained more. Treat it as an approximate retained-footprint signal, not a direct allocation metric.

## Grouped Timing Summary

Generator, transform, integrand evaluation, and end-to-end adaptive integration are summarized separately below. The `integrate` group is mixed end-to-end cost, not isolated stopping-criterion overhead.

| group | interpretation | weighted time ratio | 95% bootstrap CI | Julia total | Python total | rows |
|:------|:---------------|--------------------:|:------------------|------------:|-------------:|-----:|
| `evaluate` | integrand evaluation only | 3.658 | `[3.167, 3.731]` | 2.026 ms | 7.412 ms | 36 |
| `gen_samples` | generator only | 5.300 | `[5.278, 5.398]` | 59.757 ms | 316.692 ms | 40 |
| `integrate` | end-to-end adaptive integration; not isolated stopping-criterion overhead | 3.065 | `[2.976, 3.213]` | 75.435 ms | 231.206 ms | 11 |
| `transform` | transform only | 6.215 | `[6.028, 6.232]` | 60.029 ms | 373.079 ms | 24 |

## Detailed Results

| benchmark | time ratio | verdict | Julia (ms) | Python (ms) | Julia alloc (KiB) | Julia RSS Δ (KiB) | Python peak (KiB) | Python RSS Δ (KiB) |
|:----------|-----------:|:-------:|----------:|------------:|-------------------:|------------------:|------------------:|-------------------:|
| `["evaluate", "BoxIntegral d=10 n=1024"]` | 4.532 | ✅ | 0.008 | 0.035 | 16.1 | 0.0 | 89.0 | 0.0 |
| `["evaluate", "BoxIntegral d=10 n=16384"]` | 2.090 | ✅ | 0.245 | 0.512 | 256.1 | 0.0 | 1409.0 | 0.0 |
| `["evaluate", "BoxIntegral d=10 n=256"]` | 4.183 | ✅ | 0.003 | 0.012 | 4.1 | 0.0 | 23.0 | 0.0 |
| `["evaluate", "BoxIntegral d=10 n=4096"]` | 4.242 | ✅ | 0.031 | 0.130 | 64.1 | 0.0 | 353.0 | 0.0 |
| `["evaluate", "BoxIntegral d=200 n=1024"]` | 6.265 | ✅ | 0.033 | 0.205 | 16.1 | 0.0 | 1609.0 | 0.0 |
| `["evaluate", "BoxIntegral d=200 n=4096"]` | 2.215 | ✅ | 0.218 | 0.483 | 64.1 | 0.0 | 6433.0 | 4.0 |
| `["evaluate", "BoxIntegral d=50 n=1024"]` | 4.258 | ✅ | 0.013 | 0.054 | 16.1 | 0.0 | 409.0 | 0.0 |
| `["evaluate", "BoxIntegral d=50 n=4096"]` | 3.752 | ✅ | 0.068 | 0.257 | 64.1 | 0.0 | 1633.0 | 0.0 |
| `["evaluate", "Genz(continuous) d=10 n=1024"]` | 5.813 | ✅ | 0.007 | 0.042 | 16.1 | 0.0 | 160.2 | 0.0 |
| `["evaluate", "Genz(continuous) d=10 n=16384"]` | 4.992 | ✅ | 0.122 | 0.609 | 256.1 | 0.0 | 2560.2 | 0.0 |
| `["evaluate", "Genz(continuous) d=10 n=256"]` | 5.700 | ✅ | 0.003 | 0.015 | 4.1 | 0.0 | 40.2 | 0.0 |
| `["evaluate", "Genz(continuous) d=10 n=4096"]` | 5.560 | ✅ | 0.028 | 0.155 | 64.1 | 0.0 | 640.2 | 0.0 |
| `["evaluate", "Genz(gaussian_peak) d=10 n=1024"]` | 5.704 | ✅ | 0.007 | 0.042 | 16.1 | 0.0 | 169.2 | 0.0 |
| `["evaluate", "Genz(gaussian_peak) d=10 n=16384"]` | 5.041 | ✅ | 0.119 | 0.601 | 256.1 | 0.0 | 2689.2 | 0.0 |
| `["evaluate", "Genz(gaussian_peak) d=10 n=256"]` | 5.588 | ✅ | 0.003 | 0.015 | 4.1 | 0.0 | 43.2 | 0.0 |
| `["evaluate", "Genz(gaussian_peak) d=10 n=4096"]` | 5.593 | ✅ | 0.028 | 0.156 | 64.1 | 0.0 | 673.2 | 0.0 |
| `["evaluate", "Genz(gaussian_peak) d=200 n=1024"]` | 7.504 | ✅ | 0.035 | 0.262 | 16.1 | 0.0 | 3209.2 | 0.0 |
| `["evaluate", "Genz(gaussian_peak) d=200 n=4096"]` | 3.665 | ✅ | 0.209 | 0.767 | 64.1 | 0.0 | 12833.2 | 0.0 |
| `["evaluate", "Genz(gaussian_peak) d=50 n=1024"]` | 5.736 | ✅ | 0.013 | 0.074 | 16.1 | 0.0 | 809.2 | 0.0 |
| `["evaluate", "Genz(gaussian_peak) d=50 n=4096"]` | 5.232 | ✅ | 0.067 | 0.353 | 64.1 | 0.0 | 3233.2 | 0.0 |
| `["evaluate", "Genz(oscillatory) n=1024"]` | 5.422 | ✅ | 0.008 | 0.042 | 16.1 | 0.0 | 49.2 | 0.0 |
| `["evaluate", "Genz(oscillatory) n=16384"]` | 5.428 | ✅ | 0.114 | 0.621 | 256.1 | 0.0 | 513.0 | 0.0 |
| `["evaluate", "Genz(oscillatory) n=256"]` | 5.095 | ✅ | 0.003 | 0.014 | 4.1 | 0.0 | 13.2 | 0.0 |
| `["evaluate", "Genz(oscillatory) n=4096"]` | 5.548 | ✅ | 0.028 | 0.158 | 64.1 | 0.0 | 161.2 | 0.0 |
| `["evaluate", "Keister n=1024"]` | 3.567 | ✅ | 0.011 | 0.040 | 24.3 | 0.0 | 40.3 | 0.0 |
| `["evaluate", "Keister n=16384"]` | 2.634 | ✅ | 0.209 | 0.550 | 384.3 | 108.0 | 640.3 | 0.0 |
| `["evaluate", "Keister n=256"]` | 3.766 | ✅ | 0.004 | 0.014 | 6.3 | 0.0 | 10.3 | 0.0 |
| `["evaluate", "Keister n=4096"]` | 3.494 | ✅ | 0.041 | 0.143 | 96.3 | 0.0 | 160.3 | 0.0 |
| `["evaluate", "Linear0 d=10 n=1024"]` | 13.197 | ✅ | 0.002 | 0.027 | 8.1 | 208.0 | 8.9 | 0.0 |
| `["evaluate", "Linear0 d=10 n=16384"]` | 8.126 | ✅ | 0.051 | 0.416 | 128.1 | 0.0 | 128.9 | 0.0 |
| `["evaluate", "Linear0 d=10 n=256"]` | 8.319 | ✅ | 0.001 | 0.008 | 2.1 | 0.0 | 2.9 | 0.0 |
| `["evaluate", "Linear0 d=10 n=4096"]` | 11.508 | ✅ | 0.009 | 0.104 | 32.1 | 0.0 | 32.9 | 0.0 |
| `["evaluate", "Linear0 d=200 n=1024"]` | 2.013 | ✅ | 0.033 | 0.067 | 8.1 | 0.0 | 8.9 | 0.0 |
| `["evaluate", "Linear0 d=200 n=4096"]` | 1.366 | ✅ | 0.188 | 0.256 | 32.1 | 0.0 | 32.9 | 0.0 |
| `["evaluate", "Linear0 d=50 n=1024"]` | 5.539 | ✅ | 0.006 | 0.035 | 8.1 | 0.0 | 8.9 | 0.0 |
| `["evaluate", "Linear0 d=50 n=4096"]` | 2.406 | ✅ | 0.059 | 0.141 | 32.1 | 0.0 | 32.9 | 0.0 |
| `["gen_samples", "DigitalNetB2 d=10 n=1024"]` `[C]` | 1.859 | ✅ | 0.054 | 0.100 | 168.9 | 0.0 | 108.4 | 0.0 |
| `["gen_samples", "DigitalNetB2 d=10 n=16384"]` `[C]` | 0.232 | ❌ | 1.579 | 0.366 | 2568.9 | 0.0 | 1308.4 | 0.0 |
| `["gen_samples", "DigitalNetB2 d=10 n=256"]` `[C]` | 5.149 | ✅ | 0.017 | 0.086 | 48.9 | 4.0 | 48.4 | 0.0 |
| `["gen_samples", "DigitalNetB2 d=10 n=4096"]` `[C]` | 0.644 | ❌ | 0.239 | 0.154 | 648.9 | 0.0 | 348.4 | 0.0 |
| `["gen_samples", "DigitalNetB2 d=3 n=1024"]` `[C]` | 6.509 | ✅ | 0.014 | 0.091 | 51.1 | 0.0 | 52.4 | 0.0 |
| `["gen_samples", "DigitalNetB2 d=3 n=16384"]` `[C]` | 0.559 | ❌ | 0.409 | 0.228 | 771.1 | 0.0 | 412.4 | 0.0 |
| `["gen_samples", "DigitalNetB2 d=3 n=256"]` `[C]` | 12.364 | ✅ | 0.007 | 0.085 | 15.1 | 0.0 | 34.4 | 0.0 |
| `["gen_samples", "DigitalNetB2 d=3 n=4096"]` `[C]` | 2.378 | ✅ | 0.050 | 0.118 | 195.1 | 0.0 | 124.4 | 0.0 |
| `["gen_samples", "Halton d=10 n=1024"]` `[C]` | 5.468 | ✅ | 1.541 | 8.428 | 82.8 | 0.0 | 10191.4 | 0.0 |
| `["gen_samples", "Halton d=10 n=16384"]` `[C]` | 6.383 | ✅ | 26.307 | 167.908 | 1282.8 | 0.0 | 162591.6 | 0.0 |
| `["gen_samples", "Halton d=10 n=256"]` `[C]` | 5.263 | ✅ | 0.373 | 1.961 | 22.8 | 0.0 | 2571.4 | 0.0 |
| `["gen_samples", "Halton d=10 n=4096"]` `[C]` | 5.937 | ✅ | 6.265 | 37.197 | 322.8 | 0.0 | 40671.4 | 0.0 |
| `["gen_samples", "Halton d=3 n=1024"]` `[C]` | 8.980 | ✅ | 0.510 | 4.576 | 25.0 | 0.0 | 3079.4 | 0.0 |
| `["gen_samples", "Halton d=3 n=16384"]` `[C]` | 7.614 | ✅ | 8.658 | 65.927 | 385.0 | 0.0 | 48799.4 | 0.0 |
| `["gen_samples", "Halton d=3 n=256"]` `[C]` | 6.772 | ✅ | 0.122 | 0.828 | 7.0 | 0.0 | 793.4 | 0.0 |
| `["gen_samples", "Halton d=3 n=4096"]` `[C]` | 7.826 | ✅ | 2.092 | 16.370 | 97.0 | 0.0 | 12223.4 | 0.0 |
| `["gen_samples", "IIDStdUniform d=10 n=1024"]` | 4.949 | ✅ | 0.009 | 0.044 | 80.1 | 0.0 | 80.8 | 0.0 |
| `["gen_samples", "IIDStdUniform d=10 n=16384"]` | 1.211 | ✅ | 0.677 | 0.819 | 1280.1 | 0.0 | 1280.8 | 0.0 |
| `["gen_samples", "IIDStdUniform d=10 n=256"]` | 5.774 | ✅ | 0.002 | 0.014 | 20.1 | 0.0 | 20.7 | 0.0 |
| `["gen_samples", "IIDStdUniform d=10 n=4096"]` | 6.261 | ✅ | 0.026 | 0.164 | 320.1 | 0.0 | 320.8 | 0.0 |
| `["gen_samples", "IIDStdUniform d=3 n=1024"]` | 5.933 | ✅ | 0.003 | 0.016 | 24.1 | 0.0 | 24.8 | 0.0 |
| `["gen_samples", "IIDStdUniform d=3 n=16384"]` | 6.412 | ✅ | 0.031 | 0.196 | 384.1 | 0.0 | 384.8 | 0.0 |
| `["gen_samples", "IIDStdUniform d=3 n=256"]` | 5.757 | ✅ | 0.001 | 0.007 | 6.1 | 0.0 | 6.7 | 0.0 |
| `["gen_samples", "IIDStdUniform d=3 n=4096"]` | 4.823 | ✅ | 0.011 | 0.052 | 96.1 | 0.0 | 96.8 | 0.0 |
| `["gen_samples", "Kronecker d=10 n=1024"]` | 2.328 | ✅ | 0.073 | 0.169 | 80.1 | 0.0 | 233.6 | 0.0 |
| `["gen_samples", "Kronecker d=10 n=16384"]` | 1.416 | ✅ | 1.969 | 2.787 | 1280.1 | 0.0 | 2753.6 | 0.0 |
| `["gen_samples", "Kronecker d=10 n=256"]` | 2.584 | ✅ | 0.018 | 0.046 | 20.1 | 0.0 | 63.6 | 0.0 |
| `["gen_samples", "Kronecker d=10 n=4096"]` | 2.064 | ✅ | 0.330 | 0.682 | 320.1 | 0.0 | 737.6 | 0.0 |
| `["gen_samples", "Kronecker d=3 n=1024"]` | 3.093 | ✅ | 0.021 | 0.066 | 24.1 | 0.0 | 81.6 | 0.0 |
| `["gen_samples", "Kronecker d=3 n=16384"]` | 2.454 | ✅ | 0.415 | 1.017 | 384.1 | 0.0 | 961.6 | 0.0 |
| `["gen_samples", "Kronecker d=3 n=256"]` | 3.652 | ✅ | 0.006 | 0.021 | 6.1 | 0.0 | 21.6 | 0.0 |
| `["gen_samples", "Kronecker d=3 n=4096"]` | 2.549 | ✅ | 0.097 | 0.247 | 96.1 | 172.0 | 289.6 | 0.0 |
| `["gen_samples", "Lattice d=10 n=1024"]` `[C]` | 1.459 | ✅ | 0.201 | 0.293 | 240.9 | 0.0 | 189.2 | 0.0 |
| `["gen_samples", "Lattice d=10 n=16384"]` `[C]` | 0.650 | ❌ | 4.716 | 3.065 | 3840.9 | 0.0 | 2589.2 | 0.0 |
| `["gen_samples", "Lattice d=10 n=256"]` `[C]` | 3.096 | ✅ | 0.049 | 0.152 | 60.9 | 0.0 | 69.2 | 0.0 |
| `["gen_samples", "Lattice d=10 n=4096"]` `[C]` | 0.715 | ❌ | 1.194 | 0.854 | 960.9 | 0.0 | 669.2 | 0.0 |
| `["gen_samples", "Lattice d=3 n=1024"]` `[C]` | 2.791 | ✅ | 0.057 | 0.160 | 72.4 | 0.0 | 77.2 | 0.0 |
| `["gen_samples", "Lattice d=3 n=16384"]` `[C]` | 0.701 | ❌ | 1.369 | 0.959 | 1152.4 | 0.0 | 797.2 | 0.0 |
| `["gen_samples", "Lattice d=3 n=256"]` `[C]` | 7.925 | ✅ | 0.015 | 0.119 | 18.4 | 0.0 | 41.3 | 0.0 |
| `["gen_samples", "Lattice d=3 n=4096"]` `[C]` | 1.377 | ✅ | 0.232 | 0.320 | 288.4 | 0.0 | 221.2 | 0.0 |
| `["integrate", "CubMCCLT AsianOption"]` | 3.439 | ✅ | 3.751 | 12.899 | 3258.5 | 0.0 | 11001.7 | 0.0 |
| `["integrate", "CubMCCLT EuropeanOption"]` | 4.017 | ✅ | 7.557 | 30.355 | 8136.3 | 0.0 | 33415.8 | 15872.0 |
| `["integrate", "CubMCCLT Keister"]` | 7.099 | ✅ | 13.956 | 99.070 | 39909.1 | 0.0 | 123185.4 | 58788.0 |
| `["integrate", "CubQMCLatticeG EuropeanOption"]` `[C]` | 2.770 | ✅ | 2.062 | 5.711 | 2077.1 | 0.0 | 4583.0 | 0.0 |
| `["integrate", "CubQMCLatticeG Keister"]` `[C]` | 6.591 | ✅ | 0.423 | 2.789 | 570.7 | 0.0 | 401.2 | 704.0 |
| `["integrate", "CubQMCNetG AsianOption"]` | 3.428 | ✅ | 1.777 | 6.090 | 1718.7 | 0.0 | 4196.6 | 8.0 |
| `["integrate", "CubQMCNetG EuropeanOption"]` | 4.877 | ✅ | 1.247 | 6.083 | 1710.7 | 0.0 | 4196.6 | 0.0 |
| `["integrate", "CubQMCNetG Keister"]` | 8.577 | ✅ | 0.369 | 3.166 | 441.5 | 0.0 | 514.8 | 12.0 |
| `["integrate", "CubQMCNetGRep AsianOption"]` | 1.526 | ✅ | 20.401 | 31.138 | 26550.4 | 0.0 | 16561.0 | 1472.0 |
| `["integrate", "CubQMCNetGRep EuropeanOption"]` | 1.602 | ✅ | 19.365 | 31.019 | 26421.3 | 0.0 | 16560.8 | 0.0 |
| `["integrate", "CubQMCNetGRep Keister"]` | 0.637 | ❌ | 4.527 | 2.885 | 4735.8 | 0.0 | 1104.4 | 0.0 |
| `["transform", "Gaussian d=10 n=1024"]` | 3.307 | ✅ | 0.126 | 0.417 | 80.1 | 0.0 | 716.5 | 0.0 |
| `["transform", "Gaussian d=10 n=16384"]` | 2.243 | ✅ | 2.765 | 6.200 | 1280.1 | 0.0 | 10466.5 | 0.0 |
| `["transform", "Gaussian d=10 n=256"]` | 5.279 | ✅ | 0.030 | 0.159 | 20.1 | 0.0 | 184.1 | 0.0 |
| `["transform", "Gaussian d=10 n=4096"]` | 2.718 | ✅ | 0.564 | 1.533 | 320.1 | 0.0 | 2666.5 | 0.0 |
| `["transform", "Gaussian d=3 n=1024"]` | 4.830 | ✅ | 0.037 | 0.176 | 24.1 | 0.0 | 220.6 | 0.0 |
| `["transform", "Gaussian d=3 n=16384"]` | 2.500 | ✅ | 0.738 | 1.846 | 384.1 | 0.0 | 3186.5 | 0.0 |
| `["transform", "Gaussian d=3 n=256"]` | 8.898 | ✅ | 0.011 | 0.096 | 6.1 | 0.0 | 56.4 | 0.0 |
| `["transform", "Gaussian d=3 n=4096"]` | 3.221 | ✅ | 0.152 | 0.489 | 96.1 | 0.0 | 846.5 | 0.0 |
| `["transform", "Gaussian(dense) d=200 n=1024"]` | 4.658 | ✅ | 4.472 | 20.830 | 3200.2 | 0.0 | 13066.5 | 0.0 |
| `["transform", "Gaussian(dense) d=200 n=4096"]` | 5.096 | ✅ | 18.555 | 94.558 | 12800.2 | 0.0 | 52066.5 | 0.0 |
| `["transform", "Gaussian(dense) d=50 n=1024"]` | 2.871 | ✅ | 0.838 | 2.405 | 800.2 | 0.0 | 3316.5 | 0.0 |
| `["transform", "Gaussian(dense) d=50 n=4096"]` | 2.696 | ✅ | 3.709 | 9.998 | 3200.2 | 0.0 | 13066.5 | 0.0 |
| `["transform", "Gaussian(diag) d=200 n=1024"]` | 5.998 | ✅ | 3.463 | 20.771 | 1600.1 | 0.0 | 13066.5 | 0.0 |
| `["transform", "Gaussian(diag) d=200 n=4096"]` | 6.548 | ✅ | 14.347 | 93.942 | 6400.1 | 0.0 | 52066.5 | 0.0 |
| `["transform", "Gaussian(diag) d=50 n=1024"]` | 3.065 | ✅ | 0.774 | 2.372 | 400.1 | 0.0 | 3316.5 | 0.0 |
| `["transform", "Gaussian(diag) d=50 n=4096"]` | 2.852 | ✅ | 3.446 | 9.829 | 1600.1 | 0.0 | 13066.5 | 0.0 |
| `["transform", "JohnsonsSU d=10 n=1024"]` | 2.554 | ✅ | 0.198 | 0.506 | 160.2 | 0.0 | 716.5 | 0.0 |
| `["transform", "JohnsonsSU d=10 n=16384"]` | 2.377 | ✅ | 3.835 | 9.117 | 2560.2 | 0.0 | 10466.5 | 0.0 |
| `["transform", "JohnsonsSU d=10 n=256"]` | 3.669 | ✅ | 0.049 | 0.180 | 40.2 | 0.0 | 184.1 | 0.0 |
| `["transform", "JohnsonsSU d=10 n=4096"]` | 2.635 | ✅ | 0.867 | 2.284 | 640.2 | 0.0 | 2666.5 | 0.0 |
| `["transform", "StudentT d=10 n=1024"]` | 108.942 | ✅ | 0.051 | 5.505 | 80.1 | 0.0 | 519.7 | 0.0 |
| `["transform", "StudentT d=10 n=16384"]` | 87.600 | ✅ | 0.791 | 69.280 | 1280.1 | 0.0 | 7432.3 | 0.0 |
| `["transform", "StudentT d=10 n=256"]` | 173.590 | ✅ | 0.013 | 2.224 | 20.1 | 0.0 | 139.7 | 0.0 |
| `["transform", "StudentT d=10 n=4096"]` | 92.239 | ✅ | 0.199 | 18.360 | 320.1 | 0.0 | 1864.2 | 0.0 |

## Accuracy (integrate): solution agreement

Each criterion converges to within `tol` of the true value, so the Julia and
Python solutions should agree within **`2·tol`** (effective `tol = max(abs_tol,
rel_tol·|value|)`). Rows whose `|Julia − Python|` exceeds that bound are flagged ❌.

**0 of 11** matched integrate case(s) exceed 2×tolerance.

| integrate case | Julia | Python | abs Δ | rel Δ | tol mode | allowed 2·tol | verdict |
|:---------------|------:|-------:|------:|------:|:--------:|--------------:|:-------:|
| `CubMCCLT AsianOption` | 5.79516 | 5.80941 | 1.425e-02 | 2.45e-03 | abs | 1.000e+00 | ✅ |
| `CubMCCLT EuropeanOption` | 10.8219 | 10.4407 | 3.813e-01 | 3.65e-02 | abs | 1.000e+00 | ✅ |
| `CubMCCLT Keister` | 2.16964 | 2.16256 | 7.078e-03 | 3.27e-03 | abs | 2.000e-02 | ✅ |
| `CubQMCLatticeG EuropeanOption` | 10.3384 | 10.4714 | 1.330e-01 | 1.27e-02 | abs | 1.000e+00 | ✅ |
| `CubQMCLatticeG Keister` | 2.1682 | 2.17038 | 2.179e-03 | 1.00e-03 | abs | 2.000e-02 | ✅ |
| `CubQMCNetG AsianOption` | 5.86985 | 5.75769 | 1.122e-01 | 1.95e-02 | abs | 1.000e+00 | ✅ |
| `CubQMCNetG EuropeanOption` | 10.7209 | 10.4355 | 2.854e-01 | 2.73e-02 | abs | 1.000e+00 | ✅ |
| `CubQMCNetG Keister` | 2.16757 | 2.16925 | 1.671e-03 | 7.71e-04 | abs | 2.000e-02 | ✅ |
| `CubQMCNetGRep AsianOption` | 5.85986 | 5.75809 | 1.018e-01 | 1.77e-02 | abs | 1.000e+00 | ✅ |
| `CubQMCNetGRep EuropeanOption` | 10.46 | 10.4459 | 1.409e-02 | 1.35e-03 | abs | 1.000e+00 | ✅ |
| `CubQMCNetGRep Keister` | 2.1691 | 2.16407 | 5.026e-03 | 2.32e-03 | abs | 2.000e-02 | ✅ |

## Deterministic oracles (transform/evaluate)

These cases compare small fixed transform/evaluate outputs against QMCPy on the exact same deterministic inputs. Rows are flagged ❌ if any element exceeds `atol + rtol * |reference|`.

**0 of 11** deterministic oracle case(s) exceed elementwise tolerance.

| group | case | max abs Δ | max rel Δ | atol | rtol | failed elems | verdict |
|:------|:-----|----------:|----------:|-----:|-----:|-------------:|:-------:|
| `evaluate` | `BoxIntegral d=10 rows=4` | 1.110e-16 | 1.152e-16 | 1.0e-10 | 1.0e-10 | 0/4 | ✅ |
| `evaluate` | `Genz(continuous) d=10 rows=4` | 5.551e-17 | 2.749e-16 | 1.0e-10 | 1.0e-10 | 0/4 | ✅ |
| `evaluate` | `Genz(gaussian_peak) d=10 rows=4` | 0.000e+00 | 0.000e+00 | 1.0e-10 | 1.0e-10 | 0/4 | ✅ |
| `evaluate` | `Genz(oscillatory) rows=4` | 0.000e+00 | 0.000e+00 | 1.0e-10 | 1.0e-10 | 0/4 | ✅ |
| `evaluate` | `Keister rows=4` | 4.441e-16 | 1.169e-16 | 1.0e-10 | 1.0e-10 | 0/4 | ✅ |
| `evaluate` | `Linear0 d=10 rows=4` | 4.441e-16 | 1.144e-16 | 1.0e-10 | 1.0e-10 | 0/4 | ✅ |
| `transform` | `Gaussian d=3 rows=4` | 6.661e-16 | 6.216e-16 | 1.0e-10 | 1.0e-10 | 0/12 | ✅ |
| `transform` | `Gaussian(dense) d=50 rows=3` | 3.830e-15 | 1.681e-14 | 5.0e-10 | 5.0e-10 | 0/150 | ✅ |
| `transform` | `Gaussian(diag) d=50 rows=3` | 4.663e-15 | 2.412e-15 | 1.0e-10 | 1.0e-10 | 0/150 | ✅ |
| `transform` | `JohnsonsSU d=10 rows=4` | 8.882e-16 | 9.655e-16 | 1.0e-10 | 1.0e-10 | 0/40 | ✅ |
| `transform` | `StudentT d=1 rows=4` | 0.000e+00 | 0.000e+00 | 1.0e-07 | 1.0e-07 | 0/4 | ✅ |
