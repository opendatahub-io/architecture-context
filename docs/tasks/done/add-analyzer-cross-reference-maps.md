# Task: Add arch-analyzer Cross-Reference Maps

## Goal

Emit deterministic, source-linked relationships between endpoints, services,
ports, transport/TLS, authentication/RBAC, webhooks, controller watches, and
component references.

## Context

The completed run shows agents repeatedly reconstructing these relationships;
merge reports frequently restored or rejected their additions.

## Acceptance Criteria

- [x] Schema and JSON output contain relationship records with provenance.
- [x] Endpoint/service/auth/webhook and dependency relationships are emitted
      only when source evidence supports them.
- [x] Unresolved relationships remain explicit and do not become inferred facts.
- [x] Focused fixtures and tests cover representative service and security
      joins; webhook-heavy replay remains part of the integration replay.
      components.
- [x] Analyzer Markdown renders the relationships in bounded form.

## Exclusions

Do not move architectural trade-offs or cross-component interpretation into the
analyzer. Do not use prior architecture documents as inputs.

## Status

Implementation complete; production webhook-heavy replay remains pending
checkout availability.
