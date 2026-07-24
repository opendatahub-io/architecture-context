# Task: Audit MCP Lifecycle Internal Dependency Completeness

## Goal

Determine whether `mcp-lifecycle-operator` can receive a source-backed
complete-empty Internal Platform Dependencies contract and analyzer-only approval,
or retain an exact residual dependency-analysis gap.

## Context

All 3/3 accepted structured corrections are now analyzer-owned or source-adjudicated.
The remaining routing blocker is an empty Internal Platform Dependencies category
whose absence contract is partial.

Current limitations include unresolved Kustomize image transforms, platform aliases
found in commented cert-manager scaffolding, and unsupported shell files under
`.devcontainer` and `hack/mkdocs`. The accepted synthesis describes the operator as
standalone, but that statement is a discovery lead rather than proof.

## Acceptance Criteria

- [x] Inventory every platform-alias match reported by the dependency absence
  contract and classify it as an executed runtime relationship, selected manifest
  relationship, self-owned API, comment, test fixture, documentation, or build tool.
- [x] Commented Kustomize resources and patches do not count as selected runtime
  dependency evidence.
- [x] Non-runtime support scripts are excluded through generic path/role
  classification without hiding deployment, entrypoint, hook, or operator scripts.
- [x] Kustomize limitations block complete-empty only when the unsupported transform
  can change dependency-bearing resource selection or relationships.
- [x] Self-owned `mcp.x-k8s.io` APIs, generic Kubernetes APIs, optional unselected
  cert-manager scaffolding, and dependency imports alone are negative controls.
- [x] Do not add a component-name exception or infer absence from the historical
  agent statement.
- [x] Approve analyzer-only routing only if the category contract becomes complete
  and all high-value categories remain populated or complete-empty.
- [x] A 90-component replay has zero false approved nominations and passes all
  preservation, structural, and synthesis gates.
- [x] Run a bounded production-path matrix only if routing changes.

## Files Likely Involved

- `src/arch-analyzer/internal/extractor/categorycoverage.go`
- `src/arch-analyzer/internal/extractor/categorycoverage_test.go`
- `src/arch-analyzer/internal/extractor/loader.go`
- `lib/analyzer_only_approvals.json`

## Status

Done

## Baseline Evidence

- Latest replay:
  `tmp/architecture-corpus-runs/rhoai-next-controller-metrics-static-20260719T061600Z`
- Historical agent cost: $0.8373, 186.06 seconds, 9 reads, 4 source files,
  and 8,245 output tokens.

## Validation

- Full static replay:
  `tmp/architecture-corpus-runs/rhoai-next-mcp-dependencies-static-20260719T131146Z`
- Production-path matrix:
  `tmp/architecture-corpus-runs/rhoai-next-mcp-dependencies-matrix-20260719T132000Z`
- The complete-empty contract classifies the only alias as commented cert-manager
  scaffolding and excludes support-only documentation/development scripts.
- The full replay approves 26 components with zero false nominations and passes all
  90-component gates.
- The bounded matrix invokes zero agents and retains 80/80 analyzer identities.
- Full details are in
  `docs/notes/mcp-lifecycle-internal-dependency-completeness-validation-2026-07-19.md`.
