# Task: Audit rhods-operator Analyzer-Only Candidate

## Goal

Determine whether `rhods-operator` can safely use analyzer-only component
generation by accounting for its platform-orchestration dependencies, or retain an
exact source-backed residual reason requiring an agent.

## Context

Dynamic GVK extraction and the generic OpenShift `APIServer` mapping made
`rhods-operator` a semantic analyzer-only candidate. It remains deliberately
unapproved. A single populated dependency row satisfies the current routing policy,
but the repository owns DataScienceCluster and service orchestration across many
RHOAI components; one row does not establish category completeness.

The analyzer also sees a dynamic `GatewayConfig` get/patch operation. The audit must
separate self-owned API surfaces from actual runtime dependencies and identify the
generic source or manifest relationships that prove component orchestration.

## Acceptance Criteria

- [x] Inventory the accepted document's Internal Platform Dependencies and relevant
  orchestration prose against current controller, handler, template, and selected
  manifest evidence.
- [x] Classify dynamic `GatewayConfig`, DataScienceCluster/component APIs, embedded
  manifests, and child-resource reconciliation as self-owned surfaces or external
  runtime dependencies with explicit reasons.
- [x] Convert reusable relationships into repository-independent extraction or
  normalization; do not add a `rhods-operator` name exception.
- [x] Self API groups, RBAC, imports, CRD descriptions, and embedded assets without
  an executed reconciliation path are negative controls.
- [x] Approve analyzer-only routing only if all supported high-value structured
  surfaces are accounted for; otherwise record the exact unsupported behavior in
  the residual register.
- [x] Other semantic candidates remain blocked by rollout approval.
- [x] A 90-component replay has zero false approved nominations and passes all
  preservation, structural, and synthesis gates.
- [x] Run a bounded production-path matrix only if `rhods-operator` receives rollout
  approval.

## Files Likely Involved

- `src/arch-analyzer/internal/gosource/`
- `src/arch-analyzer/internal/platformfacts/platformfacts.go`
- `src/arch-analyzer/internal/extractor/`
- `lib/analyzer_only_approvals.json`

## Status

Complete

## Validation

See [rhods-operator analyzer-only candidate audit](../../notes/rhods-operator-analyzer-only-candidate-audit-2026-07-19.md).

## Baseline Evidence

- Latest replay:
  `tmp/architecture-corpus-runs/rhoai-next-dynamic-gvk-static-20260719T054834Z`
- Historical agent cost: $1.0241, 190.82 seconds, 8 reads, 4 source files,
  8,788 output tokens.
