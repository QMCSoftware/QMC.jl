using Pkg

# Refresh the staged in-repo JLL path dependency before instantiating so the
# active Julia rewrites any stale stdlib entries in the root manifest.
cd(joinpath(@__DIR__, "..")) do
    Pkg.develop(Pkg.PackageSpec(path="jll/QMCToolsCL_jll"))
    Pkg.resolve()
    Pkg.instantiate()
    Pkg.build("QMCToolsCL_jll")
end
