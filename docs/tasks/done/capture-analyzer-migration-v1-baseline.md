# Task: Capture Analyzer Migration V1 Baseline

## Goal

Create a durable, reproducible record of the completed analyzer migration and run a
small consumer smoke test before using it as the candidate in a broader evaluation.

## Prerequisite

Do not claim this task until
[Analyzer Ownership Expansion](../../goals/analyzer-ownership-expansion.md) meets
all completion criteria, including its final replay, production run, residual
register, and skill reduction.

## Work

- Record the repository commit, analyzer version, final production run, source
  revisions, routing policy, approvals, adjudications, and residual-agent policy.
- Record hashes or another reproducible manifest for the collected component
  Markdown, `PLATFORM.md`, overlays, and relevant configuration. Do not rely only
  on an untracked `tmp/` directory.
- Preserve the accepted historical agent baseline identifier and comparison inputs.
- Record component count, analyzer-only count, agent count, wall time, cost, tools,
  reads, source files, and token usage.
- Manually exercise 10-15 representative inventory, component-fact,
  integration/data-flow, and security questions against the v1 output. Include
  overlay precedence and honest handling of an undocumented fact.

## Acceptance Criteria

- [x] A permanent validation note identifies every artifact needed to reproduce the
  v1 output and routing decision.
- [x] The recorded artifact manifest can detect later document or configuration
  drift.
- [x] The smoke test contains expected answers and source citations, not subjective
  prose comparisons.
- [x] No catastrophic consumer regression remains unexplained before the baseline is
  frozen.
- [x] The task is moved to `docs/tasks/done/` and the follow-on plan is updated.

## Status

Done on 2026-07-20. See
[Analyzer migration v1 baseline](../../notes/analyzer-migration-v1-baseline-2026-07-20.md).

