# Task: Extract Trainer Scheduler Dependencies

## Goal

Emit deterministic Internal Platform Dependencies for controller watches backed by
JobSet, Volcano, and Kubernetes scheduler-plugins, then determine whether `trainer`
can safely move to analyzer-only generation.

## Context

`trainer` is analyzer-sufficient and its only empty high-value category is Internal
Platform Dependencies. The accepted agent made no structured mutation, but the
source contains three explicit runtime relationships:

- `pkg/runtime/framework/plugins/jobset/jobset.go` watches JobSet resources;
- `pkg/runtime/framework/plugins/volcano/volcano.go` watches Volcano PodGroups; and
- `pkg/runtime/framework/plugins/coscheduling/coscheduling.go` watches
  scheduler-plugins PodGroups.

The broad absence scan also finds Gateway API strings in generated OpenAPI/Python
models and Kubeflow identifiers for the component's own API. Those are not external
runtime relationships and must remain negative controls.

## Acceptance Criteria

- [x] Platform semantics emit JobSet, Volcano, and CoScheduling internal dependency
  rows from explicit controller watches.
- [x] Facts retain the controller-watch source reference and describe the runtime
  purpose without inferring unsupported ordering.
- [x] Generated Gateway API/model references do not create an internal dependency.
- [x] The component's own `trainer.kubeflow.org` API does not create an internal
  dependency.
- [x] Generic unit tests cover recognized watches, lookalike GVKs, and unrelated
  controllers.
- [x] The fresh analyzer document populates all four high-value categories for
  `trainer`.
- [x] A 90-component replay has zero false approved nominations and passes
  preservation, structural, and synthesis gates.
- [x] `trainer` receives rollout approval only after the source audit and replay.
- [x] A bounded production-path matrix invokes zero agents for `trainer` and passes
  all required gates.

## Files Likely Involved

- `src/arch-analyzer/internal/platformfacts/platformfacts.go`
- `src/arch-analyzer/internal/platformfacts/platformfacts_test.go`
- `lib/analyzer_only_approvals.json`
- `scripts/analyze_analyzer_only_eligibility.py`

## Status

Done

## Baseline Evidence

- Accepted production fixture:
  `tmp/architecture-corpus-runs/rhoai-next-20260718T215431Z`
- Latest static replay:
  `tmp/architecture-corpus-runs/rhoai-next-operator-auth-static-20260719T012904Z`
- Historical agent cost: $0.7290, 150.16 seconds, 8 reads, 4 source files,
  7,177 output tokens.

Validation is recorded in
`docs/notes/trainer-scheduler-dependency-validation-2026-07-19.md`.
