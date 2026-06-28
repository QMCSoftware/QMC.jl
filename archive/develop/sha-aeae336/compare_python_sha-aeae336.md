# Benchmark: Julia (local) vs QMCPy (Python)

| | Julia (local) | Python (QMCPy) |
|---|---|---|
| Julia label | `sha-aeae336` | — |
| Python label | — | `sha-aeae336` |
| Julia artifact mtime | `2026-06-28T08:36:35` | — |
| Python artifact mtime | — | `2026-06-28T08:42:05` |
| Julia generated at | `2026-06-28T08:30:23` | — |
| Python generated at | — | `2026-06-28T08:42:05` |
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
> Report generated at `2026-06-28T08:42:10`. Input artifact skew: `5 m 30 s`.

## Aggregate Summary

| metric | scope | ratio | Julia total | Python total | rows |
|:-------|:------|------:|------------:|-------------:|-----:|
| matched benchmarks | all matched rows | 111/111 | — | — | 111 |
| weighted time ratio | all matched rows | 4.369 | 197.190 ms | 861.529 ms | 111 |
| weighted time ratio | excluding StudentT | 3.912 | 196.256 ms | 767.757 ms | 107 |
| weighted time ratio | StudentT only | 100.431 | 0.934 ms | 93.772 ms | 4 |
| weighted time ratio 95% bootstrap CI | all matched rows | `[4.305, 4.428]` | — | — | 1000 |
| weighted time ratio 95% bootstrap CI | excluding StudentT | `[3.854, 3.963]` | — | — | 1000 |
| weighted time ratio 95% bootstrap CI | StudentT only | `[100.117, 100.858]` | — | — | 1000 |
| weighted approximate tracemalloc ratio | all matched rows | 4.377 | 173037.5 KiB | 757322.5 KiB | 111 |
| weighted approximate RSS delta ratio | all matched rows | n/a | 0.0 KiB | 59888.0 KiB | 111 |


## Grouped Timing Summary

Generator, transform, integrand evaluation, and end-to-end adaptive integration are summarized separately below. The `integrate` group is mixed end-to-end cost, not isolated stopping-criterion overhead.

| group | interpretation | weighted time ratio | 95% bootstrap CI | Julia total | Python total | rows |
|:------|:---------------|--------------------:|:------------------|------------:|-------------:|-----:|
| `evaluate` | integrand evaluation only | 3.684 | `[3.393, 3.696]` | 1.908 ms | 7.029 ms | 36 |
| `gen_samples` | generator only | 4.523 | `[4.487, 4.583]` | 63.738 ms | 288.294 ms | 40 |
| `integrate` | end-to-end adaptive integration; not isolated stopping-criterion overhead | 2.837 | `[2.734, 2.932]` | 74.461 ms | 211.271 ms | 11 |
| `transform` | transform only | 6.218 | `[6.160, 6.247]` | 57.083 ms | 354.935 ms | 24 |

## Detailed Results

| benchmark | time ratio | verdict | Julia (ms) | Python (ms) | Julia alloc (KiB) | Julia RSS Δ (KiB) | Python peak (KiB) | Python RSS Δ (KiB) |
|:----------|-----------:|:-------:|----------:|------------:|-------------------:|------------------:|------------------:|-------------------:|
| `["evaluate", "BoxIntegral d=10 n=1024"]` | 4.064 | ✅ | 0.008 | 0.034 | 16.1 | 0.0 | 89.0 | 0.0 |
| `["evaluate", "BoxIntegral d=10 n=16384"]` | 3.696 | ✅ | 0.134 | 0.494 | 256.1 | 0.0 | 1409.0 | 0.0 |
| `["evaluate", "BoxIntegral d=10 n=256"]` | 4.337 | ✅ | 0.003 | 0.011 | 4.1 | 0.0 | 23.0 | 0.0 |
| `["evaluate", "BoxIntegral d=10 n=4096"]` | 3.915 | ✅ | 0.032 | 0.127 | 64.1 | 0.0 | 353.0 | 0.0 |
| `["evaluate", "BoxIntegral d=200 n=1024"]` | 2.844 | ✅ | 0.044 | 0.125 | 16.1 | 0.0 | 1609.0 | 0.0 |
| `["evaluate", "BoxIntegral d=200 n=4096"]` | 2.977 | ✅ | 0.163 | 0.486 | 64.1 | 0.0 | 6433.0 | 0.0 |
| `["evaluate", "BoxIntegral d=50 n=1024"]` | 3.774 | ✅ | 0.014 | 0.054 | 16.1 | 0.0 | 409.0 | 0.0 |
| `["evaluate", "BoxIntegral d=50 n=4096"]` | 3.006 | ✅ | 0.067 | 0.201 | 64.1 | 0.0 | 1633.0 | 0.0 |
| `["evaluate", "Genz(continuous) d=10 n=1024"]` | 5.570 | ✅ | 0.007 | 0.042 | 16.1 | 0.0 | 160.2 | 0.0 |
| `["evaluate", "Genz(continuous) d=10 n=16384"]` | 4.807 | ✅ | 0.121 | 0.582 | 256.1 | 0.0 | 2560.2 | 0.0 |
| `["evaluate", "Genz(continuous) d=10 n=256"]` | 5.795 | ✅ | 0.003 | 0.015 | 4.1 | 0.0 | 40.2 | 0.0 |
| `["evaluate", "Genz(continuous) d=10 n=4096"]` | 4.877 | ✅ | 0.031 | 0.151 | 64.1 | 0.0 | 640.2 | 0.0 |
| `["evaluate", "Genz(gaussian_peak) d=10 n=1024"]` | 5.491 | ✅ | 0.008 | 0.042 | 16.1 | 0.0 | 169.2 | 0.0 |
| `["evaluate", "Genz(gaussian_peak) d=10 n=16384"]` | 4.707 | ✅ | 0.124 | 0.583 | 256.1 | 0.0 | 2689.2 | 0.0 |
| `["evaluate", "Genz(gaussian_peak) d=10 n=256"]` | 5.728 | ✅ | 0.003 | 0.015 | 4.1 | 0.0 | 43.2 | 0.0 |
| `["evaluate", "Genz(gaussian_peak) d=10 n=4096"]` | 4.736 | ✅ | 0.032 | 0.151 | 64.1 | 0.0 | 673.2 | 0.0 |
| `["evaluate", "Genz(gaussian_peak) d=200 n=1024"]` | 3.786 | ✅ | 0.050 | 0.189 | 16.1 | 0.0 | 3209.2 | 0.0 |
| `["evaluate", "Genz(gaussian_peak) d=200 n=4096"]` | 4.444 | ✅ | 0.163 | 0.722 | 64.1 | 0.0 | 12833.2 | 0.0 |
| `["evaluate", "Genz(gaussian_peak) d=50 n=1024"]` | 3.685 | ✅ | 0.020 | 0.075 | 16.1 | 0.0 | 809.2 | 0.0 |
| `["evaluate", "Genz(gaussian_peak) d=50 n=4096"]` | 4.064 | ✅ | 0.067 | 0.271 | 64.1 | 0.0 | 3233.2 | 0.0 |
| `["evaluate", "Genz(oscillatory) n=1024"]` | 5.577 | ✅ | 0.008 | 0.043 | 16.1 | 0.0 | 49.2 | 0.0 |
| `["evaluate", "Genz(oscillatory) n=16384"]` | 2.948 | ✅ | 0.233 | 0.686 | 256.1 | 0.0 | 513.0 | 0.0 |
| `["evaluate", "Genz(oscillatory) n=256"]` | 5.236 | ✅ | 0.003 | 0.014 | 4.1 | 0.0 | 13.2 | 0.0 |
| `["evaluate", "Genz(oscillatory) n=4096"]` | 5.223 | ✅ | 0.030 | 0.159 | 64.1 | 0.0 | 161.2 | 0.0 |
| `["evaluate", "Keister n=1024"]` | 3.620 | ✅ | 0.011 | 0.039 | 24.3 | 0.0 | 40.3 | 0.0 |
| `["evaluate", "Keister n=16384"]` | 2.833 | ✅ | 0.199 | 0.563 | 384.3 | 0.0 | 640.3 | 0.0 |
| `["evaluate", "Keister n=256"]` | 4.108 | ✅ | 0.003 | 0.014 | 6.3 | 0.0 | 10.3 | 0.0 |
| `["evaluate", "Keister n=4096"]` | 3.143 | ✅ | 0.043 | 0.136 | 96.3 | 0.0 | 160.3 | 0.0 |
| `["evaluate", "Linear0 d=10 n=1024"]` | 11.742 | ✅ | 0.002 | 0.026 | 8.1 | 0.0 | 8.9 | 0.0 |
| `["evaluate", "Linear0 d=10 n=16384"]` | 8.250 | ✅ | 0.048 | 0.398 | 128.1 | 0.0 | 128.9 | 0.0 |
| `["evaluate", "Linear0 d=10 n=256"]` | 8.643 | ✅ | 0.001 | 0.008 | 2.1 | 0.0 | 2.9 | 0.0 |
| `["evaluate", "Linear0 d=10 n=4096"]` | 10.985 | ✅ | 0.009 | 0.101 | 32.1 | 0.0 | 32.9 | 0.0 |
| `["evaluate", "Linear0 d=200 n=1024"]` | 1.674 | ✅ | 0.038 | 0.064 | 8.1 | 0.0 | 8.9 | 0.0 |
| `["evaluate", "Linear0 d=200 n=4096"]` | 1.735 | ✅ | 0.141 | 0.245 | 32.1 | 0.0 | 32.9 | 0.0 |
| `["evaluate", "Linear0 d=50 n=1024"]` | 4.179 | ✅ | 0.008 | 0.034 | 8.1 | 0.0 | 8.9 | 0.0 |
| `["evaluate", "Linear0 d=50 n=4096"]` | 3.465 | ✅ | 0.038 | 0.131 | 32.1 | 0.0 | 32.9 | 0.0 |
| `["gen_samples", "DigitalNetB2 d=10 n=1024"]` `[C]` | 3.345 | ✅ | 0.038 | 0.127 | 168.9 | 0.0 | 108.4 | 0.0 |
| `["gen_samples", "DigitalNetB2 d=10 n=16384"]` `[C]` | 0.252 | ❌ | 1.464 | 0.370 | 2568.9 | 0.0 | 1308.4 | 0.0 |
| `["gen_samples", "DigitalNetB2 d=10 n=256"]` `[C]` | 6.725 | ✅ | 0.017 | 0.113 | 48.9 | 0.0 | 48.4 | 0.0 |
| `["gen_samples", "DigitalNetB2 d=10 n=4096"]` `[C]` | 1.501 | ✅ | 0.117 | 0.176 | 648.9 | 0.0 | 348.4 | 0.0 |
| `["gen_samples", "DigitalNetB2 d=3 n=1024"]` `[C]` | 8.383 | ✅ | 0.014 | 0.118 | 51.1 | 0.0 | 52.4 | 0.0 |
| `["gen_samples", "DigitalNetB2 d=3 n=16384"]` `[C]` | 1.334 | ✅ | 0.194 | 0.259 | 771.1 | 0.0 | 412.4 | 0.0 |
| `["gen_samples", "DigitalNetB2 d=3 n=256"]` `[C]` | 14.740 | ✅ | 0.008 | 0.111 | 15.1 | 0.0 | 34.4 | 0.0 |
| `["gen_samples", "DigitalNetB2 d=3 n=4096"]` `[C]` | 2.729 | ✅ | 0.054 | 0.147 | 195.1 | 0.0 | 124.4 | 0.0 |
| `["gen_samples", "Halton d=10 n=1024"]` `[C]` | 4.059 | ✅ | 1.829 | 7.425 | 82.8 | 0.0 | 10191.6 | 0.0 |
| `["gen_samples", "Halton d=10 n=16384"]` `[C]` | 5.121 | ✅ | 29.929 | 153.256 | 1282.8 | 0.0 | 162591.6 | 0.0 |
| `["gen_samples", "Halton d=10 n=256"]` `[C]` | 4.040 | ✅ | 0.455 | 1.837 | 22.8 | 0.0 | 2571.4 | 0.0 |
| `["gen_samples", "Halton d=10 n=4096"]` `[C]` | 4.516 | ✅ | 7.326 | 33.084 | 322.8 | 0.0 | 40671.4 | 0.0 |
| `["gen_samples", "Halton d=3 n=1024"]` `[C]` | 7.561 | ✅ | 0.558 | 4.216 | 25.0 | 0.0 | 3079.4 | 0.0 |
| `["gen_samples", "Halton d=3 n=16384"]` `[C]` | 6.577 | ✅ | 9.073 | 59.674 | 385.0 | 0.0 | 48799.6 | 0.0 |
| `["gen_samples", "Halton d=3 n=256"]` `[C]` | 5.626 | ✅ | 0.145 | 0.813 | 7.0 | 0.0 | 793.6 | 0.0 |
| `["gen_samples", "Halton d=3 n=4096"]` `[C]` | 6.486 | ✅ | 2.245 | 14.559 | 97.0 | 0.0 | 12223.6 | 0.0 |
| `["gen_samples", "IIDStdUniform d=10 n=1024"]` | 5.901 | ✅ | 0.008 | 0.049 | 80.1 | 0.0 | 80.8 | 0.0 |
| `["gen_samples", "IIDStdUniform d=10 n=16384"]` | 1.138 | ✅ | 0.616 | 0.702 | 1280.1 | 0.0 | 1280.8 | 0.0 |
| `["gen_samples", "IIDStdUniform d=10 n=256"]` | 7.477 | ✅ | 0.002 | 0.015 | 20.1 | 0.0 | 20.7 | 0.0 |
| `["gen_samples", "IIDStdUniform d=10 n=4096"]` | 6.143 | ✅ | 0.030 | 0.185 | 320.1 | 0.0 | 320.8 | 0.0 |
| `["gen_samples", "IIDStdUniform d=3 n=1024"]` | 8.522 | ✅ | 0.002 | 0.020 | 24.1 | 0.0 | 24.8 | 0.0 |
| `["gen_samples", "IIDStdUniform d=3 n=16384"]` | 6.340 | ✅ | 0.035 | 0.222 | 384.1 | 0.0 | 384.8 | 0.0 |
| `["gen_samples", "IIDStdUniform d=3 n=256"]` | 6.796 | ✅ | 0.001 | 0.007 | 6.1 | 0.0 | 6.7 | 0.0 |
| `["gen_samples", "IIDStdUniform d=3 n=4096"]` | 5.493 | ✅ | 0.011 | 0.058 | 96.1 | 0.0 | 96.8 | 0.0 |
| `["gen_samples", "Kronecker d=10 n=1024"]` | 2.389 | ✅ | 0.072 | 0.172 | 80.1 | 0.0 | 233.6 | 0.0 |
| `["gen_samples", "Kronecker d=10 n=16384"]` | 1.519 | ✅ | 1.853 | 2.814 | 1280.1 | 0.0 | 2753.6 | 0.0 |
| `["gen_samples", "Kronecker d=10 n=256"]` | 2.664 | ✅ | 0.018 | 0.047 | 20.1 | 0.0 | 63.6 | 0.0 |
| `["gen_samples", "Kronecker d=10 n=4096"]` | 2.133 | ✅ | 0.324 | 0.690 | 320.1 | 0.0 | 737.6 | 0.0 |
| `["gen_samples", "Kronecker d=3 n=1024"]` | 3.237 | ✅ | 0.021 | 0.068 | 24.1 | 0.0 | 81.6 | 0.0 |
| `["gen_samples", "Kronecker d=3 n=16384"]` | 2.557 | ✅ | 0.407 | 1.041 | 384.1 | 0.0 | 961.6 | 0.0 |
| `["gen_samples", "Kronecker d=3 n=256"]` | 3.948 | ✅ | 0.006 | 0.022 | 6.1 | 0.0 | 21.6 | 0.0 |
| `["gen_samples", "Kronecker d=3 n=4096"]` | 2.760 | ✅ | 0.094 | 0.259 | 96.1 | 0.0 | 289.6 | 0.0 |
| `["gen_samples", "Lattice d=10 n=1024"]` `[C]` | 1.744 | ✅ | 0.178 | 0.311 | 240.9 | 0.0 | 189.2 | 0.0 |
| `["gen_samples", "Lattice d=10 n=16384"]` `[C]` | 0.648 | ❌ | 4.263 | 2.763 | 3840.9 | 0.0 | 2589.2 | 0.0 |
| `["gen_samples", "Lattice d=10 n=256"]` `[C]` | 4.153 | ✅ | 0.044 | 0.184 | 60.9 | 0.0 | 69.3 | 0.0 |
| `["gen_samples", "Lattice d=10 n=4096"]` `[C]` | 0.926 | ❌ | 0.869 | 0.805 | 960.9 | 0.0 | 669.3 | 0.0 |
| `["gen_samples", "Lattice d=3 n=1024"]` `[C]` | 3.749 | ✅ | 0.051 | 0.190 | 72.4 | 0.0 | 77.3 | 0.0 |
| `["gen_samples", "Lattice d=3 n=16384"]` `[C]` | 0.779 | ❌ | 1.153 | 0.898 | 1152.4 | 0.0 | 797.3 | 0.0 |
| `["gen_samples", "Lattice d=3 n=256"]` `[C]` | 11.572 | ✅ | 0.013 | 0.155 | 18.4 | 0.0 | 41.2 | 0.0 |
| `["gen_samples", "Lattice d=3 n=4096"]` `[C]` | 1.659 | ✅ | 0.201 | 0.334 | 288.4 | 0.0 | 221.2 | 0.0 |
| `["integrate", "CubMCCLT AsianOption"]` | 3.014 | ✅ | 3.756 | 11.320 | 3258.5 | 0.0 | 11001.7 | 0.0 |
| `["integrate", "CubMCCLT EuropeanOption"]` | 3.708 | ✅ | 7.458 | 27.650 | 8136.3 | 0.0 | 33415.8 | 0.0 |
| `["integrate", "CubMCCLT Keister"]` | 6.859 | ✅ | 13.625 | 93.448 | 39909.1 | 0.0 | 123185.4 | 58784.0 |
| `["integrate", "CubQMCLatticeG EuropeanOption"]` `[C]` | 2.337 | ✅ | 2.222 | 5.193 | 2077.1 | 0.0 | 4583.1 | 0.0 |
| `["integrate", "CubQMCLatticeG Keister"]` `[C]` | 6.817 | ✅ | 0.433 | 2.950 | 570.7 | 0.0 | 400.9 | 704.0 |
| `["integrate", "CubQMCNetG AsianOption"]` | 4.296 | ✅ | 1.289 | 5.537 | 1718.7 | 0.0 | 4196.5 | 8.0 |
| `["integrate", "CubQMCNetG EuropeanOption"]` | 4.257 | ✅ | 1.299 | 5.529 | 1710.7 | 0.0 | 4196.5 | 0.0 |
| `["integrate", "CubQMCNetG Keister"]` | 11.612 | ✅ | 0.283 | 3.284 | 441.5 | 0.0 | 514.8 | 12.0 |
| `["integrate", "CubQMCNetGRep AsianOption"]` | 1.287 | ✅ | 20.988 | 27.013 | 26550.4 | 0.0 | 16561.0 | 0.0 |
| `["integrate", "CubQMCNetGRep EuropeanOption"]` | 1.349 | ✅ | 19.715 | 26.595 | 26421.3 | 0.0 | 16561.0 | 0.0 |
| `["integrate", "CubQMCNetGRep Keister"]` | 0.811 | ❌ | 3.394 | 2.752 | 4735.8 | 0.0 | 1104.4 | 0.0 |
| `["transform", "Gaussian d=10 n=1024"]` | 3.164 | ✅ | 0.141 | 0.446 | 80.1 | 0.0 | 716.5 | 0.0 |
| `["transform", "Gaussian d=10 n=16384"]` | 2.253 | ✅ | 2.625 | 5.915 | 1280.1 | 0.0 | 10466.5 | 0.0 |
| `["transform", "Gaussian d=10 n=256"]` | 5.959 | ✅ | 0.030 | 0.181 | 20.1 | 0.0 | 184.1 | 0.0 |
| `["transform", "Gaussian d=10 n=4096"]` | 2.363 | ✅ | 0.649 | 1.534 | 320.1 | 0.0 | 2666.5 | 0.0 |
| `["transform", "Gaussian d=3 n=1024"]` | 5.482 | ✅ | 0.037 | 0.201 | 24.1 | 0.0 | 220.6 | 0.0 |
| `["transform", "Gaussian d=3 n=16384"]` | 2.324 | ✅ | 0.778 | 1.809 | 384.1 | 0.0 | 3186.5 | 0.0 |
| `["transform", "Gaussian d=3 n=256"]` | 12.763 | ✅ | 0.010 | 0.122 | 6.1 | 0.0 | 56.4 | 0.0 |
| `["transform", "Gaussian d=3 n=4096"]` | 2.945 | ✅ | 0.179 | 0.527 | 96.1 | 0.0 | 846.5 | 0.0 |
| `["transform", "Gaussian(dense) d=200 n=1024"]` | 4.498 | ✅ | 4.358 | 19.600 | 3200.2 | 0.0 | 13066.5 | 0.0 |
| `["transform", "Gaussian(dense) d=200 n=4096"]` | 5.190 | ✅ | 17.198 | 89.266 | 12800.2 | 0.0 | 52066.5 | 0.0 |
| `["transform", "Gaussian(dense) d=50 n=1024"]` | 2.568 | ✅ | 0.900 | 2.310 | 800.2 | 0.0 | 3316.5 | 0.0 |
| `["transform", "Gaussian(dense) d=50 n=4096"]` | 2.543 | ✅ | 3.496 | 8.893 | 3200.2 | 0.0 | 13066.5 | 0.0 |
| `["transform", "Gaussian(diag) d=200 n=1024"]` | 5.552 | ✅ | 3.419 | 18.983 | 1600.1 | 0.0 | 13066.5 | 0.0 |
| `["transform", "Gaussian(diag) d=200 n=4096"]` | 6.736 | ✅ | 13.143 | 88.533 | 6400.1 | 0.0 | 52066.5 | 0.0 |
| `["transform", "Gaussian(diag) d=50 n=1024"]` | 2.828 | ✅ | 0.819 | 2.316 | 400.1 | 0.0 | 3316.5 | 0.0 |
| `["transform", "Gaussian(diag) d=50 n=4096"]` | 2.701 | ✅ | 3.281 | 8.860 | 1600.1 | 0.0 | 13066.5 | 0.0 |
| `["transform", "JohnsonsSU d=10 n=1024"]` | 2.810 | ✅ | 0.224 | 0.628 | 160.2 | 0.0 | 716.5 | 0.0 |
| `["transform", "JohnsonsSU d=10 n=16384"]` | 2.230 | ✅ | 3.852 | 8.590 | 2560.2 | 0.0 | 10466.5 | 0.0 |
| `["transform", "JohnsonsSU d=10 n=256"]` | 4.061 | ✅ | 0.051 | 0.208 | 40.2 | 0.0 | 184.1 | 0.0 |
| `["transform", "JohnsonsSU d=10 n=4096"]` | 2.336 | ✅ | 0.960 | 2.243 | 640.2 | 0.0 | 2666.5 | 0.0 |
| `["transform", "StudentT d=10 n=1024"]` | 129.182 | ✅ | 0.044 | 5.713 | 80.1 | 0.0 | 519.8 | 0.0 |
| `["transform", "StudentT d=10 n=16384"]` | 96.573 | ✅ | 0.701 | 67.719 | 1280.1 | 0.0 | 7432.6 | 380.0 |
| `["transform", "StudentT d=10 n=256"]` | 229.619 | ✅ | 0.011 | 2.621 | 20.1 | 0.0 | 139.4 | 0.0 |
| `["transform", "StudentT d=10 n=4096"]` | 100.198 | ✅ | 0.177 | 17.719 | 320.1 | 0.0 | 1864.5 | 0.0 |

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
