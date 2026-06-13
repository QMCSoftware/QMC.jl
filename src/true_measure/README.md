# True Measures

This folder implements transforms from uniform samples in `[0,1)^d` to the measure under which an integrand is defined.

## Examples

- `uniform.jl`, `lebesgue.jl`: bounded-domain measures
- `gaussian.jl`, `student_t.jl`: continuous probability measures
- `brownian_motion.jl`, `geometric_brownian_motion.jl`: path-valued stochastic processes
- `triangular.jl`, `kumaraswamy.jl`, `johnsons_su.jl`, `bernoulli_cont.jl`: additional families
- `acceptance_rejection.jl`, `distributions_wrapper.jl`, `matern_gp.jl`, `uniform_triangle.jl`, `zero_inflated_exp_uniform.jl`: specialized transforms and wrappers

These types are the bridge between point generators and integrands.
