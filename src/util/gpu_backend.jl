"""
    GPU Backend (stub)

Future GPU acceleration for QMC computations using CUDA.jl.

When implemented, this will provide:
- GPU-accelerated Walsh-Hadamard transform
- GPU-accelerated digital net generation
- GPU-accelerated kernel matrix computation

Planned user-facing GPU configuration is not implemented yet; at present the
only public entry point here is [`gpu_fwht!`](@ref), which falls back to the
CPU Walsh-Hadamard transform when no GPU backend is available.
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
    gpu_fwht!(x::Vector{Float64})

GPU-accelerated Fast Walsh-Hadamard Transform (stub).
Falls back to CPU implementation when CUDA is not available.

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
