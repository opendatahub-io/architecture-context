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

- `architecture` (27 questions): INV-001, INV-003, INV-004, INV-006, INV-008,
  INV-010, FACT-001–010, INTG-001, INTG-005, INTG-007, INTG-009, NAV-002,
  NAV-005, NAV-007, NAV-008, NAV-009
- `architecture+overlays` (10 questions): INV-005, INV-009, INTG-002,
  INTG-003, INTG-004, INTG-006, INTG-008, INTG-010, NAV-003, NAV-006,
  NAV-010
- `full-repo` (3 questions): INV-002, INV-007, NAV-001, NAV-004

## Acceptance Criteria

- [ ] Every question has a `required_scope` tag.
- [ ] Report shows per-scope composite scores.
- [ ] Architecture-only composite is reported as the primary quality metric.

## Priority

MEDIUM — improves benchmark interpretability. Low implementation cost.

## Status

Pending.
