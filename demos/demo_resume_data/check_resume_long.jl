"""
Long-run resume check using rel_tol (non-ML) and rmse_tol (ML).

Julia counterpart of QMCPy/demos/demo_resume_data/check_resume_long.py.

Runs a loose solve, resumes with a tighter tolerance, then compares against
a fresh tight solve from scratch. Writes a combined text report.

Usage (from QuasiMC.jl root):
    julia demos/demo_resume_data/check_resume_long.jl
From demos/demo_resume_data/:
    julia check_resume_long.jl
"""

include(joinpath(@__DIR__, "resume_util.jl"))

const SEED      = 7
const CONT_SEED = 11

# abs_tol=1e-15 serves as a near-zero floor when rel_tol is the primary tolerance.
# Julia's stopping criterion constructors require abs_tol > 0.
const NEAR_ZERO = 1e-15

function _build_cases()
    d = 2

    iid_k   = () -> Keister(Gaussian(IIDStdUniform(d; seed=SEED); covariance=0.5))
    lat_k   = () -> Keister(Gaussian(Lattice(d; seed=SEED); covariance=0.5))
    net_k   = () -> Keister(Gaussian(DigitalNetB2(d; seed=SEED, graycode=false); covariance=0.5))
    net8_k  = () -> Keister(Gaussian(DigitalNetB2(8; seed=SEED, graycode=false); covariance=0.5))
    blat_k  = () -> Keister(Gaussian(Lattice(d; seed=SEED); covariance=0.5))

    ml_iid_4d  = () -> FinancialOptionML(IIDStdUniform(4; seed=SEED);
                           d_coarsest=2, start_price=30.0, strike_price=30.0)
    ml_qmc_4d  = () -> FinancialOptionML(Lattice(4; seed=SEED, replications=32);
                           d_coarsest=2, start_price=30.0, strike_price=30.0)
    ml_iid_4dc = () -> FinancialOptionML(IIDStdUniform(4; seed=CONT_SEED);
                           d_coarsest=2, start_price=30.0, strike_price=30.0)
    ml_qmc_4dc = () -> FinancialOptionML(Lattice(4; seed=CONT_SEED, replications=32);
                           d_coarsest=2, start_price=30.0, strike_price=30.0)

    return [
        (name="CubMCCLTVec",
         loose=() -> CubMCCLTVec(iid_k(); abs_tol=NEAR_ZERO, rel_tol=1e-2, n_init=256, n_max=2^22, trace_iterations=true),
         tight=() -> CubMCCLTVec(iid_k(); abs_tol=NEAR_ZERO, rel_tol=1e-3, n_init=256, n_max=2^22, trace_iterations=true),
         tol="rel_tol"),

        (name="CubQMCLatticeG",
         loose=() -> CubQMCLatticeG(lat_k(); abs_tol=NEAR_ZERO, rel_tol=1e-2, n_max=2^24, trace_iterations=true),
         tight=() -> CubQMCLatticeG(lat_k(); abs_tol=NEAR_ZERO, rel_tol=2e-6, n_max=2^24, trace_iterations=true),
         tol="rel_tol"),

        (name="CubQMCNetG",
         loose=() -> CubQMCNetG(net_k(); abs_tol=NEAR_ZERO, rel_tol=1e-3, n_max=2^24, trace_iterations=true),
         tight=() -> CubQMCNetG(net_k(); abs_tol=NEAR_ZERO, rel_tol=1e-6, n_max=2^24, trace_iterations=true),
         tol="rel_tol"),

        (name="CubQMCNetGRep",
         loose=() -> CubQMCNetGRep(net8_k(); abs_tol=NEAR_ZERO, rel_tol=1e-3, n_init=32, n_reps=16, n_max=2^24, trace_iterations=true),
         tight=() -> CubQMCNetGRep(net8_k(); abs_tol=NEAR_ZERO, rel_tol=1e-4, n_init=32, n_reps=16, n_max=2^24, trace_iterations=true),
         tol="rel_tol"),

        (name="CubQMCBayesLatticeG",
         loose=() -> CubQMCBayesLatticeG(blat_k(); abs_tol=NEAR_ZERO, rel_tol=1e-3, n_init=64, n_max=2^24, trace_iterations=true),
         tight=() -> CubQMCBayesLatticeG(blat_k(); abs_tol=NEAR_ZERO, rel_tol=1e-9, n_init=64, n_max=2^24, trace_iterations=true),
         tol="rel_tol"),

        (name="CubQMCBayesNetG",
         loose=() -> CubQMCBayesNetG(net_k(); abs_tol=NEAR_ZERO, rel_tol=1e-3, n_init=64, n_max=2^22, trace_iterations=true),
         tight=() -> CubQMCBayesNetG(net_k(); abs_tol=NEAR_ZERO, rel_tol=5e-6, n_init=64, n_max=2^22, trace_iterations=true),
         tol="rel_tol"),

        (name="CubMLMC",
         loose=() -> CubMLMC(ml_iid_4d(); rmse_tol=0.5, n_limit=2^24, trace_iterations=true),
         tight=() -> CubMLMC(ml_iid_4d(); rmse_tol=0.1, n_limit=2^24, trace_iterations=true),
         tol="rmse_tol"),

        (name="CubMLQMC",
         loose=() -> CubMLQMC(ml_qmc_4d(); rmse_tol=0.5, n_limit=2^24, trace_iterations=true),
         tight=() -> CubMLQMC(ml_qmc_4d(); rmse_tol=0.1, n_limit=2^24, trace_iterations=true),
         tol="rmse_tol"),

        (name="CubMLMCCont",
         loose=() -> CubMLMCCont(ml_iid_4dc(); rmse_tol=0.5, n_tols=1200, inflate=1.001, n_limit=2^24, trace_iterations=true),
         tight=() -> CubMLMCCont(ml_iid_4dc(); rmse_tol=0.1, n_tols=1200, inflate=1.001, n_limit=2^24, trace_iterations=true),
         tol="rmse_tol"),

        (name="CubMLQMCCont",
         loose=() -> CubMLQMCCont(ml_qmc_4dc(); rmse_tol=0.5, n_tols=1200, inflate=1.001, n_limit=2^24, trace_iterations=true),
         tight=() -> CubMLQMCCont(ml_qmc_4dc(); rmse_tol=0.1, n_tols=1200, inflate=1.001, n_limit=2^24, trace_iterations=true),
         tol="rmse_tol"),
    ]
end

function main()
    output_dir = joinpath(@__DIR__, "output")
    mkpath(output_dir)

    cases_config = _build_cases()
    results = [run_case(c.name, c.loose, c.tight; tol_name=c.tol) for c in cases_config]

    out_path = joinpath(output_dir, "check_resume_long_summary.txt")
    write_combined_report(
        out_path,
        "Stopping Criteria Long-Run Check: Resume vs Fresh (ML iters may differ)",
        results,
    )
end

main()
