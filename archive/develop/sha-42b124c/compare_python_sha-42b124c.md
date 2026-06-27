# Benchmark: Julia (local) vs QMCPy (Python)

| | Julia (local) | Python (QMCPy) |
|---|---|---|
| Julia label | `sha-42b124c` | — |
| Python label | — | `sha-42b124c` |
| Julia artifact mtime | `2026-06-27T01:20:02` | — |
| Python artifact mtime | — | `2026-06-27T01:25:30` |
| Julia generated at | `2026-06-27T01:13:12` | — |
| Python generated at | — | `2026-06-27T01:25:30` |
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
> Report generated at `2026-06-27T01:25:37`. Input artifact skew: `5 m 28 s`.

## Aggregate Summary

| metric | scope | ratio | Julia total | Python total | rows |
|:-------|:------|------:|------------:|-------------:|-----:|
| matched benchmarks | all matched rows | 111/111 | — | — | 111 |
| weighted time ratio | all matched rows | 4.680 | 210.875 ms | 986.812 ms | 111 |
| weighted time ratio | excluding StudentT | 4.252 | 210.227 ms | 893.846 ms | 107 |
| weighted time ratio | StudentT only | 143.302 | 0.649 ms | 92.966 ms | 4 |
| weighted time ratio 95% bootstrap CI | all matched rows | `[4.620, 4.793]` | — | — | 1000 |
| weighted time ratio 95% bootstrap CI | excluding StudentT | `[4.199, 4.355]` | — | — | 1000 |
| weighted time ratio 95% bootstrap CI | StudentT only | `[142.670, 144.195]` | — | — | 1000 |
| weighted approximate tracemalloc ratio | all matched rows | 4.377 | 173029.9 KiB | 757320.6 KiB | 111 |
| weighted approximate RSS delta ratio | all matched rows | 1.497 | 40848.0 KiB | 61160.0 KiB | 111 |


## Grouped Timing Summary

Generator, transform, integrand evaluation, and end-to-end adaptive integration are summarized separately below. The `integrate` group is mixed end-to-end cost, not isolated stopping-criterion overhead.

| group | interpretation | weighted time ratio | 95% bootstrap CI | Julia total | Python total | rows |
|:------|:---------------|--------------------:|:------------------|------------:|-------------:|-----:|
| `evaluate` | integrand evaluation only | 3.388 | `[3.010, 3.394]` | 2.408 ms | 8.158 ms | 36 |
| `gen_samples` | generator only | 5.308 | `[5.281, 5.359]` | 67.953 ms | 360.712 ms | 40 |
| `integrate` | end-to-end adaptive integration; not isolated stopping-criterion overhead | 2.666 | `[2.588, 2.815]` | 87.117 ms | 232.293 ms | 11 |
| `transform` | transform only | 7.222 | `[7.072, 7.256]` | 53.397 ms | 385.650 ms | 24 |

## Detailed Results

| benchmark | time ratio | verdict | Julia (ms) | Python (ms) | Julia alloc (KiB) | Julia RSS Δ (KiB) | Python peak (KiB) | Python RSS Δ (KiB) |
|:----------|-----------:|:-------:|----------:|------------:|-------------------:|------------------:|------------------:|-------------------:|
| `["evaluate", "BoxIntegral d=10 n=1024"]` | 3.384 | ✅ | 0.009 | 0.030 | 16.1 | 0.0 | 89.0 | 0.0 |
| `["evaluate", "BoxIntegral d=10 n=16384"]` | 3.240 | ✅ | 0.152 | 0.491 | 256.1 | 0.0 | 1409.0 | 0.0 |
| `["evaluate", "BoxIntegral d=10 n=256"]` | 2.787 | ✅ | 0.004 | 0.010 | 4.1 | 0.0 | 23.0 | 0.0 |
| `["evaluate", "BoxIntegral d=10 n=4096"]` | 3.307 | ✅ | 0.033 | 0.108 | 64.1 | 0.0 | 353.0 | 0.0 |
| `["evaluate", "BoxIntegral d=200 n=1024"]` | 3.762 | ✅ | 0.051 | 0.193 | 16.1 | 0.0 | 1609.0 | 0.0 |
| `["evaluate", "BoxIntegral d=200 n=4096"]` | 2.723 | ✅ | 0.272 | 0.742 | 64.1 | 0.0 | 6433.0 | 0.0 |
| `["evaluate", "BoxIntegral d=50 n=1024"]` | 3.746 | ✅ | 0.014 | 0.051 | 16.1 | 0.0 | 409.0 | 0.0 |
| `["evaluate", "BoxIntegral d=50 n=4096"]` | 2.987 | ✅ | 0.087 | 0.260 | 64.1 | 0.0 | 1633.0 | 0.0 |
| `["evaluate", "Genz(continuous) d=10 n=1024"]` | 4.376 | ✅ | 0.008 | 0.034 | 16.1 | 0.0 | 160.2 | 0.0 |
| `["evaluate", "Genz(continuous) d=10 n=16384"]` | 4.239 | ✅ | 0.134 | 0.570 | 256.1 | 0.0 | 2560.2 | 0.0 |
| `["evaluate", "Genz(continuous) d=10 n=256"]` | 2.134 | ✅ | 0.006 | 0.012 | 4.1 | 0.0 | 40.2 | 0.0 |
| `["evaluate", "Genz(continuous) d=10 n=4096"]` | 3.828 | ✅ | 0.032 | 0.124 | 64.1 | 0.0 | 640.2 | 0.0 |
| `["evaluate", "Genz(gaussian_peak) d=10 n=1024"]` | 4.464 | ✅ | 0.008 | 0.037 | 16.1 | 0.0 | 169.2 | 0.0 |
| `["evaluate", "Genz(gaussian_peak) d=10 n=16384"]` | 4.509 | ✅ | 0.136 | 0.615 | 256.1 | 0.0 | 2689.2 | 0.0 |
| `["evaluate", "Genz(gaussian_peak) d=10 n=256"]` | 1.963 | ✅ | 0.007 | 0.013 | 4.1 | 0.0 | 43.2 | 0.0 |
| `["evaluate", "Genz(gaussian_peak) d=10 n=4096"]` | 4.406 | ✅ | 0.031 | 0.135 | 64.1 | 0.0 | 673.2 | 0.0 |
| `["evaluate", "Genz(gaussian_peak) d=200 n=1024"]` | 6.543 | ✅ | 0.055 | 0.361 | 16.1 | 0.0 | 3209.2 | 0.0 |
| `["evaluate", "Genz(gaussian_peak) d=200 n=4096"]` | 5.167 | ✅ | 0.273 | 1.411 | 64.1 | 0.0 | 12833.2 | 0.0 |
| `["evaluate", "Genz(gaussian_peak) d=50 n=1024"]` | 6.194 | ✅ | 0.014 | 0.087 | 16.1 | 0.0 | 809.2 | 0.0 |
| `["evaluate", "Genz(gaussian_peak) d=50 n=4096"]` | 4.994 | ✅ | 0.086 | 0.431 | 64.1 | 0.0 | 3233.2 | 0.0 |
| `["evaluate", "Genz(oscillatory) n=1024"]` | 3.650 | ✅ | 0.010 | 0.035 | 16.1 | 0.0 | 49.2 | 0.0 |
| `["evaluate", "Genz(oscillatory) n=16384"]` | 2.383 | ✅ | 0.247 | 0.588 | 256.1 | 0.0 | 513.0 | 0.0 |
| `["evaluate", "Genz(oscillatory) n=256"]` | 2.415 | ✅ | 0.005 | 0.012 | 4.1 | 0.0 | 13.2 | 0.0 |
| `["evaluate", "Genz(oscillatory) n=4096"]` | 2.656 | ✅ | 0.051 | 0.135 | 64.1 | 528.0 | 161.2 | 0.0 |
| `["evaluate", "Keister n=1024"]` | 3.088 | ✅ | 0.010 | 0.032 | 24.3 | 0.0 | 40.3 | 0.0 |
| `["evaluate", "Keister n=16384"]` | 2.656 | ✅ | 0.187 | 0.496 | 384.3 | 0.0 | 640.3 | 0.0 |
| `["evaluate", "Keister n=256"]` | 2.296 | ✅ | 0.005 | 0.012 | 6.3 | 0.0 | 10.3 | 0.0 |
| `["evaluate", "Keister n=4096"]` | 2.192 | ✅ | 0.051 | 0.111 | 96.3 | 5152.0 | 160.3 | 0.0 |
| `["evaluate", "Linear0 d=10 n=1024"]` | 6.265 | ✅ | 0.004 | 0.024 | 8.1 | 0.0 | 8.9 | 0.0 |
| `["evaluate", "Linear0 d=10 n=16384"]` | 6.633 | ✅ | 0.055 | 0.367 | 128.1 | 0.0 | 128.9 | 0.0 |
| `["evaluate", "Linear0 d=10 n=256"]` | 4.371 | ✅ | 0.002 | 0.007 | 2.1 | 0.0 | 2.9 | 0.0 |
| `["evaluate", "Linear0 d=10 n=4096"]` | 9.121 | ✅ | 0.010 | 0.091 | 32.1 | 0.0 | 32.9 | 0.0 |
| `["evaluate", "Linear0 d=200 n=1024"]` | 1.760 | ✅ | 0.043 | 0.076 | 8.1 | 0.0 | 8.9 | 0.0 |
| `["evaluate", "Linear0 d=200 n=4096"]` | 1.141 | ✅ | 0.250 | 0.285 | 32.1 | 0.0 | 32.9 | 0.0 |
| `["evaluate", "Linear0 d=50 n=1024"]` | 3.913 | ✅ | 0.009 | 0.034 | 8.1 | 8128.0 | 8.9 | 0.0 |
| `["evaluate", "Linear0 d=50 n=4096"]` | 2.350 | ✅ | 0.058 | 0.137 | 32.1 | 0.0 | 32.9 | 0.0 |
| `["gen_samples", "DigitalNetB2 d=10 n=1024"]` `[C]` | 1.685 | ✅ | 0.061 | 0.103 | 168.8 | 0.0 | 108.4 | 0.0 |
| `["gen_samples", "DigitalNetB2 d=10 n=16384"]` `[C]` | 0.277 | ❌ | 1.543 | 0.428 | 2568.8 | 0.0 | 1308.4 | 0.0 |
| `["gen_samples", "DigitalNetB2 d=10 n=256"]` `[C]` | 3.166 | ✅ | 0.028 | 0.088 | 48.8 | 8592.0 | 48.4 | 0.0 |
| `["gen_samples", "DigitalNetB2 d=10 n=4096"]` `[C]` | 0.864 | ❌ | 0.190 | 0.164 | 648.8 | 0.0 | 348.4 | 0.0 |
| `["gen_samples", "DigitalNetB2 d=3 n=1024"]` `[C]` | 3.997 | ✅ | 0.023 | 0.094 | 51.0 | 0.0 | 52.4 | 0.0 |
| `["gen_samples", "DigitalNetB2 d=3 n=16384"]` `[C]` | 0.703 | ❌ | 0.333 | 0.234 | 771.0 | 0.0 | 412.4 | 0.0 |
| `["gen_samples", "DigitalNetB2 d=3 n=256"]` `[C]` | 8.234 | ✅ | 0.011 | 0.087 | 15.0 | 0.0 | 34.4 | 0.0 |
| `["gen_samples", "DigitalNetB2 d=3 n=4096"]` `[C]` | 1.628 | ✅ | 0.074 | 0.121 | 195.0 | 0.0 | 124.4 | 0.0 |
| `["gen_samples", "Halton d=10 n=1024"]` `[C]` | 4.461 | ✅ | 1.994 | 8.894 | 82.7 | 0.0 | 10191.4 | 0.0 |
| `["gen_samples", "Halton d=10 n=16384"]` `[C]` | 6.264 | ✅ | 31.535 | 197.550 | 1282.7 | 0.0 | 162591.4 | 0.0 |
| `["gen_samples", "Halton d=10 n=256"]` `[C]` | 4.224 | ✅ | 0.502 | 2.120 | 22.7 | 0.0 | 2571.4 | 0.0 |
| `["gen_samples", "Halton d=10 n=4096"]` `[C]` | 5.130 | ✅ | 7.909 | 40.573 | 322.7 | 0.0 | 40671.4 | 0.0 |
| `["gen_samples", "Halton d=3 n=1024"]` `[C]` | 7.606 | ✅ | 0.569 | 4.326 | 25.0 | 0.0 | 3079.4 | 0.0 |
| `["gen_samples", "Halton d=3 n=16384"]` `[C]` | 8.457 | ✅ | 9.008 | 76.183 | 385.0 | 2816.0 | 48799.4 | 0.0 |
| `["gen_samples", "Halton d=3 n=256"]` `[C]` | 6.126 | ✅ | 0.144 | 0.884 | 7.0 | 0.0 | 793.4 | 0.0 |
| `["gen_samples", "Halton d=3 n=4096"]` `[C]` | 7.595 | ✅ | 2.290 | 17.391 | 97.0 | 0.0 | 12223.4 | 0.0 |
| `["gen_samples", "IIDStdUniform d=10 n=1024"]` | 3.003 | ✅ | 0.011 | 0.033 | 80.1 | 0.0 | 80.8 | 0.0 |
| `["gen_samples", "IIDStdUniform d=10 n=16384"]` | 1.211 | ✅ | 0.509 | 0.617 | 1280.1 | 2640.0 | 1280.8 | 0.0 |
| `["gen_samples", "IIDStdUniform d=10 n=256"]` | 3.293 | ✅ | 0.003 | 0.011 | 20.1 | 0.0 | 20.7 | 0.0 |
| `["gen_samples", "IIDStdUniform d=10 n=4096"]` | 2.803 | ✅ | 0.043 | 0.121 | 320.1 | 0.0 | 320.8 | 0.0 |
| `["gen_samples", "IIDStdUniform d=3 n=1024"]` | 3.723 | ✅ | 0.004 | 0.013 | 24.1 | 0.0 | 24.8 | 0.0 |
| `["gen_samples", "IIDStdUniform d=3 n=16384"]` | 2.890 | ✅ | 0.050 | 0.144 | 384.1 | 0.0 | 384.8 | 0.0 |
| `["gen_samples", "IIDStdUniform d=3 n=256"]` | 3.971 | ✅ | 0.002 | 0.006 | 6.1 | 0.0 | 6.7 | 0.0 |
| `["gen_samples", "IIDStdUniform d=3 n=4096"]` | 2.745 | ✅ | 0.014 | 0.039 | 96.1 | 0.0 | 96.8 | 0.0 |
| `["gen_samples", "Kronecker d=10 n=1024"]` | 1.559 | ✅ | 0.084 | 0.132 | 80.1 | 0.0 | 233.6 | 0.0 |
| `["gen_samples", "Kronecker d=10 n=16384"]` | 1.055 | ✅ | 1.995 | 2.105 | 1280.1 | 0.0 | 2753.6 | 0.0 |
| `["gen_samples", "Kronecker d=10 n=256"]` | 1.678 | ✅ | 0.023 | 0.038 | 20.1 | 0.0 | 63.6 | 0.0 |
| `["gen_samples", "Kronecker d=10 n=4096"]` | 1.295 | ✅ | 0.392 | 0.508 | 320.1 | 0.0 | 737.6 | 0.0 |
| `["gen_samples", "Kronecker d=3 n=1024"]` | 1.957 | ✅ | 0.026 | 0.051 | 24.1 | 3552.0 | 81.6 | 0.0 |
| `["gen_samples", "Kronecker d=3 n=16384"]` | 1.483 | ✅ | 0.488 | 0.724 | 384.1 | 0.0 | 961.6 | 0.0 |
| `["gen_samples", "Kronecker d=3 n=256"]` | 2.010 | ✅ | 0.009 | 0.018 | 6.1 | 0.0 | 21.6 | 0.0 |
| `["gen_samples", "Kronecker d=3 n=4096"]` | 1.612 | ✅ | 0.116 | 0.186 | 96.1 | 0.0 | 289.6 | 0.0 |
| `["gen_samples", "Lattice d=10 n=1024"]` `[C]` | 1.375 | ✅ | 0.230 | 0.316 | 240.9 | 1680.0 | 189.2 | 0.0 |
| `["gen_samples", "Lattice d=10 n=16384"]` `[C]` | 0.710 | ❌ | 4.818 | 3.422 | 3840.9 | 0.0 | 2589.2 | 0.0 |
| `["gen_samples", "Lattice d=10 n=256"]` `[C]` | 2.711 | ✅ | 0.058 | 0.157 | 60.9 | 0.0 | 69.2 | 0.0 |
| `["gen_samples", "Lattice d=10 n=4096"]` `[C]` | 0.853 | ❌ | 1.110 | 0.947 | 960.9 | 0.0 | 669.2 | 0.0 |
| `["gen_samples", "Lattice d=3 n=1024"]` `[C]` | 2.304 | ✅ | 0.075 | 0.174 | 72.4 | 0.0 | 77.2 | 0.0 |
| `["gen_samples", "Lattice d=3 n=16384"]` `[C]` | 0.887 | ❌ | 1.361 | 1.208 | 1152.4 | 0.0 | 797.2 | 0.0 |
| `["gen_samples", "Lattice d=3 n=256"]` `[C]` | 6.281 | ✅ | 0.019 | 0.122 | 18.4 | 0.0 | 41.3 | 0.0 |
| `["gen_samples", "Lattice d=3 n=4096"]` `[C]` | 1.278 | ✅ | 0.296 | 0.378 | 288.4 | 0.0 | 221.2 | 0.0 |
| `["integrate", "CubMCCLT AsianOption"]` | 3.286 | ✅ | 3.532 | 11.608 | 3258.5 | 0.0 | 11001.7 | 0.0 |
| `["integrate", "CubMCCLT EuropeanOption"]` | 4.154 | ✅ | 7.337 | 30.479 | 8136.3 | 0.0 | 33415.8 | 0.0 |
| `["integrate", "CubMCCLT Keister"]` | 6.193 | ✅ | 17.271 | 106.960 | 39909.1 | 0.0 | 123185.5 | 58800.0 |
| `["integrate", "CubQMCLatticeG EuropeanOption"]` `[C]` | 2.071 | ✅ | 2.628 | 5.441 | 2077.1 | 2112.0 | 4583.0 | 0.0 |
| `["integrate", "CubQMCLatticeG Keister"]` `[C]` | 5.049 | ✅ | 0.528 | 2.667 | 570.7 | 0.0 | 401.0 | 868.0 |
| `["integrate", "CubQMCNetG AsianOption"]` | 3.788 | ✅ | 1.498 | 5.674 | 1718.6 | 0.0 | 4196.6 | 8.0 |
| `["integrate", "CubQMCNetG EuropeanOption"]` | 3.680 | ✅ | 1.533 | 5.642 | 1710.6 | 0.0 | 4196.6 | 0.0 |
| `["integrate", "CubQMCNetG Keister"]` | 9.209 | ✅ | 0.325 | 2.996 | 441.3 | 1632.0 | 514.8 | 12.0 |
| `["integrate", "CubQMCNetGRep AsianOption"]` | 1.125 | ✅ | 25.864 | 29.109 | 26548.9 | 0.0 | 16561.0 | 1472.0 |
| `["integrate", "CubQMCNetGRep EuropeanOption"]` | 1.279 | ✅ | 22.653 | 28.981 | 26419.8 | 0.0 | 16561.0 | 0.0 |
| `["integrate", "CubQMCNetGRep Keister"]` | 0.693 | ❌ | 3.948 | 2.735 | 4732.8 | 0.0 | 1104.4 | 0.0 |
| `["transform", "Gaussian d=10 n=1024"]` | 2.660 | ✅ | 0.159 | 0.423 | 80.1 | 0.0 | 716.5 | 0.0 |
| `["transform", "Gaussian d=10 n=16384"]` | 2.303 | ✅ | 2.549 | 5.869 | 1280.1 | 0.0 | 10466.5 | 0.0 |
| `["transform", "Gaussian d=10 n=256"]` | 4.450 | ✅ | 0.035 | 0.158 | 20.1 | 0.0 | 184.1 | 0.0 |
| `["transform", "Gaussian d=10 n=4096"]` | 2.357 | ✅ | 0.660 | 1.555 | 320.1 | 0.0 | 2666.5 | 0.0 |
| `["transform", "Gaussian d=3 n=1024"]` | 3.815 | ✅ | 0.046 | 0.176 | 24.1 | 0.0 | 220.6 | 0.0 |
| `["transform", "Gaussian d=3 n=16384"]` | 2.378 | ✅ | 0.768 | 1.825 | 384.1 | 0.0 | 3186.5 | 0.0 |
| `["transform", "Gaussian d=3 n=256"]` | 8.731 | ✅ | 0.012 | 0.101 | 6.1 | 0.0 | 56.4 | 0.0 |
| `["transform", "Gaussian d=3 n=4096"]` | 2.623 | ✅ | 0.191 | 0.500 | 96.1 | 1456.0 | 846.5 | 0.0 |
| `["transform", "Gaussian(dense) d=200 n=1024"]` | 6.050 | ✅ | 3.825 | 23.145 | 3200.2 | 0.0 | 13066.5 | 0.0 |
| `["transform", "Gaussian(dense) d=200 n=4096"]` | 6.883 | ✅ | 14.928 | 102.754 | 12800.2 | 0.0 | 52066.5 | 0.0 |
| `["transform", "Gaussian(dense) d=50 n=1024"]` | 2.454 | ✅ | 1.000 | 2.454 | 800.2 | 0.0 | 3316.5 | 0.0 |
| `["transform", "Gaussian(dense) d=50 n=4096"]` | 2.845 | ✅ | 3.408 | 9.695 | 3200.2 | 1600.0 | 13066.5 | 0.0 |
| `["transform", "Gaussian(diag) d=200 n=1024"]` | 7.234 | ✅ | 3.155 | 22.823 | 1600.1 | 0.0 | 13066.5 | 0.0 |
| `["transform", "Gaussian(diag) d=200 n=4096"]` | 8.073 | ✅ | 12.562 | 101.414 | 6400.1 | 0.0 | 52066.5 | 0.0 |
| `["transform", "Gaussian(diag) d=50 n=1024"]` | 2.888 | ✅ | 0.844 | 2.438 | 400.1 | 0.0 | 3316.5 | 0.0 |
| `["transform", "Gaussian(diag) d=50 n=4096"]` | 3.052 | ✅ | 3.159 | 9.643 | 1600.1 | 0.0 | 13066.5 | 0.0 |
| `["transform", "JohnsonsSU d=10 n=1024"]` | 1.543 | ✅ | 0.260 | 0.401 | 160.2 | 0.0 | 716.5 | 0.0 |
| `["transform", "JohnsonsSU d=10 n=16384"]` | 1.372 | ✅ | 4.098 | 5.623 | 2560.2 | 0.0 | 10466.5 | 0.0 |
| `["transform", "JohnsonsSU d=10 n=256"]` | 2.412 | ✅ | 0.063 | 0.153 | 40.2 | 0.0 | 184.1 | 0.0 |
| `["transform", "JohnsonsSU d=10 n=4096"]` | 1.494 | ✅ | 1.027 | 1.535 | 640.2 | 0.0 | 2666.5 | 0.0 |
| `["transform", "StudentT d=10 n=1024"]` | 169.311 | ✅ | 0.032 | 5.395 | 80.1 | 0.0 | 519.4 | 0.0 |
| `["transform", "StudentT d=10 n=16384"]` | 138.304 | ✅ | 0.487 | 67.297 | 1280.1 | 0.0 | 7432.3 | 0.0 |
| `["transform", "StudentT d=10 n=256"]` | 272.120 | ✅ | 0.008 | 2.213 | 20.1 | 960.0 | 139.3 | 0.0 |
| `["transform", "StudentT d=10 n=4096"]` | 147.851 | ✅ | 0.122 | 18.061 | 320.1 | 0.0 | 1864.3 | 0.0 |

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
| `transform` | `Gaussian(dense) d=50 rows=3` | 3.719e-15 | 1.610e-14 | 5.0e-10 | 5.0e-10 | 0/150 | ✅ |
| `transform` | `Gaussian(diag) d=50 rows=3` | 4.663e-15 | 2.412e-15 | 1.0e-10 | 1.0e-10 | 0/150 | ✅ |
| `transform` | `JohnsonsSU d=10 rows=4` | 8.882e-16 | 9.655e-16 | 1.0e-10 | 1.0e-10 | 0/40 | ✅ |
| `transform` | `StudentT d=1 rows=4` | 0.000e+00 | 0.000e+00 | 1.0e-07 | 1.0e-07 | 0/4 | ✅ |
