"""
    QuasiMCLoopVectorizationExt

Loaded automatically when `LoopVectorization` is available.  Overrides the default
`_erfinv_into!` with a `@turbo`-vectorised version on x86/AVX2 where SLEEFPirates
provides a SIMD `erfinv` implementation, giving 2-4× speedup for the dense Gaussian
transform inner loop.

On ARM/AARCH64 (Apple Silicon, etc.) SLEEFPirates does not supply a SIMD erfinv, so
`@turbo` falls back to scalar and adds overhead; the default `@simd` path in QuasiMC
is faster on those platforms and this extension leaves it unchanged.
"""
module QuasiMCLoopVectorizationExt

using QuasiMC: QuasiMC, _OPEN01_LOW, _OPEN01_HIGH
using LoopVectorization
using SpecialFunctions: erfinv

# Only override on x86 where SLEEFPirates has AVX/AVX2 erfinv intrinsics.
# On AARCH64 the default @simd path is faster; don't replace it.
if Sys.ARCH === :x86_64 || Sys.ARCH === :i686
    function QuasiMC._erfinv_into!(z::AbstractMatrix{Float64}, x::AbstractMatrix{Float64})
        @turbo for i in eachindex(z, x)
            xi = min(max(x[i], _OPEN01_LOW), _OPEN01_HIGH)
            z[i] = sqrt(2.0) * erfinv(muladd(2.0, xi, -1.0))
        end
        return z
    end
end

end # module QuasiMCLoopVectorizationExt
