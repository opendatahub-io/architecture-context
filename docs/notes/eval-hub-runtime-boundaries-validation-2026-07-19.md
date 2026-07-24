# Eval Hub Runtime Boundaries Validation

## Summary

This tranche audited and resolved all 8 accepted `eval-hub` structured corrections
without component-specific exceptions. Three corrections are now resolved by the
analyzer through generic extraction improvements. Five corrections are
source-adjudicated as invalid or unreachable. Eval-hub remains evidence-gated
because two high-value categories (`architecture_components`,
`internal_dependencies`) have coverage gaps that cannot be resolved statically.

The approved analyzer-only set remains at 36.

## Corrections Addressed

| # | Category | Historical identity | Disposition | Evidence |
|--:|----------|---------------------|-------------|----------|
| 1 | Component | `metrics server` | **Resolved by analyzer** | Constructor-pattern metrics server detected via cross-file reachability from `main()` to `NewMetricsServer` in a different package |
| 2 | Authentication | `/api/v1/evaluations/*` | **Resolved by analyzer** | Conditional identity enforcement classified via delegated route registration (`s.handleFunc(mux, path, handler)`) |
| 3 | Authentication | `/api/v1/health` | **Resolved by analyzer** | Ungated health route correctly classified through same delegated registration pattern |
| 4 | Internal dependency | `kube-rbac-proxy` | **Adjudicated** | Comment-only references; no deployment manifest or programmatic sidecar construction |
| 5 | Component | `eval-hub api server` | **Adjudicated** | Single CMD binary; multi-command threshold (`>= 2`) not met |
| 6 | Component | `kubernetes helper` | **Adjudicated** | Client wrapper without listener lifecycle; not an architecture component |
| 7 | Internal dependency | `HardwareProfile CR` | **Adjudicated** | GVR operations reachable only through Go interface dispatch (`abstractions.Runtime`) |
| 8 | Authentication | `/metrics` | **Adjudicated** | Constructor-pattern metrics server negative auth is implicit from runtime server detection |

## Generic Extraction Improvements

### Cross-file runtime reachability for constructor-pattern servers

Changed `extractStandaloneRuntimeServers` and `constructorMetricsServers` to accept
a pre-computed cross-file reachability map from `runtimeReachableFunctions(files)`
instead of using single-file `functionReachableFromRuntimeRoot`. This enables
detection of metrics server constructors in packages separate from `main()`.

Files: `src/arch-analyzer/internal/gosource/gosource.go`,
`src/arch-analyzer/internal/gosource/runtime_servers.go`

### Delegated route registration

Extended `extractRoutePathFromSetup` to handle route paths registered through
receiver helper methods (`s.handleFunc(mux, "/path", handler)`) in addition to
direct mux calls (`mux.HandleFunc("/path", handler)`). The secondary pattern checks
for calls on the function's receiver where one argument is a string starting with
"/".

File: `src/arch-analyzer/internal/gosource/servers.go`

## Tests

- Updated `standaloneRuntimeServersSource` and `constructorMetricsServerSource`
  fixtures to use `func main()` instead of named functions, matching the cross-file
  reachability requirement.
- Updated `conditionalIdentitySource` fixture to use delegated route registration.
- All existing negative-control mutation tests preserved and passing.
- Go: `go test ./...` and `go vet ./...` pass.
- Python: `ruff check` and 131 tests pass including routing, rendering, and
  eligibility tests.

## Replay Results

Fresh 90-component replay at
`tmp/architecture-corpus-runs/rhoai.next-20260720T011611Z-3540380`:

| Measure | Value |
|---------|------:|
| Components | 90 |
| Analyzer-only | 36 |
| Evidence-gated | 46 |
| Legacy | 8 |
| Agent invocations | 54 |
| False nominations | 0 |
| Regressions on approved components | 0 |
| Workflow wall time | 1511.21s |
| Reduction from one-hour reference | 58.02% |

## Eligibility Analysis

Eval-hub has `sufficient` readiness with populated authentication (6 facts),
integration points (2 facts), and a source component (Metrics Server). However,
`analyzer_only_eligibility` returns `False` with reason: "bounded correction gaps:
architecture_components, internal_dependencies".

Blocking factors:

1. **`architecture_components`**: The analyzer identifies the metrics server as a
   source component but does not identify `eval-hub api server` (single CMD binary,
   threshold not met) or `kubernetes helper` (no listener lifecycle). The category
   remains a coverage gap without a complete-empty contract.

2. **`internal_dependencies`**: The `internal-platform-dependencies/v1` contract
   reports `status: partial` with 0 facts. One active platform alias reference
   (`infrastructure.opendatahub.io` in `hardware_profile.go`) requires relationship
   accounting, and multiple unsupported runtime source languages (shell scripts,
   Ruby formula) prevent completeness.

Both blockers are structural: the first is a legitimate single-binary architecture
where the historical agent inferred component identity from code structure rather
than shipped artifacts; the second is a Go interface dispatch limitation that
prevents static reachability tracing.

## Outcome

- 3/8 corrections resolved by generic extraction.
- 5/8 corrections source-adjudicated with documented reasoning.
- Approved set unchanged at 36 (eval-hub not eligible).
- Zero regressions, zero false nominations.
- Two generic improvements (cross-file constructor reachability, delegated route
  registration) available to all Go components.
