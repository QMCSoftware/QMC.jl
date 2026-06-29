module QMCToolsCL_jll

const _statefile = joinpath(@__DIR__, "..", "deps", "build_state.txt")
libqmctoolscl = ""
qmctoolscl_version = "1.2.3"

function _load_state!()
    global libqmctoolscl, qmctoolscl_version
    isfile(_statefile) || return false
    for raw_line in eachline(_statefile)
        line = strip(raw_line)
        isempty(line) && continue
        startswith(line, '#') && continue
        parts = split(line, '='; limit=2)
        length(parts) == 2 || continue
        key = strip(parts[1])
        value = strip(parts[2])
        if key == "libqmctoolscl"
            libqmctoolscl = value
        elseif key == "qmctoolscl_version"
            qmctoolscl_version = value
        end
    end
    return !isempty(libqmctoolscl)
end

function __init__()
    _load_state!()
    isempty(libqmctoolscl) && return
    isfile(libqmctoolscl) || error(
        "QMCToolsCL_jll expected a library at $(repr(libqmctoolscl)), but no file was found. " *
        "Run `import Pkg; Pkg.build(\"QMCToolsCL_jll\")`.",
    )
end

_load_state!()

export libqmctoolscl, qmctoolscl_version

end
