# Benchmark: Julia (local) vs QMCPy (Python)

| | Julia (local) | Python (QMCPy) |
|---|---|---|
| Julia label | `sha-8508c52` | — |
| Python label | — | `sha-8508c52` |
| Julia artifact mtime | `2026-06-26T13:42:55` | — |
| Python artifact mtime | — | `2026-06-26T13:48:35` |
| Julia generated at | `2026-06-26T13:34:47` | — |
| Python generated at | — | `2026-06-26T13:48:35` |
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
> Report generated at `2026-06-26T13:48:42`. Input artifact skew: `5 m 41 s`.

## Aggregate Summary

| metric | scope | ratio | Julia total | Python total | rows |
|:-------|:------|------:|------------:|-------------:|-----:|
| matched benchmarks | all matched rows | 111/111 | — | — | 111 |
| weighted time ratio | all matched rows | 4.894 | 189.738 ms | 928.584 ms | 111 |
| weighted time ratio | excluding StudentT | 4.395 | 188.682 ms | 829.200 ms | 107 |
| weighted time ratio | StudentT only | 94.055 | 1.057 ms | 99.384 ms | 4 |
| weighted time ratio 95% bootstrap CI | all matched rows | `[4.807, 4.981]` | — | — | 1000 |
| weighted time ratio 95% bootstrap CI | excluding StudentT | `[4.311, 4.474]` | — | — | 1000 |
| weighted time ratio 95% bootstrap CI | StudentT only | `[93.732, 94.487]` | — | — | 1000 |
| weighted approximate tracemalloc ratio | all matched rows | 4.377 | 173029.9 KiB | 757320.0 KiB | 111 |
| weighted approximate RSS delta ratio | all matched rows | 2.718 | 34640.0 KiB | 94160.0 KiB | 111 |


## Grouped Timing Summary

Generator, transform, integrand evaluation, and end-to-end adaptive integration are summarized separately below. The `integrate` group is mixed end-to-end cost, not isolated stopping-criterion overhead.

| group | interpretation | weighted time ratio | 95% bootstrap CI | Julia total | Python total | rows |
|:------|:---------------|--------------------:|:------------------|------------:|-------------:|-----:|
| `evaluate` | integrand evaluation only | 3.672 | `[3.242, 3.773]` | 1.971 ms | 7.237 ms | 36 |
| `gen_samples` | generator only | 5.853 | `[5.792, 5.926]` | 54.195 ms | 317.201 ms | 40 |
| `integrate` | end-to-end adaptive integration; not isolated stopping-criterion overhead | 3.086 | `[2.975, 3.235]` | 74.566 ms | 230.078 ms | 11 |
| `transform` | transform only | 6.339 | `[6.135, 6.356]` | 59.007 ms | 374.068 ms | 24 |

## Detailed Results

| benchmark | time ratio | verdict | Julia (ms) | Python (ms) | Julia alloc (KiB) | Julia RSS Δ (KiB) | Python peak (KiB) | Python RSS Δ (KiB) |
|:----------|-----------:|:-------:|----------:|------------:|-------------------:|------------------:|------------------:|-------------------:|
| `["evaluate", "BoxIntegral d=10 n=1024"]` | 4.616 | ✅ | 0.007 | 0.035 | 16.1 | 0.0 | 89.0 | 0.0 |
| `["evaluate", "BoxIntegral d=10 n=16384"]` | 2.604 | ✅ | 0.195 | 0.508 | 256.1 | 0.0 | 1409.0 | 0.0 |
| `["evaluate", "BoxIntegral d=10 n=256"]` | 4.332 | ✅ | 0.003 | 0.012 | 4.1 | 0.0 | 23.0 | 0.0 |
| `["evaluate", "BoxIntegral d=10 n=4096"]` | 4.246 | ✅ | 0.031 | 0.130 | 64.1 | 480.0 | 353.0 | 0.0 |
| `["evaluate", "BoxIntegral d=200 n=1024"]` | 3.548 | ✅ | 0.035 | 0.123 | 16.1 | 0.0 | 1609.0 | 0.0 |
| `["evaluate", "BoxIntegral d=200 n=4096"]` | 2.300 | ✅ | 0.209 | 0.480 | 64.1 | 0.0 | 6433.0 | 0.0 |
| `["evaluate", "BoxIntegral d=50 n=1024"]` | 4.347 | ✅ | 0.012 | 0.054 | 16.1 | 3856.0 | 409.0 | 0.0 |
| `["evaluate", "BoxIntegral d=50 n=4096"]` | 2.663 | ✅ | 0.077 | 0.206 | 64.1 | 0.0 | 1633.0 | 0.0 |
| `["evaluate", "Genz(continuous) d=10 n=1024"]` | 5.876 | ✅ | 0.007 | 0.041 | 16.1 | 0.0 | 160.2 | 0.0 |
| `["evaluate", "Genz(continuous) d=10 n=16384"]` | 4.763 | ✅ | 0.126 | 0.601 | 256.1 | 3856.0 | 2560.2 | 0.0 |
| `["evaluate", "Genz(continuous) d=10 n=256"]` | 5.661 | ✅ | 0.003 | 0.015 | 4.1 | 0.0 | 40.2 | 0.0 |
| `["evaluate", "Genz(continuous) d=10 n=4096"]` | 5.403 | ✅ | 0.029 | 0.156 | 64.1 | 0.0 | 640.2 | 0.0 |
| `["evaluate", "Genz(gaussian_peak) d=10 n=1024"]` | 5.745 | ✅ | 0.007 | 0.042 | 16.1 | 2640.0 | 169.2 | 0.0 |
| `["evaluate", "Genz(gaussian_peak) d=10 n=16384"]` | 4.852 | ✅ | 0.124 | 0.602 | 256.1 | 0.0 | 2689.2 | 0.0 |
| `["evaluate", "Genz(gaussian_peak) d=10 n=256"]` | 5.806 | ✅ | 0.003 | 0.015 | 4.1 | 0.0 | 43.2 | 0.0 |
| `["evaluate", "Genz(gaussian_peak) d=10 n=4096"]` | 5.387 | ✅ | 0.029 | 0.156 | 64.1 | 1584.0 | 673.2 | 0.0 |
| `["evaluate", "Genz(gaussian_peak) d=200 n=1024"]` | 5.286 | ✅ | 0.035 | 0.183 | 16.1 | 0.0 | 3209.2 | 0.0 |
| `["evaluate", "Genz(gaussian_peak) d=200 n=4096"]` | 4.189 | ✅ | 0.208 | 0.871 | 64.1 | 0.0 | 12833.2 | 0.0 |
| `["evaluate", "Genz(gaussian_peak) d=50 n=1024"]` | 5.814 | ✅ | 0.013 | 0.073 | 16.1 | 0.0 | 809.2 | 0.0 |
| `["evaluate", "Genz(gaussian_peak) d=50 n=4096"]` | 4.066 | ✅ | 0.073 | 0.297 | 64.1 | 0.0 | 3233.2 | 0.0 |
| `["evaluate", "Genz(oscillatory) n=1024"]` | 5.432 | ✅ | 0.008 | 0.042 | 16.1 | 0.0 | 49.2 | 0.0 |
| `["evaluate", "Genz(oscillatory) n=16384"]` | 5.213 | ✅ | 0.120 | 0.624 | 256.1 | 0.0 | 513.0 | 0.0 |
| `["evaluate", "Genz(oscillatory) n=256"]` | 3.547 | ✅ | 0.004 | 0.014 | 4.1 | 0.0 | 13.2 | 0.0 |
| `["evaluate", "Genz(oscillatory) n=4096"]` | 5.122 | ✅ | 0.031 | 0.158 | 64.1 | 0.0 | 161.2 | 0.0 |
| `["evaluate", "Keister n=1024"]` | 3.737 | ✅ | 0.011 | 0.040 | 24.3 | 4160.0 | 40.3 | 0.0 |
| `["evaluate", "Keister n=16384"]` | 2.720 | ✅ | 0.203 | 0.552 | 384.3 | 0.0 | 640.3 | 0.0 |
| `["evaluate", "Keister n=256"]` | 3.595 | ✅ | 0.004 | 0.014 | 6.3 | 0.0 | 10.3 | 0.0 |
| `["evaluate", "Keister n=4096"]` | 3.442 | ✅ | 0.041 | 0.142 | 96.3 | 0.0 | 160.3 | 0.0 |
| `["evaluate", "Linear0 d=10 n=1024"]` | 13.262 | ✅ | 0.002 | 0.027 | 8.1 | 0.0 | 8.9 | 0.0 |
| `["evaluate", "Linear0 d=10 n=16384"]` | 8.766 | ✅ | 0.047 | 0.414 | 128.1 | 0.0 | 128.9 | 0.0 |
| `["evaluate", "Linear0 d=10 n=256"]` | 8.162 | ✅ | 0.001 | 0.008 | 2.1 | 0.0 | 2.9 | 0.0 |
| `["evaluate", "Linear0 d=10 n=4096"]` | 11.163 | ✅ | 0.009 | 0.104 | 32.1 | 0.0 | 32.9 | 0.0 |
| `["evaluate", "Linear0 d=200 n=1024"]` | 2.564 | ✅ | 0.026 | 0.066 | 8.1 | 0.0 | 8.9 | 0.0 |
| `["evaluate", "Linear0 d=200 n=4096"]` | 1.374 | ✅ | 0.187 | 0.257 | 32.1 | 0.0 | 32.9 | 0.0 |
| `["evaluate", "Linear0 d=50 n=1024"]` | 5.705 | ✅ | 0.006 | 0.036 | 8.1 | 0.0 | 8.9 | 0.0 |
| `["evaluate", "Linear0 d=50 n=4096"]` | 3.005 | ✅ | 0.047 | 0.141 | 32.1 | 0.0 | 32.9 | 0.0 |
| `["gen_samples", "DigitalNetB2 d=10 n=1024"]` `[C]` | 2.696 | ✅ | 0.038 | 0.102 | 168.8 | 0.0 | 108.4 | 0.0 |
| `["gen_samples", "DigitalNetB2 d=10 n=16384"]` `[C]` | 0.236 | ❌ | 1.539 | 0.364 | 2568.8 | 3792.0 | 1308.4 | 0.0 |
| `["gen_samples", "DigitalNetB2 d=10 n=256"]` `[C]` | 5.089 | ✅ | 0.017 | 0.088 | 48.8 | 0.0 | 48.4 | 0.0 |
| `["gen_samples", "DigitalNetB2 d=10 n=4096"]` `[C]` | 1.302 | ✅ | 0.119 | 0.154 | 648.8 | 0.0 | 348.4 | 0.0 |
| `["gen_samples", "DigitalNetB2 d=3 n=1024"]` `[C]` | 6.408 | ✅ | 0.015 | 0.093 | 51.0 | 2048.0 | 52.4 | 0.0 |
| `["gen_samples", "DigitalNetB2 d=3 n=16384"]` `[C]` | 1.122 | ✅ | 0.206 | 0.231 | 771.0 | 0.0 | 412.4 | 0.0 |
| `["gen_samples", "DigitalNetB2 d=3 n=256"]` `[C]` | 12.831 | ✅ | 0.007 | 0.086 | 15.0 | 0.0 | 34.4 | 0.0 |
| `["gen_samples", "DigitalNetB2 d=3 n=4096"]` `[C]` | 2.427 | ✅ | 0.050 | 0.121 | 195.0 | 0.0 | 124.4 | 0.0 |
| `["gen_samples", "Halton d=10 n=1024"]` `[C]` | 5.758 | ✅ | 1.451 | 8.352 | 82.7 | 0.0 | 10191.4 | 0.0 |
| `["gen_samples", "Halton d=10 n=16384"]` `[C]` | 7.125 | ✅ | 23.645 | 168.471 | 1282.7 | 0.0 | 162591.4 | 0.0 |
| `["gen_samples", "Halton d=10 n=256"]` `[C]` | 5.022 | ✅ | 0.394 | 1.977 | 22.7 | 0.0 | 2571.4 | 0.0 |
| `["gen_samples", "Halton d=10 n=4096"]` `[C]` | 6.547 | ✅ | 5.683 | 37.210 | 322.7 | 0.0 | 40671.4 | 0.0 |
| `["gen_samples", "Halton d=3 n=1024"]` `[C]` | 10.089 | ✅ | 0.459 | 4.631 | 25.0 | 0.0 | 3079.4 | 0.0 |
| `["gen_samples", "Halton d=3 n=16384"]` `[C]` | 8.275 | ✅ | 7.972 | 65.973 | 385.0 | 0.0 | 48799.4 | 0.0 |
| `["gen_samples", "Halton d=3 n=256"]` `[C]` | 7.757 | ✅ | 0.109 | 0.844 | 7.0 | 0.0 | 793.4 | 0.0 |
| `["gen_samples", "Halton d=3 n=4096"]` `[C]` | 8.587 | ✅ | 1.910 | 16.401 | 97.0 | 0.0 | 12223.4 | 0.0 |
| `["gen_samples", "IIDStdUniform d=10 n=1024"]` | 5.442 | ✅ | 0.008 | 0.044 | 80.1 | 0.0 | 80.8 | 0.0 |
| `["gen_samples", "IIDStdUniform d=10 n=16384"]` | 1.010 | – | 0.640 | 0.647 | 1280.1 | 2080.0 | 1280.8 | 0.0 |
| `["gen_samples", "IIDStdUniform d=10 n=256"]` | 5.105 | ✅ | 0.003 | 0.014 | 20.1 | 0.0 | 20.7 | 0.0 |
| `["gen_samples", "IIDStdUniform d=10 n=4096"]` | 5.441 | ✅ | 0.030 | 0.164 | 320.1 | 0.0 | 320.8 | 0.0 |
| `["gen_samples", "IIDStdUniform d=3 n=1024"]` | 5.226 | ✅ | 0.003 | 0.016 | 24.1 | 6032.0 | 24.8 | 0.0 |
| `["gen_samples", "IIDStdUniform d=3 n=16384"]` | 6.251 | ✅ | 0.031 | 0.196 | 384.1 | 0.0 | 384.8 | 0.0 |
| `["gen_samples", "IIDStdUniform d=3 n=256"]` | 5.623 | ✅ | 0.001 | 0.007 | 6.1 | 0.0 | 6.7 | 0.0 |
| `["gen_samples", "IIDStdUniform d=3 n=4096"]` | 5.214 | ✅ | 0.010 | 0.053 | 96.1 | 2944.0 | 96.8 | 0.0 |
| `["gen_samples", "Kronecker d=10 n=1024"]` | 2.310 | ✅ | 0.073 | 0.169 | 80.1 | 0.0 | 233.6 | 0.0 |
| `["gen_samples", "Kronecker d=10 n=16384"]` | 1.453 | ✅ | 1.913 | 2.780 | 1280.1 | 0.0 | 2753.6 | 0.0 |
| `["gen_samples", "Kronecker d=10 n=256"]` | 2.511 | ✅ | 0.018 | 0.046 | 20.1 | 0.0 | 63.6 | 0.0 |
| `["gen_samples", "Kronecker d=10 n=4096"]` | 2.005 | ✅ | 0.339 | 0.680 | 320.1 | 0.0 | 737.6 | 0.0 |
| `["gen_samples", "Kronecker d=3 n=1024"]` | 1.571 | ✅ | 0.041 | 0.065 | 24.1 | 0.0 | 81.6 | 0.0 |
| `["gen_samples", "Kronecker d=3 n=16384"]` | 2.408 | ✅ | 0.416 | 1.002 | 384.1 | 0.0 | 961.6 | 0.0 |
| `["gen_samples", "Kronecker d=3 n=256"]` | 3.669 | ✅ | 0.006 | 0.021 | 6.1 | 0.0 | 21.6 | 0.0 |
| `["gen_samples", "Kronecker d=3 n=4096"]` | 2.599 | ✅ | 0.095 | 0.248 | 96.1 | 0.0 | 289.6 | 0.0 |
| `["gen_samples", "Lattice d=10 n=1024"]` `[C]` | 1.473 | ✅ | 0.201 | 0.296 | 240.9 | 0.0 | 189.2 | 0.0 |
| `["gen_samples", "Lattice d=10 n=16384"]` `[C]` | 0.650 | ❌ | 4.722 | 3.068 | 3840.9 | 624.0 | 2589.2 | 0.0 |
| `["gen_samples", "Lattice d=10 n=256"]` `[C]` | 3.066 | ✅ | 0.050 | 0.155 | 60.9 | 0.0 | 69.2 | 0.0 |
| `["gen_samples", "Lattice d=10 n=4096"]` `[C]` | 1.114 | ✅ | 0.771 | 0.859 | 960.9 | 0.0 | 669.2 | 0.0 |
| `["gen_samples", "Lattice d=3 n=1024"]` `[C]` | 2.876 | ✅ | 0.057 | 0.163 | 72.4 | 224.0 | 77.2 | 0.0 |
| `["gen_samples", "Lattice d=3 n=16384"]` `[C]` | 1.062 | ✅ | 0.909 | 0.966 | 1152.4 | 0.0 | 797.2 | 0.0 |
| `["gen_samples", "Lattice d=3 n=256"]` `[C]` | 8.184 | ✅ | 0.015 | 0.122 | 18.4 | 0.0 | 41.2 | 0.0 |
| `["gen_samples", "Lattice d=3 n=4096"]` `[C]` | 1.422 | ✅ | 0.228 | 0.324 | 288.4 | 0.0 | 221.2 | 0.0 |
| `["integrate", "CubMCCLT AsianOption"]` | 3.577 | ✅ | 3.564 | 12.746 | 3258.5 | 0.0 | 11001.7 | 0.0 |
| `["integrate", "CubMCCLT EuropeanOption"]` | 3.870 | ✅ | 7.680 | 29.725 | 8136.3 | 0.0 | 33415.8 | 32368.0 |
| `["integrate", "CubMCCLT Keister"]` | 6.492 | ✅ | 15.274 | 99.164 | 39909.1 | 0.0 | 123185.5 | 58812.0 |
| `["integrate", "CubQMCLatticeG EuropeanOption"]` `[C]` | 2.661 | ✅ | 2.105 | 5.601 | 2077.1 | 0.0 | 4583.0 | 0.0 |
| `["integrate", "CubQMCLatticeG Keister"]` `[C]` | 6.735 | ✅ | 0.419 | 2.821 | 570.7 | 0.0 | 400.9 | 704.0 |
| `["integrate", "CubQMCNetG AsianOption"]` | 4.652 | ✅ | 1.268 | 5.900 | 1718.6 | 0.0 | 4196.3 | 280.0 |
| `["integrate", "CubQMCNetG EuropeanOption"]` | 4.665 | ✅ | 1.258 | 5.867 | 1710.6 | 16.0 | 4196.5 | 0.0 |
| `["integrate", "CubQMCNetG Keister"]` | 11.817 | ✅ | 0.273 | 3.229 | 441.3 | 0.0 | 514.8 | 12.0 |
| `["integrate", "CubQMCNetGRep AsianOption"]` | 1.581 | ✅ | 19.714 | 31.165 | 26548.9 | 0.0 | 16561.0 | 1600.0 |
| `["integrate", "CubQMCNetGRep EuropeanOption"]` | 1.580 | ✅ | 19.590 | 30.949 | 26419.8 | 80.0 | 16560.9 | 0.0 |
| `["integrate", "CubQMCNetGRep Keister"]` | 0.851 | ❌ | 3.421 | 2.911 | 4732.8 | 0.0 | 1104.3 | 0.0 |
| `["transform", "Gaussian d=10 n=1024"]` | 3.385 | ✅ | 0.125 | 0.421 | 80.1 | 0.0 | 716.5 | 0.0 |
| `["transform", "Gaussian d=10 n=16384"]` | 2.247 | ✅ | 2.740 | 6.159 | 1280.1 | 0.0 | 10466.5 | 0.0 |
| `["transform", "Gaussian d=10 n=256"]` | 5.449 | ✅ | 0.029 | 0.160 | 20.1 | 0.0 | 184.1 | 0.0 |
| `["transform", "Gaussian d=10 n=4096"]` | 2.683 | ✅ | 0.578 | 1.551 | 320.1 | 0.0 | 2666.5 | 0.0 |
| `["transform", "Gaussian d=3 n=1024"]` | 5.051 | ✅ | 0.035 | 0.178 | 24.1 | 0.0 | 220.6 | 0.0 |
| `["transform", "Gaussian d=3 n=16384"]` | 2.512 | ✅ | 0.735 | 1.848 | 384.1 | 0.0 | 3186.5 | 0.0 |
| `["transform", "Gaussian d=3 n=256"]` | 10.463 | ✅ | 0.009 | 0.097 | 6.1 | 0.0 | 56.4 | 0.0 |
| `["transform", "Gaussian d=3 n=4096"]` | 3.323 | ✅ | 0.146 | 0.486 | 96.1 | 0.0 | 846.5 | 0.0 |
| `["transform", "Gaussian(dense) d=200 n=1024"]` | 4.664 | ✅ | 4.503 | 21.000 | 3200.2 | 224.0 | 13066.5 | 0.0 |
| `["transform", "Gaussian(dense) d=200 n=4096"]` | 5.145 | ✅ | 18.073 | 92.994 | 12800.2 | 0.0 | 52066.5 | 0.0 |
| `["transform", "Gaussian(dense) d=50 n=1024"]` | 2.827 | ✅ | 0.852 | 2.409 | 800.2 | 0.0 | 3316.5 | 0.0 |
| `["transform", "Gaussian(dense) d=50 n=4096"]` | 2.622 | ✅ | 3.719 | 9.750 | 3200.2 | 0.0 | 13066.5 | 0.0 |
| `["transform", "Gaussian(diag) d=200 n=1024"]` | 6.019 | ✅ | 3.439 | 20.700 | 1600.1 | 0.0 | 13066.5 | 0.0 |
| `["transform", "Gaussian(diag) d=200 n=4096"]` | 6.716 | ✅ | 13.807 | 92.728 | 6400.1 | 0.0 | 52066.5 | 0.0 |
| `["transform", "Gaussian(diag) d=50 n=1024"]` | 3.080 | ✅ | 0.771 | 2.374 | 400.1 | 0.0 | 3316.5 | 0.0 |
| `["transform", "Gaussian(diag) d=50 n=4096"]` | 2.842 | ✅ | 3.434 | 9.759 | 1600.1 | 0.0 | 13066.5 | 0.0 |
| `["transform", "JohnsonsSU d=10 n=1024"]` | 2.574 | ✅ | 0.197 | 0.506 | 160.2 | 0.0 | 716.5 | 0.0 |
| `["transform", "JohnsonsSU d=10 n=16384"]` | 2.377 | ✅ | 3.828 | 9.099 | 2560.2 | 0.0 | 10466.5 | 0.0 |
| `["transform", "JohnsonsSU d=10 n=256"]` | 3.687 | ✅ | 0.050 | 0.183 | 40.2 | 0.0 | 184.1 | 0.0 |
| `["transform", "JohnsonsSU d=10 n=4096"]` | 2.592 | ✅ | 0.880 | 2.282 | 640.2 | 0.0 | 2666.5 | 0.0 |
| `["transform", "StudentT d=10 n=1024"]` | 109.589 | ✅ | 0.050 | 5.524 | 80.1 | 0.0 | 519.3 | 0.0 |
| `["transform", "StudentT d=10 n=16384"]` | 92.392 | ✅ | 0.794 | 73.342 | 1280.1 | 0.0 | 7432.4 | 384.0 |
| `["transform", "StudentT d=10 n=256"]` | 174.972 | ✅ | 0.013 | 2.237 | 20.1 | 0.0 | 139.3 | 0.0 |
| `["transform", "StudentT d=10 n=4096"]` | 91.560 | ✅ | 0.200 | 18.281 | 320.1 | 0.0 | 1864.2 | 0.0 |

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
