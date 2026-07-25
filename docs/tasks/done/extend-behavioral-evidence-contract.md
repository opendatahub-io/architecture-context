# Task: Extend Behavioral Evidence Contract Fields

## Goal

Complete the missing Phase 1 context-contract fields identified by the local
Step 2 audit in `docs/tasks/done/audit-local-plan-implementation-gaps.md`.

## Scope and controls

- Extend the Go context-contract model, JSON Schema, normalizer/renderer, and
  focused tests for configuration/RBAC/deployment ordering, architecture and
  provider matrices, observable outcomes, image/build status, and
  delivery-independence or primary/peripheral hints.
- Preserve optional-field backward compatibility and explicit validation states;
  do not invent or populate evidence that extraction does not provide.
- Do not modify generated architecture output, corpus/raw/scored results,
  production dependencies, Dockerfile, or MLflow; do not run models/evaluations.

## Acceptance criteria

- Each category has a named structured field, schema definition, renderer
  support, and round-trip/unknown-state regression coverage.
- Existing contract fixtures remain compatible; focused Go tests and
  `git diff --check` pass.
- Update this task, `PLAN.md`, and session ledger; do not commit.

## Changes made

| File | Change |
|------|--------|
| `src/arch-analyzer/internal/model/contract.go` | Added `ConfigurationRBAC`, `ArchProviderMatrices`, `ObservableOutcomes`, `ImageBuildStatus` fields to `ContractBehavioralEvidence`; added `ContractComponentClassification` struct and `ComponentClassification` field on `ContextContract` |
| `src/arch-analyzer/schema/component-architecture.schema.json` | Added `configuration_rbac`, `arch_provider_matrices`, `observable_outcomes`, `image_build_status` to `contractBehavioralEvidence`; added `contractComponentClassification` definition and reference in `contextContract` |
| `src/arch-analyzer/internal/renderer/contract.go` | Added rendering for new behavioral evidence fields and Component Classification section |
| `src/arch-analyzer/internal/model/contract_test.go` | Extended round-trip test with new fields; added `TestBehavioralEvidenceNewFieldsRoundTrip`, `TestBehavioralEvidenceNewFieldsOmittedWhenEmpty`, `TestComponentClassificationRoundTrip`, `TestComponentClassificationUnknownStateRoundTrip`; extended explicit-unknowns and omits-empty tests |
| `src/arch-analyzer/internal/renderer/contract_test.go` | Added `TestMarkdownRendersBehavioralEvidenceNewFields`, `TestMarkdownRendersComponentClassification`, `TestMarkdownRendersComponentClassificationNotExtracted`, `TestMarkdownOmitsComponentClassificationWhenNil`, `TestMarkdownOmitsNewBehavioralFieldsWhenEmpty` |
| `src/arch-analyzer/internal/normalize/normalize_test.go` | Added `TestInputPassesThroughNewContractFields` |

## New field names

| Category | Go field | JSON key | Location |
|----------|----------|----------|----------|
| Configuration/RBAC/deployment ordering | `ConfigurationRBAC` | `configuration_rbac` | `ContractBehavioralEvidence` |
| Architecture/provider matrices | `ArchProviderMatrices` | `arch_provider_matrices` | `ContractBehavioralEvidence` |
| Observable outcomes | `ObservableOutcomes` | `observable_outcomes` | `ContractBehavioralEvidence` |
| Image/build status | `ImageBuildStatus` | `image_build_status` | `ContractBehavioralEvidence` |
| Delivery-independence/primary-peripheral | `ComponentClassification` | `component_classification` | `ContextContract` (top-level) |

## Validation

- 13 model contract tests: PASS (including 4 new)
- 12 renderer contract tests: PASS (including 5 new)
- 3 normalize contract tests: PASS (including 1 new)
- All arch-analyzer `go test ./...`: PASS (13 packages)
- All arch-query `go test ./...`: PASS (5 packages)
- `git diff --check`: PASS
- No model called, no evaluation ran, no generated output modified
- Backward compatibility preserved: absent contract, empty fields, existing fixtures unchanged
- Delegated implementation-agent cost: $2.62606025; no application model,
  paid benchmark, or evaluation call was made.

## Status

Accepted after independent driver review — 2026-07-25. `gofmt -d` is clean,
all `go test ./...` checks pass in both Go modules, and `git diff --check`
passes. The five fields remain optional and are not populated without
extraction evidence.
