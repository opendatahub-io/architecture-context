# Task: Extract Managed Sub-component Lifecycle

## Goal

Extract the source-backed `ai-gateway-operator` relationship to its managed llm-d
batch-gateway sub-component, adjudicate the historical metrics Authentication row,
and determine whether the component is safe for analyzer-only routing.

## Context

The selected AIGateway CRD declares `spec.batchGateway.managementState` with
`Managed` and `Removed` states. Runtime reconciliation appends the corresponding
manifest set only in the `Managed` branch, and selected RBAC grants complete
lifecycle permissions for `batch.llm-d.ai/llmbatchgateways`. These independent
signals can form a reusable managed-subcomponent contract without relying on the
repository or component name.

The other unresolved historical row claims TokenReview and SubjectAccessReview
authentication on metrics port 8443. The deployed Service and review RBAC exist,
but `cmd/operator/operator.go` leaves both controller-runtime `SecureServing` and
`FilterProvider` unset. The endpoint is therefore plaintext and unfiltered; unused
review permissions do not prove authentication.

The accepted agent pass cost $1.0533 and 234.68 seconds, with eight reads, four
source files, and 10,816 output tokens.

## Acceptance Criteria

- [x] Extract a typed CRD managed-component contract only when a nested
  `managementState` field declares both `Managed` and `Removed` and its schema
  identifies the controlled sub-component.
- [x] Extract runtime managed-component use only when a `Managed` comparison gates
  manifest reconciliation and that function is registered in the runtime action
  chain.
- [x] Require selected full-lifecycle RBAC for a target resource matching the
  controlled field before emitting an internal platform dependency.
- [x] Derive the component identity from the target API/resource contract rather
  than the repository or analyzed component name.
- [x] Add independent negative controls for missing schema states, missing runtime
  gating, missing action registration, unrelated RBAC, and incomplete lifecycle
  verbs.
- [x] Record the metrics correction as an accepted analyzer absence with exact
  source evidence; do not infer authn/authz from Service naming or RBAC alone.
- [x] Resolve or source-adjudicate all three accepted structured corrections for
  `ai-gateway-operator`.
- [x] A fresh 90-component replay has zero false approved nominations and passes
  preservation, structural, and synthesis gates.
- [x] Run a bounded production-path matrix only if the routing changes.

## Files Likely Involved

- `src/arch-analyzer/internal/model/input.go`
- `src/arch-analyzer/internal/extractor/crds.go`
- `src/arch-analyzer/internal/gosource/`
- `src/arch-analyzer/internal/platformfacts/platformfacts.go`
- `lib/analyzer_correction_adjudications.json`
- `lib/analyzer_only_approvals.json`

## Status

Done

## Baseline Evidence

- Replay: `tmp/architecture-corpus-runs/rhoai-next-llm-d-epp-static-20260719T151327Z`
- Checkout: `2efbf1cd670336d1cfdbb836cfd5f9e0ee756b58`
- Corrections resolved: 1/3
- Managed state schema:
  `config/crd/bases/components.platform.opendatahub.io_aigateways.yaml:55-66`
- Runtime manifest gating: `internal/controller/aigateway/aigateway.go:80-98`
- Runtime action registration:
  `internal/controller/aigateway/aigateway_controller.go:80-104`
- Metrics options without TLS or filter: `cmd/operator/operator.go:82-86`
- Review RBAC: `config/rbac/metrics_auth_role.yaml:1-17`

## Progress

- Source audit established that the historical secure metrics row is not an
  operational authentication path. Controller-runtime only installs an authn/authz
  filter when `FilterProvider` is configured; this repository never configures it.
- Package-scoped constant resolution replaced an initially oscillating
  repository-wide name map discovered by the first corpus attempt.
- The final 90-component replay extracted 90/90 repositories in 11.86 seconds,
  reported zero false nominations, retained 8,454/8,459 analyzer identities, and
  passed structural and synthesis checks for 90/90 documents.
- The one-component production-path matrix invoked zero agents, retained 98/98
  analyzer identities, passed all gates, and completed in 3.22 seconds.
