.PHONY: test coverage doctest doc uml format format-check lint clean bench bench-compare bench-compare-py bench-compare-py-label bench-all bench-compare-labels bench-coverage bench-compare-coverage bench-compare-py-coverage bench-all-coverage local-ci workflow-smoke check-qmcpy-python ci-doc-demo ci-bench
.NOTPARALLEL: notebook notebook-update notebook-update-% notebook-% ci-doc-demo workflow-smoke

# ============================================================================
# Configuration and helpers
# ============================================================================

FORMATTER_PROJECT=devtools/formatter
DOC_DEPOT ?= $(if $(TMPDIR),$(TMPDIR),/tmp/)qmcju-doc-depot
QMCPY_PYTHON_AUTO := $(shell \
	for py in python python3 "$(HOME)/miniconda3/bin/python" "$(HOME)/miniconda3/envs/qmcpy/bin/python" "$(HOME)/miniconda3/envs/qmcpy-leadership/bin/python"; do \
		if { [ -x "$$py" ] || command -v "$$py" >/dev/null 2>&1; } && "$$py" -c "import qmcpy" >/dev/null 2>&1; then \
			printf "%s" "$$py"; \
			break; \
		fi; \
	done)
PYTHON ?= $(if $(QMCPY_PYTHON_AUTO),$(QMCPY_PYTHON_AUTO),python)
ACTIONLINT ?= actionlint
TEST_JOBS ?= 2
TEST_THREADS ?= 1
NOTEBOOK_JOBS ?= 2
NOTEBOOK_THREADS ?= 2
NOTEBOOK_SHARD_COUNT ?= 1
NOTEBOOK_SHARD_INDEX ?= 1
NOTEBOOK_OVERWRITE ?= 0
NOTEBOOK_KERNEL ?= qmc-1.12
NOTEBOOK_TIMEOUT ?= 1800
BENCH_COVERAGE ?= 0
BENCH_BLAS_THREADS ?= 2
BENCH_JULIA_THREADS ?= 4
WORKFLOW_SMOKE_NOTEBOOKS ?= 0
WORKFLOW_SMOKE_DOCS ?= 0
WORKFLOW_SMOKE_BENCH ?= 0
WORKFLOW_SMOKE_REV ?= HEAD
WORKFLOW_SMOKE_LABEL ?= workflow-smoke
JULIA_BENCH_COVERAGE_FLAG := $(if $(filter 1,$(BENCH_COVERAGE)),--code-coverage=user,)
BENCH_THREAD_ENV := QMC_BENCH_BLAS_THREADS=$(BENCH_BLAS_THREADS) OPENBLAS_NUM_THREADS=$(BENCH_BLAS_THREADS) MKL_NUM_THREADS=$(BENCH_BLAS_THREADS) OMP_NUM_THREADS=$(BENCH_BLAS_THREADS) NUMEXPR_NUM_THREADS=$(BENCH_BLAS_THREADS) JULIA_NUM_THREADS=$(BENCH_JULIA_THREADS) QMC_PYTHON=$(PYTHON)

define RUN_TIMED
	@start=$$(date +%s); \
	$(1); \
	exit_code=$$?; \
	end=$$(date +%s); \
	elapsed=$$((end - start)); \
	printf '\n[%s] total runtime: %ss\n' "$(2)" "$$elapsed"; \
	exit $$exit_code
endef

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

# ============================================================================
# Project maintenance and setup
# ============================================================================

# Update packages and resolve dependencies
update:
	julia --project=. -e 'using Pkg; Pkg.update(); Pkg.resolve'

# Instantiate project dependencies (includes Plots and all other deps). Download what Manifest.toml says.
setup:
	julia --project=. -e 'using Pkg; Pkg.instantiate()'

# Clean build artifacts
clean:
	rm -rf docs/build
	rm -rf *.jl.cov *.jl.*.cov *.jl.mem lcov.info
	find src benchmark test -name '*.cov' -delete

# ============================================================================
# Testing and coverage
# ============================================================================

# Run all unit tests. Override file-level process sharding with TEST_JOBS=... and
# Julia threads inside each test process with TEST_THREADS=...
test: 
	julia --project=. -e 'using Pkg; Pkg.instantiate(); Pkg.test(; julia_args=["--threads=$(TEST_THREADS)"], test_args=["--jobs=$(TEST_JOBS)"])'

# Run unit tests with Julia coverage instrumentation.
coverage:
	find src test -name '*.cov' -delete
	rm -f lcov.info
	julia --project=. -e 'using Pkg; Pkg.instantiate(); Pkg.test(; coverage=true, julia_args=["--threads=$(TEST_THREADS)"], test_args=["--jobs=$(TEST_JOBS)"])'
	julia --project=. devtools/process_coverage.jl
	find src test -name '*.cov' -delete

# Run specific test file
test-%:
	julia --project=. -e 'include("test/$*.jl")'

# ============================================================================
# Documentation
# ============================================================================

# Build documentation
doc:
	$(call RUN_TIMED,rm -rf docs/build && JULIA_DEPOT_PATH="$(DOC_DEPOT):$(HOME)/.julia" julia --project=docs -e 'using Pkg; Pkg.instantiate(); Pkg.resolve()' && JULIA_DEPOT_PATH="$(DOC_DEPOT):$(HOME)/.julia" julia --project=docs docs/make.jl,doc)

# Generate UML diagrams from the current src/ type graph.
uml:
	julia --project=. devtools/generate_uml.jl

# Run Documenter doctests only (manual pages + src docstrings) without a full render.
doctest:
	$(call RUN_TIMED,JULIA_DEPOT_PATH="$(DOC_DEPOT):$(HOME)/.julia" julia --project=docs -e 'import Pkg; Pkg.develop(Pkg.PackageSpec(path=".")); Pkg.instantiate(); Pkg.resolve()' && JULIA_DEPOT_PATH="$(DOC_DEPOT):$(HOME)/.julia" julia --project=docs docs/make.jl doctest=only,doctest)

# ============================================================================
# Formatting
# ============================================================================

# Format code with JuliaFormatter (uses the repo .JuliaFormatter.toml for all paths)
format:
	julia --project=$(FORMATTER_PROJECT) -e 'using Pkg; Pkg.instantiate(); using JuliaFormatter; format(["src/", "test/", "benchmark/"])'

# Check formatting (CI-friendly, fails if changes needed)
format-check:
	julia --project=$(FORMATTER_PROJECT) -e 'using Pkg; Pkg.instantiate(); using JuliaFormatter; @assert format(["src/", "test/", "benchmark/"], overwrite=false)'

# ============================================================================
# Smoke checks and notebooks
# ============================================================================

# Run a quick smoke test
smoke:
	julia --project=. -e 'using QMC; dd = Lattice(3; randomize=true); tm = Uniform(dd); f = Genz(tm; kind=:continuous); sc = CubQMCLatticeG(f; abs_tol=0.01); r = integrate(sc); println(r)'

# Run all demo notebooks (like Python's booktest). Override process sharding
# with NOTEBOOK_JOBS=... and Julia threads inside each notebook process with
# NOTEBOOK_THREADS=.... Use NOTEBOOK_SHARD_COUNT=... and NOTEBOOK_SHARD_INDEX=...
# to deterministically select a subset before any local process sharding. Set
# NOTEBOOK_OVERWRITE=1 to execute with Jupyter, write fresh output cells back
# into each notebook, and force the requested kernel via NOTEBOOK_KERNEL=...
notebook:
	GKSwstype=100 QMC_NOTEBOOK_PYTHON="$(PYTHON)" julia --threads=$(NOTEBOOK_THREADS) --project=. test/run_notebooks.jl --jobs=$(NOTEBOOK_JOBS) --shard-count=$(NOTEBOOK_SHARD_COUNT) --shard-index=$(NOTEBOOK_SHARD_INDEX) --overwrite=$(NOTEBOOK_OVERWRITE) --kernel=$(NOTEBOOK_KERNEL) --timeout=$(NOTEBOOK_TIMEOUT)

# Update notebooks in place with fresh output cells using Jupyter execution.
notebook-update:
	GKSwstype=100 QMC_NOTEBOOK_PYTHON="$(PYTHON)" julia --threads=$(NOTEBOOK_THREADS) --project=. test/run_notebooks.jl --jobs=$(NOTEBOOK_JOBS) --shard-count=$(NOTEBOOK_SHARD_COUNT) --shard-index=$(NOTEBOOK_SHARD_INDEX) --overwrite=1 --kernel=$(NOTEBOOK_KERNEL) --timeout=$(NOTEBOOK_TIMEOUT)

# Update a single notebook in place: make notebook-update-quickstart
notebook-update-%:
	GKSwstype=100 QMC_NOTEBOOK_PYTHON="$(PYTHON)" julia --threads=$(NOTEBOOK_THREADS) --project=. test/run_notebooks.jl --jobs=$(NOTEBOOK_JOBS) --shard-count=$(NOTEBOOK_SHARD_COUNT) --shard-index=$(NOTEBOOK_SHARD_INDEX) --overwrite=1 --kernel=$(NOTEBOOK_KERNEL) --timeout=$(NOTEBOOK_TIMEOUT) $*

# Run a single notebook by name: make notebook-quickstart
notebook-%:
	GKSwstype=100 QMC_NOTEBOOK_PYTHON="$(PYTHON)" julia --threads=$(NOTEBOOK_THREADS) --project=. test/run_notebooks.jl --jobs=$(NOTEBOOK_JOBS) --shard-count=$(NOTEBOOK_SHARD_COUNT) --shard-index=$(NOTEBOOK_SHARD_INDEX) --overwrite=$(NOTEBOOK_OVERWRITE) --kernel=$(NOTEBOOK_KERNEL) --timeout=$(NOTEBOOK_TIMEOUT) $*

# Audit QMC.jl demos against QMCPy sources
check-demos:
	$(PYTHON) devtools/check_demo_parity.py --jl-root demos --py-root ../QMCPy/demos

# ============================================================================
# Benchmarking
# ============================================================================

# Run the benchmark suite (uses its own environment in benchmark/, set up on first run)
# Override output label with: make bench LABEL=gaus or make bench gaus
# Saves results to benchmark/results/latest.json (default) or <LABEL>.json
bench:
	$(call RUN_TIMED,$(BENCH_THREAD_ENV) BENCH_COVERAGE=$(BENCH_COVERAGE) julia $(JULIA_BENCH_COVERAGE_FLAG) benchmark/runbenchmarks.jl $(LABEL),bench)

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
	$(call RUN_TIMED,$(BENCH_THREAD_ENV) BENCH_COVERAGE=$(BENCH_COVERAGE) julia $(JULIA_BENCH_COVERAGE_FLAG) benchmark/compare.jl $(REV) $(LABEL),bench-compare)

# Side-by-side Julia vs QMCPy comparison.
# Runs both the Julia and QMCPy benchmark harnesses for the requested labels.
# Override output label with: make bench-compare-py LABEL=gaus or make bench-compare-py gaus
# Output: benchmark/results/compare_python.md (default) or compare_python_<LABEL>.md
# Ratio = Python time ÷ Julia time  →  < 1: local (Julia) slower  |  > 1: local (Julia) faster
# Override compared inputs with: make bench-compare-py JL_LABEL=foo PY_LABEL=bar
# If LABEL is set, it also becomes the default input label for both sides.
JL_LABEL ?= $(if $(LABEL),$(LABEL),latest)
PY_LABEL ?= $(JL_LABEL)
BENCH_COMPARE_OUT := $(if $(LABEL),benchmark/results/compare_$(LABEL).md,benchmark/results/compare_head.md)
BENCH_COMPARE_PY_OUT := $(if $(LABEL),benchmark/results/compare_python_$(LABEL).md,benchmark/results/compare_python.md)
bench-compare-py: bench check-qmcpy-python
	$(call RUN_TIMED,$(BENCH_THREAD_ENV) $(PYTHON) benchmark/benchmark_qmcpy.py $(PY_LABEL) && $(BENCH_THREAD_ENV) QMC_BENCH_REQUIRE_QMCPY_ACCURACY=1 BENCH_COVERAGE=$(BENCH_COVERAGE) julia $(JULIA_BENCH_COVERAGE_FLAG) benchmark/compare_py.jl $(JL_LABEL) $(PY_LABEL) $(LABEL),bench-compare-py)

# Explicit labeled Julia-vs-QMCPy comparison flow.
# Usage: make bench-compare-py-label LABEL=base
bench-compare-py-label: check-qmcpy-python
	$(call RUN_TIMED,$(BENCH_THREAD_ENV) BENCH_COVERAGE=$(BENCH_COVERAGE) julia $(JULIA_BENCH_COVERAGE_FLAG) benchmark/runbenchmarks.jl $(LABEL) && $(BENCH_THREAD_ENV) $(PYTHON) benchmark/benchmark_qmcpy.py $(LABEL) && $(BENCH_THREAD_ENV) QMC_BENCH_REQUIRE_QMCPY_ACCURACY=1 BENCH_COVERAGE=$(BENCH_COVERAGE) julia $(JULIA_BENCH_COVERAGE_FLAG) benchmark/compare_py.jl $(LABEL) $(LABEL) $(LABEL),bench-compare-py-label)

# Run the labeled Julia-only comparison and Julia-vs-QMCPy comparison in one task.
# This target does not define a third ratio; inspect:
#   - $(BENCH_COMPARE_OUT)      with ratio = reference ÷ local
#   - $(BENCH_COMPARE_PY_OUT)   with ratio = Python ÷ Julia
# Usage: make bench-all LABEL=base
bench-all:
	$(call RUN_TIMED,$(MAKE) bench-compare BENCH_COVERAGE=$(BENCH_COVERAGE) BENCH_BLAS_THREADS=$(BENCH_BLAS_THREADS) REV=$(REV) LABEL=$(LABEL) && $(MAKE) bench-compare-py BENCH_COVERAGE=$(BENCH_COVERAGE) BENCH_BLAS_THREADS=$(BENCH_BLAS_THREADS) LABEL=$(LABEL) && printf '\n[bench-all] wrote %s (ratio = reference ÷ local) and %s (ratio = Python ÷ Julia)\n' "$(BENCH_COMPARE_OUT)" "$(BENCH_COMPARE_PY_OUT)",bench-all)

# Run the benchmark suite with coverage enabled and produce an lcov report over
# both src/ and benchmark/ coverage files.
bench-coverage:
	$(call RUN_TIMED,find src benchmark -name '*.cov' -delete && rm -f lcov.info && $(MAKE) bench BENCH_COVERAGE=1 BENCH_BLAS_THREADS=$(BENCH_BLAS_THREADS) && julia --project=. devtools/process_coverage.jl src benchmark && find src benchmark -name '*.cov' -delete,bench-coverage)

# Run the Julia-vs-Julia comparison with coverage enabled and produce an lcov report.
bench-compare-coverage:
	$(call RUN_TIMED,find src benchmark -name '*.cov' -delete && rm -f lcov.info && $(MAKE) bench-compare BENCH_COVERAGE=1 BENCH_BLAS_THREADS=$(BENCH_BLAS_THREADS) REV=$(REV) LABEL=$(LABEL) && julia --project=. devtools/process_coverage.jl src benchmark && find src benchmark -name '*.cov' -delete,bench-compare-coverage)

# Run the Julia-vs-QMCPy comparison with coverage enabled and produce an lcov report.
bench-compare-py-coverage:
	$(call RUN_TIMED,find src benchmark -name '*.cov' -delete && rm -f lcov.info && $(MAKE) bench-compare-py BENCH_COVERAGE=1 BENCH_BLAS_THREADS=$(BENCH_BLAS_THREADS) LABEL=$(LABEL) JL_LABEL=$(JL_LABEL) PY_LABEL=$(PY_LABEL) && julia --project=. devtools/process_coverage.jl src benchmark && find src benchmark -name '*.cov' -delete,bench-compare-py-coverage)

# Run the full labeled benchmark workflow with coverage enabled and produce an lcov report.
bench-all-coverage:
	$(call RUN_TIMED,find src benchmark -name '*.cov' -delete && rm -f lcov.info && $(MAKE) bench-all BENCH_COVERAGE=1 BENCH_BLAS_THREADS=$(BENCH_BLAS_THREADS) LABEL=$(LABEL) && julia --project=. devtools/process_coverage.jl src benchmark && find src benchmark -name '*.cov' -delete,bench-all-coverage)

# Compare two saved Julia benchmark-result labels and decide which one is better.
# Usage: make bench-compare-labels LABEL_A=a LABEL_B=b [OUT_LABEL=report]
#    or: make bench-compare-labels a b [report]
bench-compare-labels:
	julia benchmark/compare_labels.jl $(LABEL_A) $(LABEL_B) $(OUT_LABEL)

# ============================================================================
# Combination of above targets
# ============================================================================

# Lint workflow YAML (when actionlint is installed) and run the core Linux CI
# body locally. Opt into the slower workflow legs with:
#   WORKFLOW_SMOKE_NOTEBOOKS=1
#   WORKFLOW_SMOKE_DOCS=1
#   WORKFLOW_SMOKE_BENCH=1 [WORKFLOW_SMOKE_REV=HEAD~1]
workflow-smoke:
	$(call RUN_TIMED,\
		if $(ACTIONLINT) -version >/dev/null 2>&1; then \
			$(ACTIONLINT) .github/workflows/*.yml; \
		else \
			echo "[workflow-smoke] actionlint not found on PATH; skipping workflow YAML lint."; \
			echo "[workflow-smoke] See docs/src/workflow-debugging.md for install options."; \
		fi && \
		$(MAKE) coverage TEST_JOBS=$(TEST_JOBS) TEST_THREADS=$(TEST_THREADS) && \
		if [ "$(WORKFLOW_SMOKE_NOTEBOOKS)" = "1" ]; then \
			$(MAKE) notebook NOTEBOOK_JOBS=$(NOTEBOOK_JOBS) NOTEBOOK_THREADS=$(NOTEBOOK_THREADS); \
		else \
			echo "[workflow-smoke] skipping notebooks (set WORKFLOW_SMOKE_NOTEBOOKS=1 to enable)."; \
		fi && \
		if [ "$(WORKFLOW_SMOKE_DOCS)" = "1" ]; then \
			$(MAKE) doc; \
		else \
			echo "[workflow-smoke] skipping docs (set WORKFLOW_SMOKE_DOCS=1 to enable)."; \
		fi && \
		if [ "$(WORKFLOW_SMOKE_BENCH)" = "1" ]; then \
			$(MAKE) bench-all REV=$(WORKFLOW_SMOKE_REV) LABEL=$(WORKFLOW_SMOKE_LABEL) BENCH_BLAS_THREADS=$(BENCH_BLAS_THREADS); \
		else \
			echo "[workflow-smoke] skipping benchmarks (set WORKFLOW_SMOKE_BENCH=1 to enable)."; \
		fi,\
	workflow-smoke)

# Run the full-check pipeline: format code, collect unit-test,
# then collect full benchmark. Pass LABEL=... through to the benchmark step.
ci:
	$(call RUN_TIMED,$(MAKE) format && $(MAKE) test && $(MAKE) bench-all LABEL=$(LABEL),local-ci)

# ============================================================================
# Per-workflow local equivalents (sanity-check before pushing)
# ============================================================================
# ci.yml (Fast CI)      → make coverage
# ci-full.yml (Full CI) → make test  (current Julia/OS only; cross-platform matrix is CI-only)
# doc_demo.yml          → make notebook / make ci-doc-demo
# benchmarking.yml      → make ci-bench

# doc_demo.yml – full workflow: build docs then run all demo notebooks.
ci-doc-demo:
	$(call RUN_TIMED,$(MAKE) doc && $(MAKE) notebook,ci-doc-demo)

# benchmarking.yml: compare working tree against HEAD~1 (mirrors CI's comparison
# against the pre-push commit). Override baseline: make ci-bench CI_BENCH_REV=<sha>
CI_BENCH_REV ?= HEAD~1
ci-bench:
	$(call RUN_TIMED,$(MAKE) bench-all REV=$(CI_BENCH_REV) LABEL=ci-local BENCH_BLAS_THREADS=$(BENCH_BLAS_THREADS),ci-bench)
