# Integration Points Discovery Contract Validation

**Date**: 2026-07-19
**Contract**: `integration-points/v1`
**Approved set change**: 34 to 35 (+1)

## Summary

Implemented the `integration-points/v1` category-coverage contract in the Go
analyzer and Python routing. The contract uses existing structured extractor
outputs (RuntimeClients and ExternalConnections) rather than new source
scanning. A component receives `complete` status only when all five bounded
checks pass with no limitations.

## Contract Design

Five bounded checks determine completeness:

1. `normalized-integration-point-facts` — counts emitted IntegrationPoints.
2. `outbound-runtime-client-accounting` — every runtime-sourced RuntimeClient
   is covered by an IntegrationFact.
3. `external-connection-accounting` — every runtime-sourced ExternalConnection
   is covered by an IntegrationFact.
4. `supported-language-surface-inventory` — no unsupported runtime source
   languages present.
5. `manifest-resolution-completeness` — no manifest parse failures or
   unselected manifests.

Test-only, example-only, benchmark, and vendored sources are filtered by the
shared `runtimeSurfaceSource` predicate before accounting checks.

## Newly Approved Component

### guardrails-regex-detector

- Revision: `5c6116749e66a3496f7a5ac7427219f294df7ec3`
- Source: 213-line Rust Axum service, two inbound routes, zero outbound
  connections
- Contract result: complete, 0 facts, 5/5 checks, 0 limitations
- Contract-complete empty categories: integration_points,
  internal_dependencies
- Populated categories: architecture_components, authentication (empty table
  but populated header)
- Source audit: completed in
  [completeness-only candidate audit](completeness-only-candidate-audit-2026-07-19.md)

## Corpus-Wide Impact

Across the 90-component corpus:

- 11 components receive complete-empty integration_points
- 79 components remain partial (unaccounted clients, external connections,
  unsupported languages, or manifest limitations)
- The contract did not widen any existing complete-empty claims

## Static Replay

- Run:
  `tmp/architecture-corpus-runs/rhoai-next-integration-points-static-20260719T203809Z`
- Components analyzed: 90/90
- Analyzer-only nominations: 35 (with approval)
- False nominations: 0
- Zero-mutation recall: 92.11%

## Bounded Production Matrix

- Run:
  `tmp/architecture-corpus-runs/rhoai-next-integration-points-matrix-20260719T204528Z`
- Components: guardrails-regex-detector
- Route: analyzer-only
- Agent invocations: 0
- Wall time: 2.49s
- Cost: $0.00

## Test Results

- Go unit tests: 10 new tests, all passing
  - Complete-empty standalone service
  - Partial for unaccounted outbound HTTP client
  - Complete when clients are accounted for
  - Partial for unaccounted external connection
  - Complete when external connections accounted for
  - Partial for unsupported language
  - Partial for manifest parse failure
  - Ignores test-only client
  - Ignores example-only connection
  - Partial for dynamic endpoint dispatch
- `go test ./...`: pass
- `go vet ./...`: pass
- Python routing tests: 4 new tests, all passing
  - Complete-empty integration points with contract
  - Rejects wrong contract
  - Rejects nonempty facts
  - All three contracts allow analyzer-only
- Ruff: pass
- Full Python test suite: 131 tests, all passing

## Files Changed

- `src/arch-analyzer/internal/extractor/categorycoverage.go` — added
  `integrationPointsCoverage()` and helper functions
- `src/arch-analyzer/internal/extractor/categorycoverage_test.go` — 10 new
  tests
- `lib/architecture_routing.py` — added `integration_points` to
  `COMPLETE_EMPTY_CATEGORY_CONTRACTS` and `_analyzer_fact_count()`
- `lib/analyzer_only_approvals.json` — added `guardrails-regex-detector`
- `tests/test_architecture_routing.py` — 4 new tests, added
  `integration_points` to helper JSON
