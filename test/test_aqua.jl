using QuasiMC
using Pkg
using Aqua

@testset "Aqua.jl Quality Tests" begin
    Aqua.test_all(
        QuasiMC;
        ambiguities=false,       # skip for now — many methods with Union types
        stale_deps=(ignore=[:Downloads],),  # Downloads is loaded dynamically via Base.require for remote LDData fetches.
        deps_compat=true,
        piracies=false,          # we extend Base.push! for IterationLog
        project_extras=true,
        unbound_args=true,
        undefined_exports=true,
        persistent_tasks=false,
    )
end
