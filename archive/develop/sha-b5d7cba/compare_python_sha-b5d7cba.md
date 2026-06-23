# Benchmark: Julia (local) vs QMCPy (Python)

| | Julia (local) | Python (QMCPy) |
|---|---|---|
| Julia label | `sha-b5d7cba` | — |
| Python label | — | `sha-b5d7cba` |
| Julia artifact mtime | `2026-06-23T09:31:06` | — |
| Python artifact mtime | — | `2026-06-23T09:36:19` |
| Julia generated at | `2026-06-23T09:24:46` | — |
| Python generated at | — | `2026-06-23T09:36:19` |
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
> Report generated at `2026-06-23T09:36:25`. Input artifact skew: `5 m 13 s`.

## Aggregate Summary

| metric | scope | ratio | Julia total | Python total | rows |
|:-------|:------|------:|------------:|-------------:|-----:|
| matched benchmarks | all matched rows | 111/111 | — | — | 111 |
| weighted time ratio | all matched rows | 4.122 | 173.319 ms | 714.431 ms | 111 |
| weighted time ratio | excluding StudentT | 3.695 | 172.499 ms | 637.416 ms | 107 |
| weighted time ratio | StudentT only | 93.856 | 0.821 ms | 77.016 ms | 4 |
| weighted time ratio 95% bootstrap CI | all matched rows | `[4.042, 4.472]` | — | — | 1000 |
| weighted time ratio 95% bootstrap CI | excluding StudentT | `[3.625, 4.009]` | — | — | 1000 |
| weighted time ratio 95% bootstrap CI | StudentT only | `[63.485, 94.312]` | — | — | 1000 |
| weighted approximate tracemalloc ratio | all matched rows | 4.377 | 173029.9 KiB | 757324.0 KiB | 111 |
| weighted approximate RSS delta ratio | all matched rows | 1.010 | 76192.0 KiB | 76940.0 KiB | 111 |


## Grouped Timing Summary

Generator, transform, integrand evaluation, and end-to-end adaptive integration are summarized separately below. The `integrate` group is mixed end-to-end cost, not isolated stopping-criterion overhead.

| group | interpretation | weighted time ratio | 95% bootstrap CI | Julia total | Python total | rows |
|:------|:---------------|--------------------:|:------------------|------------:|-------------:|-----:|
| `evaluate` | integrand evaluation only | 3.871 | `[3.422, 3.879]` | 1.429 ms | 5.531 ms | 36 |
| `gen_samples` | generator only | 5.283 | `[5.243, 5.372]` | 46.523 ms | 245.788 ms | 40 |
| `integrate` | end-to-end adaptive integration; not isolated stopping-criterion overhead | 2.232 | `[2.147, 2.700]` | 77.295 ms | 172.495 ms | 11 |
| `transform` | transform only | 6.045 | `[5.874, 6.162]` | 48.072 ms | 290.617 ms | 24 |

## Detailed Results

| benchmark | time ratio | verdict | Julia (ms) | Python (ms) | Julia alloc (KiB) | Julia RSS Δ (KiB) | Python peak (KiB) | Python RSS Δ (KiB) |
|:----------|-----------:|:-------:|----------:|------------:|-------------------:|------------------:|------------------:|-------------------:|
| `["evaluate", "BoxIntegral d=10 n=1024"]` | 4.247 | ✅ | 0.006 | 0.027 | 16.1 | 0.0 | 89.0 | 0.0 |
| `["evaluate", "BoxIntegral d=10 n=16384"]` | 3.905 | ✅ | 0.101 | 0.396 | 256.1 | 0.0 | 1409.0 | 0.0 |
| `["evaluate", "BoxIntegral d=10 n=256"]` | 3.814 | ✅ | 0.002 | 0.009 | 4.1 | 0.0 | 23.0 | 0.0 |
| `["evaluate", "BoxIntegral d=10 n=4096"]` | 3.918 | ✅ | 0.026 | 0.100 | 64.1 | 0.0 | 353.0 | 0.0 |
| `["evaluate", "BoxIntegral d=200 n=1024"]` | 6.112 | ✅ | 0.025 | 0.153 | 16.1 | 0.0 | 1609.0 | 0.0 |
| `["evaluate", "BoxIntegral d=200 n=4096"]` | 2.272 | ✅ | 0.160 | 0.363 | 64.1 | 0.0 | 6433.0 | 0.0 |
| `["evaluate", "BoxIntegral d=50 n=1024"]` | 4.175 | ✅ | 0.010 | 0.042 | 16.1 | 0.0 | 409.0 | 0.0 |
| `["evaluate", "BoxIntegral d=50 n=4096"]` | 3.851 | ✅ | 0.053 | 0.205 | 64.1 | 0.0 | 1633.0 | 0.0 |
| `["evaluate", "Genz(continuous) d=10 n=1024"]` | 4.984 | ✅ | 0.006 | 0.028 | 16.1 | 0.0 | 160.2 | 0.0 |
| `["evaluate", "Genz(continuous) d=10 n=16384"]` | 4.330 | ✅ | 0.094 | 0.409 | 256.1 | 0.0 | 2560.2 | 0.0 |
| `["evaluate", "Genz(continuous) d=10 n=256"]` | 4.494 | ✅ | 0.002 | 0.010 | 4.1 | 0.0 | 40.2 | 0.0 |
| `["evaluate", "Genz(continuous) d=10 n=4096"]` | 4.369 | ✅ | 0.024 | 0.106 | 64.1 | 0.0 | 640.2 | 0.0 |
| `["evaluate", "Genz(gaussian_peak) d=10 n=1024"]` | 4.868 | ✅ | 0.006 | 0.029 | 16.1 | 0.0 | 169.2 | 0.0 |
| `["evaluate", "Genz(gaussian_peak) d=10 n=16384"]` | 4.351 | ✅ | 0.094 | 0.410 | 256.1 | 0.0 | 2689.2 | 0.0 |
| `["evaluate", "Genz(gaussian_peak) d=10 n=256"]` | 4.421 | ✅ | 0.002 | 0.010 | 4.1 | 0.0 | 43.2 | 0.0 |
| `["evaluate", "Genz(gaussian_peak) d=10 n=4096"]` | 4.228 | ✅ | 0.025 | 0.106 | 64.1 | 0.0 | 673.2 | 0.0 |
| `["evaluate", "Genz(gaussian_peak) d=200 n=1024"]` | 8.125 | ✅ | 0.025 | 0.206 | 16.1 | 0.0 | 3209.2 | 0.0 |
| `["evaluate", "Genz(gaussian_peak) d=200 n=4096"]` | 3.380 | ✅ | 0.159 | 0.537 | 64.1 | 0.0 | 12833.2 | 0.0 |
| `["evaluate", "Genz(gaussian_peak) d=50 n=1024"]` | 5.744 | ✅ | 0.010 | 0.055 | 16.1 | 0.0 | 809.2 | 0.0 |
| `["evaluate", "Genz(gaussian_peak) d=50 n=4096"]` | 5.453 | ✅ | 0.053 | 0.288 | 64.1 | 0.0 | 3233.2 | 0.0 |
| `["evaluate", "Genz(oscillatory) n=1024"]` | 5.202 | ✅ | 0.006 | 0.033 | 16.1 | 0.0 | 49.2 | 0.0 |
| `["evaluate", "Genz(oscillatory) n=16384"]` | 5.201 | ✅ | 0.093 | 0.482 | 256.1 | 0.0 | 513.0 | 0.0 |
| `["evaluate", "Genz(oscillatory) n=256"]` | 4.334 | ✅ | 0.002 | 0.010 | 4.1 | 0.0 | 13.2 | 0.0 |
| `["evaluate", "Genz(oscillatory) n=4096"]` | 5.220 | ✅ | 0.023 | 0.122 | 64.1 | 0.0 | 161.2 | 0.0 |
| `["evaluate", "Keister n=1024"]` | 3.475 | ✅ | 0.009 | 0.031 | 24.3 | 0.0 | 40.3 | 0.0 |
| `["evaluate", "Keister n=16384"]` | 3.375 | ✅ | 0.127 | 0.427 | 384.3 | 0.0 | 640.3 | 0.0 |
| `["evaluate", "Keister n=256"]` | 3.720 | ✅ | 0.003 | 0.011 | 6.3 | 0.0 | 10.3 | 0.0 |
| `["evaluate", "Keister n=4096"]` | 3.241 | ✅ | 0.034 | 0.110 | 96.3 | 0.0 | 160.3 | 0.0 |
| `["evaluate", "Linear0 d=10 n=1024"]` | 12.279 | ✅ | 0.002 | 0.021 | 8.1 | 0.0 | 8.9 | 0.0 |
| `["evaluate", "Linear0 d=10 n=16384"]` | 9.317 | ✅ | 0.034 | 0.321 | 128.1 | 0.0 | 128.9 | 0.0 |
| `["evaluate", "Linear0 d=10 n=256"]` | 7.508 | ✅ | 0.001 | 0.006 | 2.1 | 0.0 | 2.9 | 0.0 |
| `["evaluate", "Linear0 d=10 n=4096"]` | 10.918 | ✅ | 0.007 | 0.081 | 32.1 | 0.0 | 32.9 | 0.0 |
| `["evaluate", "Linear0 d=200 n=1024"]` | 2.466 | ✅ | 0.021 | 0.051 | 8.1 | 0.0 | 8.9 | 0.0 |
| `["evaluate", "Linear0 d=200 n=4096"]` | 1.401 | ✅ | 0.141 | 0.198 | 32.1 | 0.0 | 32.9 | 0.0 |
| `["evaluate", "Linear0 d=50 n=1024"]` | 5.286 | ✅ | 0.005 | 0.028 | 8.1 | 6496.0 | 8.9 | 0.0 |
| `["evaluate", "Linear0 d=50 n=4096"]` | 3.103 | ✅ | 0.035 | 0.109 | 32.1 | 0.0 | 32.9 | 0.0 |
| `["gen_samples", "DigitalNetB2 d=10 n=1024"]` `[C]` | 1.469 | ✅ | 0.053 | 0.078 | 168.8 | 0.0 | 108.4 | 0.0 |
| `["gen_samples", "DigitalNetB2 d=10 n=16384"]` `[C]` | 0.227 | ❌ | 1.221 | 0.277 | 2568.8 | 0.0 | 1308.4 | 0.0 |
| `["gen_samples", "DigitalNetB2 d=10 n=256"]` `[C]` | 1.801 | ✅ | 0.037 | 0.067 | 48.8 | 8400.0 | 48.4 | 0.0 |
| `["gen_samples", "DigitalNetB2 d=10 n=4096"]` `[C]` | 0.809 | ❌ | 0.147 | 0.119 | 648.8 | 0.0 | 348.4 | 0.0 |
| `["gen_samples", "DigitalNetB2 d=3 n=1024"]` `[C]` | 3.806 | ✅ | 0.019 | 0.071 | 51.0 | 0.0 | 52.4 | 0.0 |
| `["gen_samples", "DigitalNetB2 d=3 n=16384"]` `[C]` | 0.615 | ❌ | 0.286 | 0.176 | 771.0 | 0.0 | 412.4 | 0.0 |
| `["gen_samples", "DigitalNetB2 d=3 n=256"]` `[C]` | 5.391 | ✅ | 0.012 | 0.065 | 15.0 | 8688.0 | 34.4 | 0.0 |
| `["gen_samples", "DigitalNetB2 d=3 n=4096"]` `[C]` | 2.016 | ✅ | 0.046 | 0.092 | 195.0 | 0.0 | 124.4 | 0.0 |
| `["gen_samples", "Halton d=10 n=1024"]` `[C]` | 5.392 | ✅ | 1.190 | 6.418 | 82.7 | 0.0 | 10191.6 | 0.0 |
| `["gen_samples", "Halton d=10 n=16384"]` `[C]` | 6.403 | ✅ | 20.459 | 131.001 | 1282.7 | 0.0 | 162591.4 | 0.0 |
| `["gen_samples", "Halton d=10 n=256"]` `[C]` | 5.167 | ✅ | 0.293 | 1.514 | 22.7 | 5296.0 | 2571.6 | 0.0 |
| `["gen_samples", "Halton d=10 n=4096"]` `[C]` | 5.889 | ✅ | 4.876 | 28.716 | 322.7 | 0.0 | 40671.6 | 0.0 |
| `["gen_samples", "Halton d=3 n=1024"]` `[C]` | 9.106 | ✅ | 0.389 | 3.542 | 25.0 | 0.0 | 3079.6 | 0.0 |
| `["gen_samples", "Halton d=3 n=16384"]` `[C]` | 7.603 | ✅ | 6.735 | 51.209 | 385.0 | 0.0 | 48799.6 | 0.0 |
| `["gen_samples", "Halton d=3 n=256"]` `[C]` | 6.670 | ✅ | 0.095 | 0.637 | 7.0 | 6944.0 | 793.6 | 0.0 |
| `["gen_samples", "Halton d=3 n=4096"]` `[C]` | 7.679 | ✅ | 1.620 | 12.443 | 97.0 | 0.0 | 12223.6 | 0.0 |
| `["gen_samples", "IIDStdUniform d=10 n=1024"]` | 5.099 | ✅ | 0.007 | 0.034 | 80.1 | 0.0 | 80.8 | 0.0 |
| `["gen_samples", "IIDStdUniform d=10 n=16384"]` | 0.938 | ❌ | 0.533 | 0.500 | 1280.1 | 0.0 | 1280.8 | 0.0 |
| `["gen_samples", "IIDStdUniform d=10 n=256"]` | 5.408 | ✅ | 0.002 | 0.011 | 20.1 | 4832.0 | 20.7 | 0.0 |
| `["gen_samples", "IIDStdUniform d=10 n=4096"]` | 6.163 | ✅ | 0.021 | 0.127 | 320.1 | 0.0 | 320.8 | 0.0 |
| `["gen_samples", "IIDStdUniform d=3 n=1024"]` | 5.947 | ✅ | 0.002 | 0.012 | 24.1 | 0.0 | 24.8 | 0.0 |
| `["gen_samples", "IIDStdUniform d=3 n=16384"]` | 6.178 | ✅ | 0.025 | 0.152 | 384.1 | 0.0 | 384.8 | 0.0 |
| `["gen_samples", "IIDStdUniform d=3 n=256"]` | 5.369 | ✅ | 0.001 | 0.006 | 6.1 | 2672.0 | 6.7 | 0.0 |
| `["gen_samples", "IIDStdUniform d=3 n=4096"]` | 5.055 | ✅ | 0.008 | 0.041 | 96.1 | 0.0 | 96.8 | 0.0 |
| `["gen_samples", "Kronecker d=10 n=1024"]` | 2.311 | ✅ | 0.057 | 0.131 | 80.1 | 0.0 | 233.6 | 0.0 |
| `["gen_samples", "Kronecker d=10 n=16384"]` | 1.391 | ✅ | 1.550 | 2.155 | 1280.1 | 0.0 | 2753.6 | 0.0 |
| `["gen_samples", "Kronecker d=10 n=256"]` | 2.549 | ✅ | 0.014 | 0.036 | 20.1 | 1920.0 | 63.6 | 0.0 |
| `["gen_samples", "Kronecker d=10 n=4096"]` | 2.035 | ✅ | 0.259 | 0.527 | 320.1 | 0.0 | 737.6 | 0.0 |
| `["gen_samples", "Kronecker d=3 n=1024"]` | 3.040 | ✅ | 0.017 | 0.050 | 24.1 | 0.0 | 81.6 | 0.0 |
| `["gen_samples", "Kronecker d=3 n=16384"]` | 2.419 | ✅ | 0.327 | 0.791 | 384.1 | 0.0 | 961.6 | 0.0 |
| `["gen_samples", "Kronecker d=3 n=256"]` | 3.755 | ✅ | 0.004 | 0.017 | 6.1 | 3264.0 | 21.6 | 0.0 |
| `["gen_samples", "Kronecker d=3 n=4096"]` | 2.525 | ✅ | 0.076 | 0.192 | 96.1 | 0.0 | 289.6 | 0.0 |
| `["gen_samples", "Lattice d=10 n=1024"]` `[C]` | 1.508 | ✅ | 0.150 | 0.227 | 240.9 | 0.0 | 189.3 | 0.0 |
| `["gen_samples", "Lattice d=10 n=16384"]` `[C]` | 0.642 | ❌ | 3.694 | 2.373 | 3840.9 | 0.0 | 2589.3 | 0.0 |
| `["gen_samples", "Lattice d=10 n=256"]` `[C]` | 2.898 | ✅ | 0.040 | 0.117 | 60.9 | 3856.0 | 69.3 | 0.0 |
| `["gen_samples", "Lattice d=10 n=4096"]` `[C]` | 0.703 | ❌ | 0.942 | 0.662 | 960.9 | 0.0 | 669.3 | 0.0 |
| `["gen_samples", "Lattice d=3 n=1024"]` `[C]` | 2.763 | ✅ | 0.045 | 0.124 | 72.4 | 0.0 | 77.3 | 0.0 |
| `["gen_samples", "Lattice d=3 n=16384"]` `[C]` | 0.685 | ❌ | 1.082 | 0.742 | 1152.4 | 0.0 | 797.3 | 0.0 |
| `["gen_samples", "Lattice d=3 n=256"]` `[C]` | 7.216 | ✅ | 0.013 | 0.093 | 18.4 | 1968.0 | 41.3 | 0.0 |
| `["gen_samples", "Lattice d=3 n=4096"]` `[C]` | 1.401 | ✅ | 0.177 | 0.247 | 288.4 | 0.0 | 221.3 | 0.0 |
| `["integrate", "CubMCCLT AsianOption"]` | 3.213 | ✅ | 2.759 | 8.864 | 3258.5 | 0.0 | 11001.7 | 0.0 |
| `["integrate", "CubMCCLT EuropeanOption"]` | 3.869 | ✅ | 5.578 | 21.579 | 8136.3 | 0.0 | 33415.8 | 15872.0 |
| `["integrate", "CubMCCLT Keister"]` | 7.174 | ✅ | 10.700 | 76.763 | 39909.1 | 4144.0 | 123185.3 | 58812.0 |
| `["integrate", "CubQMCLatticeG EuropeanOption"]` `[C]` | 2.430 | ✅ | 1.669 | 4.056 | 2077.1 | 0.0 | 4583.1 | 0.0 |
| `["integrate", "CubQMCLatticeG Keister"]` `[C]` | 6.253 | ✅ | 0.343 | 2.147 | 570.7 | 0.0 | 401.3 | 764.0 |
| `["integrate", "CubQMCNetG AsianOption"]` | 3.877 | ✅ | 1.126 | 4.364 | 1718.6 | 0.0 | 4196.6 | 8.0 |
| `["integrate", "CubQMCNetG EuropeanOption"]` | 3.873 | ✅ | 1.122 | 4.346 | 1710.6 | 2272.0 | 4196.6 | 0.0 |
| `["integrate", "CubQMCNetG Keister"]` | 10.989 | ✅ | 0.221 | 2.428 | 441.3 | 0.0 | 514.8 | 12.0 |
| `["integrate", "CubQMCNetGRep AsianOption"]` | 0.906 | ❌ | 25.438 | 23.049 | 26548.9 | 0.0 | 16561.0 | 1472.0 |
| `["integrate", "CubQMCNetGRep EuropeanOption"]` | 0.893 | ❌ | 25.393 | 22.676 | 26419.8 | 0.0 | 16561.0 | 0.0 |
| `["integrate", "CubQMCNetGRep Keister"]` | 0.754 | ❌ | 2.947 | 2.223 | 4732.8 | 1936.0 | 1104.5 | 0.0 |
| `["transform", "Gaussian d=10 n=1024"]` | 3.359 | ✅ | 0.097 | 0.324 | 80.1 | 0.0 | 716.5 | 0.0 |
| `["transform", "Gaussian d=10 n=16384"]` | 2.178 | ✅ | 2.156 | 4.694 | 1280.1 | 0.0 | 10466.5 | 0.0 |
| `["transform", "Gaussian d=10 n=256"]` | 5.269 | ✅ | 0.023 | 0.124 | 20.1 | 0.0 | 184.1 | 0.0 |
| `["transform", "Gaussian d=10 n=4096"]` | 2.593 | ✅ | 0.462 | 1.198 | 320.1 | 2224.0 | 2666.5 | 0.0 |
| `["transform", "Gaussian d=3 n=1024"]` | 4.887 | ✅ | 0.028 | 0.138 | 24.1 | 0.0 | 220.6 | 0.0 |
| `["transform", "Gaussian d=3 n=16384"]` | 2.464 | ✅ | 0.579 | 1.427 | 384.1 | 0.0 | 3186.5 | 0.0 |
| `["transform", "Gaussian d=3 n=256"]` | 8.118 | ✅ | 0.009 | 0.075 | 6.1 | 0.0 | 56.4 | 0.0 |
| `["transform", "Gaussian d=3 n=4096"]` | 3.253 | ✅ | 0.116 | 0.379 | 96.1 | 7088.0 | 846.5 | 0.0 |
| `["transform", "Gaussian(dense) d=200 n=1024"]` | 4.548 | ✅ | 3.577 | 16.269 | 3200.2 | 0.0 | 13066.5 | 0.0 |
| `["transform", "Gaussian(dense) d=200 n=4096"]` | 5.046 | ✅ | 14.807 | 74.714 | 12800.2 | 0.0 | 52066.5 | 0.0 |
| `["transform", "Gaussian(dense) d=50 n=1024"]` | 2.592 | ✅ | 0.722 | 1.872 | 800.2 | 0.0 | 3316.5 | 0.0 |
| `["transform", "Gaussian(dense) d=50 n=4096"]` | 2.465 | ✅ | 3.002 | 7.400 | 3200.2 | 624.0 | 13066.5 | 0.0 |
| `["transform", "Gaussian(diag) d=200 n=1024"]` | 5.954 | ✅ | 2.705 | 16.107 | 1600.1 | 0.0 | 13066.5 | 0.0 |
| `["transform", "Gaussian(diag) d=200 n=4096"]` | 6.351 | ✅ | 11.629 | 73.863 | 6400.1 | 0.0 | 52066.5 | 0.0 |
| `["transform", "Gaussian(diag) d=50 n=1024"]` | 3.069 | ✅ | 0.606 | 1.861 | 400.1 | 0.0 | 3316.5 | 0.0 |
| `["transform", "Gaussian(diag) d=50 n=4096"]` | 2.734 | ✅ | 2.700 | 7.382 | 1600.1 | 752.0 | 13066.5 | 0.0 |
| `["transform", "JohnsonsSU d=10 n=1024"]` | 1.875 | ✅ | 0.157 | 0.294 | 160.2 | 0.0 | 716.5 | 0.0 |
| `["transform", "JohnsonsSU d=10 n=16384"]` | 1.382 | ✅ | 3.099 | 4.281 | 2560.2 | 0.0 | 10466.5 | 0.0 |
| `["transform", "JohnsonsSU d=10 n=256"]` | 2.957 | ✅ | 0.039 | 0.116 | 40.2 | 0.0 | 184.1 | 0.0 |
| `["transform", "JohnsonsSU d=10 n=4096"]` | 1.471 | ✅ | 0.738 | 1.085 | 640.2 | 1344.0 | 2666.5 | 0.0 |
| `["transform", "StudentT d=10 n=1024"]` | 113.763 | ✅ | 0.039 | 4.445 | 80.1 | 0.0 | 519.8 | 0.0 |
| `["transform", "StudentT d=10 n=16384"]` | 90.736 | ✅ | 0.617 | 55.961 | 1280.1 | 0.0 | 7432.3 | 0.0 |
| `["transform", "StudentT d=10 n=256"]` | 176.197 | ✅ | 0.010 | 1.762 | 20.1 | 0.0 | 139.7 | 0.0 |
| `["transform", "StudentT d=10 n=4096"]` | 95.940 | ✅ | 0.155 | 14.847 | 320.1 | 1472.0 | 1864.5 | 0.0 |

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
