# Task: Extract Secure Controller Metrics Authentication

## Goal

Emit a source-backed secure controller-runtime metrics Authentication fact when the
metrics server is configured with the Kubernetes authentication and authorization
filter, beginning with the remaining `mlflow-operator` correction.

## Context

The analyzer already owns the operator's health and readiness Authentication facts.
Its only unresolved accepted Authentication row is:

`:8443/metrics :: GET :: authn/authz filter (controller-runtime)`

The positive evidence converges across source, workload configuration, RBAC, and TLS:

- `metricsserver.Options` receives `SecureServing: secureMetrics`, whose flag default
  is `true`, and `FilterProvider` is assigned
  `filters.WithAuthenticationAndAuthorization` inside the secure branch in
  `cmd/main.go:76-136`;
- the RHOAI manager arguments set `--metrics-bind-address=:8443` and mount the
  certificate directory in `config/overlays/rhoai/manager_patch.yaml:14-15`;
- `metrics-auth-role` grants `create` on TokenReview and SubjectAccessReview in
  `config/rbac/metrics_auth_role.yaml:1-20`; and
- the OpenShift Service requests a service-ca serving certificate in
  `config/overlays/openshift/metrics_service_patch.yaml:1-8`.

None of these surfaces alone proves the final endpoint contract. The extractor must
retain uncertainty when security flags or filter assignment cannot be resolved.

## Acceptance Criteria

- [x] Go source extraction recognizes an explicit
  `filters.WithAuthenticationAndAuthorization` metrics `FilterProvider` assignment.
- [x] Static flag defaults and resolved deployment arguments establish the secure
  metrics address and secure-serving state without assuming framework defaults.
- [x] TokenReview and SubjectAccessReview permissions plus TLS/service evidence
  produce a source-backed `:8443/metrics :: GET` Authentication row.
- [x] A filter imported but not assigned, secure metrics without the filter, RBAC
  review permissions without runtime configuration, and unresolved dynamic flags are
  negative controls.
- [x] `mlflow-operator` resolves 3/3 accepted Authentication additions.
- [x] Additional semantic candidates remain blocked by rollout approval until their
  accepted corrections are fully adjudicated.
- [x] A 90-component replay has zero false approved nominations and passes all gates.
- [x] A bounded production-path matrix invokes zero agents after rollout approval.

## Files Likely Involved

- `src/arch-analyzer/internal/gosource/security.go`
- `src/arch-analyzer/internal/extractor/`
- `src/arch-analyzer/internal/platformfacts/platformfacts.go`
- `lib/analyzer_only_approvals.json`

## Status

Complete

## Baseline Evidence

- Latest replay:
  `tmp/architecture-corpus-runs/rhoai-next-controller-k8s-auth-static-20260719T023000Z`
- Historical agent cost: $0.8774, 176.69 seconds, 8 reads, 4 source files,
  7,914 output tokens.
