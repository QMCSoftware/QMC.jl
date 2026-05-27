The `jupyter` command is a shim pointing to a conda environment (`qmcju`) whose Python 3.12 no longer exists. A few ways to fix this:

**Option 1 — Use the conda environment that has Julia's IJulia:**
```bash
conda activate qmcju
conda install jupyter
jupyter notebook demos/quickstart.ipynb
```

If the `qmcju` env was removed, recreate it or use a different env.

**Option 2 — Use IJulia's built-in notebook server (no conda needed):**
```bash
julia -e 'using IJulia; notebook(dir="demos")'
```

This launches Jupyter directly from Julia's IJulia package. If IJulia isn't installed yet:
```bash
julia -e 'using Pkg; Pkg.add("IJulia")'
julia -e 'using IJulia; notebook(dir="demos")'
```

**Option 3 — Use VS Code:**
Open any `.ipynb` file in VS Code with the Jupyter extension installed, then select the Julia 1.10 kernel from the kernel picker.

Option 2 is probably the quickest path since it bypasses the broken conda shim entirely.

## Demo Notebooks

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
