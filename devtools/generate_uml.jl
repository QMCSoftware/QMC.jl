#!/usr/bin/env julia

"""
Generate UML-style class diagrams for QuasiMC.jl source types.

The script scans `src/` for `abstract type`, `struct`, and `mutable struct`
definitions, extracts subtype relations plus selected field-based associations,
and writes Graphviz DOT plus rendered PNG diagrams.

Usage:
    julia --project=. devtools/generate_uml.jl
    julia --project=. devtools/generate_uml.jl --src=src --out=docs/src/assets/uml
    julia --project=. devtools/generate_uml.jl --no-render
"""

struct FieldInfo
    name::String
    type_expr::String
end

struct TypeInfo
    name::String
    kind::Symbol
    category::String
    file::String
    line::Int
    parent::Union{Nothing, String}
    fields::Vector{FieldInfo}
    type_param_bounds::Dict{String, Union{Nothing, String}}
end

const RENDER_EXT = "png"

const BUILTIN_TYPE_NAMES = Set([
    "Any",
    "AbstractArray",
    "AbstractDict",
    "AbstractFloat",
    "AbstractMatrix",
    "AbstractRNG",
    "AbstractString",
    "AbstractVector",
    "Array",
    "Base",
    "Bool",
    "Char",
    "Dict",
    "Float16",
    "Float32",
    "Float64",
    "Function",
    "IO",
    "Int",
    "Int32",
    "Int64",
    "Integer",
    "LinearAlgebra",
    "Matrix",
    "NamedTuple",
    "Nothing",
    "NTuple",
    "Ptr",
    "Random",
    "Real",
    "Ref",
    "Set",
    "String",
    "Symbol",
    "Tuple",
    "UInt",
    "UInt32",
    "UInt64",
    "Union",
    "Vector",
    "Vararg",
])

function parse_args(args::Vector{String})
    script_dir = @__DIR__
    repo_root = normpath(joinpath(script_dir, ".."))
    src_dir = joinpath(repo_root, "src")
    out_dir = joinpath(repo_root, "docs", "src", "assets", "uml")
    render = true
    for arg in args
        if startswith(arg, "--src=")
            src_dir = normpath(joinpath(repo_root, split(arg, "="; limit=2)[2]))
        elseif startswith(arg, "--out=")
            out_dir = normpath(joinpath(repo_root, split(arg, "="; limit=2)[2]))
        elseif arg == "--no-render"
            render = false
        else
            error("Unknown argument: $arg")
        end
    end
    return (; repo_root, src_dir, out_dir, render)
end

function category_for(relpath::String)
    parts = split(relpath, '/')
    length(parts) == 1 && return "core"
    return parts[1]
end

function parse_type_param_bounds(raw::Union{Nothing, AbstractString})
    bounds = Dict{String, Union{Nothing, String}}()
    isnothing(raw) && return bounds
    for piece in split(raw, ',')
        token = strip(piece)
        isempty(token) && continue
        m = match(r"^([A-Za-z_]\w*)\s*<:\s*([A-Za-z_]\w*)$", token)
        if m !== nothing
            bounds[m.captures[1]] = m.captures[2]
        else
            bounds[token] = nothing
        end
    end
    return bounds
end

function brace_balance_delta(text::AbstractString)
    opens = count(==('{'), text)
    closes = count(==('}'), text)
    return opens - closes
end

function parse_types(src_dir::String)
    types = Dict{String, TypeInfo}()
    ordered_names = String[]
    for (root, _, files) in walkdir(src_dir)
        for file in sort(files)
            endswith(file, ".jl") || continue
            file == "QuasiMC.jl" && continue
            fullpath = joinpath(root, file)
            relative_path = Base.Filesystem.relpath(fullpath, src_dir)
            category = category_for(relative_path)
            lines = readlines(fullpath)
            i = 1
            while i <= length(lines)
                line = lines[i]
                abs_match = match(
                    r"^\s*abstract\s+type\s+([A-Za-z_]\w*)(?:\s*<:\s*([A-Za-z_]\w*))?",
                    line,
                )
                if abs_match !== nothing
                    name = abs_match.captures[1]
                    parent = abs_match.captures[2]
                    info = TypeInfo(
                        name,
                        :abstract,
                        category,
                        relative_path,
                        i,
                        parent,
                        FieldInfo[],
                        Dict{String, Union{Nothing, String}}(),
                    )
                    types[name] = info
                    push!(ordered_names, name)
                    i += 1
                    continue
                end

                struct_match = match(
                    r"^\s*(mutable\s+)?struct\s+([A-Za-z_]\w*)(?:\{([^}]*)\})?(?:\s*<:\s*([A-Za-z_]\w*))?",
                    line,
                )
                if struct_match !== nothing
                    mutable_kw = struct_match.captures[1]
                    name = struct_match.captures[2]
                    params_raw = struct_match.captures[3]
                    parent = struct_match.captures[4]
                    fields = FieldInfo[]
                    j = i + 1
                    while j <= length(lines)
                        inner = lines[j]
                        stripped = strip(inner)
                        if stripped == "end"
                            break
                        end
                        field_match = match(r"^\s*([A-Za-z_]\w*)\s*::\s*(.+?)\s*$", inner)
                        if field_match !== nothing
                            field_name = field_match.captures[1]
                            field_type = replace(field_match.captures[2], r"\s+#.*$" => "")
                            balance = brace_balance_delta(field_type)
                            while balance > 0 && j < length(lines)
                                j += 1
                                continuation = strip(replace(lines[j], r"\s+#.*$" => ""))
                                isempty(continuation) && continue
                                field_type *= " " * continuation
                                balance += brace_balance_delta(continuation)
                            end
                            field_type = replace(field_type, r",$" => "")
                            field_type = replace(field_type, r"\s+" => " ")
                            push!(fields, FieldInfo(field_name, strip(field_type)))
                        end
                        j += 1
                    end
                    kind = isnothing(mutable_kw) ? :struct : :mutable_struct
                    info = TypeInfo(
                        name,
                        kind,
                        category,
                        relative_path,
                        i,
                        parent,
                        fields,
                        parse_type_param_bounds(params_raw),
                    )
                    types[name] = info
                    push!(ordered_names, name)
                    i = min(j + 1, length(lines) + 1)
                    continue
                end
                i += 1
            end
        end
    end
    return types, ordered_names
end

function normalized_targets(field::FieldInfo, info::TypeInfo, known_names::Set{String})
    targets = String[]
    seen = Set{String}()
    for token_match in eachmatch(r"[A-Za-z_]\w*", field.type_expr)
        token = token_match.match
        if haskey(info.type_param_bounds, token)
            bound = info.type_param_bounds[token]
            if !isnothing(bound) && bound in known_names && !(bound in seen)
                push!(targets, bound)
                push!(seen, bound)
            end
        elseif token in known_names && token != info.name && !(token in seen)
            push!(targets, token)
            push!(seen, token)
        elseif token in BUILTIN_TYPE_NAMES
            continue
        end
    end
    return targets
end

function collect_associations(types::Dict{String, TypeInfo})
    known_names = Set(keys(types))
    edges = NamedTuple{(:src, :dst, :label), Tuple{String, String, String}}[]
    seen = Set{Tuple{String, String, String}}()
    for info in values(types)
        for field in info.fields
            for target in normalized_targets(field, info, known_names)
                edge = (info.name, target, field.name)
                if !(edge in seen)
                    push!(edges, (; src=info.name, dst=target, label=field.name))
                    push!(seen, edge)
                end
            end
        end
    end
    return edges
end

function dot_escape(text::String)
    escaped = replace(text, "\"" => "\\\"")
    return escaped
end

function simplify_type_expr(type_expr::String)
    text = strip(type_expr)
    text = replace(text, "Distributions." => "")
    text = replace(text, "LinearAlgebra." => "")
    text = replace(text, "Union{Nothing, " => "Optional{")
    text = replace(text, "Vector{Float64}" => "Vec{F64}")
    text = replace(text, "Vector{Int}" => "Vec{Int}")
    text = replace(text, "Vector{Bool}" => "Vec{Bool}")
    text = replace(text, "Vector{String}" => "Vec{Str}")
    text = replace(text, "Vector{UInt64}" => "Vec{U64}")
    text = replace(text, "Vector{UnivariateDistribution}" => "Vec{Distribution}")
    text = replace(text, "Vector{AbstractIntegrand}" => "Vec{AbsInt}")
    text = replace(text, "Vector{Vector{Float64}}" => "Vec{Vec{F64}}")
    text = replace(text, "Matrix{Float64}" => "Mat{F64}")
    text = replace(text, "Matrix{Bool}" => "Mat{Bool}")
    text = replace(text, "Array{Float64}" => "Array{F64}")
    text = replace(text, "Array{Int, 3}" => "Array3{Int}")
    text = replace(text, "Dict{Symbol, Any}" => "Dict")
    text = replace(text, "Dict{String, Any}" => "Dict")
    text = replace(text, "LowerTriangular{Float64, Matrix{Float64}}" => "LowerTriangular")
    text = replace(text, r"Vector\{NamedTuple\{.*\}\}" => "Vec{NamedTuple}")
    text = replace(text, r"NTuple\{(\d+),\s*Float64\}" => s"NTuple{\1, F64}")
    text = replace(text, r"Optional\{Vector\{UInt64\}\}" => "Optional{Vec{U64}}")
    text = replace(text, r"Optional\{Vector\{.*\}\}" => "Optional{Vec{...}}")
    text = replace(text, "AbstractDiscreteDistribution" => "AbsDD")
    text = replace(text, "AbstractTrueMeasure" => "AbsTM")
    text = replace(text, "AbstractIntegrand" => "AbsInt")
    text = replace(text, "AbstractStoppingCriterion" => "AbsStop")
    text = replace(text, "AbstractKernel" => "AbsKernel")
    text = replace(text, "AbstractMLIntegrand" => "AbsMLInt")
    text = replace(text, "Float64" => "F64")
    text = replace(text, "String" => "Str")
    text = replace(text, "Nothing" => "None")
    if occursin("NamedTuple{", text)
        text = "NamedTuple"
    elseif length(text) > 36 && occursin("Vector{", text)
        text = replace(text, r"Vector\{.*\}" => "Vec{...}")
    elseif length(text) > 36 && occursin("Array{", text)
        text = replace(text, r"Array\{.*\}" => "Array{...}")
    end
    return text
end

function node_label(info::TypeInfo; detailed::Bool)
    lines = String[info.name]
    if info.kind == :abstract
        nothing
    elseif info.kind == :mutable_struct
        push!(lines, "(mutable struct)")
    else
        push!(lines, "(struct)")
    end
    if !detailed
        return join(lines, "\\n")
    end
    return join(lines, "\\n")
end

function write_dot_file(
    path::String,
    diagram_name::String,
    node_names::Vector{String},
    types::Dict{String, TypeInfo},
    associations;
    detailed::Bool,
)
    inheritance = [
        (name, types[name].parent) for name in node_names if !isnothing(types[name].parent)
    ]
    open(path, "w") do io
        println(io, "digraph \"$(diagram_name)\" {")
        println(io, "  rankdir=LR;")
        println(io, "  graph [fontname=\"Helvetica\", fontsize=10, overlap=false, splines=true];")
        println(io, "  node [fontname=\"Helvetica\", fontsize=10, shape=box, style=\"rounded\", margin=0.12];")
        println(io, "  edge [fontname=\"Helvetica\", fontsize=9];")
        println(io)
        for name in node_names
            info = types[name]
            style = info.kind == :abstract ? ", style=\"rounded,dashed\"" : ""
            println(io, "  \"$(name)\" [label=\"$(dot_escape(node_label(info; detailed=detailed)))\"$(style)];")
        end
        println(io)
        for (child, parent) in inheritance
            if parent in node_names
                println(
                    io,
                    "  \"$(child)\" -> \"$(parent)\" [arrowhead=empty, color=\"#38598c\", penwidth=1.4];",
                )
            end
        end
        for edge in associations
            if edge.src in node_names && edge.dst in node_names
                println(
                    io,
                    "  \"$(edge.src)\" -> \"$(edge.dst)\" [label=\"$(dot_escape(edge.label))\", color=\"#777777\", style=dashed, arrowhead=vee];",
                )
            end
        end
        println(io, "}")
    end
end

function mermaid_label(info::TypeInfo; detailed::Bool)
    lines = String[]
    if info.kind == :abstract
        push!(lines, "<<abstract>>")
    elseif info.kind == :mutable_struct
        push!(lines, "<<mutable struct>>")
    else
        push!(lines, "<<struct>>")
    end
    if detailed
        for field in first(info.fields, min(length(info.fields), 10))
            push!(lines, "$(field.name) : $(field.type_expr)")
        end
        if length(info.fields) > 10
            push!(lines, "...")
        end
    end
    return lines
end

function write_mermaid_file(
    path::String,
    node_names::Vector{String},
    types::Dict{String, TypeInfo},
    associations;
    detailed::Bool,
)
    open(path, "w") do io
        println(io, "classDiagram")
        for name in node_names
            println(io, "  class $(name)")
            for line in mermaid_label(types[name]; detailed=detailed)
                println(io, "  $(name) : $(line)")
            end
        end
        for name in node_names
            parent = types[name].parent
            if !isnothing(parent) && parent in node_names
                println(io, "  $(parent) <|-- $(name)")
            end
        end
        for edge in associations
            if edge.src in node_names && edge.dst in node_names
                println(io, "  $(edge.src) --> $(edge.dst) : $(edge.label)")
            end
        end
    end
end

function render_image(dot_path::String)
    image_path = replace(dot_path, r"\.dot$" => ".$(RENDER_EXT)")
    try
        run(`dot -T$(RENDER_EXT) $dot_path -o $image_path`)
        return true
    catch err
        @warn "Failed to render $image_path with Graphviz" exception=(err, catch_backtrace())
        return false
    end
end

function related_node_set(base_nodes::Vector{String}, types::Dict{String, TypeInfo}, associations)
    keep = Set(base_nodes)
    changed = true
    while changed
        changed = false
        for name in collect(keep)
            parent = types[name].parent
            if !isnothing(parent) && haskey(types, parent) && !(parent in keep)
                push!(keep, parent)
                changed = true
            end
        end
        for edge in associations
            if edge.src in keep && !(edge.dst in keep)
                push!(keep, edge.dst)
                changed = true
            elseif edge.dst in keep && !(edge.src in keep)
                push!(keep, edge.src)
                changed = true
            end
        end
    end
    return sort!(collect(keep))
end

function category_diagram_nodes(
    category::String,
    base_nodes::Vector{String},
    types::Dict{String, TypeInfo},
    associations,
)
    keep = Set(base_nodes)

    # Always include parent abstractions so subtype trees stay legible.
    changed = true
    while changed
        changed = false
        for name in collect(keep)
            parent = types[name].parent
            if !isnothing(parent) && haskey(types, parent) && !(parent in keep)
                push!(keep, parent)
                changed = true
            end
        end
    end

    # Pull in only direct dependency targets from this subsystem, not reverse or
    # transitive closures. This keeps diagrams like true_measure focused.
    for edge in associations
        if edge.src in keep && haskey(types, edge.dst)
            dst_info = types[edge.dst]
            if dst_info.category == category || dst_info.category == "core" ||
               edge.dst in ("AbstractDiscreteDistribution", "AbstractTrueMeasure", "AbstractIntegrand")
                push!(keep, edge.dst)
            end
        end
    end

    return sort!(collect(keep))
end

function category_associations(node_names::Vector{String}, base_nodes::Vector{String}, associations)
    node_set = Set(node_names)
    base_set = Set(base_nodes)
    filtered = eltype(associations)[]
    for edge in associations
        edge.src in base_set || continue
        if edge.dst in node_set
            push!(filtered, edge)
        end
    end
    return filtered
end

function write_manifest(out_dir::String, diagrams)
    manifest_path = joinpath(out_dir, "README.md")
    open(manifest_path, "w") do io
        println(io, "# Generated UML Diagrams")
        println(io)
        println(io, "These files are generated by `devtools/generate_uml.jl` from `src/`.")
        println(io, "Regenerate them with `make uml` after code changes.")
        println(io)
        for (name, description) in diagrams
            println(io, "- `$(name).dot` / `$(name).mmd` / `$(name).$(RENDER_EXT)`: $(description)")
        end
    end
end

function cleanup_generated(out_dir::String)
    isdir(out_dir) || return
    for entry in readdir(out_dir; join=true)
        if isfile(entry)
            _, ext = splitext(entry)
            if ext in (".dot", ".mmd", ".svg", ".png", ".md")
                rm(entry; force=true)
            end
        end
    end
end

function main()
    cfg = parse_args(ARGS)
    mkpath(cfg.out_dir)
    cleanup_generated(cfg.out_dir)
    types, ordered_names = parse_types(cfg.src_dir)
    isempty(types) && error("No type definitions found under $(cfg.src_dir)")
    associations = collect_associations(types)

    categories = sort!(unique(info.category for info in values(types)))
    diagrams = Pair{String, String}[]

    overview_nodes = copy(ordered_names)
    overview_name = "overview"
    write_dot_file(
        joinpath(cfg.out_dir, "$(overview_name).dot"),
        overview_name,
        overview_nodes,
        types,
        associations;
        detailed=false,
    )
    write_mermaid_file(
        joinpath(cfg.out_dir, "$(overview_name).mmd"),
        overview_nodes,
        types,
        associations;
        detailed=false,
    )
    cfg.render && render_image(joinpath(cfg.out_dir, "$(overview_name).dot"))
    push!(diagrams, overview_name => "full source hierarchy overview")

    for category in categories
        base_nodes = [name for name in ordered_names if types[name].category == category]
        isempty(base_nodes) && continue
        node_names = category_diagram_nodes(category, base_nodes, types, associations)
        scoped_associations = category_associations(node_names, base_nodes, associations)
        diagram_name = replace(category, '/' => '_')
        write_dot_file(
            joinpath(cfg.out_dir, "$(diagram_name).dot"),
            diagram_name,
            node_names,
            types,
            scoped_associations;
            detailed=true,
        )
        write_mermaid_file(
            joinpath(cfg.out_dir, "$(diagram_name).mmd"),
            node_names,
            types,
            scoped_associations;
            detailed=true,
        )
        cfg.render && render_image(joinpath(cfg.out_dir, "$(diagram_name).dot"))
        push!(diagrams, diagram_name => "detailed diagram for `$(category)` source types")
    end

    write_manifest(cfg.out_dir, diagrams)
    println("Generated UML diagrams in $(cfg.out_dir)")
end

main()
