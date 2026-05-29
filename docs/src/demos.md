# Demos

## Quick Start

Examples using `Lattice` require the QMCToolsCL shared library. Install
`qmctoolscl` into a Python visible to Julia before running them.

```julia
# In terminal, run `julia`. Issue the following command:
#   import Pkg; Pkg.add("QMC")
# If the package is not on path and you started Julia from the repository root:
#   import Pkg; Pkg.develop(path=pwd())
using QMC

# 1. IID Monte Carlo for a simple integral
dd = IIDStdUniform(2; seed=42)
tm = Uniform(dd)
f = CustomFun(tm, x -> sin.(π .* x[:, 1]) .* cos.(π .* x[:, 2]))
sc = CubMCCLT(f; abs_tol=1e-3)
result = integrate(sc)
println("MC estimate: $(result.solution), error bound: $(result.data[:error_bound])")

# 2. QMC with lattice rule
dd = Lattice(3; randomize=true)
tm = Uniform(dd)
f = Genz(tm; kind=:continuous)
sc = CubQMCLatticeG(f; abs_tol=1e-4)
result = integrate(sc)
println("QMC estimate: $(result.solution)")

# 3. Asian option pricing
dd = Lattice(52; randomize=true)  # weekly monitoring for 1 year
tm = BrownianMotion(dd)
f = AsianOption(tm; volatility=0.2, start_price=100.0, strike_price=100.0,
                interest_rate=0.05)
sc = CubQMCLatticeG(f; abs_tol=0.1, n_reps=16)
result = integrate(sc)
println("Asian call price: $(result.solution)")
```

## Jupyter Notebooks

Interactive Jupyter notebooks are available in the `demos/` directory:

| Notebook | Description |
|----------|-------------|
| `quickstart.ipynb` | Getting started with QMC.jl |
| `qmcju_intro.ipynb` | Introduction to the QMC framework |
| `lebesgue_integration.ipynb` | Lebesgue integration examples |
| `lattice.ipynb` | Lattice rule demonstrations |
| `digital_net_b2.ipynb` | Digital net (Sobol') demonstrations |
| `some_true_measures.ipynb` | True measure transforms |
| `pricing_options.ipynb` | Financial option pricing (European, Asian, lookback) |
| `gbm_demo.ipynb` | Geometric Brownian motion and volatility analysis |
| `sample_scatter_plots.ipynb` | Scatter plots of QMC point sets |
| `elliptic_pde.ipynb` | Elliptic PDE with multilevel MC/QMC methods |

To run a notebook:
```bash
jupyter notebook demos/quickstart.ipynb
```

To run all notebooks non-interactively (as a test):
```bash
julia --project=. test/run_notebooks.jl
```
