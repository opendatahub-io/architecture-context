# Task: Investigate Consumer V1 Focused Eval Agent Hang

## Goal

Make focused `consumer-v1` evaluation runs fail fast or complete when the
underlying Claude SDK agent does not emit an initial response.

## Context

While validating the model-registry `FACT-005` fix on 2026-07-29, multiple
focused eval attempts reached Phase 1 and then wrote only the
`FACT-005_tree_a.log` header. The wrapper has no per-question timeout around
`benchmark/consumer-v1/run_evaluation.py`, so the run can wait indefinitely.

Tracking bug:
`docs/bugs/fixed/consumer-v1-focused-eval-agent-start-hangs.md`.

## Plan

1. Reproduce the focused `FACT-005` hang against a minimal output directory.
2. Add a per-question timeout around `run_question_against_tree`.
3. Ensure timeout failures are serialized into `raw-results.json` with useful
   diagnostics instead of blocking the whole run.
4. Rerun a focused question to verify success or bounded failure reporting.

## Acceptance Criteria

- A focused eval run cannot hang indefinitely before the first answer message.
- Timeout or startup failures are represented in raw/scored/report artifacts.
- The model-registry `FACT-005` rerun can be retried to close
  `docs/tasks/done/reconcile-model-registry-rest-auth-contract.md`.

## Status

Done as not reproduced in the host-run benchmark. The user-run
`./scripts/run_consumer_v1_rhoai_next_eval.sh` completed at
`tmp/evaluations/consumer-v1-rhoai-next-20260729T215258Z/`, wrote raw/scored
results and a report, and evaluated all 40 questions. No evaluator code change
was made.
