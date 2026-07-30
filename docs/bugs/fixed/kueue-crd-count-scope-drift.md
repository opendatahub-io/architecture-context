# Bug: Kueue CRD Count Scope Drift

## Summary

The clean `consumer-v1` reruns at `20260729T120959Z` and
`20260729T165013Z` exposed a scope mismatch for `FACT-007`. Tree B answered
that Kueue defines 16 CRDs, while the corpus expects 11 core Kueue CRDs.

## Evidence

- Evaluation report:
  `tmp/evaluations/consumer-v1-rhoai-next-20260729T120959Z/report.md`
- Follow-up report:
  `tmp/evaluations/consumer-v1-rhoai-next-20260729T165013Z/report.md`
- Question: `FACT-007`
- Expected answer: 11 CRDs in `kueue.x-k8s.io`:
  9 `v1beta1` core resources plus `Cohort` and `Topology` in `v1alpha1`.
- Tree B answer source: generated `kueue.md`, which includes additional
  `config.kueue.x-k8s.io` and `visibility.kueue.x-k8s.io` API entries.
  In the follow-up run, Tree B read `kueue.md`, cited the CRD table, and
  answered 16.

## Impact

MEDIUM — CRD counts are used as inventory facts. The current output and corpus
do not agree on whether configuration and aggregated visibility APIs count as
component-defined CRDs.

## Expected

The analyzer, renderer, and/or corpus should have an explicit CRD counting
contract, for example:

- core owned CRDs only;
- all CRD manifests emitted by the component;
- persisted CRDs excluding aggregated/non-persisted API resources.

## Status

Fixed — 2026-07-30. The Kueue CRD table now labels `API Role` and states
`11 core API CRDs; 16 total CRD/API rows including configuration and visibility
APIs`. `FACT-007` now expects the 11-core-CRD scope and cites
`architecture/rhoai.next/kueue.md:57-78`. Focused user-run re-evaluation
`tmp/evaluations/consumer-v1-rhoai-next-20260730T005726Z/` scored Tree A
`1.0` and Tree B `1.0`.
