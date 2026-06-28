using DelimitedFiles
using LinearAlgebra
using Statistics
using QuasiMC

const HABERMAN_TRAIN_INDICES = [
    1, 2, 5, 6, 7, 8, 9, 10, 11, 13, 14, 16, 17, 18, 20, 21, 22, 24, 26, 27, 28,
    29, 30, 32, 33, 34, 35, 36, 39, 40, 42, 43, 44, 45, 46, 47, 48, 49, 50, 52,
    53, 54, 55, 57, 59, 60, 64, 65, 68, 69, 72, 73, 74, 76, 77, 78, 80, 83, 84,
    86, 88, 90, 93, 94, 96, 97, 98, 101, 104, 106, 107, 108, 110, 111, 113, 116,
    117, 118, 120, 121, 122, 123, 124, 125, 128, 129, 130, 131, 132, 134, 135,
    136, 137, 138, 141, 143, 144, 145, 146, 147, 149, 150, 152, 153, 154, 158,
    159, 160, 162, 163, 164, 166, 167, 168, 170, 172, 176, 178, 179, 181, 184,
    185, 186, 187, 188, 190, 191, 192, 193, 196, 197, 198, 199, 200, 201, 202,
    203, 204, 205, 206, 208, 209, 210, 211, 212, 215, 216, 217, 218, 219, 220,
    221, 222, 223, 224, 225, 226, 227, 230, 231, 232, 234, 236, 237, 238, 239,
    243, 244, 245, 248, 250, 251, 252, 253, 254, 258, 260, 261, 262, 263, 264,
    265, 266, 267, 269, 270, 272, 273, 274, 276, 278, 281, 284, 288, 290, 292,
    293, 295, 296, 297, 298, 300, 301, 303, 306,
]

_logistic(x) = 1 / (1 + exp(-x))

function _log_likelihood(design, response, beta)
    eta = design * beta
    return sum(response .* eta .- max.(eta, 0) .- log1p.(exp.(-abs.(eta))))
end

function _posterior_mode(design, response, prior_variance)
    beta = zeros(size(design, 2))
    for _ in 1:30
        eta = design * beta
        probability = _logistic.(eta)
        variance = probability .* (1 .- probability)
        gradient = transpose(design) * (response - probability) - beta / prior_variance
        precision =
            transpose(design) * (variance .* design) +
            I / prior_variance
        step = precision \ gradient
        beta += step
        norm(step) < 1e-10 && break
    end
    return beta
end

function bayesian_lr_demo(; n=2^16, seed=1, prior_variance=5.0)
    raw = readdlm(joinpath(@__DIR__, "haberman.data"), ',', Float64)
    features = raw[:, 1:3]
    response = Float64.(raw[:, 4] .== 1)
    test_indices = setdiff(axes(raw, 1), HABERMAN_TRAIN_INDICES)

    train_features = features[HABERMAN_TRAIN_INDICES, :]
    train_response = response[HABERMAN_TRAIN_INDICES]
    test_features = features[test_indices, :]
    test_response = response[test_indices]
    design = hcat(train_features, ones(length(train_response)))

    mode = _posterior_mode(design, train_response, prior_variance)
    eta = design * mode
    probability = _logistic.(eta)
    variance = probability .* (1 .- probability)
    covariance = inv(
        transpose(design) * (variance .* design) +
        I / prior_variance,
    )

    dd = DigitalNetB2(4; seed=seed, graycode=false)
    proposal = Gaussian(dd; mean=mode, covariance=covariance, decomp_type=:Cholesky)
    beta_samples = transform(proposal, gen_samples(dd, n))
    inverse_covariance = inv(covariance)
    logdet_covariance = logdet(covariance)
    log_weights = Vector{Float64}(undef, n)
    for i in axes(beta_samples, 1)
        beta = @view beta_samples[i, :]
        log_target =
            _log_likelihood(design, train_response, beta) -
            dot(beta, beta) / (2prior_variance)
        difference = beta - mode
        log_proposal =
            -dot(difference, inverse_covariance * difference) / 2 -
            logdet_covariance / 2
        log_weights[i] = log_target - log_proposal
    end

    weights = exp.(log_weights .- maximum(log_weights))
    coefficients = vec(sum(beta_samples .* weights; dims=1) ./ sum(weights))
    effective_sample_size = sum(weights)^2 / sum(abs2, weights)
    test_probability =
        _logistic.(hcat(test_features, ones(length(test_response))) * coefficients)
    predictions = test_probability .>= 0.5
    accuracy = mean(predictions .== test_response)

    return (;
        coefficients,
        accuracy,
        effective_sample_size,
        n_train=length(train_response),
        n_test=length(test_response),
    )
end
