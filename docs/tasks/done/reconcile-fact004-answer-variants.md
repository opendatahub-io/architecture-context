# Task: Reconcile FACT-004 Answer Variants

## Goal

Make the synchronized architecture benchmark accept semantically equivalent
answers for the model-registry CRD ownership question.

## Evidence

The full architecture benchmark at
`tmp/evaluations/consumer-v1-rhoai-next-20260801T234901Z/` flagged `FACT-004`.
Tree B correctly stated that the model-registry service defines zero CRDs and
that the operator owns `ModelRegistry`, but exact-match scoring failed because
the corpus did not accept the wording `defines zero CRDs`.

## Plan

1. Add the evidence-backed wording to both synchronized benchmark corpora.
2. Run focused `FACT-004` scoring.
3. Re-score the full architecture benchmark and record the result.

## Acceptance Criteria

- Both `consumer-v1` and `strategy-v1` accept `defines zero CRDs`.
- The focused question scores 1.0 for the regenerated tree.
- The full benchmark no longer flags `FACT-004`.

## Validation

- Both synchronized corpora validate successfully.
- The unchanged raw benchmark was rescored against the updated
  `consumer-v1` corpus at
  `tmp/evaluations/consumer-v1-rhoai-next-20260801T234901Z/`.
- `FACT-004` scored `1.0` for both Tree A and Tree B.
- Tree B overall increased from `0.6458` to `0.6583`; the regenerated
  architecture document required no change.
- The regenerated benchmark report shows no regressions.

The later full run at
`tmp/evaluations/consumer-v1-rhoai-next-20260803T160532Z/` exposed another
equivalent wording (`no custom resource definitions of its own`) and the
corpus was extended accordingly. Rescoring that unchanged raw run produced a
report with no regressions.

## Status

Complete — 2026-08-01.
