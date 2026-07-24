# Python Import Analysis Validation

Date: 2026-07-21

Task: [Extract Python dependency-import relationships](../tasks/done/extract-python-dependency-import-relationships.md)

## Summary

Implemented a Python AST-based import analyzer (`python_import_analyzer.py`)
and wired it into the Go arch-analyzer via `exec.Command`. The analyzer
statically resolves which declared Python dependencies are actually imported
in shipped source, classifies test-only and declared-unused packages, detects
gRPC server registrations, and maps optional dependency groups.

## New Files

| File | Lines | Purpose |
|------|------:|---------|
| `scripts/python_import_analyzer.py` | ~180 | AST import analyzer (stdlib only: ast, tomllib, json, pathlib) |
| `scripts/test_python_import_analyzer.py` | ~475 | 48 pytest tests with positive/negative controls |
| `scripts/embed.go` | 6 | Go embed wrapper for Python script |
| `internal/pythonsource/imports.go` | 113 | Go exec wrapper + JSON consumer + gRPC service producer |
| `internal/pythonsource/imports_test.go` | 222 | Go unit tests for JSON parsing, gRPC service emission, dedup |

## Modified Files

| File | Change |
|------|--------|
| `internal/pythonsource/pythonsource.go` | Added `Imports *ImportAnalysis` to Result; wired `extractImportAnalysis` + `importAnalysisGRPCServices` into Extract(); updated Coverage string |

## Test Results

| Suite | Tests | Result |
|-------|------:|--------|
| Python (pytest) | 48 | All pass |
| Go (`go test ./...`) | 13 packages | All pass |
| Go (`go vet ./...`) | 13 packages | Clean |

## Corpus Validation

90-component static replay:

| Measure | Result |
|---------|-------:|
| Components extracted | 90 |
| Extraction failures | 0 |
| False nominations | 0 |

### Non-target component changes

| Type | Count | Impact |
|------|------:|--------|
| Coverage string updated | 33 | Informational only — Python repos now include import analysis metadata |
| feast gRPC services | +4 | Legitimate registrations (GrpcFeatureServer, RegistryServer, TransformationService, Health); feast already approved |
| integration_points changes | 15 | From prior Go source extractor work (commit c5276e40), not from import analysis |

## Target Component Results

| Component | Import analysis | gRPC registrations | New gRPC facts | Eligible |
|-----------|----------------|:------------------:|:---------------:|----------|
| MLServer | 27 used, 21 test-only, 6 unused | 2 (GRPCInferenceService, ModelRepositoryService) | +2 | No |
| caikit | 29 used, 8 test-only, 6 unused | 3 (Process, ModelRuntime, Health) | +3 | No |
| codeflare-sdk | 7 used, 0 test-only, 3 unused | 0 | 0 | No |
| kubeflow-sdk | setup.py (no_dependencies_found) | 0 | 0 | No |

## Why Target Components Are Not Yet Eligible

All four components still have empty high-value categories:

| Component | authentication | integration_points | internal_dependencies |
|-----------|:--------------:|:------------------:|:---------------------:|
| MLServer | partial (0) | partial (0) | partial (0) |
| caikit | partial (0) | partial (0) | partial (0) |
| codeflare-sdk | partial (0) | complete (0) | partial (0) |
| kubeflow-sdk | partial (1) | complete (0) | partial (0) |

The import analysis resolves the **gRPC registration detection** gap
(MLServer +2, caikit +3) but does not yet produce `InternalDependency` or
`IntegrationFact` facts from the dependency usage data. Converting import
analysis results into category-level facts would require additional work in
`categorycoverage.go` to map used dependencies to platform aliases and
integration classifications.

## What the Import Analysis Provides

The `ImportAnalysis` struct on `pythonsource.Result` contains:

- **Used**: packages imported in shipped source with file:line references
- **TestOnly**: packages imported only in test paths
- **DeclaredUnused**: declared dependencies with no matching imports
- **OptionalGroups**: per-group used/unused classification
- **GRPCServer**: whether `grpc.server()` / `grpc.aio.server()` is called
- **GRPCRegistrations**: `add_*Servicer_to_server()` calls with source refs

This data is available for future category coverage integration.

## Negative Controls Verified

- **pyproject.toml not proof of usage**: Declaring a dependency without
  importing it results in `declared_unused`, not `used`.
- **Optional extras not conflated**: Optional group packages are classified
  separately from required dependencies.
- **Proto without registration**: `.proto` files without
  `add_*Servicer_to_server()` calls don't produce registration facts.
- **Test-only imports**: conftest.py, test directories, test_ prefixed files
  correctly classified as test paths.
- **Namespace packages**: `google.protobuf` imports don't match
  `google-cloud-storage` (no cross-contamination).

## kubeflow-sdk Limitation

kubeflow-sdk uses `setup.py` with `requirements.in`, not `pyproject.toml`.
The analyzer handles this gracefully by returning `no_dependencies_found`
status. The import analysis doesn't produce results for this component.
A `setup.py` parser could be added in future work.
