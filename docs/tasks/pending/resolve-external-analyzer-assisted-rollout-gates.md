# Task: Resolve External Analyzer-Assisted Rollout Gates

## Goal

Resolve the remaining external gates for full analyzer-assisted rollout, or
record the exact unavailable inputs and continue only under the documented
provisional track.

## Required inputs

- A reachable approved MLflow server and `MLFLOW_TRACKING_URI`, if external
  experiment registration is required.
- The external `fetch-architecture-context.sh` OTel producer or equivalent
  approved producer evidence.
- Human adjudication for the 35 root-cause proposals in
  `benchmark/consumer-v1/adjudication_template.json`.
- Human semantic labels for the 24 calibration questions in
  `benchmark/consumer-v1/calibration_template.json`, plus authorization to
  execute the semantic judge.

## Acceptance criteria

- Each gate has authoritative evidence, a validation command, and provenance.
- Full rollout claims and legacy-route retirement remain prohibited while any
  required gate is unresolved.
- If inputs remain unavailable, update the plan and report the provisional
  limitations without fabricating labels, external telemetry, or server state.
- Preserve the empty tracked synthesis allowlist until an explicit reviewed
  expansion decision is made.
