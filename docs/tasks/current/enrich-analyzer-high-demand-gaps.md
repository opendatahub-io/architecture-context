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

- [ ] Each added fact has schema, source provenance, and explicit unknown
      behavior.
- [ ] Ambiguous semantics remain agent-owned rather than inferred.
- [ ] Focused fixtures and analyzer tests cover every implemented priority.
- [ ] Merge demand and source-read replay show reduced reconstruction work.

## Status

Current
