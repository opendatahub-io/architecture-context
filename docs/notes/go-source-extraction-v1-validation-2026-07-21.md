# Go Source Extraction V1 — Validation Note

**Date**: 2026-07-21
**Reference run**: `rhoai.next-20260720T103625Z-3372001`
**Analyzer snapshot**: `rhoai.next-20260721T015309Z-static-v2`

## Summary

Extended Go source extractors to resolve 16 mutations across 7 components.
15 automated extraction contracts implemented; 1 adjudicated (argo-workflows DSP config injection).

### New Extractors

| Extractor | File | Resolves |
|-----------|------|----------|
| Controller components | `controller_components.go` | ai-gateway-payload-processing architecture_components (4 mutations) |
| CRD auth enum detection | `configurable_auth.go` (extended, cross-file) | ai-gateway-payload-processing authentication (3 mutations) |
| Default mux health endpoints | `servers.go` (extended) | argo-workflows authentication health endpoint |
| K8s client auth (3 patterns) | `k8s_client_auth.go` | argo-workflows ServiceAccount, kube-auth-proxy TokenReview, rhaii-cluster-validation kubeconfig |
| Cobra CLI components | `command_components.go` (extended) | rhaii-cluster-validation architecture_components |
| Cross-file gRPC reachability | `grpc_services.go` (extended) | llm-d-kv-cache gRPC authentication |
| Platform module prefix | `runtime_modules.go` + `platformfacts.go` | llm-d-async gateway-api dependency |
| GVR cross-file constant resolution | `operations.go` (extended) | eval-hub HardwareProfile CR dependency |
| ComponentRef resource group fallback | `platformfacts.go` (extended) | eval-hub internal dependency conversion |

### Cross-File Fixes

Two extractors initially failed on real components because they operated per-file:
- `extractEnumBasedCRDAuthentication`: AuthConfig struct in `common_types.go`, referenced by ExternalProviderSpec in `externalprovider_types.go`. Fixed by collecting structs across all files in the same package.
- GVR constant resolution: `hardwareProfileGVR` in `k8s_helper.go` references constants from `hardware_profile.go`. Fixed by building a package-level constant map via `collectPackageConstants`.

### Eligibility Resolution

| Component | Mutations Resolved | Status |
|-----------|-------------------|--------|
| ai-gateway-payload-processing | 2/7 | Candidate (approved) |
| argo-workflows | 2/3 | Candidate (approved) — DSP adjudicated, internal_dependencies source-audited |
| eval-hub | 0/1 | Candidate (approved) — HardwareProfile populates internal_dependencies |
| rhaii-cluster-validation | 1/2 | Candidate (approved) |
| kube-auth-proxy | 1/2 | Not candidate — internal_dependencies still empty |
| llm-d-async | 1/2 | Not candidate — authentication still empty |
| llm-d-kv-cache | 6/7 | Not candidate — authentication + internal_dependencies still empty |

### Corpus Replay

- 90 components extracted, 0 failures
- Zero false nominations in pre-approval eligibility check
- 4 components newly eligible (43 total, up from 39)
- All existing tests pass; 8 new tests added
- go vet clean

### Remaining Residual Gaps

Components not reaching candidacy have empty high-value categories that require either:
- Additional extractor contracts (kube-auth-proxy proxy auth, llm-d-async auth)
- Cross-language detection (llm-d-kv-cache TokenizationService registered in Python)
- Source-audited empty category entries after manual review

### Adjudications

1. **argo-workflows / internal_dependencies / DSP**: Workflow-controller accepts generic `--configmap` and `--executor-image` CLI flags. Source doesn't reference DSP. Deployment-time relationship.
2. **argo-workflows / internal_dependencies (source-audited empty)**: Platform alias references (gateway.networking.k8s.io) appear exclusively in generated API schema/swagger files, not runtime code.
