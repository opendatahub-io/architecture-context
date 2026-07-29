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
├── analyzer_architecture.md
└── contracts/schemas/*.json
```

Architecture routing and eligibility consume that location. Eligibility retains
a fallback to checkout-root artifacts for compatibility with older runs; the
current generation path no longer copies analyzer artifacts into checkouts.

## Verification

- Static-analysis output-path, Markdown, schema, and platform-scoping tests pass.
- Architecture-routing tests pass.
- No generated architecture output, raw telemetry, or secrets were staged.
