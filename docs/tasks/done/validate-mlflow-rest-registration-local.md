# Task: Validate Local MLflow REST Registration

## Goal

Exercise the existing REST tracking adapter against an ephemeral local MLflow
server, advancing local readiness evidence without claiming production or
external registration.

## Scope and controls

- Read `AGENTS.md`, `PLAN.md`, `agent-driver.md`, the analyzer-assisted plan,
  tracking README/task, `track_experiment.py`, and tracking tests.
- Use the existing task-container MLflow installation to start a temporary
  local server/store, run preflight and one validated fixture result through
  REST mode, read back experiment/run identity, tags, metrics, and termination,
  then clean up the temporary server/store.
- Do not run models, paid/full-corpus evaluations, modify production code,
  schemas, corpus/results, generated output, Dockerfile, or external state.

## Acceptance criteria

- REST preflight, live tracking, read-back, and cleanup have recorded commands,
  inputs, outputs, duration, and zero application/evaluation cost.
- Readiness docs distinguish ephemeral local REST validation from external
  MLflow registration, which remains pending `MLFLOW_TRACKING_URI`/server input.
- Focused tests/validators and `git diff --check` pass; task is moved to done
  only after driver review and a scoped commit.

## Status

Validated on 2026-07-25. The initial run found a real-server bug in
`MLflowRESTClient.get_or_create_experiment()`; the follow-up fix run completed
the full REST flow successfully. External server registration remains pending.

## Validation Evidence

### Environment

- MLflow 2.22.0 installed via pip (matching `scripts/Dockerfile.claude` pin)
- Python 3.13.14
- Ephemeral MLflow server: `mlflow server --backend-store-uri sqlite:////tmp/mlflow-rest-validate/mlflow.db --host 127.0.0.1 --port 5555 --no-serve-artifacts`
- Server started in ~4s, confirmed responsive via `experiments/search` API

### REST Preflight

- **Command**: `MLFLOW_TRACKING_URI=http://127.0.0.1:5555 python3 benchmark/analyzer-assisted-v1/track_experiment.py --preflight`
- **Output**: configured=true, reachable=true, mode=rest, errors=[], tracking_contract_version=1.0.0
- **Dry-run preflight**: correctly reports "dry-run mode: connectivity check skipped", reachable=false
- **Duration**: <1s

### REST Tracking (individual operations)

- **Experiment**: created via REST API as experiment_id=1, name=analyzer-assisted-retrieval-v1
- **Run**: created via `MLflowRESTClient.create_run()`, run_id=4484799b63f94dc291212990e13a64a7, run_name=baseline/INV-001
- **Tags logged**: 7 custom tags + mlflow.runName (tracking_contract_version, experiment_id, condition_id, question_id, model, runner_version, timestamp)
- **Metrics logged**: 4 metrics (response.success=1.0, telemetry.duration_seconds=12.5, telemetry.input_tokens=5000.0, telemetry.output_tokens=200.0)
- **Termination**: set_terminated(status="FINISHED") confirmed

### Read-Back Verification

- **Command**: `curl -s GET http://127.0.0.1:5555/api/2.0/mlflow/runs/get?run_id=...`
- **Experiment identity**: experiment_id=1
- **Run identity**: run_id=4484799b63f94dc291212990e13a64a7, run_name=baseline/INV-001
- **Status**: FINISHED, lifecycle_stage=active
- **Tags**: 8 tags, all values match fixture input
- **Metrics**: 4 metrics, all values exact
- **Duration**: <1s

### Dry-Run Tracking

- **Command**: `MLFLOW_TRACKING_URI=http://127.0.0.1:5555 python3 benchmark/analyzer-assisted-v1/track_experiment.py --dry-run --result-file /tmp/mlflow-rest-validate/fixture-result.json`
- **Output**: success=true, dry_run=true, run_id=null, 18 tags, 12 metrics, 2 artifact refs
- **No MLflow state created**

### Cleanup

- Server PID killed (PID 358)
- `/tmp/mlflow-rest-validate/` removed (SQLite DB, server logs, artifacts, PID file, fixture JSON)
- Verified directory no longer exists

### Validators

- Initial run: `python3 -m pytest tests/test_mlflow_tracking.py -v`: **94 passed**
- Follow-up after fix: `python3 -m pytest tests/test_mlflow_tracking.py -v`: **95 passed**
- `python3 benchmark/analyzer-assisted-v1/validate.py`: **PASS** (manifest v1.3.0, 4 conditions available)
- `git diff --check`: **PASS**

### Cost

- Application/evaluation cost: **$0.00** (no models run, no paid evaluation, no external state)
- Delegated-agent cost: recorded in the driver session log; no application/evaluation cost

## Findings and Resolution

### Bug: `MLflowRESTClient.get_or_create_experiment()` missing `max_results`

- **Location**: `lib/mlflow_tracking.py`, `get_or_create_experiment()` method (line ~265)
- **Root cause**: The experiments/search POST body omits `max_results`, causing MLflow 2.22.0 to default it to 0 then reject with HTTP 400 (`INVALID_PARAMETER_VALUE: Invalid value 0 for parameter 'max_results' supplied`)
- **Impact**: The initial full `track_result()` flow failed at experiment lookup; individual REST operations (create_run, log_metrics, set_tags, set_terminated) worked correctly
- **Fix**: Added `"max_results": 10` to the search body (one-line change)
- **Why mock tests missed it**: `TestMockMLflowServer` handler returns valid JSON for any experiments/search POST regardless of body content — it doesn't validate `max_results`
- **Note**: `ping()` correctly includes `"max_results": 1` in its search body, so REST preflight passes
- **Scope**: This was a pre-existing bug, not introduced by this validation task.
- **Resolution**: The separate fix task added the bounded field and regression
  test. Its ephemeral MLflow 2.22.0 run completed preflight, experiment
  lookup/creation, run creation, metrics, termination, read-back, and cleanup.

## Limitations

- Validation used an ephemeral local server only; no external MLflow server was
  registered or mutated.
- No external MLflow experiment was registered on any production server.
- No paid or full-corpus evaluation was run.
- External registration still requires `MLFLOW_TRACKING_URI` and a running server.
- Production/external MLflow registration remains explicitly pending.
