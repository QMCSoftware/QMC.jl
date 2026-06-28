# Benchmark: Julia (local) vs QMCPy (Python)

| | Julia (local) | Python (QMCPy) |
|---|---|---|
| Julia label | `sha-61f7244` | — |
| Python label | — | `sha-61f7244` |
| Julia artifact mtime | `2026-06-28T13:42:48` | — |
| Python artifact mtime | — | `2026-06-28T13:48:28` |
| Julia generated at | `2026-06-28T13:35:05` | — |
| Python generated at | — | `2026-06-28T13:48:28` |
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
> Report generated at `2026-06-28T13:48:34`. Input artifact skew: `5 m 39 s`.

## Aggregate Summary

| metric | scope | ratio | Julia total | Python total | rows |
|:-------|:------|------:|------------:|-------------:|-----:|
| matched benchmarks | all matched rows | 111/111 | — | — | 111 |
| weighted time ratio | all matched rows | 4.743 | 193.520 ms | 917.774 ms | 111 |
| weighted time ratio | excluding StudentT | 4.279 | 192.464 ms | 823.583 ms | 107 |
| weighted time ratio | StudentT only | 89.193 | 1.056 ms | 94.190 ms | 4 |
| weighted time ratio 95% bootstrap CI | all matched rows | `[4.665, 4.815]` | — | — | 1000 |
| weighted time ratio 95% bootstrap CI | excluding StudentT | `[4.213, 4.346]` | — | — | 1000 |
| weighted time ratio 95% bootstrap CI | StudentT only | `[88.840, 89.585]` | — | — | 1000 |
| weighted approximate tracemalloc ratio | all matched rows | 4.377 | 173037.5 KiB | 757323.6 KiB | 111 |
| weighted approximate RSS delta ratio | all matched rows | 2.926 | 27408.0 KiB | 80200.0 KiB | 111 |

> ℹ️ RSS delta ratio compares retained process RSS after one warmed call; ratio < 1 means Python retained less RSS than Julia, and ratio > 1 means Python retained more. Treat it as an approximate retained-footprint signal, not a direct allocation metric.

## Grouped Timing Summary

Generator, transform, integrand evaluation, and end-to-end adaptive integration are summarized separately below. The `integrate` group is mixed end-to-end cost, not isolated stopping-criterion overhead.

| group | interpretation | weighted time ratio | 95% bootstrap CI | Julia total | Python total | rows |
|:------|:---------------|--------------------:|:------------------|------------:|-------------:|-----:|
| `evaluate` | integrand evaluation only | 3.561 | `[3.044, 3.608]` | 2.097 ms | 7.468 ms | 36 |
| `gen_samples` | generator only | 5.374 | `[5.298, 5.423]` | 58.786 ms | 315.928 ms | 40 |
| `integrate` | end-to-end adaptive integration; not isolated stopping-criterion overhead | 3.058 | `[2.945, 3.181]` | 73.671 ms | 225.265 ms | 11 |
| `transform` | transform only | 6.260 | `[6.133, 6.334]` | 58.965 ms | 369.113 ms | 24 |

## Detailed Results

| benchmark | time ratio | verdict | Julia (ms) | Python (ms) | Julia alloc (KiB) | Julia RSS Δ (KiB) | Python peak (KiB) | Python RSS Δ (KiB) |
|:----------|-----------:|:-------:|----------:|------------:|-------------------:|------------------:|------------------:|-------------------:|
| `["evaluate", "BoxIntegral d=10 n=1024"]` | 4.613 | ✅ | 0.007 | 0.035 | 16.1 | 0.0 | 89.0 | 0.0 |
| `["evaluate", "BoxIntegral d=10 n=16384"]` | 2.066 | ✅ | 0.247 | 0.510 | 256.1 | 0.0 | 1409.0 | 0.0 |
| `["evaluate", "BoxIntegral d=10 n=256"]` | 4.419 | ✅ | 0.003 | 0.012 | 4.1 | 0.0 | 23.0 | 0.0 |
| `["evaluate", "BoxIntegral d=10 n=4096"]` | 3.991 | ✅ | 0.032 | 0.129 | 64.1 | 0.0 | 353.0 | 0.0 |
| `["evaluate", "BoxIntegral d=200 n=1024"]` | 3.815 | ✅ | 0.039 | 0.148 | 16.1 | 0.0 | 1609.0 | 0.0 |
| `["evaluate", "BoxIntegral d=200 n=4096"]` | 2.185 | ✅ | 0.213 | 0.465 | 64.1 | 0.0 | 6433.0 | 0.0 |
| `["evaluate", "BoxIntegral d=50 n=1024"]` | 4.303 | ✅ | 0.012 | 0.053 | 16.1 | 0.0 | 409.0 | 0.0 |
| `["evaluate", "BoxIntegral d=50 n=4096"]` | 2.923 | ✅ | 0.078 | 0.229 | 64.1 | 0.0 | 1633.0 | 0.0 |
| `["evaluate", "Genz(continuous) d=10 n=1024"]` | 5.680 | ✅ | 0.007 | 0.042 | 16.1 | 0.0 | 160.2 | 0.0 |
| `["evaluate", "Genz(continuous) d=10 n=16384"]` | 4.265 | ✅ | 0.141 | 0.603 | 256.1 | 0.0 | 2560.2 | 0.0 |
| `["evaluate", "Genz(continuous) d=10 n=256"]` | 5.717 | ✅ | 0.003 | 0.015 | 4.1 | 0.0 | 40.2 | 0.0 |
| `["evaluate", "Genz(continuous) d=10 n=4096"]` | 5.077 | ✅ | 0.031 | 0.155 | 64.1 | 0.0 | 640.2 | 0.0 |
| `["evaluate", "Genz(gaussian_peak) d=10 n=1024"]` | 4.118 | ✅ | 0.010 | 0.042 | 16.1 | 0.0 | 169.2 | 0.0 |
| `["evaluate", "Genz(gaussian_peak) d=10 n=16384"]` | 4.426 | ✅ | 0.139 | 0.615 | 256.1 | 0.0 | 2689.2 | 0.0 |
| `["evaluate", "Genz(gaussian_peak) d=10 n=256"]` | 5.842 | ✅ | 0.003 | 0.015 | 4.1 | 4272.0 | 43.2 | 0.0 |
| `["evaluate", "Genz(gaussian_peak) d=10 n=4096"]` | 5.250 | ✅ | 0.030 | 0.156 | 64.1 | 0.0 | 673.2 | 0.0 |
| `["evaluate", "Genz(gaussian_peak) d=200 n=1024"]` | 7.972 | ✅ | 0.040 | 0.320 | 16.1 | 0.0 | 3209.2 | 0.0 |
| `["evaluate", "Genz(gaussian_peak) d=200 n=4096"]` | 3.570 | ✅ | 0.208 | 0.741 | 64.1 | 0.0 | 12833.2 | 0.0 |
| `["evaluate", "Genz(gaussian_peak) d=50 n=1024"]` | 5.986 | ✅ | 0.012 | 0.074 | 16.1 | 0.0 | 809.2 | 0.0 |
| `["evaluate", "Genz(gaussian_peak) d=50 n=4096"]` | 4.736 | ✅ | 0.087 | 0.414 | 64.1 | 0.0 | 3233.2 | 0.0 |
| `["evaluate", "Genz(oscillatory) n=1024"]` | 5.498 | ✅ | 0.008 | 0.042 | 16.1 | 0.0 | 49.2 | 0.0 |
| `["evaluate", "Genz(oscillatory) n=16384"]` | 5.600 | ✅ | 0.121 | 0.678 | 256.1 | 0.0 | 513.0 | 0.0 |
| `["evaluate", "Genz(oscillatory) n=256"]` | 4.990 | ✅ | 0.003 | 0.014 | 4.1 | 0.0 | 13.2 | 0.0 |
| `["evaluate", "Genz(oscillatory) n=4096"]` | 5.527 | ✅ | 0.029 | 0.163 | 64.1 | 0.0 | 161.2 | 0.0 |
| `["evaluate", "Keister n=1024"]` | 3.602 | ✅ | 0.011 | 0.040 | 24.3 | 5264.0 | 40.3 | 0.0 |
| `["evaluate", "Keister n=16384"]` | 2.928 | ✅ | 0.188 | 0.551 | 384.3 | 0.0 | 640.3 | 0.0 |
| `["evaluate", "Keister n=256"]` | 3.716 | ✅ | 0.004 | 0.014 | 6.3 | 0.0 | 10.3 | 0.0 |
| `["evaluate", "Keister n=4096"]` | 3.384 | ✅ | 0.042 | 0.142 | 96.3 | 0.0 | 160.3 | 0.0 |
| `["evaluate", "Linear0 d=10 n=1024"]` | 11.943 | ✅ | 0.002 | 0.027 | 8.1 | 0.0 | 8.9 | 0.0 |
| `["evaluate", "Linear0 d=10 n=16384"]` | 7.713 | ✅ | 0.054 | 0.414 | 128.1 | 0.0 | 128.9 | 0.0 |
| `["evaluate", "Linear0 d=10 n=256"]` | 8.090 | ✅ | 0.001 | 0.008 | 2.1 | 0.0 | 2.9 | 0.0 |
| `["evaluate", "Linear0 d=10 n=4096"]` | 11.351 | ✅ | 0.009 | 0.104 | 32.1 | 48.0 | 32.9 | 0.0 |
| `["evaluate", "Linear0 d=200 n=1024"]` | 2.118 | ✅ | 0.031 | 0.066 | 8.1 | 0.0 | 8.9 | 0.0 |
| `["evaluate", "Linear0 d=200 n=4096"]` | 1.357 | ✅ | 0.189 | 0.257 | 32.1 | 0.0 | 32.9 | 0.0 |
| `["evaluate", "Linear0 d=50 n=1024"]` | 5.442 | ✅ | 0.007 | 0.035 | 8.1 | 3248.0 | 8.9 | 0.0 |
| `["evaluate", "Linear0 d=50 n=4096"]` | 2.517 | ✅ | 0.056 | 0.140 | 32.1 | 0.0 | 32.9 | 0.0 |
| `["gen_samples", "DigitalNetB2 d=10 n=1024"]` `[C]` | 2.025 | ✅ | 0.050 | 0.100 | 168.9 | 0.0 | 108.4 | 0.0 |
| `["gen_samples", "DigitalNetB2 d=10 n=16384"]` `[C]` | 0.231 | ❌ | 1.555 | 0.359 | 2568.9 | 0.0 | 1308.4 | 0.0 |
| `["gen_samples", "DigitalNetB2 d=10 n=256"]` `[C]` | 5.212 | ✅ | 0.017 | 0.087 | 48.9 | 0.0 | 48.4 | 0.0 |
| `["gen_samples", "DigitalNetB2 d=10 n=4096"]` `[C]` | 0.731 | ❌ | 0.210 | 0.154 | 648.9 | 0.0 | 348.4 | 0.0 |
| `["gen_samples", "DigitalNetB2 d=3 n=1024"]` `[C]` | 6.397 | ✅ | 0.015 | 0.093 | 51.1 | 0.0 | 52.4 | 0.0 |
| `["gen_samples", "DigitalNetB2 d=3 n=16384"]` `[C]` | 1.101 | ✅ | 0.208 | 0.229 | 771.1 | 0.0 | 412.4 | 0.0 |
| `["gen_samples", "DigitalNetB2 d=3 n=256"]` `[C]` | 12.800 | ✅ | 0.007 | 0.087 | 15.1 | 0.0 | 34.4 | 0.0 |
| `["gen_samples", "DigitalNetB2 d=3 n=4096"]` `[C]` | 2.427 | ✅ | 0.049 | 0.120 | 195.1 | 0.0 | 124.4 | 0.0 |
| `["gen_samples", "Halton d=10 n=1024"]` `[C]` | 5.362 | ✅ | 1.543 | 8.274 | 82.8 | 0.0 | 10191.6 | 0.0 |
| `["gen_samples", "Halton d=10 n=16384"]` `[C]` | 6.367 | ✅ | 26.404 | 168.113 | 1282.8 | 0.0 | 162591.5 | 0.0 |
| `["gen_samples", "Halton d=10 n=256"]` `[C]` | 5.205 | ✅ | 0.377 | 1.964 | 22.8 | 0.0 | 2571.6 | 0.0 |
| `["gen_samples", "Halton d=10 n=4096"]` `[C]` | 5.884 | ✅ | 6.289 | 37.004 | 322.8 | 272.0 | 40671.5 | 0.0 |
| `["gen_samples", "Halton d=3 n=1024"]` `[C]` | 9.172 | ✅ | 0.502 | 4.600 | 25.0 | 0.0 | 3079.6 | 0.0 |
| `["gen_samples", "Halton d=3 n=16384"]` `[C]` | 7.567 | ✅ | 8.677 | 65.664 | 385.0 | 0.0 | 48799.6 | 0.0 |
| `["gen_samples", "Halton d=3 n=256"]` `[C]` | 6.956 | ✅ | 0.120 | 0.832 | 7.0 | 0.0 | 793.6 | 0.0 |
| `["gen_samples", "Halton d=3 n=4096"]` `[C]` | 7.725 | ✅ | 2.090 | 16.147 | 97.0 | 0.0 | 12223.5 | 0.0 |
| `["gen_samples", "IIDStdUniform d=10 n=1024"]` | 5.040 | ✅ | 0.009 | 0.044 | 80.1 | 0.0 | 80.8 | 0.0 |
| `["gen_samples", "IIDStdUniform d=10 n=16384"]` | 0.978 | – | 0.659 | 0.645 | 1280.1 | 0.0 | 1280.8 | 0.0 |
| `["gen_samples", "IIDStdUniform d=10 n=256"]` | 5.838 | ✅ | 0.002 | 0.014 | 20.1 | 0.0 | 20.7 | 0.0 |
| `["gen_samples", "IIDStdUniform d=10 n=4096"]` | 6.226 | ✅ | 0.026 | 0.164 | 320.1 | 0.0 | 320.8 | 0.0 |
| `["gen_samples", "IIDStdUniform d=3 n=1024"]` | 5.665 | ✅ | 0.003 | 0.016 | 24.1 | 0.0 | 24.8 | 0.0 |
| `["gen_samples", "IIDStdUniform d=3 n=16384"]` | 6.319 | ✅ | 0.031 | 0.196 | 384.1 | 2272.0 | 384.8 | 0.0 |
| `["gen_samples", "IIDStdUniform d=3 n=256"]` | 5.601 | ✅ | 0.001 | 0.007 | 6.1 | 0.0 | 6.7 | 0.0 |
| `["gen_samples", "IIDStdUniform d=3 n=4096"]` | 4.637 | ✅ | 0.011 | 0.052 | 96.1 | 0.0 | 96.8 | 0.0 |
| `["gen_samples", "Kronecker d=10 n=1024"]` | 2.237 | ✅ | 0.076 | 0.169 | 80.1 | 0.0 | 233.6 | 0.0 |
| `["gen_samples", "Kronecker d=10 n=16384"]` | 1.457 | ✅ | 1.910 | 2.782 | 1280.1 | 0.0 | 2753.6 | 0.0 |
| `["gen_samples", "Kronecker d=10 n=256"]` | 2.561 | ✅ | 0.018 | 0.046 | 20.1 | 0.0 | 63.6 | 0.0 |
| `["gen_samples", "Kronecker d=10 n=4096"]` | 2.044 | ✅ | 0.332 | 0.679 | 320.1 | 0.0 | 737.6 | 0.0 |
| `["gen_samples", "Kronecker d=3 n=1024"]` | 3.044 | ✅ | 0.021 | 0.065 | 24.1 | 0.0 | 81.6 | 0.0 |
| `["gen_samples", "Kronecker d=3 n=16384"]` | 2.446 | ✅ | 0.415 | 1.015 | 384.1 | 0.0 | 961.6 | 0.0 |
| `["gen_samples", "Kronecker d=3 n=256"]` | 3.678 | ✅ | 0.006 | 0.021 | 6.1 | 0.0 | 21.6 | 0.0 |
| `["gen_samples", "Kronecker d=3 n=4096"]` | 2.587 | ✅ | 0.097 | 0.250 | 96.1 | 4944.0 | 289.6 | 0.0 |
| `["gen_samples", "Lattice d=10 n=1024"]` `[C]` | 1.498 | ✅ | 0.197 | 0.294 | 240.9 | 0.0 | 189.3 | 0.0 |
| `["gen_samples", "Lattice d=10 n=16384"]` `[C]` | 0.641 | ❌ | 4.773 | 3.062 | 3840.9 | 0.0 | 2589.3 | 0.0 |
| `["gen_samples", "Lattice d=10 n=256"]` `[C]` | 3.130 | ✅ | 0.049 | 0.154 | 60.9 | 0.0 | 69.2 | 0.0 |
| `["gen_samples", "Lattice d=10 n=4096"]` `[C]` | 1.090 | ✅ | 0.786 | 0.857 | 960.9 | 0.0 | 669.3 | 0.0 |
| `["gen_samples", "Lattice d=3 n=1024"]` `[C]` | 2.694 | ✅ | 0.060 | 0.161 | 72.4 | 0.0 | 77.3 | 0.0 |
| `["gen_samples", "Lattice d=3 n=16384"]` `[C]` | 1.013 | – | 0.950 | 0.962 | 1152.4 | 0.0 | 797.3 | 0.0 |
| `["gen_samples", "Lattice d=3 n=256"]` `[C]` | 8.044 | ✅ | 0.015 | 0.122 | 18.4 | 4240.0 | 41.3 | 4.0 |
| `["gen_samples", "Lattice d=3 n=4096"]` `[C]` | 1.427 | ✅ | 0.227 | 0.325 | 288.4 | 0.0 | 221.3 | 0.0 |
| `["integrate", "CubMCCLT AsianOption"]` | 3.194 | ✅ | 3.781 | 12.075 | 3258.5 | 0.0 | 11001.7 | 0.0 |
| `["integrate", "CubMCCLT EuropeanOption"]` | 3.894 | ✅ | 7.523 | 29.296 | 8136.3 | 896.0 | 33415.8 | 19072.0 |
| `["integrate", "CubMCCLT Keister"]` | 7.152 | ✅ | 13.641 | 97.560 | 39909.1 | 0.0 | 123185.4 | 58800.0 |
| `["integrate", "CubQMCLatticeG EuropeanOption"]` `[C]` | 2.067 | ✅ | 2.634 | 5.445 | 2077.1 | 0.0 | 4583.1 | 0.0 |
| `["integrate", "CubQMCLatticeG Keister"]` `[C]` | 6.325 | ✅ | 0.442 | 2.793 | 570.7 | 0.0 | 401.4 | 704.0 |
| `["integrate", "CubQMCNetG AsianOption"]` | 4.696 | ✅ | 1.252 | 5.880 | 1718.7 | 0.0 | 4196.6 | 8.0 |
| `["integrate", "CubQMCNetG EuropeanOption"]` | 4.677 | ✅ | 1.247 | 5.834 | 1710.7 | 0.0 | 4196.5 | 0.0 |
| `["integrate", "CubQMCNetG Keister"]` | 11.496 | ✅ | 0.275 | 3.156 | 441.5 | 0.0 | 514.8 | 12.0 |
| `["integrate", "CubQMCNetGRep AsianOption"]` | 1.502 | ✅ | 20.157 | 30.271 | 26550.4 | 400.0 | 16561.0 | 1600.0 |
| `["integrate", "CubQMCNetGRep EuropeanOption"]` | 1.564 | ✅ | 19.227 | 30.074 | 26421.3 | 0.0 | 16561.1 | 0.0 |
| `["integrate", "CubQMCNetGRep Keister"]` | 0.825 | ❌ | 3.491 | 2.881 | 4735.8 | 0.0 | 1104.4 | 0.0 |
| `["transform", "Gaussian d=10 n=1024"]` | 3.385 | ✅ | 0.123 | 0.417 | 80.1 | 224.0 | 716.5 | 0.0 |
| `["transform", "Gaussian d=10 n=16384"]` | 2.199 | ✅ | 2.739 | 6.024 | 1280.1 | 0.0 | 10466.5 | 0.0 |
| `["transform", "Gaussian d=10 n=256"]` | 5.428 | ✅ | 0.029 | 0.159 | 20.1 | 0.0 | 184.1 | 0.0 |
| `["transform", "Gaussian d=10 n=4096"]` | 2.749 | ✅ | 0.558 | 1.535 | 320.1 | 0.0 | 2666.5 | 0.0 |
| `["transform", "Gaussian d=3 n=1024"]` | 5.044 | ✅ | 0.035 | 0.179 | 24.1 | 0.0 | 220.6 | 0.0 |
| `["transform", "Gaussian d=3 n=16384"]` | 2.362 | ✅ | 0.778 | 1.838 | 384.1 | 0.0 | 3186.5 | 0.0 |
| `["transform", "Gaussian d=3 n=256"]` | 10.013 | ✅ | 0.010 | 0.096 | 6.1 | 0.0 | 56.4 | 0.0 |
| `["transform", "Gaussian d=3 n=4096"]` | 3.334 | ✅ | 0.146 | 0.486 | 96.1 | 0.0 | 846.5 | 0.0 |
| `["transform", "Gaussian(dense) d=200 n=1024"]` | 4.633 | ✅ | 4.474 | 20.731 | 3200.2 | 0.0 | 13066.5 | 0.0 |
| `["transform", "Gaussian(dense) d=200 n=4096"]` | 5.217 | ✅ | 18.054 | 94.192 | 12800.2 | 0.0 | 52066.5 | 0.0 |
| `["transform", "Gaussian(dense) d=50 n=1024"]` | 2.833 | ✅ | 0.843 | 2.389 | 800.2 | 0.0 | 3316.5 | 0.0 |
| `["transform", "Gaussian(dense) d=50 n=4096"]` | 2.540 | ✅ | 3.714 | 9.433 | 3200.2 | 0.0 | 13066.5 | 0.0 |
| `["transform", "Gaussian(diag) d=200 n=1024"]` | 5.981 | ✅ | 3.449 | 20.630 | 1600.1 | 0.0 | 13066.5 | 0.0 |
| `["transform", "Gaussian(diag) d=200 n=4096"]` | 6.768 | ✅ | 13.783 | 93.286 | 6400.1 | 1168.0 | 52066.5 | 0.0 |
| `["transform", "Gaussian(diag) d=50 n=1024"]` | 2.891 | ✅ | 0.816 | 2.358 | 400.1 | 0.0 | 3316.5 | 0.0 |
| `["transform", "Gaussian(diag) d=50 n=4096"]` | 2.706 | ✅ | 3.438 | 9.303 | 1600.1 | 0.0 | 13066.5 | 0.0 |
| `["transform", "JohnsonsSU d=10 n=1024"]` | 2.529 | ✅ | 0.199 | 0.504 | 160.2 | 160.0 | 716.5 | 0.0 |
| `["transform", "JohnsonsSU d=10 n=16384"]` | 2.330 | ✅ | 3.821 | 8.903 | 2560.2 | 0.0 | 10466.5 | 0.0 |
| `["transform", "JohnsonsSU d=10 n=256"]` | 3.742 | ✅ | 0.048 | 0.181 | 40.2 | 0.0 | 184.1 | 0.0 |
| `["transform", "JohnsonsSU d=10 n=4096"]` | 2.681 | ✅ | 0.850 | 2.278 | 640.2 | 0.0 | 2666.5 | 0.0 |
| `["transform", "StudentT d=10 n=1024"]` | 104.895 | ✅ | 0.052 | 5.493 | 80.1 | 0.0 | 519.6 | 0.0 |
| `["transform", "StudentT d=10 n=16384"]` | 86.307 | ✅ | 0.792 | 68.339 | 1280.1 | 0.0 | 7432.4 | 0.0 |
| `["transform", "StudentT d=10 n=256"]` | 172.328 | ✅ | 0.013 | 2.206 | 20.1 | 0.0 | 139.7 | 0.0 |
| `["transform", "StudentT d=10 n=4096"]` | 91.197 | ✅ | 0.199 | 18.152 | 320.1 | 0.0 | 1864.5 | 0.0 |

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
