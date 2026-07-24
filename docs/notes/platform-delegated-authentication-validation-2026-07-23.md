# Platform-Delegated Authentication Validation

Date: 2026-07-23

## Summary

Resolved the platform-delegated authentication pattern that blocked 3 components
(MLServer, caikit, caikit-tgis-backend) from analyzer-only routing. These
components have real inbound gRPC surfaces with authentication handled by
external platform infrastructure (kube-rbac-proxy sidecar, ModelMesh pod-local),
not by the component's own source code.

## Design Decision

**Approach A: Supplemental auth facts via Go analyzer flag** was chosen over:
- Approach B (GRPCService.Auth field): Would require changing `inboundRuntimeSurfaces()` logic
- Approach C (source_audited_empty_categories): Bypasses the Go analyzer's accounting mechanism
- Approach D (cross-repo sidecar detection): Fragile, depends on operator repo checkouts

The chosen approach:
1. Added `--supplemental-auth <path>` flag to the Go `extract` command
2. Added `platform_delegated_authentication` section to `analyzer_correction_adjudications.json`
3. Python static analysis reads entries and passes supplemental auth JSON to the Go binary
4. The Go extractor expands wildcard (`endpoint: "*"`, `methods: "gRPC"`) entries into
   per-service `AuthenticationFact` records matching each discovered `GRPCService`
5. `grpcAuthenticationAccounted()` finds the matching facts and accounts for the surfaces
6. Auth facts are visible in the output JSON and rendered in ANALYZER_ARCHITECTURE.md

This is the most principled approach because:
- Uses the existing `grpcAuthenticationAccounted()` mechanism without modification
- Auth facts are visible and auditable in the component-architecture.json
- The Go analyzer correctly accounts for surfaces (no Python-level bypassing)
- Generalizable: any future component with platform-delegated gRPC auth adds an entry to the adjudication JSON

## Component Audit

### MLServer (KServe kube-rbac-proxy sidecar)
- **gRPC surfaces**: 16 (11 GRPCInferenceService RPCs + 3 ModelRepositoryService RPCs + 2 Python registrations)
- **Auth mechanism**: KServe deploys kube-rbac-proxy sidecar intercepting all inbound traffic
- **Evidence**: `mlserver/grpc/server.py:88` uses `add_insecure_port` — no TLS, no auth interceptors
- **Result**: 16 synthetic auth facts injected, all surfaces accounted for

### caikit (ModelMesh pod-local)
- **gRPC surfaces**: 16 (7 mmesh.ModelMesh + 5 mmesh.ModelRuntime + 1 processproto.Process + 3 Python registrations)
- **Auth mechanism**: ModelMesh orchestrates caikit as co-located container; RPCs are pod-local
- **Evidence**: `grpc_server.py:199-234` supports optional TLS/mTLS, no auth interceptors
- **Result**: 16 synthetic auth facts injected, all surfaces accounted for

### caikit-tgis-backend (ModelMesh pod-local)
- **gRPC surfaces**: 4 (fmaas.GenerationService: Generate, GenerateStream, Tokenize, ModelInfo)
- **Auth mechanism**: Same ModelMesh pod-local pattern as caikit
- **Evidence**: `tgis_connection.py` TLS/mTLS transport only, no application-level auth
- **Result**: 4 synthetic auth facts injected, all surfaces accounted for

## Verification

### Pre-change baseline
- 54 approved, 57 eligible (baseline includes workbenches-operator regression from upstream source changes)
- MLServer: ineligible (bounded correction gaps: authentication)
- caikit: ineligible (bounded correction gaps: authentication)
- caikit-tgis-backend: ineligible (bounded correction gaps: authentication)

### Post-change
- 57 approved (+3: MLServer, caikit, caikit-tgis-backend)
- MLServer: eligible=True, approved=True
- caikit: eligible=True, approved=True
- caikit-tgis-backend: eligible=True, approved=True
- 0 regressions among previously approved components
- Go test suite: all tests pass (3 new tests for supplemental auth)
- 90-component replay: all 90 extracted and rendered successfully

## Files Changed

| File | Change |
|------|--------|
| `src/arch-analyzer/internal/extractor/extractor.go` | Added `SupplementalAuth` to Options, `expandSupplementalAuth()` function |
| `src/arch-analyzer/internal/extractor/categorycoverage_test.go` | 3 new tests for supplemental auth expansion and coverage |
| `src/arch-analyzer/cmd/root.go` | Added `--supplemental-auth` flag to extract command |
| `lib/analyzer_correction_adjudications.json` | Added `platform_delegated_authentication` section with 3 entries |
| `lib/phases/static_analysis.py` | Load and pass supplemental auth to Go binary per component |
| `lib/analyzer_only_approvals.json` | Added MLServer, caikit, caikit-tgis-backend |

## Negative Controls

- No changes to `inboundRuntimeSurfaces()` or `grpcAuthenticationAccounted()` logic
- No component names hardcoded in Go analyzer code
- Supplemental auth facts require explicit adjudication entries with evidence
- Go test suite verifies wildcard expansion and non-wildcard passthrough
- Components without platform_delegated_authentication entries are unaffected
