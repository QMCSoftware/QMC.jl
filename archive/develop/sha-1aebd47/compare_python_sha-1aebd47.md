# Benchmark: Julia (local) vs QMCPy (Python)

| | Julia (local) | Python (QMCPy) |
|---|---|---|
| Julia label | `sha-1aebd47` | — |
| Python label | — | `sha-1aebd47` |
| Julia artifact mtime | `2026-06-30T10:33:59` | — |
| Python artifact mtime | — | `2026-06-30T10:39:29` |
| Julia generated at | `2026-06-30T10:27:48` | — |
| Python generated at | — | `2026-06-30T10:39:29` |
| Julia BLAS threads | `2` | — |
| Python version | — | `3.13.14` |
| qmcpy version | — | 2.3 |
| integrate timing | `samples=9` | `repeat=9` |
| StudentT timing | `samples=21` | `repeat=21`, `warmup=3` |
| thread env | — | `MKL_NUM_THREADS=2, NUMEXPR_NUM_THREADS=2, OMP_NUM_THREADS=2, OPENBLAS_NUM_THREADS=2, QUASIMC_BENCH_BLAS_THREADS=2` |

**`ratio = Python time ÷ Julia time`**  
ratio `< 1` → local (Julia) is **slower** ❌  |  ratio `> 1` → local (Julia) is **faster** ✅  

> WARNING: C-kernel rows `[C]` (Lattice/DigitalNetB2/Halton `gen_samples`) call the same
> QMCToolsCL C-kernel family on both sides and are **not** a Julia vs Python comparison.
> `StudentT` rows are also summarized separately below because they can dominate
> the weighted cross-language time ratio.
> Julia `alloc KiB` is allocated bytes from BenchmarkTools. Julia `RSS Δ` and Python
> `RSS Δ` are coarse retained-memory signals from one warmed call. Python `tracemalloc`
> peak is Python-managed temporary memory. These are related but not interchangeable.
> The 95% timing intervals below come from bootstrap resampling of the repeated timing samples already collected inside this run. They quantify within-run timing-sample variability, not cross-machine or cross-workflow reproducibility.
> Report generated at `2026-06-30T10:39:38`. Input artifact skew: `5 m 30 s`.

## Aggregate Summary

| metric | scope | ratio | Julia total | Python total | rows |
|:-------|:------|------:|------------:|-------------:|-----:|
| matched benchmarks | all matched rows | 111/111 | — | — | 111 |
| weighted time ratio | all matched rows | 5.292 | 161.117 ms | 852.677 ms | 111 |
| weighted time ratio | excluding StudentT | 4.755 | 160.186 ms | 761.669 ms | 107 |
| weighted time ratio | StudentT only | 97.695 | 0.932 ms | 91.008 ms | 4 |
| weighted time ratio 95% bootstrap CI | all matched rows | `[5.157, 5.380]` | — | — | 1000 |
| weighted time ratio 95% bootstrap CI | excluding StudentT | `[4.641, 4.846]` | — | — | 1000 |
| weighted time ratio 95% bootstrap CI | StudentT only | `[97.407, 98.064]` | — | — | 1000 |
| weighted approximate tracemalloc ratio | all matched rows | 6.244 | 121291.7 KiB | 757322.0 KiB | 111 |
| weighted approximate RSS delta ratio | all matched rows | 1.525 | 39376.0 KiB | 60032.0 KiB | 111 |

> NOTE: RSS delta ratio compares retained process RSS after one warmed call; ratio < 1 means Python retained less RSS than Julia, and ratio > 1 means Python retained more. Treat it as an approximate retained-footprint signal, not a direct allocation metric.

## Grouped Timing Summary

Generator, transform, integrand evaluation, and end-to-end adaptive integration are summarized separately below. The `integrate` group is mixed end-to-end cost, not isolated stopping-criterion overhead.

| group | interpretation | weighted time ratio | 95% bootstrap CI | Julia total | Python total | rows |
|:------|:---------------|--------------------:|:------------------|------------:|-------------:|-----:|
| `evaluate` | integrand evaluation only | 3.347 | `[2.998, 3.370]` | 2.035 ms | 6.810 ms | 36 |
| `gen_samples` | generator only | 9.965 | `[9.786, 10.141]` | 28.984 ms | 288.837 ms | 40 |
| `integrate` | end-to-end adaptive integration; not isolated stopping-criterion overhead | 2.841 | `[2.711, 2.928]` | 72.608 ms | 206.265 ms | 11 |
| `transform` | transform only | 6.101 | `[5.939, 6.347]` | 57.490 ms | 350.766 ms | 24 |

## Detailed Results

| benchmark | time ratio | verdict | Julia (ms) | Python (ms) | Julia alloc (KiB) | Julia RSS Δ (KiB) | Python peak (KiB) | Python RSS Δ (KiB) |
|:----------|-----------:|:-------:|----------:|------------:|-------------------:|------------------:|------------------:|-------------------:|
| `["evaluate", "BoxIntegral d=10 n=1024"]` | 4.322 | ✅ | 0.008 | 0.033 | 16.1 | 0.0 | 89.0 | 0.0 |
| `["evaluate", "BoxIntegral d=10 n=16384"]` | 3.035 | ✅ | 0.162 | 0.490 | 256.1 | 0.0 | 1409.0 | 0.0 |
| `["evaluate", "BoxIntegral d=10 n=256"]` | 4.641 | ✅ | 0.002 | 0.011 | 4.1 | 0.0 | 23.0 | 0.0 |
| `["evaluate", "BoxIntegral d=10 n=4096"]` | 3.821 | ✅ | 0.033 | 0.127 | 64.1 | 0.0 | 353.0 | 0.0 |
| `["evaluate", "BoxIntegral d=200 n=1024"]` | 2.457 | ✅ | 0.048 | 0.117 | 16.1 | 0.0 | 1609.0 | 0.0 |
| `["evaluate", "BoxIntegral d=200 n=4096"]` | 2.609 | ✅ | 0.168 | 0.439 | 64.1 | 0.0 | 6433.0 | 0.0 |
| `["evaluate", "BoxIntegral d=50 n=1024"]` | 3.483 | ✅ | 0.015 | 0.052 | 16.1 | 0.0 | 409.0 | 0.0 |
| `["evaluate", "BoxIntegral d=50 n=4096"]` | 2.740 | ✅ | 0.073 | 0.200 | 64.1 | 0.0 | 1633.0 | 0.0 |
| `["evaluate", "Genz(continuous) d=10 n=1024"]` | 5.408 | ✅ | 0.008 | 0.041 | 16.1 | 0.0 | 160.2 | 0.0 |
| `["evaluate", "Genz(continuous) d=10 n=16384"]` | 4.379 | ✅ | 0.130 | 0.569 | 256.1 | 0.0 | 2560.2 | 0.0 |
| `["evaluate", "Genz(continuous) d=10 n=256"]` | 5.558 | ✅ | 0.003 | 0.014 | 4.1 | 0.0 | 40.2 | 0.0 |
| `["evaluate", "Genz(continuous) d=10 n=4096"]` | 4.679 | ✅ | 0.031 | 0.147 | 64.1 | 0.0 | 640.2 | 0.0 |
| `["evaluate", "Genz(gaussian_peak) d=10 n=1024"]` | 5.150 | ✅ | 0.008 | 0.041 | 16.1 | 880.0 | 169.2 | 0.0 |
| `["evaluate", "Genz(gaussian_peak) d=10 n=16384"]` | 4.782 | ✅ | 0.119 | 0.569 | 256.1 | 0.0 | 2689.2 | 0.0 |
| `["evaluate", "Genz(gaussian_peak) d=10 n=256"]` | 5.383 | ✅ | 0.003 | 0.015 | 4.1 | 0.0 | 43.2 | 0.0 |
| `["evaluate", "Genz(gaussian_peak) d=10 n=4096"]` | 4.636 | ✅ | 0.033 | 0.152 | 64.1 | 0.0 | 673.2 | 0.0 |
| `["evaluate", "Genz(gaussian_peak) d=200 n=1024"]` | 2.374 | ✅ | 0.071 | 0.169 | 16.1 | 0.0 | 3209.2 | 0.0 |
| `["evaluate", "Genz(gaussian_peak) d=200 n=4096"]` | 3.901 | ✅ | 0.166 | 0.648 | 64.1 | 0.0 | 12833.2 | 0.0 |
| `["evaluate", "Genz(gaussian_peak) d=50 n=1024"]` | 4.346 | ✅ | 0.016 | 0.069 | 16.1 | 0.0 | 809.2 | 0.0 |
| `["evaluate", "Genz(gaussian_peak) d=50 n=4096"]` | 3.059 | ✅ | 0.085 | 0.259 | 64.1 | 0.0 | 3233.2 | 0.0 |
| `["evaluate", "Genz(oscillatory) n=1024"]` | 5.323 | ✅ | 0.008 | 0.043 | 16.1 | 0.0 | 49.2 | 0.0 |
| `["evaluate", "Genz(oscillatory) n=16384"]` | 2.911 | ✅ | 0.235 | 0.683 | 256.1 | 0.0 | 513.0 | 0.0 |
| `["evaluate", "Genz(oscillatory) n=256"]` | 4.973 | ✅ | 0.003 | 0.014 | 4.1 | 0.0 | 13.2 | 0.0 |
| `["evaluate", "Genz(oscillatory) n=4096"]` | 5.026 | ✅ | 0.032 | 0.160 | 64.1 | 0.0 | 161.2 | 0.0 |
| `["evaluate", "Keister n=1024"]` | 3.350 | ✅ | 0.012 | 0.039 | 24.3 | 0.0 | 40.3 | 0.0 |
| `["evaluate", "Keister n=16384"]` | 2.608 | ✅ | 0.215 | 0.560 | 384.3 | 5856.0 | 640.3 | 0.0 |
| `["evaluate", "Keister n=256"]` | 4.071 | ✅ | 0.003 | 0.014 | 6.3 | 0.0 | 10.3 | 0.0 |
| `["evaluate", "Keister n=4096"]` | 3.112 | ✅ | 0.044 | 0.137 | 96.3 | 0.0 | 160.3 | 0.0 |
| `["evaluate", "Linear0 d=10 n=1024"]` | 11.317 | ✅ | 0.002 | 0.026 | 8.1 | 0.0 | 8.9 | 0.0 |
| `["evaluate", "Linear0 d=10 n=16384"]` | 8.012 | ✅ | 0.049 | 0.394 | 128.1 | 0.0 | 128.9 | 0.0 |
| `["evaluate", "Linear0 d=10 n=256"]` | 8.114 | ✅ | 0.001 | 0.008 | 2.1 | 0.0 | 2.9 | 0.0 |
| `["evaluate", "Linear0 d=10 n=4096"]` | 10.011 | ✅ | 0.010 | 0.100 | 32.1 | 0.0 | 32.9 | 0.0 |
| `["evaluate", "Linear0 d=200 n=1024"]` | 1.557 | ✅ | 0.040 | 0.063 | 8.1 | 0.0 | 8.9 | 0.0 |
| `["evaluate", "Linear0 d=200 n=4096"]` | 1.664 | ✅ | 0.146 | 0.243 | 32.1 | 0.0 | 32.9 | 0.0 |
| `["evaluate", "Linear0 d=50 n=1024"]` | 4.966 | ✅ | 0.007 | 0.034 | 8.1 | 0.0 | 8.9 | 0.0 |
| `["evaluate", "Linear0 d=50 n=4096"]` | 2.768 | ✅ | 0.047 | 0.130 | 32.1 | 0.0 | 32.9 | 0.0 |
| `["gen_samples", "DigitalNetB2 d=10 n=1024"]` `[C]` | 3.148 | ✅ | 0.039 | 0.124 | 166.1 | 0.0 | 108.4 | 0.0 |
| `["gen_samples", "DigitalNetB2 d=10 n=16384"]` `[C]` | 0.246 | ❌ | 1.497 | 0.368 | 2566.1 | 0.0 | 1308.4 | 0.0 |
| `["gen_samples", "DigitalNetB2 d=10 n=256"]` `[C]` | 7.600 | ✅ | 0.015 | 0.112 | 46.1 | 0.0 | 48.4 | 0.0 |
| `["gen_samples", "DigitalNetB2 d=10 n=4096"]` `[C]` | 1.124 | ✅ | 0.157 | 0.176 | 646.1 | 0.0 | 348.4 | 0.0 |
| `["gen_samples", "DigitalNetB2 d=3 n=1024"]` `[C]` | 7.686 | ✅ | 0.015 | 0.118 | 50.5 | 0.0 | 52.4 | 0.0 |
| `["gen_samples", "DigitalNetB2 d=3 n=16384"]` `[C]` | 1.178 | ✅ | 0.221 | 0.260 | 770.5 | 0.0 | 412.4 | 0.0 |
| `["gen_samples", "DigitalNetB2 d=3 n=256"]` `[C]` | 19.192 | ✅ | 0.006 | 0.110 | 14.5 | 0.0 | 34.4 | 0.0 |
| `["gen_samples", "DigitalNetB2 d=3 n=4096"]` `[C]` | 2.979 | ✅ | 0.049 | 0.146 | 194.5 | 0.0 | 124.4 | 0.0 |
| `["gen_samples", "Halton d=10 n=1024"]` `[C]` | 10.321 | ✅ | 0.721 | 7.437 | 82.8 | 0.0 | 10191.6 | 0.0 |
| `["gen_samples", "Halton d=10 n=16384"]` `[C]` | 12.197 | ✅ | 12.523 | 152.735 | 1282.8 | 0.0 | 162591.4 | 0.0 |
| `["gen_samples", "Halton d=10 n=256"]` `[C]` | 10.141 | ✅ | 0.179 | 1.814 | 22.8 | 0.0 | 2571.6 | 0.0 |
| `["gen_samples", "Halton d=10 n=4096"]` `[C]` | 11.196 | ✅ | 2.943 | 32.946 | 322.8 | 0.0 | 40671.6 | 0.0 |
| `["gen_samples", "Halton d=3 n=1024"]` `[C]` | 17.960 | ✅ | 0.233 | 4.193 | 25.0 | 0.0 | 3079.6 | 0.0 |
| `["gen_samples", "Halton d=3 n=16384"]` `[C]` | 14.947 | ✅ | 4.006 | 59.874 | 385.0 | 0.0 | 48799.4 | 0.0 |
| `["gen_samples", "Halton d=3 n=256"]` `[C]` | 13.811 | ✅ | 0.059 | 0.810 | 7.0 | 0.0 | 793.6 | 0.0 |
| `["gen_samples", "Halton d=3 n=4096"]` `[C]` | 16.288 | ✅ | 0.966 | 15.739 | 97.0 | 5952.0 | 12223.6 | 0.0 |
| `["gen_samples", "IIDStdUniform d=10 n=1024"]` | 4.988 | ✅ | 0.008 | 0.039 | 80.1 | 0.0 | 80.8 | 0.0 |
| `["gen_samples", "IIDStdUniform d=10 n=16384"]` | 1.169 | ✅ | 0.595 | 0.695 | 1280.1 | 0.0 | 1280.8 | 0.0 |
| `["gen_samples", "IIDStdUniform d=10 n=256"]` | 6.097 | ✅ | 0.002 | 0.013 | 20.1 | 0.0 | 20.7 | 0.0 |
| `["gen_samples", "IIDStdUniform d=10 n=4096"]` | 5.985 | ✅ | 0.025 | 0.147 | 320.1 | 0.0 | 320.8 | 0.0 |
| `["gen_samples", "IIDStdUniform d=3 n=1024"]` | 6.136 | ✅ | 0.002 | 0.015 | 24.1 | 0.0 | 24.8 | 0.0 |
| `["gen_samples", "IIDStdUniform d=3 n=16384"]` | 5.878 | ✅ | 0.030 | 0.177 | 384.1 | 0.0 | 384.8 | 0.0 |
| `["gen_samples", "IIDStdUniform d=3 n=256"]` | 6.001 | ✅ | 0.001 | 0.006 | 6.1 | 0.0 | 6.7 | 0.0 |
| `["gen_samples", "IIDStdUniform d=3 n=4096"]` | 4.251 | ✅ | 0.011 | 0.047 | 96.1 | 0.0 | 96.8 | 0.0 |
| `["gen_samples", "Kronecker d=10 n=1024"]` | 7.058 | ✅ | 0.024 | 0.171 | 80.1 | 272.0 | 233.6 | 0.0 |
| `["gen_samples", "Kronecker d=10 n=16384"]` | 3.284 | ✅ | 0.853 | 2.801 | 1280.1 | 0.0 | 2753.6 | 0.0 |
| `["gen_samples", "Kronecker d=10 n=256"]` | 7.977 | ✅ | 0.006 | 0.047 | 20.1 | 0.0 | 63.6 | 0.0 |
| `["gen_samples", "Kronecker d=10 n=4096"]` | 7.488 | ✅ | 0.091 | 0.684 | 320.1 | 0.0 | 737.6 | 0.0 |
| `["gen_samples", "Kronecker d=3 n=1024"]` | 9.517 | ✅ | 0.007 | 0.068 | 24.1 | 0.0 | 81.6 | 0.0 |
| `["gen_samples", "Kronecker d=3 n=16384"]` | 9.242 | ✅ | 0.113 | 1.044 | 384.1 | 0.0 | 961.6 | 0.0 |
| `["gen_samples", "Kronecker d=3 n=256"]` | 10.816 | ✅ | 0.002 | 0.022 | 6.1 | 0.0 | 21.6 | 0.0 |
| `["gen_samples", "Kronecker d=3 n=4096"]` | 8.540 | ✅ | 0.030 | 0.259 | 96.1 | 0.0 | 289.6 | 0.0 |
| `["gen_samples", "Lattice d=10 n=1024"]` `[C]` | 4.374 | ✅ | 0.071 | 0.310 | 240.9 | 0.0 | 189.2 | 0.0 |
| `["gen_samples", "Lattice d=10 n=16384"]` `[C]` | 1.051 | ✅ | 2.629 | 2.764 | 3840.9 | 0.0 | 2589.3 | 0.0 |
| `["gen_samples", "Lattice d=10 n=256"]` `[C]` | 9.296 | ✅ | 0.020 | 0.182 | 60.9 | 0.0 | 69.2 | 0.0 |
| `["gen_samples", "Lattice d=10 n=4096"]` `[C]` | 2.929 | ✅ | 0.276 | 0.808 | 960.9 | 0.0 | 669.2 | 0.0 |
| `["gen_samples", "Lattice d=3 n=1024"]` `[C]` | 5.712 | ✅ | 0.033 | 0.189 | 72.4 | 0.0 | 77.3 | 0.0 |
| `["gen_samples", "Lattice d=3 n=16384"]` `[C]` | 2.151 | ✅ | 0.417 | 0.897 | 1152.4 | 3488.0 | 797.3 | 0.0 |
| `["gen_samples", "Lattice d=3 n=256"]` `[C]` | 21.072 | ✅ | 0.007 | 0.152 | 18.4 | 0.0 | 41.3 | 4.0 |
| `["gen_samples", "Lattice d=3 n=4096"]` `[C]` | 3.243 | ✅ | 0.104 | 0.337 | 288.4 | 0.0 | 221.3 | 0.0 |
| `["integrate", "CubMCCLT AsianOption"]` | 2.829 | ✅ | 3.765 | 10.650 | 3258.5 | 0.0 | 11001.7 | 0.0 |
| `["integrate", "CubMCCLT EuropeanOption"]` | 3.410 | ✅ | 7.885 | 26.885 | 8136.3 | 6992.0 | 33415.8 | 0.0 |
| `["integrate", "CubMCCLT Keister"]` | 6.945 | ✅ | 13.276 | 92.201 | 39909.1 | 0.0 | 123185.4 | 58760.0 |
| `["integrate", "CubQMCLatticeG EuropeanOption"]` `[C]` | 3.672 | ✅ | 1.403 | 5.151 | 2077.1 | 0.0 | 4583.1 | 0.0 |
| `["integrate", "CubQMCLatticeG Keister"]` `[C]` | 8.738 | ✅ | 0.333 | 2.908 | 570.7 | 0.0 | 401.1 | 868.0 |
| `["integrate", "CubQMCNetG AsianOption"]` | 4.106 | ✅ | 1.340 | 5.502 | 1703.4 | 2912.0 | 4196.6 | 8.0 |
| `["integrate", "CubQMCNetG EuropeanOption"]` | 4.190 | ✅ | 1.307 | 5.475 | 1695.4 | 0.0 | 4196.6 | 0.0 |
| `["integrate", "CubQMCNetG Keister"]` | 11.948 | ✅ | 0.270 | 3.228 | 440.2 | 0.0 | 514.8 | 12.0 |
| `["integrate", "CubQMCNetGRep AsianOption"]` | 1.296 | ✅ | 19.944 | 25.852 | 2299.2 | 0.0 | 16560.7 | 0.0 |
| `["integrate", "CubQMCNetGRep EuropeanOption"]` | 1.296 | ✅ | 19.834 | 25.697 | 2170.1 | 0.0 | 16561.0 | 0.0 |
| `["integrate", "CubQMCNetGRep Keister"]` | 0.835 | ❌ | 3.252 | 2.716 | 1538.0 | 0.0 | 1104.3 | 0.0 |
| `["transform", "Gaussian d=10 n=1024"]` | 3.170 | ✅ | 0.141 | 0.448 | 80.1 | 0.0 | 716.5 | 0.0 |
| `["transform", "Gaussian d=10 n=16384"]` | 2.189 | ✅ | 2.636 | 5.770 | 1280.1 | 0.0 | 10466.5 | 0.0 |
| `["transform", "Gaussian d=10 n=256"]` | 5.881 | ✅ | 0.031 | 0.181 | 20.1 | 0.0 | 184.1 | 0.0 |
| `["transform", "Gaussian d=10 n=4096"]` | 2.341 | ✅ | 0.653 | 1.529 | 320.1 | 4160.0 | 2666.5 | 0.0 |
| `["transform", "Gaussian d=3 n=1024"]` | 4.763 | ✅ | 0.042 | 0.200 | 24.1 | 0.0 | 220.6 | 0.0 |
| `["transform", "Gaussian d=3 n=16384"]` | 2.320 | ✅ | 0.781 | 1.813 | 384.1 | 0.0 | 3186.5 | 0.0 |
| `["transform", "Gaussian d=3 n=256"]` | 12.790 | ✅ | 0.010 | 0.122 | 6.1 | 0.0 | 56.4 | 0.0 |
| `["transform", "Gaussian d=3 n=4096"]` | 2.963 | ✅ | 0.176 | 0.522 | 96.1 | 5584.0 | 846.5 | 0.0 |
| `["transform", "Gaussian(dense) d=200 n=1024"]` | 4.510 | ✅ | 4.365 | 19.687 | 3200.2 | 0.0 | 13066.5 | 0.0 |
| `["transform", "Gaussian(dense) d=200 n=4096"]` | 5.127 | ✅ | 17.476 | 89.596 | 12800.2 | 0.0 | 52066.5 | 0.0 |
| `["transform", "Gaussian(dense) d=50 n=1024"]` | 2.492 | ✅ | 0.923 | 2.301 | 800.2 | 0.0 | 3316.5 | 0.0 |
| `["transform", "Gaussian(dense) d=50 n=4096"]` | 2.468 | ✅ | 3.568 | 8.804 | 3200.2 | 0.0 | 13066.5 | 0.0 |
| `["transform", "Gaussian(diag) d=200 n=1024"]` | 5.817 | ✅ | 3.289 | 19.133 | 1600.1 | 0.0 | 13066.5 | 0.0 |
| `["transform", "Gaussian(diag) d=200 n=4096"]` | 6.602 | ✅ | 13.178 | 87.002 | 6400.1 | 0.0 | 52066.5 | 0.0 |
| `["transform", "Gaussian(diag) d=50 n=1024"]` | 2.816 | ✅ | 0.817 | 2.302 | 400.1 | 0.0 | 3316.5 | 0.0 |
| `["transform", "Gaussian(diag) d=50 n=4096"]` | 2.680 | ✅ | 3.286 | 8.807 | 1600.1 | 0.0 | 13066.5 | 0.0 |
| `["transform", "JohnsonsSU d=10 n=1024"]` | 2.725 | ✅ | 0.227 | 0.619 | 160.2 | 0.0 | 716.5 | 0.0 |
| `["transform", "JohnsonsSU d=10 n=16384"]` | 2.161 | ✅ | 3.933 | 8.501 | 2560.2 | 0.0 | 10466.5 | 0.0 |
| `["transform", "JohnsonsSU d=10 n=256"]` | 3.966 | ✅ | 0.052 | 0.207 | 40.2 | 0.0 | 184.1 | 0.0 |
| `["transform", "JohnsonsSU d=10 n=4096"]` | 2.273 | ✅ | 0.974 | 2.213 | 640.2 | 0.0 | 2666.5 | 0.0 |
| `["transform", "StudentT d=10 n=1024"]` | 128.893 | ✅ | 0.044 | 5.677 | 80.1 | 3280.0 | 519.4 | 0.0 |
| `["transform", "StudentT d=10 n=16384"]` | 93.126 | ✅ | 0.699 | 65.139 | 1280.1 | 0.0 | 7432.4 | 380.0 |
| `["transform", "StudentT d=10 n=256"]` | 228.482 | ✅ | 0.011 | 2.574 | 20.1 | 0.0 | 139.5 | 0.0 |
| `["transform", "StudentT d=10 n=4096"]` | 99.671 | ✅ | 0.177 | 17.619 | 320.1 | 0.0 | 1864.2 | 0.0 |

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
