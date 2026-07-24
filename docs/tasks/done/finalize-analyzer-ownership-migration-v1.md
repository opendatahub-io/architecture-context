# Task: Finalize Analyzer Ownership Migration V1

## Goal

Close the active analyzer-ownership goal by proving that every analyzer-sufficient
component is either safely analyzer-only or has a source-backed, explicitly named
agent residual, then validate the final routing policy in production and reduce the
component-summary skill to those residual responsibilities.

This is an audit and release task. Do not implement unrelated extractors inside it.
If the audit finds another reusable, supported extraction opportunity with a
reasonable chance of removing an agent invocation, create a focused pending task
and leave this closeout task open.

## Bounded Start

Do not begin with broad repository exploration or research subagents. Start from:

- Static authority:
  `tmp/architecture-corpus-runs/rhoai.next-20260720T173035Z-static`
- Machine classification: `reports/eligibility.json` under that run.
- Last paid production run:
  `tmp/architecture-corpus-runs/rhoai.next-20260720T103625Z-3372001`
- Residual register: `docs/notes/analyzer-residual-agent-gaps.md`
- Prioritization:
  `docs/notes/analyzer-remaining-candidate-prioritization-2026-07-19.md`
- Approval and adjudication registries:
  `lib/analyzer_only_approvals.json` and
  `lib/analyzer_correction_adjudications.json`
- Current skill: `.claude/skills/repo-to-architecture-summary/SKILL.md`
- Completed validation notes linked from `PLAN.md` and the ownership goal.

The current measured state is 90 components, 64 analyzer-sufficient, 36 approved
analyzer-only, 27 false deterministic candidates, one deliberate prose residual,
124 unresolved post-adjudication row identities, and zero false nominations.

## Work

### 1. Reconcile The Residual Inventory

- Account for all 64 analyzer-sufficient components exactly once as approved
  analyzer-only, deterministic candidate, or deliberate residual.
- For every non-approved component, replace category-only blockers with the exact
  unsupported behavior and source evidence. Reuse existing merge reports and
  validation notes before reading a checkout.
- Distinguish source-derived analyzer rows that fail historical identity matching
  from genuinely missing behavior.
- Verify that all invalid example, demo, benchmark, test, documentation,
  dependency-only, and proto-only claims have explicit adjudications.
- Retain conservative limitations for unsupported languages, dynamic dispatch,
  caller identity, image inventories, and prose-only platform semantics.

### 2. Audit Closeout Candidates

Review the four zero-correction or analyzer-only-candidate boundaries explicitly:

| Component | Current state | Required decision |
|-----------|---------------|-------------------|
| `llm-d-batch-gateway-operator` | Analyzer-only candidate, not approved | Source-audit current completeness and approve only through bounded validation. |
| `rhods-operator` | Analyzer-only candidate, deliberate prose residual | Preserve or revise the documented prose-residual decision. |
| `lm-evaluation-harness` | Zero unresolved rows, incomplete categories | Name the unsupported behavior or create focused extractor work. |
| `ogx` | Authentication resolved, Internal Dependencies incomplete | Confirm the shell/Swift limitation remains an agent-relevant blocker. |

Do not approve a component from zero corrections or populated tables alone.

### 3. Decide Whether Extractor Work Is Exhausted

- Review the remaining 124 identities by recurring evidence pattern, frequency,
  expected avoided agent cost, supported source surface, and false-positive risk.
- Create a focused task for any reusable tranche that still has a reasonable path
  to eliminating an invocation. Include exact evidence, implementation map,
  reproducer, tests, and negative controls so the next agent does not rediscover the
  codebase.
- Record source-backed residuals or explicit no-action decisions for the rest.
- Do not use this task to increase approval count as an end in itself.

### 4. Validate Final Routing

- Run a bounded production matrix for every newly approved component.
- After the approval and residual policy is stable, run one final paid 90-component
  production workflow using `scripts/run_rhoai_next_architecture.sh`.
- Require zero false nominations, complete analyzer-row preservation, zero
  unexplained populated-cell conflicts or missing rows, and all structural and
  synthesis-quality gates.
- Record route counts, agent invocations, wall time, cost, tools, reads, source
  files, tokens, revisions, and comparison artifacts against the accepted baseline.

### 5. Reduce The Skill And Close The Goal

- Audit the component-summary skill against the final routing policy.
- For sufficient and partial analyzer baselines, retain only bounded synthesis and
  the exact residual gap responsibilities. Do not ask agents to rediscover
  analyzer-owned structured facts.
- Preserve the legacy fallback for absent or insufficient analyzer baselines.
- Update routing, prompt, merge, validation, and skill tests for the final contract.
- Write the migration-v1 validation note and completion milestone, mark
  `docs/goals/analyzer-ownership-expansion.md` complete, reconcile `PLAN.md` and the
  residual register, and make the post-migration baseline-capture task the next
  work item.

## Acceptance Criteria

- [x] All 64 analyzer-sufficient components have exactly one final disposition.
- [x] Every agent-owned disposition names exact unsupported behavior and source
  evidence; category names alone are insufficient.
- [x] Every remaining reasonable reusable extractor opportunity has a focused task,
  or the audit records why no such opportunity remains.
- [x] All final approvals pass source audit, static replay, and bounded production
  validation without component-specific analyzer exceptions.
- [x] The final paid 90-component run passes preservation, conflict, structure,
  synthesis, and false-nomination gates and records complete execution telemetry.
- [x] The skill prohibits rediscovery of analyzer-owned facts on sufficient/partial
  routes while preserving bounded residual and legacy behavior.
- [x] A permanent v1 completion note and milestone identify the final run, routing
  policy, approved set, residual set, performance, and known limitations.
- [x] The ownership goal is marked complete only after every criterion above passes.
- [x] This task moves to `docs/tasks/done/`; the next task is
  `capture-analyzer-migration-v1-baseline.md`.

## Likely Files

- `docs/notes/analyzer-residual-agent-gaps.md`
- `docs/goals/analyzer-ownership-expansion.md`
- `docs/milestones/`
- `lib/analyzer_only_approvals.json`
- `lib/analyzer_correction_adjudications.json`
- `.claude/skills/repo-to-architecture-summary/SKILL.md`
- `.claude/skills/repo-to-architecture-summary/scripts/validate_architecture.py`
- `lib/architecture_routing.py`
- `tests/test_architecture_routing.py`
- `tests/test_analyzer_only_eligibility.py`

## Status

Done on 2026-07-20. See
[Analyzer ownership migration v1 milestone](../../milestones/analyzer-ownership-migration-v1.md).

