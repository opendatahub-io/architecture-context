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
- Preserve the reviewed, bounded allowlist decision (`rhoai-mcp` for synthesis
  and `caikit-nlp` for partial) while external gates remain unresolved. Do not
  expand it further without new reviewed evidence.

## Current gate audit — 2026-07-26

No new external or human inputs were present in the repository or workspace.
The local provisional matrix is complete and the reviewed allowlist expansion
is recorded in
`docs/tasks/done/expand-provisional-analyzer-assisted-synthesis-allowlist.md`.
The following gates remain unresolved:

| Gate | Current evidence | Missing input |
|---|---|---|
| MLflow registration | Local file-backed and ephemeral REST validation | Approved reachable server and `MLFLOW_TRACKING_URI` |
| Fetch OTel | Local export boundary and launcher capture exist | External `fetch-architecture-context.sh` producer evidence |
| Root-cause labels | 35-proposal template, all `human_category: null` | Human adjudication |
| Semantic calibration | 24-question template, all `human_label: null` | Human labels and judge authorization |

The provisional track remains usable with exact-match, deterministic,
telemetry, and artifact-structure measurements. It cannot establish human
semantic quality or authorize legacy-route retirement.

## Driver reconciliation — 2026-07-26

No additional local implementation task remains after clean-run isolation was
verified in commit `6e04522a` and the plan was reconciled in `827ecfd3`.
The full 320-session provisional evaluation, local MLflow read-back, required
validators, telemetry, and human-readable report are already complete in
`docs/tasks/done/run-full-provisional-corpus-evaluation.md`. This task remains
current solely because the four external gates above are not locally
resolvable.

## Final state audit — 2026-07-26

The available `tmp/feedback-data/` package contains staff corrections,
directional corpus material, and review context, but does not provide the
required 35 authoritative root-cause classifications or 24 semantic-match
labels. No approved external MLflow URI or external fetcher OTel producer
evidence is present. Existing feedback therefore remains valid provisional
evidence only and cannot satisfy the full rollout gates.
