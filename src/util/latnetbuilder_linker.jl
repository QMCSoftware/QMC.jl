"""
    latnetbuilder_linker(lnb_dir::String) -> (type, gen_data, n_points, dim)

Parse a LatNetBuilder `outputMachine.txt` file and return the generating
vector (for ordinary lattice rules) or generating matrices (for digital nets).

# Returns
- `type::Symbol`: `:ordinary` or `:digital`
- `gen_data`: `Vector{UInt64}` (lattice gen vector) or `Matrix{UInt64}` (d × m direction numbers)
- `n_points::Int`: number of points
- `dim::Int`: number of dimensions

# Examples
```jldoctest
julia> using QuasiMC

julia> mktempdir() do d
           open(joinpath(d, "outputMachine.txt"), "w") do io
               write(io, join([
                   "Ordinary  // type",
                   "8  // n_points",
                   "3  // dim",
                   "comment",
                   "comment",
                   "1  // gen1",
                   "3  // gen2",
                   "5  // gen3",
                   "",
               ], "\\n"))
           end
           latnetbuilder_linker(d)
       end
(:ordinary, UInt64[0x0000000000000001, 0x0000000000000003, 0x0000000000000005], 8, 3)
```

Adapted from the LatNetBuilder Python parser:
  https://github.com/umontreal-simul/latnetbuilder/blob/master/python-wrapper/latnetbuilder/parse_output.py
"""
function latnetbuilder_linker(lnb_dir::String)
    fpath = joinpath(lnb_dir, "outputMachine.txt")
    isfile(fpath) || throw(ArgumentError("File not found: $fpath"))

    lines = readlines(fpath)
    sep = "  //"

    _val(line) = strip(split(line, sep)[1])

    if _val(lines[1]) == "Ordinary"
        # Ordinary lattice rule
        n_points = parse(Int, _val(lines[2]))
        dim = parse(Int, _val(lines[3]))
        gen_vector = Vector{UInt64}(undef, dim)
        for i in 1:dim
            gen_vector[i] = parse(UInt64, _val(lines[5 + i]))
        end
        return :ordinary, gen_vector, n_points, dim
    else
        # Digital net (polynomial or Sobol)
        nb_cols = parse(Int, _val(lines[1]))
        nb_rows = parse(Int, _val(lines[2]))
        n_points = parse(Int, _val(lines[3]))
        dim = parse(Int, _val(lines[4]))
        set_type = _val(lines[6])

        line_idx = 7
        if set_type == "Polynomial"
            line_idx += dim + 1
        elseif set_type == "Sobol"
            line_idx += dim
        end

        # Parse generating matrices
        pows2 = UInt64[UInt64(1) << (nb_rows - 1 - k) for k in 0:(nb_rows - 1)]
        mint = Matrix{UInt64}(undef, dim, nb_cols)

        for c in 1:dim
            line_idx += 1  # skip separator
            M = Matrix{Int}(undef, nb_rows, nb_cols)
            for i in 1:nb_rows
                vals = parse.(Int, split(strip(lines[line_idx])))
                M[i, :] .= vals
                line_idx += 1
            end
            # Convert binary matrix to integer direction numbers
            for j in 1:nb_cols
                mint[c, j] = sum(UInt64(M[i, j]) * pows2[i] for i in 1:nb_rows)
            end
        end

        return :digital, mint, n_points, dim
    end
end
