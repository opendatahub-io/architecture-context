# Bug: Architecture Context Static Migration Bug Cluster

## Summary

During the architecture-context static migration, the implementation and
evaluation loops exposed a large set of defects across analyzer extraction,
artifact layout, bounded synthesis, merge preservation, routing, telemetry,
and consumer-benchmark contracts. The individual records were useful while
iterating, but the fixes are now one completed migration-level change rather
than an active collection of independent bugs.

This record consolidates 36 fixed bug reports. The detailed implementation
history remains available in the original checkout and in the migration task,
plans, notes, tests, and validation artifacts.

## Fixed areas

- Analyzer correctness and preservation: incomplete CRD patches, duplicate
  security evidence, empty-cell adjudications, authentication row-key changes,
  stale snapshots, serving-runtime evidence, and platform serving paths.
- Pipeline and routing behavior: stale layout/test expectations, analyzer
  artifact discovery, denied tools, oversized source reads, partial-route
  change records, insight applicability, and source-read ledger mismatches.
- Generation and runtime operations: nonblocking concurrent output, rootless
  Podman runtime fallback, analyzer-backed artifact promotion, and component
  runtime diagnostics.
- Evaluation and benchmark contracts: language inference, citation scoring,
  CRD-count scope, rolling inventory counts, exact-match variants, overlay and
  metadata scope, source citations, domain reporting, and consumer-evaluation
  startup behavior.
- Contract and quality regressions: authentication migration records, MLflow
  REST search, report generation, corpus minimums, and mixed-regression triage.

## Resolution

The affected implementations, schemas, prompts, parsers, renderers, routing
logic, benchmark contracts, and regression tests were updated incrementally.
The current migration policy and evidence are summarized in:

- [Architecture context static migration](../../tasks/done/complete-architecture-context-static-migration.md)
- [Analyzer-assisted agent architecture plan](../../plans/architecture-context-static-migration.md)
- [Analyzer ownership migration v1 milestone](../../milestones/analyzer-ownership-migration-v1.md)
- [Analyzer residual agent gaps](../../notes/architecture-context-static-migration.md)

Representative validation included analyzer preservation and conflict gates,
static replay, 97-component generation, focused Go/Python tests, architecture
schema validation, and consumer-v1 benchmark rescoring. The final fixes were
source-backed and preserved explicit residuals instead of hiding unsupported
behavior as analyzer certainty.

## Related records that remain separate

- [Partial-route component runtime remains high](../open/partial-route-component-runtime-remains-high.md)
  remains open for performance follow-up.
- [Upstream analyzer output-dir behavior](../wontfix/arch-analyzer-output-dir.md)
  remains an intentional wontfix because the project-owned analyzer superseded
  that upstream CLI path.

## Status

Resolved and consolidated on 2026-08-03.
