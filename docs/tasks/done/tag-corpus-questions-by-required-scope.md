# Task: Tag Corpus Questions by Required Scope

## Goal

Add a `required_scope` field to each corpus question so the evaluation
harness can filter or separately report questions by what content the
agent needs access to.

## Motivation

13 of 40 corpus v1 questions (32.5%) expect answers from files outside the
architecture document tree. Mixing in-scope and out-of-scope questions in a
single composite score obscures the signal. Tagging lets us report separate
scores for "architecture docs only" vs "architecture + overlays" vs "full
repo" and track each independently.

## Work

1. Add a `required_scope` field to each question in `corpus.json` with one of:
   - `architecture` — answerable from `architecture/rhoai.next/` alone
   - `architecture+overlays` — requires `overlays/` content
   - `full-repo` — requires `docs/notes/`, `docs/plans/`, or repo structure
2. Update `score_results.py` to include scope in scored output.
3. Update `generate_report.py` to show per-scope score breakdowns.
4. Re-score the existing v1 results to produce the scoped breakdown.

## Affected Questions by Scope

Original task listed 40 questions across 3 scopes. Reconciled against
the actual 31-question corpus (9 questions retired, see bug
`corpus-v1-below-minimum-question-count`):

- `architecture` (28 questions): INV-001, INV-003, INV-004, INV-005, INV-006,
  INV-008, INV-009, INV-010, FACT-001–010, INTG-001, INTG-005, INTG-007,
  INTG-009, NAV-001, NAV-002, NAV-005, NAV-007, NAV-008, NAV-009
- `architecture+overlays` (0 questions): all 8 overlay-dependent questions
  were retired (INTG-002/3/4/6/8/10, NAV-003/6); NAV-010 also absent
- `full-repo` (3 questions): INV-002, INV-007, NAV-004

### Reconciliation notes

- Original task had counting errors: listed 3 full-repo but named 4 IDs;
  27+10+3=40 but 27+10+4=41.
- INV-005 and INV-009 were re-authored with architecture-only sources
  (moved from `architecture+overlays` to `architecture`).
- NAV-001 (`architecture/current-ga`) classified as `architecture` (within
  architecture/ tree), not `full-repo` as originally listed.
- Classification is evidence-based: `source_file` prefix determines scope.

## Acceptance Criteria

- [x] Every question has a `required_scope` tag.
- [x] Report shows per-scope composite scores.
- [x] Architecture-only composite is reported as the primary quality metric.
- [x] A deterministic re-score of the existing raw v1 results is written to a
  clearly named separate artifact and its scope counts/report are validated;
  historical raw/scored results remain unchanged.

## Priority

MEDIUM — improves benchmark interpretability. Low implementation cost.

## Status

Complete — all acceptance criteria met. Re-score artifact at
`benchmark/consumer-v1/results/v1-ab/scored-results-scoped.json` with
companion `report-scoped.md`. Architecture-only primary metric: tree_a=0.5357,
tree_b=0.5000. Historical raw/scored results verified unchanged.
