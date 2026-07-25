# Task: Define a Condition-Aware Canary Report

## Goal

Add a deterministic, non-executing canary manifest/report layer for the
analyzer-assisted condition experiment so rollout readiness can be reviewed
before any agent evaluation is authorized.

## Scope

- Add a canary manifest under `benchmark/analyzer-assisted-v1/` that selects a
  stable, representative question subset by explicit IDs and records the
  conditions, corpus identity, and provenance requirements.
- Add a read-only report/validator that consumes the canary manifest and
  condition plans or result artifacts and reports missing coverage, invalid
  condition status, missing provenance, and no-fallback violations.
- Keep output deterministic and machine-readable; do not calculate or invent
  quality scores when results are absent.
- Add focused tests for stable ordering, missing artifacts, pending conditions,
  provenance coverage, no-fallback violations, and explicit no-score behavior.

## Negative controls

- Do not launch agents or run paid, full-corpus, or external evaluations.
- Do not fabricate scores, telemetry, condition results, or artifact revisions.
- Do not modify generated architecture, manifests for the four conditions,
  consumer raw results, overlays, or ledger files beyond this task's records.

## Acceptance criteria

- [x] Canary subset and identities are explicit and deterministic.
- [x] Report distinguishes planned, available, unavailable, and missing-result
  states without baseline fallback.
- [x] Provenance and condition coverage violations are machine-readable.
- [x] Focused tests, lint, task note, session log, PLAN, and accepted scoped
  commit are recorded.

## Status

Implementation complete; accepted after focused review and validation.
