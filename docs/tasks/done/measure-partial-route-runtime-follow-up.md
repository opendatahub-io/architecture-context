# Task: Measure Partial Route Runtime Follow-up

## Goal

Run a post-remediation measurement that determines whether partial-route
runtime materially improved after analyzer evidence and runtime-breakdown
changes.

## Context

`docs/bugs/open/partial-route-component-runtime-remains-high.md` remains open.
Runtime-breakdown reports now exist, and the partial-run log mining task is
complete, but the bug needs a follow-up full run or representative replay to
prove improvement and identify remaining slow-component gaps.

## Plan

1. Select the full-run or representative replay scope.
2. Capture per-component wall time, agent activity counts, denied calls,
   targeted reads, edit counts, and validation outcomes.
3. Compare against the 97-component high-runtime baseline.
4. Update the runtime bug with measured improvement or remaining bottlenecks.

## Acceptance Criteria

- A measurement report records baseline versus follow-up runtime.
- Remaining slow components are linked to concrete missing evidence categories.
- `partial-route-component-runtime-remains-high.md` is either closed or updated
  with current evidence and next actions.

## Status

Completed on 2026-07-30.

Measurement report:
`docs/notes/partial-route-runtime-follow-up-2026-07-30.md`.

Result: follow-up reliability materially improved and runtime indicators
improved versus the validation-contaminated 97-component baseline, but
`docs/bugs/open/partial-route-component-runtime-remains-high.md` remains open
with narrowed remaining bottlenecks.
