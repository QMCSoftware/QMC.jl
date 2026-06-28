"""
Fast-run resume check using abs_tol.

Julia counterpart of QMCPy/demos/demo_resume_data/check_resume.py.

Runs a loose solve, resumes with a tighter tolerance, then compares against
a fresh tight solve from scratch. Writes a combined text report.

Usage (from QuasiMC.jl root):
    julia demos/demo_resume_data/check_resume.jl
From demos/demo_resume_data/:
    julia check_resume.jl
"""

include(joinpath(@__DIR__, "resume_util.jl"))

const SEED      = 7
const CONT_SEED = 11

function _build_cases()
    d = 2

    iid_k  = () -> Keister(Gaussian(IIDStdUniform(d; seed=SEED); covariance=0.5))
    lat_k  = () -> Keister(Gaussian(Lattice(d; seed=SEED); covariance=0.5))
    net_k  = () -> Keister(Gaussian(DigitalNetB2(d; seed=SEED, graycode=false); covariance=0.5))
    net5_k = () -> Keister(Gaussian(DigitalNetB2(5; seed=SEED, graycode=false); covariance=0.5))
    blat_k = () -> Keister(Gaussian(Lattice(d; seed=SEED); covariance=0.5))

    ml_iid  = () -> FinancialOptionML(IIDStdUniform(8; seed=SEED);
                        d_coarsest=2, start_price=30.0, strike_price=30.0)
    ml_iid2 = () -> FinancialOptionML(IIDStdUniform(8; seed=CONT_SEED);
                        d_coarsest=2, start_price=30.0, strike_price=30.0)
    ml_qmc  = () -> FinancialOptionML(Lattice(8; seed=SEED, replications=32);
                        d_coarsest=2, start_price=30.0, strike_price=30.0)
    ml_qmc2 = () -> FinancialOptionML(Lattice(8; seed=CONT_SEED, replications=32);
                        d_coarsest=2, start_price=30.0, strike_price=30.0)

    return [
        (name="CubMCCLTVec",
         loose=() -> CubMCCLTVec(iid_k(); abs_tol=5e-2, n_init=256, n_max=2^24, trace_iterations=true),
         tight=() -> CubMCCLTVec(iid_k(); abs_tol=2.5e-2, n_init=256, n_max=2^24, trace_iterations=true),
         tol="abs_tol"),

        (name="CubQMCLatticeG",
         loose=() -> CubQMCLatticeG(lat_k(); abs_tol=5e-3, n_max=2^20, trace_iterations=true),
         tight=() -> CubQMCLatticeG(lat_k(); abs_tol=1e-3, n_max=2^20, trace_iterations=true),
         tol="abs_tol"),

        (name="CubQMCNetG",
         loose=() -> CubQMCNetG(net_k(); abs_tol=5e-3, n_max=2^22, trace_iterations=true),
         tight=() -> CubQMCNetG(net_k(); abs_tol=1e-3, n_max=2^22, trace_iterations=true),
         tol="abs_tol"),

        (name="CubQMCNetGRep",
         loose=() -> CubQMCNetGRep(net5_k(); abs_tol=5e-2, n_init=32, n_reps=16, trace_iterations=true),
         tight=() -> CubQMCNetGRep(net5_k(); abs_tol=1e-2, n_init=32, n_reps=16, trace_iterations=true),
         tol="abs_tol"),

        (name="CubQMCBayesLatticeG",
         loose=() -> CubQMCBayesLatticeG(blat_k(); abs_tol=5e-2, n_init=32, n_max=2^24, trace_iterations=true),
         tight=() -> CubQMCBayesLatticeG(blat_k(); abs_tol=5e-4, n_init=32, n_max=2^24, trace_iterations=true),
         tol="abs_tol"),

        (name="CubQMCBayesNetG",
         loose=() -> CubQMCBayesNetG(net_k(); abs_tol=1e-1, n_init=32, n_max=2^24, trace_iterations=true),
         tight=() -> CubQMCBayesNetG(net_k(); abs_tol=3e-3, n_init=32, n_max=2^24, trace_iterations=true),
         tol="abs_tol"),

        (name="CubMLMC",
         loose=() -> CubMLMC(ml_iid(); abs_tol=0.2, n_limit=2^20, trace_iterations=true),
         tight=() -> CubMLMC(ml_iid(); abs_tol=0.1, n_limit=2^20, trace_iterations=true),
         tol="rmse_tol"),

        (name="CubMLMCCont",
         loose=() -> CubMLMCCont(ml_iid2(); abs_tol=0.4, n_tols=6, n_limit=2^20, trace_iterations=true),
         tight=() -> CubMLMCCont(ml_iid2(); abs_tol=0.3, n_tols=6, n_limit=2^20, trace_iterations=true),
         tol="rmse_tol"),

        (name="CubMLQMC",
         loose=() -> CubMLQMC(ml_qmc(); abs_tol=0.2, n_limit=2^22, trace_iterations=true),
         tight=() -> CubMLQMC(ml_qmc(); abs_tol=0.1, n_limit=2^22, trace_iterations=true),
         tol="rmse_tol"),

        (name="CubMLQMCCont",
         loose=() -> CubMLQMCCont(ml_qmc2(); abs_tol=0.6, n_tols=6, n_limit=2^18, trace_iterations=true),
         tight=() -> CubMLQMCCont(ml_qmc2(); abs_tol=0.3, n_tols=6, n_limit=2^18, trace_iterations=true),
         tol="rmse_tol"),
    ]
end

function main()
    output_dir = joinpath(@__DIR__, "output")
    mkpath(output_dir)

    cases_config = _build_cases()
    results = [run_case(c.name, c.loose, c.tight; tol_name=c.tol) for c in cases_config]

    out_path = joinpath(output_dir, "check_resume_summary.txt")
    write_combined_report(out_path, "Stopping Criteria Check: Resume vs Fresh", results)
end

main()
