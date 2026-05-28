.PHONY: test docs format format-check lint clean

FORMATTER_PROJECT=devtools/formatter

# Run all tests
test:
	julia --project=. -e 'using Pkg; Pkg.test()'

# Run specific test file
test-%:
	julia --project=. -e 'include("test/$*.jl")'

# Build documentation
doc:
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

# Instantiate project dependencies (includes Plots and all other deps)
setup:
	julia --project=. -e 'using Pkg; Pkg.instantiate()'

# Run a quick smoke test
smoke:
	julia --project=. -e 'using QMCJu; dd = Lattice(3; randomize=true); tm = Uniform(dd); f = Genz(tm; kind=:continuous); sc = CubQMCLatticeG(f; abs_tol=0.01); r = integrate(sc); println(r)'


# Run all demo notebooks (like Python's booktest)
notebook:
	julia --project=. test/run_notebooks.jl

# Run a single notebook by name: make notebook-quickstart
notebook-%:
	julia --project=. test/run_notebooks.jl $*
