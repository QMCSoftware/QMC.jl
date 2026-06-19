# Benchmark: Julia (local) vs QMCPy (Python)

| | Julia (local) | Python (QMCPy) |
|---|---|---|
| Julia label | `sha-11aca0c` | — |
| Python label | — | `sha-11aca0c` |
| Julia artifact mtime | `2026-06-19T09:26:24` | — |
| Python artifact mtime | — | `2026-06-19T09:32:06` |
| Julia generated at | `2026-06-19T09:19:23` | — |
| Python generated at | — | `2026-06-19T09:32:06` |
| Julia BLAS threads | `2` | — |
| Python version | — | `3.13.14` |
| qmcpy version | — | 2.3 |
| integrate timing | `samples=9` | `repeat=9` |
| StudentT timing | `samples=21` | `repeat=21`, `warmup=3` |
| thread env | — | `MKL_NUM_THREADS=2, NUMEXPR_NUM_THREADS=2, OMP_NUM_THREADS=2, OPENBLAS_NUM_THREADS=2, QMC_BENCH_BLAS_THREADS=2` |

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
> Report generated at `2026-06-19T09:32:13`. Input artifact skew: `5 m 42 s`.

## Aggregate Summary

| metric | scope | ratio | Julia total | Python total | rows |
|:-------|:------|------:|------------:|-------------:|-----:|
| matched benchmarks | all matched rows | 111/111 | — | — | 111 |
| weighted time ratio | all matched rows | 4.968 | 184.635 ms | 917.270 ms | 111 |
| weighted time ratio | excluding StudentT | 4.453 | 183.582 ms | 817.422 ms | 107 |
| weighted time ratio | StudentT only | 94.827 | 1.053 ms | 99.848 ms | 4 |
| weighted time ratio 95% bootstrap CI | all matched rows | `[4.890, 5.072]` | — | — | 1000 |
| weighted time ratio 95% bootstrap CI | excluding StudentT | `[4.386, 4.540]` | — | — | 1000 |
| weighted time ratio 95% bootstrap CI | StudentT only | `[94.445, 95.064]` | — | — | 1000 |
| weighted approximate tracemalloc ratio | all matched rows | 4.611 | 164010.8 KiB | 756229.9 KiB | 111 |
| weighted approximate RSS delta ratio | all matched rows | 1.098 | 55792.0 KiB | 61264.0 KiB | 111 |


## Grouped Timing Summary

Generator, transform, integrand evaluation, and end-to-end adaptive integration are summarized separately below. The `integrate` group is mixed end-to-end cost, not isolated stopping-criterion overhead.

| group | interpretation | weighted time ratio | 95% bootstrap CI | Julia total | Python total | rows |
|:------|:---------------|--------------------:|:------------------|------------:|-------------:|-----:|
| `evaluate` | integrand evaluation only | 3.824 | `[3.415, 3.836]` | 1.855 ms | 7.095 ms | 36 |
| `gen_samples` | generator only | 5.881 | `[5.781, 6.040]` | 53.798 ms | 316.393 ms | 40 |
| `integrate` | end-to-end adaptive integration; not isolated stopping-criterion overhead | 3.151 | `[3.045, 3.310]` | 70.306 ms | 221.550 ms | 11 |
| `transform` | transform only | 6.344 | `[6.212, 6.355]` | 58.676 ms | 372.232 ms | 24 |

## Detailed Results

| benchmark | time ratio | verdict | Julia (ms) | Python (ms) | Julia alloc (KiB) | Julia RSS Δ (KiB) | Python peak (KiB) | Python RSS Δ (KiB) |
|:----------|-----------:|:-------:|----------:|------------:|-------------------:|------------------:|------------------:|-------------------:|
| `["evaluate", "BoxIntegral d=10 n=1024"]` | 4.398 | ✅ | 0.008 | 0.035 | 16.1 | 0.0 | 89.0 | 0.0 |
| `["evaluate", "BoxIntegral d=10 n=16384"]` | 3.717 | ✅ | 0.137 | 0.510 | 256.1 | 0.0 | 1409.0 | 0.0 |
| `["evaluate", "BoxIntegral d=10 n=256"]` | 4.273 | ✅ | 0.003 | 0.012 | 4.1 | 0.0 | 23.0 | 0.0 |
| `["evaluate", "BoxIntegral d=10 n=4096"]` | 3.889 | ✅ | 0.033 | 0.130 | 64.1 | 0.0 | 353.0 | 0.0 |
| `["evaluate", "BoxIntegral d=200 n=1024"]` | 4.250 | ✅ | 0.030 | 0.129 | 16.1 | 0.0 | 1609.0 | 0.0 |
| `["evaluate", "BoxIntegral d=200 n=4096"]` | 2.222 | ✅ | 0.210 | 0.466 | 64.1 | 0.0 | 6433.0 | 4.0 |
| `["evaluate", "BoxIntegral d=50 n=1024"]` | 4.224 | ✅ | 0.013 | 0.054 | 16.1 | 0.0 | 409.0 | 0.0 |
| `["evaluate", "BoxIntegral d=50 n=4096"]` | 3.090 | ✅ | 0.070 | 0.217 | 64.1 | 0.0 | 1633.0 | 0.0 |
| `["evaluate", "Genz(continuous) d=10 n=1024"]` | 5.997 | ✅ | 0.007 | 0.041 | 16.1 | 0.0 | 160.2 | 0.0 |
| `["evaluate", "Genz(continuous) d=10 n=16384"]` | 4.907 | ✅ | 0.123 | 0.604 | 256.1 | 0.0 | 2560.2 | 0.0 |
| `["evaluate", "Genz(continuous) d=10 n=256"]` | 6.064 | ✅ | 0.002 | 0.015 | 4.1 | 0.0 | 40.2 | 0.0 |
| `["evaluate", "Genz(continuous) d=10 n=4096"]` | 5.236 | ✅ | 0.030 | 0.155 | 64.1 | 0.0 | 640.2 | 0.0 |
| `["evaluate", "Genz(gaussian_peak) d=10 n=1024"]` | 5.813 | ✅ | 0.007 | 0.042 | 16.1 | 0.0 | 169.2 | 0.0 |
| `["evaluate", "Genz(gaussian_peak) d=10 n=16384"]` | 4.913 | ✅ | 0.123 | 0.604 | 256.1 | 0.0 | 2689.2 | 0.0 |
| `["evaluate", "Genz(gaussian_peak) d=10 n=256"]` | 6.063 | ✅ | 0.002 | 0.015 | 4.1 | 0.0 | 43.2 | 0.0 |
| `["evaluate", "Genz(gaussian_peak) d=10 n=4096"]` | 5.597 | ✅ | 0.028 | 0.156 | 64.1 | 0.0 | 673.2 | 0.0 |
| `["evaluate", "Genz(gaussian_peak) d=200 n=1024"]` | 5.804 | ✅ | 0.033 | 0.193 | 16.1 | 0.0 | 3209.2 | 0.0 |
| `["evaluate", "Genz(gaussian_peak) d=200 n=4096"]` | 3.381 | ✅ | 0.210 | 0.712 | 64.1 | 0.0 | 12833.2 | 0.0 |
| `["evaluate", "Genz(gaussian_peak) d=50 n=1024"]` | 6.080 | ✅ | 0.012 | 0.073 | 16.1 | 0.0 | 809.2 | 0.0 |
| `["evaluate", "Genz(gaussian_peak) d=50 n=4096"]` | 4.105 | ✅ | 0.071 | 0.293 | 64.1 | 0.0 | 3233.2 | 0.0 |
| `["evaluate", "Genz(oscillatory) n=1024"]` | 3.508 | ✅ | 0.012 | 0.043 | 16.1 | 0.0 | 49.2 | 0.0 |
| `["evaluate", "Genz(oscillatory) n=16384"]` | 5.174 | ✅ | 0.121 | 0.625 | 256.1 | 0.0 | 513.0 | 0.0 |
| `["evaluate", "Genz(oscillatory) n=256"]` | 5.266 | ✅ | 0.003 | 0.014 | 4.1 | 0.0 | 13.2 | 0.0 |
| `["evaluate", "Genz(oscillatory) n=4096"]` | 5.552 | ✅ | 0.028 | 0.158 | 64.1 | 0.0 | 161.2 | 0.0 |
| `["evaluate", "Keister n=1024"]` | 3.762 | ✅ | 0.011 | 0.040 | 24.3 | 0.0 | 40.3 | 0.0 |
| `["evaluate", "Keister n=16384"]` | 3.407 | ✅ | 0.162 | 0.551 | 384.3 | 0.0 | 640.3 | 0.0 |
| `["evaluate", "Keister n=256"]` | 3.803 | ✅ | 0.004 | 0.014 | 6.3 | 14896.0 | 10.3 | 0.0 |
| `["evaluate", "Keister n=4096"]` | 3.447 | ✅ | 0.041 | 0.142 | 96.3 | 0.0 | 160.3 | 0.0 |
| `["evaluate", "Linear0 d=10 n=1024"]` | 14.149 | ✅ | 0.002 | 0.027 | 8.1 | 0.0 | 8.9 | 0.0 |
| `["evaluate", "Linear0 d=10 n=16384"]` | 9.200 | ✅ | 0.045 | 0.416 | 128.1 | 0.0 | 128.9 | 0.0 |
| `["evaluate", "Linear0 d=10 n=256"]` | 9.099 | ✅ | 0.001 | 0.008 | 2.1 | 6848.0 | 2.9 | 0.0 |
| `["evaluate", "Linear0 d=10 n=4096"]` | 11.355 | ✅ | 0.009 | 0.105 | 32.1 | 0.0 | 32.9 | 0.0 |
| `["evaluate", "Linear0 d=200 n=1024"]` | 2.729 | ✅ | 0.024 | 0.067 | 8.1 | 0.0 | 8.9 | 0.0 |
| `["evaluate", "Linear0 d=200 n=4096"]` | 1.377 | ✅ | 0.187 | 0.257 | 32.1 | 0.0 | 32.9 | 0.0 |
| `["evaluate", "Linear0 d=50 n=1024"]` | 5.828 | ✅ | 0.006 | 0.036 | 8.1 | 0.0 | 8.9 | 0.0 |
| `["evaluate", "Linear0 d=50 n=4096"]` | 3.027 | ✅ | 0.047 | 0.141 | 32.1 | 0.0 | 32.9 | 0.0 |
| `["gen_samples", "DigitalNetB2 d=10 n=1024"]` `[C]` | 2.730 | ✅ | 0.037 | 0.101 | 168.8 | 0.0 | 108.4 | 0.0 |
| `["gen_samples", "DigitalNetB2 d=10 n=16384"]` `[C]` | 0.262 | ❌ | 1.520 | 0.398 | 2568.8 | 2224.0 | 1308.4 | 0.0 |
| `["gen_samples", "DigitalNetB2 d=10 n=256"]` `[C]` | 5.055 | ✅ | 0.017 | 0.086 | 48.8 | 0.0 | 48.4 | 0.0 |
| `["gen_samples", "DigitalNetB2 d=10 n=4096"]` `[C]` | 1.296 | ✅ | 0.119 | 0.154 | 648.8 | 0.0 | 348.4 | 0.0 |
| `["gen_samples", "DigitalNetB2 d=3 n=1024"]` `[C]` | 6.220 | ✅ | 0.015 | 0.092 | 51.0 | 0.0 | 52.4 | 0.0 |
| `["gen_samples", "DigitalNetB2 d=3 n=16384"]` `[C]` | 1.308 | ✅ | 0.175 | 0.229 | 771.0 | 4576.0 | 412.4 | 0.0 |
| `["gen_samples", "DigitalNetB2 d=3 n=256"]` `[C]` | 13.404 | ✅ | 0.006 | 0.084 | 15.0 | 0.0 | 34.4 | 0.0 |
| `["gen_samples", "DigitalNetB2 d=3 n=4096"]` `[C]` | 2.465 | ✅ | 0.049 | 0.120 | 195.0 | 0.0 | 124.4 | 0.0 |
| `["gen_samples", "Halton d=10 n=1024"]` `[C]` | 5.716 | ✅ | 1.452 | 8.298 | 82.7 | 0.0 | 10191.4 | 0.0 |
| `["gen_samples", "Halton d=10 n=16384"]` `[C]` | 7.109 | ✅ | 23.644 | 168.077 | 1282.7 | 0.0 | 162591.4 | 0.0 |
| `["gen_samples", "Halton d=10 n=256"]` `[C]` | 4.987 | ✅ | 0.395 | 1.969 | 22.7 | 0.0 | 2571.4 | 0.0 |
| `["gen_samples", "Halton d=10 n=4096"]` `[C]` | 6.442 | ✅ | 5.693 | 36.676 | 322.7 | 0.0 | 40671.4 | 0.0 |
| `["gen_samples", "Halton d=3 n=1024"]` `[C]` | 10.051 | ✅ | 0.458 | 4.603 | 25.0 | 2832.0 | 3079.4 | 0.0 |
| `["gen_samples", "Halton d=3 n=16384"]` `[C]` | 8.320 | ✅ | 7.980 | 66.394 | 385.0 | 0.0 | 48799.4 | 0.0 |
| `["gen_samples", "Halton d=3 n=256"]` `[C]` | 7.524 | ✅ | 0.111 | 0.836 | 7.0 | 0.0 | 793.4 | 0.0 |
| `["gen_samples", "Halton d=3 n=4096"]` `[C]` | 8.342 | ✅ | 1.918 | 16.000 | 97.0 | 0.0 | 12223.4 | 0.0 |
| `["gen_samples", "IIDStdUniform d=10 n=1024"]` | 5.274 | ✅ | 0.008 | 0.044 | 80.1 | 0.0 | 80.8 | 0.0 |
| `["gen_samples", "IIDStdUniform d=10 n=16384"]` | 1.693 | ✅ | 0.489 | 0.828 | 1280.1 | 0.0 | 1280.8 | 0.0 |
| `["gen_samples", "IIDStdUniform d=10 n=256"]` | 5.498 | ✅ | 0.002 | 0.013 | 20.1 | 0.0 | 20.7 | 0.0 |
| `["gen_samples", "IIDStdUniform d=10 n=4096"]` | 5.917 | ✅ | 0.028 | 0.164 | 320.1 | 0.0 | 320.8 | 0.0 |
| `["gen_samples", "IIDStdUniform d=3 n=1024"]` | 6.355 | ✅ | 0.002 | 0.016 | 24.1 | 0.0 | 24.8 | 0.0 |
| `["gen_samples", "IIDStdUniform d=3 n=16384"]` | 6.444 | ✅ | 0.031 | 0.197 | 384.1 | 0.0 | 384.8 | 0.0 |
| `["gen_samples", "IIDStdUniform d=3 n=256"]` | 6.027 | ✅ | 0.001 | 0.007 | 6.1 | 0.0 | 6.7 | 0.0 |
| `["gen_samples", "IIDStdUniform d=3 n=4096"]` | 5.667 | ✅ | 0.009 | 0.052 | 96.1 | 1456.0 | 96.8 | 0.0 |
| `["gen_samples", "Kronecker d=10 n=1024"]` | 2.288 | ✅ | 0.074 | 0.168 | 80.1 | 0.0 | 233.6 | 0.0 |
| `["gen_samples", "Kronecker d=10 n=16384"]` | 1.604 | ✅ | 1.741 | 2.792 | 1280.1 | 0.0 | 2753.6 | 0.0 |
| `["gen_samples", "Kronecker d=10 n=256"]` | 2.543 | ✅ | 0.018 | 0.046 | 20.1 | 0.0 | 63.6 | 0.0 |
| `["gen_samples", "Kronecker d=10 n=4096"]` | 2.065 | ✅ | 0.330 | 0.681 | 320.1 | 0.0 | 737.6 | 0.0 |
| `["gen_samples", "Kronecker d=3 n=1024"]` | 3.060 | ✅ | 0.021 | 0.065 | 24.1 | 0.0 | 81.6 | 0.0 |
| `["gen_samples", "Kronecker d=3 n=16384"]` | 2.419 | ✅ | 0.415 | 1.004 | 384.1 | 0.0 | 961.6 | 0.0 |
| `["gen_samples", "Kronecker d=3 n=256"]` | 3.668 | ✅ | 0.006 | 0.021 | 6.1 | 0.0 | 21.6 | 0.0 |
| `["gen_samples", "Kronecker d=3 n=4096"]` | 2.602 | ✅ | 0.095 | 0.247 | 96.1 | 0.0 | 289.6 | 0.0 |
| `["gen_samples", "Lattice d=10 n=1024"]` `[C]` | 1.515 | ✅ | 0.194 | 0.295 | 240.9 | 0.0 | 189.2 | 0.0 |
| `["gen_samples", "Lattice d=10 n=16384"]` `[C]` | 0.645 | ❌ | 4.749 | 3.063 | 3840.9 | 0.0 | 2589.2 | 0.0 |
| `["gen_samples", "Lattice d=10 n=256"]` `[C]` | 3.137 | ✅ | 0.049 | 0.153 | 60.9 | 4208.0 | 69.2 | 0.0 |
| `["gen_samples", "Lattice d=10 n=4096"]` `[C]` | 1.104 | ✅ | 0.774 | 0.855 | 960.9 | 0.0 | 669.2 | 0.0 |
| `["gen_samples", "Lattice d=3 n=1024"]` `[C]` | 2.785 | ✅ | 0.058 | 0.161 | 72.4 | 0.0 | 77.2 | 0.0 |
| `["gen_samples", "Lattice d=3 n=16384"]` `[C]` | 1.093 | ✅ | 0.880 | 0.961 | 1152.4 | 0.0 | 797.2 | 0.0 |
| `["gen_samples", "Lattice d=3 n=256"]` `[C]` | 8.281 | ✅ | 0.014 | 0.120 | 18.4 | 2464.0 | 41.2 | 0.0 |
| `["gen_samples", "Lattice d=3 n=4096"]` `[C]` | 1.453 | ✅ | 0.222 | 0.322 | 288.4 | 0.0 | 221.2 | 0.0 |
| `["integrate", "CubMCCLT AsianOption"]` | 3.859 | ✅ | 3.132 | 12.085 | 2928.2 | 0.0 | 11001.7 | 0.0 |
| `["integrate", "CubMCCLT EuropeanOption"]` | 4.449 | ✅ | 6.492 | 28.887 | 7199.6 | 0.0 | 33415.8 | 0.0 |
| `["integrate", "CubMCCLT Keister"]` | 7.585 | ✅ | 12.516 | 94.937 | 32156.9 | 0.0 | 123185.4 | 59000.0 |
| `["integrate", "CubQMCLatticeG EuropeanOption"]` `[C]` | 2.429 | ✅ | 2.238 | 5.436 | 2077.1 | 0.0 | 4583.1 | 0.0 |
| `["integrate", "CubQMCLatticeG Keister"]` `[C]` | 6.316 | ✅ | 0.440 | 2.777 | 570.7 | 0.0 | 400.5 | 328.0 |
| `["integrate", "CubQMCNetG AsianOption"]` | 4.602 | ✅ | 1.267 | 5.832 | 1718.6 | 1424.0 | 4196.3 | 8.0 |
| `["integrate", "CubQMCNetG EuropeanOption"]` | 4.667 | ✅ | 1.244 | 5.807 | 1710.6 | 0.0 | 4196.6 | 0.0 |
| `["integrate", "CubQMCNetG Keister"]` | 11.645 | ✅ | 0.270 | 3.141 | 441.3 | 0.0 | 514.8 | 8.0 |
| `["integrate", "CubQMCNetGRep AsianOption"]` | 1.493 | ✅ | 20.141 | 30.064 | 26548.9 | 0.0 | 16561.0 | 1472.0 |
| `["integrate", "CubQMCNetGRep EuropeanOption"]` | 1.555 | ✅ | 19.104 | 29.702 | 26419.8 | 7376.0 | 16561.0 | 0.0 |
| `["integrate", "CubQMCNetGRep Keister"]` | 0.833 | ❌ | 3.462 | 2.884 | 4732.8 | 0.0 | 1104.2 | 64.0 |
| `["transform", "Gaussian d=10 n=1024"]` | 3.411 | ✅ | 0.122 | 0.415 | 80.1 | 0.0 | 716.5 | 0.0 |
| `["transform", "Gaussian d=10 n=16384"]` | 2.165 | ✅ | 2.757 | 5.967 | 1280.1 | 0.0 | 10466.5 | 0.0 |
| `["transform", "Gaussian d=10 n=256"]` | 5.355 | ✅ | 0.029 | 0.158 | 20.1 | 0.0 | 184.1 | 0.0 |
| `["transform", "Gaussian d=10 n=4096"]` | 2.711 | ✅ | 0.563 | 1.526 | 320.1 | 0.0 | 2666.5 | 0.0 |
| `["transform", "Gaussian d=3 n=1024"]` | 4.706 | ✅ | 0.037 | 0.175 | 24.1 | 0.0 | 220.6 | 0.0 |
| `["transform", "Gaussian d=3 n=16384"]` | 2.387 | ✅ | 0.765 | 1.826 | 384.1 | 1280.0 | 3186.5 | 0.0 |
| `["transform", "Gaussian d=3 n=256"]` | 10.231 | ✅ | 0.009 | 0.095 | 6.1 | 0.0 | 56.4 | 0.0 |
| `["transform", "Gaussian d=3 n=4096"]` | 3.276 | ✅ | 0.147 | 0.481 | 96.1 | 0.0 | 846.5 | 0.0 |
| `["transform", "Gaussian(dense) d=200 n=1024"]` | 4.632 | ✅ | 4.451 | 20.621 | 3200.2 | 0.0 | 13066.5 | 0.0 |
| `["transform", "Gaussian(dense) d=200 n=4096"]` | 5.173 | ✅ | 17.927 | 92.732 | 12800.2 | 2752.0 | 52066.5 | 0.0 |
| `["transform", "Gaussian(dense) d=50 n=1024"]` | 2.851 | ✅ | 0.833 | 2.375 | 800.2 | 0.0 | 3316.5 | 0.0 |
| `["transform", "Gaussian(dense) d=50 n=4096"]` | 2.561 | ✅ | 3.667 | 9.393 | 3200.2 | 0.0 | 13066.5 | 0.0 |
| `["transform", "Gaussian(diag) d=200 n=1024"]` | 5.893 | ✅ | 3.429 | 20.206 | 1600.1 | 0.0 | 13066.5 | 0.0 |
| `["transform", "Gaussian(diag) d=200 n=4096"]` | 6.754 | ✅ | 13.774 | 93.035 | 6400.1 | 0.0 | 52066.5 | 0.0 |
| `["transform", "Gaussian(diag) d=50 n=1024"]` | 3.119 | ✅ | 0.762 | 2.378 | 400.1 | 0.0 | 3316.5 | 0.0 |
| `["transform", "Gaussian(diag) d=50 n=4096"]` | 2.689 | ✅ | 3.432 | 9.226 | 1600.1 | 0.0 | 13066.5 | 0.0 |
| `["transform", "JohnsonsSU d=10 n=1024"]` | 2.577 | ✅ | 0.195 | 0.502 | 160.2 | 1888.0 | 716.5 | 0.0 |
| `["transform", "JohnsonsSU d=10 n=16384"]` | 2.313 | ✅ | 3.817 | 8.828 | 2560.2 | 0.0 | 10466.5 | 0.0 |
| `["transform", "JohnsonsSU d=10 n=256"]` | 3.732 | ✅ | 0.048 | 0.180 | 40.2 | 0.0 | 184.1 | 0.0 |
| `["transform", "JohnsonsSU d=10 n=4096"]` | 2.638 | ✅ | 0.859 | 2.265 | 640.2 | 0.0 | 2666.5 | 0.0 |
| `["transform", "StudentT d=10 n=1024"]` | 110.851 | ✅ | 0.051 | 5.682 | 80.1 | 1568.0 | 519.5 | 0.0 |
| `["transform", "StudentT d=10 n=16384"]` | 92.525 | ✅ | 0.790 | 73.081 | 1280.1 | 0.0 | 6535.3 | 380.0 |
| `["transform", "StudentT d=10 n=256"]` | 178.234 | ✅ | 0.013 | 2.268 | 20.1 | 0.0 | 139.4 | 0.0 |
| `["transform", "StudentT d=10 n=4096"]` | 94.505 | ✅ | 0.199 | 18.817 | 320.1 | 0.0 | 1671.5 | 0.0 |

## Accuracy (integrate): solution agreement

Each criterion converges to within `tol` of the true value, so the Julia and
Python solutions should agree within **`2·tol`** (effective `tol = max(abs_tol,
rel_tol·|value|)`). Rows whose `|Julia − Python|` exceeds that bound are flagged ❌.

**0 of 11** matched integrate case(s) exceed 2×tolerance.

| integrate case | Julia | Python | abs Δ | rel Δ | tol mode | allowed 2·tol | verdict |
|:---------------|------:|-------:|------:|------:|:--------:|--------------:|:-------:|
| `CubMCCLT AsianOption` | 5.8309 | 5.80941 | 2.149e-02 | 3.70e-03 | abs | 1.000e+00 | ✅ |
| `CubMCCLT EuropeanOption` | 10.8932 | 10.4407 | 4.526e-01 | 4.33e-02 | abs | 1.000e+00 | ✅ |
| `CubMCCLT Keister` | 2.16845 | 2.16256 | 5.888e-03 | 2.72e-03 | abs | 2.000e-02 | ✅ |
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
