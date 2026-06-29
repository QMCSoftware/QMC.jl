using Libdl
using QMCToolsCL_jll

@testset "QMCToolsCL backend" begin
    @test isfile(QMCToolsCL_jll.libqmctoolscl)

    handle = Libdl.dlopen(QMCToolsCL_jll.libqmctoolscl)
    try
        @test Libdl.dlsym_e(handle, :lat_gen_linear) != C_NULL
        @test Libdl.dlsym_e(handle, :dnb2_gen_gray) != C_NULL
        @test Libdl.dlsym_e(handle, :halton_qrng) != C_NULL
    finally
        Libdl.dlclose(handle)
    end

    original_path = QuasiMC._QMCTOOLSCL_LIB_PATH[]
    original_handle = QuasiMC._QMCTOOLSCL_HANDLE[]
    original_attempted = QuasiMC._QMCTOOLSCL_INIT_ATTEMPTED[]
    original_search = QuasiMC._QMCTOOLSCL_LAST_SEARCH[]
    original_error = QuasiMC._QMCTOOLSCL_LAST_ERROR[]
    original_fused = QuasiMC._HAS_DNB2_FUSED[]
    had_override = haskey(ENV, "QUASIMC_QMCTOOLSCL_LIB")
    original_override = get(ENV, "QUASIMC_QMCTOOLSCL_LIB", "")
    bogus_override = joinpath(pwd(), "definitely-missing-qmctoolscl")

    try
        ENV["QUASIMC_QMCTOOLSCL_LIB"] = bogus_override
        QuasiMC._QMCTOOLSCL_LIB_PATH[] = ""
        QuasiMC._QMCTOOLSCL_HANDLE[] = C_NULL
        QuasiMC._QMCTOOLSCL_INIT_ATTEMPTED[] = false
        QuasiMC._QMCTOOLSCL_LAST_SEARCH[] = "none"
        QuasiMC._QMCTOOLSCL_LAST_ERROR[] = "none"
        QuasiMC._HAS_DNB2_FUSED[] = false

        err = try
            QuasiMC._qmctoolscl_lib_path()
            nothing
        catch caught
            caught
        end
        @test err isa ErrorException
        msg = sprint(showerror, err)
        occursin("QUASIMC_QMCTOOLSCL_LIB", msg) ||
            error("Override error omitted env var:\n$msg")
        occursin(bogus_override, msg) || error("Override error omitted path:\n$msg")
    finally
        if had_override
            ENV["QUASIMC_QMCTOOLSCL_LIB"] = original_override
        else
            delete!(ENV, "QUASIMC_QMCTOOLSCL_LIB")
        end
        QuasiMC._QMCTOOLSCL_LIB_PATH[] = original_path
        QuasiMC._QMCTOOLSCL_HANDLE[] = original_handle
        QuasiMC._QMCTOOLSCL_INIT_ATTEMPTED[] = original_attempted
        QuasiMC._QMCTOOLSCL_LAST_SEARCH[] = original_search
        QuasiMC._QMCTOOLSCL_LAST_ERROR[] = original_error
        QuasiMC._HAS_DNB2_FUSED[] = original_fused
    end
end
