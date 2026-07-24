# Task: Wire Python Import Analysis into Category Coverage

## Goal

Convert Python import analysis data (`ImportAnalysis.Used` packages) into
`InternalDependency` and `IntegrationFact` entries so that `categorycoverage.go`
can resolve limitations for components whose category gaps are provably filled
by confirmed-used Python packages.

## Context

The Python AST import analyzer (Task 7) produces structured import analysis
for Python components: which declared dependencies are actually imported in
shipped source, which are test-only, and which are declared but unused. This
data is available on `pythonsource.Result.Imports` but is NOT carried into
`model.Input` or converted to dependency/integration facts. As a result:

- `internalDependencyCoverage()` scans Python source files for platform
  aliases (e.g., `kubeflow.org`, `ray`), finds them, and flags them as
  blocking "runtime source/config reference" limitations — even though the
  import analyzer has confirmed exactly which packages are used.
- `integrationPointsCoverage()` checks `RuntimeClients` and
  `ExternalConnections` against `IntegrationFact` entries, but Python SDK
  client connections have no corresponding integration facts.
- Components with confirmed-used Python platform packages remain ineligible
  because the category coverage system can't see the import analysis data.

The `platformfacts.go` module already converts Go `RuntimeClients` to both
`InternalDependency` and `IntegrationFact` entries (lines 151-152). This
task extends that pattern to Python import analysis results.

## Source And Evidence

- Eligibility report:
  `tmp/architecture-corpus-runs/rhoai.next-20260720T173035Z-static/reports/eligibility-v1.json`
- Residual register: `docs/notes/analyzer-residual-agent-gaps.md`
- Adjudications: `lib/analyzer_correction_adjudications.json`
- Import analysis types: `src/arch-analyzer/internal/pythonsource/imports.go`
- Category coverage: `src/arch-analyzer/internal/extractor/categorycoverage.go`
- Platform facts: `src/arch-analyzer/internal/platformfacts/platformfacts.go`
- Python extraction pipeline: `src/arch-analyzer/internal/pythonsource/pythonsource.go`
- Extraction wiring: `src/arch-analyzer/internal/extractor/extractor.go`

## Target Components

Components with `internal_dependencies` and/or `integration_points` gaps
that have Python import analysis data available:

| Component | Mutations | Current gaps | Import analysis state |
|-----------|----------:|--------------|----------------------|
| `mlflow` | 5 | `internal_dependencies` | Auth resolved (absence-of-auth). Import data available. |
| `NeMo-Guardrails` | 4 | `internal_dependencies` | SDK client resolved (Azure OpenAI). Import data available. |
| `llm-d-latency-predictor` | 4 | `integration_points`, `internal_dependencies` | Auth resolved (absence-of-auth). Import data available. |
| `codeflare-sdk` | 3 | `authentication`, `internal_dependencies` | 7 used deps (ray, kubernetes confirmed). Import data available. |
| `MLServer` | 8 | `authentication`, `integration_points`, `internal_dependencies` | gRPC resolved (+2 facts). Import data available. |
| `caikit` | 8 | `authentication`, `integration_points`, `internal_dependencies` | gRPC resolved (+3 facts). Import data available. |

### Out of scope

These components have structural gaps that category coverage wiring cannot fix:

| Component | Reason |
|-----------|--------|
| `kubeflow-sdk` | Uses `setup.py`, import analysis returns `no_dependencies_found` |
| `rhoai-mcp` | MCP handler extraction gap (not a category coverage issue) |
| `llm-d-routing-sidecar` | Unresolved kustomize template variables |
| `lm-evaluation-harness` | No auth pattern exists; bounded correction gaps |
| `kube-auth-proxy` | Go component, not Python |
| `llm-d-async` | Authentication gap in Python+Go hybrid (not import-related) |
| `llm-d-kv-cache` | Python gRPC registration (not import-related) |

## Extraction Contracts

### 1. Python import-to-InternalDependency conversion

For `ImportAnalysis.Used` packages that correspond to known platform
components, generate `InternalDependency` facts. The mapping should cover
at minimum:

| Python package | Platform component |
|---------------|-------------------|
| `kubernetes` | Kubernetes API |
| `ray` | Ray |
| `kserve` | KServe |
| `caikit` / `caikit_runtime` | Caikit Runtime |
| `grpcio` | gRPC framework (only when gRPC services registered) |

The mapping should be conservative — only packages that represent genuine
platform integration relationships, not utility libraries.

### 2. Python import-to-IntegrationFact conversion

For `ImportAnalysis.Used` packages that represent external service SDKs,
generate `IntegrationFact` entries:

| Python package | Integration target |
|---------------|-------------------|
| `openai` | OpenAI API |
| `boto3` / `botocore` | AWS |
| `azure-*` | Azure services |
| `google-cloud-*` | Google Cloud |

### 3. Python ExternalConnection-to-IntegrationFact wiring

Ensure Python `ExternalConnections` (already flowing into `input.ExternalConnections`
via `extractor.go:143`) are converted to `IntegrationFact` entries in
`platformfacts.go`, following the same pattern as `runtimeClientIntegrationFacts()`.

### 4. Source-audited empty categories

For target components where a category is provably empty after the wiring
changes (e.g., `authentication` for components with no inbound surfaces and
no auth constructs), add `source_audited_empty_categories` entries to
`lib/analyzer_correction_adjudications.json`.

## Implementation Approach

The cleanest integration point is to either:

A. Add `InternalDependency` and `IntegrationFact` fields to
   `pythonsource.Result`, generate facts in `pythonsource`, and merge them
   in `extractor.go` alongside existing fields.

B. Carry `ImportAnalysis` on `model.Input` and consume it in
   `platformfacts.go` (which already has the dependency/integration
   conversion pattern).

C. Do the conversion in `extractor.go` after Python extraction but before
   `platformfacts.Extract()`.

Choose whichever approach is most consistent with the existing codebase
patterns. The key constraint is that the facts must be present on
`model.Input` before `categoryCoverage()` runs at `extractor.go:172`.

## Negative Controls

- Must not generate `InternalDependency` facts for test-only or unused imports.
- Must not generate facts for utility libraries that don't represent platform
  integration (e.g., `numpy`, `pandas`, `pydantic`).
- Must not accept `DeclaredUnused` packages as evidence of runtime integration.
- Must not generate duplicate facts when `platformfacts.go` already produces
  the same relationship from another signal (e.g., RBAC, controller watches).
- Must not break existing category coverage completions for the 46 approved
  components.

## Acceptance Criteria

- [ ] `ImportAnalysis.Used` packages that map to platform components generate
  `InternalDependency` facts.
- [ ] `ImportAnalysis.Used` packages that map to external SDKs generate
  `IntegrationFact` entries.
- [ ] Python `ExternalConnections` are accounted in `integrationPointsCoverage`.
- [ ] Unit tests for the package-to-dependency and package-to-integration
  mappings with positive and negative cases.
- [ ] Preserve all existing tests.
- [ ] Run `go test ./...` and `go vet ./...` in `src/arch-analyzer`.
- [ ] Run Ruff and the Python suite for affected routing/rendering behavior.
- [ ] Run a fresh 90-component replay with zero false nominations.
- [ ] Add approval and source-audited entries only after the fresh replay
  proves eligibility.
- [ ] Run a bounded one-component production matrix if approval changes routing.
- [ ] Write a validation note, update the residual register, and move this
  task to `docs/tasks/done/`.

## Likely Files

- `src/arch-analyzer/internal/pythonsource/pythonsource.go` (add fact generation)
- `src/arch-analyzer/internal/pythonsource/imports.go` (package-to-platform mapping)
- `src/arch-analyzer/internal/extractor/extractor.go` (merge new fact fields)
- `src/arch-analyzer/internal/extractor/categorycoverage.go` (verify wiring resolves limitations)
- `src/arch-analyzer/internal/platformfacts/platformfacts.go` (ExternalConnection conversion)
- `lib/analyzer_correction_adjudications.json` (source-audited empty categories)
- `lib/analyzer_only_approvals.json` (new approvals)
- `docs/notes/analyzer-residual-agent-gaps.md` (update residual register)

## Status

Done. See [validation note](../notes/python-import-category-wiring-validation-2026-07-21.md).
