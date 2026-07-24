# Task: Extract KubeRay Internal Platform Dependencies

## Goal

Audit and resolve the two remaining `kuberay` Internal Platform Dependencies
corrections by correlating controller resource construction, watched API groups,
RBAC, and the actual ownership of referenced platform services.

## Context

The accepted corpus adds dependencies on `cert-manager` and the RHOAI platform
Gateway attributed to `rhods-operator`. `kuberay` is otherwise structurally ready
for analyzer-only generation and has no other empty high-value category.

The two historical claims need separate treatment:

- Certificate and Issuer RBAC is evidence of API access but must converge with the
  controller code that constructs those resources for Ray mTLS.
- Gateway API access, HTTPRoute construction, and `parentRefs` establish a Gateway
  dependency, but do not by themselves prove that `rhods-operator` owns the selected
  Gateway in every deployment.

Historical agent output is a discovery fixture. Either dependency may be corrected
or left agent-owned when exact source does not support its accepted wording.

## Acceptance Criteria

- [x] cert-manager dependency facts require controller behavior that constructs or
  reconciles cert-manager resources, not RBAC or imports alone.
- [x] Gateway dependency facts distinguish the Gateway API contract from ownership
  by a particular RHOAI component.
- [x] RBAC, API imports, generated clients, or type references alone are negative
  controls and do not create runtime dependency rows.
- [x] Both accepted correction identities are analyzer-owned or contradicted claims
  have exact source-backed adjudications.
- [x] Other semantic candidates remain blocked by rollout approval.
- [x] A 90-component replay has zero false approved nominations and passes all gates.
- [x] A bounded production-path matrix invokes zero agents after rollout approval.

## Files Likely Involved

- `src/arch-analyzer/internal/gosource/`
- `src/arch-analyzer/internal/platformfacts/platformfacts.go`
- `src/arch-analyzer/internal/model/input.go`
- `lib/analyzer_correction_adjudications.json`
- `lib/analyzer_only_approvals.json`

## Status

Complete

## Validation

See [KubeRay Internal Platform Dependencies validation](../../notes/kuberay-internal-platform-dependencies-validation-2026-07-19.md).

## Baseline Evidence

- Latest replay:
  `tmp/architecture-corpus-runs/rhoai-next-trustyai-auth-static-20260719T042645Z`
- Historical agent cost: $1.2209, 318.25 seconds, 8 reads, 4 source files,
  15,384 output tokens.
