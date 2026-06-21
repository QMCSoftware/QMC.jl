module QMC

using LinearAlgebra,
    Libdl, Random, Statistics, FFTW, SpecialFunctions, Distributions, Printf, Downloads

# Utilities
include("util/bernoulli.jl")
include("util/transforms.jl")
include("util/fwht.jl")
include("util/periodization.jl")
include("util/diagnostics.jl")
include("util/latnetbuilder_linker.jl")
include("util/bro_fft.jl")
include("util/gpu_backend.jl")

# Abstract types
include("abstract_types.jl")

# Data files (generating vectors, direction numbers)
include("data/kuo_lattice_gen_vector.jl")
include("data/joe_kuo_direction_numbers.jl")

# Discrete Distributions
include("discrete_distribution/qmctoolscl_c.jl")
include("discrete_distribution/iid_std_uniform.jl")
include("discrete_distribution/lattice.jl")
include("discrete_distribution/digital_net_b2.jl")
include("discrete_distribution/halton.jl")
include("discrete_distribution/kronecker.jl")
include("discrete_distribution/digital_net_any_bases.jl")

# True Measures
include("true_measure/uniform.jl")
include("true_measure/gaussian.jl")
include("true_measure/brownian_motion.jl")
include("true_measure/lebesgue.jl")
include("true_measure/geometric_brownian_motion.jl")
include("true_measure/student_t.jl")
include("true_measure/triangular.jl")
include("true_measure/kumaraswamy.jl")
include("true_measure/johnsons_su.jl")
include("true_measure/bernoulli_cont.jl")
include("true_measure/acceptance_rejection.jl")
include("true_measure/distributions_wrapper.jl")
include("true_measure/matern_gp.jl")
include("true_measure/uniform_triangle.jl")
include("true_measure/zero_inflated_exp_uniform.jl")

# Integrands
include("integrand/custom_fun.jl")
include("integrand/keister.jl")
include("integrand/genz.jl")
include("integrand/asian_option.jl")
include("integrand/financial_option.jl")
include("integrand/box_integral.jl")
include("integrand/linear0.jl")
include("integrand/sin1d.jl")
include("integrand/ishigami.jl")
include("integrand/hartmann6d.jl")
include("integrand/multimodal2d.jl")
include("integrand/four_branch2d.jl")
include("integrand/sensitivity_indices.jl")
include("integrand/bayesian_lr_coeffs.jl")
include("integrand/umbridge_wrapper.jl")

# Multilevel Integrand Interface
include("integrand/ml_integrand.jl")
include("integrand/financial_option_ml.jl")
include("util/mlmc_test.jl")

# Kernels
include("kernel/shift_invariant.jl")
include("kernel/dig_shift_invariant.jl")
include("kernel/matern.jl")
include("kernel/multitask.jl")
include("kernel/si_dsi_value_kernels.jl")
include("kernel/si_deriv_kernel.jl")
include("kernel/dsi_deriv_kernel.jl")
include("kernel/multitask_derivs.jl")

# Stopping Criteria
include("stopping_criterion/control_variates.jl")
include("stopping_criterion/cub_mc_clt.jl")
include("stopping_criterion/cub_qmc_lattice_g.jl")
include("stopping_criterion/cub_qmc_net_g.jl")
include("stopping_criterion/cub_qmc_net_g_rep.jl")
include("stopping_criterion/cub_qmc_bayes_lattice_g.jl")
include("stopping_criterion/cub_qmc_bayes_net_g.jl")
include("stopping_criterion/cub_mlmc.jl")
include("stopping_criterion/cub_mlmc_cont.jl")
include("stopping_criterion/cub_mc_g.jl")
include("stopping_criterion/cub_mlqmc_cont.jl")
include("stopping_criterion/cub_mlqmc.jl")
include("stopping_criterion/cub_mc_clt_vec.jl")
include("stopping_criterion/cub_qmc_rep_student_t.jl")
include("stopping_criterion/pf_gp_ci.jl")

__init__() = _init_qmctoolscl!(; warn_on_failure=false)

# Exports — abstract types
export AbstractDiscreteDistribution, AbstractTrueMeasure, AbstractIntegrand
export AbstractStoppingCriterion, AbstractKernel, AbstractStationaryKernel
export AbstractMLIntegrand

# Exports — discrete distributions
export IIDStdUniform, Lattice, DigitalNetB2, Halton, Kronecker
export DigitalNetAnyBases, Faure

# Exports — true measures
export Uniform, Gaussian, BrownianMotion, Lebesgue
export GeometricBrownianMotion, StudentT, Triangular
export Kumaraswamy, JohnsonsSU, BernoulliCont
export AcceptanceRejection, AcceptanceRejectionReal, DistributionsWrapper
export MaternGP, UniformTriangle, ZeroInflatedExpUniform

# Exports — integrands
export CustomFun, Keister, Genz, AsianOption, FinancialOption, FinancialOptionML
export BoxIntegral, Linear0, Sin1D, Ishigami, Hartmann6D
export Multimodal2D, FourBranch2D
export SensitivityIndices, compute_sensitivity_indices, BayesianLRCoeffs
export UMBridgeWrapper

# Exports — kernels
export KernelShiftInvar, KernelDigShiftInvar
export KernelMatern12, KernelMatern32, KernelMatern52, KernelGaussian
export KernelRationalQuadratic
export KernelSquaredExponential
export SumKernel, ProductKernel, kernel_eval, kernel_matrix
export KernelMultiTask
export KernelShiftInvarCombined, KernelDigShiftInvarAdaptiveAlpha, KernelDigShiftInvarCombined
export KernelShiftInvarDeriv, kernel_eval_deriv
export KernelDigShiftInvarDeriv, KernelMultiTaskDerivs

# Exports — stopping criteria
export CubMCCLT, CubQMCLatticeG, CubQMCNetG, CubQMCNetGRep, CubQMCNetGSingle
export CubQMCBayesLatticeG, CubQMCBayesNetG
export CubMCG
export CubMCCLTVec
export CubMLMC, CubMLMCCont, CubMLQMC, CubMLQMCCont
export CubQMCRepStudentT, PFGPCI

# Exports — interface functions
export integrate, gen_samples, transform, evaluate, sample_and_evaluate
export set_tolerance!
export QMCResult, QMCVecResult, compute_kernel_eigenvalues
export get_exact_value
export ml_evaluate, dimension_at_level, cost_at_level
export spawn_dd, spawn_tm, spawn_integrand
export ml_sample_and_evaluate, ml_sample_and_evaluate_reps

# Exports — utilities
export bernoulli_poly, to_bin, to_float, fwht!, fwht, ifwht!
export DisplayTable, display_table, IterationLog, iterations
export latnetbuilder_linker, mlmc_test
export bro_fft, bro_ifft, gpu_fwht, gpu_fwht!
export keister_exact, genz_exact, periodize

end
