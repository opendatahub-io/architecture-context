# Task: Validate Context Telemetry in Canary Readiness

## Goal

Require available-condition canary results to prove versioned context
telemetry, per-tree provenance, and condition-level attachment evidence before
rollout readiness.

## Scope and controls

- Updated `benchmark/analyzer-assisted-v1/canary_report.py` and
  `tests/test_canary_report.py` only for the implementation.
- Preserved no-results, no-fallback, existing provenance, coverage, and
  deterministic ordering behavior.
- Did not alter experiment availability, result schemas, permissions, scoring,
  telemetry instrumentation, or optional OTel dependencies.
- No evaluation or MLflow run was performed.

## Acceptance criteria

- [x] Missing or malformed context telemetry produces deterministic
  `missing-context-telemetry` violations for available-condition results.
- [x] Valid baseline, index-md, arch-query, and combined records pass using the
  exact current `lib.context_telemetry.CONTRACT_VERSION`.
- [x] Missing envelope provenance is rejected; unavailable and no-results cases
  remain safe.
- [x] 87 focused tests, canary `--validate-only`, Ruff, and diff checks pass.
- [x] No evaluation or paid benchmark API call was performed.

## Implementation summary

Added `_check_context_telemetry()` and the `missing-context-telemetry`
violation type. It requires per-tree `context_provenance`, envelope and
condition-level provenance, true `events_attached_per_tree`, and exact current
contract version matching. Added 25 focused tests, including refinement tests
for missing envelope provenance and wrong versions.

## Status

Accepted 2026-07-25 after independent review. Two delegated container-agent
runs cost $4.6831315. No evaluation or MLflow run was performed.
