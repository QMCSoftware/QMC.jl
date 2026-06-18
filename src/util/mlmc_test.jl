"""
    mlmc_test(integrand; n=20000, L=8)

MLMC convergence rate test routine. Estimates the three key MLMC parameters
(α, β, γ) by running `n` samples at each of `L+1` levels and performing
linear regression on the observed means, variances, and costs.

Prints a formatted table with per-level statistics and regression estimates.

# Returns
- `alpha::Float64`: weak convergence exponent (E[P_ℓ - P_{ℓ-1}] ~ 2^{-α·ℓ})
- `beta::Float64`:  variance decay exponent (Var[P_ℓ - P_{ℓ-1}] ~ 2^{-β·ℓ})
- `gamma::Float64`: cost growth exponent (cost_ℓ ~ 2^{γ·ℓ})

# Example
```text
dd = IIDStdUniform(4; seed=7)
tm = GeometricBrownianMotion(dd)
fml = FinancialOptionML(tm; d_coarsest=4)
alpha, beta, gamma = mlmc_test(fml; n=10000, L=6)
```
"""
function mlmc_test(integrand::AbstractMLIntegrand; n::Int=20000, L::Int=8)
    # Make n a multiple of 100 for batching
    n = 100 * ceil(Int, n / 100)
    n_batch = div(n, 100)

    del1 = Float64[]   # E[Pf - Pc]
    del2 = Float64[]   # E[Pf]
    var1 = Float64[]   # Var[Pf - Pc]
    var2 = Float64[]   # Var[Pf]
    kur1 = Float64[]   # kurtosis
    chk1 = Float64[]   # telescoping check
    cst = Float64[]   # cost per sample

    @printf("Convergence tests using N = %d samples\n", n)
    @printf(
        "  %4s  %12s  %12s  %12s  %12s  %12s  %12s\n",
        "l",
        "ave(Pf-Pc)",
        "ave(Pf)",
        "var(Pf-Pc)",
        "var(Pf)",
        "kurtosis",
        "check"
    )

    for ll in 0:L
        d_l = dimension_at_level(integrand, ll)
        c_l = cost_at_level(integrand, ll)

        sums = zeros(6)
        for _ in 1:100
            dd = discrete_distribution(integrand)
            x_raw = gen_samples(dd, n_batch)
            x = transform(true_measure(integrand), x_raw)

            # Pad/truncate to d_l dimensions
            n_pts = size(x, 1)
            x_l = x[:, 1:min(d_l, size(x, 2))]
            if size(x_l, 2) < d_l
                x_l = hcat(x_l, rand(n_pts, d_l - size(x_l, 2)))
            end

            Pc, Pf = ml_evaluate(integrand, x_l, ll)
            dP = Pf .- Pc

            sums[1] += sum(dP)
            sums[2] += sum(dP .^ 2)
            sums[3] += sum(dP .^ 3)
            sums[4] += sum(dP .^ 4)
            sums[5] += sum(Pf)
            sums[6] += sum(Pf .^ 2)
        end
        sums ./= n

        kurt =
            ll == 0 ? 0.0 :
            (sums[4] - 4sums[3]*sums[1] + 6sums[2]*sums[1]^2 - 3sums[1]^4) /
            max((sums[2] - sums[1]^2)^2, 1e-30)

        push!(del1, sums[1])
        push!(del2, sums[5])
        push!(var1, sums[2] - sums[1]^2)
        push!(var2, max(sums[6] - sums[5]^2, 1e-10))
        push!(kur1, kurt)
        push!(cst, c_l)

        check = if ll == 0
            0.0
        else
            abs(del1[end] + del2[end - 1] - del2[end]) / (
                3 * (sqrt(abs(var1[end])) + sqrt(abs(var2[end - 1])) + sqrt(abs(var2[end]))) /
                sqrt(n)
            )
        end
        push!(chk1, check)

        @printf(
            "  %4d  %12.4e  %12.4e  %12.3e  %12.3e  %12.2e  %12.2e\n",
            ll,
            del1[end],
            del2[end],
            var1[end],
            var2[end],
            kur1[end],
            chk1[end]
        )
    end

    # Warnings
    if kur1[end] > 100
        @warn "Kurtosis on finest level = $(kur1[end]); MLMC correction may be dominated by rare paths"
    end
    if maximum(chk1) > 1
        @warn "Max consistency error = $(maximum(chk1)); telescoping identity may not be satisfied"
    end

    # Linear regression for alpha, beta, gamma
    l1 = 3  # skip first 2 levels (1-indexed)
    l2 = L + 1
    npts = l2 - l1 + 1
    X = hcat(ones(npts), collect((l1 - 1):(l2 - 1)))  # [ones, level_index]

    y_alpha = log2.(abs.(del1[l1:l2]) .+ 1e-300)
    y_beta = log2.(abs.(var1[l1:l2]) .+ 1e-300)
    y_gamma = log2.(abs.(cst[l1:l2]) .+ 1e-300)

    pa = X \ y_alpha
    pb = X \ y_beta
    pg = X \ y_gamma

    alpha = -pa[2]
    beta = -pb[2]
    gamma = pg[2]

    @printf("\nLinear regression estimates of MLMC parameters\n")
    @printf("    alpha = %f  (exponent for MLMC weak convergence)\n", alpha)
    @printf("    beta  = %f  (exponent for MLMC variance)\n", beta)
    @printf("    gamma = %f  (exponent for MLMC cost)\n", gamma)

    return alpha, beta, gamma
end
