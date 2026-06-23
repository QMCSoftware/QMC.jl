# Demos

## Quick Start

Add the package with `import Pkg; Pkg.add("QMC")`, or `Pkg.develop(path=pwd())`
from the repository root. Examples using `Lattice` also require `qmctoolscl`
installed in a Python visible to Julia.

**1. IID Monte Carlo** — integrate ``\sin(\pi x_1)\cos(\pi x_2)`` over ``[0,1]^2``
(exact value = 0):

```jldoctest
julia> using QMC

julia> dd = IIDStdUniform(2; seed=42);

julia> f = CustomFun(Uniform(dd), x -> sin.(π .* x[:, 1]) .* cos.(π .* x[:, 2]));

julia> result = integrate(CubMCCLT(f; abs_tol=1e-3));

julia> abs(result.solution) < 0.1
true
```

**2. QMC with a lattice rule** — Genz continuous integrand in 3D:

```jldoctest
julia> using QMC

julia> dd = Lattice(3; randomize=true, seed=7);

julia> f = Genz(Uniform(dd); kind=:continuous);

julia> result = integrate(CubQMCLatticeG(f; abs_tol=1e-4));

julia> isapprox(result.solution, genz_exact(f); atol=1e-4)
true
```

**3. Asian option pricing** — arithmetic-average call with 52 monitoring dates:

```jldoctest
julia> using QMC

julia> dd = Lattice(52; randomize=true, seed=7);

julia> f = AsianOption(BrownianMotion(dd); volatility=0.2, start_price=100.0, strike_price=100.0, interest_rate=0.05);

julia> result = integrate(CubQMCLatticeG(f; abs_tol=0.1));

julia> result.data[:converged]
true

julia> result.solution > 0.0
true
```

## Jupyter Notebooks

The `demos/` directory currently contains 26 notebooks. Current inventory:

- `acceptance_rejection.ipynb`
- `asian_option_mlqmc.ipynb`
- `control_variates.ipynb`
- `digital_net_b2.ipynb`
- `elliptic_pde.ipynb`
- `financial_option_ml.ipynb`
- `gbm_demo.ipynb`
- `iris.ipynb`
- `kronecker.ipynb`
- `lattice.ipynb`
- `lattice_random_generator.ipynb`
- `lebesgue_integration.ipynb`
- `linear_scrambled_halton.ipynb`
- `nei_demo.ipynb`
- `plot_proj_function.ipynb`
- `pricing_options.ipynb`
- `qei_demo.ipynb`
- `qmc.jl_intro.ipynb`
- `quickstart.ipynb`
- `ray_tracing.ipynb`
- `sample_scatter_plots.ipynb`
- `sensitivity_indices.ipynb`
- `some_true_measures.ipynb`
- `umbridge.ipynb`
- `vectorized_qmc.ipynb`
- `vectorized_qmc_bayes.ipynb`

To run a notebook:
```bash
jupyter notebook demos/quickstart.ipynb
```

To run all notebooks non-interactively (as a test):
```bash
julia --project=. test/run_notebooks.jl
# or
make notebook NOTEBOOK_JOBS=2 NOTEBOOK_THREADS=1
```

To execute notebooks with the `qmc-1.12` kernel and overwrite output cells in place:
```bash
make notebook-update NOTEBOOK_KERNEL=qmc-1.12
```

Both `make notebook` and `make notebook-update` shard the runnable notebook list across `NOTEBOOK_JOBS` processes. Set `NOTEBOOK_JOBS=1` if you want a single sequential pass over all runnable notebooks.

