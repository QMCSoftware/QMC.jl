using QuasiMC
using Pkg
using Aqua

@testset "Aqua.jl Quality Tests" begin
    Aqua.test_all(
        QuasiMC;
        ambiguities=false,       # skip for now — many methods with Union types
        stale_deps=(ignore=[:Downloads, :NBInclude],),  # Downloads: loaded dynamically for remote LDData fetches. NBInclude: used in test/run_notebooks.jl (invoked with --project=., not Pkg.test), not in src/.
        deps_compat=true,
        piracies=false,          # we extend Base.push! for IterationLog
        project_extras=true,
        unbound_args=true,
        undefined_exports=true,
        persistent_tasks=false,
    )
end
