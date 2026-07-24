# Task: Extract Feast Service Authentication Surfaces

## Goal

Resolve the four remaining `feast` Authentication corrections using generic Go HTTP
handler, gRPC interceptor, and typed CRD configuration evidence without turning an
incomplete middleware scan into an unsupported absence claim.

## Context

The accepted corpus contains four source-backed additions:

- `/get-online-features (Go HTTP) :: POST` with no authentication middleware;
- `/health (Go HTTP) :: GET` with no authentication middleware;
- `gRPC services (Go) :: ALL` with only the Prometheus unary interceptor; and
- `Feast services (CRD-configured) :: ALL` with mutually exclusive Kubernetes RBAC
  or OIDC authorization configuration.

At commit `84c996eedbf3afd31edd8a0dfacd79580e154167`, the analyzer already extracts the
Go and Python route identities, registered protobuf services, controller health
surfaces, and Kubernetes API authentication. It does not yet model:

- `go/internal/feast/server/http_server.go:148-159,386-403`, where the handler
  constrains POST and the complete `http.NewServeMux` registrations wrap routes only
  in metrics and recovery middleware;
- `go/main.go:191-204`, where `grpc.NewServer` receives only the Prometheus unary
  interceptor before services are registered; or
- `infra/feast-operator/api/v1alpha1/featurestore_types.go:609-632`, where
  `AuthzConfig` requires exactly one of Kubernetes or OIDC and OIDC references a
  Secret.

The CRD contract describes selectable deployment configuration, not proof that one
mechanism is active in every repository checkout. The rendered fact must preserve
that distinction.

## Acceptance Criteria

- [x] Go HTTP route extraction correlates `ServeMux` registration, wrapper chain,
  handler method checks, and server assignment before describing authentication.
- [x] A route with an unknown wrapper, a dynamically assembled middleware chain, or
  an unresolved handler method remains partial rather than being labeled `None`.
- [x] gRPC server extraction inventories configured unary and stream interceptors
  and correlates registered services with the constructed server.
- [x] Absence of a recognized authentication interceptor is emitted only when the
  complete static constructor option set is bounded; chained, conditional, or
  dynamic options are negative controls.
- [x] Typed CRD extraction represents mutually exclusive Kubernetes and OIDC
  authorization choices, Kubernetes role configuration, and OIDC Secret references
  without claiming a currently selected mechanism.
- [x] All four accepted correction identities are analyzer-owned or any contradicted
  historical claim is recorded as a source-backed correction.
- [x] Other semantic candidates remain blocked by rollout approval.
- [x] A 90-component replay has zero false approved nominations and passes all gates.
- [x] A bounded production-path matrix invokes zero agents after rollout approval.

## Files Likely Involved

- `src/arch-analyzer/internal/gosource/`
- `src/arch-analyzer/internal/model/input.go`
- `src/arch-analyzer/internal/platformfacts/platformfacts.go`
- `lib/analyzer_only_approvals.json`

## Status

Complete

## Baseline Evidence

- Latest replay:
  `tmp/architecture-corpus-runs/rhoai-next-maas-auth-static-20260719T031000Z`
- Historical agent cost: $1.4918, 214.69 seconds, 10 reads, 4 source files,
  9,725 output tokens.

## Validation

- Full static replay:
  `tmp/architecture-corpus-runs/rhoai-next-feast-auth-static-20260719T034500Z`
- Production-path matrix:
  `tmp/architecture-corpus-runs/rhoai-next-feast-auth-matrix-20260719T035000Z`
- The classifier resolves all four accepted Authentication corrections and reports
  22 approved nominations with zero false nominations.
- A corpus audit rejected a conditional TLS/plaintext gRPC server as ambiguous;
  only two additional bounded plaintext application servers gained generic gRPC
  facts.
- The 90-component comparison retains 8,303/8,308 analyzer identities, with all 16
  conflicts and 5 row corrections accepted, zero unexplained loss, and 90/90
  structural and synthesis-quality checks passing.
- The bounded matrix invokes zero agents, retains 448/448 analyzer identities, and
  passes 1/1 structural and synthesis-quality checks in 5.58 seconds.
