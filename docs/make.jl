using Documenter
using QMC

makedocs(
    sitename = "QMC.jl",
    authors = "Sou-Cheng T. Choi, Fred J. Hickernell, Aleksei Sorokin, and contributors",
    modules = [QMC],
    remotes = nothing,
    format = Documenter.HTML(
        prettyurls = get(ENV, "CI", nothing) == "true",
        canonical = "https://qmcsoftware.github.io/QMC.jl/",
        repolink = "https://github.com/QMCSoftware/QMC.jl",
        edit_link = nothing,
        assets = String[],
    ),
    pages = [
        "Home" => "index.md",
        "Components" => "components.md",
        "API Reference" => [
            "Discrete Distributions" => "api/discrete_distributions.md",
            "True Measures" => "api/true_measures.md",
            "Integrands" => "api/integrands.md",
            "Kernels" => "api/kernels.md",
            "Stopping Criteria" => "api/stopping_criteria.md",
            "Utilities" => "api/utilities.md",
            "Internals" => "api/internals.md",
        ],
        "Demos" => "demos.md",
        "CI/CD Testing" => "ci-testing.md",
        "Contributing" => "contributing.md",
        "Community" => "community.md",
    ],
)

# Only deploy from CI
if get(ENV, "CI", nothing) == "true"
    deploydocs(
        repo = "github.com/QMCSoftware/QMC.jl.git",
        devbranch = "develop",
        push_preview = true,
    )
end
