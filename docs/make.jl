using Documenter
using QMC

rm(joinpath(@__DIR__, "build"); force=true, recursive=true)

makedocs(
    sitename = "QMC.jl",
    authors = "Sou-Cheng T. Choi, Fred J. Hickernell, Aleksei Sorokin, and contributors",
    modules = [QMC],
    doctest = ("doctest=fix" in ARGS) ? :fix : ("doctest=only" in ARGS) ? :only : true,
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
        "Architecture" => "architecture.md",
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
        "Release Policy" => "releasing.md",
        "CI/CD Testing" => "ci-testing.md",
        "Workflow Debugging" => "workflow-debugging.md",
        "Contributing" => "contributing.md",
        "Community" => "community.md",
    ],
)

# Only deploy from CI
if get(ENV, "CI", nothing) == "true" && get(ENV, "GITHUB_EVENT_NAME", nothing) == "push"
    deploydocs(
        repo = "github.com/QMCSoftware/QMC.jl.git",
        devbranch = "develop",
        push_preview = true,
    )
end
