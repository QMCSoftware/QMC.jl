# Internal API

These are internal helper functions. They are not part of the public API and may change without notice.

For framework extension work, `QMC.dimension`, `QMC.discrete_distribution`, and `QMC.true_measure` are the core internal accessors used by the generic pipeline. Built-in types provide these through conventional fields, while custom subtypes may overload the methods directly to support alternative internal layouts.

The default methods intentionally bridge existing storage conventions into the interface:

- `dimension(dd::AbstractDiscreteDistribution)` falls back to a `dimension` field when present.
- `discrete_distribution(tm::AbstractTrueMeasure)` falls back to a `dd` field when present.
- `true_measure(f::AbstractIntegrand)` falls back to a `true_measure` field when present.

That compatibility layer keeps existing concrete types simple while allowing new subtype authors to define method-based interfaces instead of copying the same field names.

```@autodocs
Modules = [QMC]
Public = false
```
