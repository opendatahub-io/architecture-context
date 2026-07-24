# Task: Extract model-registry KServe Controller Dependency

## Goal

Resolve the missed KServe Internal Dependency in `model-registry` by extracting
the conditional controller-runtime watch with construction and call evidence.

## Context

The completeness-only candidate audit (2026-07-19) found that `model-registry`'s
`manager` binary has a genuine runtime dependency on KServe InferenceService CRDs.
The dependency is backed by scheme registration, controller-runtime Watch
construction, and concrete Get/Update operations, but the analyzer did not extract
it for two reasons:

1. The CRD watch extractor does not follow controller-runtime registrations into
   imported packages (`internal/controllers/`) — it only operates on `main.go`.
2. The alias scanner classified `inferenceservice_controller.go` as "commented
   configuration" because the raw `serving.kserve.io` string appears in Go import
   comments, while runtime code uses imported Go types (`kservev1beta1.InferenceService{}`).

The merge process also rejected the agent-proposed KServe row on formal grounds
("candidate-only row has no exact evidence record"), confirming the extraction gap.

## Evidence

`model-registry` at `62733189ea906eeb88e955052c9b5da10405115a`:

| Evidence | Location | Detail |
|----------|----------|--------|
| Scheme registration | `cmd/controller/main.go:111` | `kservev1beta1.AddToScheme(scheme)` |
| Conditional gate | `cmd/controller/main.go:138` | `INFERENCE_SERVICE_CONTROLLER == "managed"` env var |
| Watch construction | `cmd/controller/internal/controllers/inferenceservice_controller.go:44` | `For(&kservev1beta1.InferenceService{})` |
| Watch construction | `pkg/inferenceservice-controller/controller.go:251` | `For(&kservev1beta1.InferenceService{})` |
| Runtime Get | `pkg/inferenceservice-controller/controller.go:96` | `r.client.Get(ctx, req.NamespacedName, isvc)` |
| Runtime Update | `pkg/inferenceservice-controller/controller.go:155,181,241` | `r.client.Update(ctx, isvc)` |
| RBAC manifest | `manifests/kustomize/options/controller/rbac/role.yaml:16,26` | ClusterRole for `serving.kserve.io/inferenceservices` |

Additionally, the nine active platform aliases flagged by the analyzer are all
accounted for: false positives (Go struct names), self-referential labels
(`modelregistry.kubeflow.org/*`), test/mock fixtures, sample files, and naming
conventions. None represents a missed Internal Dependency beyond KServe.

## Scope

Two generic analyzer improvements are required:

### 1. Follow CRD watch registrations into imported controller packages

The existing CRD watch extractor finds `For(&Type{})` patterns in `main.go` but
not in packages imported and registered by `main.go` via
`SetupWithManager(mgr)` or equivalent delegation. Extend the extractor to follow
one level of controller registration into imported packages within the same
module.

This is a generic improvement that applies to any Go controller that delegates
CRD watch setup to imported packages (a common controller-runtime pattern).

### 2. Improve alias scan classification

The alias scanner should:

- Classify test directories (`*_test.go`, `k8mocks/`, `__mocks__/`, `testdata/`)
  as test fixtures, not runtime references.
- Classify `samples/` directories as sample data, not production manifests.
- Classify Go struct type names and LeaderElectionID strings as naming conventions,
  not runtime dependencies.
- Classify self-referential labels (component's own API group in label selectors)
  as self-owned, not external dependencies.

These improvements are repository-independent and reduce false-positive alias
counts across the corpus.

## Negative Controls

- Must not extract KServe dependency from `go.mod` alone without construction
  evidence.
- Must not treat commented API group strings as runtime relationships.
- Must not treat self-referential labels as external dependencies.
- Must not mark `model-registry` complete while the KServe dependency remains
  unextracted.

## Deliverables

- Extend CRD watch extractor to follow `SetupWithManager` delegation.
- Improve alias scan classification for test, sample, naming convention, and
  self-referential patterns.
- Add Go unit tests for imported-package CRD watches and new alias classifications.
- Replay 90-component corpus: zero false nominations.
- Add `model-registry` to the approval list only if the replay demonstrates full
  eligibility.

## Status

Pending.
