# Task: Fix FACT-008 Telemetry-Backed Citation Scoring

## Goal

Stop `FACT-008` from being reported as a false regression when the response
answers the intended MLflow per-route authentication question, reads
`mlflow.md`, cites the component and line evidence, but does not spell out the
literal `mlflow.md` basename.

## Context

The `20260729T215258Z` `consumer-v1` rerun showed Tree B answering "No" for
MLflow per-route FastAPI gateway authentication enforcement. It read
`mlflow.md` and cited the relevant line evidence, but deterministic scoring
failed source citation because the answer used the `MLflow` stem and line
numbers rather than the basename. Gap acknowledgment also failed because the
answer used "does not describe" and "gap in ... documentation" instead of the
older exact phrase list.

This was a scoring-contract bug, not a static-analysis or generated
architecture bug.

## Changes

- Extended `benchmark/consumer-v1/score_results.py` so source citation can pass
  when the response cites the expected source stem and telemetry confirms the
  expected basename was read.
- Expanded gap acknowledgment phrases to include "does not describe", "not
  described", "documentation gap", and "gap in".
- Added focused regression tests in `tests/test_scorer_variants.py` with a
  negative control proving telemetry reads alone do not satisfy citation.

## Validation

- `uv run pytest tests/test_scorer_variants.py` — 37 passed.
- `uv run python3 benchmark/consumer-v1/validate.py` — 40 questions validated.
- Re-scored `tmp/evaluations/consumer-v1-rhoai-next-20260729T215258Z/raw-results.json`
  to `scored-results-fact008-rescored.json`.
- Generated `report-fact008-rescored.md`; `FACT-008` no longer appears in
  flagged regressions. The only remaining flagged regression is `INV-003`.

## Status

Done — 2026-07-29.
