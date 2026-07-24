# Task: Extract Go HTTP Authentication Boundaries

## Goal

Extract source-backed Authentication facts for separately wired Go HTTP surfaces,
starting with the business-route and observability muxes in `batch-gateway`.

## Context

`batch-gateway` has two remaining accepted corrections. Its API mux registers
business routes with recovery, request-observability, and security-header middleware;
the request middleware reads a configurable tenant header intended for upstream
Envoy `ext_authz`, but does not enforce credentials. Its observability mux registers
health, readiness, and metrics handlers without middleware.

The analyzer must not infer unauthenticated access merely because it fails to find a
known auth library. It needs a closed registration boundary: concrete mux identity,
route inventory, complete middleware arguments, inspected local middleware behavior,
and correlation to a running HTTP server.

## Acceptance Criteria

- [x] Correlate a concrete `http.ServeMux` with registered handler sets and the
  runtime `http.Server` or serving lifecycle that uses it.
- [x] Resolve helper-based route registration, including variadic middleware passed
  at each call site and statically declared route methods and patterns.
- [x] Treat an empty middleware argument list as unauthenticated only when all routes
  on the bounded mux are inventoried and no handler-level auth control is unresolved.
- [x] Classify a non-auth middleware chain only when every local wrapper is inspected
  and its behavior is bounded; unknown, imported, interface-dispatched, or dynamic
  middleware keeps Authentication unresolved.
- [x] Recognize tenant/request headers as identity context rather than credential
  enforcement when no rejection, verification, authorization, or credential parser
  is present in the closed middleware chain.
- [x] Preserve grouped surface identity and concrete HTTP methods from source rather
  than hard-coding `batch-gateway` row names.
- [x] Reject disconnected muxes, test-only servers, partially inventoried handlers,
  conditional unknown middleware, and wrappers that perform authentication or
  authorization.
- [x] Resolve the final two accepted `batch-gateway` Authentication corrections.
- [x] Nominate `batch-gateway` analyzer-only only if all existing readiness,
  completeness, approval, preservation, and quality policies pass.
- [x] Run a bounded paid matrix if this tranche changes production routing.
- [x] A fresh 90-component replay has zero false approved nominations and passes
  preservation, structural, and synthesis gates.

## Files Likely Involved

- `src/arch-analyzer/internal/gosource/servers.go`
- `src/arch-analyzer/internal/gosource/security.go`
- `src/arch-analyzer/internal/gosource/runtime_graph.go`
- `src/arch-analyzer/internal/model/input.go`
- `src/arch-analyzer/internal/normalize/normalize.go`
- `scripts/analyze_analyzer_only_eligibility.py`

## Status

Done

## Baseline Evidence

- Replay:
  `tmp/architecture-corpus-runs/rhoai-next-inference-gateway-client-static-20260719T165652Z`
- Checkout: `fac0c8d8c69369662d46edf1bfecacf3bd15b5d2`
- API mux and middleware chain: `internal/apiserver/server/server.go:85-100`
- Observability mux without middleware: `internal/apiserver/server/server.go:102-109`
- Tenant-header behavior: `internal/apiserver/middleware/request_middleware.go:44-63`
- Registration helper: `internal/apiserver/common/rest.go:46-59`
- Accepted corrections:
  `tmp/architecture-corpus-runs/rhoai-next-20260718T215431Z/logs/agents/batch-gateway.changes.md`

## Progress

- The repository-level Go pass recognizes registration helpers from their
  implementation, resolves concrete route-provider types and constants, binds muxes
  through returned struct fields to invoked HTTP server methods, and inspects every
  middleware wrapper before emitting `None`.
- The API surface resolves exactly as `API server routes :: POST, GET, DELETE`.
  Health and readiness each explicitly register `HEAD`, so the analyzer corrects the
  historical observability method set to `GET, HEAD`; the stale `GET` addition is
  source-adjudicated.
- The 90-component replay emitted the new contract only for `batch-gateway`,
  extracted 90/90 repositories with zero failures, reported 64 fresh sufficient
  components, 33 approved analyzer-only nominations, and zero false nominations.
- The one-component production-path matrix invoked zero agents, retained 39/39
  analyzer identities, passed all gates, and completed in 2.50 seconds.

Validation: [Go HTTP Authentication boundaries](../../notes/go-http-authentication-boundaries-validation-2026-07-19.md).
