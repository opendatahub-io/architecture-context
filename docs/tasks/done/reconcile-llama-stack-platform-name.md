# Task: Reconcile Llama Stack Platform Name

## Goal

Resolve the `NAV-010` mismatch between the corpus expectation
`OGX (Llama Stack)` and the current Tree B platform/component-map evidence for
`rhds-llama-stack-distribution`.

## Context

The `20260729T165013Z` rerun flagged `NAV-010`. Tree B answered from the
current platform tree and component map, which list `rhds-llama-stack-distribution`
and Llama Stack provider components. The corpus expects the older display name
`OGX (Llama Stack)` / `OpenShift Generative Extensibility`.

Tracking bug:
`docs/bugs/fixed/llama-stack-platform-name-drift.md`.

## Plan

1. Decide whether `OGX (Llama Stack)` is still the canonical consumer-facing
   platform name.
2. If yes, update platform/component-map generation so the alias is preserved
   as first-class navigation evidence.
3. If no, update or retire `NAV-010` so the expected answer matches the
   current tree.
4. Rerun `NAV-010` or the focused consumer-v1 slice.

## Acceptance Criteria

- The platform tree exposes a clear, source-backed answer for the Llama Stack
  component name.
- `NAV-010` is aligned with that answer or removed from the active rolling
  benchmark.
- A focused rerun no longer flags `NAV-010`.

## Status

Done. The current `rhoai.next` platform tree is source-backed by
`architecture/rhoai.next/PLATFORM.md` lines `66-70`, which list both
`ogx-distribution` and `rhds-llama-stack-distribution`. The concrete current
RHOAI Llama Stack distribution component is
`rhds-llama-stack-distribution`; `OGX (Llama Stack)` remains an accepted
legacy/product alias for older tree answers.

Implementation:

- Updated `benchmark/consumer-v1/corpus.json` `NAV-010` expected answer to
  describe the current `rhoai.next` component names.
- Added acceptable variants for `rhds-llama-stack-distribution` and
  `ogx-distribution`, while retaining the previous `OGX` variants so older
  Tree A answers still score as semantically acceptable.
- Updated `NAV-010` `source_line` from `101` to `66-70`.

Validation:

- `uv run python3 benchmark/consumer-v1/validate.py` passed.
- Re-scored `tmp/evaluations/consumer-v1-rhoai-next-20260729T215258Z/raw-results.json`
  to `scored-results-nav010-rescored.json`.
- Generated `report-nav010-rescored.md`; the re-score flags only `INV-003`
  and `FACT-008`. `NAV-010` scores Tree A `50%`, Tree B `100%`, and is no
  longer flagged.
