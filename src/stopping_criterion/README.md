# Stopping Criteria

This folder contains the adaptive algorithms that decide when an integral estimate has met its error target.

## Single-level methods

- `cub_mc_clt.jl`
- `cub_mc_clt_vec.jl`
- `cub_mc_g.jl`
- `cub_qmc_lattice_g.jl`
- `cub_qmc_net_g.jl`
- `cub_qmc_bayes_lattice_g.jl`
- `cub_qmc_bayes_net_g.jl`
- `cub_qmc_rep_student_t.jl`

## Multilevel methods

- `cub_mlmc.jl`
- `cub_mlmc_cont.jl`
- `cub_mlqmc.jl`
- `cub_mlqmc_cont.jl`

## Experimental / placeholder integrations

- `pf_gp_ci.jl`

Each file defines a stopping-criterion type plus its corresponding `integrate` method.
