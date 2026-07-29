# Task: Fix INV-003 InstructLab Standalone Document Variant

## Goal

Stop `INV-003` from being reported as a false exact-match regression when the
answer correctly says InstructLab does not have its own standalone architecture
document and is only present as a training backend/library dependency.

## Context

The `20260729T215258Z` `consumer-v1` rerun showed Tree B answering the intended
"No" for InstructLab:

- `InstructLab does not have its own standalone architecture document`
- `instructlab-training` appears under `distributed-workloads.md` and
  `training-hub.md`
- Training Hub uses InstructLab as a backend implementation, not a separate
  RHOAI component

The answer cited `training-hub.md`, so source citation passed. Only
deterministic exact-match failed because the corpus variants did not include
the observed correct phrasing.

## Changes

- Added narrow `INV-003` acceptable variants to
  `benchmark/consumer-v1/corpus.json`:
  - `InstructLab does not have its own standalone architecture document`
  - `does not have a dedicated architecture document`
- Added a focused scorer regression test in `tests/test_scorer_variants.py`.

## Validation

- `uv run pytest tests/test_scorer_variants.py` — 38 passed.
- `uv run python3 benchmark/consumer-v1/validate.py` — 40 questions validated.
- `uv run ruff check benchmark/consumer-v1/score_results.py tests/test_scorer_variants.py` — passed.
- Re-scored `tmp/evaluations/consumer-v1-rhoai-next-20260729T215258Z/raw-results.json`
  to `scored-results-inv003-rescored.json`.
- Generated `report-inv003-rescored.md`; no regressions detected.

## Status

Done — 2026-07-29.
