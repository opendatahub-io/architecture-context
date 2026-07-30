# Task: Reconcile Kueue CRD Count Scope

## Goal

Define and implement the CRD counting contract used for Kueue and similar
components so generated architecture facts and consumer-v1 expectations agree.

## Context

The clean `consumer-v1` rerun at `20260729T120959Z` flagged `FACT-007`.
Tree B answered 16 CRDs from generated `kueue.md`, while the corpus expects
11 core Kueue CRDs.

Tracking bug: `docs/bugs/fixed/kueue-crd-count-scope-drift.md`.

## Plan

1. Decide whether benchmark inventory questions count core owned CRDs,
   all CRD manifests, or persisted CRDs excluding aggregated APIs.
2. Update analyzer rendering and/or corpus expected answers to use the chosen
   contract consistently.
3. Add tests covering Kueue's core, configuration, and visibility API entries.
4. Rerun `FACT-007` or the focused consumer-v1 slice.

## Decision

`FACT-007` counts **core API CRDs**: rows whose API role is `Core API`. The
rendered architecture may still list configuration and visibility API rows, but
the CRD table must label those roles and state both the core count and total
CRD/API row count.

For Kueue this means:

- 11 core API CRDs in `kueue.x-k8s.io`.
- 16 total CRD/API rows when `config.kueue.x-k8s.io` and
  `visibility.kueue.x-k8s.io` rows are included.

## Changes

- Added `API Role` to rendered CRD rows.
- Added deterministic CRD role classification:
  - `Core API`
  - `Configuration API`
  - `Visibility API`
- Added a CRD count-scope line before the CRD table.
- Rendered the deterministic CRD section from Kueue's
  `component-architecture.json` analyzer data and promoted that section to
  `architecture/rhoai.next/kueue.md` while preserving the authored narrative.
- Updated `FACT-007` expected answer and `source_line` to the new explicit
  contract.

## Acceptance Criteria

- [x] The CRD table or surrounding text clearly labels the counting scope.
- [x] `FACT-007` has a source-backed expected answer aligned with that scope.
- [x] Tests prevent Kueue-style configuration/visibility API entries from
  silently changing the intended count.

## Validation

- `GOCACHE=/tmp/arch-analyzer-go-cache go test ./...`
- `uv run pytest tests/test_scorer_variants.py`
- `uv run python3 benchmark/consumer-v1/validate.py`
- `uv run python scripts/lint_architecture_docs.py architecture/rhoai.next/kueue.md`
- Focused user-run `FACT-007` re-evaluation:
  `tmp/evaluations/consumer-v1-rhoai-next-20260730T005726Z/`
  - Tree A overall: `1.0`
  - Tree B overall: `1.0`

## Status

Done — 2026-07-30. Focused `FACT-007` re-evaluation passed for both trees;
the next verification step is a full consumer-v1 rerun.
