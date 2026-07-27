# Store Static-Analysis Artifacts in the Architecture Output Tree

## Status

Done — 2026-07-27

## Objective

Keep component checkouts read-only during static analysis by writing every
arch-analyzer artifact directly under the platform architecture output tree.

## Implementation

Static analysis now writes each component's artifacts to:

```text
architecture/<platform>/<component>/.analyzer/
├── component-architecture.json
├── ANALYZER_ARCHITECTURE.md
└── contracts/schemas/*.json
```

Architecture routing and eligibility consume that location, with a fallback to
checkout-root artifacts for compatibility with older runs. The current
checkout-based synthesis contract still receives a temporary compatibility copy
until the containerized synthesis backend mounts analyzer artifacts directly.

## Verification

- Static-analysis output-path, Markdown, schema, and platform-scoping tests pass.
- Architecture-routing tests pass.
- No generated architecture output, raw telemetry, or secrets were staged.
