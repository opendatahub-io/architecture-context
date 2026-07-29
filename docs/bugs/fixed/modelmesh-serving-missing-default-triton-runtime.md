# Bug: ModelMesh Serving Does Not Clearly Document Default Triton Runtime

## Summary

The clean `consumer-v1` rerun at `20260729T120959Z` showed that Tree B could
lead consumers to answer `INV-009` incorrectly. The agent read
`modelmesh-serving.md` and `modelmesh-runtime-adapter.md` but answered that
Triton was not shipped as a default RHOAI model serving runtime.

## Evidence

- Original regression report:
  `tmp/evaluations/consumer-v1-rhoai-next-20260729T120959Z/report.md`
- Follow-up regression report:
  `tmp/evaluations/consumer-v1-rhoai-next-20260729T165013Z/report.md`
- Question: `INV-009`
- Expected answer: Triton is shipped as a default `ServingRuntime` in the
  ModelMesh Serving stack alongside MLServer, OVMS, and TorchServe.

The follow-up Tree B artifact now includes a `Serving Runtime Definitions`
table in `modelmesh-serving.md` with `mlserver-1.x`, `ovms-1.x`,
`torchserve-0.x`, and `triton-2.x`. The `triton-2.x` row records the built-in
adapter as `triton` and cites `config/runtimes/triton-2.x.yaml:14`.

The follow-up Tree B answer says yes and cites both `kserve.md` and
`modelmesh-serving.md`, including the ModelMesh `triton-2.x`
`ClusterServingRuntime`.

## Fix

`arch-analyzer` now extracts `ServingRuntime` and `ClusterServingRuntime`
manifest instances into `serving_runtime_definitions`, renders them under
`APIs Exposed -> Serving Runtime Definitions`, includes them in bounded
synthesis evidence, and supplements selected-manifest extraction with
canonical `runtimes` kustomization directories while excluding
scripts/tests/examples.

Real-source validation against `red-hat-data-services/modelmesh-serving`
extracted `triton-2.x`, `mlserver-1.x`, `ovms-1.x`, and `torchserve-0.x` from
`config/runtimes`.

## Status

Fixed — 2026-07-29. `INV-009` may still fail deterministic exact-match scoring
because the answer is broader than the current acceptable variants, but the
original missing-evidence bug is resolved. The remaining exact-match cleanup is
tracked by `docs/bugs/open/corpus-v1-exact-match-variants-too-strict.md`.
