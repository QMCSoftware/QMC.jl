using Test
using QMC
using Statistics
using LinearAlgebra
using Distributions
# Resolve name conflicts: prefer QMC's versions in tests
import QMC: Uniform, Kumaraswamy

const TEST_FILES = [
    "test_discrete_distributions.jl",
    "test_true_measures.jl",
    "test_integrands.jl",
    "test_kernels.jl",
    "test_stopping_criteria.jl",
    "test_integration.jl",
    "test_multilevel.jl",
    "test_aqua.jl",
]

"Format a duration in seconds as a short string."
function fmt_duration(s::Real)
    if s >= 60
        m = floor(Int, s / 60)
        return "$(m)m $(round(s - 60m; digits = 1))s"
    else
        return "$(round(s; digits = 2))s"
    end
end

times = Dict{String, Float64}()

@testset "QMC" begin
    for test_file in TEST_FILES
        elapsed = @elapsed include(test_file)
        times[test_file] = elapsed
        println("  ⏱  $(test_file): $(fmt_duration(elapsed))")
    end
end

total_time = sum(values(times); init = 0.0)
println("Ran $(length(TEST_FILES)) test file(s) in $(fmt_duration(total_time)).")
