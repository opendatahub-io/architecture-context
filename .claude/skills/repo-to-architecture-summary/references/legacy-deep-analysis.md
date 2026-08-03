# Legacy Deep Analysis

This reference is loaded only for `legacy` runs, or for a `partial` run when
the declared gap requires one of these checks. The analyzer baseline is always
read first; do not repeat analyzer-covered inspection.

## Discovery

Identify only unresolved or contradictory surfaces. For legacy runs, inspect
repository identity, language/build files, deployment manifests, Konflux
Dockerfiles, kustomize composition, and relevant source directories. Prefer
`Dockerfile.konflux`/`Containerfile.konflux` over generic Dockerfiles.

Use the applicable language reference for deep analysis:

- Go operators: `controller-analysis.md`
- Frontend/BFF: `frontend-bff-analysis.md`
- Python: `python-service-analysis.md`
- Go service: `go-service-analysis.md`
- Rust: `rust-service-analysis.md`
- Container-only: `container-image-analysis.md`
- Kustomize: `kustomize-manifest-analysis.md`
- Multi-tenancy: `multi-tenancy-analysis.md`

For large repositories, use up to three read-only Explore sub-agents per
batch. Each reads every assigned file, writes structured findings to a temp
file, and returns only a short confirmation. The parent reads and aggregates
those files. Never read `*_test.go` files.

## Required surfaces

Inspect CRDs, controllers/webhooks, dynamically created resources, APIs,
Services, sidecars, RBAC, Secret/ConfigMap references, NetworkPolicies,
service-mesh policies, and external integrations. Controller code is required
when it creates resources dynamically; manifests alone are insufficient.

For every claim, record relative path, line range, and output section in the
source-reference log. Reads must be justified by an analyzer gap, contradiction,
staleness check, or safety-critical dynamic behavior.

## Conditional checks

Use `konflux-component-discovery.md` for image inventory and component intent.
Use `aipcc-ecosystems-analysis.md` when Konflux Dockerfiles install Python.
Use `rhoai-ingress-analysis.md` for Gateway/HTTPRoute, Envoy, auth proxy,
OpenShift Route, redirect, and service-mesh behavior. Use
`multi-tenancy-analysis.md` for tenancy and isolation.
