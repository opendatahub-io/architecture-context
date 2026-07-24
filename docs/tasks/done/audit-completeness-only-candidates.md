# Task: Audit Completeness-Only Candidates

## Goal

Determine whether `guardrails-regex-detector`, `model-registry`, and `ogx` have
legitimately empty blocking categories, missed source-backed facts, or unsupported
behavior that must remain partial.

## Context

These are the three completeness-only candidates from the post-`odh-cli`
classification. They have no unresolved accepted mutations, but absence of
historical corrections is not proof of category completeness.

Authoritative replay:
`tmp/architecture-corpus-runs/rhoai-next-cli-kubernetes-static-20260719T180727Z`

Read first:

- `docs/goals/analyzer-ownership-expansion.md`
- `docs/notes/analyzer-remaining-candidate-prioritization-2026-07-19.md`
- `docs/notes/analyzer-residual-agent-gaps.md`
- `docs/plans/analyzer-category-completeness.md`

## Audit Matrix

| Component | Revision | Blocking categories | Current warning |
|-----------|----------|---------------------|-----------------|
| `guardrails-regex-detector` | `5c6116749e66a3496f7a5ac7427219f294df7ec3` | Integration Points | Do not infer runtime integrations from Rust crate dependencies. |
| `model-registry` | `62733189ea906eeb88e955052c9b5da10405115a` | Internal Dependencies | Nine active platform aliases, partial Kustomize resolution, and unsupported runtime languages remain unclassified. |
| `ogx` | `5d65c017b088eab0f40c88fc92e7b4aac9834a27` | Authentication, Internal Dependencies | Dynamic Python auth, nine credential references, and unsupported shell/C-family surfaces remain unresolved. |

Checkouts are under `/data/checkouts/red-hat-data-services.next/<component>` and are
intentionally dirty. Do not reset them. Use the replay's `run.json`,
`analyzer/rhoai.next/<component>.json`, and `logs/agents/<component>.merge.json` as
the snapshot authority.

## Required Decisions

For every blocking category, record exactly one outcome:

1. Complete-empty under an existing bounded discovery contract.
2. A missed source-backed fact requiring generic extraction.
3. Partial because unsupported or dynamic behavior prevents an absence claim.
4. A new generic completeness contract or focused extractor task is required.

It is acceptable for the audit to approve zero components. Do not weaken coverage
contracts to force routing expansion.

## Safety Requirements

- Do not add component-name exceptions.
- Do not mark Integration Points complete from dependency absence or keyword scans.
- Do not treat module dependencies, imports, credential names, tests, samples,
  comments, or unselected manifests as runtime relationships.
- Do not mark `model-registry` complete while active aliases or Kustomize limitations
  remain unclassified.
- Do not mark `ogx` complete while dynamic Python authentication or shipped
  unsupported source remains unresolved.
- Treat historical agent output as a regression fixture, not ground truth.

## Deliverables

- Create `docs/notes/completeness-only-candidate-audit-2026-07-19.md`.
- Record exact revisions, shipped entrypoints, searched runtime surfaces, negative
  controls, every current limitation, discovered facts, and the final decision for
  each category.
- Implement analyzer changes only when the audit establishes a bounded,
  repository-independent contract.
- Create focused pending tasks for extractor gaps that are not implemented here.
- Update the residual register, goal, and `PLAN.md`.

## Validation

If analyzer behavior changes:

- Run `go test ./...` and `go vet ./...` in `src/arch-analyzer`.
- Run Ruff and affected Python routing/rendering tests.
- Run a fresh 90-component static replay.
- Require zero false nominations, no unexplained analyzer conflicts or missing rows,
  and 90/90 structural and synthesis gates.
- Add approval only for components proven eligible by the replay.
- Run a bounded production matrix for every newly approved component.

## Acceptance Criteria

- [x] All blocking categories for all three components have source-backed decisions.
- [x] Every analyzer limitation is resolved, retained, or converted into a focused
  task with exact evidence.
- [x] No category is marked complete solely because its table is empty.
- [x] Any analyzer changes are generic and covered by positive and negative tests.
  (N/A — no analyzer changes made.)
- [x] All applicable static replay and production gates pass.
  (N/A — no analyzer changes, no replay needed.)
- [x] The audit note and ledger documents are reconciled.
- [x] This task is moved to `docs/tasks/done/` only after all applicable criteria
  pass.

## Status

Complete. See [audit note](../notes/completeness-only-candidate-audit-2026-07-19.md).
Zero routing expansion. Three focused tasks created for the identified gaps.
