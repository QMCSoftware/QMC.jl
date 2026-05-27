# Demo Notebooks

These notebooks contain Julia code. Run them with a Julia kernel, not the Python `qmcju` kernel.

**Option 1 — Use IJulia's built-in notebook server:**
```bash
julia -e 'using IJulia; notebook(dir="demos")'
```

If you want the notebooks to use this repository's environment by default, install a custom kernel from the repository root first:
```bash
julia -e 'using IJulia; IJulia.installkernel("QMCJu", "--project=$(pwd())")'
```

Then open a demo notebook and select the `QMCJu` kernel once. Jupyter usually remembers that choice for that notebook.

If IJulia is not installed yet:
```bash
julia -e 'using Pkg; Pkg.add("IJulia")'
julia -e 'using IJulia; notebook(dir="demos")'
```

**Option 2 — Use VS Code:**
Open any `.ipynb` file in VS Code with the Jupyter and Julia extensions installed, then select the Julia kernel from the kernel picker before running cells.

If VS Code selects `qmcju (Python 3.12.x)` or another Python kernel, switch to Julia. Otherwise Julia code such as `using QMCJu` will fail with a Python `SyntaxError`.

**Option 3 — Use Conda + Jupyter explicitly:**
```bash
conda activate qmcju
conda install jupyter ipykernel
jupyter notebook demos/quickstart.ipynb
```

When Jupyter opens, choose the Julia kernel for the notebook.

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
