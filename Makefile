.PHONY: test coverage doc format format-check lint clean bench bench-compare bench-compare-py bench-compare-py-label bench-all-label bench-compare-labels check-qmcpy-python

FORMATTER_PROJECT=devtools/formatter
QMCPY_PYTHON_AUTO := $(shell \
	for py in python python3 "$(HOME)/miniconda3/bin/python" "$(HOME)/miniconda3/envs/qmcpy/bin/python" "$(HOME)/miniconda3/envs/qmcpy-leadership/bin/python"; do \
		if { [ -x "$$py" ] || command -v "$$py" >/dev/null 2>&1; } && "$$py" -c "import qmcpy" >/dev/null 2>&1; then \
			printf "%s" "$$py"; \
			break; \
		fi; \
	done)
PYTHON ?= $(if $(QMCPY_PYTHON_AUTO),$(QMCPY_PYTHON_AUTO),python)

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

# Allow `make bench-compare-labels a b` or `make bench-compare-labels a b out` as
# shorthand for `LABEL_A=a LABEL_B=b [OUT_LABEL=out]`.
ifneq ($(filter bench-compare-labels,$(firstword $(MAKECMDGOALS))),)
  EXTRA_LABEL_COMPARE_GOALS := $(wordlist 2,$(words $(MAKECMDGOALS)),$(MAKECMDGOALS))
  ifneq ($(strip $(EXTRA_LABEL_COMPARE_GOALS)),)
    LABEL_A ?= $(word 1,$(EXTRA_LABEL_COMPARE_GOALS))
    LABEL_B ?= $(word 2,$(EXTRA_LABEL_COMPARE_GOALS))
    OUT_LABEL ?= $(word 3,$(EXTRA_LABEL_COMPARE_GOALS))
    .PHONY: $(EXTRA_LABEL_COMPARE_GOALS)
    $(EXTRA_LABEL_COMPARE_GOALS):
	@:
  endif
endif

# Update packages and resolve dependencies
update:
	julia --project=. -e 'using Pkg; Pkg.update(); Pkg.resolve'

# Run all tests
test: 
	julia --project=. -e 'using Pkg; Pkg.instantiate(); Pkg.test()'

# Run tests with Julia coverage instrumentation
coverage:
	julia --project=. -e 'using Pkg; Pkg.instantiate(); Pkg.test(coverage=true)'

# Run specific test file
test-%:
	julia --project=. -e 'include("test/$*.jl")'

# Build documentation
doc:
	julia --project=docs -e 'using Pkg; Pkg.instantiate(); Pkg.resolve()'
	julia --project=docs docs/make.jl

# Format code with JuliaFormatter (uses the repo .JuliaFormatter.toml for all paths)
format:
	julia --project=$(FORMATTER_PROJECT) -e 'using Pkg; Pkg.instantiate(); using JuliaFormatter; format(["src/", "test/", "benchmark/"])'

# Check formatting (CI-friendly, fails if changes needed)
format-check:
	julia --project=$(FORMATTER_PROJECT) -e 'using Pkg; Pkg.instantiate(); using JuliaFormatter; @assert format(["src/", "test/", "benchmark/"], overwrite=false)'

# Clean build artifacts
clean:
	rm -rf docs/build
	rm -rf *.jl.cov *.jl.*.cov *.jl.mem lcov.info

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

check-qmcpy-python:
	@$(PYTHON) -c "import qmcpy" >/dev/null 2>&1 || \
		( echo "Configured PYTHON='$(PYTHON)' cannot import qmcpy."; \
		  echo "Use PYTHON=/path/to/python with qmcpy installed."; \
		  exit 1 )

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
# Runs both the Julia and QMCPy benchmark harnesses for the requested labels.
# Override output label with: make bench-compare-py LABEL=gaus or make bench-compare-py gaus
# Output: benchmark/results/compare_python.md (default) or compare_python_<LABEL>.md
# Ratio = Python time ÷ Julia time  →  < 1: local (Julia) slower  |  > 1: local (Julia) faster
# Override compared inputs with: make bench-compare-py JL_LABEL=foo PY_LABEL=bar
# If LABEL is set, it also becomes the default input label for both sides.
JL_LABEL ?= $(if $(LABEL),$(LABEL),latest)
PY_LABEL ?= $(JL_LABEL)
bench-compare-py: bench check-qmcpy-python
	$(PYTHON) benchmark/benchmark_qmcpy.py $(PY_LABEL)
	julia benchmark/compare_py.jl $(JL_LABEL) $(PY_LABEL) $(LABEL)

# Explicit labeled Julia-vs-QMCPy comparison flow.
# Usage: make bench-compare-py-label LABEL=base
bench-compare-py-label: check-qmcpy-python
	julia benchmark/runbenchmarks.jl $(LABEL)
	$(PYTHON) benchmark/benchmark_qmcpy.py $(LABEL)
	julia benchmark/compare_py.jl $(LABEL) $(LABEL) $(LABEL)

# Run the labeled Julia-only comparison and Julia-vs-QMCPy comparison in one task.
# Usage: make bench-all-label LABEL=base
bench-all-label:
	$(MAKE) bench-compare LABEL=$(LABEL)
	$(MAKE) bench-compare-py LABEL=$(LABEL)

# Compare two saved Julia benchmark-result labels and decide which one is better.
# Usage: make bench-compare-labels LABEL_A=a LABEL_B=b [OUT_LABEL=report]
#    or: make bench-compare-labels a b [report]
bench-compare-labels:
	julia benchmark/compare_labels.jl $(LABEL_A) $(LABEL_B) $(OUT_LABEL)
