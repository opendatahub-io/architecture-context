# ADR-0019: Analyzer-Owned Facts with Bounded, Evidence-Gated Synthesis

## Status

Accepted

## Date

2026-07-26

## Context

Architecture documents need richer narrative explanations, but allowing an
agent to regenerate the complete document makes deterministic facts vulnerable
to omission, invention, or accidental rewriting. A missing analyzer finding
must not be interpreted as proof that the fact is absent. Earlier legacy
generation also encouraged broad source discovery even when static evidence was
already sufficient.

## Decision

Use the project-owned static analyzer as the authoritative producer of
structured architecture facts, source evidence, coverage, schemas, and explicit
unknown or not-extracted states.

When valid analyzer artifacts exist:

- route all readiness classifications through bounded partial or
  extend-and-improve synthesis;
- give the agent analyzer context and declared residual gaps before allowing
  bounded source inspection;
- treat agent output as a non-authoritative candidate containing narrative or
  explicitly evidenced residual changes;
- apply only changes that pass preservation, provenance, structural, and
  evidence-gated merge checks; and
- retain analyzer-baseline or legacy fallback for missing/invalid analyzer
  artifacts and explicit operator override.

Analyzer-owned facts, explicit unknowns, and unsupported behavior must not be
silently replaced by agent inference. Prior generated documents are comparison
fixtures, not synthesis inputs.

## Consequences

Positive:

- Deterministic facts remain stable across agent runs and can be independently
  validated.
- Agents can add useful explanation where static extraction is insufficient
  without gaining authority over the baseline.
- Missing evidence remains visible instead of becoming an inferred absence.
- Rollout can be staged and measured while the legacy route remains available.

Negative:

- The pipeline must maintain analyzer schemas, candidate contracts, merge
  validators, and fallback behavior.
- Some useful improvements require analyzer changes rather than prompt-only
  changes.
- Bounded synthesis can leave residual gaps until the analyzer or a reviewed
  correction supplies stronger evidence.

## Related Records

- [Architecture context static migration note](../notes/architecture-context-static-migration.md)
- [Architecture context static migration plan](../plans/architecture-context-static-migration.md)
- [Analyzer ownership migration milestone](../milestones/analyzer-ownership-migration-v1.md)
