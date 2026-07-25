# Task: Reconcile Deterministic V1 Scoring Accuracy

## Goal

Improve the deterministic consumer-v1 scorer and its ground-truth variants so
the existing raw results distinguish phrasing variance from actual failures.
This is a local, non-paid evaluation prerequisite for the analyzer-assisted
architecture plan.

## Scope

- Inspect `benchmark/consumer-v1/score_results.py`,
  `benchmark/consumer-v1/generate_report.py`, the current corpus, and the
  existing `results/v1-ab/raw-results.json` and scored artifacts.
- Preserve the 31-question current corpus and its explicit below-contract
  status; do not invent or restore questions in this task.
- Make deterministic matching case-insensitive and review only variant entries
  supported by the existing raw responses and source-backed ground truth.
- Fix source-citation regression reporting if the existing implementation
  misses a demonstrable A-pass/B-fail case.
- Add focused tests for every changed behavior, including negative controls.

## Explicit exclusions

- Do not add an LLM judge, invoke Claude for scoring, run a paid benchmark, or
  change production dependencies.
- Do not modify architecture documents, retired-question manifests, or the
  stale pending task `improve-corpus-v1-scoring-accuracy.md`.
- Do not weaken corpus validation or claim the 40-question contract is met.

## Acceptance criteria

- Existing raw results can be rescored reproducibly with the updated code.
- No question that passed deterministic exact match before the change regresses.
- Every added variant has evidence in an existing response and corresponds to
  the same source-backed answer; unsupported variants are not added.
- Source-citation regression detection has a focused failing-before/passing-
  after test, or the task records evidence that the suspected defect is absent.
- Focused tests, `git diff --check`, and the applicable validators pass.
- Report the exact commands, resulting rates, changed files, and any
  pre-existing validation errors. Do not commit.

## Review evidence

The driver must independently inspect the diff, test assertions, corpus
changes, rescored output, and validation output before moving this task to
`docs/tasks/done/`.

### Driver review (2026-07-25)

- Container run: `scripts/run_claude_container.sh --prompt-file tmp/claude-task-prompt.md`
- Stable log: `/tmp/claude-task-runs/agent-driver.jsonl`
- Reported cost: `$5.15027225`; no paid benchmark was run.
- Container validation: 28 focused tests passed; analyzer-assisted validator
  passed; consumer-v1 validator retained its four pre-existing 31/40 errors;
  `git diff --check` passed.
- Independent rescoring to `/tmp/scored-v1-reconciled.json`: 31 questions,
  Tree A exact match 15/31 (48.39%), Tree B 14/31 (45.16%), composite scores
  0.6237 and 0.5753. Comparing shared IDs with the prior scored artifact found
  no exact-match regressions.
- Reviewed and rejected the agent's unrelated change to
  `docs/notes/analyzer-assisted-evaluation-contract.md`; that file remains
  unchanged. No Dockerfile change was needed.
- Accepted files are limited to the scorer, report generator, corpus variants,
  focused tests, and this task record.

**Status**: Accepted 2026-07-25 after independent review. Checkpoint commit follows.
