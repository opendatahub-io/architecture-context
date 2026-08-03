# Task: Fix Authentication Row-Key Migrations

## Goal

Allow evidence-gated generation to split or rename analyzer authentication
surfaces without losing the source-backed candidate row or restoring stale
analyzer data.

## Plan

1. [x] Add explicit skill guidance that key-cell changes require delete/add,
   not an update to the old row key.
2. [x] Add skill-contract coverage for the migration rule and empty add/delete
   value columns.
3. [x] Add a merge fixture for `HTTP API :: All` to `Tracking Server API :: All`
   plus a separate gateway row.
4. [x] Retarget `custom-test.sh` to MLflow and replay the focused generation.

## Acceptance Criteria

- The old analyzer authentication row is removed only with exact evidence.
- The new tracking-server row is added with exact evidence and the canonical
  `endpoint :: methods` key.
- The gateway row remains independently represented.
- The focused replay has zero rejected or restored changes and a complete
  source-read justification ledger.

## Status

Contract guidance and focused merge coverage are complete. The targeted MLflow
replay completed successfully: 4 changes applied, 0 rejected, 0 restored, and
the source-read justification ratio was 1.0. The migration is resolved.
