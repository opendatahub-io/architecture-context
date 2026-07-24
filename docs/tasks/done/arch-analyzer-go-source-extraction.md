# Task: Implement arch-analyzer Go Source Extraction

## Goal

Add high-confidence Go source facts to manifest extraction without invoking an agent
or requiring the upstream architecture-analyzer binary.

## Acceptance Criteria

- [x] Parse the root Go module version and direct dependencies.
- [x] Extract controller-runtime `For`, `Owns`, and `Watches` registrations when the
      watched type is statically identifiable.
- [x] Extract literal HTTP route registrations from common Go routers.
- [x] Extract Kubernetes client operations when the target API type is locally
      identifiable.
- [x] Record source file and line evidence for every source-derived fact.
- [x] Exclude vendor, generated, and test-only source.
- [x] Deduplicate source facts before compatibility JSON is rendered.
- [x] Add focused AST fixtures and end-to-end extraction tests.
- [x] Record exact-commit Kueue and Model Registry coverage and timing changes.

## Status

Done on 2026-07-17.

## Boundaries

The first pass does not perform Go type checking, pointer analysis, or call-graph
construction. Dynamic route strings and watched objects returned from helper methods
remain explicit gaps until a higher-confidence analysis is added.

## Results

The extractor uses `go/ast` for source facts and `golang.org/x/mod/modfile` for the
root module. It extracts direct dependencies, literal router registrations,
controller-manager health checks, controller-runtime builder watches, and typed
Kubernetes client operations. Test files, standard generated files, vendor trees,
and test/helper directories are excluded.

| Component | Extract | Render | Dependencies | Watches | Routes | Operation targets | Retained rows |
|-----------|--------:|-------:|-------------:|--------:|-------:|------------------:|--------------:|
| Kueue | ~0.2s | <0.01s | 37 | 29 | 15 | 19 | 27/121 (22.31%) |
| Model Registry Operator | ~0.03s | <0.01s | 17 | 19 | 2 | 15 | 18/121 (14.88%) |

Kueue includes the expected 13 `kueue-viz` WebSocket routes plus `/healthz` and
`/readyz`. Model Registry recovers all 17 watches in the stored analyzer JSON and
adds two source-backed conditional watches for OpenShift Routes and
ClusterRoleBindings that the stored output omitted.

Compared with manifest-only extraction, Kueue retained rows increase from 25 to 27
and Model Registry increases from 5 to 18. The low Kueue increment is primarily a
fixture-normalization issue: the source facts use precise module paths and GVKs while
the baseline uses synthesized component labels such as `Kubernetes` and
`controller-runtime`.

Both generated documents pass structural validation. Source coverage is explicitly
partial because only the root Go module is scanned, dynamic expressions are skipped,
and Go type checking and call-graph analysis are not performed.
