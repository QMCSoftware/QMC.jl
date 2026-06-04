using Aqua
using QMC

@testset "Aqua.jl Quality Tests" begin
    Aqua.test_all(
        QMC;
        ambiguities=false,       # skip for now — many methods with Union types
        stale_deps=(ignore=[:NBInclude],),  # used by test/run_notebooks.jl, not src/
        deps_compat=true,
        piracies=false,          # we extend Base.push! for IterationLog
        project_extras=true,
        unbound_args=true,
        undefined_exports=true,
        persistent_tasks=false,
    )
end
