# Task: Fix Runtime-Tail Change and Read-Ledger Contracts

## Goal

Reduce false or avoidable diagnostics in partial-route runtime-tail replays
without weakening evidence-gated assembly.

## Evidence

The replay at
`tmp/architecture-corpus-runs/rhoai.next-20260801T225723Z-2275124/logs/agents-runtime-tail-replay/`
completed all four components successfully. TrustyAI emitted 15 structured
change records for candidate-only facts but did not include the corresponding
rows in the candidate tables, so the merge rejected every record. MLServer
performed four bounded reads of `mlserver/settings.py`, but its read sidecar
collapsed them into one `1-470` range and reported a misleading oversized-read
diagnostic.

## Plan

1. [x] Require candidate table rows to accompany every structured change
   record.
2. [x] Require separate source-read ledger entries for separate bounded reads of
   the same file; do not merge disjoint or bounded ranges into a whole-file
   range.
3. Replay TrustyAI and MLServer and verify applied/rejected changes,
   justification ranges, runtime, and document validation.

## Acceptance Criteria

- Candidate-only change records have matching candidate rows and are applied
  when their evidence is valid and their category is allowed.
- Bounded repeated reads do not become a false oversized-read diagnostic.
- Analyzer-owned rows remain preserved and final documents validate.
- TrustyAI and MLServer show no avoidable change-record or read-ledger
  diagnostics.

## Validation

- The first contract-fix replay reduced TrustyAI from 15 rejected records to 22
  applied records and one source-adjudicated rejection. Its source-read ledger
  was complete and its document validated.
- MLServer applied 16 endpoint/integration changes. Its remaining diagnostics
  were two invalid pseudo-evidence records, readiness-budget exclusions for
  gRPC updates, and a sidecar range aggregated as `1-520`.
- Added source-read operation-range telemetry so the validator can distinguish
  aggregated bounded reads from a genuinely oversized read. Focused tests pass
  (`62 passed`).
- Final replay at
  `tmp/architecture-corpus-runs/rhoai.next-20260801T225723Z-2275124/logs/agents-runtime-tail-contract-fix/`
  passed for both components: MLServer applied 22 changes and rejected 0;
  TrustyAI applied 14 changes and rejected 0. Both documents validated, with
  no diagnostics and 1.0 source-read justification ratios.

## Status

Complete — 2026-08-02. The contract diagnostics are resolved; the broader
runtime-tail duration issue remains open for performance optimization.
