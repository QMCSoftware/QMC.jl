module QMC

using LinearAlgebra, Libdl, Random, Statistics, FFTW, SpecialFunctions, Distributions, Printf

# Utilities
include("util/bernoulli.jl")
include("util/transforms.jl")
include("util/fwht.jl")
include("util/periodization.jl")

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

# Multilevel Integrand Interface
include("integrand/ml_integrand.jl")

# Kernels
include("kernel/shift_invariant.jl")
include("kernel/dig_shift_invariant.jl")
include("kernel/matern.jl")

# Stopping Criteria
include("stopping_criterion/cub_mc_clt.jl")
include("stopping_criterion/cub_qmc_lattice_g.jl")
include("stopping_criterion/cub_qmc_net_g.jl")
include("stopping_criterion/cub_qmc_bayes_lattice_g.jl")
include("stopping_criterion/cub_qmc_bayes_net_g.jl")
include("stopping_criterion/cub_mlmc.jl")
include("stopping_criterion/cub_mlmc_cont.jl")
include("stopping_criterion/cub_mlqmc_cont.jl")

function __init__()
    _init_qmctoolscl!(; warn_on_failure = false)
end

# Exports — abstract types
export AbstractDiscreteDistribution, AbstractTrueMeasure, AbstractIntegrand
export AbstractStoppingCriterion, AbstractKernel, AbstractStationaryKernel
export AbstractMLIntegrand

# Exports — discrete distributions
export IIDStdUniform, Lattice, DigitalNetB2, Halton

# Exports — true measures
export Uniform, Gaussian, BrownianMotion, Lebesgue
export GeometricBrownianMotion, StudentT, Triangular
export Kumaraswamy, JohnsonsSU, BernoulliCont

# Exports — integrands
export CustomFun, Keister, Genz, AsianOption, FinancialOption
export BoxIntegral, Linear0, Sin1D, Ishigami, Hartmann6D
export Multimodal2D, FourBranch2D

# Exports — kernels
export KernelShiftInvar, KernelDigShiftInvar
export KernelMatern12, KernelMatern32, KernelMatern52, KernelGaussian
export SumKernel, ProductKernel, kernel_eval, kernel_matrix

# Exports — stopping criteria
export CubMCCLT, CubQMCLatticeG, CubQMCNetG
export CubQMCBayesLatticeG, CubQMCBayesNetG
export CubMLMC, CubMLMCCont, CubMLQMCCont

# Exports — interface functions
export integrate, gen_samples, transform, evaluate, sample_and_evaluate
export QMCResult, compute_kernel_eigenvalues
export ml_evaluate, dimension_at_level, cost_at_level
export spawn_dd, spawn_tm, spawn_integrand
export ml_sample_and_evaluate, ml_sample_and_evaluate_reps

# Exports — utilities
export bernoulli_poly, to_bin, to_float, fwht!, fwht, ifwht!
export keister_exact, genz_exact, periodize

end
