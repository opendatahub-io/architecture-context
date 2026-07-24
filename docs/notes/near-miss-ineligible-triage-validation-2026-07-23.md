# Near-Miss Ineligible Component Triage Validation

## Summary

Triaged 3 near-miss ineligible components, each blocked by a single category.
All 3 resolved and approved: llm-d-async, llm-d-routing-sidecar, and
workbenches-operator (regression fix). Approved count: 57 -> 62 (includes
3 from prior platform-delegated auth task).

## Component Dispositions

### llm-d-async — approved (was blocked by `authentication`)

**Root cause**: Two classification gaps in `categorycoverage.go`:

1. `runtimeSurfaceSource()` did not exclude `docs/` directories. The file
   `docs/guides/e2e-deploy/modelserver/patch-vllm.yaml` (a documentation
   manifest) was counted as an inbound runtime surface, contributing 2 of the
   4 inbound surfaces (deployment liveness/readiness probes).

2. `inboundRuntimeSurfaces()` counted HTTP endpoints without checking for
   matching authentication facts. gRPC services already had auth accounting
   via `grpcAuthenticationAccounted()`, but HTTP endpoints did not.

**Fixes**:
- Added `"docs"` to `runtimeSurfaceSource()` exclusion list (line 411)
- Added `httpAuthenticationAccounted()` function mirroring the gRPC pattern
- Used it in `inboundRuntimeSurfaces()` for HTTPEndpoints
- Added platform-delegated auth for `/healthz` and `/readyz` health probes
  (Kubernetes kubelet health probes — unauthenticated by design)
- Extended `_load_platform_delegated_auth()` to handle `scope: "http-endpoints"`

**Evidence**: health.go registers `/healthz` (always 200) and `/readyz`
(200/503 based on readiness state) on a dedicated health port using plain
`http.ServeMux` with no middleware, no TLS, and no authentication. These are
standard Kubernetes liveness/readiness probe endpoints.

### llm-d-routing-sidecar — approved (was blocked by `internal_dependencies`)

**Root cause**: The only active platform alias reference was `route.openshift.io`
in `deploy/openshift/patch-route.yaml` — an OpenShift Route API group
(infrastructure primitive, not a platform component dependency). The kustomize
`configMapGenerator` was an empty scaffold with no data entries.

**Fix**: Source-audited `internal_dependencies` as empty. The route.openshift.io
reference configures the component's own ingress via a standard OpenShift Route,
similar to how Kubernetes API was source-audited for mlflow and
rhaii-cluster-validation.

### workbenches-operator — regression fixed (was blocked by `architecture_components`)

**Root cause**: Upstream Go restructuring moved source files, causing the analyzer
to stop detecting the controller as a component identity. The
`architecture_components` table became empty (0 workloads, 0 services).

**Fix**: Source-audited `architecture_components` as empty. The operator is a
lightweight single-controller binary that reconciles Workbenches CRs and
registers 2 mutating webhooks. It does not deploy distinct sub-components — an
empty architecture_components table is the expected output.

**Note**: workbenches-operator was already in the approvals list from a prior
review. This fix restores it to eligible status after the upstream regression.

## Verification

### Pre-change baseline
- 57 approved, 60 eligible (includes workbenches-operator regression)
- llm-d-async: ineligible (bounded correction gaps: authentication)
- llm-d-routing-sidecar: ineligible (bounded correction gaps: internal_dependencies)
- workbenches-operator: ineligible (bounded correction gaps: architecture_components)

### Post-change
- 62 approved (+2 new: llm-d-async, llm-d-routing-sidecar; +3 from prior task)
- llm-d-async: eligible=True, approved=True
- llm-d-routing-sidecar: eligible=True, approved=True
- workbenches-operator: eligible=True, approved=True (regression resolved)
- 0 regressions among previously approved components
- Go test suite: all tests pass (4 new tests)
- 90-component replay: all 90 extracted and rendered successfully

## Files Changed

| File | Change |
|------|--------|
| `src/arch-analyzer/internal/extractor/categorycoverage.go` | Added `"docs"` to `runtimeSurfaceSource()` exclusion; added `httpAuthenticationAccounted()` |
| `src/arch-analyzer/internal/extractor/categorycoverage_test.go` | 4 new tests: docs exclusion, HTTP auth accounting (positive + negative), docs deployment probes |
| `lib/analyzer_correction_adjudications.json` | Source-audited: llm-d-routing-sidecar internal_deps, workbenches-operator architecture_components; platform-delegated auth: llm-d-async health probes |
| `lib/phases/static_analysis.py` | Extended `_load_platform_delegated_auth()` for `http-endpoints` scope |
| `lib/analyzer_only_approvals.json` | Added llm-d-async, llm-d-routing-sidecar |

## Negative Controls

- No weakening of inbound surface counting for legitimate runtime endpoints
- HTTP auth accounting mirrors existing gRPC pattern — only accounts for exact path matches
- docs/ exclusion is consistent with `ignoredCoverageDir()` which already excludes docs/
- Platform-delegated auth facts require explicit adjudication entries with evidence
- Components without platform_delegated_authentication entries are unaffected
- Go test suite includes positive and negative test cases for all changes
