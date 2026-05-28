# QMC.jl Demo Notebooks

These notebooks contain Julia code for the QMC.jl package. Most demos use `Lattice`
or `DigitalNetB2`, so Python is currently required because those generators depend on
the `qmctoolscl` Python package. Conda is optional; it is only one way to provide that
Python environment or to launch Jupyter. The notebooks themselves must run with a Julia
kernel, not a Python kernel.

Install `qmctoolscl` into a Python visible to Julia before running the low-discrepancy demos:

```bash
python3 -m pip install qmctoolscl
```

If Julia should use a specific Python interpreter, set this before first use of those generators:

```julia
ENV["QMC_PYTHON"] = "/path/to/python"
```

**Option 1 — Use IJulia's built-in notebook server (no separate Jupyter Python environment required):**
```bash
julia -e 'using IJulia; notebook(dir="demos")'
```

From the repository root, create the project-bound notebook kernel once:
```bash
julia --project=. -e 'using Pkg; Pkg.instantiate()'
julia -e 'using Pkg; Pkg.add("IJulia")'
julia -e 'using IJulia; IJulia.installkernel("QMC", "--project=$(pwd())")'
```

Then open a demo notebook and select the `QMC` kernel once. Jupyter usually remembers that choice for that notebook.

**Option 2 — Use VS Code:**
Open any `.ipynb` file in VS Code with the Jupyter and Julia extensions installed, click the notebook kernel picker, and select `QMC` before running cells.

If VS Code selects `qmcju (Python 3.12.x)`, `qmcpy (Python 3.12.x)`, `Python 3.12.x`, or another non-`QMC` kernel, switch it before running cells. Otherwise Julia code such as `using QMC` will fail with a Python `SyntaxError`, or a generic Julia kernel may not see this repository's dependencies.

**Option 3 — Use Conda + Jupyter explicitly as the frontend only:**
```bash
conda create -n qmcju-notebooks python=3.12 -y
conda activate qmcju-notebooks
conda install jupyter
jupyter notebook demos/quickstart.ipynb
```

When Jupyter opens, choose the `QMC` Julia kernel for the notebook. The Python environment only launches Jupyter; it does not run the notebook code.

| Notebook | Topic |
|---|---|
| `quickstart.ipynb` | Keister integral with all 5 stopping criteria |
| `pricing_options.ipynb` | European, Asian, Lookback, Digital options |
| `digital_net_b2.ipynb` | Sobol' sequences, scrambling, replications |
| `lattice.ipynb` | Lattice orderings, shifts, Kuo vectors |
| `lebesgue_integration.ipynb` | Lebesgue measure integration |
| `some_true_measures.ipynb` | All 10 true measures demonstrated |
| `gbm_demo.ipynb` | Geometric Brownian Motion for finance |
| `qmcju_intro.ipynb` | Package tour: building blocks explained |
| `sample_scatter_plots.ipynb` | Point set visualizations and statistics |
| `elliptic_pde.ipynb` | 1D elliptic PDE uncertainty quantification with MC and lattice QMC |
