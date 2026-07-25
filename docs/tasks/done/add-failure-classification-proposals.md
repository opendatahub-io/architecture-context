# Task: Add Failure-Classification Proposals

## Goal

Create a deterministic, reviewable explanation pipeline for analyzer-assisted
evaluation failures without silently classifying or rewriting result records.

## Context

`docs/plans/analyzer-assisted-agent-architecture.md` requires root-cause
categories such as stale context, missing context, retrieval failure, and
unsupported inference before rollout evaluation. The result schema already
records explicit context signals and an authoritative classification field, but
there is no proposal artifact or conservative classifier.

## Scope and controls

- Read `AGENTS.md`, `PLAN.md`, `agent-driver.md`, the architecture plan,
  `benchmark/analyzer-assisted-v1/experiment.json`, `result_schema.json`,
  `validate.py`, and `lib/context_telemetry.py`.
- Add a deterministic CLI/module and versioned proposal schema that consumes
  validated raw/scored result records and emits pending proposals with exact
  result/question/condition evidence and reasoning.
- Propose only directly evidenced causes: infrastructure failure from an
  explicit unsuccessful response/error, or stale/missing/unsupported signals
  from explicit telemetry; preserve recorded classifications as annotations.
  Do not infer retrieval failure or scoring defects from a score alone.
- Do not modify raw/scored results, authoritative schema semantics, corpus,
  generated architecture docs, overlays, or run any evaluation/benchmark.
  Do not commit.

## Acceptance criteria

- [x] Output is deterministic, schema-validated, review-status `pending`, and
  never overwrites input results or promotes proposals automatically.
- [x] Direct evidence, source record identity, proposed category (or explicit
  unresolved state), reasoning, and suggested adjudication action are present.
- [x] Negative tests prove ambiguous failures remain unresolved rather than
  becoming retrieval/scoring claims; malformed inputs fail explicitly.
- [x] Focused tests, validators, and `git diff --check` pass; documentation
  distinguishes proposals from authoritative classifications and execution
  blockers remain explicit.

## Implementation

Added `lib/failure_proposals.py` and
`benchmark/analyzer-assisted-v1/proposal_schema.json` (both version 1.0.0),
plus 41 focused tests. The generator emits only `pending` proposals. It maps
explicit unsuccessful responses to `infrastructure-failure`, explicit
stale/missing/unsupported telemetry signals to their corresponding categories,
and all score-only or otherwise ambiguous cases to `unresolved`. Existing
recorded classifications remain evidence annotations and are never promoted.
Generated timestamps are deterministic: the latest input result timestamp is
used, or `1970-01-01T00:00:00+00:00` is used as an explicit no-timestamp
sentinel.

## Validation

- `python3 -m pytest tests/test_failure_proposals.py` — 41 passed in the task
  container.
- `python3 benchmark/analyzer-assisted-v1/validate.py` — PASS, all four
  conditions available and six failure classifications.
- Proposal output schema validation — PASS for derived and epoch timestamps.
- `git diff --check` — PASS.
- No evaluation, benchmark, corpus/result, or authoritative classification was
  changed. Delegated runs cost `$4.5559225` total.

## Status

Validated. Human adjudication is still required before any proposal can become
an authoritative failure classification; retrieval-failure and scoring-defect
remain unresolved unless directly adjudicated.
