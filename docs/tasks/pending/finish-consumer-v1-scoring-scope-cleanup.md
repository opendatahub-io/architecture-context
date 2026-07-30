# Task: Finish Consumer V1 Scoring and Scope Cleanup

## Goal

Resolve the remaining deterministic scoring and out-of-scope corpus artifacts
that are known to create false negatives in consumer-v1 results.

## Context

Two existing open bugs track scoring/scope cleanup:

- `docs/bugs/open/corpus-v1-exact-match-variants-too-strict.md`
- `docs/bugs/open/corpus-v1-meta-questions-outside-architecture-tree.md`

The clean `20260729T120959Z` rerun added fresh evidence for `INV-003`: Tree B
answered the question semantically but failed exact-match and citation checks.

The `20260729T165013Z` rerun added fresh cleanup evidence:

- `INV-003` remains a semantic-but-not-deterministic exact-match false
  negative.
- `INV-009` now has correct ModelMesh runtime evidence and a correct answer,
  but the deterministic exact-match variants do not accept the broader KServe
  plus ModelMesh response.
- `FACT-008` gives the intended "No" answer for MLflow per-route auth
  enforcement and reads `mlflow.md`, but fails source citation because the
  response cites line numbers without naming the expected file.

The `20260729T215258Z` rerun refreshed the current cleanup scope:

- `INV-003` remains an exact-match-only regression.
- `FACT-008` initially remained a citation/gap-acknowledgment regression for
  the MLflow per-route authentication question; it was fixed by
  `docs/tasks/done/fix-fact008-telemetry-backed-citation-scoring.md`.
- `INV-009` is no longer flagged as a regression in the latest report.
- `NAV-010` was resolved separately by aligning the benchmark to the current
  `rhds-llama-stack-distribution` component name while retaining `OGX` as an
  accepted legacy/product alias.

The `FACT-008` re-score against the same raw results wrote
`scored-results-fact008-rescored.json` and `report-fact008-rescored.md`. Tree B
overall is now `0.5583`; `FACT-008` scores `67%` for both trees and is no
longer flagged. The only remaining flagged regression in that report is
`INV-003`.

The `INV-003` re-score against the same raw results wrote
`scored-results-inv003-rescored.json` and `report-inv003-rescored.md`. Tree B
overall is now `0.5708`; `INV-003` scores `100%` for both trees and the report
has no flagged regressions.

The fresh full `20260730T011953Z` rerun kept `FACT-007` fixed at `100%` for
both trees, but surfaced a new exact-match-only `INV-003` phrasing:
`InstructLab does not have its own architecture document`. Added that narrow
variant and re-scored the same raw results to
`scored-results-inv003-rescored.json` and `report-inv003-rescored.md`. Tree B
overall is now `0.55`; `INV-003` scores `100%` for both trees and the report
has no flagged regressions.

## Plan

1. Expand deterministic variants where the answer is semantically correct and
   source-backed.
2. Retire or retarget questions whose expected source is outside the
   architecture evaluation tree.
3. Keep full-repo process metadata out of architecture-only benchmark scope.
4. Validate the corpus and rerun or re-score the affected slice.

## Acceptance Criteria

- `INV-003` no longer fails solely because of acceptable-variant phrasing.
  **Done 2026-07-29.**
- `FACT-008` either cites the expected source file reliably and acknowledges
  the documented gap, or the scoring contract accounts for telemetry-backed
  reads in an explicit way. **Done 2026-07-29.**
- Meta questions outside the architecture tree are retired, retargeted, or
  explicitly scoped outside the primary architecture metric.
- Corpus validation passes with the expected active question count and tier
  balance.

## Status

Pending for broader scope/meta cleanup; the current `20260729T215258Z`
and `20260730T011953Z` regression lists are reconciled.
