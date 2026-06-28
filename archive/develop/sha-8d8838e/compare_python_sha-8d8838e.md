# Benchmark: Julia (local) vs QMCPy (Python)

| | Julia (local) | Python (QMCPy) |
|---|---|---|
| Julia label | `sha-8d8838e` | — |
| Python label | — | `sha-8d8838e` |
| Julia artifact mtime | `2026-06-28T09:50:21` | — |
| Python artifact mtime | — | `2026-06-28T09:55:51` |
| Julia generated at | `2026-06-28T09:44:15` | — |
| Python generated at | — | `2026-06-28T09:55:51` |
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
> Report generated at `2026-06-28T09:55:57`. Input artifact skew: `5 m 31 s`.

## Aggregate Summary

| metric | scope | ratio | Julia total | Python total | rows |
|:-------|:------|------:|------------:|-------------:|-----:|
| matched benchmarks | all matched rows | 111/111 | — | — | 111 |
| weighted time ratio | all matched rows | 4.296 | 199.398 ms | 856.560 ms | 111 |
| weighted time ratio | excluding StudentT | 3.850 | 198.458 ms | 764.005 ms | 107 |
| weighted time ratio | StudentT only | 98.429 | 0.940 ms | 92.554 ms | 4 |
| weighted time ratio 95% bootstrap CI | all matched rows | `[4.236, 4.363]` | — | — | 1000 |
| weighted time ratio 95% bootstrap CI | excluding StudentT | `[3.793, 3.910]` | — | — | 1000 |
| weighted time ratio 95% bootstrap CI | StudentT only | `[98.201, 98.865]` | — | — | 1000 |
| weighted approximate tracemalloc ratio | all matched rows | 4.377 | 173037.5 KiB | 757322.2 KiB | 111 |
| weighted approximate RSS delta ratio | all matched rows | 1.999 | 38592.0 KiB | 77152.0 KiB | 111 |

> ℹ️ RSS delta ratio compares retained process RSS after one warmed call; ratio < 1 means Python retained less RSS than Julia, and ratio > 1 means Python retained more. Treat it as an approximate retained-footprint signal, not a direct allocation metric.

## Grouped Timing Summary

Generator, transform, integrand evaluation, and end-to-end adaptive integration are summarized separately below. The `integrate` group is mixed end-to-end cost, not isolated stopping-criterion overhead.

| group | interpretation | weighted time ratio | 95% bootstrap CI | Julia total | Python total | rows |
|:------|:---------------|--------------------:|:------------------|------------:|-------------:|-----:|
| `evaluate` | integrand evaluation only | 3.279 | `[3.019, 3.316]` | 2.072 ms | 6.795 ms | 36 |
| `gen_samples` | generator only | 4.455 | `[4.434, 4.532]` | 64.661 ms | 288.060 ms | 40 |
| `integrate` | end-to-end adaptive integration; not isolated stopping-criterion overhead | 2.772 | `[2.677, 2.880]` | 75.744 ms | 209.979 ms | 11 |
| `transform` | transform only | 6.179 | `[6.086, 6.189]` | 56.921 ms | 351.725 ms | 24 |

## Detailed Results

| benchmark | time ratio | verdict | Julia (ms) | Python (ms) | Julia alloc (KiB) | Julia RSS Δ (KiB) | Python peak (KiB) | Python RSS Δ (KiB) |
|:----------|-----------:|:-------:|----------:|------------:|-------------------:|------------------:|------------------:|-------------------:|
| `["evaluate", "BoxIntegral d=10 n=1024"]` | 4.001 | ✅ | 0.009 | 0.034 | 16.1 | 0.0 | 89.0 | 0.0 |
| `["evaluate", "BoxIntegral d=10 n=16384"]` | 2.144 | ✅ | 0.226 | 0.485 | 256.1 | 0.0 | 1409.0 | 0.0 |
| `["evaluate", "BoxIntegral d=10 n=256"]` | 4.413 | ✅ | 0.003 | 0.011 | 4.1 | 0.0 | 23.0 | 0.0 |
| `["evaluate", "BoxIntegral d=10 n=4096"]` | 3.433 | ✅ | 0.037 | 0.126 | 64.1 | 0.0 | 353.0 | 0.0 |
| `["evaluate", "BoxIntegral d=200 n=1024"]` | 2.693 | ✅ | 0.047 | 0.127 | 16.1 | 0.0 | 1609.0 | 0.0 |
| `["evaluate", "BoxIntegral d=200 n=4096"]` | 2.568 | ✅ | 0.167 | 0.428 | 64.1 | 0.0 | 6433.0 | 4.0 |
| `["evaluate", "BoxIntegral d=50 n=1024"]` | 3.601 | ✅ | 0.014 | 0.052 | 16.1 | 0.0 | 409.0 | 0.0 |
| `["evaluate", "BoxIntegral d=50 n=4096"]` | 2.956 | ✅ | 0.065 | 0.191 | 64.1 | 0.0 | 1633.0 | 0.0 |
| `["evaluate", "Genz(continuous) d=10 n=1024"]` | 5.455 | ✅ | 0.008 | 0.041 | 16.1 | 0.0 | 160.2 | 0.0 |
| `["evaluate", "Genz(continuous) d=10 n=16384"]` | 4.487 | ✅ | 0.126 | 0.565 | 256.1 | 0.0 | 2560.2 | 0.0 |
| `["evaluate", "Genz(continuous) d=10 n=256"]` | 5.746 | ✅ | 0.003 | 0.015 | 4.1 | 0.0 | 40.2 | 0.0 |
| `["evaluate", "Genz(continuous) d=10 n=4096"]` | 4.491 | ✅ | 0.033 | 0.147 | 64.1 | 0.0 | 640.2 | 0.0 |
| `["evaluate", "Genz(gaussian_peak) d=10 n=1024"]` | 5.002 | ✅ | 0.008 | 0.042 | 16.1 | 0.0 | 169.2 | 0.0 |
| `["evaluate", "Genz(gaussian_peak) d=10 n=16384"]` | 4.865 | ✅ | 0.121 | 0.589 | 256.1 | 0.0 | 2689.2 | 0.0 |
| `["evaluate", "Genz(gaussian_peak) d=10 n=256"]` | 5.722 | ✅ | 0.003 | 0.015 | 4.1 | 0.0 | 43.2 | 0.0 |
| `["evaluate", "Genz(gaussian_peak) d=10 n=4096"]` | 4.147 | ✅ | 0.036 | 0.148 | 64.1 | 0.0 | 673.2 | 0.0 |
| `["evaluate", "Genz(gaussian_peak) d=200 n=1024"]` | 2.889 | ✅ | 0.059 | 0.169 | 16.1 | 0.0 | 3209.2 | 0.0 |
| `["evaluate", "Genz(gaussian_peak) d=200 n=4096"]` | 3.527 | ✅ | 0.172 | 0.606 | 64.1 | 0.0 | 12833.2 | 0.0 |
| `["evaluate", "Genz(gaussian_peak) d=50 n=1024"]` | 3.832 | ✅ | 0.018 | 0.070 | 16.1 | 0.0 | 809.2 | 0.0 |
| `["evaluate", "Genz(gaussian_peak) d=50 n=4096"]` | 3.547 | ✅ | 0.080 | 0.285 | 64.1 | 0.0 | 3233.2 | 0.0 |
| `["evaluate", "Genz(oscillatory) n=1024"]` | 4.851 | ✅ | 0.009 | 0.043 | 16.1 | 0.0 | 49.2 | 0.0 |
| `["evaluate", "Genz(oscillatory) n=16384"]` | 2.951 | ✅ | 0.231 | 0.682 | 256.1 | 0.0 | 513.0 | 0.0 |
| `["evaluate", "Genz(oscillatory) n=256"]` | 5.432 | ✅ | 0.003 | 0.014 | 4.1 | 0.0 | 13.2 | 0.0 |
| `["evaluate", "Genz(oscillatory) n=4096"]` | 5.439 | ✅ | 0.029 | 0.159 | 64.1 | 0.0 | 161.2 | 0.0 |
| `["evaluate", "Keister n=1024"]` | 3.525 | ✅ | 0.011 | 0.039 | 24.3 | 0.0 | 40.3 | 0.0 |
| `["evaluate", "Keister n=16384"]` | 2.644 | ✅ | 0.212 | 0.560 | 384.3 | 0.0 | 640.3 | 0.0 |
| `["evaluate", "Keister n=256"]` | 4.005 | ✅ | 0.003 | 0.014 | 6.3 | 0.0 | 10.3 | 0.0 |
| `["evaluate", "Keister n=4096"]` | 2.921 | ✅ | 0.047 | 0.136 | 96.3 | 0.0 | 160.3 | 0.0 |
| `["evaluate", "Linear0 d=10 n=1024"]` | 11.162 | ✅ | 0.002 | 0.026 | 8.1 | 0.0 | 8.9 | 0.0 |
| `["evaluate", "Linear0 d=10 n=16384"]` | 7.329 | ✅ | 0.054 | 0.396 | 128.1 | 0.0 | 128.9 | 0.0 |
| `["evaluate", "Linear0 d=10 n=256"]` | 10.069 | ✅ | 0.001 | 0.008 | 2.1 | 14576.0 | 2.9 | 0.0 |
| `["evaluate", "Linear0 d=10 n=4096"]` | 10.572 | ✅ | 0.009 | 0.100 | 32.1 | 0.0 | 32.9 | 0.0 |
| `["evaluate", "Linear0 d=200 n=1024"]` | 1.645 | ✅ | 0.038 | 0.063 | 8.1 | 0.0 | 8.9 | 0.0 |
| `["evaluate", "Linear0 d=200 n=4096"]` | 1.714 | ✅ | 0.142 | 0.244 | 32.1 | 0.0 | 32.9 | 0.0 |
| `["evaluate", "Linear0 d=50 n=1024"]` | 3.627 | ✅ | 0.009 | 0.034 | 8.1 | 0.0 | 8.9 | 0.0 |
| `["evaluate", "Linear0 d=50 n=4096"]` | 3.406 | ✅ | 0.038 | 0.131 | 32.1 | 0.0 | 32.9 | 0.0 |
| `["gen_samples", "DigitalNetB2 d=10 n=1024"]` `[C]` | 2.403 | ✅ | 0.052 | 0.125 | 168.9 | 0.0 | 108.4 | 0.0 |
| `["gen_samples", "DigitalNetB2 d=10 n=16384"]` `[C]` | 0.240 | ❌ | 1.546 | 0.371 | 2568.9 | 0.0 | 1308.4 | 0.0 |
| `["gen_samples", "DigitalNetB2 d=10 n=256"]` `[C]` | 6.903 | ✅ | 0.016 | 0.113 | 48.9 | 0.0 | 48.4 | 0.0 |
| `["gen_samples", "DigitalNetB2 d=10 n=4096"]` `[C]` | 1.045 | – | 0.168 | 0.175 | 648.9 | 0.0 | 348.4 | 0.0 |
| `["gen_samples", "DigitalNetB2 d=3 n=1024"]` `[C]` | 7.220 | ✅ | 0.017 | 0.120 | 51.1 | 0.0 | 52.4 | 0.0 |
| `["gen_samples", "DigitalNetB2 d=3 n=16384"]` `[C]` | 0.705 | ❌ | 0.368 | 0.259 | 771.1 | 0.0 | 412.4 | 0.0 |
| `["gen_samples", "DigitalNetB2 d=3 n=256"]` `[C]` | 16.789 | ✅ | 0.007 | 0.110 | 15.1 | 0.0 | 34.4 | 0.0 |
| `["gen_samples", "DigitalNetB2 d=3 n=4096"]` `[C]` | 2.613 | ✅ | 0.056 | 0.146 | 195.1 | 4432.0 | 124.4 | 0.0 |
| `["gen_samples", "Halton d=10 n=1024"]` `[C]` | 4.031 | ✅ | 1.861 | 7.501 | 82.8 | 0.0 | 10191.6 | 0.0 |
| `["gen_samples", "Halton d=10 n=16384"]` `[C]` | 5.086 | ✅ | 30.115 | 153.168 | 1282.8 | 0.0 | 162591.6 | 0.0 |
| `["gen_samples", "Halton d=10 n=256"]` `[C]` | 4.052 | ✅ | 0.454 | 1.841 | 22.8 | 0.0 | 2571.6 | 0.0 |
| `["gen_samples", "Halton d=10 n=4096"]` `[C]` | 4.524 | ✅ | 7.328 | 33.151 | 322.8 | 8032.0 | 40671.4 | 0.0 |
| `["gen_samples", "Halton d=3 n=1024"]` `[C]` | 7.519 | ✅ | 0.558 | 4.194 | 25.0 | 0.0 | 3079.6 | 0.0 |
| `["gen_samples", "Halton d=3 n=16384"]` `[C]` | 6.517 | ✅ | 9.143 | 59.580 | 385.0 | 0.0 | 48799.6 | 0.0 |
| `["gen_samples", "Halton d=3 n=256"]` `[C]` | 5.836 | ✅ | 0.140 | 0.817 | 7.0 | 0.0 | 793.5 | 0.0 |
| `["gen_samples", "Halton d=3 n=4096"]` `[C]` | 6.517 | ✅ | 2.244 | 14.627 | 97.0 | 0.0 | 12223.5 | 0.0 |
| `["gen_samples", "IIDStdUniform d=10 n=1024"]` | 4.869 | ✅ | 0.008 | 0.040 | 80.1 | 0.0 | 80.8 | 0.0 |
| `["gen_samples", "IIDStdUniform d=10 n=16384"]` | 0.968 | – | 0.594 | 0.575 | 1280.1 | 0.0 | 1280.8 | 0.0 |
| `["gen_samples", "IIDStdUniform d=10 n=256"]` | 5.877 | ✅ | 0.002 | 0.013 | 20.1 | 0.0 | 20.7 | 0.0 |
| `["gen_samples", "IIDStdUniform d=10 n=4096"]` | 5.327 | ✅ | 0.028 | 0.148 | 320.1 | 0.0 | 320.8 | 0.0 |
| `["gen_samples", "IIDStdUniform d=3 n=1024"]` | 6.257 | ✅ | 0.002 | 0.015 | 24.1 | 0.0 | 24.8 | 0.0 |
| `["gen_samples", "IIDStdUniform d=3 n=16384"]` | 5.868 | ✅ | 0.030 | 0.176 | 384.1 | 0.0 | 384.8 | 0.0 |
| `["gen_samples", "IIDStdUniform d=3 n=256"]` | 5.601 | ✅ | 0.001 | 0.007 | 6.1 | 0.0 | 6.7 | 0.0 |
| `["gen_samples", "IIDStdUniform d=3 n=4096"]` | 3.313 | ✅ | 0.014 | 0.047 | 96.1 | 0.0 | 96.8 | 0.0 |
| `["gen_samples", "Kronecker d=10 n=1024"]` | 2.340 | ✅ | 0.073 | 0.172 | 80.1 | 48.0 | 233.6 | 0.0 |
| `["gen_samples", "Kronecker d=10 n=16384"]` | 1.526 | ✅ | 1.849 | 2.821 | 1280.1 | 0.0 | 2753.6 | 0.0 |
| `["gen_samples", "Kronecker d=10 n=256"]` | 2.697 | ✅ | 0.018 | 0.047 | 20.1 | 0.0 | 63.6 | 0.0 |
| `["gen_samples", "Kronecker d=10 n=4096"]` | 2.142 | ✅ | 0.323 | 0.691 | 320.1 | 0.0 | 737.6 | 0.0 |
| `["gen_samples", "Kronecker d=3 n=1024"]` | 3.227 | ✅ | 0.021 | 0.068 | 24.1 | 0.0 | 81.6 | 0.0 |
| `["gen_samples", "Kronecker d=3 n=16384"]` | 2.549 | ✅ | 0.408 | 1.040 | 384.1 | 0.0 | 961.6 | 0.0 |
| `["gen_samples", "Kronecker d=3 n=256"]` | 3.923 | ✅ | 0.006 | 0.022 | 6.1 | 0.0 | 21.6 | 0.0 |
| `["gen_samples", "Kronecker d=3 n=4096"]` | 2.736 | ✅ | 0.094 | 0.259 | 96.1 | 0.0 | 289.6 | 0.0 |
| `["gen_samples", "Lattice d=10 n=1024"]` `[C]` | 1.764 | ✅ | 0.175 | 0.309 | 240.9 | 0.0 | 189.3 | 0.0 |
| `["gen_samples", "Lattice d=10 n=16384"]` `[C]` | 0.635 | ❌ | 4.351 | 2.762 | 3840.9 | 0.0 | 2589.2 | 0.0 |
| `["gen_samples", "Lattice d=10 n=256"]` `[C]` | 4.094 | ✅ | 0.044 | 0.180 | 60.9 | 0.0 | 69.3 | 0.0 |
| `["gen_samples", "Lattice d=10 n=4096"]` `[C]` | 0.754 | ❌ | 1.068 | 0.806 | 960.9 | 0.0 | 669.2 | 0.0 |
| `["gen_samples", "Lattice d=3 n=1024"]` `[C]` | 3.755 | ✅ | 0.050 | 0.187 | 72.4 | 0.0 | 77.3 | 0.0 |
| `["gen_samples", "Lattice d=3 n=16384"]` `[C]` | 0.735 | ❌ | 1.220 | 0.896 | 1152.4 | 944.0 | 797.2 | 0.0 |
| `["gen_samples", "Lattice d=3 n=256"]` `[C]` | 11.467 | ✅ | 0.013 | 0.151 | 18.4 | 0.0 | 41.3 | 0.0 |
| `["gen_samples", "Lattice d=3 n=4096"]` `[C]` | 1.685 | ✅ | 0.196 | 0.331 | 288.4 | 0.0 | 221.2 | 0.0 |
| `["integrate", "CubMCCLT AsianOption"]` | 2.980 | ✅ | 3.764 | 11.219 | 3258.5 | 0.0 | 11001.7 | 0.0 |
| `["integrate", "CubMCCLT EuropeanOption"]` | 3.726 | ✅ | 7.458 | 27.791 | 8136.3 | 1232.0 | 33415.8 | 15872.0 |
| `["integrate", "CubMCCLT Keister"]` | 6.619 | ✅ | 14.062 | 93.076 | 39909.1 | 0.0 | 123185.4 | 58788.0 |
| `["integrate", "CubQMCLatticeG EuropeanOption"]` `[C]` | 2.389 | ✅ | 2.161 | 5.163 | 2077.1 | 0.0 | 4583.0 | 0.0 |
| `["integrate", "CubQMCLatticeG Keister"]` `[C]` | 6.880 | ✅ | 0.423 | 2.908 | 570.7 | 0.0 | 401.3 | 868.0 |
| `["integrate", "CubQMCNetG AsianOption"]` | 4.174 | ✅ | 1.321 | 5.515 | 1718.7 | 0.0 | 4196.6 | 8.0 |
| `["integrate", "CubQMCNetG EuropeanOption"]` | 4.156 | ✅ | 1.321 | 5.490 | 1710.7 | 0.0 | 4196.5 | 0.0 |
| `["integrate", "CubQMCNetG Keister"]` | 11.234 | ✅ | 0.288 | 3.237 | 441.5 | 0.0 | 514.8 | 12.0 |
| `["integrate", "CubQMCNetGRep AsianOption"]` | 1.238 | ✅ | 21.398 | 26.494 | 26550.4 | 0.0 | 16560.9 | 1600.0 |
| `["integrate", "CubQMCNetGRep EuropeanOption"]` | 1.309 | ✅ | 20.132 | 26.354 | 26421.3 | 0.0 | 16560.9 | 0.0 |
| `["integrate", "CubQMCNetGRep Keister"]` | 0.800 | ❌ | 3.415 | 2.732 | 4735.8 | 0.0 | 1104.3 | 0.0 |
| `["transform", "Gaussian d=10 n=1024"]` | 3.171 | ✅ | 0.140 | 0.444 | 80.1 | 0.0 | 716.5 | 0.0 |
| `["transform", "Gaussian d=10 n=16384"]` | 2.189 | ✅ | 2.629 | 5.754 | 1280.1 | 0.0 | 10466.5 | 0.0 |
| `["transform", "Gaussian d=10 n=256"]` | 5.832 | ✅ | 0.031 | 0.180 | 20.1 | 0.0 | 184.1 | 0.0 |
| `["transform", "Gaussian d=10 n=4096"]` | 2.372 | ✅ | 0.649 | 1.541 | 320.1 | 1488.0 | 2666.5 | 0.0 |
| `["transform", "Gaussian d=3 n=1024"]` | 5.416 | ✅ | 0.037 | 0.201 | 24.1 | 0.0 | 220.6 | 0.0 |
| `["transform", "Gaussian d=3 n=16384"]` | 2.319 | ✅ | 0.784 | 1.818 | 384.1 | 0.0 | 3186.5 | 0.0 |
| `["transform", "Gaussian d=3 n=256"]` | 12.469 | ✅ | 0.010 | 0.121 | 6.1 | 0.0 | 56.4 | 0.0 |
| `["transform", "Gaussian d=3 n=4096"]` | 2.840 | ✅ | 0.183 | 0.520 | 96.1 | 0.0 | 846.5 | 0.0 |
| `["transform", "Gaussian(dense) d=200 n=1024"]` | 4.677 | ✅ | 4.239 | 19.829 | 3200.2 | 0.0 | 13066.5 | 0.0 |
| `["transform", "Gaussian(dense) d=200 n=4096"]` | 5.194 | ✅ | 17.128 | 88.957 | 12800.2 | 0.0 | 52066.5 | 0.0 |
| `["transform", "Gaussian(dense) d=50 n=1024"]` | 2.480 | ✅ | 0.927 | 2.300 | 800.2 | 0.0 | 3316.5 | 0.0 |
| `["transform", "Gaussian(dense) d=50 n=4096"]` | 2.526 | ✅ | 3.516 | 8.881 | 3200.2 | 0.0 | 13066.5 | 0.0 |
| `["transform", "Gaussian(diag) d=200 n=1024"]` | 5.861 | ✅ | 3.294 | 19.305 | 1600.1 | 0.0 | 13066.5 | 0.0 |
| `["transform", "Gaussian(diag) d=200 n=4096"]` | 6.569 | ✅ | 13.193 | 86.666 | 6400.1 | 0.0 | 52066.5 | 0.0 |
| `["transform", "Gaussian(diag) d=50 n=1024"]` | 2.797 | ✅ | 0.820 | 2.294 | 400.1 | 0.0 | 3316.5 | 0.0 |
| `["transform", "Gaussian(diag) d=50 n=4096"]` | 2.696 | ✅ | 3.308 | 8.919 | 1600.1 | 0.0 | 13066.5 | 0.0 |
| `["transform", "JohnsonsSU d=10 n=1024"]` | 2.786 | ✅ | 0.221 | 0.617 | 160.2 | 7728.0 | 716.5 | 0.0 |
| `["transform", "JohnsonsSU d=10 n=16384"]` | 2.180 | ✅ | 3.859 | 8.414 | 2560.2 | 0.0 | 10466.5 | 0.0 |
| `["transform", "JohnsonsSU d=10 n=256"]` | 3.920 | ✅ | 0.053 | 0.207 | 40.2 | 0.0 | 184.1 | 0.0 |
| `["transform", "JohnsonsSU d=10 n=4096"]` | 2.297 | ✅ | 0.959 | 2.203 | 640.2 | 0.0 | 2666.5 | 0.0 |
| `["transform", "StudentT d=10 n=1024"]` | 124.583 | ✅ | 0.046 | 5.693 | 80.1 | 112.0 | 519.6 | 0.0 |
| `["transform", "StudentT d=10 n=16384"]` | 94.504 | ✅ | 0.705 | 66.636 | 1280.1 | 0.0 | 7432.2 | 0.0 |
| `["transform", "StudentT d=10 n=256"]` | 224.117 | ✅ | 0.011 | 2.572 | 20.1 | 0.0 | 139.4 | 0.0 |
| `["transform", "StudentT d=10 n=4096"]` | 99.158 | ✅ | 0.178 | 17.653 | 320.1 | 0.0 | 1864.1 | 0.0 |

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
