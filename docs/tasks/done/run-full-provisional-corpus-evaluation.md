# Task: Run Full Provisional 40-Question Evaluation

## Goal

Run the full provisional no-human-data evaluation against the verified
40-question corpus to replace the directional 4-question pilot with complete
exact-match, citation, gap, telemetry, provenance, and local-MLflow evidence.

## Fixed matrix

- Corpus: all 40 active questions in `benchmark/consumer-v1/corpus.json`.
- Conditions: `baseline`, `index-md`, `arch-query`, `combined`.
- Trees: `architecture/rhoai.next.bak` and `architecture/rhoai.next`.
- Model: `opus`; 320 tree sessions total; use bounded concurrency (at most 8).
- Cost: explicitly authorized by the user without a cost ceiling.
- Process safety: stop and preserve partial evidence after 2 hours wall time.

## Controls and provenance

- Use `benchmark/consumer-v1/run_evaluation.py`, the condition planner, and
  `benchmark/consumer-v1/score_results.py`; do not silently fall back between
  conditions.
- Use the corrected `rhoai.next` index identities under
  `tmp/provisional-pilot/`; use the same canonical INDEX and local-build
  `arch-query` binary provenance as the accepted pilot.
- Write all full-run results, logs, scores, summaries, and normalized tracking
  inputs under `tmp/provisional-full-corpus/`.
- Use local MLflow only:
  `MLFLOW_RUNS_DIR=/workspace/tmp/mlflow-runs/provisional-full-corpus`,
  `MLFLOW_EXPERIMENT_NAME=analyzer-assisted-provisional-full-corpus`, and
  unset `MLFLOW_TRACKING_URI`.
- Do not read `tmp/feedback-data`, fill human labels/categories, modify code,
  schemas, corpus, architecture facts, overlays, generated documents, or
  external state; do not commit.

## Acceptance criteria

- Produce raw and scored artifacts for all four conditions, each covering 40
  questions and both trees, with condition, model, corpus, tree, telemetry,
  and artifact provenance intact.
- Produce deterministic aggregate and per-tier/per-condition/per-tree scores,
  exact-match/citation/gap rates, session failures, duration, token/cost
  totals, and full-run artifact hashes.
- After the evaluation, create a committed human-readable Markdown results and
  conclusions report (for example,
  `docs/notes/analyzer-assisted-provisional-results.md`) covering methodology,
  matrix, condition/tree/tier/scoring results, cost/time/token/context metrics,
  observations versus conclusions, limitations, and remaining rollout gates.
- Track all valid tree/question results in local MLflow and verify read-back;
  report the local store and experiment name.
- Run all corpus/experiment/result/canary validators and `git diff --check`;
  record exact commands, actual cost/duration, partial/complete status, and
  limitations in this task and the session ledger.
- Do not commit generated evaluation artifacts; the driver reviews and
  checkpoints only the accepted task/ledger documentation.

## Execution record

### Commands executed

```bash
# 1. Runner script
python3 tmp/provisional-full-corpus/run_full_corpus.py
# Runs 4 conditions × 40 questions × 2 trees sequentially by condition,
# max 8 concurrent sessions per condition, 2-hour wall-time guard.

# 2. Scoring (all four conditions)
python3 benchmark/consumer-v1/score_results.py \
  --results tmp/provisional-full-corpus/results/<cond>/raw-results.json \
  --corpus benchmark/consumer-v1/corpus.json \
  --output tmp/provisional-full-corpus/results/<cond>/scored-results.json

# 3. Report generation
python3 benchmark/consumer-v1/generate_report.py \
  --scored-results tmp/provisional-full-corpus/results/<cond>/scored-results.json \
  --output tmp/provisional-full-corpus/results/<cond>/report.md

# 4. MLflow tracking and read-back verification
MLFLOW_ALLOW_FILE_STORE=true python3 tmp/provisional-full-corpus/track_mlflow.py

# 5. Summary with SHA-256 hashes
python3 tmp/provisional-full-corpus/generate_summary.py
```

### Results

- **320/320 sessions completed**, 0 failures
- **Total cost**: $117.13 ($28.88 baseline, $29.99 index-md, $26.98 arch-query, $31.28 combined)
- **Total wall time**: 2338.66 seconds (39.0 minutes)
- **Time guard (2 hours)**: not reached
- **Model**: opus (claude-opus-4-6)

### Scores by condition

| Condition | Tree A avg | Tree B avg | Tree A exact | Tree B exact | Tree A cite | Tree B cite |
|-----------|-----------|-----------|-------------|-------------|------------|------------|
| baseline  | 0.5375    | 0.475     | 0.350       | 0.200       | 0.700      | 0.725      |
| index-md  | 0.5125    | 0.475     | 0.350       | 0.225       | 0.650      | 0.700      |
| arch-query| 0.5250    | 0.4458    | 0.375       | 0.175       | 0.650      | 0.700      |
| combined  | 0.5500    | 0.4458    | 0.400       | 0.200       | 0.675      | 0.675      |

### MLflow tracking

- Local store: `tmp/mlflow-runs/provisional-full-corpus`
- Experiment: `analyzer-assisted-provisional-full-corpus`
- Runs tracked: 320, failed: 0, skipped: 0
- Read-back: 320 runs found — **PASS**
- Runs by condition: baseline=80, index-md=80, arch-query=80, combined=80

### Artifact hashes (SHA-256)

| Artifact | Hash |
|----------|------|
| baseline/raw_results | `b4646b4e7b03fcba5b451f5873c79e536e5aabd4badb95badc5542995e2f7d71` |
| baseline/scored_results | `873238754a5f3b56b7d345e0553840974210247352f3a837a32eef30c8f03cea` |
| index-md/raw_results | `216f59089a8a7cef849a791de7574225cbe7795add615d5ffb247eb34abe9495` |
| index-md/scored_results | `a5e90375764ff91a965f988cd8335b2ee05212aae1163d642b472d3c46fea263` |
| arch-query/raw_results | `3e678fd0034a697c650da4dca9eb14cf45c8b6f82e56a9980e02843e45afd866` |
| arch-query/scored_results | `816b69d8d0d1df3bbc5e9f12a288cdcb013fffbcbf86d1235630d63e1dffafbd` |
| combined/raw_results | `ddf70fec87b7b5b07517e35de09cafe331454a0a9c737214cb18adc352570c45` |
| combined/scored_results | `91c0bd19d44d8c4ed9b85acdf0e02eabf3583ed463136b9313d6703553e87c33` |
| run-meta | `fdda5f9a67ba52446ef9913cd31abd74ac04cef6b894d783620cc1376ee099b4` |
| mlflow-tracking-summary | `774990c0939842f191825908fa51d2afc8e83a48799e0791c3f84db01b96e1a1` |

### Validators

| Validator | Result |
|-----------|--------|
| `python3 benchmark/consumer-v1/validate.py` | PASS (40 questions, 10/tier) |
| `python3 benchmark/analyzer-assisted-v1/validate.py` | PASS (v1.3.0, 4 available) |
| `python3 benchmark/analyzer-assisted-v1/validate_corpus.py` | PASS (40 active, 0 retired) |
| `python3 benchmark/analyzer-assisted-v1/canary_report.py --validate-only` | PASS (no violations) |
| `python3 benchmark/consumer-v1/validate_adjudication.py adjudication_template.json` | PASS (35 proposals) |
| `python3 benchmark/consumer-v1/validate_calibration.py calibration_template.json` | PASS (24 questions) |
| `git diff --check` | PASS (exit 0) |

### Controls confirmed

- Did NOT read `tmp/feedback-data`
- Did NOT fill human labels or categories
- Did NOT modify code, schemas, corpus, architecture facts, overlays, or generated documents
- Did NOT create external state or commit
- Used local MLflow only (MLFLOW_RUNS_DIR, unset MLFLOW_TRACKING_URI)
- Used corrected rhoai.next index identities from `tmp/provisional-pilot/`
- Used canonical INDEX.md and local-build arch-query binary provenance

### Limitations

- All scores are deterministic exact-match only; no LLM-as-judge semantic scoring
  (no calibrated judge available)
- All `human_label` and `human_category` values remain null
- External MLflow server registration remains pending
- External-fetch OTel producer not validated
- Legacy route preserved; not retired

## Status

Complete — evaluation, independent review, validators, and the committed
human-readable results report are complete. The raw evaluation artifacts remain
under the ignored `tmp/` tree; the report and task record are tracked.
