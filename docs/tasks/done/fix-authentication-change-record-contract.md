# Task: Fix Authentication Change-Record Contract

## Goal

Prevent partial-route agents from rejecting valid authentication synthesis by
using the authentication mechanism instead of the table's key columns in a
change record, or by emitting duplicate records for one row.

## Evidence

The MLflow replay at
`tmp/architecture-corpus-runs/rhoai.next-20260802T182238Z-2696509/logs/agents-mlflow-next/`
generated the candidate row:

`Tracking Server API | All | kubernetes-auth plugin | ...`

but emitted one candidate-only record and a second evidence record keyed as
`Tracking Server API :: kubernetes-auth plugin`. The merge correctly rejected
both records because the canonical authentication identity is
`Tracking Server API :: All` and each row identity must have one evidence
record.

## Plan

1. [x] Add explicit authentication row-key and one-record-per-identity rules
   to the summary skill.
2. [x] Add parser and skill-contract regression tests.
3. [x] Replay MLflow with `./custom-test.sh` and verify zero rejected changes.

## Acceptance Criteria

- Authentication change records use `endpoint :: methods` as their row key.
- The auth mechanism remains a cell value, not a key component.
- Multiple evidence references for one row are consolidated into one record.
- MLflow replay produces zero rejected changes and a valid merged document.

## Status

Complete — 2026-08-02. The MLflow replay applied 3 changes with zero
rejections, zero validation errors, zero denied calls, and a 1.0 source-read
justification ratio. The authentication record used the canonical
`Tracking Server API :: All` identity. Runtime was 398.3 seconds with 20 soft
discovery-budget hits; that performance issue remains tracked separately.
