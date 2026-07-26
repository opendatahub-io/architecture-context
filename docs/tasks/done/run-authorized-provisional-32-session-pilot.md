# Task: Run Authorized Provisional 32-Session Pilot

## Goal

Run a bounded analyzer-assisted pilot for directional retrieval, telemetry,
provenance, and cost evidence without human labels or external MLflow state.

## Fixed matrix

- Questions: `INV-001`, `FACT-001`, `INTG-001`, `NAV-001`.
- Conditions: `baseline`, `index-md`, `arch-query`, `combined`.
- Trees: `architecture/rhoai.next.bak` and `architecture/rhoai.next`.
- Model: `opus`; at most 4 concurrent sessions; 32 total tree sessions.
- Guards: $25 cumulative cost and 30 minutes wall time.

## Execution evidence

The pilot completed on 2026-07-26 with 32/32 sessions and zero failures.
Both guards remained below limit: $8.1087 total and 347.65 seconds wall time.

| Condition | Tree A score | Tree B score | Cost |
|---|---:|---:|---:|
| baseline | 0.375 | 0.375 | $3.2095 |
| index-md | 0.500 | 0.375 | $1.4405 |
| arch-query | 0.375 | 0.375 | $1.9600 |
| combined | 0.375 | 0.375 | $1.4987 |

Scores are the deterministic consumer-v1 composite on four questions per
condition/tree. The index result is directional only; it is not statistically
significant and does not establish rollout safety. All conditions had zero
exact-match rate on tree B in this small sample.

### Artifacts and provenance

Ignored artifacts are under `tmp/provisional-pilot/results/`:

- one raw and scored result pair per condition;
- `pilot-summary.json` with totals, telemetry, guard outcome, and SHA-256
  prefixes/full artifact hashes;
- `mlflow-tracking-summary.json` with 32 successful local runs and verified
  read-back;
- local store: `/workspace/tmp/mlflow-runs/provisional-32-session-pilot`;
- experiment: `analyzer-assisted-provisional-32-session-pilot`;
- canonical index provenance: `rhoai.next`, 99 components,
  `c5c8201c748a8c982677f0948e686178bf5d2bf8`;
- context telemetry contract: `1.0.0`; canary validation passed for all four
  condition result directories.

### Validation

- `score_results.py`: all four condition artifacts scored successfully.
- `canary_report.py --validate-only`: PASS for all four conditions.
- Experiment manifest and corpus validators: PASS.
- 16 question records / 32 tree sessions: all successful and provenance-aligned.
- No-fallback and access-boundary checks: PASS.
- No human labels/categories or feedback data were used; no external MLflow
  state was created; no architecture facts, overlays, or generated documents
  were modified.

## Limitations

- Only 4 of 40 active questions were evaluated.
- No human review, semantic calibration, or authoritative failure labels exist.
- The `arch-query` artifact is a local build, not a pinned Git-SHA build.
- File-backed MLflow required `MLFLOW_ALLOW_FILE_STORE=true` for the image's
  MLflow filesystem backend.

## Status

Done — accepted and ready for checkpoint commit.
