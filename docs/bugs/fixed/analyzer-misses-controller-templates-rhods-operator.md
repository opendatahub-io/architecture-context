# Bug: Static Analyzer Misses Controller-Embedded Templates in rhods-operator

## Summary

The arch-analyzer's Go template extraction pipeline fails to discover any
controller-embedded templates in rhods-operator (`controller_templates:
"not_found"`). This causes the analyzer to miss 77 Kubernetes resources
created at runtime by the gateway, auth, and monitoring service controllers
— including the EnvoyFilter that wires the `data-science-gateway` ext_authz
chain to kube-auth-proxy.

## Root Causes

Two bugs in `src/arch-analyzer/internal/gosource/gosource.go`:

### 1. Directory embed patterns not followed

rhods-operator's service controllers embed templates using bare directory
names:

```go
//go:embed resources
var gatewayResources embed.FS
```

`embeddedManifests()` passes the pattern to `filepath.Glob()`, which matches
the directory entry itself — not the files inside it. `embeddedManifestFile()`
then rejects the match because a directory path doesn't end in `.yaml`.

Affected embed directives (all in `internal/controller/`):

- `services/gateway/gateway_controller_actions.go` — `//go:embed resources`
- `services/auth/auth_controller_support.go` — `//go:embed resources`
- `services/monitoring/monitoring_controller_actions.go` — `//go:embed resources`, `//go:embed monitoring`
- `components/components.go` — 7 `//go:embed <component>/monitoring` directives

### 2. `.tmpl.yaml` extension not recognized

`embeddedManifestFile()` accepts `.yaml.tmpl` and `.yml.tmpl` but not the
reversed convention `.tmpl.yaml` used by rhods-operator (60 files).

```go
// Current — misses .tmpl.yaml:
func embeddedManifestFile(path string) bool {
    lower := strings.ToLower(path)
    return strings.HasSuffix(lower, ".yaml.tmpl") || strings.HasSuffix(lower, ".yml.tmpl") ||
        strings.HasSuffix(lower, ".yaml") || strings.HasSuffix(lower, ".yml")
}
```

## Impact

77 template-created resources are invisible to the analyzer (35 with
unhandled kinds, 42 with existing collectors). The missing
resource kinds and their counts from `internal/controller/` templates:

**Not in `collect()` switch (missed even after discovery fix):**

| Kind | Count | Architectural Significance |
|---|---|---|
| EnvoyFilter | 1 | Wires ext_authz → kube-auth-proxy for data-science-gateway authentication |
| DestinationRule | 1 | mTLS policy for kube-auth-proxy traffic |
| NetworkPolicy | 3 | Network segmentation for gateway and monitoring |
| HorizontalPodAutoscaler | 1 | kube-auth-proxy scaling |
| ServiceMonitor | 3 | Monitoring integration |
| PrometheusRule | 8 | Alerting rules |
| ServiceAccount | 3 | Identity for controller-created workloads |
| ValidatingAdmissionPolicy | 1 | Admission control |
| ValidatingAdmissionPolicyBinding | 1 | Admission control |
| MonitoringStack | 1 | Observability operator CR |
| OpenTelemetryCollector | 1 | Tracing/logging |
| Instrumentation | 1 | Auto-instrumentation |
| TempoStack | 1 | Distributed tracing |
| TempoMonolithic | 1 | Distributed tracing |
| ThanosQuerier | 1 | Metrics federation |
| Perses | 1 | Dashboard |
| PersesDatasource | 4 | Dashboard data sources |
| PersesDashboard | 2 | Dashboard definitions |

**Already in `collect()` switch (would work after discovery fix):**

| Kind | Count |
|---|---|
| Deployment | 5 |
| Service | 7 |
| Route | 6 |
| HTTPRoute | 1 |
| ClusterRole | 5 |
| ClusterRoleBinding | 8 |
| Role | 3 |
| ConfigMap | 4 |
| Secret | 3 |

## Platform-Level Consequence

The PLATFORM.md aggregation flagged the EnvoyFilter → ext_authz →
kube-auth-proxy chain as "not source-confirmed" because neither the
models-as-a-service nor kube-auth-proxy component analyses contained
it. The wiring lives in rhods-operator's gateway controller template
(`resources/envoyfilter-authn.tmpl.yaml`), which the analyzer never
discovered.

## Fix

### Discovery (gosource.go)

1. When `filepath.Glob` returns a directory, walk it to find manifest files
2. Add `.tmpl.yaml` and `.tmpl.yml` to `embeddedManifestFile()`

### Collection (extractor.go)

Add cases to the `collect()` switch for architecturally significant kinds
not currently handled. At minimum: `EnvoyFilter`, `DestinationRule`,
`NetworkPolicy`, `HorizontalPodAutoscaler`, `ServiceAccount`. The
observability CRs (ServiceMonitor, PrometheusRule, MonitoringStack, etc.)
could use a generic fallback that captures kind + name + namespace.

## Reproduction

```bash
# Verify templates are present but not discovered:
bin/arch-analyzer checkouts/red-hat-data-services.rhoai-3.6-ea.1/rhods-operator/ \
  2>&1 | grep controller_templates
# Output: "controller_templates": "not_found"

# Verify the templates exist:
find checkouts/red-hat-data-services.rhoai-3.6-ea.1/rhods-operator/internal/controller/ \
  -name "*.tmpl.yaml" | wc -l
# Output: 60
```
