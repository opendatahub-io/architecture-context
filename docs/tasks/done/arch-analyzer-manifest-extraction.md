# Task: Implement arch-analyzer Manifest Extraction

## Goal

Make `src/arch-analyzer` produce its own source-backed facts for Kubernetes YAML and
kustomize repositories instead of requiring an upstream-generated JSON file.

## Acceptance Criteria

- [x] `extract` command accepts a repository path.
- [x] Extracts CRDs, Deployments, Services, RBAC, bindings, Secrets, and ingress.
- [x] Records source file and line evidence for extracted facts.
- [x] Resolves a selected ODH or RHOAI kustomize overlay without duplicating bases.
- [x] Writes compatible `component-architecture.json`.
- [x] Extracted JSON renders through the existing MVP renderer.
- [x] Version-matched Kueue and Model Registry comparisons are recorded.
- [x] Extraction and rendering performance are measured independently.

## Status

Done on 2026-07-17.

## Notes

Port focused upstream packages when useful and record each import in
`src/arch-analyzer/UPSTREAM.md`.

## Results

The independently implemented extractor supports local resources, bases,
components, strategic merge patches, targeted file-based JSON6902 patches, name
prefixes/suffixes, namespaces, and common Kubernetes name references. It emits
CRDs, workloads and probes, services, RBAC, secret references, ingress resources,
and admission webhooks with `path:line` evidence.

Both measured documents pass the existing structural Markdown validator.

| Component | Source commit | Selected overlay | Extract | Render | Retained baseline rows | Conflicts |
|-----------|---------------|------------------|--------:|-------:|-----------------------:|----------:|
| Kueue | `02d9049` | `config/rhoai` | 0.06s | <0.01s | 25/121 (20.66%) | 7 |
| Model Registry Operator | `4392f88` | `config/overlays/odh` | 0.02s | <0.01s | 5/121 (4.13%) | 2 |

Kueue retains all 11 baseline CRDs, two of three services, two of three role
bindings, and two of three secrets. Its 35 unmapped candidate rows are mostly
admission webhooks that the comparator does not map into a baseline category.

Model Registry has no RHOAI overlay at the measured commit, so its exact-commit ODH
overlay is compared to the RHOAI baseline. The baseline also describes resources
created dynamically by the operator and source-code behavior, which manifest-only
extraction cannot recover. The candidate retains four of five HTTP endpoints from
manager probes and admission webhooks.

Both repositories report partial kustomize coverage. Generators, replacements,
legacy vars, image transforms, and inline patches remain explicit gaps. Source-code
analysis is also marked `not_analyzed` in compatibility JSON.
