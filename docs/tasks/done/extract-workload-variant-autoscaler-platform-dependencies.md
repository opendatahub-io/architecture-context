# Task: Extract Workload Variant Autoscaler Platform Dependencies

## Goal

Convert the five remaining source-backed `workload-variant-autoscaler` Internal
Platform Dependencies into generic analyzer facts and determine whether the
component can be approved for analyzer-only generation.

## Context

The analyzer resolves 3/8 accepted corrections. The remaining rows are Prometheus,
KEDA, LeaderWorkerSet, Gateway API Inference Extension, and Prometheus Operator.

The Go analyzer already discovers source watches for KEDA `ScaledObject`,
LeaderWorkerSet, two InferencePool API packages, and Prometheus Operator
`ServiceMonitor`, but the platform semantic pass does not normalize those watches
into dependencies. Startup also conditionally detects the KEDA and LWS CRDs before
enabling support. A separately configured Prometheus client is validated at startup,
constructed through the Prometheus Go client, and tested with a required query.

## Acceptance Criteria

- [x] Normalize controller-runtime watches for KEDA `ScaledObject`,
  LeaderWorkerSet, InferencePool, and Prometheus Operator `ServiceMonitor` through
  GVK and controller evidence, not component names.
- [x] Preserve optional/conditional semantics when controller registration or scheme
  setup is gated by CRD availability.
- [x] Resolve aliased Go package paths such as the two InferencePool API versions to
  canonical platform identities without broad kind-only matching.
- [x] Extract a Prometheus runtime dependency only when client construction,
  configuration, and runtime use converge; imports or config fields alone are
  negative controls.
- [x] Retain TLS and ServiceAccount-token configuration as evidence without
  misclassifying an outbound client as an inbound Authentication row.
- [x] Exclude CI-only deployment scripts through path/role classification without
  hiding scripts used as workload entrypoints, operator hooks, or production
  deployment logic.
- [x] Resolve or source-adjudicate all 5/5 remaining accepted dependency corrections.
- [x] Do not add a component-name exception or infer a dependency from imports,
  schemes, or type declarations alone.
- [x] A 90-component replay has zero false approved nominations and passes all
  preservation, structural, and synthesis gates.
- [x] Run a bounded production-path matrix only if routing changes.

## Files Likely Involved

- `src/arch-analyzer/internal/gosource/`
- `src/arch-analyzer/internal/model/input.go`
- `src/arch-analyzer/internal/platformfacts/platformfacts.go`
- `src/arch-analyzer/internal/extractor/categorycoverage.go`
- `lib/analyzer_only_approvals.json`

## Status

Done

## Baseline Evidence

- Latest replay:
  `tmp/architecture-corpus-runs/rhoai-next-workbenches-projections-static-20260719T133450Z`
- WVA checkout: `9278cbc194275f2ec7a12a9a97918ee6cf4ec733`.
- Historical agent cost: $1.0810, 212.17 seconds, 8 reads, 4 source files,
and 9,673 output tokens.

## Validation

- Full static replay:
  `tmp/architecture-corpus-runs/rhoai-next-wva-dependencies-static-20260719T134420Z`
- Production-path matrix:
  `tmp/architecture-corpus-runs/rhoai-next-wva-dependencies-matrix-20260719T140520Z`
- Workload Variant Autoscaler resolves 8/8 accepted corrections and becomes the
  28th approved analyzer-only component with zero false nominations.
- The five raw fixture misses are source-backed corrections from Go import aliases
  to canonical Kubernetes API groups; every other historical structured identity
  is retained.
- The bounded matrix invokes zero agents, retains 98/98 analyzer identities, and
  passes all required gates.
- Full details are in
  `docs/notes/workload-variant-autoscaler-platform-dependencies-validation-2026-07-19.md`.
