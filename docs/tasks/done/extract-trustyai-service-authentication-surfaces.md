# Task: Extract TrustyAI Service Authentication Surfaces

## Goal

Audit and resolve the five remaining `trustyai-service-operator` Authentication
corrections by converging controller-created workloads, kube-rbac-proxy arguments,
Services, ServiceAccounts, review RBAC, webhook runtime configuration, and TLS
Secret provisioning.

## Context

The accepted corpus adds rows for EvalHub API and MCP services, TrustyAI Service,
controller metrics, and the conversion webhook. The recorded evidence is not
sufficient by itself:

- `api/evalhub/v1alpha1/evalhub_types.go:99-103` documents intended proxy behavior
  but a field comment is not deployed runtime proof;
- TokenReview and SubjectAccessReview permissions do not prove a proxy or caller;
- `cmd/main.go:136-139` conditionally creates a webhook server on port 9443 but does
  not itself prove the deployed certificate source; and
- controller-created deployment templates must be linked to their Services,
  sidecars, arguments, ServiceAccounts, and RBAC.

The latest analyzer owns 2/7 accepted corrections. Historical rows may be corrected
when the current source graph contradicts their mechanisms or ownership.

## Acceptance Criteria

- [x] Controller-created and manifest-resolved workloads retain sidecar containers,
  ports, arguments, ServiceAccounts, and Secret mounts needed for security
  convergence.
- [x] kube-rbac-proxy Authentication facts require a deployed proxy container,
  upstream/listen arguments, a matching exposed Service, and ServiceAccount-bound
  TokenReview and SubjectAccessReview permissions.
- [x] Field comments, container images, review RBAC, or Services alone are negative
  controls and do not produce runtime Authentication rows.
- [x] Conditional controller-runtime webhook configuration is correlated with the
  deployed Service and TLS Secret; port or service-ca evidence alone is unresolved.
- [x] Metrics facts distinguish controller-runtime filter authentication from a
  kube-rbac-proxy sidecar and do not normalize unlike enforcement paths together.
- [x] All seven accepted correction identities are analyzer-owned or contradicted
  historical rows are recorded as source-backed corrections.
- [x] Other semantic candidates remain blocked by rollout approval.
- [x] A 90-component replay has zero false approved nominations and passes all gates.
- [x] A bounded production-path matrix invokes zero agents after rollout approval.

## Files Likely Involved

- `src/arch-analyzer/internal/extractor/`
- `src/arch-analyzer/internal/gosource/`
- `src/arch-analyzer/internal/model/input.go`
- `src/arch-analyzer/internal/platformfacts/platformfacts.go`
- `lib/analyzer_only_approvals.json`

## Status

Complete

## Validation

See [TrustyAI Service Authentication validation](../../notes/trustyai-service-authentication-validation-2026-07-19.md).

## Baseline Evidence

- Latest replay:
  `tmp/architecture-corpus-runs/rhoai-next-feast-auth-static-20260719T034500Z`
- Historical agent cost: $1.2302, 194.33 seconds, 9 reads, 4 source files,
  9,510 output tokens.
