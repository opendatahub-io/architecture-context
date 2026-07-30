# Bug: Analyzer Snapshot Uses Stale Checkout Layout

## Summary

The full `rhoai.next` wrapper exits after successful static analysis because
`snapshot-analyzers` only searches checkout roots for analyzer artifacts.
Current static analysis writes those artifacts under the run candidate tree at
`architecture/<platform>/<component>/.analyzer/`.

## Evidence

Run:
`tmp/architecture-corpus-runs/rhoai.next-20260730T192039Z-851562/`

- Static analysis: 97 extracted, 0 failed, 97 Markdown baselines rendered.
- Snapshot: 0 copied, 97 components reported missing
  `analyzer_architecture.md`.
- Actual artifact example:
  `architecture/rhoai.next/MLServer/.analyzer/analyzer_architecture.md`.

## Impact

High for the full-run wrapper. Generation never starts, even though static
analysis completed successfully.

## Fix

`snapshot_analyzers()` now prefers the current candidate `.analyzer` directory
and retains the checkout-root layout as a compatibility fallback.

## Status

Resolved 2026-07-30. The fix is covered by a regression test, and the full
wrapper run at
`tmp/architecture-corpus-runs/rhoai.next-20260730T194519Z-863253/` copied
97/97 analyzer artifact pairs and completed component generation with zero
phase failures.
