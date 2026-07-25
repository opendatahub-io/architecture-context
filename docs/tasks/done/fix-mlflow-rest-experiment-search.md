# Task: Fix MLflow REST Experiment Search

## Goal

Fix the real-server REST tracking defect discovered by the local MLflow 2.22.0
validation task.

## Scope and controls

- Read `AGENTS.md`, `PLAN.md`, `agent-driver.md`, the open bug, the validation
  task, `lib/mlflow_tracking.py`, and MLflow tracking tests.
- Add a positive bounded `max_results` field to
  `MLflowRESTClient.get_or_create_experiment()` and a regression test that
  rejects an omitted/zero value while preserving existing mock behavior.
- Do not run models, paid/full-corpus evaluations, create external state,
  modify schemas/corpus/results/generated output/Dockerfile, or reinstall MLflow.

## Acceptance criteria

- Focused mock tests prove the search request includes `max_results > 0`.
- The same ephemeral local MLflow REST server flow succeeds end-to-end:
  preflight, experiment lookup/creation, run, metrics, termination, and
  read-back; clean up all temporary state.
- Update the bug, validation task, README/evaluation note, PLAN, and session
  ledger with exact evidence; close the bug only after review and commit.
- Run focused tests, validators, and `git diff --check`; do not commit.

## Status

Accepted on 2026-07-25 after driver review. Fix applied, regression test
added, and end-to-end REST flow validated. Included in the scoped driver
commit.

## Implementation Evidence

### Fix

Added `"max_results": 10` to the experiments/search POST body in
`MLflowRESTClient.get_or_create_experiment()` (`lib/mlflow_tracking.py:266`).

### Regression Test

Added `test_experiment_search_includes_positive_max_results` to
`TestMockMLflowServer` in `tests/test_mlflow_tracking.py`. The test
asserts that the experiments/search body contains `max_results` as a
positive integer.

### End-to-End REST Validation

- **Server**: ephemeral MLflow 2.22.0, SQLite backend, port 5556
- **Preflight**: configured=true, reachable=true, errors=[]
- **track_result()**: success=true, experiment_id=1,
  run_id=675326ce5ae148e0aedc9a37d13d19ca, run_name=baseline/INV-001
- **Tags logged**: 16 custom tags (tracking_contract_version, experiment_id,
  condition_id, question_id, model, runner_version, timestamp,
  question_category, question_difficulty, question_scope, schema_version,
  seed, provenance.architecture_context_sha, provenance.corpus_version,
  provenance.experiment_manifest_version, artifact_ref.0)
- **Metrics logged**: 12 metrics (response.success, telemetry.duration_seconds,
  telemetry.input_tokens, telemetry.output_tokens, telemetry.total_cost_usd,
  telemetry.num_turns, telemetry.tool_calls.Read, telemetry.tool_calls.Grep,
  context_metrics.context_fetches, context_metrics.useful_reads,
  context_metrics.navigation_reads, context_metrics.queries_issued)
- **Termination**: FINISHED
- **Read-back**: all 17 tags (16 custom + mlflow.runName), 12 metrics, status
  FINISHED, lifecycle_stage=active — all values exact match
- **Cleanup**: server killed, /tmp/mlflow-rest-e2e-validate/ removed, verified absent

### Validators

- `python3 -m pytest tests/test_mlflow_tracking.py -v`: **95 passed** (94 existing + 1 new)
- `python3 benchmark/analyzer-assisted-v1/validate.py`: **PASS** (v1.3.0, 4 conditions)
- `git diff --check`: **PASS**

### Cost

- Application/evaluation cost: **$0.00** (no models run, no paid evaluation, no external state)
- Delegated implementation-agent cost: **$3.213281** (launcher-reported)

### Changed Files

- `lib/mlflow_tracking.py` (one-line fix: added `max_results: 10` to search body)
- `tests/test_mlflow_tracking.py` (regression test added)
