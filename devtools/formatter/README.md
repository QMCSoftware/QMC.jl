# Formatter Environment

This folder contains the dedicated Julia environment used for formatting-related tooling.

## Files

- `Project.toml`: formatter dependencies.
- `Manifest.toml`: formatter environment lockfile.

Keeping formatting tools here avoids adding them to the main package or docs dependency sets.
