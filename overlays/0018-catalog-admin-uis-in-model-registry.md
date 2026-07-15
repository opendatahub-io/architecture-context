---
id: "0018"
title: Catalog admin UIs (Model Catalog and MCP Catalog) belong to the model-registry module
status: active
created: 2026-07-09
affects:
  - model-registry
  - odh-dashboard
release:
  - "all"
provenance:
  - https://github.com/red-hat-data-services/model-registry/tree/main/catalog
  - https://github.com/red-hat-data-services/odh-dashboard/tree/main/manifests/modular-architecture/modules/model-registry
author: Andrew Ballantyne
superseded_by: null
---

## Fact

Both catalog admin UIs — Model Catalog and MCP Catalog — are features of the **model-registry** module, not the gen-ai module. This applies to every layer of the stack:

| Layer | Component | Location |
|-------|-----------|----------|
| Backend API | Model Catalog REST API (`/api/model_catalog/v1alpha1/*`) | model-registry repo (`catalog` subcommand) |
| Backend API | MCP Catalog REST API (`/api/mcp_catalog/v1alpha1/*`) | model-registry repo (`catalog` subcommand) |
| BFF proxy | Model Catalog + MCP Catalog proxy routes | model-registry BFF in odh-dashboard |
| Frontend UI | Catalog source admin, catalog browsing | model-registry module in odh-dashboard |

MCP Catalog is a variant of the same catalog feature — it reuses the same backend service, the same BFF proxy layer, and the same admin UI patterns as Model Catalog. Both are managed through the model-registry module's deployment and RBAC.

## Impact on Strategies

- Strategies must attribute catalog admin UI work (source management, catalog configuration, catalog browsing) to the **model-registry** team and module — not gen-ai
- MCP Catalog admin UI follows the same ownership as Model Catalog admin UI — both are model-registry features
- Dependencies on catalog admin capabilities should reference the model-registry component, not gen-ai
- The gen-ai module is a *consumer* of catalog data (e.g., browsing models for deployment), but does not own the catalog admin surfaces

## Context

Generated architecture docs describe the gen-ai module as owning catalog-related UI because it consumes catalog data for model discovery and deployment flows. However, the admin UIs for managing catalog sources and configuration are part of the model-registry module. The catalog backend itself (`model-catalog` service) is built from the model-registry repo and proxied exclusively through the model-registry BFF. This overlay corrects the ownership boundary so strategies assign catalog admin work to the correct team.
