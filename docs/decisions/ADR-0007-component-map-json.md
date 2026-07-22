# ADR-0007: component-map.json as Pipeline Intermediate Artifact

## Status

Accepted

## Date

2026-04-27

## Context

Pipeline phases (architecture generation, collection, platform aggregation, diagrams) each independently discovered which components existed and how they mapped to repositories. This caused inconsistencies: one phase might find 28 components while another found 32, depending on how each parsed manifests and applied filters.

The discover-components phase was introduced to formalize component discovery, but its output needed a durable, machine-readable format that all downstream phases could consume.

## Decision

Introduce `component-map.json` as the intermediate artifact produced by the discover-components phase and consumed by all downstream phases. The schema includes:

- Component name, tier (managed/unmanaged/adjacent), and confidence level
- Repository URL, checkout branch, and local checkout path
- Discovery method (`discovered_via`: DSC spec, RELATED_IMAGE, catalog, image dependency, manual override)
- Platform overrides from `platforms.yaml`

All downstream phases read component-map.json instead of re-discovering components. The discover phase is skipped if component-map.json already exists (unless `--force` is passed).

## Consequences

Positive:
- Single source of truth for component inventory eliminates cross-phase inconsistencies
- Discovery results are cached, avoiding redundant manifest parsing on subsequent runs
- Machine-readable format enables programmatic filtering (by tier, confidence, discovery method)
- Validators catch schema violations early

Negative:
- Stale component-map.json can mask newly added/removed components; requires `--force` to regenerate
- Schema evolution requires updating validators and all consuming phases
