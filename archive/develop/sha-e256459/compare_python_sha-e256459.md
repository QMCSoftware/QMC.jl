# Benchmark: Julia (local) vs QMCPy (Python)

| | Julia (local) | Python (QMCPy) |
|---|---|---|
| Julia label | `sha-e256459` | — |
| Python label | — | `sha-e256459` |
| Julia artifact mtime | `2026-06-19T02:27:27` | — |
| Python artifact mtime | — | `2026-06-19T02:33:08` |
| Julia generated at | `2026-06-19T02:20:38` | — |
| Python generated at | — | `2026-06-19T02:33:08` |
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
> Report generated at `2026-06-19T02:33:15`. Input artifact skew: `5 m 41 s`.

## Aggregate Summary

| metric | scope | ratio | Julia total | Python total | rows |
|:-------|:------|------:|------------:|-------------:|-----:|
| matched benchmarks | all matched rows | 111/111 | — | — | 111 |
| weighted time ratio | all matched rows | 4.705 | 194.059 ms | 913.047 ms | 111 |
| weighted time ratio | excluding StudentT | 4.214 | 193.004 ms | 813.404 ms | 107 |
| weighted time ratio | StudentT only | 94.400 | 1.056 ms | 99.643 ms | 4 |
| weighted time ratio 95% bootstrap CI | all matched rows | `[4.407, 4.833]` | — | — | 1000 |
| weighted time ratio 95% bootstrap CI | excluding StudentT | `[3.955, 4.343]` | — | — | 1000 |
| weighted time ratio 95% bootstrap CI | StudentT only | `[94.088, 94.865]` | — | — | 1000 |
| weighted approximate tracemalloc ratio | all matched rows | 4.250 | 177946.0 KiB | 756231.9 KiB | 111 |
| weighted approximate RSS delta ratio | all matched rows | 149.256 | 516.0 KiB | 77016.0 KiB | 111 |


## Grouped Timing Summary

Generator, transform, integrand evaluation, and end-to-end adaptive integration are summarized separately below. The `integrate` group is mixed end-to-end cost, not isolated stopping-criterion overhead.

| group | interpretation | weighted time ratio | 95% bootstrap CI | Julia total | Python total | rows |
|:------|:---------------|--------------------:|:------------------|------------:|-------------:|-----:|
| `evaluate` | integrand evaluation only | 3.767 | `[3.356, 3.779]` | 1.870 ms | 7.044 ms | 36 |
| `gen_samples` | generator only | 5.406 | `[5.339, 5.546]` | 58.260 ms | 314.961 ms | 40 |
| `integrate` | end-to-end adaptive integration; not isolated stopping-criterion overhead | 2.989 | `[2.576, 3.199]` | 73.806 ms | 220.616 ms | 11 |
| `transform` | transform only | 6.161 | `[6.075, 6.302]` | 60.123 ms | 370.426 ms | 24 |

## Detailed Results

| benchmark | time ratio | verdict | Julia (ms) | Python (ms) | Julia alloc (KiB) | Julia RSS Δ (KiB) | Python peak (KiB) | Python RSS Δ (KiB) |
|:----------|-----------:|:-------:|----------:|------------:|-------------------:|------------------:|------------------:|-------------------:|
| `["evaluate", "BoxIntegral d=10 n=1024"]` | 4.626 | ✅ | 0.007 | 0.035 | 16.1 | 0.0 | 89.0 | 0.0 |
| `["evaluate", "BoxIntegral d=10 n=16384"]` | 3.590 | ✅ | 0.141 | 0.508 | 256.1 | 0.0 | 1409.0 | 0.0 |
| `["evaluate", "BoxIntegral d=10 n=256"]` | 4.339 | ✅ | 0.003 | 0.012 | 4.1 | 0.0 | 23.0 | 0.0 |
| `["evaluate", "BoxIntegral d=10 n=4096"]` | 4.068 | ✅ | 0.032 | 0.131 | 64.1 | 0.0 | 353.0 | 0.0 |
| `["evaluate", "BoxIntegral d=200 n=1024"]` | 4.197 | ✅ | 0.029 | 0.124 | 16.1 | 0.0 | 1609.0 | 0.0 |
| `["evaluate", "BoxIntegral d=200 n=4096"]` | 2.261 | ✅ | 0.209 | 0.472 | 64.1 | 0.0 | 6433.0 | 4.0 |
| `["evaluate", "BoxIntegral d=50 n=1024"]` | 4.410 | ✅ | 0.012 | 0.054 | 16.1 | 0.0 | 409.0 | 0.0 |
| `["evaluate", "BoxIntegral d=50 n=4096"]` | 2.918 | ✅ | 0.071 | 0.207 | 64.1 | 0.0 | 1633.0 | 0.0 |
| `["evaluate", "Genz(continuous) d=10 n=1024"]` | 5.952 | ✅ | 0.007 | 0.042 | 16.1 | 0.0 | 160.2 | 0.0 |
| `["evaluate", "Genz(continuous) d=10 n=16384"]` | 4.754 | ✅ | 0.127 | 0.602 | 256.1 | 0.0 | 2560.2 | 0.0 |
| `["evaluate", "Genz(continuous) d=10 n=256"]` | 5.681 | ✅ | 0.003 | 0.015 | 4.1 | 0.0 | 40.2 | 0.0 |
| `["evaluate", "Genz(continuous) d=10 n=4096"]` | 5.227 | ✅ | 0.030 | 0.155 | 64.1 | 0.0 | 640.2 | 0.0 |
| `["evaluate", "Genz(gaussian_peak) d=10 n=1024"]` | 5.802 | ✅ | 0.007 | 0.042 | 16.1 | 0.0 | 169.2 | 0.0 |
| `["evaluate", "Genz(gaussian_peak) d=10 n=16384"]` | 4.772 | ✅ | 0.126 | 0.602 | 256.1 | 0.0 | 2689.2 | 0.0 |
| `["evaluate", "Genz(gaussian_peak) d=10 n=256"]` | 5.707 | ✅ | 0.003 | 0.015 | 4.1 | 0.0 | 43.2 | 0.0 |
| `["evaluate", "Genz(gaussian_peak) d=10 n=4096"]` | 5.484 | ✅ | 0.028 | 0.156 | 64.1 | 0.0 | 673.2 | 0.0 |
| `["evaluate", "Genz(gaussian_peak) d=200 n=1024"]` | 5.006 | ✅ | 0.036 | 0.181 | 16.1 | 0.0 | 3209.2 | 0.0 |
| `["evaluate", "Genz(gaussian_peak) d=200 n=4096"]` | 3.379 | ✅ | 0.209 | 0.706 | 64.1 | 0.0 | 12833.2 | 0.0 |
| `["evaluate", "Genz(gaussian_peak) d=50 n=1024"]` | 6.058 | ✅ | 0.012 | 0.074 | 16.1 | 0.0 | 809.2 | 0.0 |
| `["evaluate", "Genz(gaussian_peak) d=50 n=4096"]` | 4.015 | ✅ | 0.068 | 0.273 | 64.1 | 0.0 | 3233.2 | 0.0 |
| `["evaluate", "Genz(oscillatory) n=1024"]` | 5.405 | ✅ | 0.008 | 0.042 | 16.1 | 0.0 | 49.2 | 0.0 |
| `["evaluate", "Genz(oscillatory) n=16384"]` | 5.041 | ✅ | 0.124 | 0.625 | 256.1 | 0.0 | 513.0 | 0.0 |
| `["evaluate", "Genz(oscillatory) n=256"]` | 4.840 | ✅ | 0.003 | 0.014 | 4.1 | 0.0 | 13.2 | 0.0 |
| `["evaluate", "Genz(oscillatory) n=4096"]` | 5.340 | ✅ | 0.030 | 0.158 | 64.1 | 0.0 | 161.2 | 0.0 |
| `["evaluate", "Keister n=1024"]` | 3.680 | ✅ | 0.011 | 0.040 | 24.3 | 0.0 | 40.3 | 0.0 |
| `["evaluate", "Keister n=16384"]` | 3.382 | ✅ | 0.163 | 0.552 | 384.3 | 0.0 | 640.3 | 0.0 |
| `["evaluate", "Keister n=256"]` | 3.739 | ✅ | 0.004 | 0.014 | 6.3 | 0.0 | 10.3 | 0.0 |
| `["evaluate", "Keister n=4096"]` | 3.506 | ✅ | 0.041 | 0.143 | 96.3 | 0.0 | 160.3 | 0.0 |
| `["evaluate", "Linear0 d=10 n=1024"]` | 12.866 | ✅ | 0.002 | 0.027 | 8.1 | 0.0 | 8.9 | 0.0 |
| `["evaluate", "Linear0 d=10 n=16384"]` | 8.660 | ✅ | 0.048 | 0.415 | 128.1 | 480.0 | 128.9 | 0.0 |
| `["evaluate", "Linear0 d=10 n=256"]` | 7.659 | ✅ | 0.001 | 0.008 | 2.1 | 0.0 | 2.9 | 0.0 |
| `["evaluate", "Linear0 d=10 n=4096"]` | 10.995 | ✅ | 0.009 | 0.104 | 32.1 | 0.0 | 32.9 | 0.0 |
| `["evaluate", "Linear0 d=200 n=1024"]` | 2.513 | ✅ | 0.026 | 0.066 | 8.1 | 0.0 | 8.9 | 0.0 |
| `["evaluate", "Linear0 d=200 n=4096"]` | 1.378 | ✅ | 0.186 | 0.256 | 32.1 | 16.0 | 32.9 | 0.0 |
| `["evaluate", "Linear0 d=50 n=1024"]` | 5.716 | ✅ | 0.006 | 0.036 | 8.1 | 0.0 | 8.9 | 0.0 |
| `["evaluate", "Linear0 d=50 n=4096"]` | 2.958 | ✅ | 0.048 | 0.141 | 32.1 | 0.0 | 32.9 | 0.0 |
| `["gen_samples", "DigitalNetB2 d=10 n=1024"]` `[C]` | 2.575 | ✅ | 0.039 | 0.101 | 168.8 | 0.0 | 108.4 | 0.0 |
| `["gen_samples", "DigitalNetB2 d=10 n=16384"]` `[C]` | 0.237 | ❌ | 1.519 | 0.359 | 2568.8 | 0.0 | 1308.4 | 0.0 |
| `["gen_samples", "DigitalNetB2 d=10 n=256"]` `[C]` | 4.760 | ✅ | 0.018 | 0.086 | 48.8 | 0.0 | 48.4 | 0.0 |
| `["gen_samples", "DigitalNetB2 d=10 n=4096"]` `[C]` | 1.298 | ✅ | 0.118 | 0.153 | 648.8 | 0.0 | 348.4 | 0.0 |
| `["gen_samples", "DigitalNetB2 d=3 n=1024"]` `[C]` | 6.560 | ✅ | 0.015 | 0.098 | 51.0 | 0.0 | 52.4 | 0.0 |
| `["gen_samples", "DigitalNetB2 d=3 n=16384"]` `[C]` | 1.644 | ✅ | 0.186 | 0.307 | 771.0 | 0.0 | 412.4 | 0.0 |
| `["gen_samples", "DigitalNetB2 d=3 n=256"]` `[C]` | 12.884 | ✅ | 0.007 | 0.085 | 15.0 | 0.0 | 34.4 | 0.0 |
| `["gen_samples", "DigitalNetB2 d=3 n=4096"]` `[C]` | 2.258 | ✅ | 0.053 | 0.120 | 195.0 | 0.0 | 124.4 | 0.0 |
| `["gen_samples", "Halton d=10 n=1024"]` `[C]` | 5.374 | ✅ | 1.542 | 8.289 | 82.7 | 0.0 | 10191.4 | 0.0 |
| `["gen_samples", "Halton d=10 n=16384"]` `[C]` | 6.350 | ✅ | 26.289 | 166.939 | 1282.7 | 0.0 | 162591.6 | 0.0 |
| `["gen_samples", "Halton d=10 n=256"]` `[C]` | 5.189 | ✅ | 0.379 | 1.968 | 22.7 | 0.0 | 2571.4 | 0.0 |
| `["gen_samples", "Halton d=10 n=4096"]` `[C]` | 5.814 | ✅ | 6.296 | 36.605 | 322.7 | 0.0 | 40671.4 | 0.0 |
| `["gen_samples", "Halton d=3 n=1024"]` `[C]` | 9.121 | ✅ | 0.503 | 4.591 | 25.0 | 0.0 | 3079.4 | 0.0 |
| `["gen_samples", "Halton d=3 n=16384"]` `[C]` | 7.638 | ✅ | 8.682 | 66.309 | 385.0 | 0.0 | 48799.4 | 0.0 |
| `["gen_samples", "Halton d=3 n=256"]` `[C]` | 6.808 | ✅ | 0.123 | 0.835 | 7.0 | 0.0 | 793.6 | 0.0 |
| `["gen_samples", "Halton d=3 n=4096"]` `[C]` | 7.661 | ✅ | 2.092 | 16.024 | 97.0 | 0.0 | 12223.5 | 0.0 |
| `["gen_samples", "IIDStdUniform d=10 n=1024"]` | 4.004 | ✅ | 0.011 | 0.044 | 80.1 | 0.0 | 80.8 | 0.0 |
| `["gen_samples", "IIDStdUniform d=10 n=16384"]` | 1.343 | ✅ | 0.481 | 0.646 | 1280.1 | 0.0 | 1280.8 | 0.0 |
| `["gen_samples", "IIDStdUniform d=10 n=256"]` | 4.623 | ✅ | 0.003 | 0.014 | 20.1 | 0.0 | 20.7 | 0.0 |
| `["gen_samples", "IIDStdUniform d=10 n=4096"]` | 4.695 | ✅ | 0.035 | 0.164 | 320.1 | 0.0 | 320.8 | 0.0 |
| `["gen_samples", "IIDStdUniform d=3 n=1024"]` | 5.015 | ✅ | 0.003 | 0.016 | 24.1 | 0.0 | 24.8 | 0.0 |
| `["gen_samples", "IIDStdUniform d=3 n=16384"]` | 6.067 | ✅ | 0.032 | 0.196 | 384.1 | 0.0 | 384.8 | 0.0 |
| `["gen_samples", "IIDStdUniform d=3 n=256"]` | 5.112 | ✅ | 0.001 | 0.007 | 6.1 | 0.0 | 6.7 | 0.0 |
| `["gen_samples", "IIDStdUniform d=3 n=4096"]` | 4.810 | ✅ | 0.011 | 0.052 | 96.1 | 0.0 | 96.8 | 0.0 |
| `["gen_samples", "Kronecker d=10 n=1024"]` | 2.299 | ✅ | 0.073 | 0.169 | 80.1 | 0.0 | 233.6 | 0.0 |
| `["gen_samples", "Kronecker d=10 n=16384"]` | 1.576 | ✅ | 1.774 | 2.796 | 1280.1 | 0.0 | 2753.6 | 0.0 |
| `["gen_samples", "Kronecker d=10 n=256"]` | 2.456 | ✅ | 0.019 | 0.046 | 20.1 | 0.0 | 63.6 | 0.0 |
| `["gen_samples", "Kronecker d=10 n=4096"]` | 2.014 | ✅ | 0.339 | 0.683 | 320.1 | 0.0 | 737.6 | 0.0 |
| `["gen_samples", "Kronecker d=3 n=1024"]` | 2.928 | ✅ | 0.022 | 0.065 | 24.1 | 0.0 | 81.6 | 0.0 |
| `["gen_samples", "Kronecker d=3 n=16384"]` | 2.371 | ✅ | 0.425 | 1.007 | 384.1 | 0.0 | 961.6 | 0.0 |
| `["gen_samples", "Kronecker d=3 n=256"]` | 3.637 | ✅ | 0.006 | 0.021 | 6.1 | 0.0 | 21.6 | 0.0 |
| `["gen_samples", "Kronecker d=3 n=4096"]` | 2.519 | ✅ | 0.098 | 0.248 | 96.1 | 0.0 | 289.6 | 0.0 |
| `["gen_samples", "Lattice d=10 n=1024"]` `[C]` | 1.487 | ✅ | 0.197 | 0.293 | 240.9 | 0.0 | 189.2 | 0.0 |
| `["gen_samples", "Lattice d=10 n=16384"]` `[C]` | 0.651 | ❌ | 4.700 | 3.062 | 3840.9 | 0.0 | 2589.2 | 0.0 |
| `["gen_samples", "Lattice d=10 n=256"]` `[C]` | 2.978 | ✅ | 0.051 | 0.151 | 60.9 | 0.0 | 69.2 | 0.0 |
| `["gen_samples", "Lattice d=10 n=4096"]` `[C]` | 1.054 | ✅ | 0.810 | 0.854 | 960.9 | 0.0 | 669.2 | 0.0 |
| `["gen_samples", "Lattice d=3 n=1024"]` `[C]` | 2.815 | ✅ | 0.057 | 0.160 | 72.4 | 0.0 | 77.3 | 0.0 |
| `["gen_samples", "Lattice d=3 n=16384"]` `[C]` | 0.953 | – | 1.007 | 0.959 | 1152.4 | 0.0 | 797.3 | 0.0 |
| `["gen_samples", "Lattice d=3 n=256"]` `[C]` | 7.897 | ✅ | 0.015 | 0.118 | 18.4 | 0.0 | 41.3 | 0.0 |
| `["gen_samples", "Lattice d=3 n=4096"]` `[C]` | 1.406 | ✅ | 0.228 | 0.320 | 288.4 | 0.0 | 221.2 | 0.0 |
| `["integrate", "CubMCCLT AsianOption"]` | 3.673 | ✅ | 3.253 | 11.945 | 2928.2 | 0.0 | 11001.6 | 0.0 |
| `["integrate", "CubMCCLT EuropeanOption"]` | 4.513 | ✅ | 6.341 | 28.616 | 7199.6 | 0.0 | 33415.8 | 15872.0 |
| `["integrate", "CubMCCLT Keister"]` | 6.718 | ✅ | 14.082 | 94.599 | 32156.9 | 0.0 | 123185.4 | 58876.0 |
| `["integrate", "CubQMCLatticeG EuropeanOption"]` `[C]` | 2.420 | ✅ | 2.230 | 5.397 | 2077.1 | 0.0 | 4583.1 | 0.0 |
| `["integrate", "CubQMCLatticeG Keister"]` `[C]` | 4.637 | ✅ | 0.599 | 2.778 | 570.7 | 0.0 | 400.9 | 328.0 |
| `["integrate", "CubQMCNetG AsianOption"]` | 4.759 | ✅ | 1.223 | 5.821 | 1718.6 | 0.0 | 4196.6 | 8.0 |
| `["integrate", "CubQMCNetG EuropeanOption"]` | 4.723 | ✅ | 1.226 | 5.789 | 1710.6 | 0.0 | 4196.6 | 0.0 |
| `["integrate", "CubQMCNetG Keister"]` | 11.539 | ✅ | 0.272 | 3.140 | 441.3 | 0.0 | 514.8 | 8.0 |
| `["integrate", "CubQMCNetGRep AsianOption"]` | 1.407 | ✅ | 21.265 | 29.919 | 32944.7 | 0.0 | 16561.0 | 1472.0 |
| `["integrate", "CubQMCNetGRep EuropeanOption"]` | 1.504 | ✅ | 19.757 | 29.722 | 32816.4 | 0.0 | 16561.0 | 0.0 |
| `["integrate", "CubQMCNetGRep Keister"]` | 0.812 | ❌ | 3.558 | 2.889 | 5875.6 | 0.0 | 1104.4 | 64.0 |
| `["transform", "Gaussian d=10 n=1024"]` | 3.380 | ✅ | 0.122 | 0.413 | 80.1 | 0.0 | 716.5 | 0.0 |
| `["transform", "Gaussian d=10 n=16384"]` | 2.182 | ✅ | 2.745 | 5.990 | 1280.1 | 0.0 | 10466.5 | 0.0 |
| `["transform", "Gaussian d=10 n=256"]` | 5.365 | ✅ | 0.030 | 0.159 | 20.1 | 0.0 | 184.1 | 0.0 |
| `["transform", "Gaussian d=10 n=4096"]` | 2.613 | ✅ | 0.585 | 1.528 | 320.1 | 0.0 | 2666.5 | 0.0 |
| `["transform", "Gaussian d=3 n=1024"]` | 5.032 | ✅ | 0.035 | 0.178 | 24.1 | 0.0 | 220.6 | 0.0 |
| `["transform", "Gaussian d=3 n=16384"]` | 2.452 | ✅ | 0.745 | 1.827 | 384.1 | 0.0 | 3186.5 | 0.0 |
| `["transform", "Gaussian d=3 n=256"]` | 10.357 | ✅ | 0.009 | 0.097 | 6.1 | 0.0 | 56.4 | 0.0 |
| `["transform", "Gaussian d=3 n=4096"]` | 3.315 | ✅ | 0.145 | 0.482 | 96.1 | 0.0 | 846.5 | 0.0 |
| `["transform", "Gaussian(dense) d=200 n=1024"]` | 4.586 | ✅ | 4.432 | 20.328 | 3200.2 | 0.0 | 13066.5 | 0.0 |
| `["transform", "Gaussian(dense) d=200 n=4096"]` | 4.815 | ✅ | 19.221 | 92.545 | 12800.2 | 0.0 | 52066.5 | 0.0 |
| `["transform", "Gaussian(dense) d=50 n=1024"]` | 2.819 | ✅ | 0.843 | 2.375 | 800.2 | 0.0 | 3316.5 | 0.0 |
| `["transform", "Gaussian(dense) d=50 n=4096"]` | 2.567 | ✅ | 3.653 | 9.377 | 3200.2 | 0.0 | 13066.5 | 0.0 |
| `["transform", "Gaussian(diag) d=200 n=1024"]` | 5.872 | ✅ | 3.450 | 20.260 | 1600.1 | 0.0 | 13066.5 | 0.0 |
| `["transform", "Gaussian(diag) d=200 n=4096"]` | 6.619 | ✅ | 13.872 | 91.817 | 6400.1 | 0.0 | 52066.5 | 0.0 |
| `["transform", "Gaussian(diag) d=50 n=1024"]` | 3.054 | ✅ | 0.770 | 2.351 | 400.1 | 0.0 | 3316.5 | 0.0 |
| `["transform", "Gaussian(diag) d=50 n=4096"]` | 2.689 | ✅ | 3.456 | 9.291 | 1600.1 | 0.0 | 13066.5 | 0.0 |
| `["transform", "JohnsonsSU d=10 n=1024"]` | 2.536 | ✅ | 0.199 | 0.504 | 160.2 | 0.0 | 716.5 | 0.0 |
| `["transform", "JohnsonsSU d=10 n=16384"]` | 2.291 | ✅ | 3.843 | 8.806 | 2560.2 | 0.0 | 10466.5 | 0.0 |
| `["transform", "JohnsonsSU d=10 n=256"]` | 3.723 | ✅ | 0.049 | 0.181 | 40.2 | 20.0 | 184.1 | 0.0 |
| `["transform", "JohnsonsSU d=10 n=4096"]` | 2.632 | ✅ | 0.864 | 2.274 | 640.2 | 0.0 | 2666.5 | 0.0 |
| `["transform", "StudentT d=10 n=1024"]` | 110.125 | ✅ | 0.052 | 5.686 | 80.1 | 0.0 | 519.5 | 0.0 |
| `["transform", "StudentT d=10 n=16384"]` | 91.975 | ✅ | 0.792 | 72.838 | 1280.1 | 0.0 | 6535.5 | 384.0 |
| `["transform", "StudentT d=10 n=256"]` | 178.999 | ✅ | 0.013 | 2.292 | 20.1 | 0.0 | 139.4 | 0.0 |
| `["transform", "StudentT d=10 n=4096"]` | 94.525 | ✅ | 0.199 | 18.827 | 320.1 | 0.0 | 1671.6 | 0.0 |

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
