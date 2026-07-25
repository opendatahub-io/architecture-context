# Task: Validate Local MLflow Tracking in Task Container

## Goal

Prove the local file-backed MLflow path works end-to-end in the task
container, without requiring an external server or running the paid/full-corpus
evaluation.

## Outcome

Accepted on 2026-07-25. The existing task image provided `mlflow==2.22.0` and
the local `MLFLOW_RUNS_DIR` backend was validated without modifying the image
or production dependencies.

## Evidence

- Local preflight: configured, reachable, and dry-run; the dry-run directory
  was not created.
- Dry-run tracking: success, 16 tags, 12 metrics, and 1 artifact reference,
  with no writes and no run ID.
- Live tracking: success in `/tmp/mlflow-validate-live`; read-back verified
  experiment identity, `FINISHED` status, run name, 9 tags, 12 metrics, and 4
  artifact references. All writes remained inside the local store.
- `python3 -m pytest tests/test_mlflow_tracking.py -v`: 94 passed, including
  the five SDK-backed local tracking tests.
- `python3 benchmark/analyzer-assisted-v1/validate.py`: PASS.
- `git diff --check`: PASS.

## Documentation

Updated `benchmark/analyzer-assisted-v1/README.md` and
`docs/notes/analyzer-assisted-evaluation-contract.md` to distinguish locally
validated tracking from pending external MLflow server registration.

## Limitations

No external MLflow experiment was registered. No paid or full-corpus
evaluation was run. External registration still requires `MLFLOW_TRACKING_URI`
and a running server.
