# Task: Configure Analyzer-Assisted Experiment Tracking

## Goal

Implement the missing experiment-tracking boundary for the four-condition
analyzer-assisted benchmark so an authorized evaluation can register and record
runs reproducibly, without running an evaluation in this task.

## Context

`docs/plans/analyzer-assisted-agent-architecture.md` requires experiment
tracking before rollout evaluation. The current contract records provenance,
telemetry, condition identity, scores, and failure classifications in JSON, but
the readiness notes still report MLflow tracking as not configured.

## Scope and controls

- Inspect `benchmark/analyzer-assisted-v1/experiment.json`, `result_schema.json`,
  `validate.py`, `benchmark/consumer-v1/run_evaluation.py`, and the readiness
  feedback in `tmp/feedback-data/experiment-readiness-2026-07-23.yaml`.
- Add a small, optional tracking adapter or CLI using the MLflow tracking REST
  API (stdlib HTTP is preferred); it must support deterministic experiment/run
  metadata, condition/provenance tags, metrics, and artifact references.
- Add a no-network preflight/dry-run mode that reports the exact tracking URI,
  experiment name, required fields, and unavailable configuration clearly.
- Do not launch agents, paid/full-corpus evaluations, create external MLflow
  state, alter production dependencies, or change result/schema semantics.
- Do not modify generated architecture output, corpus questions/results, or
  unrelated tracking code. Do not commit.

## Acceptance criteria

- [x] A versioned tracking contract/adapter maps validated experiment results to
  MLflow experiment/run metadata without fabricating scores or provenance.
- [x] Missing `MLFLOW_TRACKING_URI` or an unreachable endpoint is an explicit
  preflight status, not a silent success; configured operation has a safe
  request boundary and actionable errors.
- [x] Focused tests cover dry-run, required metadata, result-to-metric mapping,
  artifact references, and failure/unavailable paths without network access.
- [x] README/notes distinguish implemented tracking integration from external
  experiment registration and preserve the remaining authorization gate.
- [x] Run validators, focused tests, and `git diff --check`; report exact
  commands, outputs, and any infrastructure limitation.

## Implementation

Added `lib/mlflow_tracking.py`, a versioned (`TRACKING_CONTRACT_VERSION=1.0.0`)
stdlib-only MLflow REST adapter; `benchmark/analyzer-assisted-v1/track_experiment.py`
with preflight, dry-run, and live-tracking modes; and
`tests/test_mlflow_tracking.py` with 62 offline tests. The adapter maps result
identity, condition, provenance, telemetry, context metrics, failure
classifications, and artifact references without changing the result schema.

Refinement corrected MLflow `experiments/search` connectivity to POST with JSON
and converts socket/time-out `OSError` failures into explicit tracking errors.
No external MLflow experiment was created and no evaluation was run.

## Validation

- `python3 -m pytest tests/test_mlflow_tracking.py -v` — 62 passed in the task
  container.
- `python3 -m pytest tests/test_analyzer_assisted_evaluation.py -v` — 98 passed
  in the task container.
- `python3 benchmark/analyzer-assisted-v1/validate.py` — PASS, all four
  conditions available and six failure classifications.
- `git diff --check` — PASS.
- Host `python3 -m pytest` was unavailable (`pytest` not installed); this is an
  infrastructure limitation, covered by the container test results.

## Status

Validated. External MLflow registration and evaluation authorization remain
pending.
