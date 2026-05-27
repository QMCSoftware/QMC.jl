The `jupyter` command is a shim pointing to a conda environment (`qmcpy`) whose Python 3.12 no longer exists. A few ways to fix this:

**Option 1 — Use the conda environment that has Julia's IJulia:**
```bash
conda activate qmcpy
conda install jupyter
jupyter notebook demos/quickstart.ipynb
```

If the `qmcpy` env was removed, recreate it or use a different env.

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