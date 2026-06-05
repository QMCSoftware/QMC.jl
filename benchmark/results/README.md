# Benchmark Results

This directory stores generated benchmark outputs and comparison reports.

## Typical files

- `<label>.json`: Julia `BenchmarkTools` results
- `<label>_memory.json`: Julia retained-RSS sidecar
- `<label>_solutions.json`: Julia integrate-case solution and exactness sidecar
- `qmcpy_<label>.json`: QMCPy benchmark results
- `compare_*.md`: Julia-vs-Julia comparison reports
- `compare_python*.md`: Julia-vs-QMCPy comparison reports

The JSON and Markdown outputs here are machine-specific benchmark artifacts and are intentionally not tracked in git.
