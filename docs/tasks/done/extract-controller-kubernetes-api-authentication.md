# Task: Extract Controller Kubernetes API Authentication

## Goal

Emit a source-backed Kubernetes API Authentication fact when a deployed controller
uses an in-cluster Kubernetes client under an explicit ServiceAccount, beginning with
the remaining `mcp-lifecycle-module-operator` correction.

## Context

The operator's health and readiness facts are already analyzer-owned. Its only
unresolved accepted Authentication row is:

`Kubernetes API :: REST :: ServiceAccount token (in-cluster)`

Evidence converges across three independent surfaces:

- `ctrl.NewManager(ctrl.GetConfigOrDie(), ...)` and dynamic/discovery clients in
  `cmd/main.go:71-85`;
- `serviceAccountName: controller-manager` in
  `config/manager/manager.yaml:68`; and
- Kubernetes API permissions, including TokenReview and SubjectAccessReview, in
  `config/rbac/role.yaml:73-84`.

TokenReview/SubjectAccessReview permissions alone do not prove the controller's own
API authentication, and a `client-go` module in a library does not prove in-cluster
runtime use. The extractor must require converging runtime and deployment evidence.

## Acceptance Criteria

- [x] The normalized model exposes a reliable runtime Kubernetes-client signal.
- [x] A non-empty workload ServiceAccount and runtime Kubernetes-client evidence
  produce `Kubernetes API :: REST` with an in-cluster ServiceAccount mechanism.
- [x] The policy names the observed ServiceAccount and kube-apiserver enforcement.
- [x] Client libraries without a deployment, deployments without a ServiceAccount,
  and RBAC review permissions without runtime client construction are negative
  controls.
- [x] `mcp-lifecycle-module-operator` resolves 3/3 accepted Authentication additions.
- [x] Any additional semantic candidates remain blocked by rollout approval until
  their accepted corrections are fully adjudicated.
- [x] A 90-component replay has zero false approved nominations and passes all gates.
- [x] A bounded production-path matrix invokes zero agents if the component receives
  rollout approval.

## Files Likely Involved

- `src/arch-analyzer/internal/gosource/`
- `src/arch-analyzer/internal/platformfacts/platformfacts.go`
- `src/arch-analyzer/internal/extractor/categorycoverage.go`
- `lib/analyzer_only_approvals.json`

## Status

Complete

## Baseline Evidence

- Latest replay:
  `tmp/architecture-corpus-runs/rhoai-next-trainer-dependencies-static-20260719T015433Z`
- Historical agent cost: $0.8600, 191.53 seconds, 8 reads, 4 source files,
  8,570 output tokens.
