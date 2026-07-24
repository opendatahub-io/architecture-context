# Task: Extract MaaS API Authentication Surfaces

## Goal

Resolve the three remaining `models-as-a-service` Authentication corrections using
deployed policy, route, source, probe, and metrics evidence, correcting historical
claims when the current source graph contradicts them.

## Context

The accepted corpus contains four structured Authentication additions. One is
already analyzer-owned; the remaining identities are:

- `/v1/models, /maas-api/* :: GET, POST, DELETE, OPTIONS`;
- `/health :: GET`; and
- `/metrics :: Unknown`.

The historical agent described the API row as application JWT/RBAC based on a JWT
dependency, review permissions, and an HTTPRoute without filters. Current source
contains a more explicit policy model:

- `deployment/base/maas-api/policies/auth-policy.yaml` describes API-key and
  Kubernetes TokenReview authentication with a health-path exclusion;
- `deployment/base/maas-api/policies/kustomization.yaml:7-10` excludes that file and
  says a singleton gateway AuthPolicy managed by `maas-controller` owns the route;
- `maas-api/cmd/main.go:80-236` registers Gin routes and application middleware;
- `deployment/base/maas-api/core/deployment.yaml:21-56` exposes dedicated API,
  metrics, liveness, and readiness surfaces; and
- `deployment/base/maas-api/rbac/clusterrole.yaml:24-31` grants TokenReview and
  SubjectAccessReview.

An unused policy file and a linked JWT module are not runtime proof. The task must
trace resolved Kustomize or controller-created policy objects before attributing an
authentication mechanism.

## Acceptance Criteria

- [x] The normalized model represents resolved Kuadrant AuthPolicy targets,
  authentication mechanisms, authorization controls, and explicit path exclusions.
- [x] Unreferenced policy YAML, dependency-only JWT matches, RBAC review permissions
  without a runtime caller, and HTTPRoutes without policy attachment are negative
  controls.
- [x] Gin route groups and middleware are correlated with the deployed gateway policy
  without claiming that application code performs gateway-owned authentication.
- [x] Kubernetes probe configuration with no authentication headers supports the
  deployed `/health :: GET` control, while header-bearing or non-HTTP probes remain
  unresolved.
- [x] A dedicated metrics listener and scrape target produce `/metrics :: Unknown`
  when source does not establish an authentication mechanism; Unknown is not silently
  promoted to None.
- [x] All four accepted corrections are analyzer-owned or any contradicted historical
  row is recorded as a source-backed correction.
- [x] Other semantic candidates remain blocked by rollout approval.
- [x] A 90-component replay has zero false approved nominations and passes all gates.
- [x] A bounded production-path matrix invokes zero agents after rollout approval.

## Files Likely Involved

- `src/arch-analyzer/internal/extractor/`
- `src/arch-analyzer/internal/gosource/routes.go`
- `src/arch-analyzer/internal/model/input.go`
- `src/arch-analyzer/internal/platformfacts/platformfacts.go`
- `lib/analyzer_only_approvals.json`

## Status

Complete

## Baseline Evidence

- Latest replay:
  `tmp/architecture-corpus-runs/rhoai-next-secure-metrics-static-20260719T024000Z`
- Historical agent cost: $0.9999, 240.67 seconds, 9 reads, 4 source files,
  11,388 output tokens.

## Validation

- Full static replay:
  `tmp/architecture-corpus-runs/rhoai-next-maas-auth-static-20260719T031000Z`
- Production-path matrix:
  `tmp/architecture-corpus-runs/rhoai-next-maas-auth-matrix-20260719T032600Z`
- The classifier resolves all four accepted Authentication row identities and
  reports 21 approved nominations with zero false nominations.
- The API row corrects the historical application-JWT claim: the controller-created
  Gateway `AuthPolicy` owns API-key, Kubernetes TokenReview, optional OIDC JWT, and
  authorization enforcement; the application consumes injected identity headers.
- The 90-component comparison retains 8,297/8,302 analyzer identities, with all 16
  conflicts and 5 row corrections accepted, zero unexplained loss, and 90/90
  structural and synthesis-quality checks passing.
- The bounded matrix invokes zero agents, retains 110/110 analyzer identities, and
  passes 1/1 structural and synthesis-quality checks in 3.17 seconds.
