# Bug: Partial Run Insight Artifacts Fail Validation

## Observed

In the completed 97-component partial run on 2026-07-27, 96 component run
records were classified with `insight_artifact_validation` errors. The errors
include missing platform/version fields, empty claims/reasoning, unsupported
categories, missing applicability/confidence, and absent provenance references.
Only 1/97 component run records was marked successful.

## Impact

Component architecture files were produced, but run success and benchmark
metrics are contaminated. The error is separate from analyzer extraction
quality and must be fixed before treating run records as clean evaluation
evidence.

## Evidence

- `docs/notes/partial-run-log-demand-report.md`
- ignored `tmp/partial-run-demand-inventory.json`
- representative `logs/generate-architecture/*.run.json` records

## Status

Open
