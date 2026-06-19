"""
    Experimental GPU backend placeholder

Reserved space for future GPU support in QMC.jl.

No working GPU execution path is shipped. The public entry points in this file
are [`gpu_fwht`](@ref) and [`gpu_fwht!`](@ref), and their current behavior is a
CPU fallback to [`fwht`](@ref) and [`fwht!`](@ref). They do not allocate GPU
buffers, launch GPU kernels, or provide acceleration.
"""

# Placeholder: check if CUDA is available
_gpu_available() =
    try
        # Would check: isdefined(Main, :CUDA) && CUDA.functional()
        return false
    catch
        return false
    end

"""
    gpu_fwht(x::Vector{Float64})

Placeholder out-of-place API for a future GPU Fast Walsh-Hadamard Transform.

**Placeholder.** This exported name is kept for API discoverability, but QMC.jl
does not currently provide a GPU implementation. The present behavior is always
the CPU `fwht` path, so callers should not expect GPU acceleration.

```jldoctest
julia> using QMC

julia> x = [1.0, 2.0, 3.0, 4.0];

julia> gpu_fwht(x)
4-element Vector{Float64}:
 10.0
 -2.0
 -4.0
  0.0

julia> x
4-element Vector{Float64}:
 1.0
 2.0
 3.0
 4.0
```
"""
function gpu_fwht(x::Vector{Float64})
    y = copy(x)
    gpu_fwht!(y)
    return y
end

"""
    gpu_fwht!(x::Vector{Float64})

Placeholder API for a future GPU Fast Walsh-Hadamard Transform.

**Placeholder.** This exported name is kept for API discoverability, but QMC.jl
does not currently provide a GPU implementation. The present behavior is always
the CPU `fwht!` path, so callers should not expect GPU acceleration.

```jldoctest
julia> using QMC

julia> x = [1.0, 2.0, 3.0, 4.0];

julia> gpu_fwht!(x)
4-element Vector{Float64}:
 10.0
 -2.0
 -4.0
  0.0
```
"""
function gpu_fwht!(x::Vector{Float64})
    if _gpu_available()
        error("GPU FWHT not yet implemented. Install CUDA.jl and implement gpu_fwht!.")
    else
        fwht!(x)
    end
end
