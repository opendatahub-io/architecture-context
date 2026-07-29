# Bug: Llama Stack Platform Name Drift

## Summary

The `consumer-v1` rerun at `20260729T165013Z` flagged `NAV-010` because Tree B
answers that the platform component tree uses `rhds-llama-stack-distribution`,
while the corpus expects `OGX (Llama Stack)` with the description
`OpenShift Generative Extensibility`.

## Evidence

- Evaluation report:
  `tmp/evaluations/consumer-v1-rhoai-next-20260729T165013Z/report.md`
- Raw results:
  `tmp/evaluations/consumer-v1-rhoai-next-20260729T165013Z/raw-results.json`
- Question: `NAV-010`
- Expected answer: `OGX (Llama Stack)` / `OpenShift Generative Extensibility`
- Tree B response: `rhds-llama-stack-distribution`, plus
  `llama-stack-provider-ragas` and `llama-stack-provider-trustyai-garak`
- Tree B evidence:
  - `PLATFORM.md` line 70 lists `rhds-llama-stack-distribution`
  - `PLATFORM.md` line 66 lists `ogx-distribution`
  - `PLATFORM.md` line 387 lists `ogx-k8s-operator` as a new OGX inference
    gateway operator
  - `component-map.json` contains both `rhds-llama-stack-distribution` and
    Llama Stack provider entries

## Impact

MEDIUM — this is a navigation/alias question. Consumers can land on a concrete
Llama Stack distribution component instead of the expected OGX display name,
which means either the current platform tree has changed or the tree no longer
preserves the intended product alias clearly enough.

## Expected

Decide the canonical consumer-facing name for Llama Stack in `rhoai.next`:

- If `OGX (Llama Stack)` remains the intended platform display name, update
  the platform/component-map generation so the alias is first-class and easy
  to retrieve.
- If `rhds-llama-stack-distribution` is now the canonical component name,
  update or retire `NAV-010` so it does not expect the older OGX phrasing.

## Status

Fixed. `NAV-010` was a stale benchmark expectation rather than a generated
architecture content bug. The current platform tree lists
`ogx-distribution` and `rhds-llama-stack-distribution` at
`architecture/rhoai.next/PLATFORM.md` lines `66-70`; Tree B's answer using
`rhds-llama-stack-distribution` is source-backed.

Closure note, 2026-07-29: updated `benchmark/consumer-v1/corpus.json` so
`NAV-010` expects the current `rhoai.next` Llama Stack distribution naming and
retains `OGX` as an accepted legacy/product alias. Re-scoring
`tmp/evaluations/consumer-v1-rhoai-next-20260729T215258Z/raw-results.json`
with the updated corpus gives Tree B `100%` on `NAV-010`, and the regenerated
report no longer flags `NAV-010`.
