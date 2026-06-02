# Benchmark Report for */Users/terrya/Documents/ProgramData/qmcju_software_choi*

## Job Properties
* Time of benchmarks:
    - Target: 2 Jun 2026 - 14:56
    - Baseline: 2 Jun 2026 - 14:57
* Package commits:
    - Target: dirty
    - Baseline: f21de9e
* Julia commits:
    - Target: 1534690
    - Baseline: 1534690
* Julia command flags:
    - Target: None
    - Baseline: None
* Environment variables:
    - Target: None
    - Baseline: None

## Results
A ratio greater than `1.0` denotes a possible regression (marked with :x:), while a ratio less
than `1.0` denotes a possible improvement (marked with :white_check_mark:). Brackets display [tolerances](https://juliaci.github.io/BenchmarkTools.jl/stable/manual/#Benchmark-Parameters) for the benchmark estimates. Only significant results - results
that indicate possible regressions or improvements - are shown below (thus, an empty table means that all
benchmark results remained invariant between builds).

| ID                                              | time ratio                   | memory ratio |
|-------------------------------------------------|------------------------------|--------------|
| `["evaluate", "Genz(oscillatory) n=16384"]`     |                1.08 (5%) :x: |   1.00 (1%)  |
| `["evaluate", "Keister n=256"]`                 |                1.24 (5%) :x: |   1.00 (1%)  |
| `["gen_samples", "DigitalNetB2 d=10 n=16384"]`  | 0.89 (5%) :white_check_mark: |   1.00 (1%)  |
| `["gen_samples", "DigitalNetB2 d=3 n=1024"]`    | 0.94 (5%) :white_check_mark: |   1.00 (1%)  |
| `["gen_samples", "DigitalNetB2 d=3 n=4096"]`    |                1.07 (5%) :x: |   1.00 (1%)  |
| `["gen_samples", "Halton d=3 n=1024"]`          | 0.90 (5%) :white_check_mark: |   1.00 (1%)  |
| `["gen_samples", "IIDStdUniform d=10 n=1024"]`  |                1.13 (5%) :x: |   1.00 (1%)  |
| `["gen_samples", "IIDStdUniform d=10 n=16384"]` |                1.11 (5%) :x: |   1.00 (1%)  |
| `["gen_samples", "IIDStdUniform d=10 n=4096"]`  | 0.81 (5%) :white_check_mark: |   1.00 (1%)  |
| `["gen_samples", "IIDStdUniform d=3 n=16384"]`  |                1.73 (5%) :x: |   1.00 (1%)  |
| `["gen_samples", "Kronecker d=3 n=1024"]`       |                1.16 (5%) :x: |   1.00 (1%)  |
| `["gen_samples", "Kronecker d=3 n=4096"]`       |                1.19 (5%) :x: |   1.00 (1%)  |
| `["gen_samples", "Lattice d=10 n=16384"]`       |                1.17 (5%) :x: |   1.00 (1%)  |
| `["gen_samples", "Lattice d=3 n=1024"]`         | 0.80 (5%) :white_check_mark: |   1.00 (1%)  |
| `["gen_samples", "Lattice d=3 n=256"]`          | 0.86 (5%) :white_check_mark: |   1.00 (1%)  |
| `["integrate", "CubMCCLT Keister"]`             | 0.90 (5%) :white_check_mark: |   1.00 (1%)  |
| `["integrate", "CubQMCNetG EuropeanOption"]`    |                1.12 (5%) :x: |   1.00 (1%)  |
| `["transform", "Gaussian d=10 n=1024"]`         |                1.08 (5%) :x: |   1.00 (1%)  |
| `["transform", "Gaussian d=10 n=16384"]`        |                1.07 (5%) :x: |   1.00 (1%)  |
| `["transform", "Gaussian d=10 n=4096"]`         |                1.06 (5%) :x: |   1.00 (1%)  |
| `["transform", "Gaussian d=3 n=1024"]`          |                1.08 (5%) :x: |   1.00 (1%)  |
| `["transform", "Gaussian d=3 n=16384"]`         |                1.05 (5%) :x: |   1.00 (1%)  |
| `["transform", "Gaussian d=3 n=256"]`           |                1.10 (5%) :x: |   1.00 (1%)  |
| `["transform", "Gaussian d=3 n=4096"]`          |                1.08 (5%) :x: |   1.00 (1%)  |

## Benchmark Group List
Here's a list of all the benchmark groups executed by this job:

- `["evaluate"]`
- `["gen_samples"]`
- `["integrate"]`
- `["transform"]`

## Julia versioninfo

### Target
```
Julia Version 1.12.6
Commit 15346901f0 (2026-04-09 19:20 UTC)
Build Info:
  Built by Homebrew (v1.12.6)

    Note: This is an unofficial build, please report bugs to the project
    responsible for this build and not to the Julia project unless you can
    reproduce the issue using official builds available at https://julialang.org

Platform Info:
  OS: macOS (arm64-apple-darwin25.4.0)
  uname: Darwin 25.5.0 Darwin Kernel Version 25.5.0: Mon Apr 27 20:41:15 PDT 2026; root:xnu-12377.121.6~2/RELEASE_ARM64_T6041 arm64 arm
  CPU: Apple M4 Max: 
                 speed         user         nice          sys         idle          irq
       #1-16  2400 MHz     709878 s          0 s     249549 s   14785237 s          0 s  
  Memory: 128.0 GB (4583.15625 MB free)
  Uptime: 1.090962e6 sec
  Load Avg:  4.328125  3.29736328125  3.0224609375
  WORD_SIZE: 64
  LLVM: libLLVM-18.1.7 (ORCJIT, apple-m4)
  GC: Built with stock GC
Threads: 1 default, 1 interactive, 1 GC (on 12 virtual cores)
```

### Baseline
```
Julia Version 1.12.6
Commit 15346901f0 (2026-04-09 19:20 UTC)
Build Info:
  Built by Homebrew (v1.12.6)

    Note: This is an unofficial build, please report bugs to the project
    responsible for this build and not to the Julia project unless you can
    reproduce the issue using official builds available at https://julialang.org

Platform Info:
  OS: macOS (arm64-apple-darwin25.4.0)
  uname: Darwin 25.5.0 Darwin Kernel Version 25.5.0: Mon Apr 27 20:41:15 PDT 2026; root:xnu-12377.121.6~2/RELEASE_ARM64_T6041 arm64 arm
  CPU: Apple M4 Max: 
                 speed         user         nice          sys         idle          irq
       #1-16  2400 MHz     709913 s          0 s     249559 s   14785501 s          0 s  
  Memory: 128.0 GB (4493.359375 MB free)
  Uptime: 1.090982e6 sec
  Load Avg:  4.82861328125  3.49853515625  3.10107421875
  WORD_SIZE: 64
  LLVM: libLLVM-18.1.7 (ORCJIT, apple-m4)
  GC: Built with stock GC
Threads: 1 default, 1 interactive, 1 GC (on 12 virtual cores)
```