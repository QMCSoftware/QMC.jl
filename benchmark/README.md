# Benchmarking QMC.jl

This directory contains the standalone benchmark suite, the git-revision
comparison tooling, and the Julia-vs-QMCPy comparison tooling.

The benchmark scripts use the local `benchmark/Project.toml` environment, so
benchmark-only dependencies do not need to be added to the main package
environment.

## Files

- `benchmarks.jl`: defines the benchmark suite (`SUITE`)
- `runbenchmarks.jl`: runs the Julia suite and saves `*.json` results
- `compare.jl`: compares Julia benchmark results across revisions
- `compare_labels.jl`: compares two saved Julia benchmark labels
- `benchmark_qmcpy.py`: runs the QMCPy counterpart suite and saves `qmcpy_*.json`
- `compare_py.jl`: compares Julia results against QMCPy results
- `results/`: generated benchmark result files and Markdown reports

## Quick Start

From the repository root:

```bash
make bench
```

This writes:

```text
benchmark/results/latest.json
```

To save to a labeled file instead:

```bash
make bench base
# or
make bench LABEL=base
```

This writes:

```text
benchmark/results/base.json
benchmark/results/base_memory.json
```

## Julia-Only Comparison

Compare the current working tree against `HEAD`:

```bash
make bench-compare
```

This writes:

```text
benchmark/results/compare_head.md
```

Compare the current working tree against another revision:

```bash
make bench-compare REV=master
```

Write the comparison report to a labeled file:

```bash
make bench-compare gaus
# or
make bench-compare LABEL=gaus
```

This writes:

```text
benchmark/results/compare_gaus.md
```

Compare two saved Julia benchmark labels and decide which one is better:

```bash
make bench-compare-labels base latest
# or
make bench-compare-labels LABEL_A=base LABEL_B=latest
```

This writes:

```text
benchmark/results/compare_labels_base_vs_latest.md
```

The report uses:

- `weighted time ratio = latest ÷ base`
- `weighted memory ratio = latest ÷ base`

So:

- ratio `> 1` means `base` is better
- ratio `< 1` means `latest` is better

If one label wins both time and memory, it wins overall. If time and memory trade
off, the script uses a combined score to break the tie and reports that explicitly.

## Julia vs QMCPy Comparison

Run the full Julia-vs-QMCPy flow with the default `latest` label:

```bash
make bench-compare-py
```

Run the full flow with a label:

```bash
make bench-compare-py base
# or
make bench-compare-py LABEL=base
```

This runs:

```bash
julia benchmark/runbenchmarks.jl base
python benchmark/benchmark_qmcpy.py base
julia benchmark/compare_py.jl base base base
```

and writes:

```text
benchmark/results/base.json
benchmark/results/base_memory.json
benchmark/results/qmcpy_base.json
benchmark/results/compare_python_base.md
```

The Julia runner now also writes a sidecar memory file per label:

- `<label>_memory.json`: per-row Julia `rss_delta_kib` from one warmed call

The Python benchmark JSON records two approximate memory metrics per row:

- `tracemalloc_peak_kib`: Python-managed peak memory during one warmed call
- `rss_delta_kib`: retained process RSS delta after one warmed call

Together with Julia's `KiB` allocation metric from `BenchmarkTools`, this gives
three distinct memory signals:

- Julia `alloc KiB`: bytes allocated during the call
- Julia `rss_delta_kib`: retained process RSS delta after the call
- Python `tracemalloc_peak_kib`: Python-managed peak memory during the call
- Python `rss_delta_kib`: retained process RSS delta after the call

Briefly:

- `tracemalloc_peak_kib` is temporary Python-level memory pressure during the call
- Julia `rss_delta_kib` is temporary-to-retained process memory on the Julia side
- `rss_delta_kib` is net process memory retained after the call
- Julia `KiB` is bytes allocated during the call, not retained RSS

When reading the weighted ratios in `compare_python*.md`:

- ratio `< 1` means the Python metric is smaller than the Julia total
- ratio `> 1` means the Python metric is larger than the Julia total

If one memory ratio is `< 1` and the other is `> 1`, that is normal rather than
contradictory. It usually means Python allocated more temporary memory during the
call but released most of it afterward, or conversely retained more process
memory even though its traced Python-level peak was modest. Use:

- time ratio as the cleanest cross-language comparison
- `tracemalloc` as a temporary-allocation signal
- `Julia RSS delta` / `Python RSS delta` as retained-footprint signals

If `<label>_memory.json` is missing because the Julia benchmarks were generated
before this feature was added, `compare_python*.md` will show Julia RSS delta as
`n/a` until that label is rerun with `make bench` or `make bench-compare-py`.

The Python harness also mirrors most of the newer Julia-only benchmark rows:

- large-`d` `Gaussian(diag)` and `Gaussian(dense)` transforms
- `StudentT` and `JohnsonsSU` transforms
- `BoxIntegral` and `Linear0` evaluate rows, including large-`d` variants
- `Genz(gaussian_peak)` and `Genz(continuous)` via direct NumPy formulas with the
  same default parameters Julia uses, since QMCPy exposes only oscillatory and
  corner-peak Genz variants

If `compare_python*.md` still shows `n/a` rows after regenerating `qmcpy_<label>.json`,
those rows do not currently have a meaningful Python counterpart in the harness.

If the Python interpreter should be overridden:

```bash
make bench-compare-py base PYTHON=python3
```

By default, the Makefile now tries to auto-detect a Python that can
`import qmcpy`, checking common candidates such as `python`, `python3`, and
common Miniconda locations. If that guess is wrong on your machine, override it
explicitly with `PYTHON=/path/to/python`.

If the Julia and QMCPy input labels should differ:

```bash
make bench-compare-py JL_LABEL=julia_run PY_LABEL=python_run LABEL=ab_test
```

This writes:

```text
benchmark/results/compare_python_ab_test.md
```

## Explicit Labeled QMCPy Comparison Target

There is also an explicit target for the three-step labeled Julia-vs-QMCPy flow:

```bash
make bench-compare-py-label LABEL=base
```

This is equivalent to:

```bash
julia benchmark/runbenchmarks.jl base
python benchmark/benchmark_qmcpy.py base
julia benchmark/compare_py.jl base base base
```

## Combined Labeled Comparison Target

To run both the labeled Julia-only comparison and the labeled Julia-vs-QMCPy
comparison in one task:

```bash
make bench-all-label LABEL=base
```

This runs:

```bash
make bench-compare LABEL=base
make bench-compare-py LABEL=base
```

which expands to:

```bash
julia benchmark/compare.jl HEAD base
julia benchmark/runbenchmarks.jl base
python benchmark/benchmark_qmcpy.py base
julia benchmark/compare_py.jl base base base
```

and writes:

```text
benchmark/results/compare_base.md
benchmark/results/base.json
benchmark/results/base_memory.json
benchmark/results/qmcpy_base.json
benchmark/results/compare_python_base.md
```

## Output Files

Common generated files:

- `results/<label>.json`: Julia benchmark data
- `results/<label>_memory.json`: Julia RSS-delta sidecar data
- `results/qmcpy_<label>.json`: QMCPy benchmark data
- `results/compare_<label>.md`: Julia-vs-Julia comparison report
- `results/compare_labels_<a>_vs_<b>.md`: saved-label comparison report
- `results/compare_python_<label>.md`: Julia-vs-QMCPy comparison report
- `results/compare_head.md`: default Julia-vs-Julia report
- `results/compare_python.md`: default Julia-vs-QMCPy report
- `results/bench_local.md`: single-run Julia benchmark summary

## Notes

- `bench-compare` uses `PkgBenchmark` and may benchmark git revisions in a
  temporary worktree.
- `bench-compare-py` requires a Python environment where `qmcpy` is installed.
- Python-vs-Julia benchmark reports now include Python `tracemalloc` peak and, when
  available, retained RSS delta. Those memory metrics are approximate and should be
  read as supporting evidence, not as exact equivalents of Julia allocation `KiB`.
- Current benchmark reports are written in a sanitized form and avoid embedding
  host-specific system details or absolute local paths.
