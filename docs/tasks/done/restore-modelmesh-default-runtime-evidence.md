# Task: Restore ModelMesh Default Runtime Evidence

## Goal

Make generated ModelMesh Serving architecture output explicitly document
default runtime definitions, including Triton when present, so consumer lookup
questions can answer `INV-009` correctly from architecture files alone.

## Context

The clean `consumer-v1` rerun at `20260729T120959Z` flagged `INV-009`.
Tree B read `modelmesh-serving.md` and `modelmesh-runtime-adapter.md`, found
Triton adapter evidence, but answered that Triton was not shipped as a default
runtime. The architecture tree needed clearer default-runtime evidence.

Tracking bug:
`docs/bugs/fixed/modelmesh-serving-missing-default-triton-runtime.md`.

## Implementation

`arch-analyzer` now extracts `ServingRuntime` and `ClusterServingRuntime`
manifest instances, including supported model formats, container images,
built-in adapter type, scope, and source path. It renders them under
`APIs Exposed -> Serving Runtime Definitions`, exposes them to bounded
synthesis evidence, and supplements selected-manifest extraction with
canonical `runtimes` kustomization directories while excluding scripts, tests,
examples, and samples.

Real-source validation against `red-hat-data-services/modelmesh-serving`
extracted:

- `triton-2.x`
- `mlserver-1.x`
- `ovms-1.x`
- `torchserve-0.x`

## Acceptance Criteria

- `modelmesh-serving.md` states whether Triton is a default ModelMesh runtime
  when source evidence supports it.
- The output distinguishes default runtime definitions from adapter-only
  support.
- A focused regression test covers the extracted/rendered fact.
- `INV-009` no longer fails because of missing default-runtime evidence.

## Status

Done — 2026-07-29. The follow-up `consumer-v1` run at `20260729T165013Z`
generated the runtime table in Tree B and the Tree B `INV-009` answer correctly
identified Triton as a default runtime. Remaining deterministic exact-match
cleanup for broader-but-correct answers is tracked separately.
