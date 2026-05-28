using Test
using QMC
using Statistics
using LinearAlgebra
using Distributions
# Resolve name conflicts: prefer QMC's versions in tests
import QMC: Uniform, Kumaraswamy

@testset "QMC" begin
    include("test_discrete_distributions.jl")
    include("test_true_measures.jl")
    include("test_integrands.jl")
    include("test_kernels.jl")
    include("test_stopping_criteria.jl")
    include("test_integration.jl")
end
