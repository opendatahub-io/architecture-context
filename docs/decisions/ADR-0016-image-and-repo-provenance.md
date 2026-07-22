# ADR-0016: Image Dependency and Repo Provenance Discovery

## Status

Accepted

## Date

2026-06-26

## Context

Component discovery (ADR-0007) found components through DSC spec entries, RELATED_IMAGE references, and catalog parsing. But components shipped as pip dependencies inside container images (e.g., `codeflare-sdk` bundled into notebook images) were missed entirely. Additionally, the upstream→downstream repository relationship (e.g., `opendatahub-io/kserve` → `red-hat-data-services/kserve`) was not captured, making it difficult to trace architectural lineage.

## Decision

Add two discovery mechanisms to the discover-components skill:

**Image dependency discovery** (`parse_image_dependencies.py`):
- Scan `pyproject.toml` and `requirements*.txt` in image-building repos (e.g., notebooks)
- Match Python package names against checked-out repos
- Components found this way are tagged `discovered_via: image_dependency`
- Closes the gap where pip-bundled components were invisible to DSC/RELATED_IMAGE logic

**Repo provenance** (`parse_repo_provenance.py`):
- Map upstream (opendatahub-io) repos to downstream (red-hat-data-services) repos
- Record provenance in component-map.json and make it queryable via arch-query
- Enables tracing architectural decisions from upstream design to downstream deployment

## Consequences

Positive:
- Complete component inventory including pip-bundled dependencies
- Upstream→downstream traceability for every component
- Provenance data available to agents for cross-repo architectural analysis

Negative:
- Python package name → repo matching is heuristic-based; uncommon naming conventions may be missed
- Provenance mapping depends on org naming conventions (opendatahub-io → red-hat-data-services)
