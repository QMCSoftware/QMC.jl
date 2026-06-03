.PHONY: test doc format format-check lint clean bench bench-compare bench-compare-py

FORMATTER_PROJECT=devtools/formatter

# Allow `make bench gaus` / `make bench-compare gaus` / `make bench-compare-py gaus`
# as shorthand for `LABEL=gaus`. `make` treats `gaus` as an extra goal, so consume
# it explicitly.
ifneq ($(filter bench bench-compare bench-compare-py,$(firstword $(MAKECMDGOALS))),)
  EXTRA_BENCH_GOALS := $(wordlist 2,$(words $(MAKECMDGOALS)),$(MAKECMDGOALS))
  ifneq ($(strip $(EXTRA_BENCH_GOALS)),)
    LABEL ?= $(firstword $(EXTRA_BENCH_GOALS))
    .PHONY: $(EXTRA_BENCH_GOALS)
    $(EXTRA_BENCH_GOALS):
	@:
  endif
endif

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
# Override output label with: make bench LABEL=gaus or make bench gaus
# Saves results to benchmark/results/latest.json (default) or <LABEL>.json
bench:
	julia benchmark/runbenchmarks.jl $(LABEL)

# Compare the working tree against a baseline git revision (default: HEAD, i.e.
# the effect of uncommitted changes). Override with: make bench-compare REV=master
# Override output label with: make bench-compare LABEL=gaus or make bench-compare gaus
# Output: benchmark/results/compare_head.md (default) or compare_<LABEL>.md
# Ratio = reference (REV) time ÷ local time  →  < 1: local slower  |  > 1: local faster
REV ?= HEAD
LABEL ?=
bench-compare:
	julia benchmark/compare.jl $(REV) $(LABEL)

# Side-by-side Julia vs QMCPy comparison.
# Prerequisites: run `make bench` then `python benchmark/benchmark_qmcpy.py [label]`.
# Override output label with: make bench-compare-py LABEL=gaus or make bench-compare-py gaus
# Output: benchmark/results/compare_python.md (default) or compare_python_<LABEL>.md
# Ratio = Python time ÷ Julia time  →  < 1: local (Julia) slower  |  > 1: local (Julia) faster
# Override compared inputs with: make bench-compare-py JL_LABEL=foo PY_LABEL=bar
# If LABEL is set, it also becomes the default input label for both sides.
JL_LABEL ?= $(if $(LABEL),$(LABEL),latest)
PY_LABEL ?= $(JL_LABEL)
bench-compare-py: bench
	julia benchmark/compare_py.jl $(JL_LABEL) $(PY_LABEL) $(LABEL)
