# QMCJu.jl Demo Notebooks

These notebooks contain Julia code for the QMCJu.jl package. Python or Conda is optional and, if used, only provides a Jupyter frontend. The notebooks themselves must run with a Julia kernel, not a Python kernel.

**Option 1 — Use IJulia's built-in notebook server (no Python environment required):**
```bash
julia -e 'using IJulia; notebook(dir="demos")'
```

From the repository root, create the project-bound notebook kernel once:
```bash
julia --project=. -e 'using Pkg; Pkg.instantiate()'
julia -e 'using Pkg; Pkg.add("IJulia")'
julia -e 'using IJulia; IJulia.installkernel("QMCJu", "--project=$(pwd())")'
```

Then open a demo notebook and select the `QMCJu` kernel once. Jupyter usually remembers that choice for that notebook.

**Option 2 — Use VS Code:**
Open any `.ipynb` file in VS Code with the Jupyter and Julia extensions installed, click the notebook kernel picker, and select `QMCJu` before running cells.

If VS Code selects `qmcju (Python 3.12.x)`, `qmcpy (Python 3.12.x)`, `Python 3.12.x`, or another non-`QMCJu` kernel, switch it before running cells. Otherwise Julia code such as `using QMCJu` will fail with a Python `SyntaxError`, or a generic Julia kernel may not see this repository's dependencies.

**Option 3 — Use Conda + Jupyter explicitly as the frontend only:**
```bash
conda create -n qmcju-notebooks python=3.12 -y
conda activate qmcju-notebooks
conda install jupyter
jupyter notebook demos/quickstart.ipynb
```

When Jupyter opens, choose the `QMCJu` Julia kernel for the notebook. The Python environment only launches Jupyter; it does not run the notebook code.

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
