# Bug: FACT-008 Telemetry-Backed Citation False Negative

## Summary

`FACT-008` was reported as a Tree B regression even though the response
answered the intended MLflow per-route authentication question, read
`mlflow.md`, and cited line-level evidence from that file.

## Root Cause

The deterministic source-citation check only passed when the response included
the full expected source path or basename. It ignored telemetry showing that the
expected source file had been read. The gap-acknowledgment phrase list also did
not include common correct wording such as "does not describe" or
"documentation gap".

## Fix

`benchmark/consumer-v1/score_results.py` now treats a response as source-cited
when both conditions are true:

- the response cites the expected source stem, such as `MLflow`;
- telemetry confirms the expected basename, such as `mlflow.md`, was read.

Gap acknowledgment now accepts the additional documentation-gap phrasings
observed in the raw result.

## Validation

- `uv run pytest tests/test_scorer_variants.py` — 37 passed.
- `uv run python3 benchmark/consumer-v1/validate.py` — 40 questions validated.
- Re-scoring `20260729T215258Z` produced Tree B overall `0.5583`.
- `report-fact008-rescored.md` flags only `INV-003`; `FACT-008` scores `67%`
  for both trees and is no longer a regression.

## Status

Fixed — 2026-07-29.
