# Internal API

These are internal helper functions. They are not part of the public API and may change without notice.

For framework extension work, `QMC.dimension`, `QMC.discrete_distribution`, and
`QMC.true_measure` are the core internal accessors used by the generic pipeline.
Built-in types provide these through conventional fields, while custom subtypes
may overload the methods directly to support alternative internal layouts.

```@autodocs
Modules = [QMC]
Public = false
```
