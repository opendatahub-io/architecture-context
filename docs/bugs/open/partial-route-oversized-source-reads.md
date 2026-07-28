# Bug: Partial Route Still Performs Oversized Source Reads

## Summary

The latest 97-component `rhoai.next` generation run used the partial route for
all components, but oversized source reads remain common. The source-read
justification summaries reported 64 oversized reads across 49 components.

## Evidence

Components with oversized reads included:

- `training-hub` and `training_hub`: 3 each
- `caikit-nlp`, `caikit`, `codeflare-operator`, `kube-auth-proxy`,
  `kube-rbac-proxy`, `kubeflow-sdk`, `ml-metadata`,
  `model-metadata-collection`, `odh-cli`, `openvino_model_server`,
  `training-operator`: 2 each
- Many additional components with 1 oversized read

Several oversized records had no `scope_reason`, including `kube-rbac-proxy`
and `model-metadata-collection`.

## Expected

Partial-route synthesis should use bounded, section-level reads where possible.
When a larger read is necessary, the ledger should include an explicit
`scope_reason` explaining why narrower evidence was insufficient.

## Actual

Agents still read large source ranges or whole files frequently, and some
oversized reads are not justified.

## Impact

Medium to high. Oversized reads consume context, increase runtime, and weaken
the evidence that arch-analyzer is reducing agent source inspection.

## Acceptance Criteria

- Oversized read detection is visible in run summaries and grouped by component
  and gap category.
- The repo-to-architecture-summary skill instructs agents to prefer exact
  symbols, functions, or manifest snippets over whole files.
- The orchestrator or ledger validator requires `scope_reason` for oversized
  reads.
- Analyzer follow-up work mines repeated oversized read targets and adds
  compact evidence fields where feasible.
- A replay shows a measurable decline in oversized reads or all remaining
  oversized reads have explicit scope reasons.
