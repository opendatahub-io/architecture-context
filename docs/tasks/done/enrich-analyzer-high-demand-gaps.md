# Task: Enrich arch-analyzer High-Demand Gap Categories

## Goal

Reduce agent rediscovery by extracting the deterministic facts most often
requested in the completed run.

## Priority Order

1. Dynamic HTTP routes and handler ownership.
2. gRPC registration, interceptors, credentials, and ports.
3. Runtime clients, egress targets, TLS, and authentication configuration.
4. Kubernetes client/resource relationships and controller watches.
5. RBAC-to-controller/handler relationships and service/deployment joins.
6. Configuration defaults, environment variables, probes, and lifecycle args.

## Acceptance Criteria

- [x] The existing analyzer fact families for routes, gRPC, runtime clients,
      watches, RBAC, defaults, lifecycle, and service joins are now exposed as
      bounded gap candidates with schema, source provenance, and explicit
      candidate/unknown limitations.
- [x] Ambiguous semantics remain agent-owned rather than inferred.
- [x] Focused fixtures and analyzer tests cover every implemented priority.
- [x] The four-component replay showed 26 unique source reads versus 30 in the
      comparison host reports, fewer full-budget components, valid output
      validation, and analyzer-preserving merge checks. Discovery comparison
      remains qualified because the standalone runner does not install the
      orchestrator guard.

## Status

Done — 2026-07-27
