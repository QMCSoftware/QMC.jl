"""
    bernoulli_poly(k::Int, x::Real)

Compute the Bernoulli polynomial B_k(x) for k = 0, 1, ..., 6.

Bernoulli polynomials arise in lattice rule kernel computations
and error analysis for quasi-Monte Carlo methods.
"""
function bernoulli_poly(k::Int, x::Real)
    if k == 0
        return 1.0
    elseif k == 1
        return x - 0.5
    elseif k == 2
        return x^2 - x + 1.0/6.0
    elseif k == 3
        return x^3 - 1.5*x^2 + 0.5*x
    elseif k == 4
        return x^4 - 2.0*x^3 + x^2 - 1.0/30.0
    elseif k == 5
        return x^5 - 2.5*x^4 + (5.0/3.0)*x^3 - x/6.0
    elseif k == 6
        return x^6 - 3.0*x^5 + 2.5*x^4 - 0.5*x^2 + 1.0/42.0
    else
        error("bernoulli_poly only implemented for k = 0, ..., 6, got k = $k")
    end
end

"""
    bernoulli_number(k::Int)

Compute the Bernoulli number B_k = B_k(0) for k = 0, 1, ..., 6.

The first several Bernoulli numbers are:
  B_0 = 1, B_1 = -1/2, B_2 = 1/6, B_3 = 0,
  B_4 = -1/30, B_5 = 0, B_6 = 1/42.
"""
function bernoulli_number(k::Int)
    return bernoulli_poly(k, 0.0)
end

"""
    bernoulli_poly_vec(k::Int, x::AbstractVector)

Vectorized Bernoulli polynomial evaluation: compute B_k(x_i) for each element.
"""
function bernoulli_poly_vec(k::Int, x::AbstractVector{<:Real})
    return bernoulli_poly.(k, x)
end

"""
    lattice_kernel_component(x::Real, alpha::Int=2)

Compute the one-dimensional shift-invariant kernel component for lattice rules:

    omega_alpha(x) = (-1)^(alpha+1) * (2*pi)^(2*alpha) / (2*alpha)! * B_{2*alpha}(x)

where `x` should be the fractional part of the shifted point and `alpha` controls smoothness.
Only `alpha = 1, 2, 3` are supported (using B_2, B_4, B_6).
"""
function lattice_kernel_component(x::Real, alpha::Int=2)
    if alpha < 1 || alpha > 3
        error("lattice_kernel_component: alpha must be 1, 2, or 3, got alpha = $alpha")
    end
    k = 2 * alpha
    sign_factor = (-1)^(alpha + 1)
    coeff = (2.0 * pi)^k / factorial(k)
    return sign_factor * coeff * bernoulli_poly(k, mod(x, 1.0))
end
