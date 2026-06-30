using Serialization
using LinearAlgebra
using QuasiMC
import QuasiMC: Uniform

length(ARGS) == 2 ||
    error("usage: julia cub_qmc_net_g_rep_thread_repro.jl <scenario> <outfile>")

const SCENARIO = ARGS[1]
const OUTFILE = ARGS[2]

BLAS.set_num_threads(1)

function scenario_result(name::AbstractString)
    if name == "ds"
        dd = DigitalNetB2(2; randomize="DS", seed=700)
        f = Genz(Uniform(dd); kind=:gaussian_peak, a=[1.0, 1.0], u=[0.5, 0.5])
        return integrate(
            CubQMCNetGRep(
                f;
                abs_tol=0.02,
                n_init=2^8,
                n_max=2^14,
                n_reps=8,
                trace_iterations=true,
            ),
        )
    elseif name == "lms_ds"
        dd = DigitalNetB2(3; randomize="LMS_DS", seed=2024)
        f = Keister(Gaussian(dd; covariance=0.5))
        return integrate(
            CubQMCNetGRep(
                f;
                abs_tol=0.005,
                n_init=2^8,
                n_max=2^14,
                n_reps=8,
                trace_iterations=true,
            ),
        )
    end
    error("unknown scenario: $name")
end

function iteration_diagnostics(result)
    haskey(result.data, :iteration_log) || return NamedTuple[]
    return [
        (
            iter=row.iter,
            n=row.n,
            solution=row.solution,
            error_bound=row.error_bound,
            tol=row.tol,
        ) for row in iterations(result.data[:iteration_log])
    ]
end

result = scenario_result(SCENARIO)
payload = (
    threads=Threads.nthreads(),
    solution=result.solution,
    error_bound=result.data[:error_bound],
    n=result.data[:n],
    n_per_rep=result.data[:n_per_rep],
    n_total=result.data[:n_total],
    n_reps=result.data[:n_reps],
    n_iterations=result.data[:n_iterations],
    converged=result.data[:converged],
    replicate_means=copy(result.data[:replicate_means]),
    replicate_std=result.data[:replicate_std],
    iteration_diagnostics=iteration_diagnostics(result),
)

open(OUTFILE, "w") do io
    serialize(io, payload)
end
