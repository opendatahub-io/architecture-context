# Task: Improve Readiness-Routed Synthesis Coverage

## Goal

Recover valid agent-owned structured architecture facts without giving up analyzer
preservation or returning to repository-wide discovery.

## Context

The first full production-routing run preserved 8,192/8,192 analyzer identities and
reduced workflow wall time by 44.57% from the first full run. Exact fixture recall
fell from 35.66% to 24.82%, however, and source review found that partial category
selection can omit empty architecture components, authentication, integration
points, and internal dependencies.

This task addresses the routing defect before another full paid platform run.

## Acceptance Criteria

- [x] Make partial category selection use one explicit architecture-value priority
      across coverage-surface gaps and empty analyzer tables.
- [x] Align coverage hints with analyzer keys actually emitted by the corpus,
      including `source` and `platform_semantics`; remove or justify dead hint keys.
- [x] Ensure a partial repository with source components or semantic tables missing
      cannot have all agent-owned categories displaced by manifest-only gaps.
- [x] Keep source access bounded, broad exploration prohibited, and all structured
      mutations evidence-gated.
- [x] Add routing tests that reproduce the `batch-gateway` policy failure from its
      analyzer coverage and empty-table shape.
- [x] Add a quality assertion for detailed synthesis paired with unexpectedly empty
      high-value structured tables.
- [x] Run a small same-model matrix containing `batch-gateway`, one sufficient
      component with a large loss, and one component whose current fidelity is high.
- [x] Source-adjudicate facts recovered from the older full-agent output instead of
      treating raw fixture equality as truth.
- [x] Preserve 100% analyzer structured identities with zero unexplained conflicts
      in the matrix.
- [x] Demonstrate that the matrix improves valid architecture-component,
      authentication, integration, and internal-dependency coverage without broad
      discovery.
- [x] Record tool calls, reads, source-file count, tokens, cost, and wall time before
      deciding whether another 90-component run is warranted.

## Candidate Matrix

| Component | Readiness | Reason |
|-----------|-----------|--------|
| `batch-gateway` | partial | Reproduces category-budget displacement; 1/51 fixture rows in the new run versus 27/51 previously |
| `trustyai-explainability` or `eval-hub` | sufficient | Large sufficient-route recall loss and sparse structured output |
| `odh-dashboard` | sufficient | High-fidelity regression control at 162/166 |

## Non-Goals

- Do not weaken analyzer preservation or evidence requirements.
- Do not restore broad exploration for sufficient or partial routes.
- Do not select a new static extractor from raw fixture recall alone.
- Do not run `PLATFORM.md` synthesis or diagram generation.
- Do not launch another full paid corpus until the small matrix is reviewed.

## Related

- [Fixed routing bug](../../bugs/fixed/readiness-routing-omits-agent-owned-categories.md)
- [Readiness-routed corpus comparison](../../notes/rhoai-next-readiness-routed-corpus-comparison-2026-07-18.md)
- [Bounded routing matrix](../../notes/readiness-routing-coverage-matrix-2026-07-18.md)
- [Component analyzer migration plan](../../plans/component-analyzer-migration.md)

## Status

Completed on 2026-07-18.

## Results

The corrected Opus matrix recovered 16 source-adjudicated high-value facts across
`batch-gateway` and `eval-hub`; `odh-dashboard` remained unchanged as the regression
control. It preserved 390/390 analyzer identities with zero conflicts, passed the
quality gate for all three documents, read 16 source files, and completed in 342.48
seconds for $3.8907. The subsequent 90-component run increased high-value structured
coverage by 325 rows (18.81%) over the prior routed run at 7.87% higher cost. It
completed in 33.11 minutes and passed every required gate after four source-backed
analyzer false positives were recorded as accepted row corrections. The permanent
matrix and full-corpus notes record the evidence and decisions.
