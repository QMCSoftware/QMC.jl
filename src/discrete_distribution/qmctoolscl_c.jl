# ──────────────────────────────────────────────────────────────────────────────
# QMCToolsCL C library bridge
#
# Provides low-level ccall wrappers around the compiled C functions in the
# QMCToolsCL Python package. The shared library is discovered on demand by
# asking Python where it installed qmctoolscl.
#
# Requires:  pip install qmctoolscl
# ──────────────────────────────────────────────────────────────────────────────

const _QMCTOOLSCL_LIB_PATH = Ref{String}("")
const _QMCTOOLSCL_HANDLE = Ref{Ptr{Cvoid}}(C_NULL)
const _QMCTOOLSCL_INIT_ATTEMPTED = Ref(false)
const _QMCTOOLSCL_LAST_SEARCH = Ref("none")

# True when the loaded library exports the fused gen+shift+float functions
# (available since qmctoolscl 1.2.3; probe once at init time).
const _HAS_DNB2_FUSED = Ref(false)

function _python_candidates()
    candidates = String[]

    # Allow callers to point QMC at a specific Python interpreter.
    for key in ("QMC_PYTHON", "CONDA_PYTHON_EXE", "PYTHON")
        if haskey(ENV, key) && !isempty(strip(ENV[key]))
            push!(candidates, strip(ENV[key]))
        end
    end

    # Prefer an active Conda environment when one is available.
    if haskey(ENV, "CONDA_PREFIX") && !isempty(strip(ENV["CONDA_PREFIX"]))
        push!(candidates, joinpath(strip(ENV["CONDA_PREFIX"]), "bin", "python"))
    end

    # Fall back to common user-level Conda installs, checking named environments
    # BEFORE the base interpreter. A named env often carries a newer qmctoolscl
    # (with fused gen+float C functions) while the base env may have an older one.
    for root in ("miniconda3", "miniforge3", "mambaforge", "anaconda3")
        conda_base = joinpath(homedir(), root)
        envs_dir = joinpath(conda_base, "envs")
        if isdir(envs_dir)
            for env_name in sort(readdir(envs_dir))
                push!(candidates, joinpath(envs_dir, env_name, "bin", "python"))
            end
        end
        push!(candidates, joinpath(conda_base, "bin", "python"))
    end

    for py_cmd in ("python3", "python")
        exe = Sys.which(py_cmd)
        isnothing(exe) || push!(candidates, exe)
    end

    seen = Set{String}()
    unique_candidates = String[]
    for candidate in candidates
        path = abspath(expanduser(candidate))
        if isfile(path) && !(path in seen)
            push!(unique_candidates, path)
            push!(seen, path)
        end
    end

    return unique_candidates
end

"""
    _init_qmctoolscl!(; warn_on_failure=true, force=false)

Locate the QMCToolsCL compiled C library via Python and pre-load it with
`Libdl.RTLD_GLOBAL` so that subsequent `ccall`s can resolve symbols by name.
Returns `true` on success, `false` (with a warning) if the library is not found.
"""
function _init_qmctoolscl!(; warn_on_failure::Bool=true, force::Bool=false)
    !isempty(_QMCTOOLSCL_LIB_PATH[]) && return true
    _QMCTOOLSCL_INIT_ATTEMPTED[] && !force && return false
    _QMCTOOLSCL_INIT_ATTEMPTED[] = true

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
    searched = String[]
    fallback_path = ""   # best non-fused library found so far
    for exe in _python_candidates()
        push!(searched, exe)
        try
            path = strip(read(`$exe -c $py_script`, String))
            if !isempty(path) && isfile(path)
                hdl = Libdl.dlopen(path, Libdl.RTLD_GLOBAL | Libdl.RTLD_LAZY)
                has_fused = Libdl.dlsym_e(hdl, :dnb2_gen_gray_float) != C_NULL
                if has_fused
                    _QMCTOOLSCL_LIB_PATH[] = path
                    _QMCTOOLSCL_HANDLE[] = hdl
                    _HAS_DNB2_FUSED[] = true
                    return true
                end
                Libdl.dlclose(hdl)
                isempty(fallback_path) && (fallback_path = path)
            end
        catch
        end
    end
    if !isempty(fallback_path)
        _QMCTOOLSCL_LIB_PATH[] = fallback_path
        hdl = Libdl.dlopen(fallback_path, Libdl.RTLD_GLOBAL | Libdl.RTLD_LAZY)
        _QMCTOOLSCL_HANDLE[] = hdl
        _HAS_DNB2_FUSED[] = false
        return true
    end
    searched_str = isempty(searched) ? "none" : join(searched, ", ")
    _QMCTOOLSCL_LAST_SEARCH[] = searched_str
    if warn_on_failure
        @warn """QMCToolsCL C library not found.
Lattice, DigitalNetB2, and Halton generation require it.
Install `qmctoolscl` into a Python visible to Julia, or set
ENV["QMC_PYTHON"] to the interpreter that has it installed.
Searched Python interpreters: $searched_str
Then restart Julia."""
    end
    return false
end

"""
    _qmctoolscl_lib_path() -> String

Return the cached path to the QMCToolsCL shared library, raising an informative
error if the library was not successfully loaded.
"""
function _qmctoolscl_lib_path()
    # Retry discovery on demand so users can set ENV["QMC_PYTHON"]
    # after importing QMC but before first use of QMCToolsCL-backed generators.
    isempty(_QMCTOOLSCL_LIB_PATH[]) && _init_qmctoolscl!(; warn_on_failure=false, force=true)
    isempty(_QMCTOOLSCL_LIB_PATH[]) && error(
        "QMCToolsCL C library not loaded. " *
        "Lattice, DigitalNetB2, and Halton require it. " *
        "Install `qmctoolscl` into a Python visible to Julia, or set " *
        "ENV[\"QMC_PYTHON\"] to that interpreter before first use. " *
        "Searched Python interpreters: $(_QMCTOOLSCL_LAST_SEARCH[]).",
    )
    return _QMCTOOLSCL_LIB_PATH[]
end

# Return the open library handle, triggering initialization if needed.
# Julia 1.14 requires ccall library names to be compile-time constants,
# so we look up function pointers via dlsym at runtime instead.
function _qmctoolscl_handle()
    _QMCTOOLSCL_HANDLE[] == C_NULL && _qmctoolscl_lib_path()  # triggers init + error if missing
    return _QMCTOOLSCL_HANDLE[]
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

function _c_lat_gen_linear!(n::Int, d::Int, g::Vector{UInt64}, x_buf::Vector{Float64})
    ccall(
        Libdl.dlsym(_qmctoolscl_handle(), :lat_gen_linear),
        Cvoid,
        (UInt64, UInt64, UInt64, UInt64, UInt64, UInt64, Ptr{UInt64}, Ptr{Float64}),
        UInt64(1),
        UInt64(n),
        UInt64(d),
        UInt64(1),
        UInt64(n),
        UInt64(d),
        g,
        x_buf,
    )
end

function _c_lat_gen_natural!(
    n::Int,
    d::Int,
    n_start::Int,
    g::Vector{UInt64},
    x_buf::Vector{Float64},
)
    ccall(
        Libdl.dlsym(_qmctoolscl_handle(), :lat_gen_natural),
        Cvoid,
        (UInt64, UInt64, UInt64, UInt64, UInt64, UInt64, UInt64, Ptr{UInt64}, Ptr{Float64}),
        UInt64(1),
        UInt64(n),
        UInt64(d),
        UInt64(1),
        UInt64(n),
        UInt64(d),
        UInt64(n_start),
        g,
        x_buf,
    )
end

function _c_lat_gen_gray!(
    n::Int,
    d::Int,
    n_start::Int,
    g::Vector{UInt64},
    x_buf::Vector{Float64},
)
    ccall(
        Libdl.dlsym(_qmctoolscl_handle(), :lat_gen_gray),
        Cvoid,
        (UInt64, UInt64, UInt64, UInt64, UInt64, UInt64, UInt64, Ptr{UInt64}, Ptr{Float64}),
        UInt64(1),
        UInt64(n),
        UInt64(d),
        UInt64(1),
        UInt64(n),
        UInt64(d),
        UInt64(n_start),
        g,
        x_buf,
    )
end

function _c_lat_shift_mod_1!(
    R::Int,
    n::Int,
    d::Int,
    r_x::Int,
    x::Vector{Float64},
    shifts::Vector{Float64},
    xr::Vector{Float64},
)
    ccall(
        Libdl.dlsym(_qmctoolscl_handle(), :lat_shift_mod_1),
        Cvoid,
        (
            UInt64,
            UInt64,
            UInt64,
            UInt64,
            UInt64,
            UInt64,
            UInt64,
            Ptr{Float64},
            Ptr{Float64},
            Ptr{Float64},
        ),
        UInt64(R),
        UInt64(n),
        UInt64(d),
        UInt64(R),
        UInt64(n),
        UInt64(d),
        UInt64(r_x),
        x,
        shifts,
        xr,
    )
end

# ──────────────────────────────────────────────────────────────────────────────
# DigitalNetB2 C wrapper
#
# Signatures:
#   dnb2_gen_gray(r, n, d, bs_r, bs_n, bs_d, n_start, mmax, *C, *xb)
#   dnb2_gen_natural(r, n, d, bs_r, bs_n, bs_d, n_start, mmax, *C, *xb)
#   dnb2_digital_shift(r, n, d, bs_r, bs_n, bs_d, r_x, *lshifts, *xb, *shiftsb, *xrb)
#   dnb2_integer_to_float(r, n, d, bs_r, bs_n, bs_d, *tmaxes, *xb, *x)
#
# C: r_x*d*mmax UInt64, row-major as C[l_x*d*mmax + j*mmax + b].
# xb/xrb: binary digital net points stored as UInt64 values in row-major R×n×d order.
# lshifts: r_x UInt64  (left shift per matrix replication before digital shift).
# shiftsb: r*d  UInt64  (digital shift per output replication × dimension).
# tmaxes:  r    UInt64  (bit width for float scaling: x = val * 2^{-tmaxes[l]}).
# ──────────────────────────────────────────────────────────────────────────────

function _c_dnb2_gen_gray!(
    R::Int,
    n::Int,
    d::Int,
    n_start::Int,
    mmax::Int,
    C::Vector{UInt64},
    xb_buf::Vector{UInt64},
)
    ccall(
        Libdl.dlsym(_qmctoolscl_handle(), :dnb2_gen_gray),
        Cvoid,
        (
            UInt64,
            UInt64,
            UInt64,
            UInt64,
            UInt64,
            UInt64,
            UInt64,
            UInt64,
            Ptr{UInt64},
            Ptr{UInt64},
        ),
        UInt64(R),
        UInt64(n),
        UInt64(d),
        UInt64(R),
        UInt64(n),
        UInt64(d),
        UInt64(n_start),
        UInt64(mmax),
        C,
        xb_buf,
    )
end

function _c_dnb2_gen_natural!(
    R::Int,
    n::Int,
    d::Int,
    n_start::Int,
    mmax::Int,
    C::Vector{UInt64},
    xb_buf::Vector{UInt64},
)
    ccall(
        Libdl.dlsym(_qmctoolscl_handle(), :dnb2_gen_natural),
        Cvoid,
        (
            UInt64,
            UInt64,
            UInt64,
            UInt64,
            UInt64,
            UInt64,
            UInt64,
            UInt64,
            Ptr{UInt64},
            Ptr{UInt64},
        ),
        UInt64(R),
        UInt64(n),
        UInt64(d),
        UInt64(R),
        UInt64(n),
        UInt64(d),
        UInt64(n_start),
        UInt64(mmax),
        C,
        xb_buf,
    )
end

function _c_dnb2_digital_shift!(
    R::Int,
    n::Int,
    d::Int,
    r_x::Int,
    lshifts::Vector{UInt64},
    xb_buf::Vector{UInt64},
    shiftsb::Vector{UInt64},
    xrb_buf::Vector{UInt64},
)
    ccall(
        Libdl.dlsym(_qmctoolscl_handle(), :dnb2_digital_shift),
        Cvoid,
        (
            UInt64,
            UInt64,
            UInt64,
            UInt64,
            UInt64,
            UInt64,
            UInt64,
            Ptr{UInt64},
            Ptr{UInt64},
            Ptr{UInt64},
            Ptr{UInt64},
        ),
        UInt64(R),
        UInt64(n),
        UInt64(d),
        UInt64(R),
        UInt64(n),
        UInt64(d),
        UInt64(r_x),
        lshifts,
        xb_buf,
        shiftsb,
        xrb_buf,
    )
end

function _c_dnb2_interlace!(
    R::Int,
    d_alpha::Int,
    mmax::Int,
    d::Int,
    tmax::Int,
    tmax_alpha::Int,
    alpha::Int,
    C::Vector{UInt64},
    C_alpha::Vector{UInt64},
)
    ccall(
        Libdl.dlsym(_qmctoolscl_handle(), :dnb2_interlace),
        Cvoid,
        (
            UInt64,
            UInt64,
            UInt64,
            UInt64,
            UInt64,
            UInt64,
            UInt64,
            UInt64,
            UInt64,
            UInt64,
            Ptr{UInt64},
            Ptr{UInt64},
        ),
        UInt64(R),
        UInt64(d_alpha),
        UInt64(mmax),
        UInt64(R),
        UInt64(d_alpha),
        UInt64(mmax),
        UInt64(d),
        UInt64(tmax),
        UInt64(tmax_alpha),
        UInt64(alpha),
        C,
        C_alpha,
    )
end

function _c_dnb2_integer_to_float!(
    R::Int,
    n::Int,
    d::Int,
    tmaxes::Vector{UInt64},
    xb_buf::Vector{UInt64},
    x_buf::Vector{Float64},
)
    ccall(
        Libdl.dlsym(_qmctoolscl_handle(), :dnb2_integer_to_float),
        Cvoid,
        (
            UInt64,
            UInt64,
            UInt64,
            UInt64,
            UInt64,
            UInt64,
            Ptr{UInt64},
            Ptr{UInt64},
            Ptr{Float64},
        ),
        UInt64(R),
        UInt64(n),
        UInt64(d),
        UInt64(R),
        UInt64(n),
        UInt64(d),
        tmaxes,
        xb_buf,
        x_buf,
    )
end

# ──────────────────────────────────────────────────────────────────────────────
# Fused generation + optional digital shift + integer-to-float
#
# Signatures (from qmctoolscl/c_funcs/):
#   dnb2_gen_gray_float(r, n, d, bs_r, bs_n, bs_d, n_start, mmax, r_x,
#                       apply_shift, *lshifts, *shiftsb, *tmaxes, *C, *x)
#   dnb2_gen_natural_float(...)  — same signature, non-Gray ordering
#
# These fuse generate + digital shift + float conversion into a single C pass,
# eliminating the intermediate xb (UInt64) and xrb (UInt64) buffers.
#
# lshifts:  size r_x  UInt64  (left shift per matrix replication; use zeros)
# shiftsb:  size r*d  UInt64  (digital shifts; ignored when apply_shift=0x00)
# tmaxes:   size r    UInt64  (bit width for scaling: x = val * 2^{-tmaxes[l]})
# C:        size r_x*d*mmax UInt64 (generating matrices, row-major)
# x:        size r*n*d Float64 (output, row-major)
# ──────────────────────────────────────────────────────────────────────────────

function _c_dnb2_gen_gray_float!(
    R::Int,
    n::Int,
    d::Int,
    n_start::Int,
    mmax::Int,
    r_x::Int,
    apply_shift::UInt8,
    lshifts::Vector{UInt64},
    shiftsb::Vector{UInt64},
    tmaxes::Vector{UInt64},
    C::Vector{UInt64},
    x_buf::Vector{Float64},
)
    ccall(
        Libdl.dlsym(_qmctoolscl_handle(), :dnb2_gen_gray_float),
        Cvoid,
        (
            UInt64,
            UInt64,
            UInt64,
            UInt64,
            UInt64,
            UInt64,
            UInt64,
            UInt64,
            UInt64,
            UInt8,
            Ptr{UInt64},
            Ptr{UInt64},
            Ptr{UInt64},
            Ptr{UInt64},
            Ptr{Float64},
        ),
        UInt64(R),
        UInt64(n),
        UInt64(d),
        UInt64(R),
        UInt64(n),
        UInt64(d),
        UInt64(n_start),
        UInt64(mmax),
        UInt64(r_x),
        apply_shift,
        lshifts,
        shiftsb,
        tmaxes,
        C,
        x_buf,
    )
end

function _c_dnb2_gen_natural_float!(
    R::Int,
    n::Int,
    d::Int,
    n_start::Int,
    mmax::Int,
    r_x::Int,
    apply_shift::UInt8,
    lshifts::Vector{UInt64},
    shiftsb::Vector{UInt64},
    tmaxes::Vector{UInt64},
    C::Vector{UInt64},
    x_buf::Vector{Float64},
)
    ccall(
        Libdl.dlsym(_qmctoolscl_handle(), :dnb2_gen_natural_float),
        Cvoid,
        (
            UInt64,
            UInt64,
            UInt64,
            UInt64,
            UInt64,
            UInt64,
            UInt64,
            UInt64,
            UInt64,
            UInt8,
            Ptr{UInt64},
            Ptr{UInt64},
            Ptr{UInt64},
            Ptr{UInt64},
            Ptr{Float64},
        ),
        UInt64(R),
        UInt64(n),
        UInt64(d),
        UInt64(R),
        UInt64(n),
        UInt64(d),
        UInt64(n_start),
        UInt64(mmax),
        UInt64(r_x),
        apply_shift,
        lshifts,
        shiftsb,
        tmaxes,
        C,
        x_buf,
    )
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

function _c_halton_qrng!(
    n::Int,
    d::Int,
    n0::Int,
    generalized::Int,
    res::Vector{Float64},
    randu_d_32::Vector{Float64},
    dvec::Vector{Int32},
)
    ccall(
        Libdl.dlsym(_qmctoolscl_handle(), :halton_qrng),
        Cvoid,
        (Cint, Cint, Cint, Cint, Ptr{Float64}, Ptr{Float64}, Ptr{Cint}),
        Cint(n),
        Cint(d),
        Cint(n0),
        Cint(generalized),
        res,
        randu_d_32,
        dvec,
    )
end
