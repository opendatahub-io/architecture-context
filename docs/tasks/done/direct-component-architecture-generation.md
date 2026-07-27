# Generate Component Architecture Directly in the Architecture Tree

## Status

Done — 2026-07-27

## Objective

Keep source checkouts focused on original repository content while making the
architecture tree the canonical home for analyzer inputs and generated
component documents.

## Implementation

Generation now uses:

```text
architecture/<platform>/<component>/.analyzer/
architecture/<platform>/<component>.md
```

Agents run with the component checkout as their source working directory, but
the execution guard separately authorizes reads from `.analyzer/` and writes to
the canonical architecture output plus private generation sidecars. Analyzer
JSON and Markdown are never copied into the checkout.

The obsolete collect phase, CLI command, orchestration step, and collection
utility were removed because generation now writes the final location directly.

## Verification

- 96 focused agent, architecture, routing, and static-analysis tests pass.
- Shell syntax, Python compilation, and affected-module lint pass.
- Generated outputs, telemetry, and secrets were not staged.
