# Task: Extract Eval Hub Runtime Boundaries

## Goal

Resolve or source-adjudicate the eight accepted `eval-hub` structured corrections
through generic Go runtime-server, authentication, Kubernetes-client, and component
lifecycle contracts.

## Context

`eval-hub` is analyzer-sufficient but blocked by Architecture Components,
Authentication, and Internal Platform Dependencies. The historical agent added
three runtime components, two platform dependencies, and three Authentication
surfaces. Its source is a useful extension of the existing closed Go mux and runtime
client analysis, but conditional identity enforcement and a separate metrics server
must be modeled without assuming that every header or unwrapped route has the same
policy.

## Source And Evidence

- Checkout: `/data/checkouts/red-hat-data-services.next/eval-hub`
- Accepted baseline:
  `tmp/architecture-corpus-runs/rhoai-next-20260718T215431Z`
- Merge report:
  `tmp/architecture-corpus-runs/rhoai-next-inference-gateway-client-static-20260719T165652Z/logs/combined-merges-fresh/eval-hub.merge.md`
- Historical agent cost: 203.29 seconds, 7 reads, 4 source files, 8,658 output
  tokens, and $0.9234.

| Category | Accepted identity | Historical evidence |
|----------|-------------------|---------------------|
| Component | `eval-hub api server` | `internal/eval_hub/server/server.go:62-92` |
| Component | `metrics server` | `internal/eval_hub/server/metrics_server.go:16-43` |
| Component | `kubernetes helper` | `internal/eval_hub/runtimes/k8s/k8s_helper.go:19-25` |
| Internal dependency | `HardwareProfile CR` | `internal/eval_hub/runtimes/k8s/k8s_helper.go:70-90` |
| Internal dependency | `kube-rbac-proxy` | `internal/eval_hub/server/server.go:159-166` |
| Authentication | `/api/v1/evaluations/*` | `internal/eval_hub/server/server.go:382-395` |
| Authentication | `/api/v1/health` | `internal/eval_hub/server/server.go:200-212` |
| Authentication | `/metrics` | `internal/eval_hub/server/metrics_server.go:23-43` |

Treat these additions as hypotheses. In particular, prove proxy identity from
shipped configuration or source correlation rather than from an `X-User` label
alone.

## Required Contracts

- Correlate shipped Go entrypoints with constructed API and metrics server
  lifecycles and the concrete muxes each server serves.
- Inventory registered methods and patterns through local helpers, including the
  evaluation route family, health route, and metrics handler.
- Follow the complete local handler/middleware chain before declaring a surface
  authenticated or unauthenticated.
- Model conditional identity enforcement from runtime configuration. The evaluation
  routes require `X-User` and `X-Tenant` only in modes where source says they are
  required; local-mode bypass must remain visible.
- Correlate `kube-rbac-proxy` only when selected workload/manifests or a closed
  source contract prove that it supplies the headers. Logging a named header is not
  sufficient.
- Emit the Kubernetes helper component only if a shipped runtime constructs it and
  executes typed or dynamic client operations.
- Recognize the `HardwareProfile` dependency from concrete GVR construction and
  reachable dynamic-client operations, not merely from a string or schema import.
- Derive component and relationship identities generically from lifecycle and API
  semantics. Do not match `eval-hub` by component name.

## Negative Controls

Reject test-only servers, unused constructors, disconnected muxes, incomplete route
inventories, unknown/imported middleware, dynamically registered routes, headers
that are only logged, local-mode identity bypass presented as universal enforcement,
unselected proxy manifests, GVR declarations without executed operations, interface
types without construction, and the separate `evalhub_mcp` server unless its own
shipped lifecycle is independently proven.

## Acceptance Criteria

- [ ] Source-audit all eight historical additions and record invalid or overstated
  rows as explicit adjudications.
- [ ] Resolve or adjudicate 8/8 accepted corrections without component-specific
  exceptions.
- [ ] Add focused positive, conditional, and negative Go tests.
- [ ] Preserve all existing HTTP, client, component, renderer, and routing tests.
- [ ] Run `go test ./...` and `go vet ./...` in `src/arch-analyzer`.
- [ ] Run Ruff and the Python suite for affected routing/rendering behavior.
- [ ] Run a fresh 90-component replay with zero false nominations and all
  preservation, structural, and synthesis gates passing.
- [ ] Add approval only after the fresh replay proves eligibility.
- [ ] Run a bounded one-component production matrix if approval changes routing.
- [ ] Write a validation note, update the residual register and goal, and move this
  task to `docs/tasks/done/` only after all applicable gates pass.

## Likely Files

- `src/arch-analyzer/internal/gosource/runtime_servers.go`
- `src/arch-analyzer/internal/gosource/servers.go`
- `src/arch-analyzer/internal/gosource/security.go`
- `src/arch-analyzer/internal/gosource/runtime_graph.go`
- `src/arch-analyzer/internal/gosource/clients.go`
- `src/arch-analyzer/internal/platformfacts/platformfacts.go`
- `src/arch-analyzer/internal/normalize/normalize.go`

## Status

Done. 3/8 corrections resolved by analyzer, 5/8 source-adjudicated. Eval-hub
remains evidence-gated; approved set unchanged at 36. See
[validation](../../notes/eval-hub-runtime-boundaries-validation-2026-07-19.md).

## Acceptance Checklist

- [x] Source-audit all eight historical additions and record invalid or overstated
  rows as explicit adjudications.
- [x] Resolve or adjudicate 8/8 accepted corrections without component-specific
  exceptions.
- [x] Add focused positive, conditional, and negative Go tests.
- [x] Preserve all existing HTTP, client, component, renderer, and routing tests.
- [x] Run `go test ./...` and `go vet ./...` in `src/arch-analyzer`.
- [x] Run Ruff and the Python suite for affected routing/rendering behavior.
- [x] Run a fresh 90-component replay with zero false nominations and all
  preservation, structural, and synthesis gates passing.
- [ ] ~~Add approval only after the fresh replay proves eligibility.~~ Eval-hub is
  not eligible due to structural architecture_components and
  internal_dependencies gaps.
- [ ] ~~Run a bounded one-component production matrix if approval changes routing.~~
  No routing change.
- [x] Write a validation note, update the residual register and goal, and move this
  task to `docs/tasks/done/`.
