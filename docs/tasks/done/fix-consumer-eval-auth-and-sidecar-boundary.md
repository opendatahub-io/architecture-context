# Fix Consumer Eval Auth and Sidecar Boundary

## Status

Done — 2026-07-28

## Context

The first consumer-v1 run after generation returned 0% for both trees because
each agent response was `Not logged in · Please run /login`; the evaluator
treated that auth text as a successful answer. After auth was fixed, a valid
run showed Tree B regressions, but inspection found Tree B agents reading
private `.analyzer` and `.generation` files under the architecture tree.

## Changes

- `benchmark/consumer-v1/run_evaluation.py` now:
  - passes known Claude/Vertex authentication variables from `.env` and caller
    environment into the SDK without shell-sourcing `.env`;
  - treats Claude auth/login responses and `ResultMessage.is_error` as failed
    evaluation sessions;
  - denies direct reads/searches rooted at private `.analyzer` and
    `.generation` sidecar directories.
- `scripts/run_consumer_v1_rhoai_next_eval.sh` now:
  - uses a repo-local `tmp/uv-cache` by default;
  - materializes private-dir-free eval trees under the output directory before
    launching agents.
- Added focused tests for env parsing, caller precedence, auth failure
  detection, and private sidecar read denial.
- Recorded the 2026-07-29 benchmark as provisional because it predated the
  private-sidecar eval-tree staging fix.

## Validation

- `uv run ruff check benchmark/consumer-v1/run_evaluation.py tests/test_eval_guard_telemetry.py`
- `uv run pytest tests/test_eval_guard_telemetry.py -q`
- `bash -n scripts/run_consumer_v1_rhoai_next_eval.sh`
- `scripts/run_consumer_v1_rhoai_next_eval.sh --dry-run --question-id FACT-001`
