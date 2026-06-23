# Benchmark: Julia (local) vs QMCPy (Python)

| | Julia (local) | Python (QMCPy) |
|---|---|---|
| Julia label | `sha-365da35` | — |
| Python label | — | `sha-365da35` |
| Julia artifact mtime | `2026-06-23T02:21:19` | — |
| Python artifact mtime | — | `2026-06-23T02:26:53` |
| Julia generated at | `2026-06-23T02:15:18` | — |
| Python generated at | — | `2026-06-23T02:26:53` |
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
> Report generated at `2026-06-23T02:27:00`. Input artifact skew: `5 m 35 s`.

## Aggregate Summary

| metric | scope | ratio | Julia total | Python total | rows |
|:-------|:------|------:|------------:|-------------:|-----:|
| matched benchmarks | all matched rows | 111/111 | — | — | 111 |
| weighted time ratio | all matched rows | 4.316 | 200.499 ms | 865.383 ms | 111 |
| weighted time ratio | excluding StudentT | 3.867 | 199.560 ms | 771.648 ms | 107 |
| weighted time ratio | StudentT only | 99.797 | 0.939 ms | 93.734 ms | 4 |
| weighted time ratio 95% bootstrap CI | all matched rows | `[4.088, 4.368]` | — | — | 1000 |
| weighted time ratio 95% bootstrap CI | excluding StudentT | `[3.656, 3.919]` | — | — | 1000 |
| weighted time ratio 95% bootstrap CI | StudentT only | `[99.340, 100.252]` | — | — | 1000 |
| weighted approximate tracemalloc ratio | all matched rows | 4.377 | 173029.9 KiB | 757321.5 KiB | 111 |
| weighted approximate RSS delta ratio | all matched rows | 2.972 | 34576.0 KiB | 102772.0 KiB | 111 |


## Grouped Timing Summary

Generator, transform, integrand evaluation, and end-to-end adaptive integration are summarized separately below. The `integrate` group is mixed end-to-end cost, not isolated stopping-criterion overhead.

| group | interpretation | weighted time ratio | 95% bootstrap CI | Julia total | Python total | rows |
|:------|:---------------|--------------------:|:------------------|------------:|-------------:|-----:|
| `evaluate` | integrand evaluation only | 3.491 | `[3.236, 3.512]` | 1.940 ms | 6.772 ms | 36 |
| `gen_samples` | generator only | 4.486 | `[4.454, 4.523]` | 64.601 ms | 289.779 ms | 40 |
| `integrate` | end-to-end adaptive integration; not isolated stopping-criterion overhead | 2.785 | `[2.453, 2.883]` | 76.620 ms | 213.364 ms | 11 |
| `transform` | transform only | 6.200 | `[6.007, 6.223]` | 57.338 ms | 355.468 ms | 24 |

## Detailed Results

| benchmark | time ratio | verdict | Julia (ms) | Python (ms) | Julia alloc (KiB) | Julia RSS Δ (KiB) | Python peak (KiB) | Python RSS Δ (KiB) |
|:----------|-----------:|:-------:|----------:|------------:|-------------------:|------------------:|------------------:|-------------------:|
| `["evaluate", "BoxIntegral d=10 n=1024"]` | 4.379 | ✅ | 0.008 | 0.034 | 16.1 | 0.0 | 89.0 | 0.0 |
| `["evaluate", "BoxIntegral d=10 n=16384"]` | 3.707 | ✅ | 0.131 | 0.487 | 256.1 | 0.0 | 1409.0 | 0.0 |
| `["evaluate", "BoxIntegral d=10 n=256"]` | 2.808 | ✅ | 0.004 | 0.011 | 4.1 | 0.0 | 23.0 | 0.0 |
| `["evaluate", "BoxIntegral d=10 n=4096"]` | 3.905 | ✅ | 0.032 | 0.127 | 64.1 | 0.0 | 353.0 | 0.0 |
| `["evaluate", "BoxIntegral d=200 n=1024"]` | 2.364 | ✅ | 0.049 | 0.115 | 16.1 | 0.0 | 1609.0 | 0.0 |
| `["evaluate", "BoxIntegral d=200 n=4096"]` | 2.427 | ✅ | 0.176 | 0.428 | 64.1 | 0.0 | 6433.0 | 4.0 |
| `["evaluate", "BoxIntegral d=50 n=1024"]` | 3.735 | ✅ | 0.014 | 0.052 | 16.1 | 0.0 | 409.0 | 0.0 |
| `["evaluate", "BoxIntegral d=50 n=4096"]` | 2.899 | ✅ | 0.065 | 0.188 | 64.1 | 0.0 | 1633.0 | 0.0 |
| `["evaluate", "Genz(continuous) d=10 n=1024"]` | 5.498 | ✅ | 0.007 | 0.041 | 16.1 | 0.0 | 160.2 | 0.0 |
| `["evaluate", "Genz(continuous) d=10 n=16384"]` | 4.740 | ✅ | 0.120 | 0.568 | 256.1 | 0.0 | 2560.2 | 0.0 |
| `["evaluate", "Genz(continuous) d=10 n=256"]` | 5.809 | ✅ | 0.003 | 0.015 | 4.1 | 0.0 | 40.2 | 0.0 |
| `["evaluate", "Genz(continuous) d=10 n=4096"]` | 4.239 | ✅ | 0.035 | 0.149 | 64.1 | 0.0 | 640.2 | 0.0 |
| `["evaluate", "Genz(gaussian_peak) d=10 n=1024"]` | 3.866 | ✅ | 0.011 | 0.041 | 16.1 | 0.0 | 169.2 | 0.0 |
| `["evaluate", "Genz(gaussian_peak) d=10 n=16384"]` | 4.694 | ✅ | 0.121 | 0.567 | 256.1 | 0.0 | 2689.2 | 0.0 |
| `["evaluate", "Genz(gaussian_peak) d=10 n=256"]` | 4.607 | ✅ | 0.003 | 0.015 | 4.1 | 0.0 | 43.2 | 0.0 |
| `["evaluate", "Genz(gaussian_peak) d=10 n=4096"]` | 4.626 | ✅ | 0.032 | 0.149 | 64.1 | 0.0 | 673.2 | 0.0 |
| `["evaluate", "Genz(gaussian_peak) d=200 n=1024"]` | 3.783 | ✅ | 0.043 | 0.163 | 16.1 | 0.0 | 3209.2 | 0.0 |
| `["evaluate", "Genz(gaussian_peak) d=200 n=4096"]` | 3.535 | ✅ | 0.180 | 0.635 | 64.1 | 0.0 | 12833.2 | 0.0 |
| `["evaluate", "Genz(gaussian_peak) d=50 n=1024"]` | 4.019 | ✅ | 0.017 | 0.069 | 16.1 | 0.0 | 809.2 | 0.0 |
| `["evaluate", "Genz(gaussian_peak) d=50 n=4096"]` | 3.777 | ✅ | 0.066 | 0.251 | 64.1 | 0.0 | 3233.2 | 0.0 |
| `["evaluate", "Genz(oscillatory) n=1024"]` | 5.613 | ✅ | 0.008 | 0.043 | 16.1 | 0.0 | 49.2 | 0.0 |
| `["evaluate", "Genz(oscillatory) n=16384"]` | 2.986 | ✅ | 0.231 | 0.690 | 256.1 | 0.0 | 513.0 | 0.0 |
| `["evaluate", "Genz(oscillatory) n=256"]` | 5.409 | ✅ | 0.003 | 0.014 | 4.1 | 0.0 | 13.2 | 0.0 |
| `["evaluate", "Genz(oscillatory) n=4096"]` | 5.234 | ✅ | 0.031 | 0.160 | 64.1 | 0.0 | 161.2 | 0.0 |
| `["evaluate", "Keister n=1024"]` | 3.702 | ✅ | 0.010 | 0.039 | 24.3 | 0.0 | 40.3 | 0.0 |
| `["evaluate", "Keister n=16384"]` | 2.944 | ✅ | 0.192 | 0.564 | 384.3 | 0.0 | 640.3 | 0.0 |
| `["evaluate", "Keister n=256"]` | 4.406 | ✅ | 0.003 | 0.014 | 6.3 | 0.0 | 10.3 | 0.0 |
| `["evaluate", "Keister n=4096"]` | 3.147 | ✅ | 0.043 | 0.136 | 96.3 | 0.0 | 160.3 | 0.0 |
| `["evaluate", "Linear0 d=10 n=1024"]` | 11.994 | ✅ | 0.002 | 0.026 | 8.1 | 0.0 | 8.9 | 0.0 |
| `["evaluate", "Linear0 d=10 n=16384"]` | 9.605 | ✅ | 0.042 | 0.399 | 128.1 | 0.0 | 128.9 | 0.0 |
| `["evaluate", "Linear0 d=10 n=256"]` | 9.712 | ✅ | 0.001 | 0.008 | 2.1 | 0.0 | 2.9 | 0.0 |
| `["evaluate", "Linear0 d=10 n=4096"]` | 11.183 | ✅ | 0.009 | 0.101 | 32.1 | 0.0 | 32.9 | 0.0 |
| `["evaluate", "Linear0 d=200 n=1024"]` | 1.654 | ✅ | 0.038 | 0.063 | 8.1 | 0.0 | 8.9 | 0.0 |
| `["evaluate", "Linear0 d=200 n=4096"]` | 1.511 | ✅ | 0.162 | 0.245 | 32.1 | 0.0 | 32.9 | 0.0 |
| `["evaluate", "Linear0 d=50 n=1024"]` | 5.094 | ✅ | 0.007 | 0.034 | 8.1 | 0.0 | 8.9 | 0.0 |
| `["evaluate", "Linear0 d=50 n=4096"]` | 3.187 | ✅ | 0.041 | 0.131 | 32.1 | 0.0 | 32.9 | 0.0 |
| `["gen_samples", "DigitalNetB2 d=10 n=1024"]` `[C]` | 3.364 | ✅ | 0.038 | 0.128 | 168.8 | 0.0 | 108.4 | 0.0 |
| `["gen_samples", "DigitalNetB2 d=10 n=16384"]` `[C]` | 0.253 | ❌ | 1.473 | 0.373 | 2568.8 | 0.0 | 1308.4 | 0.0 |
| `["gen_samples", "DigitalNetB2 d=10 n=256"]` `[C]` | 6.917 | ✅ | 0.017 | 0.114 | 48.8 | 0.0 | 48.4 | 0.0 |
| `["gen_samples", "DigitalNetB2 d=10 n=4096"]` `[C]` | 1.481 | ✅ | 0.122 | 0.181 | 648.8 | 0.0 | 348.4 | 0.0 |
| `["gen_samples", "DigitalNetB2 d=3 n=1024"]` `[C]` | 7.949 | ✅ | 0.015 | 0.121 | 51.0 | 0.0 | 52.4 | 0.0 |
| `["gen_samples", "DigitalNetB2 d=3 n=16384"]` `[C]` | 0.566 | ❌ | 0.460 | 0.260 | 771.0 | 9056.0 | 412.4 | 0.0 |
| `["gen_samples", "DigitalNetB2 d=3 n=256"]` `[C]` | 18.003 | ✅ | 0.006 | 0.113 | 15.0 | 0.0 | 34.4 | 0.0 |
| `["gen_samples", "DigitalNetB2 d=3 n=4096"]` `[C]` | 3.208 | ✅ | 0.046 | 0.148 | 195.0 | 0.0 | 124.4 | 0.0 |
| `["gen_samples", "Halton d=10 n=1024"]` `[C]` | 4.066 | ✅ | 1.835 | 7.460 | 82.7 | 0.0 | 10191.4 | 0.0 |
| `["gen_samples", "Halton d=10 n=16384"]` `[C]` | 5.080 | ✅ | 30.129 | 153.065 | 1282.7 | 0.0 | 162591.6 | 0.0 |
| `["gen_samples", "Halton d=10 n=256"]` `[C]` | 3.979 | ✅ | 0.457 | 1.818 | 22.7 | 0.0 | 2571.4 | 0.0 |
| `["gen_samples", "Halton d=10 n=4096"]` `[C]` | 4.503 | ✅ | 7.333 | 33.019 | 322.7 | 0.0 | 40671.6 | 0.0 |
| `["gen_samples", "Halton d=3 n=1024"]` `[C]` | 7.496 | ✅ | 0.559 | 4.187 | 25.0 | 0.0 | 3079.6 | 0.0 |
| `["gen_samples", "Halton d=3 n=16384"]` `[C]` | 6.648 | ✅ | 9.104 | 60.522 | 385.0 | 0.0 | 48799.6 | 0.0 |
| `["gen_samples", "Halton d=3 n=256"]` `[C]` | 5.933 | ✅ | 0.137 | 0.812 | 7.0 | 0.0 | 793.4 | 0.0 |
| `["gen_samples", "Halton d=3 n=4096"]` `[C]` | 6.874 | ✅ | 2.248 | 15.452 | 97.0 | 0.0 | 12223.6 | 0.0 |
| `["gen_samples", "IIDStdUniform d=10 n=1024"]` | 4.977 | ✅ | 0.008 | 0.040 | 80.1 | 0.0 | 80.8 | 0.0 |
| `["gen_samples", "IIDStdUniform d=10 n=16384"]` | 1.207 | ✅ | 0.602 | 0.726 | 1280.1 | 0.0 | 1280.8 | 0.0 |
| `["gen_samples", "IIDStdUniform d=10 n=256"]` | 5.873 | ✅ | 0.002 | 0.013 | 20.1 | 6512.0 | 20.7 | 0.0 |
| `["gen_samples", "IIDStdUniform d=10 n=4096"]` | 7.305 | ✅ | 0.025 | 0.184 | 320.1 | 0.0 | 320.8 | 0.0 |
| `["gen_samples", "IIDStdUniform d=3 n=1024"]` | 5.802 | ✅ | 0.003 | 0.015 | 24.1 | 0.0 | 24.8 | 0.0 |
| `["gen_samples", "IIDStdUniform d=3 n=16384"]` | 7.282 | ✅ | 0.030 | 0.221 | 384.1 | 0.0 | 384.8 | 0.0 |
| `["gen_samples", "IIDStdUniform d=3 n=256"]` | 6.753 | ✅ | 0.001 | 0.007 | 6.1 | 3680.0 | 6.7 | 0.0 |
| `["gen_samples", "IIDStdUniform d=3 n=4096"]` | 4.916 | ✅ | 0.009 | 0.047 | 96.1 | 0.0 | 96.8 | 0.0 |
| `["gen_samples", "Kronecker d=10 n=1024"]` | 2.357 | ✅ | 0.072 | 0.171 | 80.1 | 0.0 | 233.6 | 0.0 |
| `["gen_samples", "Kronecker d=10 n=16384"]` | 1.483 | ✅ | 1.896 | 2.813 | 1280.1 | 0.0 | 2753.6 | 0.0 |
| `["gen_samples", "Kronecker d=10 n=256"]` | 2.616 | ✅ | 0.018 | 0.047 | 20.1 | 0.0 | 63.6 | 0.0 |
| `["gen_samples", "Kronecker d=10 n=4096"]` | 2.076 | ✅ | 0.331 | 0.686 | 320.1 | 0.0 | 737.6 | 0.0 |
| `["gen_samples", "Kronecker d=3 n=1024"]` | 3.204 | ✅ | 0.021 | 0.068 | 24.1 | 0.0 | 81.6 | 0.0 |
| `["gen_samples", "Kronecker d=3 n=16384"]` | 2.509 | ✅ | 0.415 | 1.042 | 384.1 | 0.0 | 961.6 | 0.0 |
| `["gen_samples", "Kronecker d=3 n=256"]` | 4.026 | ✅ | 0.006 | 0.022 | 6.1 | 0.0 | 21.6 | 0.0 |
| `["gen_samples", "Kronecker d=3 n=4096"]` | 2.731 | ✅ | 0.094 | 0.258 | 96.1 | 0.0 | 289.6 | 0.0 |
| `["gen_samples", "Lattice d=10 n=1024"]` `[C]` | 1.786 | ✅ | 0.174 | 0.311 | 240.9 | 0.0 | 189.2 | 0.0 |
| `["gen_samples", "Lattice d=10 n=16384"]` `[C]` | 0.639 | ❌ | 4.329 | 2.767 | 3840.9 | 0.0 | 2589.3 | 0.0 |
| `["gen_samples", "Lattice d=10 n=256"]` `[C]` | 4.237 | ✅ | 0.043 | 0.183 | 60.9 | 0.0 | 69.2 | 0.0 |
| `["gen_samples", "Lattice d=10 n=4096"]` `[C]` | 0.755 | ❌ | 1.070 | 0.809 | 960.9 | 3136.0 | 669.2 | 0.0 |
| `["gen_samples", "Lattice d=3 n=1024"]` `[C]` | 3.708 | ✅ | 0.051 | 0.191 | 72.4 | 0.0 | 77.3 | 0.0 |
| `["gen_samples", "Lattice d=3 n=16384"]` `[C]` | 0.743 | ❌ | 1.209 | 0.899 | 1152.4 | 0.0 | 797.3 | 0.0 |
| `["gen_samples", "Lattice d=3 n=256"]` `[C]` | 12.169 | ✅ | 0.013 | 0.156 | 18.4 | 0.0 | 41.3 | 0.0 |
| `["gen_samples", "Lattice d=3 n=4096"]` `[C]` | 1.685 | ✅ | 0.197 | 0.333 | 288.4 | 2992.0 | 221.2 | 0.0 |
| `["integrate", "CubMCCLT AsianOption"]` | 3.138 | ✅ | 3.702 | 11.617 | 3258.5 | 0.0 | 11001.6 | 8292.0 |
| `["integrate", "CubMCCLT EuropeanOption"]` | 3.749 | ✅ | 7.450 | 27.926 | 8136.3 | 0.0 | 33415.8 | 32272.0 |
| `["integrate", "CubMCCLT Keister"]` | 6.943 | ✅ | 13.554 | 94.113 | 39909.1 | 0.0 | 123185.5 | 58808.0 |
| `["integrate", "CubQMCLatticeG EuropeanOption"]` `[C]` | 2.360 | ✅ | 2.206 | 5.206 | 2077.1 | 0.0 | 4583.1 | 0.0 |
| `["integrate", "CubQMCLatticeG Keister"]` `[C]` | 7.063 | ✅ | 0.416 | 2.940 | 570.7 | 0.0 | 401.2 | 704.0 |
| `["integrate", "CubQMCNetG AsianOption"]` | 4.380 | ✅ | 1.273 | 5.574 | 1718.6 | 0.0 | 4196.6 | 1080.0 |
| `["integrate", "CubQMCNetG EuropeanOption"]` | 4.481 | ✅ | 1.254 | 5.622 | 1710.6 | 0.0 | 4196.3 | 0.0 |
| `["integrate", "CubQMCNetG Keister"]` | 12.328 | ✅ | 0.269 | 3.320 | 441.3 | 0.0 | 514.8 | 12.0 |
| `["integrate", "CubQMCNetGRep AsianOption"]` | 1.248 | ✅ | 21.774 | 27.180 | 26548.9 | 0.0 | 16561.0 | 1600.0 |
| `["integrate", "CubQMCNetGRep EuropeanOption"]` | 1.314 | ✅ | 20.633 | 27.108 | 26419.8 | 0.0 | 16560.7 | 0.0 |
| `["integrate", "CubQMCNetGRep Keister"]` | 0.674 | ❌ | 4.089 | 2.758 | 4732.8 | 0.0 | 1104.5 | 0.0 |
| `["transform", "Gaussian d=10 n=1024"]` | 3.219 | ✅ | 0.138 | 0.445 | 80.1 | 0.0 | 716.5 | 0.0 |
| `["transform", "Gaussian d=10 n=16384"]` | 2.153 | ✅ | 2.654 | 5.713 | 1280.1 | 2960.0 | 10466.5 | 0.0 |
| `["transform", "Gaussian d=10 n=256"]` | 5.756 | ✅ | 0.031 | 0.179 | 20.1 | 0.0 | 184.1 | 0.0 |
| `["transform", "Gaussian d=10 n=4096"]` | 2.320 | ✅ | 0.657 | 1.525 | 320.1 | 0.0 | 2666.5 | 0.0 |
| `["transform", "Gaussian d=3 n=1024"]` | 5.380 | ✅ | 0.037 | 0.199 | 24.1 | 0.0 | 220.6 | 0.0 |
| `["transform", "Gaussian d=3 n=16384"]` | 2.292 | ✅ | 0.790 | 1.811 | 384.1 | 0.0 | 3186.5 | 0.0 |
| `["transform", "Gaussian d=3 n=256"]` | 12.428 | ✅ | 0.010 | 0.120 | 6.1 | 0.0 | 56.4 | 0.0 |
| `["transform", "Gaussian d=3 n=4096"]` | 2.989 | ✅ | 0.175 | 0.522 | 96.1 | 0.0 | 846.5 | 0.0 |
| `["transform", "Gaussian(dense) d=200 n=1024"]` | 4.564 | ✅ | 4.303 | 19.639 | 3200.2 | 0.0 | 13066.5 | 0.0 |
| `["transform", "Gaussian(dense) d=200 n=4096"]` | 5.217 | ✅ | 17.268 | 90.080 | 12800.2 | 0.0 | 52066.5 | 0.0 |
| `["transform", "Gaussian(dense) d=50 n=1024"]` | 2.592 | ✅ | 0.890 | 2.307 | 800.2 | 0.0 | 3316.5 | 0.0 |
| `["transform", "Gaussian(dense) d=50 n=4096"]` | 2.526 | ✅ | 3.517 | 8.885 | 3200.2 | 0.0 | 13066.5 | 0.0 |
| `["transform", "Gaussian(diag) d=200 n=1024"]` | 5.842 | ✅ | 3.325 | 19.424 | 1600.1 | 0.0 | 13066.5 | 0.0 |
| `["transform", "Gaussian(diag) d=200 n=4096"]` | 6.597 | ✅ | 13.334 | 87.964 | 6400.1 | 0.0 | 52066.5 | 0.0 |
| `["transform", "Gaussian(diag) d=50 n=1024"]` | 2.811 | ✅ | 0.822 | 2.310 | 400.1 | 6240.0 | 3316.5 | 0.0 |
| `["transform", "Gaussian(diag) d=50 n=4096"]` | 2.680 | ✅ | 3.325 | 8.910 | 1600.1 | 0.0 | 13066.5 | 0.0 |
| `["transform", "JohnsonsSU d=10 n=1024"]` | 2.830 | ✅ | 0.219 | 0.619 | 160.2 | 0.0 | 716.5 | 0.0 |
| `["transform", "JohnsonsSU d=10 n=16384"]` | 2.228 | ✅ | 3.883 | 8.653 | 2560.2 | 0.0 | 10466.5 | 0.0 |
| `["transform", "JohnsonsSU d=10 n=256"]` | 3.932 | ✅ | 0.052 | 0.206 | 40.2 | 0.0 | 184.1 | 0.0 |
| `["transform", "JohnsonsSU d=10 n=4096"]` | 2.293 | ✅ | 0.968 | 2.221 | 640.2 | 0.0 | 2666.5 | 0.0 |
| `["transform", "StudentT d=10 n=1024"]` | 126.557 | ✅ | 0.045 | 5.700 | 80.1 | 0.0 | 519.6 | 0.0 |
| `["transform", "StudentT d=10 n=16384"]` | 96.132 | ✅ | 0.705 | 67.748 | 1280.1 | 0.0 | 7432.3 | 0.0 |
| `["transform", "StudentT d=10 n=256"]` | 226.366 | ✅ | 0.011 | 2.601 | 20.1 | 0.0 | 139.5 | 0.0 |
| `["transform", "StudentT d=10 n=4096"]` | 99.368 | ✅ | 0.178 | 17.685 | 320.1 | 0.0 | 1864.2 | 0.0 |

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
