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

## Status

Fixed on 2026-07-28 by
`docs/tasks/done/fix-partial-route-oversized-source-reads.md`.

The source-read validator now emits oversized-read details and gap-category
counts in the per-component run-report validation result. Oversized records
missing `scope_reason` are categorized as
`oversized-read-missing-scope-reason` and no longer count as justified reads.
The repo-to-architecture-summary skill now instructs agents to prefer exact
symbols, functions, handlers, and manifest snippets over whole files.

The agent guard now enforces the behavior for future partial-route runs:
source files larger than 400 lines require an explicit `offset`/`limit`, and
`limit` must be at most 400. Bounded source reads remain allowed.

Validation passed:

```bash
uv run ruff check lib/agent_runner.py lib/source_read_justifications.py tests/test_agent_runner.py tests/test_source_read_justifications.py
uv run pytest -q tests/test_agent_runner.py tests/test_source_read_justifications.py
uv run pytest -q tests/test_architecture_phase.py
uv run pytest -q tests/test_agent_runner.py tests/test_source_read_justifications.py tests/test_architecture_phase.py
```

Read-only replay over the historical 97-component run still reports the old
baseline of 64 oversized reads across 49 components, including 2 missing
`scope_reason`. Those generated historical artifacts were not rewritten. The
fix is enforced for the next generation run.
