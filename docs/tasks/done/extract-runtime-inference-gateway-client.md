# Task: Extract Runtime Inference Gateway Client

## Goal

Extract source-backed project-owned HTTP client construction and platform
relationships, starting with the global and per-model inference gateway resolvers
used by `batch-gateway`.

## Context

The standard runtime-client tranche recognizes well-known library constructors.
`batch-gateway` instead wraps its outbound inference transport in project-owned
constructors: runtime configuration selects global or per-model gateway URLs,
`NewClientset` creates a `GatewayResolver`, and the processor uses it for inference
requests.

The accepted architecture contains both an `llm-d inference gateway` Integration
Point and Internal Platform Dependency. Finding only a constructor name is not
enough: the analyzer must prove runtime reachability, outbound HTTP behavior, target
semantics, and project/module ownership without adding a `batch-gateway` exception.

## Acceptance Criteria

- [x] Follow runtime-reachable project-owned client factories through the bounded Go
  call graph rather than matching disconnected declarations or tests.
- [x] Require a concrete outbound HTTP transport or request execution path plus
  runtime endpoint configuration; a URL field or client-shaped type alone is not
  sufficient.
- [x] Correlate wrapper/resolver construction with the downstream transport while
  preserving global and per-model conditional configuration.
- [x] Derive the target and interaction from source/module semantics and typed
  configuration without a component-name exception.
- [x] Emit an Integration Point with runtime-configured port and encryption when the
  source does not prove fixed transport values.
- [x] Emit an Internal Platform Dependency only when source/module ownership proves
  that the target is an in-platform component.
- [x] Reject test-only, disconnected, configuration-only, generic HTTP utility, and
  ambiguous interface-dispatch cases.
- [x] Resolve the two accepted `batch-gateway` inference-gateway corrections while
  leaving its two Authentication corrections agent-owned.
- [x] Keep `batch-gateway` agent-routed until the Authentication residual is resolved
  or source-adjudicated.
- [x] A fresh 90-component replay has zero false approved nominations and passes
  preservation, structural, and synthesis gates.

## Files Likely Involved

- `src/arch-analyzer/internal/gosource/runtime_graph.go`
- `src/arch-analyzer/internal/gosource/service_clients.go`
- `src/arch-analyzer/internal/model/input.go`
- `src/arch-analyzer/internal/platformfacts/platformfacts.go`
- `src/arch-analyzer/internal/normalize/normalize.go`

## Status

Completed

## Baseline Evidence

- Replay:
  `tmp/architecture-corpus-runs/rhoai-next-runtime-commands-static-20260719T162833Z`
- Checkout: `fac0c8d8c69369662d46edf1bfecacf3bd15b5d2`
- Runtime selection: `cmd/batch-processor/main.go:283-299`
- Resolver construction: `internal/util/clientset/clientset.go:267-282`
- Accepted Integration Point and Internal Dependency evidence:
  `tmp/architecture-corpus-runs/rhoai-next-20260718T215431Z/logs/agents/batch-gateway.changes.md`

## Progress

- Initial source audit identified two runtime branches, global and per-model, which
  converge on project-owned inference resolvers. The implementation must continue
  through those resolvers to concrete outbound transport before emitting a fact.
- The extractor requires runtime reachability, configured Resty construction, a
  concrete outbound method, one complete semantic ancestor, and llm-d module
  ownership. Negative controls reject semantic sibling calls and incomplete client
  shapes.
- Replay
  `tmp/architecture-corpus-runs/rhoai-next-inference-gateway-client-static-20260719T165652Z`
  emitted the project-owned client only for `batch-gateway`, resolved 9/11 accepted
  corrections, retained 32 approvals with zero false nominations, and passed every
  gate. See [runtime inference gateway client validation](../../notes/runtime-inference-gateway-client-validation-2026-07-19.md).
