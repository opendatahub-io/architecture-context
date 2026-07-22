# ADR-0004: Inject Kustomize Overlay Context into Agent Prompts

## Status

Accepted

## Date

2026-03-18

## Context

RHOAI components use kustomize overlays to configure deployments for different environments (e.g., `rhoai/onprem` for dashboard, `overlays/rhoai` for data science pipelines). The RHOAI operator's Go source code (`*_support.go` files) determines which overlay is applied for each component, along with image parameter substitutions and `params.env` values from prefetched manifests.

Without this context, architecture analysis agents would examine the wrong kustomize overlay (typically `default` or `base`), producing architecture docs that didn't reflect the actual RHOAI deployment. Early generated docs contained incorrect image references and missed RHOAI-specific configuration.

## Decision

Parse the RHOAI operator's Go source to extract per-component kustomize deployment context and inject it into each architecture agent's prompt. Specifically:

- Parse overlay paths from platform maps, named constants, and struct literals in `*_support.go`
- Extract `imageParamMap`/`imagesMap` entries to identify container image substitutions
- Read `params.env` from prefetched manifests for concrete configuration values
- Format the context as a prompt string injected between build metadata and skill instructions

Implemented in `lib/kustomize_context.py` with `get_component_kustomize_context()` and `format_kustomize_context()`.

## Consequences

Positive:
- Architecture docs now reflect actual RHOAI deployment configuration, not default/base overlays
- Image references in generated docs match what the operator actually deploys
- Agents analyze the correct set of deployment manifests, improving accuracy of network, security, and RBAC sections

Negative:
- Tightly coupled to the RHOAI operator's Go source code structure; changes to the operator's kustomize handling require parser updates
- Only works for RHOAI (not ODH upstream, which uses a different deployment model)
