"""
    UMBridgeWrapper(true_measure; url, model_name, config)

Integrand wrapper for [UM-Bridge](https://um-bridge-benchmarks.readthedocs.io/)
Docker models.  Sends evaluation requests over HTTP to a running UM-Bridge
server using the [UMBridge.jl](https://github.com/UM-Bridge/UMBridge.jl)
client library.

# Requirements

```julia
import Pkg; Pkg.add("UMBridge")   # installs HTTP.jl, JSON.jl as deps
```

A running UM-Bridge model server is required.  For example, the cantilever
beam benchmark:

```bash
docker run -d -p 4243:4243 linusseelinger/benchmark-muq-beam-propagation:latest
```

# Arguments
- `true_measure::AbstractTrueMeasure`: The underlying measure (e.g. `Uniform`).
- `url::String`: URL of the UM-Bridge server (default `"http://localhost:4243"`).
- `model_name::String`: Model name on the server (default `"forward"`).
- `config::Dict{String,Any}`: Configuration dict passed to the model
  (e.g. `Dict("d" => 3)`).

# Example
```julia
using QMC
import QMC: Uniform

dd = DigitalNetB2(3; seed=7)
tm = Uniform(dd; lower_bound=1.0, upper_bound=1.05)
f  = UMBridgeWrapper(tm;
         url="http://localhost:4243",
         model_name="forward",
         config=Dict("d" => 3))
sc = CubQMCNetG(f; abs_tol=2.5e-2)
result = integrate(sc)
```
"""
struct UMBridgeWrapper{TM <: AbstractTrueMeasure} <: AbstractIntegrand
    true_measure::TM
    url::String
    model_name::String
    config::Dict{String, Any}
    _model::Any   # UMBridge.HTTPModel (lazy, Any to avoid hard dep)
end

function UMBridgeWrapper(
    true_measure::AbstractTrueMeasure;
    url::String="http://localhost:4243",
    model_name::String="forward",
    config::Dict{String, Any}=Dict{String, Any}(),
)
    # Try to load UMBridge
    model = _load_umbridge_model(url, model_name)
    return UMBridgeWrapper(true_measure, url, model_name, config, model)
end

"""Load UMBridge.HTTPModel, or nothing if UMBridge is not installed."""
function _load_umbridge_model(url::String, model_name::String)
    try
        UMB = Base.require(
            Base.PkgId(Base.UUID("0a9a1a31-3e76-4660-84e1-f39fcdc3920b"), "UMBridge"),
        )
        return UMB.HTTPModel(model_name, url)
    catch e
        @warn "UMBridge.jl not found. Install with: import Pkg; Pkg.add(\"UMBridge\")"
        return nothing
    end
end

function evaluate(f::UMBridgeWrapper, x::AbstractMatrix)
    if f._model === nothing
        error(
            "UMBridgeWrapper requires UMBridge.jl. " *
            "Install with: import Pkg; Pkg.add(\"UMBridge\")",
        )
    end

    n = size(x, 1)
    d = size(x, 2)

    # UMBridge.evaluate expects input as Vector{Vector{Float64}}
    # and returns output as Vector{Vector{Float64}}.
    # For scalar output models, output[1] is a single-element vector.
    # For vector output models (e.g. cantilever beam), output[1] has
    # multiple elements → we return the full vector per sample.

    # First call to detect output dimension
    UMB = parentmodule(typeof(f._model))
    out0 = UMB.evaluate(f._model, [collect(Float64, x[1, :])], f.config)
    out_dim = length(out0[1])

    if out_dim == 1
        # Scalar output
        results = Vector{Float64}(undef, n)
        results[1] = out0[1][1]
        for i in 2:n
            input_vec = [collect(Float64, x[i, :])]
            output = UMB.evaluate(f._model, input_vec, f.config)
            results[i] = output[1][1]
        end
        return results
    else
        # Vector output — return n × out_dim matrix
        results = Matrix{Float64}(undef, n, out_dim)
        results[1, :] = out0[1]
        for i in 2:n
            input_vec = [collect(Float64, x[i, :])]
            output = UMB.evaluate(f._model, input_vec, f.config)
            results[i, :] = output[1]
        end
        return results
    end
end

function Base.show(io::IO, f::UMBridgeWrapper)
    status = f._model === nothing ? "not connected" : "connected"
    print(io, "UMBridgeWrapper(url=\"$(f.url)\", model=\"$(f.model_name)\", $status)")
end
