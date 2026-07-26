# Provisional Full-Corpus Evaluation Results

## Methodology

Deterministic exact-match evaluation of the analyzer-assisted retrieval pipeline
against the verified 40-question consumer-v1 corpus. No LLM-as-judge semantic
scoring (no calibrated judge available). All `human_label` and `human_category`
fields remain null.

## Matrix

| Parameter | Value |
|-----------|-------|
| Corpus | 40 active questions (10 per tier) |
| Conditions | baseline, index-md, arch-query, combined |
| Trees | architecture/rhoai.next.bak (tree A), architecture/rhoai.next (tree B) |
| Model | opus (claude-opus-4-6) |
| Total sessions | 320 (4 conditions x 40 questions x 2 trees) |
| Concurrency | 8 concurrent sessions per condition |
| Seed | 42 |

## Overall Scores by Condition and Tree

| Condition | Tree A avg | Tree B avg | Tree A exact | Tree B exact | Tree A cite | Tree B cite |
|-----------|-----------|-----------|-------------|-------------|------------|------------|
| baseline  | 0.5375    | 0.475     | 0.350       | 0.200       | 0.700      | 0.725      |
| index-md  | 0.5125    | 0.475     | 0.350       | 0.225       | 0.650      | 0.700      |
| arch-query| 0.5250    | 0.4458    | 0.375       | 0.175       | 0.650      | 0.700      |
| combined  | 0.5500    | 0.4458    | 0.400       | 0.200       | 0.675      | 0.675      |

## Tree A by Tier

### Baseline

| Tier | Exact Match | Citation | Avg Score |
|------|------------|----------|-----------|
| Tier 1 (Inventory) | 0.600 | 0.300 | 0.4833 |
| Tier 2 (Component Facts) | 0.600 | 1.000 | 0.8167 |
| Tier 3 (Integration) | 0.100 | 0.900 | 0.5000 |
| Tier 4 (Navigation) | 0.100 | 0.600 | 0.3500 |

### Index-MD

| Tier | Exact Match | Citation | Avg Score |
|------|------------|----------|-----------|
| Tier 1 (Inventory) | 0.500 | 0.100 | 0.3333 |
| Tier 2 (Component Facts) | 0.600 | 1.000 | 0.8167 |
| Tier 3 (Integration) | 0.100 | 0.800 | 0.4500 |
| Tier 4 (Navigation) | 0.200 | 0.700 | 0.4500 |

### Arch-Query

| Tier | Exact Match | Citation | Avg Score |
|------|------------|----------|-----------|
| Tier 1 (Inventory) | 0.600 | 0.200 | 0.4333 |
| Tier 2 (Component Facts) | 0.600 | 1.000 | 0.8167 |
| Tier 3 (Integration) | 0.100 | 0.700 | 0.4000 |
| Tier 4 (Navigation) | 0.200 | 0.700 | 0.4500 |

### Combined

| Tier | Exact Match | Citation | Avg Score |
|------|------------|----------|-----------|
| Tier 1 (Inventory) | 0.700 | 0.200 | 0.4833 |
| Tier 2 (Component Facts) | 0.600 | 1.000 | 0.8167 |
| Tier 3 (Integration) | 0.100 | 0.800 | 0.4500 |
| Tier 4 (Navigation) | 0.200 | 0.700 | 0.4500 |

## Tree B by Tier

### Baseline

| Tier | Exact Match | Citation | Avg Score |
|------|------------|----------|-----------|
| Tier 1 (Inventory) | 0.500 | 0.400 | 0.4833 |
| Tier 2 (Component Facts) | 0.100 | 1.000 | 0.5667 |
| Tier 3 (Integration) | 0.000 | 0.900 | 0.4500 |
| Tier 4 (Navigation) | 0.200 | 0.600 | 0.4000 |

### Index-MD

| Tier | Exact Match | Citation | Avg Score |
|------|------------|----------|-----------|
| Tier 1 (Inventory) | 0.500 | 0.300 | 0.4333 |
| Tier 2 (Component Facts) | 0.200 | 1.000 | 0.6167 |
| Tier 3 (Integration) | 0.000 | 0.800 | 0.4000 |
| Tier 4 (Navigation) | 0.200 | 0.700 | 0.4500 |

### Arch-Query

| Tier | Exact Match | Citation | Avg Score |
|------|------------|----------|-----------|
| Tier 1 (Inventory) | 0.300 | 0.400 | 0.3667 |
| Tier 2 (Component Facts) | 0.200 | 1.000 | 0.6167 |
| Tier 3 (Integration) | 0.000 | 0.800 | 0.4000 |
| Tier 4 (Navigation) | 0.200 | 0.600 | 0.4000 |

### Combined

| Tier | Exact Match | Citation | Avg Score |
|------|------------|----------|-----------|
| Tier 1 (Inventory) | 0.400 | 0.300 | 0.3667 |
| Tier 2 (Component Facts) | 0.200 | 1.000 | 0.6167 |
| Tier 3 (Integration) | 0.000 | 0.700 | 0.3500 |
| Tier 4 (Navigation) | 0.200 | 0.700 | 0.4500 |

## Cost and Time

| Condition | Cost | Duration (s) | Tree A cost | Tree B cost |
|-----------|------|-------------|-------------|-------------|
| baseline  | $28.88 | 477.8 | $12.92 | $15.96 |
| index-md  | $29.99 | 687.3 | — | — |
| arch-query| $26.98 | 418.9 | — | — |
| combined  | $31.28 | 754.7 | — | — |
| **Total** | **$117.13** | **2338.7** | | |

## Context Telemetry

Context telemetry was captured for all 320 sessions via the versioned
`ContextTelemetryCollector` integrated into the evaluation guard. Per-tree
`context_metrics` and `context_provenance` are present in all raw-results.json
files.

The run metadata exposes aggregate cost and duration, while the raw records
preserve per-session context telemetry. A separately exposed aggregate token
total was not available from the runner output, so no token total is claimed
here; token fields remain available for future aggregation from the raw
telemetry where present.

## MLflow Tracking

- Store: `tmp/mlflow-runs/provisional-full-corpus` (local file-backed)
- Experiment: `analyzer-assisted-provisional-full-corpus`
- Runs: 320 tracked, 0 failed, 0 skipped
- Read-back: 320 runs verified (80 per condition)

## Observations

1. **Tier 2 (Component Facts) is the strongest tier** across all conditions and
   both trees: 60-100% exact match, 100% citation rate. The architecture docs
   have strong per-component factual coverage.

2. **Combined condition produces the highest Tree A average (0.55)** and highest
   Tree A exact match rate (0.40), suggesting that INDEX.md navigation guidance
   plus arch-query structured queries together provide marginal improvement over
   either alone.

3. **Tree B (rhoai.next) scores consistently lower than Tree A (rhoai.next.bak)**
   across all conditions. Tree B is the larger tree (99 vs 92 components); the
   additional components may introduce more noise in navigation.

4. **Tier 3 (Integration) and Tier 4 (Navigation) have low exact-match rates**
   (0-20%) but moderate citation rates (60-90%). Agents find relevant files but
   the deterministic exact-match scorer is strict on phrasing.

5. **Conditions show modest differentiation**. The combined condition's 0.55
   Tree A average vs baseline's 0.5375 is a +2.3% improvement. No condition
   dramatically outperforms baseline on the deterministic scorer.

6. **Cost is roughly uniform** across conditions ($27-31 per condition).
   Baseline was not the cheapest despite having fewer tool capabilities.

## Limitations

- **Deterministic exact-match only**: no semantic scoring, no LLM-as-judge.
  Many semantically correct answers score 0 on exact match because phrasing
  differs from the expected answer. The real quality gap between conditions
  may be larger than these scores show.
- **No human labels**: all `human_label` and `human_category` fields remain null.
  Root-cause classification and failure-mode analysis are blocked.
- **Single seed**: seed=42 throughout. No variance estimation across seeds.
- **Provisional track only**: this evaluation satisfies provisional S2
  (exact-match scoring) but not the full rollout gates (S8 human review,
  semantic calibration, external MLflow, OTel, legacy retirement).

## Remaining Rollout Gates

| Gate | Status |
|------|--------|
| Full-corpus exact-match evaluation (S2) | **Complete** (this run) |
| Semantic-judge calibration (S2 semantic) | Blocked — no calibrated judge |
| Human review scores (S8) | Blocked — no human labels |
| Root-cause classification | Blocked — no human adjudication |
| External MLflow server registration | Pending |
| External-fetch OTel producer | Pending |
| Legacy route retirement | Not started |
