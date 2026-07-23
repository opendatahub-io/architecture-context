# ADR-0013: Webhook Inventory Phase

## Status

Accepted

## Date

2026-05-13

## Context

Kubernetes admission webhooks (validating and mutating) are critical operational and security infrastructure: they intercept API requests, enforce policies, and can block cluster operations if misconfigured. The standard architecture analysis (phase 3) captured webhooks inconsistently because they're spread across kubebuilder markers, CRD conversion patches, and kustomize overlays.

Platform architects and SREs needed a comprehensive, cross-cutting view of all webhooks across all components -- including which resources they target, their failure policies, and which component actually owns them (since the RHOAI operator's prefetched manifests re-host webhooks from peer components).

## Decision

Add a dedicated webhook inventory phase (phase 4b) that:

1. Discovers webhooks from kubebuilder markers and CRD conversion patches
2. Resolves kustomize overlay membership to determine which webhooks are actually deployed
3. Maps Go handler files to understand validation/mutation logic
4. Spawns Claude agents to extract purpose and data dependencies
5. Splits webhook ownership: `platform_webhooks` (from the operator's prefetched manifests) vs `external_webhooks` (from peer components)
6. Enriches both per-component JSON and markdown with Admission Webhooks sections
7. Produces platform-wide `webhooks.json` with cross-cutting analysis

Also added `arch-query webhooks` subcommand with `--type`, `--target` (kube-style `resource.group`), and `--output text|wide|json` for querying.

## Consequences

Positive:
- Complete webhook inventory across the platform for the first time
- Correct ownership attribution (operator-hosted vs component-owned)
- Queryable via arch-query for SRE and security review workflows

Negative:
- Depends on kubebuilder marker conventions; components using non-standard webhook registration may be missed
- Additional pipeline phase increases full run time
