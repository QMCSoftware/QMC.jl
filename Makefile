.PHONY: test doc format format-check lint clean bench bench-compare bench-compare-py

FORMATTER_PROJECT=devtools/formatter

# Update packages and resolve dependencies
update:
	julia --project=. -e 'using Pkg; Pkg.update(); Pkg.resolve'

# Run all tests
test: 
	julia --project=. -e 'using Pkg; Pkg.instantiate(); Pkg.test()'

# Run specific test file
test-%:
	julia --project=. -e 'include("test/$*.jl")'

# Build documentation
doc:
	julia --project=docs -e 'using Pkg; Pkg.instantiate(); Pkg.resolve()'
	julia --project=docs docs/make.jl

# Format code with JuliaFormatter
format:
	julia --project=$(FORMATTER_PROJECT) -e 'using Pkg; Pkg.instantiate(); using JuliaFormatter; format("src/"); format("test/")'

# Check formatting (CI-friendly, fails if changes needed)
format-check:
	julia --project=$(FORMATTER_PROJECT) -e 'using Pkg; Pkg.instantiate(); using JuliaFormatter; @assert format("src/", overwrite=false); @assert format("test/", overwrite=false)'

# Clean build artifacts
clean:
	rm -rf docs/build
	rm -rf *.jl.cov *.jl.*.cov *.jl.mem

# Instantiate project dependencies (includes Plots and all other deps). Download what Manifest.toml says.
setup:
	julia --project=. -e 'using Pkg; Pkg.instantiate()'

# Run a quick smoke test
smoke:
	julia --project=. -e 'using QMC; dd = Lattice(3; randomize=true); tm = Uniform(dd); f = Genz(tm; kind=:continuous); sc = CubQMCLatticeG(f; abs_tol=0.01); r = integrate(sc); println(r)'

# Run all demo notebooks (like Python's booktest)
notebook:
	julia --project=. test/run_notebooks.jl

# Run a single notebook by name: make notebook-quickstart
notebook-%:
	julia --project=. test/run_notebooks.jl $*

# Run the benchmark suite (uses its own environment in benchmark/, set up on first run)
# Saves results to benchmark/results/latest.json
bench:
	julia benchmark/runbenchmarks.jl

# Compare the working tree against a baseline git revision (default: HEAD, i.e.
# the effect of uncommitted changes). Override with: make bench-compare REV=master
# Output: benchmark/results/compare_head.md
# Ratio = reference (REV) time ÷ local time  →  < 1: local slower  |  > 1: local faster
REV ?= HEAD
bench-compare:
	julia benchmark/compare.jl $(REV)

# Side-by-side Julia vs QMCPy comparison.
# Prerequisites: run `make bench` then `python benchmark/benchmark_qmcpy.py [label]`.
# Output: benchmark/results/compare_python.md
# Ratio = Python time ÷ Julia time  →  < 1: local (Julia) slower  |  > 1: local (Julia) faster
# Override label with: make bench-compare-py JL_LABEL=foo PY_LABEL=bar
JL_LABEL ?= latest
PY_LABEL ?= $(JL_LABEL)
bench-compare-py: bench
	julia benchmark/compare_py.jl $(JL_LABEL) $(PY_LABEL)
