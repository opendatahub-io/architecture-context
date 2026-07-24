# Task: Extend Controller-Runtime Metrics Authentication

## Goal

Resolve the remaining controller-runtime metrics Authentication pattern across
analyzer-sufficient components by correlating mutable metrics options, deployment
flags, review RBAC, and the actual TLS/exposure path.

## Context

The analyzer already extracts a runtime security control when
`FilterProvider` is assigned `filters.WithAuthenticationAndAuthorization` and its
address and secure defaults resolve statically. Several accepted agent corrections
remain because the current platform convergence requires an OpenShift service-ca
Secret and matching Service even when controller-runtime serves a self-signed
certificate or the endpoint is only workload-local.

The repeated unresolved pattern appears in `mcp-lifecycle-operator`,
`workbenches-operator`, `workload-variant-autoscaler`,
`llm-d-inference-scheduler`, and `llm-d-router`. The first target is
`mcp-lifecycle-operator`, which has 2/3 Authentication corrections analyzer-owned.

## Acceptance Criteria

- [x] Inventory each target's source control, resolved deployment arguments,
  Service exposure, certificate source, ServiceAccount, and review RBAC.
- [x] Distinguish OpenShift service-ca TLS, controller-runtime self-signed TLS,
  externally supplied certificates, and unresolved certificate behavior.
- [x] Emit a metrics Authentication fact only when bind address, secure serving,
  authn/authz filter, and TokenReview/SubjectAccessReview permissions converge.
- [x] Do not require a Service for a workload-local endpoint, but preserve exposure
  and certificate uncertainty instead of claiming service-ca provisioning.
- [x] Filter imports, secure serving alone, review RBAC alone, unresolved flags, and
  disconnected Services or Secrets are negative controls.
- [x] Resolve or source-adjudicate every targeted metrics correction; unrelated
  category gaps remain visible.
- [x] Other semantic candidates remain blocked by rollout approval.
- [x] A 90-component replay has zero false approved nominations and passes all
  preservation, structural, and synthesis gates.
- [x] Run bounded production-path matrices only for components whose routing changes.

## Files Likely Involved

- `src/arch-analyzer/internal/gosource/security.go`
- `src/arch-analyzer/internal/platformfacts/platformfacts.go`
- `src/arch-analyzer/internal/extractor/`
- `lib/analyzer_only_approvals.json`

## Status

Complete

## Validation

See [extended controller-runtime metrics Authentication validation](../../notes/extended-controller-runtime-metrics-authentication-validation-2026-07-19.md).

## Baseline Evidence

- Latest replay:
  `tmp/architecture-corpus-runs/rhoai-next-dynamic-gvk-static-20260719T054834Z`
- Primary target historical cost: $0.8373, 186.06 seconds, 9 reads, 4 source
  files, and 8,245 output tokens.
