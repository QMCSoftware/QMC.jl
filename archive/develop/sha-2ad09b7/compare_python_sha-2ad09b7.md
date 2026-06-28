# Benchmark: Julia (local) vs QMCPy (Python)

| | Julia (local) | Python (QMCPy) |
|---|---|---|
| Julia label | `sha-2ad09b7` | — |
| Python label | — | `sha-2ad09b7` |
| Julia artifact mtime | `2026-06-28T06:24:23` | — |
| Python artifact mtime | — | `2026-06-28T06:29:57` |
| Julia generated at | `2026-06-28T06:18:01` | — |
| Python generated at | — | `2026-06-28T06:29:57` |
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
> Report generated at `2026-06-28T06:30:02`. Input artifact skew: `5 m 34 s`.

## Aggregate Summary

| metric | scope | ratio | Julia total | Python total | rows |
|:-------|:------|------:|------------:|-------------:|-----:|
| matched benchmarks | all matched rows | 111/111 | — | — | 111 |
| weighted time ratio | all matched rows | 4.000 | 216.783 ms | 867.085 ms | 111 |
| weighted time ratio | excluding StudentT | 3.586 | 215.843 ms | 773.941 ms | 107 |
| weighted time ratio | StudentT only | 99.125 | 0.940 ms | 93.144 ms | 4 |
| weighted time ratio 95% bootstrap CI | all matched rows | `[3.932, 4.251]` | — | — | 1000 |
| weighted time ratio 95% bootstrap CI | excluding StudentT | `[3.526, 3.803]` | — | — | 1000 |
| weighted time ratio 95% bootstrap CI | StudentT only | `[98.902, 99.533]` | — | — | 1000 |
| weighted approximate tracemalloc ratio | all matched rows | 4.377 | 173037.5 KiB | 757322.4 KiB | 111 |
| weighted approximate RSS delta ratio | all matched rows | 3.179 | 18720.0 KiB | 59512.0 KiB | 111 |


## Grouped Timing Summary

Generator, transform, integrand evaluation, and end-to-end adaptive integration are summarized separately below. The `integrate` group is mixed end-to-end cost, not isolated stopping-criterion overhead.

| group | interpretation | weighted time ratio | 95% bootstrap CI | Julia total | Python total | rows |
|:------|:---------------|--------------------:|:------------------|------------:|-------------:|-----:|
| `evaluate` | integrand evaluation only | 3.235 | `[2.960, 3.282]` | 2.197 ms | 7.106 ms | 36 |
| `gen_samples` | generator only | 4.646 | `[4.596, 4.740]` | 62.799 ms | 291.787 ms | 40 |
| `integrate` | end-to-end adaptive integration; not isolated stopping-criterion overhead | 2.254 | `[2.176, 2.580]` | 94.606 ms | 213.205 ms | 11 |
| `transform` | transform only | 6.208 | `[5.965, 6.254]` | 57.180 ms | 354.988 ms | 24 |

## Detailed Results

| benchmark | time ratio | verdict | Julia (ms) | Python (ms) | Julia alloc (KiB) | Julia RSS Δ (KiB) | Python peak (KiB) | Python RSS Δ (KiB) |
|:----------|-----------:|:-------:|----------:|------------:|-------------------:|------------------:|------------------:|-------------------:|
| `["evaluate", "BoxIntegral d=10 n=1024"]` | 2.680 | ✅ | 0.013 | 0.034 | 16.1 | 0.0 | 89.0 | 0.0 |
| `["evaluate", "BoxIntegral d=10 n=16384"]` | 2.083 | ✅ | 0.238 | 0.496 | 256.1 | 0.0 | 1409.0 | 0.0 |
| `["evaluate", "BoxIntegral d=10 n=256"]` | 4.310 | ✅ | 0.003 | 0.011 | 4.1 | 0.0 | 23.0 | 0.0 |
| `["evaluate", "BoxIntegral d=10 n=4096"]` | 2.159 | ✅ | 0.059 | 0.127 | 64.1 | 0.0 | 353.0 | 0.0 |
| `["evaluate", "BoxIntegral d=200 n=1024"]` | 2.324 | ✅ | 0.054 | 0.126 | 16.1 | 0.0 | 1609.0 | 0.0 |
| `["evaluate", "BoxIntegral d=200 n=4096"]` | 2.683 | ✅ | 0.185 | 0.496 | 64.1 | 0.0 | 6433.0 | 0.0 |
| `["evaluate", "BoxIntegral d=50 n=1024"]` | 3.489 | ✅ | 0.016 | 0.054 | 16.1 | 0.0 | 409.0 | 0.0 |
| `["evaluate", "BoxIntegral d=50 n=4096"]` | 2.885 | ✅ | 0.071 | 0.204 | 64.1 | 0.0 | 1633.0 | 0.0 |
| `["evaluate", "Genz(continuous) d=10 n=1024"]` | 5.199 | ✅ | 0.008 | 0.041 | 16.1 | 0.0 | 160.2 | 0.0 |
| `["evaluate", "Genz(continuous) d=10 n=16384"]` | 4.293 | ✅ | 0.136 | 0.584 | 256.1 | 0.0 | 2560.2 | 0.0 |
| `["evaluate", "Genz(continuous) d=10 n=256"]` | 4.097 | ✅ | 0.004 | 0.014 | 4.1 | 0.0 | 40.2 | 0.0 |
| `["evaluate", "Genz(continuous) d=10 n=4096"]` | 4.670 | ✅ | 0.032 | 0.151 | 64.1 | 0.0 | 640.2 | 0.0 |
| `["evaluate", "Genz(gaussian_peak) d=10 n=1024"]` | 4.999 | ✅ | 0.008 | 0.041 | 16.1 | 0.0 | 169.2 | 0.0 |
| `["evaluate", "Genz(gaussian_peak) d=10 n=16384"]` | 4.748 | ✅ | 0.123 | 0.586 | 256.1 | 0.0 | 2689.2 | 0.0 |
| `["evaluate", "Genz(gaussian_peak) d=10 n=256"]` | 5.891 | ✅ | 0.002 | 0.015 | 4.1 | 0.0 | 43.2 | 0.0 |
| `["evaluate", "Genz(gaussian_peak) d=10 n=4096"]` | 4.746 | ✅ | 0.032 | 0.153 | 64.1 | 0.0 | 673.2 | 0.0 |
| `["evaluate", "Genz(gaussian_peak) d=200 n=1024"]` | 3.808 | ✅ | 0.050 | 0.190 | 16.1 | 0.0 | 3209.2 | 0.0 |
| `["evaluate", "Genz(gaussian_peak) d=200 n=4096"]` | 3.830 | ✅ | 0.198 | 0.760 | 64.1 | 0.0 | 12833.2 | 0.0 |
| `["evaluate", "Genz(gaussian_peak) d=50 n=1024"]` | 4.356 | ✅ | 0.018 | 0.077 | 16.1 | 0.0 | 809.2 | 0.0 |
| `["evaluate", "Genz(gaussian_peak) d=50 n=4096"]` | 3.641 | ✅ | 0.076 | 0.275 | 64.1 | 0.0 | 3233.2 | 0.0 |
| `["evaluate", "Genz(oscillatory) n=1024"]` | 5.515 | ✅ | 0.008 | 0.043 | 16.1 | 0.0 | 49.2 | 0.0 |
| `["evaluate", "Genz(oscillatory) n=16384"]` | 3.042 | ✅ | 0.228 | 0.694 | 256.1 | 0.0 | 513.0 | 0.0 |
| `["evaluate", "Genz(oscillatory) n=256"]` | 5.497 | ✅ | 0.002 | 0.014 | 4.1 | 0.0 | 13.2 | 0.0 |
| `["evaluate", "Genz(oscillatory) n=4096"]` | 5.218 | ✅ | 0.030 | 0.159 | 64.1 | 0.0 | 161.2 | 0.0 |
| `["evaluate", "Keister n=1024"]` | 3.640 | ✅ | 0.011 | 0.039 | 24.3 | 0.0 | 40.3 | 0.0 |
| `["evaluate", "Keister n=16384"]` | 2.610 | ✅ | 0.217 | 0.566 | 384.3 | 0.0 | 640.3 | 0.0 |
| `["evaluate", "Keister n=256"]` | 4.120 | ✅ | 0.003 | 0.014 | 6.3 | 0.0 | 10.3 | 0.0 |
| `["evaluate", "Keister n=4096"]` | 2.948 | ✅ | 0.046 | 0.136 | 96.3 | 0.0 | 160.3 | 0.0 |
| `["evaluate", "Linear0 d=10 n=1024"]` | 11.615 | ✅ | 0.002 | 0.026 | 8.1 | 0.0 | 8.9 | 0.0 |
| `["evaluate", "Linear0 d=10 n=16384"]` | 8.945 | ✅ | 0.044 | 0.397 | 128.1 | 2512.0 | 128.9 | 0.0 |
| `["evaluate", "Linear0 d=10 n=256"]` | 8.171 | ✅ | 0.001 | 0.008 | 2.1 | 0.0 | 2.9 | 0.0 |
| `["evaluate", "Linear0 d=10 n=4096"]` | 9.790 | ✅ | 0.010 | 0.100 | 32.1 | 0.0 | 32.9 | 0.0 |
| `["evaluate", "Linear0 d=200 n=1024"]` | 1.399 | ✅ | 0.046 | 0.064 | 8.1 | 0.0 | 8.9 | 0.0 |
| `["evaluate", "Linear0 d=200 n=4096"]` | 1.493 | ✅ | 0.165 | 0.247 | 32.1 | 4160.0 | 32.9 | 0.0 |
| `["evaluate", "Linear0 d=50 n=1024"]` | 4.380 | ✅ | 0.008 | 0.034 | 8.1 | 0.0 | 8.9 | 0.0 |
| `["evaluate", "Linear0 d=50 n=4096"]` | 2.671 | ✅ | 0.049 | 0.131 | 32.1 | 0.0 | 32.9 | 0.0 |
| `["gen_samples", "DigitalNetB2 d=10 n=1024"]` `[C]` | 3.465 | ✅ | 0.036 | 0.126 | 168.9 | 0.0 | 108.4 | 0.0 |
| `["gen_samples", "DigitalNetB2 d=10 n=16384"]` `[C]` | 0.248 | ❌ | 1.490 | 0.370 | 2568.9 | 0.0 | 1308.4 | 0.0 |
| `["gen_samples", "DigitalNetB2 d=10 n=256"]` `[C]` | 6.695 | ✅ | 0.017 | 0.112 | 48.9 | 0.0 | 48.4 | 0.0 |
| `["gen_samples", "DigitalNetB2 d=10 n=4096"]` `[C]` | 0.485 | ❌ | 0.360 | 0.175 | 648.9 | 0.0 | 348.4 | 0.0 |
| `["gen_samples", "DigitalNetB2 d=3 n=1024"]` `[C]` | 7.680 | ✅ | 0.015 | 0.118 | 51.1 | 0.0 | 52.4 | 0.0 |
| `["gen_samples", "DigitalNetB2 d=3 n=16384"]` `[C]` | 1.355 | ✅ | 0.190 | 0.257 | 771.1 | 0.0 | 412.4 | 0.0 |
| `["gen_samples", "DigitalNetB2 d=3 n=256"]` `[C]` | 16.332 | ✅ | 0.007 | 0.111 | 15.1 | 0.0 | 34.4 | 0.0 |
| `["gen_samples", "DigitalNetB2 d=3 n=4096"]` `[C]` | 2.961 | ✅ | 0.049 | 0.146 | 195.1 | 0.0 | 124.4 | 0.0 |
| `["gen_samples", "Halton d=10 n=1024"]` `[C]` | 4.119 | ✅ | 1.835 | 7.558 | 82.8 | 0.0 | 10191.6 | 0.0 |
| `["gen_samples", "Halton d=10 n=16384"]` `[C]` | 5.235 | ✅ | 29.477 | 154.308 | 1282.8 | 0.0 | 162591.4 | 0.0 |
| `["gen_samples", "Halton d=10 n=256"]` `[C]` | 4.028 | ✅ | 0.456 | 1.839 | 22.8 | 0.0 | 2571.6 | 0.0 |
| `["gen_samples", "Halton d=10 n=4096"]` `[C]` | 4.534 | ✅ | 7.327 | 33.225 | 322.8 | 0.0 | 40671.6 | 0.0 |
| `["gen_samples", "Halton d=3 n=1024"]` `[C]` | 7.476 | ✅ | 0.558 | 4.172 | 25.0 | 0.0 | 3079.6 | 0.0 |
| `["gen_samples", "Halton d=3 n=16384"]` `[C]` | 6.720 | ✅ | 9.074 | 60.981 | 385.0 | 0.0 | 48799.6 | 0.0 |
| `["gen_samples", "Halton d=3 n=256"]` `[C]` | 5.801 | ✅ | 0.141 | 0.817 | 7.0 | 0.0 | 793.6 | 0.0 |
| `["gen_samples", "Halton d=3 n=4096"]` `[C]` | 6.928 | ✅ | 2.248 | 15.571 | 97.0 | 0.0 | 12223.6 | 0.0 |
| `["gen_samples", "IIDStdUniform d=10 n=1024"]` | 4.839 | ✅ | 0.008 | 0.040 | 80.1 | 0.0 | 80.8 | 0.0 |
| `["gen_samples", "IIDStdUniform d=10 n=16384"]` | 1.719 | ✅ | 0.422 | 0.725 | 1280.1 | 0.0 | 1280.8 | 0.0 |
| `["gen_samples", "IIDStdUniform d=10 n=256"]` | 5.789 | ✅ | 0.002 | 0.013 | 20.1 | 0.0 | 20.7 | 0.0 |
| `["gen_samples", "IIDStdUniform d=10 n=4096"]` | 5.761 | ✅ | 0.026 | 0.147 | 320.1 | 0.0 | 320.8 | 0.0 |
| `["gen_samples", "IIDStdUniform d=3 n=1024"]` | 5.486 | ✅ | 0.003 | 0.015 | 24.1 | 0.0 | 24.8 | 0.0 |
| `["gen_samples", "IIDStdUniform d=3 n=16384"]` | 5.800 | ✅ | 0.030 | 0.176 | 384.1 | 0.0 | 384.8 | 0.0 |
| `["gen_samples", "IIDStdUniform d=3 n=256"]` | 6.597 | ✅ | 0.001 | 0.007 | 6.1 | 0.0 | 6.7 | 0.0 |
| `["gen_samples", "IIDStdUniform d=3 n=4096"]` | 3.631 | ✅ | 0.013 | 0.047 | 96.1 | 0.0 | 96.8 | 0.0 |
| `["gen_samples", "Kronecker d=10 n=1024"]` | 2.350 | ✅ | 0.073 | 0.171 | 80.1 | 0.0 | 233.6 | 0.0 |
| `["gen_samples", "Kronecker d=10 n=16384"]` | 1.633 | ✅ | 1.723 | 2.814 | 1280.1 | 0.0 | 2753.6 | 0.0 |
| `["gen_samples", "Kronecker d=10 n=256"]` | 2.651 | ✅ | 0.018 | 0.047 | 20.1 | 1072.0 | 63.6 | 0.0 |
| `["gen_samples", "Kronecker d=10 n=4096"]` | 2.100 | ✅ | 0.329 | 0.690 | 320.1 | 0.0 | 737.6 | 0.0 |
| `["gen_samples", "Kronecker d=3 n=1024"]` | 3.146 | ✅ | 0.021 | 0.068 | 24.1 | 0.0 | 81.6 | 0.0 |
| `["gen_samples", "Kronecker d=3 n=16384"]` | 2.507 | ✅ | 0.415 | 1.040 | 384.1 | 0.0 | 961.6 | 0.0 |
| `["gen_samples", "Kronecker d=3 n=256"]` | 3.947 | ✅ | 0.006 | 0.022 | 6.1 | 1504.0 | 21.6 | 0.0 |
| `["gen_samples", "Kronecker d=3 n=4096"]` | 2.654 | ✅ | 0.097 | 0.257 | 96.1 | 0.0 | 289.6 | 0.0 |
| `["gen_samples", "Lattice d=10 n=1024"]` `[C]` | 1.770 | ✅ | 0.174 | 0.309 | 240.9 | 0.0 | 189.3 | 0.0 |
| `["gen_samples", "Lattice d=10 n=16384"]` `[C]` | 0.630 | ❌ | 4.378 | 2.759 | 3840.9 | 0.0 | 2589.3 | 0.0 |
| `["gen_samples", "Lattice d=10 n=256"]` `[C]` | 4.073 | ✅ | 0.045 | 0.182 | 60.9 | 1600.0 | 69.3 | 0.0 |
| `["gen_samples", "Lattice d=10 n=4096"]` `[C]` | 1.164 | ✅ | 0.691 | 0.804 | 960.9 | 0.0 | 669.3 | 0.0 |
| `["gen_samples", "Lattice d=3 n=1024"]` `[C]` | 3.659 | ✅ | 0.052 | 0.190 | 72.4 | 0.0 | 77.3 | 0.0 |
| `["gen_samples", "Lattice d=3 n=16384"]` `[C]` | 1.151 | ✅ | 0.780 | 0.898 | 1152.4 | 0.0 | 797.3 | 0.0 |
| `["gen_samples", "Lattice d=3 n=256"]` `[C]` | 11.687 | ✅ | 0.013 | 0.153 | 18.4 | 2240.0 | 41.3 | 0.0 |
| `["gen_samples", "Lattice d=3 n=4096"]` `[C]` | 1.665 | ✅ | 0.200 | 0.332 | 288.4 | 0.0 | 221.3 | 0.0 |
| `["integrate", "CubMCCLT AsianOption"]` | 3.565 | ✅ | 3.189 | 11.369 | 3258.5 | 0.0 | 11001.7 | 0.0 |
| `["integrate", "CubMCCLT EuropeanOption"]` | 4.119 | ✅ | 6.772 | 27.890 | 8136.3 | 0.0 | 33415.8 | 0.0 |
| `["integrate", "CubMCCLT Keister"]` | 6.941 | ✅ | 13.596 | 94.374 | 39909.1 | 3136.0 | 123185.5 | 58788.0 |
| `["integrate", "CubQMCLatticeG EuropeanOption"]` `[C]` | 2.267 | ✅ | 2.283 | 5.178 | 2077.1 | 0.0 | 4583.1 | 0.0 |
| `["integrate", "CubQMCLatticeG Keister"]` `[C]` | 7.155 | ✅ | 0.408 | 2.917 | 570.7 | 0.0 | 401.4 | 704.0 |
| `["integrate", "CubQMCNetG AsianOption"]` | 4.049 | ✅ | 1.381 | 5.594 | 1718.7 | 0.0 | 4196.3 | 8.0 |
| `["integrate", "CubQMCNetG EuropeanOption"]` | 4.019 | ✅ | 1.372 | 5.512 | 1710.7 | 0.0 | 4196.6 | 0.0 |
| `["integrate", "CubQMCNetG Keister"]` | 11.977 | ✅ | 0.271 | 3.241 | 441.5 | 0.0 | 514.8 | 12.0 |
| `["integrate", "CubQMCNetGRep AsianOption"]` | 0.879 | ❌ | 31.095 | 27.346 | 26550.4 | 0.0 | 16561.0 | 0.0 |
| `["integrate", "CubQMCNetGRep EuropeanOption"]` | 0.875 | ❌ | 30.912 | 27.038 | 26421.3 | 0.0 | 16560.7 | 0.0 |
| `["integrate", "CubQMCNetGRep Keister"]` | 0.825 | ❌ | 3.329 | 2.746 | 4735.8 | 0.0 | 1104.4 | 0.0 |
| `["transform", "Gaussian d=10 n=1024"]` | 3.257 | ✅ | 0.137 | 0.445 | 80.1 | 0.0 | 716.5 | 0.0 |
| `["transform", "Gaussian d=10 n=16384"]` | 2.191 | ✅ | 2.632 | 5.765 | 1280.1 | 0.0 | 10466.5 | 0.0 |
| `["transform", "Gaussian d=10 n=256"]` | 5.964 | ✅ | 0.030 | 0.180 | 20.1 | 0.0 | 184.1 | 0.0 |
| `["transform", "Gaussian d=10 n=4096"]` | 2.419 | ✅ | 0.642 | 1.553 | 320.1 | 0.0 | 2666.5 | 0.0 |
| `["transform", "Gaussian d=3 n=1024"]` | 5.415 | ✅ | 0.037 | 0.199 | 24.1 | 0.0 | 220.6 | 0.0 |
| `["transform", "Gaussian d=3 n=16384"]` | 2.372 | ✅ | 0.775 | 1.839 | 384.1 | 0.0 | 3186.5 | 0.0 |
| `["transform", "Gaussian d=3 n=256"]` | 12.800 | ✅ | 0.009 | 0.121 | 6.1 | 0.0 | 56.4 | 0.0 |
| `["transform", "Gaussian d=3 n=4096"]` | 2.961 | ✅ | 0.175 | 0.518 | 96.1 | 0.0 | 846.5 | 0.0 |
| `["transform", "Gaussian(dense) d=200 n=1024"]` | 4.644 | ✅ | 4.286 | 19.907 | 3200.2 | 0.0 | 13066.5 | 0.0 |
| `["transform", "Gaussian(dense) d=200 n=4096"]` | 5.179 | ✅ | 17.345 | 89.826 | 12800.2 | 0.0 | 52066.5 | 0.0 |
| `["transform", "Gaussian(dense) d=50 n=1024"]` | 2.629 | ✅ | 0.879 | 2.311 | 800.2 | 0.0 | 3316.5 | 0.0 |
| `["transform", "Gaussian(dense) d=50 n=4096"]` | 2.449 | ✅ | 3.628 | 8.884 | 3200.2 | 0.0 | 13066.5 | 0.0 |
| `["transform", "Gaussian(diag) d=200 n=1024"]` | 5.796 | ✅ | 3.296 | 19.104 | 1600.1 | 0.0 | 13066.5 | 0.0 |
| `["transform", "Gaussian(diag) d=200 n=4096"]` | 6.739 | ✅ | 13.101 | 88.290 | 6400.1 | 0.0 | 52066.5 | 0.0 |
| `["transform", "Gaussian(diag) d=50 n=1024"]` | 2.850 | ✅ | 0.813 | 2.317 | 400.1 | 0.0 | 3316.5 | 0.0 |
| `["transform", "Gaussian(diag) d=50 n=4096"]` | 2.631 | ✅ | 3.398 | 8.941 | 1600.1 | 0.0 | 13066.5 | 0.0 |
| `["transform", "JohnsonsSU d=10 n=1024"]` | 2.853 | ✅ | 0.217 | 0.618 | 160.2 | 1040.0 | 716.5 | 0.0 |
| `["transform", "JohnsonsSU d=10 n=16384"]` | 2.239 | ✅ | 3.838 | 8.595 | 2560.2 | 0.0 | 10466.5 | 0.0 |
| `["transform", "JohnsonsSU d=10 n=256"]` | 4.035 | ✅ | 0.051 | 0.206 | 40.2 | 0.0 | 184.1 | 0.0 |
| `["transform", "JohnsonsSU d=10 n=4096"]` | 2.338 | ✅ | 0.952 | 2.226 | 640.2 | 0.0 | 2666.5 | 0.0 |
| `["transform", "StudentT d=10 n=1024"]` | 125.814 | ✅ | 0.045 | 5.665 | 80.1 | 1456.0 | 519.5 | 0.0 |
| `["transform", "StudentT d=10 n=16384"]` | 95.416 | ✅ | 0.705 | 67.291 | 1280.1 | 0.0 | 7432.1 | 0.0 |
| `["transform", "StudentT d=10 n=256"]` | 227.161 | ✅ | 0.011 | 2.572 | 20.1 | 0.0 | 139.4 | 0.0 |
| `["transform", "StudentT d=10 n=4096"]` | 98.928 | ✅ | 0.178 | 17.616 | 320.1 | 0.0 | 1864.1 | 0.0 |

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
