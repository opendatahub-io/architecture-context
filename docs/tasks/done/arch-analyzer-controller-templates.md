# Task: Extract Controller-Created Resource Templates

## Goal

Recover Kubernetes resources created dynamically by operators from source-referenced
embedded YAML and Go-template files, while keeping them distinguishable from the
operator's own deployment manifests.

## Acceptance Criteria

- [x] Discover template files through `//go:embed` directives.
- [x] Sanitize non-executable Go-template YAML into parseable structural YAML.
- [x] Preserve source file and line evidence.
- [x] Extract controller-created workloads, services, RBAC, secrets, and routing.
- [x] Mark generated resources and conditional values explicitly.
- [x] Avoid duplicate facts from overlapping embed patterns.
- [x] Add conditional-template and end-to-end fixtures.
- [x] Record exact-commit Kueue and Model Registry coverage and timing changes.

## Status

Done on 2026-07-17.

## Boundaries

The analyzer does not execute repository template functions or select a runtime CR
configuration. Conditional branches describe possible resources and values. Dynamic
resources built entirely through Go object construction remain a later milestone.

## Results

Embed discovery is performed during the existing Go AST pass, so repositories without
embedded manifests are not parsed twice. Embedded YAML and `.yaml.tmpl` files are
deduplicated across overlapping patterns. Template control lines are removed without
changing source line numbers, dynamic scalars become explicit placeholders, and
duplicate mapping keys from alternate branches retain the first possible branch.
Alternative sequence entries remain visible as possible containers and ports.

Model Registry extraction now includes four controller-created Deployments, four
controller-created Services, five possible Route/HTTPRoute resources, template RBAC,
and template secret references. Catalog templates are normalized to the source-backed
singleton identity `model-catalog`; per-CR templates use `{registry-name}`.

| Component | Extract | Render | Retained rows | Conflicts | Template coverage |
|-----------|--------:|-------:|--------------:|----------:|-------------------|
| Kueue | ~0.19s | <0.01s | 27/121 (22.31%) | 6 | Not found |
| Model Registry Operator | ~0.04s | <0.01s | 34/121 (28.10%) | 9 | Partial, conditional branches |

Model Registry improves from 18 retained rows after Go source extraction to 34. All
four baseline Service identities and all four baseline ingress identities are
retained. Ingress has zero populated-cell conflicts after preserving unknown
HTTPRoute protocol and normalizing Route domain placeholders. The remaining service
conflicts primarily reflect runtime selection between the 8080 HTTP and 8443 HTTPS
template branches; these values are deliberately not hardcoded.

Both exact-commit outputs pass structural Markdown validation. Kueue results are
unchanged except for one corrected ClusterRoleBinding scope conflict.
