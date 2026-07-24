# Manifest/Deployment Residuals Validation — 2026-07-21

## Summary

Resolved 18 mutations across 4 manifest-dependent components by implementing 3 extraction contracts and fixing 13 adjudication entries with correctly-keyed values. Added 1 source-audited empty category entry and approved 2 new components for analyzer-only generation.

## Results

| Component | Mutations | Extraction | Adjudication | Source-Audited | Eligible | Approved |
|-----------|-----------|------------|--------------|----------------|----------|----------|
| trustyai-explainability | 7 | 2 (prometheus) | 4 | 1 (authentication) | Yes | Yes |
| llm-d-planner | 6 | 3 (nodes, service-ca, k8s-api) | 3 | 0 | Yes | Yes |
| rhoai-mcp | 3 | 0 | 3 | 0 | Yes | No |
| llm-d-routing-sidecar | 2 | 0 | 2 | 0 | Yes | No |

**Total**: 18/18 mutations resolved, 45 components now approved (was 43).

## Extraction Contracts Implemented

### 1. Prometheus annotation extraction (collectors.go)

Detects `prometheus.io/scrape: "true"` on Service annotations and emits:
- `IntegrationFact{Component: "Prometheus", InteractionType: "Inbound scrape"}`
- `InternalDependency{Component: "Prometheus", Interaction: "monitoring"}`

Also extracts `prometheus.io/port` and `prometheus.io/path` for the IntegrationFact.

### 2. Service-CA annotation extraction (collectors.go)

Detects `service.beta.openshift.io/inject-cabundle: "true"` on ConfigMap annotations and emits:
- `InternalDependency{Component: "OpenShift Service CA", Interaction: "CA bundle injection"}`

Added `case "ConfigMap"` in the `collect()` switch (extractor.go).

### 3. Core RBAC node access (platformfacts.go)

Detects ClusterRole rules with `apiGroups: [""]` and infrastructure resources (nodes, persistentvolumes, storageclasses) and emits:
- `InternalDependency{Component: "Kubernetes API (nodes)", Interaction: "list"}`
- `IntegrationFact{Component: "Kubernetes API", InteractionType: "API client"}`

Scoped to infrastructure resources only to avoid false positives.

## Bug Fix: Manifest Internal Dependencies Overwritten

Discovered that `extractor.go:86` (`input.Dependencies = sourceFacts.Dependencies`) overwrote manifest-collected InternalDependencies with Go source dependencies. Fixed by preserving manifest-collected entries before the assignment.

## Verification

- `go test ./... -count=1` — all tests pass (11 new tests across 2 files)
- `go vet ./...` — clean
- 90-component corpus replay — 0 failures
- Routing policy confirms trustyai-explainability and llm-d-planner route to `analyzer-only`
- rhoai-mcp and llm-d-routing-sidecar route to `evidence-gated` (eligible but not approved)

## Adjudication Key Fix

All ~22 existing adjudication entries for the 4 target components had wrong keys that didn't match mutation keys after `_normalize_row_key()`. Replaced all with correctly-keyed entries matching exact mutation key values.
