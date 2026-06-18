# Architecture

This page describes the target extensible architecture for QMC.jl. The goal is not to imitate Python- or Java-style classes literally, but to make the Julia implementation behave like a clear, stable, and composable framework in the same spirit as QMCPy's discrete-distribution / true-measure / integrand / stopping-criterion design.

## Purpose

QMC.jl already has the right high-level decomposition:

- `AbstractDiscreteDistribution`
- `AbstractTrueMeasure`
- `AbstractIntegrand`
- `AbstractStoppingCriterion`
- `AbstractKernel`

The main architectural problem is not lack of subtype relationships. It is that too much framework code still assumes specific stored field layouts such as `.dimension`, `.dd`, and `.true_measure`. That makes extension harder than it should be, because new subtype authors must often mimic internal storage conventions instead of only satisfying a documented interface.

The target design is therefore:

- subtype-oriented
- interface-driven
- dispatch-based
- field-layout-agnostic where practical
- testable through shared contracts

## Design Principles

### 1. Stable Abstract Roles

Each major component family should be defined first by its abstract role, not by its stored fields.

- A discrete distribution generates points in ``[0,1)^d``.
- A true measure transforms those points to the target domain.
- An integrand evaluates transformed samples.
- A stopping criterion orchestrates adaptive sampling and error control.
- A kernel supplies covariance or reproducing-kernel behavior where required.

### 2. Methods Over Field Coupling

Framework orchestration should depend on interface methods rather than direct field access whenever the interaction crosses subsystem boundaries.

Current preferred accessors:

- `QMC.dimension(obj)`
- `QMC.discrete_distribution(obj)`
- `QMC.true_measure(f)`

This keeps the pipeline compatible with existing built-in types while allowing new subtypes to choose different internal representations.

### 3. Multiple Dispatch Is the Polymorphism Mechanism

In QMC.jl, polymorphism should come from dispatch, not from attaching methods to class instances.

Representative examples:

- `gen_samples(dd::AbstractDiscreteDistribution, n)`
- `transform(tm::AbstractTrueMeasure, x)`
- `evaluate(f::AbstractIntegrand, x)`
- `integrate(sc::AbstractStoppingCriterion)`
- `spawn_tm(tm, dd_new)`
- `spawn_dd(dd, d_new)`

This is the Julia-native equivalent of “virtual methods” in an OO framework.

### 4. Encapsulation Means Interface Boundaries

Julia does not enforce private fields in the same way as some OO languages. Encapsulation here therefore means:

- external code depends on documented methods
- subsystem internals can change without breaking extensions
- authors do not need to reproduce another type's storage layout to interoperate

### 5. Contract Tests Over Informal Convention

An extensible framework needs tests that verify architectural contracts explicitly. Shared contract tests are more valuable than relying on convention or documentation alone.

## Architectural Layers

QMC.jl should be understood as four operational layers plus utilities:

### Point Generation Layer

`AbstractDiscreteDistribution` and its concrete subtypes own:

- dimension of the driver space
- randomization / scrambling state
- sequence generation
- replication semantics where relevant

They should not need to know about specific integrands or stopping rules.

### Measure Layer

`AbstractTrueMeasure` and its concrete subtypes own:

- the mapping from uniform driver points to the target domain
- distribution parameters such as bounds, covariance, or path construction data
- the association to an underlying discrete distribution

They should present a uniform transformation interface regardless of internal construction details.

### Model Layer

`AbstractIntegrand` and `AbstractMLIntegrand` own:

- evaluation on transformed samples
- model-specific parameters
- optional multi-output semantics
- optional multilevel semantics

They should interact with the outside world through `true_measure`, `dimension`, `evaluate`, `d_indv`, `combine_fun`, `bound_fun`, and multilevel hooks where appropriate.

### Algorithm Layer

`AbstractStoppingCriterion` owns:

- sample-budget logic
- error-bound logic
- tracing / diagnostics
- control-variate orchestration
- multilevel sample allocation

Stopping criteria should depend only on stable integrand and sampler interfaces, not on concrete subtype storage details.

### Utility Layer

Utility code should remain support code, not become a hidden fifth framework layer. Utility modules may help multiple subsystems, but they should avoid introducing new implicit architectural contracts unless those contracts are documented and tested.

## Current Pain Points

The main sources of architectural friction today are:

1. Direct cross-subsystem field access
   Examples include relying on `.dd`, `.true_measure`, or `.dimension` in shared orchestration paths.

2. Interface knowledge spread across implementation files
   Some contracts are implicit in how built-in types happen to be written rather than stated in one place.

3. Built-in storage conventions functioning as de facto public API
   This makes extension more brittle than necessary.

4. Incomplete contract testing
   Some extension behaviors are only exercised indirectly through built-in examples rather than through explicit interface tests.

5. Mixed concerns in some subsystem files
   Some files define both component-local behavior and framework-level orchestration assumptions.

## Target Extensibility Contract

For a new subtype to plug into the framework, the minimum required behavior should be documented per family.

### Discrete Distribution Contract

A subtype of `AbstractDiscreteDistribution` should provide:

- `QMC.dimension(dd)` or a compatible stored dimension
- `gen_samples(dd, n; kwargs...)`

Optional extension points include:

- replication-aware sample generation
- multilevel spawning via `spawn_dd`

### True Measure Contract

A subtype of `AbstractTrueMeasure` should provide:

- `QMC.discrete_distribution(tm)` or a compatible stored `dd`
- `QMC.dimension(tm)` or a compatible stored dimension
- `transform(tm, x)`

Optional extension points include:

- custom 3D replicated `transform`
- multilevel spawning via `spawn_tm`

### Integrand Contract

A subtype of `AbstractIntegrand` should provide:

- `QMC.true_measure(f)` or a compatible stored true measure
- `QMC.dimension(f)` or a compatible stored dimension
- `evaluate(f, x)`

Optional extension points include:

- `evaluate(f, x, compute_flags)`
- `d_indv`, `d_comb`, `combine_fun`, `bound_fun`, `dependency`

### Multilevel Integrand Contract

A subtype of `AbstractMLIntegrand` should provide:

- `ml_evaluate(f, x, level)`
- `dimension_at_level(f, level)`

Optional extension points include:

- `cost_at_level`
- custom multilevel spawning helpers when the default ones are insufficient

### Stopping Criterion Contract

A subtype of `AbstractStoppingCriterion` should provide:

- `integrate(sc)`

And should only assume interface-level access to the integrand/sampler pipeline except where a subsystem-specific contract is explicitly documented.

## Recommended Refactor Strategy

This should be done incrementally.

### Stage 1. Harden Accessor-Based Plumbing

Status:
- started

Tasks:

- use `dimension`, `discrete_distribution`, and `true_measure` in shared pipeline code
- avoid introducing new cross-file direct-field assumptions
- keep backward compatibility for existing built-in types

Success criterion:
- custom subtypes with different internal field names still work through the generic pipeline

### Stage 2. Reduce Cross-Subsystem Field Access

Tasks:

- audit framework code for direct access to:
  - `.dd`
  - `.true_measure`
  - `.dimension`
- replace those uses with interface calls in framework-level code
- leave component-local direct field access in place where it is clearly internal to that component

Success criterion:
- orchestration logic no longer depends on concrete storage layout

### Stage 3. Formalize Subtype Contracts

Tasks:

- document per-family required and optional methods
- add contract tests for each major abstract family
- provide minimal toy subtype examples in tests

Success criterion:
- extension breakage is caught as an interface regression, not only as a
  downstream algorithm failure

### Stage 4. Clarify Spawning and Multilevel Semantics

Tasks:

- document what `spawn_dd`, `spawn_tm`, and multilevel helper functions promise
- specify when default spawning is valid and when subtype authors must overload
- reduce assumptions that spawned objects preserve exact field layouts

Success criterion:
- multilevel extension becomes predictable rather than convention-based

### Stage 5. Separate Framework API from Storage Details

Tasks:

- identify concrete fields that currently behave like accidental public API
- either expose them intentionally through methods or declare them internal
- keep docs and tests aligned with the chosen boundary

Success criterion:
- storage refactors become possible without widespread downstream breakage

## Contract Testing Plan

The framework should eventually have dedicated test groups for:

- discrete-distribution interface compliance
- true-measure interface compliance
- integrand interface compliance
- multi-output integrand compliance
- multilevel integrand compliance
- stopping-criterion compatibility with toy subtype implementations

These tests should focus on:

- shape behavior
- finite outputs
- dimension consistency
- shared-point-stream semantics
- spawning behavior
- failure modes for unsupported contracts

## Documentation Plan

Architecture work should be documented in three places:

1. [components.md](components.md)
   For a high-level user-facing overview.

2. [api/internals.md](api/internals.md)
   For concrete internal helpers and interface accessors.

3. This page
   For design intent, boundaries, and refactor priorities.

Generated UML diagrams may help communicate the current type graph, but they are only a visualization of the architecture. They are not the architecture itself.

## Non-Goals

The target architecture is not trying to:

- emulate Python or Java classes literally
- move behavior into pseudo-method containers attached to instances
- replace Julia dispatch with OO method dispatch
- over-abstract numerically performance-critical code
- enforce privacy through conventions that the language does not support

## Practical Guidance for Contributors

When adding a new framework component:

- subtype the correct abstract family
- implement the required methods first
- avoid depending on another component's stored fields unless the code is clearly internal to that component family
- add contract-style tests, not just example-specific tests
- document any new cross-subsystem assumption explicitly

When refactoring existing framework code:

- prefer method calls to cross-file direct field access
- preserve numerical behavior first
- keep changes incremental and reviewable
- update tests and docs in the same change

## Recommended Next Work

The next architecture-focused tasks with the best payoff are:

1. finish the audit and replacement of framework-level direct field access
2. add explicit contract tests for custom true measures and integrands
3. document multilevel spawning semantics in more detail
4. add a contributor-facing “how to implement a new component” guide

That path strengthens extensibility while staying idiomatic to Julia.
