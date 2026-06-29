# QuasiMC.jl Demo Notebooks

These notebooks contain Julia code for the QuasiMC.jl package. Most demos use
`Lattice` or `DigitalNetB2`, but those generators now use the packaged
QMCToolsCL backend supplied through QuasiMC itself. Python is only needed here
as a Jupyter frontend if you choose to launch notebooks that way. The notebooks
themselves must run with a Julia kernel, not a Python kernel.

If you need to force QuasiMC to load a custom QMCToolsCL build while debugging,
set this before first use of those generators:

```julia
ENV["QUASIMC_QMCTOOLSCL_LIB"] = "/absolute/path/to/library"
```

**Option 1 — Use IJulia's built-in notebook server (no separate Jupyter Python environment required):**
```bash
julia -e 'using IJulia; notebook(dir="demos")'
```

From the repository root, create the project-bound notebook kernel once:
```bash
julia --project=. -e 'using Pkg; Pkg.instantiate()'
julia -e 'using Pkg; Pkg.add("IJulia")'
julia -e 'using IJulia; IJulia.installkernel("QuasiMC", "--project=$(pwd())")'
```

Then open a demo notebook and select the `QuasiMC` kernel once. Jupyter usually remembers that choice for that notebook.

**Option 2 — Use VS Code:** Open any `.ipynb` file in VS Code with the Jupyter and Julia extensions installed, click the notebook kernel picker, and select `QuasiMC` before running cells.

If VS Code selects `qmcpy (Python 3.12.x)`, `Python 3.12.x`, or another non-`QuasiMC` kernel, switch it before running cells. Otherwise Julia code such as `using QuasiMC` will fail with a Python `SyntaxError`, or a generic Julia kernel may not see this repository's dependencies.

**Option 3 — Use Conda + Jupyter explicitly as the frontend only:**
```bash
conda create -n qmcpy python=3.12 -y
conda activate qmcpy
conda install jupyter
jupyter notebook demos/quickstart.ipynb
```

When Jupyter opens, choose the `QuasiMC` Julia kernel for the notebook. The
Python environment only launches Jupyter; it does not run the notebook code or
provide QuasiMC's QMCToolsCL backend.

Current notebook inventory:

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
- `quasimc.jl_intro.ipynb`
- `quickstart.ipynb`
- `ray_tracing.ipynb`
- `sample_scatter_plots.ipynb`
- `sensitivity_indices.ipynb`
- `some_true_measures.ipynb`
- `umbridge.ipynb`
- `vectorized_qmc.ipynb`
- `vectorized_qmc_bayes.ipynb`
