# ADR-0009: Sub-Agent Dispatch for Deep Code Analysis

## Status

Accepted

## Date

2026-04-28

## Context

Large operator repositories (e.g., odh-model-controller with 140+ Go files) exceeded a single agent's effective analysis capacity. The architecture skill would produce shallow documentation that missed controller reconciliation logic, webhook configurations, and integration points buried deep in the codebase.

## Decision

Add a sub-agent dispatch pattern to the architecture skill: the main agent enumerates files, groups them by functional area (controllers, webhooks, API types, config), and spawns sub-agents via the Task tool to read and analyze each group in parallel. Each sub-agent returns structured findings:

- Resources created, watched, and reconciled
- Webhook configurations and validation logic
- Integration points with other components
- Network exposure (ports, services, routes)
- RBAC requirements

The main agent aggregates sub-agent findings into the final architecture document. Language-specific reference docs (Go operator patterns, Python service patterns) guide sub-agents on what to look for.

Sub-agents write findings to temp files rather than returning them as messages, avoiding context window pressure on the main agent.

## Consequences

Positive:
- Significantly deeper analysis of complex operator repos (captured controller logic, webhook chains, RBAC)
- Parallel sub-agent execution reduced analysis time for large repos
- Reference docs standardize what sub-agents look for across different component types

Negative:
- More complex skill logic (enumeration, dispatch, aggregation)
- Temp file coordination adds failure modes (partial writes, missing files)
- Higher token cost per component (multiple agent invocations)
