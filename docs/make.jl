using Documenter
using QMCJu

makedocs(
    sitename = "QMCJu.jl",
    authors = "Sou-Cheng T. Choi, Fred J. Hickernell, Aleksei Sorokin, and contributors",
    modules = [QMCJu],
    remotes = nothing,
    format = Documenter.HTML(
        prettyurls = get(ENV, "CI", nothing) == "true",
        canonical = "https://qmcsoftware.github.io/qmcju.jl/",
        repolink = "https://github.com/QMCSoftware/qmcju.jl",
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
        "Contributing" => "contributing.md",
        "Community" => "community.md",
    ],
)

# Only deploy from CI
if get(ENV, "CI", nothing) == "true"
    deploydocs(
        repo = "github.com/QMCSoftware/qmcju.jl.git",
        devbranch = "develop",
        push_preview = true,
    )
end
