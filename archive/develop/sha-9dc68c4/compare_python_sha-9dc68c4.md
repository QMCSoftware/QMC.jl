# Benchmark: Julia (local) vs QMCPy (Python)

| | Julia (local) | Python (QMCPy) |
|---|---|---|
| Julia label | `sha-9dc68c4` | — |
| Python label | — | `sha-9dc68c4` |
| Julia artifact mtime | `2026-06-30T14:26:24` | — |
| Python artifact mtime | — | `2026-06-30T14:31:50` |
| Julia generated at | `2026-06-30T14:19:26` | — |
| Python generated at | — | `2026-06-30T14:31:50` |
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
> Report generated at `2026-06-30T14:31:59`. Input artifact skew: `5 m 26 s`.

## Aggregate Summary

| metric | scope | ratio | Julia total | Python total | rows |
|:-------|:------|------:|------------:|-------------:|-----:|
| matched benchmarks | all matched rows | 111/111 | — | — | 111 |
| weighted time ratio | all matched rows | 5.721 | 175.235 ms | 1002.443 ms | 111 |
| weighted time ratio | excluding StudentT | 5.210 | 174.182 ms | 907.434 ms | 107 |
| weighted time ratio | StudentT only | 90.170 | 1.054 ms | 95.009 ms | 4 |
| weighted time ratio 95% bootstrap CI | all matched rows | `[5.637, 5.844]` | — | — | 1000 |
| weighted time ratio 95% bootstrap CI | excluding StudentT | `[5.128, 5.324]` | — | — | 1000 |
| weighted time ratio 95% bootstrap CI | StudentT only | `[87.097, 147.389]` | — | — | 1000 |
| weighted approximate tracemalloc ratio | all matched rows | 6.368 | 118918.9 KiB | 757322.0 KiB | 111 |
| weighted approximate RSS delta ratio | all matched rows | 2.063 | 28848.0 KiB | 59516.0 KiB | 111 |

> NOTE: RSS delta ratio compares retained process RSS after one warmed call; ratio < 1 means Python retained less RSS than Julia, and ratio > 1 means Python retained more. Treat it as an approximate retained-footprint signal, not a direct allocation metric.

## Grouped Timing Summary

Generator, transform, integrand evaluation, and end-to-end adaptive integration are summarized separately below. The `integrate` group is mixed end-to-end cost, not isolated stopping-criterion overhead.

| group | interpretation | weighted time ratio | 95% bootstrap CI | Julia total | Python total | rows |
|:------|:---------------|--------------------:|:------------------|------------:|-------------:|-----:|
| `evaluate` | integrand evaluation only | 3.231 | `[2.893, 3.253]` | 2.547 ms | 8.232 ms | 36 |
| `gen_samples` | generator only | 12.541 | `[12.320, 12.729]` | 28.871 ms | 362.081 ms | 40 |
| `integrate` | end-to-end adaptive integration; not isolated stopping-criterion overhead | 2.860 | `[2.770, 2.951]` | 82.666 ms | 236.433 ms | 11 |
| `transform` | transform only | 6.471 | `[6.419, 6.704]` | 61.150 ms | 395.697 ms | 24 |

## Detailed Results

| benchmark | time ratio | verdict | Julia (ms) | Python (ms) | Julia alloc (KiB) | Julia RSS Δ (KiB) | Python peak (KiB) | Python RSS Δ (KiB) |
|:----------|-----------:|:-------:|----------:|------------:|-------------------:|------------------:|------------------:|-------------------:|
| `["evaluate", "BoxIntegral d=10 n=1024"]` | 3.295 | ✅ | 0.009 | 0.029 | 16.1 | 0.0 | 89.0 | 0.0 |
| `["evaluate", "BoxIntegral d=10 n=16384"]` | 2.285 | ✅ | 0.207 | 0.474 | 256.1 | 0.0 | 1409.0 | 0.0 |
| `["evaluate", "BoxIntegral d=10 n=256"]` | 2.763 | ✅ | 0.004 | 0.010 | 4.1 | 0.0 | 23.0 | 0.0 |
| `["evaluate", "BoxIntegral d=10 n=4096"]` | 3.094 | ✅ | 0.034 | 0.105 | 64.1 | 0.0 | 353.0 | 0.0 |
| `["evaluate", "BoxIntegral d=200 n=1024"]` | 3.767 | ✅ | 0.053 | 0.199 | 16.1 | 0.0 | 1609.0 | 0.0 |
| `["evaluate", "BoxIntegral d=200 n=4096"]` | 2.665 | ✅ | 0.288 | 0.767 | 64.1 | 0.0 | 6433.0 | 0.0 |
| `["evaluate", "BoxIntegral d=50 n=1024"]` | 3.393 | ✅ | 0.014 | 0.048 | 16.1 | 0.0 | 409.0 | 0.0 |
| `["evaluate", "BoxIntegral d=50 n=4096"]` | 3.112 | ✅ | 0.084 | 0.263 | 64.1 | 0.0 | 1633.0 | 0.0 |
| `["evaluate", "Genz(continuous) d=10 n=1024"]` | 5.034 | ✅ | 0.008 | 0.040 | 16.1 | 0.0 | 160.2 | 0.0 |
| `["evaluate", "Genz(continuous) d=10 n=16384"]` | 4.222 | ✅ | 0.138 | 0.582 | 256.1 | 0.0 | 2560.2 | 0.0 |
| `["evaluate", "Genz(continuous) d=10 n=256"]` | 2.532 | ✅ | 0.006 | 0.015 | 4.1 | 0.0 | 40.2 | 0.0 |
| `["evaluate", "Genz(continuous) d=10 n=4096"]` | 4.113 | ✅ | 0.033 | 0.138 | 64.1 | 0.0 | 640.2 | 0.0 |
| `["evaluate", "Genz(gaussian_peak) d=10 n=1024"]` | 1.689 | ✅ | 0.023 | 0.038 | 16.1 | 0.0 | 169.2 | 0.0 |
| `["evaluate", "Genz(gaussian_peak) d=10 n=16384"]` | 4.532 | ✅ | 0.136 | 0.616 | 256.1 | 1744.0 | 2689.2 | 0.0 |
| `["evaluate", "Genz(gaussian_peak) d=10 n=256"]` | 2.580 | ✅ | 0.006 | 0.016 | 4.1 | 0.0 | 43.2 | 0.0 |
| `["evaluate", "Genz(gaussian_peak) d=10 n=4096"]` | 4.744 | ✅ | 0.029 | 0.140 | 64.1 | 0.0 | 673.2 | 0.0 |
| `["evaluate", "Genz(gaussian_peak) d=200 n=1024"]` | 6.683 | ✅ | 0.056 | 0.376 | 16.1 | 0.0 | 3209.2 | 0.0 |
| `["evaluate", "Genz(gaussian_peak) d=200 n=4096"]` | 5.087 | ✅ | 0.279 | 1.418 | 64.1 | 0.0 | 12833.2 | 0.0 |
| `["evaluate", "Genz(gaussian_peak) d=50 n=1024"]` | 6.270 | ✅ | 0.016 | 0.103 | 16.1 | 0.0 | 809.2 | 0.0 |
| `["evaluate", "Genz(gaussian_peak) d=50 n=4096"]` | 5.191 | ✅ | 0.083 | 0.430 | 64.1 | 0.0 | 3233.2 | 0.0 |
| `["evaluate", "Genz(oscillatory) n=1024"]` | 3.339 | ✅ | 0.011 | 0.036 | 16.1 | 3936.0 | 49.2 | 0.0 |
| `["evaluate", "Genz(oscillatory) n=16384"]` | 2.287 | ✅ | 0.256 | 0.585 | 256.1 | 0.0 | 513.0 | 0.0 |
| `["evaluate", "Genz(oscillatory) n=256"]` | 2.695 | ✅ | 0.004 | 0.012 | 4.1 | 0.0 | 13.2 | 0.0 |
| `["evaluate", "Genz(oscillatory) n=4096"]` | 2.926 | ✅ | 0.046 | 0.133 | 64.1 | 0.0 | 161.2 | 0.0 |
| `["evaluate", "Keister n=1024"]` | 1.984 | ✅ | 0.016 | 0.032 | 24.3 | 0.0 | 40.3 | 0.0 |
| `["evaluate", "Keister n=16384"]` | 2.444 | ✅ | 0.199 | 0.487 | 384.3 | 0.0 | 640.3 | 0.0 |
| `["evaluate", "Keister n=256"]` | 2.420 | ✅ | 0.005 | 0.012 | 6.3 | 0.0 | 10.3 | 0.0 |
| `["evaluate", "Keister n=4096"]` | 2.414 | ✅ | 0.047 | 0.114 | 96.3 | 0.0 | 160.3 | 0.0 |
| `["evaluate", "Linear0 d=10 n=1024"]` | 4.953 | ✅ | 0.005 | 0.023 | 8.1 | 0.0 | 8.9 | 0.0 |
| `["evaluate", "Linear0 d=10 n=16384"]` | 5.855 | ✅ | 0.060 | 0.352 | 128.1 | 0.0 | 128.9 | 0.0 |
| `["evaluate", "Linear0 d=10 n=256"]` | 4.349 | ✅ | 0.002 | 0.007 | 2.1 | 0.0 | 2.9 | 0.0 |
| `["evaluate", "Linear0 d=10 n=4096"]` | 8.689 | ✅ | 0.010 | 0.087 | 32.1 | 0.0 | 32.9 | 0.0 |
| `["evaluate", "Linear0 d=200 n=1024"]` | 1.691 | ✅ | 0.046 | 0.077 | 8.1 | 0.0 | 8.9 | 0.0 |
| `["evaluate", "Linear0 d=200 n=4096"]` | 1.156 | ✅ | 0.257 | 0.298 | 32.1 | 0.0 | 32.9 | 0.0 |
| `["evaluate", "Linear0 d=50 n=1024"]` | 2.137 | ✅ | 0.016 | 0.034 | 8.1 | 0.0 | 8.9 | 0.0 |
| `["evaluate", "Linear0 d=50 n=4096"]` | 2.235 | ✅ | 0.062 | 0.138 | 32.1 | 0.0 | 32.9 | 0.0 |
| `["gen_samples", "DigitalNetB2 d=10 n=1024"]` `[C]` | 1.044 | – | 0.099 | 0.103 | 166.1 | 0.0 | 108.4 | 0.0 |
| `["gen_samples", "DigitalNetB2 d=10 n=16384"]` `[C]` | 0.296 | ❌ | 1.451 | 0.429 | 2566.1 | 0.0 | 1308.4 | 0.0 |
| `["gen_samples", "DigitalNetB2 d=10 n=256"]` `[C]` | 5.096 | ✅ | 0.017 | 0.089 | 46.1 | 0.0 | 48.4 | 0.0 |
| `["gen_samples", "DigitalNetB2 d=10 n=4096"]` `[C]` | 0.916 | ❌ | 0.179 | 0.164 | 646.1 | 0.0 | 348.4 | 0.0 |
| `["gen_samples", "DigitalNetB2 d=3 n=1024"]` `[C]` | 4.194 | ✅ | 0.022 | 0.093 | 50.5 | 0.0 | 52.4 | 0.0 |
| `["gen_samples", "DigitalNetB2 d=3 n=16384"]` `[C]` | 0.852 | ❌ | 0.275 | 0.234 | 770.5 | 0.0 | 412.4 | 0.0 |
| `["gen_samples", "DigitalNetB2 d=3 n=256"]` `[C]` | 8.071 | ✅ | 0.011 | 0.087 | 14.5 | 5184.0 | 34.4 | 0.0 |
| `["gen_samples", "DigitalNetB2 d=3 n=4096"]` `[C]` | 1.797 | ✅ | 0.067 | 0.120 | 194.5 | 0.0 | 124.4 | 0.0 |
| `["gen_samples", "Halton d=10 n=1024"]` `[C]` | 13.395 | ✅ | 0.684 | 9.157 | 82.8 | 0.0 | 10191.6 | 0.0 |
| `["gen_samples", "Halton d=10 n=16384"]` `[C]` | 16.749 | ✅ | 11.791 | 197.490 | 1282.8 | 0.0 | 162591.6 | 0.0 |
| `["gen_samples", "Halton d=10 n=256"]` `[C]` | 12.605 | ✅ | 0.170 | 2.139 | 22.8 | 0.0 | 2571.6 | 0.0 |
| `["gen_samples", "Halton d=10 n=4096"]` `[C]` | 14.645 | ✅ | 2.786 | 40.798 | 322.8 | 0.0 | 40671.5 | 0.0 |
| `["gen_samples", "Halton d=3 n=1024"]` `[C]` | 19.964 | ✅ | 0.221 | 4.411 | 25.0 | 0.0 | 3079.4 | 0.0 |
| `["gen_samples", "Halton d=3 n=16384"]` `[C]` | 20.139 | ✅ | 3.811 | 76.744 | 385.0 | 592.0 | 48799.6 | 0.0 |
| `["gen_samples", "Halton d=3 n=256"]` `[C]` | 6.645 | ✅ | 0.134 | 0.893 | 7.0 | 0.0 | 793.4 | 0.0 |
| `["gen_samples", "Halton d=3 n=4096"]` `[C]` | 19.060 | ✅ | 0.928 | 17.696 | 97.0 | 0.0 | 12223.4 | 0.0 |
| `["gen_samples", "IIDStdUniform d=10 n=1024"]` | 2.692 | ✅ | 0.012 | 0.033 | 80.1 | 0.0 | 80.8 | 0.0 |
| `["gen_samples", "IIDStdUniform d=10 n=16384"]` | 0.983 | – | 0.500 | 0.492 | 1280.1 | 0.0 | 1280.8 | 0.0 |
| `["gen_samples", "IIDStdUniform d=10 n=256"]` | 3.298 | ✅ | 0.003 | 0.011 | 20.1 | 0.0 | 20.7 | 0.0 |
| `["gen_samples", "IIDStdUniform d=10 n=4096"]` | 2.742 | ✅ | 0.044 | 0.121 | 320.1 | 0.0 | 320.8 | 0.0 |
| `["gen_samples", "IIDStdUniform d=3 n=1024"]` | 3.420 | ✅ | 0.004 | 0.013 | 24.1 | 0.0 | 24.8 | 0.0 |
| `["gen_samples", "IIDStdUniform d=3 n=16384"]` | 2.914 | ✅ | 0.050 | 0.144 | 384.1 | 0.0 | 384.8 | 0.0 |
| `["gen_samples", "IIDStdUniform d=3 n=256"]` | 3.937 | ✅ | 0.002 | 0.006 | 6.1 | 0.0 | 6.7 | 0.0 |
| `["gen_samples", "IIDStdUniform d=3 n=4096"]` | 2.844 | ✅ | 0.014 | 0.039 | 96.1 | 0.0 | 96.8 | 0.0 |
| `["gen_samples", "Kronecker d=10 n=1024"]` | 3.980 | ✅ | 0.033 | 0.133 | 80.1 | 1680.0 | 233.6 | 0.0 |
| `["gen_samples", "Kronecker d=10 n=16384"]` | 2.230 | ✅ | 0.974 | 2.172 | 1280.1 | 0.0 | 2753.6 | 0.0 |
| `["gen_samples", "Kronecker d=10 n=256"]` | 4.887 | ✅ | 0.008 | 0.038 | 20.1 | 0.0 | 63.6 | 0.0 |
| `["gen_samples", "Kronecker d=10 n=4096"]` | 4.053 | ✅ | 0.126 | 0.510 | 320.1 | 0.0 | 737.6 | 0.0 |
| `["gen_samples", "Kronecker d=3 n=1024"]` | 5.333 | ✅ | 0.010 | 0.052 | 24.1 | 0.0 | 81.6 | 0.0 |
| `["gen_samples", "Kronecker d=3 n=16384"]` | 4.777 | ✅ | 0.152 | 0.725 | 384.1 | 0.0 | 961.6 | 0.0 |
| `["gen_samples", "Kronecker d=3 n=256"]` | 6.691 | ✅ | 0.003 | 0.018 | 6.1 | 0.0 | 21.6 | 0.0 |
| `["gen_samples", "Kronecker d=3 n=4096"]` | 4.552 | ✅ | 0.041 | 0.185 | 96.1 | 4992.0 | 289.6 | 0.0 |
| `["gen_samples", "Lattice d=10 n=1024"]` `[C]` | 2.666 | ✅ | 0.118 | 0.315 | 240.9 | 0.0 | 189.2 | 0.0 |
| `["gen_samples", "Lattice d=10 n=16384"]` `[C]` | 1.168 | ✅ | 2.943 | 3.436 | 3840.9 | 0.0 | 2589.3 | 0.0 |
| `["gen_samples", "Lattice d=10 n=256"]` `[C]` | 5.232 | ✅ | 0.030 | 0.157 | 60.9 | 0.0 | 69.3 | 0.0 |
| `["gen_samples", "Lattice d=10 n=4096"]` `[C]` | 2.149 | ✅ | 0.442 | 0.951 | 960.9 | 2912.0 | 669.3 | 0.0 |
| `["gen_samples", "Lattice d=3 n=1024"]` `[C]` | 4.696 | ✅ | 0.037 | 0.173 | 72.4 | 0.0 | 77.2 | 0.0 |
| `["gen_samples", "Lattice d=3 n=16384"]` `[C]` | 2.262 | ✅ | 0.533 | 1.207 | 1152.4 | 0.0 | 797.2 | 0.0 |
| `["gen_samples", "Lattice d=3 n=256"]` `[C]` | 11.445 | ✅ | 0.011 | 0.122 | 18.4 | 0.0 | 41.2 | 0.0 |
| `["gen_samples", "Lattice d=3 n=4096"]` `[C]` | 2.783 | ✅ | 0.136 | 0.378 | 288.4 | 0.0 | 221.2 | 0.0 |
| `["integrate", "CubMCCLT AsianOption"]` | 3.301 | ✅ | 3.748 | 12.370 | 3258.5 | 0.0 | 11001.7 | 0.0 |
| `["integrate", "CubMCCLT EuropeanOption"]` | 3.963 | ✅ | 7.706 | 30.540 | 8136.3 | 0.0 | 33415.8 | 0.0 |
| `["integrate", "CubMCCLT Keister"]` | 6.724 | ✅ | 16.088 | 108.174 | 39909.1 | 1280.0 | 123185.5 | 58792.0 |
| `["integrate", "CubQMCLatticeG EuropeanOption"]` `[C]` | 2.667 | ✅ | 2.229 | 5.946 | 2077.1 | 0.0 | 4582.9 | 0.0 |
| `["integrate", "CubQMCLatticeG Keister"]` `[C]` | 7.788 | ✅ | 0.342 | 2.665 | 570.7 | 0.0 | 401.3 | 704.0 |
| `["integrate", "CubQMCNetG AsianOption"]` | 3.555 | ✅ | 1.736 | 6.172 | 1703.4 | 0.0 | 4196.6 | 8.0 |
| `["integrate", "CubQMCNetG EuropeanOption"]` | 3.477 | ✅ | 1.718 | 5.974 | 1695.4 | 1728.0 | 4196.6 | 0.0 |
| `["integrate", "CubQMCNetG Keister"]` | 9.999 | ✅ | 0.299 | 2.993 | 440.2 | 0.0 | 514.7 | 12.0 |
| `["integrate", "CubQMCNetGRep AsianOption"]` | 1.290 | ✅ | 22.784 | 29.387 | 1650.6 | 0.0 | 16561.0 | 0.0 |
| `["integrate", "CubQMCNetGRep EuropeanOption"]` | 1.300 | ✅ | 22.656 | 29.447 | 1650.6 | 0.0 | 16560.9 | 0.0 |
| `["integrate", "CubQMCNetGRep Keister"]` | 0.824 | ❌ | 3.359 | 2.766 | 333.3 | 0.0 | 1104.4 | 0.0 |
| `["transform", "Gaussian d=10 n=1024"]` | 2.849 | ✅ | 0.148 | 0.422 | 80.1 | 0.0 | 716.5 | 0.0 |
| `["transform", "Gaussian d=10 n=16384"]` | 2.653 | ✅ | 2.464 | 6.536 | 1280.1 | 0.0 | 10466.5 | 0.0 |
| `["transform", "Gaussian d=10 n=256"]` | 5.054 | ✅ | 0.031 | 0.157 | 20.1 | 1888.0 | 184.1 | 0.0 |
| `["transform", "Gaussian d=10 n=4096"]` | 2.559 | ✅ | 0.627 | 1.605 | 320.1 | 0.0 | 2666.5 | 0.0 |
| `["transform", "Gaussian d=3 n=1024"]` | 4.451 | ✅ | 0.039 | 0.175 | 24.1 | 0.0 | 220.6 | 0.0 |
| `["transform", "Gaussian d=3 n=16384"]` | 2.534 | ✅ | 0.738 | 1.870 | 384.1 | 0.0 | 3186.5 | 0.0 |
| `["transform", "Gaussian d=3 n=256"]` | 8.580 | ✅ | 0.012 | 0.101 | 6.1 | 0.0 | 56.4 | 0.0 |
| `["transform", "Gaussian d=3 n=4096"]` | 2.678 | ✅ | 0.185 | 0.496 | 96.1 | 0.0 | 846.5 | 0.0 |
| `["transform", "Gaussian(dense) d=200 n=1024"]` | 4.860 | ✅ | 4.845 | 23.545 | 3200.2 | 0.0 | 13066.5 | 0.0 |
| `["transform", "Gaussian(dense) d=200 n=4096"]` | 5.621 | ✅ | 18.386 | 103.348 | 12800.2 | 0.0 | 52066.5 | 0.0 |
| `["transform", "Gaussian(dense) d=50 n=1024"]` | 2.128 | ✅ | 1.171 | 2.493 | 800.2 | 0.0 | 3316.5 | 0.0 |
| `["transform", "Gaussian(dense) d=50 n=4096"]` | 2.603 | ✅ | 4.116 | 10.715 | 3200.2 | 0.0 | 13066.5 | 0.0 |
| `["transform", "Gaussian(diag) d=200 n=1024"]` | 7.638 | ✅ | 3.098 | 23.661 | 1600.1 | 0.0 | 13066.5 | 0.0 |
| `["transform", "Gaussian(diag) d=200 n=4096"]` | 7.201 | ✅ | 14.488 | 104.324 | 6400.1 | 2912.0 | 52066.5 | 0.0 |
| `["transform", "Gaussian(diag) d=50 n=1024"]` | 3.249 | ✅ | 0.772 | 2.509 | 400.1 | 0.0 | 3316.5 | 0.0 |
| `["transform", "Gaussian(diag) d=50 n=4096"]` | 3.454 | ✅ | 3.091 | 10.678 | 1600.1 | 0.0 | 13066.5 | 0.0 |
| `["transform", "JohnsonsSU d=10 n=1024"]` | 1.586 | ✅ | 0.251 | 0.398 | 160.2 | 0.0 | 716.5 | 0.0 |
| `["transform", "JohnsonsSU d=10 n=16384"]` | 1.283 | ✅ | 4.559 | 5.847 | 2560.2 | 0.0 | 10466.5 | 0.0 |
| `["transform", "JohnsonsSU d=10 n=256"]` | 2.560 | ✅ | 0.059 | 0.151 | 40.2 | 0.0 | 184.1 | 0.0 |
| `["transform", "JohnsonsSU d=10 n=4096"]` | 1.630 | ✅ | 1.016 | 1.656 | 640.2 | 0.0 | 2666.5 | 0.0 |
| `["transform", "StudentT d=10 n=1024"]` | 173.031 | ✅ | 0.031 | 5.399 | 80.1 | 0.0 | 519.5 | 0.0 |
| `["transform", "StudentT d=10 n=16384"]` | 76.681 | ✅ | 0.893 | 68.498 | 1280.1 | 0.0 | 7432.3 | 0.0 |
| `["transform", "StudentT d=10 n=256"]` | 276.772 | ✅ | 0.008 | 2.217 | 20.1 | 0.0 | 139.5 | 0.0 |
| `["transform", "StudentT d=10 n=4096"]` | 155.945 | ✅ | 0.121 | 18.895 | 320.1 | 0.0 | 1864.2 | 0.0 |

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
