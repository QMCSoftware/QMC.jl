module BenchmarkEnvBootstrap

using Pkg

const _STALE_MANIFEST_SNIPPETS = (
    "does not appear in the manifest",
    "dependencies or compat requirements have changed since the manifest was last resolved",
)

function _stale_manifest_error(err)
    msg = sprint(showerror, err)
    return any(snippet -> occursin(snippet, msg), _STALE_MANIFEST_SNIPPETS)
end

"""
    bootstrap_benchmark_env(project_dir; io=stderr)

Activate and synchronize the benchmark environment.

This handles two common cases:

- a fresh environment where `instantiate()` needs to materialize registries
- a local stale `Manifest.toml` after the root package gains a new direct dependency
"""
function bootstrap_benchmark_env(project_dir::AbstractString; io::IO=stderr)
    Pkg.activate(project_dir; io)
    try
        Pkg.instantiate(; io)
    catch err
        _stale_manifest_error(err) || rethrow()
    end

    Pkg.resolve(; io)
    Pkg.instantiate(; io)
    Pkg.build("QMCToolsCL_jll"; io)
    return nothing
end

end
