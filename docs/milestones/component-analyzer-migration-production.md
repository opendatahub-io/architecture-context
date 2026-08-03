# Milestone: Component Analyzer Migration Production Acceptance

## Goal

Replace most per-component repository-wide agent discovery with the project-owned
`src/arch-analyzer` while preserving the canonical Markdown contract, source-backed
quality, explicit readiness fallbacks, and the existing platform/diagram boundary.

## Result

The migration is accepted against current production state:

| Measure | Result |
|---------|-------:|
| Configured static extraction and rendering | 90/90 |
| Structurally valid analyzer documents | 90/90 |
| Static phase, 10 workers, including build | 17.25s |
| Sufficient readiness | 63/90 (70.0%) |
| Insufficient readiness | 8/90 (8.9%) |
| Live analyzer identity preservation | 323/323 |
| Live analyzer-to-final conflicts | 0 |
| Dashboard raw structured fidelity | 162/166 (97.59%) |
| Dashboard adjudicated structured fidelity | 162/162 (100%) |

## Acceptance Criteria

- [x] The production pipeline builds and runs the self-contained analyzer.
- [x] Extraction, product normalization, Markdown adaptation, and synthesis ownership
      are separate and tested.
- [x] All configured repositories extract, render, and structurally validate.
- [x] Static performance and readiness distribution meet the migration-plan gates.
- [x] Sufficient and partial routes prohibit broad discovery in code.
- [x] Insufficient repositories retain an explicit legacy fallback.
- [x] Generated documents preserve analyzer facts and meet the adjudicated
      replacement-fidelity gate on a representative high-coverage component.
- [x] The representative same-model treatment materially reduces work without a
      quality regression.
- [x] `PLATFORM.md` synthesis and diagrams remain unchanged.
- [x] Full tests, linters, validators, smoke, and corpus checks pass.

## Evidence

- [Migration plan](../plans/architecture-context-static-migration.md)
- [Completion audit](../notes/architecture-context-static-migration.md)
- [Full-corpus routing coverage validation](../notes/architecture-context-static-migration.md)
- [Analyzer-only routing matrix](../notes/architecture-context-static-migration.md)
- [Analyzer-only full-corpus production validation](../notes/architecture-context-static-migration.md)
- [Readiness-routed live pilot](../notes/architecture-context-static-migration.md)
- [Dashboard fidelity audit](../notes/architecture-context-static-migration.md)

## Status

Done on 2026-07-18.
