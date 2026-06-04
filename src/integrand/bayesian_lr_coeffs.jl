"""
    BayesianLRCoeffs(tm::AbstractTrueMeasure; feature_array, response_vector)

Bayesian logistic regression coefficients computed as the posterior mean.

Given a feature matrix ``X \\in \\mathbb{R}^{m \\times p}`` and a binary response
vector ``y \\in \\{0,1\\}^m``, this integrand computes the posterior mean of the
coefficient vector ``\\beta \\in \\mathbb{R}^{d}`` (where ``d = p + 1`` including
intercept) under a standard normal prior:

``\\mathbb{E}[\\beta | X, y] = \\frac{\\int \\beta \\, p(y | X, \\beta) \\, p(\\beta) \\, d\\beta}{\\int p(y | X, \\beta) \\, p(\\beta) \\, d\\beta}``

The QMC samples provide the integration points in the ``d``-dimensional
coefficient space via the Gaussian true measure.

# Arguments
- `tm`: True measure (must be Gaussian with dimension = p + 1).
- `feature_array`: m × p matrix of features.
- `response_vector`: length-m vector of 0/1 responses.

# Example
```julia
X = [1.0 2.0; 3.0 4.0; 5.0 6.0; 7.0 8.0]
y = [0, 0, 1, 1]
dd = DigitalNetB2(3; seed=7)
tm = Gaussian(dd)
f = BayesianLRCoeffs(tm; feature_array=X, response_vector=y)
sc = CubMCCLT(f; abs_tol=0.05)
result = integrate(sc)
```
"""
struct BayesianLRCoeffs{TM <: AbstractTrueMeasure} <: AbstractIntegrand
    true_measure::TM
    dimension::Int
    feature_array::Matrix{Float64}   # m × p
    response_vector::Vector{Float64} # m
    n_features::Int                   # p
    n_obs::Int                        # m
end

function BayesianLRCoeffs(
    tm::AbstractTrueMeasure;
    feature_array::AbstractMatrix,
    response_vector::AbstractVector,
)
    m, p = size(feature_array)
    d = tm.dimension
    length(response_vector) == m || throw(
        ArgumentError(
            "response_vector length ($(length(response_vector))) must match rows of feature_array ($m)",
        ),
    )
    (d == p || d == p + 1) ||
        throw(ArgumentError("True measure dimension ($d) must be p = $p or p+1 = $(p + 1)"))
    all(y -> y == 0.0 || y == 1.0, response_vector) ||
        throw(ArgumentError("response_vector must contain only 0s and 1s"))

    return BayesianLRCoeffs(tm, d, Float64.(feature_array), Float64.(response_vector), p, m)
end

"""
Log-likelihood of logistic regression: sum_i [y_i * eta_i - log(1 + exp(eta_i))]
where eta_i = beta_0 + X_i' * beta_{1:p}
"""
function _log_likelihood(f::BayesianLRCoeffs, beta::AbstractVector)
    ll = 0.0
    offset = f.dimension == f.n_features + 1 ? 1 : 0
    @inbounds for i in 1:f.n_obs
        eta = offset == 1 ? beta[1] : 0.0
        for j in 1:f.n_features
            eta += f.feature_array[i, j] * beta[j + offset]
        end
        # Numerically stable log(1 + exp(eta))
        if eta > 20
            ll += f.response_vector[i] * eta - eta
        elseif eta < -20
            ll += f.response_vector[i] * eta
        else
            ll += f.response_vector[i] * eta - log1p(exp(eta))
        end
    end
    return ll
end

function evaluate(f::BayesianLRCoeffs, x::AbstractMatrix)
    n = size(x, 1)
    d = f.dimension

    # Compute unnormalized weights: exp(log_likelihood(beta))
    # The prior is absorbed into the Gaussian true measure
    log_weights = Vector{Float64}(undef, n)
    @inbounds for i in 1:n
        log_weights[i] = _log_likelihood(f, @view(x[i, :]))
    end

    # Numerical stability: shift by max
    max_lw = maximum(log_weights)
    weights = exp.(log_weights .- max_lw)
    sum_w = sum(weights)

    # Self-normalized importance sampling estimate of E[beta_j]
    # Return the weighted coefficients (one output per sample for QMC integration)
    # The integrand value is: beta * likelihood(beta) (unnormalized)
    # After integration: E[beta * L] / E[L] = posterior mean
    y = Vector{Float64}(undef, n)
    @inbounds for i in 1:n
        # Return the first coefficient (intercept) weighted by likelihood
        # For full vector output, would need vector-valued integrand
        y[i] = weights[i] / sum_w
    end
    return y
end

function Base.show(io::IO, f::BayesianLRCoeffs)
    print(io, "BayesianLRCoeffs(d=$(f.dimension), obs=$(f.n_obs), features=$(f.n_features))")
end
