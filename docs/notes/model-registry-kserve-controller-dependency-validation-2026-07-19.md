# Model Registry KServe Controller Dependency Validation

**Date**: 2026-07-19
**Task**: `extract-model-registry-kserve-controller-dependency`
**Approved set change**: 35 to 36 (+1)

## Summary

Extended the Go analyzer to extract model-registry's genuine runtime dependency
on KServe InferenceService CRDs. Three generic improvements — no
model-registry-specific code:

1. Added KServe package path mapping in `formatGVK` so
   `github.com/kserve/kserve/pkg/apis/serving/v1beta1` produces canonical
   `serving.kserve.io/v1beta1/{Kind}` GVKs.
2. Added generic `resourceGroups` fallback in `watchInternalDependencies` so any
   controller watch on a known platform API group produces an internal
   dependency, regardless of controller name.
3. Improved alias scan classification: extended `ignoredCoverageDir` with
   mock/sample/fixture directories; added subdomain and Go identifier checks to
   eliminate false-positive blocking references.

## Newly Approved Component

### model-registry

- Revision: checkout at `/data/checkouts/red-hat-data-services.next/model-registry`
- KServe import: `github.com/kserve/kserve v0.17.0-rc1` in
  `cmd/controller/go.mod`
- Controller watches extracted:
  - `serving.kserve.io/v1beta1/InferenceService` via
    `InferenceServiceReconciler` (conditional)
  - `serving.kserve.io/v1beta1/InferenceService` via
    `InferenceServiceController`
- Internal dependencies: 2 KServe InferenceService facts (controller watches)
- Blocking alias references: 0 (9 former false positives correctly classified
  as naming convention or excluded by directory filter)
- Category coverage: internal_dependencies partial (fact_count=2, only
  limitation is "unsupported runtime source languages")
- Empty high-value categories: none
- Corrections resolved: 2/2
- Eligibility: candidate=yes, approved=yes, eligible=yes

## Gates

| Gate | Result |
|------|--------|
| KServe internal dependencies extracted | 2 facts |
| Watch GVKs canonical (`serving.kserve.io/...`) | Yes |
| Zero blocking alias references | Yes |
| Corrections resolved | 2/2 |
| Eligible after approval | Yes |
| Zero false nominations (corpus) | 0 |
| Corpus nominations | 36/64 sufficient |
| Zero-mutation recall | 94.74% |

## Static Replay

- Run:
  `tmp/architecture-corpus-runs/rhoai-next-mr-kserve-dep-static-20260719T234520Z`
- Components analyzed: 90
- Analyzer-only nominations: 36 (with model-registry approval)
- False nominations: 0
- Zero-mutation recall: 94.74%
- Baseline: `rhoai-next-20260718T215431Z`

## Bounded Production Matrix

- Run:
  `tmp/architecture-corpus-runs/rhoai-next-mr-kserve-dep-matrix-20260719T234520Z`
- Components: model-registry
- Route: analyzer-only
- All gates: pass

## Preservation

- Static replay artifacts:
  `tmp/architecture-corpus-runs/rhoai-next-mr-kserve-dep-static-20260719T234520Z/`
  - `analyzer/rhoai.next/` — 90 fresh analyzer JSON + MD snapshots
  - `reports/analyzer-only-eligibility.json` — full eligibility classification
  - `reports/analyzer-only-eligibility.md` — human-readable report
  - `reports/analyzer-snapshot.json` — component inventory
  - `run.json` — run metadata
- Matrix artifacts:
  `tmp/architecture-corpus-runs/rhoai-next-mr-kserve-dep-matrix-20260719T234520Z/`
  - `reports/model-registry-matrix.json` — bounded treatment matrix
  - `reports/analyzer-only-eligibility.json` — eligibility (shared)
  - `run.json` — matrix metadata
- Task file: `docs/tasks/done/extract-model-registry-kserve-controller-dependency.md`

## Timing

- Analyzer binary rebuild: ~2s
- Single-component static analysis (model-registry): ~5s
- Full 90-component static analysis: ~45s (all extracted, 0 failed)
- Eligibility analysis: ~2s

## Test Results

- Go unit tests: 8 new tests, all passing
  - KServe GVK canonical format
  - Generic watch-to-dependency for known platform API group
  - Self-owned API group rejected by generic fallback
  - Named controller case takes precedence over generic fallback
  - Mock/sample directory exclusion from alias scan
  - Subdomain alias classified as non-blocking
  - Go identifier alias classified as non-blocking
  - String literal alias remains blocking
- `go test ./...`: pass
- `go vet ./...`: pass

## Files Changed

- `src/arch-analyzer/internal/gosource/watches.go` — KServe package path
  mapping in `formatGVK`
- `src/arch-analyzer/internal/platformfacts/platformfacts.go` — generic
  `resourceGroups` fallback in `watchInternalDependenciesWithOwnedGroups`
- `src/arch-analyzer/internal/extractor/categorycoverage.go` — extended
  `ignoredCoverageDir`, added `aliasOnlyAsSubdomain` and
  `aliasOnlyInGoIdentifiers`, integrated into `classifyPlatformAliasMatch`
- `src/arch-analyzer/internal/gosource/watches_semantics_test.go` — KServe GVK
  test
- `src/arch-analyzer/internal/platformfacts/platformfacts_test.go` — 3 generic
  watch dependency tests
- `src/arch-analyzer/internal/extractor/categorycoverage_test.go` — 5 alias
  classification tests
- `lib/analyzer_only_approvals.json` — added `model-registry`
