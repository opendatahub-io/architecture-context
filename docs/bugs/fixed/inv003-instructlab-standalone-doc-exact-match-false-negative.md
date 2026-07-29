# Bug: INV-003 InstructLab Standalone Document Exact-Match False Negative

## Summary

`INV-003` was reported as a Tree B exact-match regression even though the
response correctly answered that InstructLab does not have its own standalone
architecture document in the RHOAI tree.

## Root Cause

The corpus variants accepted "InstructLab is not a standalone RHOAI component"
but did not accept the equally correct phrasing "InstructLab does not have its
own standalone architecture document." The deterministic scorer uses substring
matching, so the semantic match was missed.

## Fix

Added narrow accepted variants matching the observed correct wording while
preserving the negative answer and standalone-document requirement.

## Validation

- `uv run pytest tests/test_scorer_variants.py` — 38 passed.
- `uv run python3 benchmark/consumer-v1/validate.py` — 40 questions validated.
- Re-scoring `20260729T215258Z` produced Tree B overall `0.5708`.
- `report-inv003-rescored.md` reports no flagged regressions.

## Status

Fixed — 2026-07-29.
