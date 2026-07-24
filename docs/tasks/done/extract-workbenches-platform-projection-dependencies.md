# Task: Extract Workbenches Platform Projection Dependencies

## Goal

Convert the remaining source-backed `workbenches-operator` Internal Platform
Dependencies into generic analyzer facts and determine whether the component can be
approved for analyzer-only generation.

## Context

The analyzer resolves 3/6 accepted corrections. The remaining three rows are all
described by the selected Workbenches CRD schema: the platform orchestrator projects
`gatewayDomain`, `mlflowEnabled`, and `platform`; the first comes from
`GatewayConfig`, and the second from DSC `MLflowOperator` state.

The current dependency absence scan also finds a
`schema.GroupVersionKind{Group: "kubeflow.org", Kind: "Notebook"}` construction in
`internal/gvk/gvk.go`. Repository-wide usage inspection shows that the package-level
value is never referenced. It is a negative control that must be classified as an
unused declaration rather than converted into a runtime dependency.

## Acceptance Criteria

- [x] Parse selected CRD OpenAPI property descriptions through structured YAML nodes,
  retaining field and source-line evidence.
- [x] Emit a platform-orchestrator projection dependency only for explicit language
  that the field is projected by an orchestrator; ordinary descriptive prose is a
  negative control.
- [x] Normalize explicit `GatewayConfig` and DSC component-state projection sources
  without tying extraction to the Workbenches component name.
- [x] Keep literal Go `schema.GroupVersionKind` references blocking when their values
  are used by reconciliation or dependency configuration; declarations that are
  unused, test-only, generated, self-owned, or generic Kubernetes APIs are negative
  controls.
- [x] Classify the unused `kubeflow.org/v1 Notebook` declaration without emitting a
  runtime dependency row.
- [x] Resolve or source-adjudicate all 3/3 remaining accepted dependency corrections.
- [x] Do not add a component-name exception, broad substring rule, or infer a
  relationship from an import alone.
- [x] A 90-component replay has zero false approved nominations and passes all
  preservation, structural, and synthesis gates.
- [x] Run a bounded production-path matrix only if routing changes.

## Files Likely Involved

- `src/arch-analyzer/internal/extractor/crds.go`
- `src/arch-analyzer/internal/gosource/`
- `src/arch-analyzer/internal/model/input.go`
- `src/arch-analyzer/internal/platformfacts/platformfacts.go`
- `lib/analyzer_only_approvals.json`

## Status

Done

## Baseline Evidence

- Latest replay:
  `tmp/architecture-corpus-runs/rhoai-next-mcp-dependencies-static-20260719T131146Z`
- Workbenches checkout: `4d6ed9766aea812224a91d91c7a563ffa4da61bd`.
- Historical agent cost: $0.7943, 201.40 seconds, 7 reads, 4 source files,
  and 9,475 output tokens.

## Validation

- Full static replay:
  `tmp/architecture-corpus-runs/rhoai-next-workbenches-projections-static-20260719T133450Z`
- Production-path matrix:
  `tmp/architecture-corpus-runs/rhoai-next-workbenches-projections-matrix-20260719T134000Z`
- Workbenches resolves or source-adjudicates 6/6 corrections and becomes the 27th
  approved analyzer-only component with zero false nominations.
- The bounded matrix invokes zero agents and retains 50/50 analyzer identities.
- Full details are in
  `docs/notes/workbenches-platform-projection-dependencies-validation-2026-07-19.md`.
