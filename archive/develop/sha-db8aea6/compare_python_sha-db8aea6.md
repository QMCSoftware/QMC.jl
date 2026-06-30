# Benchmark: Julia (local) vs QMCPy (Python)

| | Julia (local) | Python (QMCPy) |
|---|---|---|
| Julia label | `sha-db8aea6` | — |
| Python label | — | `sha-db8aea6` |
| Julia artifact mtime | `2026-06-30T10:11:38` | — |
| Python artifact mtime | — | `2026-06-30T10:17:10` |
| Julia generated at | `2026-06-30T10:04:10` | — |
| Python generated at | — | `2026-06-30T10:17:10` |
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
> Report generated at `2026-06-30T10:17:20`. Input artifact skew: `5 m 32 s`.

## Aggregate Summary

| metric | scope | ratio | Julia total | Python total | rows |
|:-------|:------|------:|------------:|-------------:|-----:|
| matched benchmarks | all matched rows | 111/111 | — | — | 111 |
| weighted time ratio | all matched rows | 4.742 | 182.361 ms | 864.680 ms | 111 |
| weighted time ratio | excluding StudentT | 4.274 | 180.948 ms | 773.294 ms | 107 |
| weighted time ratio | StudentT only | 64.663 | 1.413 ms | 91.386 ms | 4 |
| weighted time ratio 95% bootstrap CI | all matched rows | `[4.654, 4.821]` | — | — | 1000 |
| weighted time ratio 95% bootstrap CI | excluding StudentT | `[4.195, 4.344]` | — | — | 1000 |
| weighted time ratio 95% bootstrap CI | StudentT only | `[64.046, 65.204]` | — | — | 1000 |
| weighted approximate tracemalloc ratio | all matched rows | 6.244 | 121291.7 KiB | 757322.9 KiB | 111 |
| weighted approximate RSS delta ratio | all matched rows | 1.269 | 48064.0 KiB | 61012.0 KiB | 111 |

> NOTE: RSS delta ratio compares retained process RSS after one warmed call; ratio < 1 means Python retained less RSS than Julia, and ratio > 1 means Python retained more. Treat it as an approximate retained-footprint signal, not a direct allocation metric.

## Grouped Timing Summary

Generator, transform, integrand evaluation, and end-to-end adaptive integration are summarized separately below. The `integrate` group is mixed end-to-end cost, not isolated stopping-criterion overhead.

| group | interpretation | weighted time ratio | 95% bootstrap CI | Julia total | Python total | rows |
|:------|:---------------|--------------------:|:------------------|------------:|-------------:|-----:|
| `evaluate` | integrand evaluation only | 3.530 | `[3.212, 3.582]` | 2.092 ms | 7.386 ms | 36 |
| `gen_samples` | generator only | 9.713 | `[9.586, 9.985]` | 29.770 ms | 289.173 ms | 40 |
| `integrate` | end-to-end adaptive integration; not isolated stopping-criterion overhead | 2.484 | `[2.401, 2.563]` | 85.848 ms | 213.229 ms | 11 |
| `transform` | transform only | 5.489 | `[5.413, 5.603]` | 64.650 ms | 354.891 ms | 24 |

## Detailed Results

| benchmark | time ratio | verdict | Julia (ms) | Python (ms) | Julia alloc (KiB) | Julia RSS Δ (KiB) | Python peak (KiB) | Python RSS Δ (KiB) |
|:----------|-----------:|:-------:|----------:|------------:|-------------------:|------------------:|------------------:|-------------------:|
| `["evaluate", "BoxIntegral d=10 n=1024"]` | 3.936 | ✅ | 0.009 | 0.034 | 16.1 | 0.0 | 89.0 | 0.0 |
| `["evaluate", "BoxIntegral d=10 n=16384"]` | 2.338 | ✅ | 0.214 | 0.500 | 256.1 | 0.0 | 1409.0 | 0.0 |
| `["evaluate", "BoxIntegral d=10 n=256"]` | 4.206 | ✅ | 0.003 | 0.011 | 4.1 | 0.0 | 23.0 | 0.0 |
| `["evaluate", "BoxIntegral d=10 n=4096"]` | 3.756 | ✅ | 0.034 | 0.127 | 64.1 | 0.0 | 353.0 | 0.0 |
| `["evaluate", "BoxIntegral d=200 n=1024"]` | 3.543 | ✅ | 0.055 | 0.195 | 16.1 | 0.0 | 1609.0 | 0.0 |
| `["evaluate", "BoxIntegral d=200 n=4096"]` | 2.854 | ✅ | 0.174 | 0.495 | 64.1 | 0.0 | 6433.0 | 4.0 |
| `["evaluate", "BoxIntegral d=50 n=1024"]` | 3.734 | ✅ | 0.015 | 0.054 | 16.1 | 800.0 | 409.0 | 0.0 |
| `["evaluate", "BoxIntegral d=50 n=4096"]` | 2.893 | ✅ | 0.079 | 0.229 | 64.1 | 0.0 | 1633.0 | 0.0 |
| `["evaluate", "Genz(continuous) d=10 n=1024"]` | 5.307 | ✅ | 0.008 | 0.042 | 16.1 | 0.0 | 160.2 | 0.0 |
| `["evaluate", "Genz(continuous) d=10 n=16384"]` | 4.262 | ✅ | 0.138 | 0.589 | 256.1 | 0.0 | 2560.2 | 0.0 |
| `["evaluate", "Genz(continuous) d=10 n=256"]` | 5.811 | ✅ | 0.003 | 0.015 | 4.1 | 0.0 | 40.2 | 0.0 |
| `["evaluate", "Genz(continuous) d=10 n=4096"]` | 4.582 | ✅ | 0.033 | 0.151 | 64.1 | 0.0 | 640.2 | 0.0 |
| `["evaluate", "Genz(gaussian_peak) d=10 n=1024"]` | 5.533 | ✅ | 0.008 | 0.042 | 16.1 | 0.0 | 169.2 | 0.0 |
| `["evaluate", "Genz(gaussian_peak) d=10 n=16384"]` | 4.471 | ✅ | 0.132 | 0.591 | 256.1 | 5568.0 | 2689.2 | 0.0 |
| `["evaluate", "Genz(gaussian_peak) d=10 n=256"]` | 5.791 | ✅ | 0.003 | 0.015 | 4.1 | 0.0 | 43.2 | 0.0 |
| `["evaluate", "Genz(gaussian_peak) d=10 n=4096"]` | 4.790 | ✅ | 0.032 | 0.151 | 64.1 | 7312.0 | 673.2 | 0.0 |
| `["evaluate", "Genz(gaussian_peak) d=200 n=1024"]` | 5.458 | ✅ | 0.051 | 0.278 | 16.1 | 0.0 | 3209.2 | 0.0 |
| `["evaluate", "Genz(gaussian_peak) d=200 n=4096"]` | 4.555 | ✅ | 0.168 | 0.763 | 64.1 | 5744.0 | 12833.2 | 0.0 |
| `["evaluate", "Genz(gaussian_peak) d=50 n=1024"]` | 4.883 | ✅ | 0.016 | 0.076 | 16.1 | 0.0 | 809.2 | 0.0 |
| `["evaluate", "Genz(gaussian_peak) d=50 n=4096"]` | 5.332 | ✅ | 0.068 | 0.361 | 64.1 | 0.0 | 3233.2 | 0.0 |
| `["evaluate", "Genz(oscillatory) n=1024"]` | 5.223 | ✅ | 0.008 | 0.043 | 16.1 | 0.0 | 49.2 | 0.0 |
| `["evaluate", "Genz(oscillatory) n=16384"]` | 2.908 | ✅ | 0.237 | 0.688 | 256.1 | 0.0 | 513.0 | 0.0 |
| `["evaluate", "Genz(oscillatory) n=256"]` | 4.852 | ✅ | 0.003 | 0.014 | 4.1 | 896.0 | 13.2 | 0.0 |
| `["evaluate", "Genz(oscillatory) n=4096"]` | 5.268 | ✅ | 0.030 | 0.159 | 64.1 | 0.0 | 161.2 | 0.0 |
| `["evaluate", "Keister n=1024"]` | 2.294 | ✅ | 0.017 | 0.038 | 24.3 | 0.0 | 40.3 | 0.0 |
| `["evaluate", "Keister n=16384"]` | 2.797 | ✅ | 0.202 | 0.565 | 384.3 | 0.0 | 640.3 | 0.0 |
| `["evaluate", "Keister n=256"]` | 4.007 | ✅ | 0.003 | 0.014 | 6.3 | 0.0 | 10.3 | 0.0 |
| `["evaluate", "Keister n=4096"]` | 2.777 | ✅ | 0.049 | 0.136 | 96.3 | 960.0 | 160.3 | 0.0 |
| `["evaluate", "Linear0 d=10 n=1024"]` | 11.364 | ✅ | 0.002 | 0.026 | 8.1 | 0.0 | 8.9 | 0.0 |
| `["evaluate", "Linear0 d=10 n=16384"]` | 7.370 | ✅ | 0.054 | 0.399 | 128.1 | 0.0 | 128.9 | 0.0 |
| `["evaluate", "Linear0 d=10 n=256"]` | 9.613 | ✅ | 0.001 | 0.008 | 2.1 | 0.0 | 2.9 | 0.0 |
| `["evaluate", "Linear0 d=10 n=4096"]` | 10.256 | ✅ | 0.010 | 0.101 | 32.1 | 2160.0 | 32.9 | 0.0 |
| `["evaluate", "Linear0 d=200 n=1024"]` | 1.639 | ✅ | 0.039 | 0.063 | 8.1 | 0.0 | 8.9 | 0.0 |
| `["evaluate", "Linear0 d=200 n=4096"]` | 1.725 | ✅ | 0.143 | 0.247 | 32.1 | 0.0 | 32.9 | 0.0 |
| `["evaluate", "Linear0 d=50 n=1024"]` | 3.976 | ✅ | 0.009 | 0.034 | 8.1 | 0.0 | 8.9 | 0.0 |
| `["evaluate", "Linear0 d=50 n=4096"]` | 2.768 | ✅ | 0.047 | 0.131 | 32.1 | 0.0 | 32.9 | 0.0 |
| `["gen_samples", "DigitalNetB2 d=10 n=1024"]` `[C]` | 3.550 | ✅ | 0.036 | 0.127 | 166.1 | 0.0 | 108.4 | 0.0 |
| `["gen_samples", "DigitalNetB2 d=10 n=16384"]` `[C]` | 0.246 | ❌ | 1.530 | 0.376 | 2566.1 | 0.0 | 1308.4 | 0.0 |
| `["gen_samples", "DigitalNetB2 d=10 n=256"]` `[C]` | 8.004 | ✅ | 0.014 | 0.113 | 46.1 | 0.0 | 48.4 | 0.0 |
| `["gen_samples", "DigitalNetB2 d=10 n=4096"]` `[C]` | 0.957 | – | 0.186 | 0.178 | 646.1 | 0.0 | 348.4 | 0.0 |
| `["gen_samples", "DigitalNetB2 d=3 n=1024"]` `[C]` | 8.246 | ✅ | 0.014 | 0.118 | 50.5 | 0.0 | 52.4 | 0.0 |
| `["gen_samples", "DigitalNetB2 d=3 n=16384"]` `[C]` | 0.898 | ❌ | 0.300 | 0.269 | 770.5 | 0.0 | 412.4 | 0.0 |
| `["gen_samples", "DigitalNetB2 d=3 n=256"]` `[C]` | 18.574 | ✅ | 0.006 | 0.112 | 14.5 | 0.0 | 34.4 | 0.0 |
| `["gen_samples", "DigitalNetB2 d=3 n=4096"]` `[C]` | 2.546 | ✅ | 0.058 | 0.147 | 194.5 | 0.0 | 124.4 | 0.0 |
| `["gen_samples", "Halton d=10 n=1024"]` `[C]` | 10.310 | ✅ | 0.721 | 7.438 | 82.8 | 0.0 | 10191.6 | 0.0 |
| `["gen_samples", "Halton d=10 n=16384"]` `[C]` | 12.298 | ✅ | 12.517 | 153.930 | 1282.8 | 0.0 | 162591.6 | 0.0 |
| `["gen_samples", "Halton d=10 n=256"]` `[C]` | 10.168 | ✅ | 0.179 | 1.821 | 22.8 | 5200.0 | 2571.5 | 0.0 |
| `["gen_samples", "Halton d=10 n=4096"]` `[C]` | 11.302 | ✅ | 2.948 | 33.324 | 322.8 | 0.0 | 40671.6 | 0.0 |
| `["gen_samples", "Halton d=3 n=1024"]` `[C]` | 17.837 | ✅ | 0.234 | 4.168 | 25.0 | 0.0 | 3079.5 | 0.0 |
| `["gen_samples", "Halton d=3 n=16384"]` `[C]` | 14.959 | ✅ | 3.995 | 59.763 | 385.0 | 0.0 | 48799.6 | 0.0 |
| `["gen_samples", "Halton d=3 n=256"]` `[C]` | 14.506 | ✅ | 0.056 | 0.815 | 7.0 | 3808.0 | 793.6 | 0.0 |
| `["gen_samples", "Halton d=3 n=4096"]` `[C]` | 15.076 | ✅ | 0.968 | 14.590 | 97.0 | 0.0 | 12223.6 | 0.0 |
| `["gen_samples", "IIDStdUniform d=10 n=1024"]` | 5.747 | ✅ | 0.009 | 0.049 | 80.1 | 0.0 | 80.8 | 0.0 |
| `["gen_samples", "IIDStdUniform d=10 n=16384"]` | 0.951 | – | 0.604 | 0.574 | 1280.1 | 0.0 | 1280.8 | 0.0 |
| `["gen_samples", "IIDStdUniform d=10 n=256"]` | 5.961 | ✅ | 0.002 | 0.013 | 20.1 | 7536.0 | 20.7 | 0.0 |
| `["gen_samples", "IIDStdUniform d=10 n=4096"]` | 7.429 | ✅ | 0.025 | 0.185 | 320.1 | 0.0 | 320.8 | 0.0 |
| `["gen_samples", "IIDStdUniform d=3 n=1024"]` | 6.153 | ✅ | 0.002 | 0.015 | 24.1 | 0.0 | 24.8 | 0.0 |
| `["gen_samples", "IIDStdUniform d=3 n=16384"]` | 7.401 | ✅ | 0.030 | 0.221 | 384.1 | 0.0 | 384.8 | 0.0 |
| `["gen_samples", "IIDStdUniform d=3 n=256"]` | 6.635 | ✅ | 0.001 | 0.007 | 6.1 | 0.0 | 6.7 | 0.0 |
| `["gen_samples", "IIDStdUniform d=3 n=4096"]` | 4.604 | ✅ | 0.012 | 0.053 | 96.1 | 0.0 | 96.8 | 0.0 |
| `["gen_samples", "Kronecker d=10 n=1024"]` | 6.949 | ✅ | 0.025 | 0.171 | 80.1 | 0.0 | 233.6 | 0.0 |
| `["gen_samples", "Kronecker d=10 n=16384"]` | 3.303 | ✅ | 0.853 | 2.818 | 1280.1 | 0.0 | 2753.6 | 0.0 |
| `["gen_samples", "Kronecker d=10 n=256"]` | 8.032 | ✅ | 0.006 | 0.047 | 20.1 | 0.0 | 63.6 | 0.0 |
| `["gen_samples", "Kronecker d=10 n=4096"]` | 7.712 | ✅ | 0.089 | 0.689 | 320.1 | 0.0 | 737.6 | 0.0 |
| `["gen_samples", "Kronecker d=3 n=1024"]` | 9.743 | ✅ | 0.007 | 0.068 | 24.1 | 0.0 | 81.6 | 0.0 |
| `["gen_samples", "Kronecker d=3 n=16384"]` | 9.714 | ✅ | 0.107 | 1.043 | 384.1 | 0.0 | 961.6 | 0.0 |
| `["gen_samples", "Kronecker d=3 n=256"]` | 11.313 | ✅ | 0.002 | 0.022 | 6.1 | 0.0 | 21.6 | 0.0 |
| `["gen_samples", "Kronecker d=3 n=4096"]` | 8.885 | ✅ | 0.029 | 0.258 | 96.1 | 0.0 | 289.6 | 0.0 |
| `["gen_samples", "Lattice d=10 n=1024"]` `[C]` | 4.700 | ✅ | 0.066 | 0.310 | 240.9 | 0.0 | 189.3 | 0.0 |
| `["gen_samples", "Lattice d=10 n=16384"]` `[C]` | 1.080 | ✅ | 2.571 | 2.776 | 3840.9 | 208.0 | 2589.3 | 0.0 |
| `["gen_samples", "Lattice d=10 n=256"]` `[C]` | 10.910 | ✅ | 0.017 | 0.182 | 60.9 | 0.0 | 69.3 | 0.0 |
| `["gen_samples", "Lattice d=10 n=4096"]` `[C]` | 1.351 | ✅ | 0.597 | 0.806 | 960.9 | 0.0 | 669.3 | 0.0 |
| `["gen_samples", "Lattice d=3 n=1024"]` `[C]` | 7.282 | ✅ | 0.026 | 0.190 | 72.4 | 0.0 | 77.2 | 0.0 |
| `["gen_samples", "Lattice d=3 n=16384"]` `[C]` | 1.097 | ✅ | 0.819 | 0.899 | 1152.4 | 1424.0 | 797.3 | 0.0 |
| `["gen_samples", "Lattice d=3 n=256"]` `[C]` | 21.206 | ✅ | 0.007 | 0.155 | 18.4 | 0.0 | 41.3 | 4.0 |
| `["gen_samples", "Lattice d=3 n=4096"]` `[C]` | 3.279 | ✅ | 0.102 | 0.333 | 288.4 | 0.0 | 221.2 | 0.0 |
| `["integrate", "CubMCCLT AsianOption"]` | 3.022 | ✅ | 3.806 | 11.505 | 3258.5 | 0.0 | 11001.7 | 0.0 |
| `["integrate", "CubMCCLT EuropeanOption"]` | 3.416 | ✅ | 8.121 | 27.741 | 8136.3 | 2704.0 | 33415.8 | 0.0 |
| `["integrate", "CubMCCLT Keister"]` | 6.767 | ✅ | 13.992 | 94.678 | 39909.1 | 0.0 | 123185.4 | 58808.0 |
| `["integrate", "CubQMCLatticeG EuropeanOption"]` `[C]` | 2.130 | ✅ | 2.433 | 5.183 | 2077.1 | 0.0 | 4583.1 | 0.0 |
| `["integrate", "CubQMCLatticeG Keister"]` `[C]` | 8.030 | ✅ | 0.365 | 2.935 | 570.7 | 0.0 | 401.4 | 704.0 |
| `["integrate", "CubQMCNetG AsianOption"]` | 3.822 | ✅ | 1.449 | 5.538 | 1703.4 | 2528.0 | 4196.6 | 8.0 |
| `["integrate", "CubQMCNetG EuropeanOption"]` | 3.903 | ✅ | 1.416 | 5.526 | 1695.4 | 0.0 | 4196.6 | 0.0 |
| `["integrate", "CubQMCNetG Keister"]` | 11.255 | ✅ | 0.289 | 3.256 | 440.2 | 0.0 | 514.8 | 12.0 |
| `["integrate", "CubQMCNetGRep AsianOption"]` | 0.920 | ❌ | 29.587 | 27.205 | 2299.2 | 0.0 | 16560.8 | 1472.0 |
| `["integrate", "CubQMCNetGRep EuropeanOption"]` | 1.273 | ✅ | 21.142 | 26.918 | 2170.1 | 592.0 | 16560.9 | 0.0 |
| `["integrate", "CubQMCNetGRep Keister"]` | 0.845 | ❌ | 3.246 | 2.745 | 1538.0 | 0.0 | 1104.2 | 0.0 |
| `["transform", "Gaussian d=10 n=1024"]` | 3.203 | ✅ | 0.138 | 0.443 | 80.1 | 0.0 | 716.5 | 0.0 |
| `["transform", "Gaussian d=10 n=16384"]` | 2.186 | ✅ | 2.620 | 5.728 | 1280.1 | 0.0 | 10466.5 | 0.0 |
| `["transform", "Gaussian d=10 n=256"]` | 5.921 | ✅ | 0.030 | 0.180 | 20.1 | 624.0 | 184.1 | 0.0 |
| `["transform", "Gaussian d=10 n=4096"]` | 2.387 | ✅ | 0.645 | 1.540 | 320.1 | 0.0 | 2666.5 | 0.0 |
| `["transform", "Gaussian d=3 n=1024"]` | 4.813 | ✅ | 0.042 | 0.200 | 24.1 | 0.0 | 220.6 | 0.0 |
| `["transform", "Gaussian d=3 n=16384"]` | 2.355 | ✅ | 0.780 | 1.837 | 384.1 | 0.0 | 3186.5 | 0.0 |
| `["transform", "Gaussian d=3 n=256"]` | 12.737 | ✅ | 0.009 | 0.121 | 6.1 | 0.0 | 56.4 | 0.0 |
| `["transform", "Gaussian d=3 n=4096"]` | 3.030 | ✅ | 0.171 | 0.519 | 96.1 | 0.0 | 846.5 | 0.0 |
| `["transform", "Gaussian(dense) d=200 n=1024"]` | 3.566 | ✅ | 5.705 | 20.344 | 3200.2 | 0.0 | 13066.5 | 0.0 |
| `["transform", "Gaussian(dense) d=200 n=4096"]` | 4.768 | ✅ | 18.868 | 89.971 | 12800.2 | 0.0 | 52066.5 | 0.0 |
| `["transform", "Gaussian(dense) d=50 n=1024"]` | 2.203 | ✅ | 1.043 | 2.298 | 800.2 | 0.0 | 3316.5 | 0.0 |
| `["transform", "Gaussian(dense) d=50 n=4096"]` | 1.853 | ✅ | 4.794 | 8.882 | 3200.2 | 0.0 | 13066.5 | 0.0 |
| `["transform", "Gaussian(diag) d=200 n=1024"]` | 4.860 | ✅ | 3.983 | 19.357 | 1600.1 | 0.0 | 13066.5 | 0.0 |
| `["transform", "Gaussian(diag) d=200 n=4096"]` | 6.305 | ✅ | 14.149 | 89.215 | 6400.1 | 0.0 | 52066.5 | 0.0 |
| `["transform", "Gaussian(diag) d=50 n=1024"]` | 2.842 | ✅ | 0.813 | 2.310 | 400.1 | 0.0 | 3316.5 | 0.0 |
| `["transform", "Gaussian(diag) d=50 n=4096"]` | 2.710 | ✅ | 3.277 | 8.882 | 1600.1 | 0.0 | 13066.5 | 0.0 |
| `["transform", "JohnsonsSU d=10 n=1024"]` | 2.833 | ✅ | 0.219 | 0.619 | 160.2 | 0.0 | 716.5 | 0.0 |
| `["transform", "JohnsonsSU d=10 n=16384"]` | 1.752 | ✅ | 4.933 | 8.642 | 2560.2 | 0.0 | 10466.5 | 0.0 |
| `["transform", "JohnsonsSU d=10 n=256"]` | 3.965 | ✅ | 0.052 | 0.207 | 40.2 | 0.0 | 184.1 | 0.0 |
| `["transform", "JohnsonsSU d=10 n=4096"]` | 2.290 | ✅ | 0.965 | 2.209 | 640.2 | 0.0 | 2666.5 | 0.0 |
| `["transform", "StudentT d=10 n=1024"]` | 126.808 | ✅ | 0.045 | 5.681 | 80.1 | 0.0 | 519.8 | 0.0 |
| `["transform", "StudentT d=10 n=16384"]` | 55.590 | ✅ | 1.178 | 65.508 | 1280.1 | 0.0 | 7432.3 | 0.0 |
| `["transform", "StudentT d=10 n=256"]` | 221.550 | ✅ | 0.012 | 2.583 | 20.1 | 0.0 | 139.4 | 0.0 |
| `["transform", "StudentT d=10 n=4096"]` | 98.731 | ✅ | 0.178 | 17.614 | 320.1 | 0.0 | 1864.2 | 0.0 |

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
