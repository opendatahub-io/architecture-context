# Python Import→Category Coverage Wiring Validation

**Date:** 2026-07-21
**Task:** wire-python-import-category-coverage
**Branch:** feat/scripted-architecture-summaries

## Summary

Wired Python import analysis (`ImportAnalysis.Used` packages) into
`InternalDependency` and `IntegrationFact` entries so that
`categorycoverage.go` resolves limitations for Python components whose
category gaps are filled by confirmed-used packages.

## Changes

### Go source (src/arch-analyzer)

- **pythonsource/imports.go**: Added `pythonPlatformPackages` (7 entries)
  and `pythonIntegrationPackages` (6 entries) mapping tables.
  `importAnalysisInternalDependencies()` converts Used packages to
  `InternalDependency` facts; `importAnalysisIntegrationFacts()` converts
  to `IntegrationFact` entries. Both deduplicate by Component and enforce
  negative controls (no test-only, no utility libs, gRPC requires server).

- **pythonsource/pythonsource.go**: Added `Internal` and `Integrations`
  fields to `Result` struct, wired in `Extract()`.

- **extractor/extractor.go**: Merged `pythonFacts.Internal` and
  `pythonFacts.Integrations` into `model.Input` before `categoryCoverage()`.

- **platformfacts/platformfacts.go**: Added
  `externalConnectionIntegrationFacts()` converting Python
  `ExternalConnection` entries (SDK clients) to `IntegrationFact` entries,
  matching the existing `runtimeClientIntegrationFacts()` pattern.

### Tests

- **pythonsource/imports_test.go**: 10 new tests covering platform
  mappings, utility lib exclusion, gRPC server gate, dedup, source field
  fallback, integration SDK packages, and nil handling.

- **platformfacts/platformfacts_test.go**: 4 new tests for
  ExternalConnection→IntegrationFact conversion including dedup, test
  source exclusion, and empty service handling.

## Verification

### Go suite

- `go test ./... -count=1`: 12 packages pass (1 no-test)
- `go vet ./...`: clean

### 90-component corpus replay

- `uv run main.py static-analysis --platform=rhoai.next --force`:
  90 extracted, 0 failed, 0 skipped
- `uv run main.py collect-architectures --platform=rhoai.next`:
  90 collected

### Eligibility audit

- 45 previously approved components: all still route to `analyzer-only`
  (zero regressions)
- 0 false nominations from import wiring
- `rhods-operator` shows eligible (pre-existing, `python: not_applicable`)

### Target component results

| Component | internal_odh | integration_points | eligible | blocking gap |
|-----------|:---:|:---:|:---:|---|
| mlflow | 1 (Kubernetes API) | 5 (AWS S3, GCS, OpenAI + ExternalConnections) | **yes** | — |
| codeflare-sdk | 2 (Kubernetes API, Ray) | 0 | no | authentication |
| NeMo-Guardrails | 0 | 2 (OpenAI API, Azure OpenAI) | no | internal_dependencies (empty, no platform packages) |
| llm-d-latency-predictor | 0 | 0 | no | integration_points, internal_dependencies (both empty) |
| MLServer | 1 (gRPC framework) | 0 | no | authentication |
| caikit | 2 (Caikit Runtime, gRPC framework) | 0 | no | authentication |

### Approval

- Added `mlflow` to `lib/analyzer_only_approvals.json` (46 → 47 approved)
- Verified: mlflow routes to `analyzer-only` after approval

## Remaining gaps

The other 5 target components have category gaps outside the scope of
import-to-fact wiring:

- **codeflare-sdk, MLServer, caikit**: `authentication` category is
  empty — these are SDKs/runtimes with no inbound auth surfaces that the
  analyzer can detect. Would need `source_audited_empty_categories` entries
  after manual verification.

- **NeMo-Guardrails**: `internal_dependencies` is empty because no Python
  packages map to platform components. This is correct — the component
  has no Kubernetes, Ray, or KServe dependencies.

- **llm-d-latency-predictor**: Both `integration_points` and
  `internal_dependencies` are empty. No platform or SDK packages are used
  in shipped source. This is correct.
