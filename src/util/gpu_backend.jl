"""
    GPU Backend (stub)

Future GPU acceleration for QMC computations using CUDA.jl.

When implemented, this will provide:
- GPU-accelerated Walsh-Hadamard transform
- GPU-accelerated digital net generation
- GPU-accelerated kernel matrix computation

# Usage (future)
```julia
using CUDA
QMC.enable_gpu!()
dd = DigitalNetB2(1000; randomize="LMS_DS")
x = gen_samples(dd, 2^20)  # automatically uses GPU
```
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
"""
function gpu_fwht!(x::Vector{Float64})
    if _gpu_available()
        error("GPU FWHT not yet implemented. Install CUDA.jl and implement gpu_fwht!.")
    else
        fwht!(x)
    end
end
