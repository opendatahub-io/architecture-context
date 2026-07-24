# Task: Extract Dynamic Kubernetes API Dependencies

## Goal

Correlate dynamically assigned Kubernetes GroupVersionKinds with client operations
and platform semantics, beginning with the `spark-operator` read of the OpenShift
cluster `APIServer` TLS profile.

## Context

`spark-operator` is analyzer-sufficient and has no unresolved accepted structured
corrections, but Internal Platform Dependencies remains partial and empty. Its
webhook constructs an `unstructured.Unstructured`, assigns
`config.openshift.io/v1, Kind=APIServer`, and reads the singleton `cluster` object
through a controller-runtime client. When present, that object controls the
webhook's TLS minimum version and cipher suites; when absent, the operator uses
hardened defaults.

The current Go operation extractor resolves statically typed client objects but
loses the API identity of `unstructured.Unstructured`. RBAC or a standalone
`SetGroupVersionKind` call is insufficient: the fact requires the same dynamic
object to reach a Kubernetes client operation.

Optional compiled integrations are not automatically selected runtime
dependencies. Spark's Volcano scheduler and cert-manager support remain separate
until deployment flags or selected manifests prove activation.

## Acceptance Criteria

- [x] Track a local `unstructured.Unstructured` identity assigned through
  `SetGroupVersionKind` with statically resolvable group, version, and kind fields.
- [x] Correlate that same object with controller-runtime Get, List, Create, Update,
  Patch, or Delete calls and emit a canonical Component Reference.
- [x] Map a read of `config.openshift.io/v1/APIServer` named `cluster` to an
  OpenShift cluster-configuration dependency whose fallback behavior is explicit.
- [x] GVK construction without a client call, RBAC alone, different object
  variables, unresolved dynamic GVK fields, CRD descriptions, and generated or test
  code are negative controls.
- [x] Do not report compiled Volcano or cert-manager support as active in the
  selected RHOAI deployment without deployment activation evidence.
- [x] `spark-operator` becomes a truthful analyzer-only candidate or retains an
  exact source-backed residual limitation.
- [x] Other semantic candidates remain blocked by rollout approval.
- [x] A 90-component replay has zero false approved nominations and passes all
  preservation, structural, and synthesis gates.
- [x] Run a bounded production-path matrix only if `spark-operator` receives rollout
  approval.

## Files Likely Involved

- `src/arch-analyzer/internal/gosource/operations.go`
- `src/arch-analyzer/internal/gosource/operations_test.go`
- `src/arch-analyzer/internal/platformfacts/platformfacts.go`
- `lib/analyzer_only_approvals.json`

## Status

Complete

## Validation

See [Dynamic Kubernetes API Dependencies validation](../../notes/dynamic-kubernetes-api-dependencies-validation-2026-07-19.md).

## Baseline Evidence

- Latest replay:
  `tmp/architecture-corpus-runs/rhoai-next-kuberay-dependencies-static-20260719T050621Z`
- Source:
  `cmd/operator/webhook/start.go:351-402` in the `spark-operator` checkout.
- Historical agent cost: $1.0982, 194.94 seconds, 8 reads, 4 source files,
  8,714 output tokens.
