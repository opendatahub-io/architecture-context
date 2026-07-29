# Task: Reconcile Kueue CRD Count Scope

## Goal

Define and implement the CRD counting contract used for Kueue and similar
components so generated architecture facts and consumer-v1 expectations agree.

## Context

The clean `consumer-v1` rerun at `20260729T120959Z` flagged `FACT-007`.
Tree B answered 16 CRDs from generated `kueue.md`, while the corpus expects
11 core Kueue CRDs.

Tracking bug: `docs/bugs/open/kueue-crd-count-scope-drift.md`.

## Plan

1. Decide whether benchmark inventory questions count core owned CRDs,
   all CRD manifests, or persisted CRDs excluding aggregated APIs.
2. Update analyzer rendering and/or corpus expected answers to use the chosen
   contract consistently.
3. Add tests covering Kueue's core, configuration, and visibility API entries.
4. Rerun `FACT-007` or the focused consumer-v1 slice.

## Acceptance Criteria

- The CRD table or surrounding text clearly labels the counting scope.
- `FACT-007` has a source-backed expected answer aligned with that scope.
- Tests prevent Kueue-style configuration/visibility API entries from silently
  changing the intended count.

## Status

Pending.
