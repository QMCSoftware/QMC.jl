# ──────────────────────────────────────────────────────────────────────────────
# QMCToolsCL C library bridge
#
# Provides low-level ccall wrappers around the compiled C functions in the
# QMCToolsCL Python package.  The shared library is discovered at module load
# time by asking Python where it installed qmctoolscl.
#
# Requires:  pip install qmctoolscl
# ──────────────────────────────────────────────────────────────────────────────

const _QMCTOOLSCL_LIB_PATH = Ref{String}("")

"""
    _init_qmctoolscl!()

Locate the QMCToolsCL compiled C library via Python and pre-load it with
`Libdl.RTLD_GLOBAL` so that subsequent `ccall`s can resolve symbols by name.
Returns `true` on success, `false` (with a warning) if the library is not found.
"""
function _init_qmctoolscl!()
    py_script = """import glob, os
try:
    import qmctoolscl
    pattern = os.path.dirname(os.path.abspath(qmctoolscl.__file__)) + "/c_lib*"
    matches = glob.glob(pattern)
    if matches:
        print(matches[0])
    else:
        print("")
except Exception:
    print("")
"""
    for py_cmd in ("python3", "python")
        try
            exe = Sys.which(py_cmd)
            isnothing(exe) && continue
            path = strip(read(`$exe -c $py_script`, String))
            if !isempty(path) && isfile(path)
                _QMCTOOLSCL_LIB_PATH[] = path
                Libdl.dlopen(path, Libdl.RTLD_GLOBAL | Libdl.RTLD_LAZY)
                return true
            end
        catch
        end
    end
    @warn """QMCToolsCL C library not found.
Lattice, DigitalNetB2, and Halton generation require it.
Install with:  pip install qmctoolscl
Then restart Julia."""
    return false
end

"""
    _qmctoolscl_lib_path() -> String

Return the cached path to the QMCToolsCL shared library, raising an informative
error if the library was not successfully loaded at module initialisation.
"""
function _qmctoolscl_lib_path()
    isempty(_QMCTOOLSCL_LIB_PATH[]) &&
        error("QMCToolsCL C library not loaded. " *
              "Install with: pip install qmctoolscl, then restart Julia.")
    return _QMCTOOLSCL_LIB_PATH[]
end

# ──────────────────────────────────────────────────────────────────────────────
# Layout helpers
#
# All qmctoolscl generation functions write output in C row-major order:
#   x[l*n*d + i*d + j]  (0-indexed l = replication, i = point, j = dimension)
#
# The helpers below convert these flat buffers to Julia column-major arrays.
# ──────────────────────────────────────────────────────────────────────────────

function _rowmaj_to_nxd(buf::Vector{Float64}, n::Int, d::Int)
    # buf: row-major n×d  →  Julia n×d Matrix
    return permutedims(reshape(buf, d, n), (2, 1))
end

function _rowmaj_to_Rnxd(buf::Vector{Float64}, R::Int, n::Int, d::Int)
    # buf: row-major R×n×d  →  Julia R×n×d Array
    return permutedims(reshape(buf, d, n, R), (3, 2, 1))
end

# ──────────────────────────────────────────────────────────────────────────────
# Lattice C wrappers
#
# Signatures (from qmctoolscl/c_funcs/):
#   lat_gen_linear(r, n, d, bs_r, bs_n, bs_d, *g, *x)
#   lat_gen_natural(r, n, d, bs_r, bs_n, bs_d, n_start, *g, *x)
#   lat_gen_gray(r, n, d, bs_r, bs_n, bs_d, n_start, *g, *x)
#   lat_shift_mod_1(r, n, d, bs_r, bs_n, bs_d, r_x, *x, *shifts, *xr)
#
# All sizes are unsigned long long (UInt64).
# g: r*d generating vector entries; x/xr: r*n*d floats (row-major).
# shifts: r*d floats (row-major).
# r_x: number of base-lattice replications in x (use 1 for a single base set).
# ──────────────────────────────────────────────────────────────────────────────

function _c_lat_gen_linear!(n::Int, d::Int, g::Vector{UInt64},
        x_buf::Vector{Float64})
    ccall((:lat_gen_linear, _qmctoolscl_lib_path()), Cvoid,
        (UInt64, UInt64, UInt64, UInt64, UInt64, UInt64,
         Ptr{UInt64}, Ptr{Float64}),
        UInt64(1), UInt64(n), UInt64(d), UInt64(1), UInt64(n), UInt64(d),
        g, x_buf)
end

function _c_lat_gen_natural!(n::Int, d::Int, n_start::Int, g::Vector{UInt64},
        x_buf::Vector{Float64})
    ccall((:lat_gen_natural, _qmctoolscl_lib_path()), Cvoid,
        (UInt64, UInt64, UInt64, UInt64, UInt64, UInt64, UInt64,
         Ptr{UInt64}, Ptr{Float64}),
        UInt64(1), UInt64(n), UInt64(d), UInt64(1), UInt64(n), UInt64(d),
        UInt64(n_start), g, x_buf)
end

function _c_lat_gen_gray!(n::Int, d::Int, n_start::Int, g::Vector{UInt64},
        x_buf::Vector{Float64})
    ccall((:lat_gen_gray, _qmctoolscl_lib_path()), Cvoid,
        (UInt64, UInt64, UInt64, UInt64, UInt64, UInt64, UInt64,
         Ptr{UInt64}, Ptr{Float64}),
        UInt64(1), UInt64(n), UInt64(d), UInt64(1), UInt64(n), UInt64(d),
        UInt64(n_start), g, x_buf)
end

function _c_lat_shift_mod_1!(R::Int, n::Int, d::Int, r_x::Int,
        x::Vector{Float64}, shifts::Vector{Float64}, xr::Vector{Float64})
    ccall((:lat_shift_mod_1, _qmctoolscl_lib_path()), Cvoid,
        (UInt64, UInt64, UInt64, UInt64, UInt64, UInt64, UInt64,
         Ptr{Float64}, Ptr{Float64}, Ptr{Float64}),
        UInt64(R), UInt64(n), UInt64(d), UInt64(R), UInt64(n), UInt64(d),
        UInt64(r_x), x, shifts, xr)
end

# ──────────────────────────────────────────────────────────────────────────────
# DigitalNetB2 C wrapper
#
# Signature:
#   dnb2_gen_gray_float(r, n, d, bs_r, bs_n, bs_d,
#                       n_start, mmax, r_x, apply_shift,
#                       *lshifts, *shiftsb, *tmaxes, *C, *x)
#
# C: r_x*d*mmax UInt64, row-major as C[l_x*d*mmax + j*mmax + b].
# lshifts: r_x UInt64  (left-shift per matrix replication before digital shift).
# shiftsb: r*d  UInt64  (digital shift per output replication × dimension).
# tmaxes:  r    UInt64  (bit width for float scaling: x = val * 2^{-tmaxes[l]}).
# apply_shift: 0 = none, 1 = apply digital shift.
# ──────────────────────────────────────────────────────────────────────────────

function _c_dnb2_gen_gray_float!(R::Int, n::Int, d::Int, n_start::Int,
        mmax::Int, r_x::Int, apply_shift::UInt8,
        lshifts::Vector{UInt64}, shiftsb::Vector{UInt64},
        tmaxes::Vector{UInt64}, C::Vector{UInt64},
        x_buf::Vector{Float64})
    ccall((:dnb2_gen_gray_float, _qmctoolscl_lib_path()), Cvoid,
        (UInt64, UInt64, UInt64, UInt64, UInt64, UInt64,
         UInt64, UInt64, UInt64, UInt8,
         Ptr{UInt64}, Ptr{UInt64}, Ptr{UInt64}, Ptr{UInt64}, Ptr{Float64}),
        UInt64(R), UInt64(n), UInt64(d),
        UInt64(R), UInt64(n), UInt64(d),
        UInt64(n_start), UInt64(mmax), UInt64(r_x), apply_shift,
        lshifts, shiftsb, tmaxes, C, x_buf)
end

# ──────────────────────────────────────────────────────────────────────────────
# Halton C wrapper
#
# Signature:
#   halton_qrng(n, d, n0, generalized, *res, *randu_d_32, *dvec)
#
# Uses Cint (not UInt64) for all integer arguments.
# res: d*n doubles; layout res[j*n + i] for 0-indexed dim j, point i.
# randu_d_32: d*32 doubles in [0,1) used to encode the random shift.
# dvec: d Cint values [0, 1, ..., d-1] selecting which prime-base dimensions.
#
# Because res[j*n + i] matches Julia column-major for an n×d matrix,
# reshape(res, n, d) gives the correct n×d result without transposing.
# ──────────────────────────────────────────────────────────────────────────────

function _c_halton_qrng!(n::Int, d::Int, n0::Int, generalized::Int,
        res::Vector{Float64}, randu_d_32::Vector{Float64},
        dvec::Vector{Int32})
    ccall((:halton_qrng, _qmctoolscl_lib_path()), Cvoid,
        (Cint, Cint, Cint, Cint,
         Ptr{Float64}, Ptr{Float64}, Ptr{Cint}),
        Cint(n), Cint(d), Cint(n0), Cint(generalized),
        res, randu_d_32, dvec)
end
