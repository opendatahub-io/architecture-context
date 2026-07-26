# No-Human-Data Provisional Rollout Track

**Date**: 2026-07-26
**Task**: `docs/tasks/done/define-no-human-data-rollout-track.md`

## Context

The analyzer-assisted architecture plan defines five external-input gates
for Step 5 (canary, benchmark, and expand). Two of these gates require
human-provided data that is unlikely to arrive:

1. **Human adjudication** of 35 failure-classification proposals
   (`adjudication_template.json` v0.1.0, all `human_category: null`)
2. **Human semantic-match labeling** of 24 calibration questions
   (`calibration_template.json` v0.1.0, all `human_label: null`)

A 94-question feedback package exists in `tmp/feedback-data/` (git-ignored)
but is internally inconsistent and non-reproducible — see
`docs/notes/historical-feedback-provenance.md`. It cannot substitute for
the missing human labels.

This note defines a provisional track that enables evaluation and rollout
planning without asserting that human-data gates have been satisfied.

## Provisional track definition

### What the provisional track permits

| Activity | Scope | Limitation |
|----------|-------|------------|
| Deterministic regression testing | Snapshot-to-snapshot 1:1 comparison of analyzer facts, overlay preservation, merge-layer enforcement, and correction regression assertions | Not a semantic quality measurement; detects structural regressions only |
| Automated root-cause signal generation | `lib/failure_proposals.py` generates `proposed_category` from direct infrastructure and context telemetry signals | All proposals are `unresolved` and non-authoritative; no `human_category` may be claimed |
| Exact-match scoring against canonical corpus | `score_results.py` with case-insensitive, emphasis-stripped matching against the 40-question consumer-v1 corpus | Measures exact-match retrieval only; not semantic equivalence |
| File-backed MLflow experiment tracking | `MLFLOW_RUNS_DIR` local mode with validated preflight, dry-run, and live tracking | No external server registration; no cross-session experiment comparison |
| Context telemetry collection | `ContextTelemetryCollector` (reads, queries, denials, context-quality signals) with per-tree `context_metrics` and `context_provenance` | Local OTel JSONL export only; external-fetch producer not available |

### What the provisional track does NOT permit

| Claim | Reason |
|-------|--------|
| LLM-as-judge semantic scores | Calibration template has all `human_label: null`; no calibrated judge exists |
| Human-review quality assertions | No human review scores exist; calibration and adjudication templates are unfilled |
| Authoritative failure classifications | All 35 proposals have `human_category: null`; automated `proposed_category` is directional only |
| Full rollout gate satisfaction | Two human-data gates (adjudication, labeling) and user authorization remain unsatisfied |
| Historical 84% baseline comparison | The 94-question/84% figure is unverified and internally inconsistent — see provenance note |

### Existing feedback as directional signal

The 94-question feedback package (`tmp/feedback-data/`) provides:

- **Category weakness patterns**: CRD/API surface, deployment model, and
  team ownership were the lowest-scoring categories. These inform plan
  design priorities but are not evaluation evidence.
- **Semantic gap distribution**: 38 gaps across 7 REVISE strategies
  (87% missing context, 13% wrong/stale context). Useful for prioritizing
  extraction improvements.
- **Staff-correction frequency**: `staff-corrections.yaml` (169 records)
  is already consumed by `arch-analyzer harvest-proposals` as an input
  fixture — this is appropriately scoped consumption, not promotion to
  ground truth.

These signals are directional. They informed the plan's design but cannot
serve as reproducible evaluation baselines or substitute for human labels.

## Provisional success criteria

The full plan success criteria (S1–S8) remain authoritative targets. The
provisional track narrows what can be measured without human data:

| Full criterion | Provisional measurement | Evidence boundary |
|----------------|------------------------|-------------------|
| S1: No analyzer-owned fact regressions | Deterministic regression assertions (18 adjudication tests + merge-layer tests) | **Measurable** — structural regression only |
| S2: Retrieval improves from v1-ab baseline | Exact-match scoring against 40-question corpus; v1-ab tree_a avg 0.3625, tree_b avg 0.3375 as reproducible baseline | **Measurable** — exact match, not semantic equivalence |
| S3: Fewer stale/wrong-context corrections | Automated proposal generation with direct signals; compare `unresolved` vs `infrastructure-failure`/`stale-context` counts across runs | **Directional only** — proposals are non-authoritative without human adjudication |
| S4: Testability output quality | Contract field presence and explicit-unknown coverage in synthesis output | **Measurable** — schema compliance, not content quality |
| S5: Feasibility output quality | Contract field presence and explicit-unknown coverage in synthesis output | **Measurable** — schema compliance, not content quality |
| S6: Context fetch cost | Context telemetry metrics (reads, queries, denials) per evaluation run | **Measurable** — local telemetry; no external-fetch OTel |
| S7: Synthesis insight quality | Insight artifact count, category distribution, provenance references present | **Directional only** — no unsupported-claim/false-positive threshold without human review |
| S8: Human review scores do not regress | **Not measurable** — no human review scores exist | Requires human labeling and judge calibration |

## Retained invariants

The provisional track preserves all existing invariants:

- **Canonical 40-question corpus**: `benchmark/consumer-v1/corpus.json`
  (v1.0.0), 10 questions per tier, all with verified source evidence
- **v1-ab baseline**: `benchmark/consumer-v1/results/v1-ab/scored-results.json`
  (40 questions, durable artifact)
- **File-backed MLflow workflow**: `lib/mlflow_tracking.py`
  (TRACKING_CONTRACT_VERSION 1.0.0) with REST and local modes
- **Legacy route**: preserved and available; retirement requires canary
  evidence that the plan's full (not provisional) gates have passed
- **External cost/authorization gate**: no paid or full-corpus evaluation
  without explicit user authorization
- **External OTel caveat**: `fetch-architecture-context.sh` OTel producer
  is not in this repository; end-to-end fetch spans remain unavailable
- **Null human fields**: all `human_label` and `human_category` values
  remain null; no fields are filled or relabeled

## Relationship to the full rollout track

The provisional track is a subset, not a replacement. When human data
becomes available:

1. Fill `human_label` values in `calibration_template.json` → enables
   judge calibration and semantic scoring (S2 upgrade, S8 enablement)
2. Fill `human_category` values in `adjudication_template.json` → enables
   authoritative failure classifications (S3 upgrade)
3. Both + user authorization → full rollout gate satisfaction

Until then, provisional measurements provide regression detection and
directional signal. They do not satisfy the full plan's rollout criteria,
and the legacy route must not be retired based on provisional evidence
alone.

## Snapshot regression report

A deterministic bulk comparison command is available for structural
regression detection between architecture snapshot directories:

```
python3 scripts/compare_snapshot_regression.py [options]
```

### Defaults

| Parameter | Default |
|-----------|---------|
| `--baseline` | `architecture/rhoai.next.bak` |
| `--candidate` | `architecture/rhoai.next` |
| `--format` | `both` (text to stderr, JSON to stdout) |

### Thresholds

| Flag | Default | Purpose |
|------|---------|---------|
| `--min-row-recall` | `0.0` | Fail when aggregate stable-row recall is below this value |
| `--min-structured-recall` | `0.0` | Fail when aggregate structured-row recall (excluding source inventory and recent history) is below this value |
| `--max-missing-components` | none | Fail when more than N baseline components are absent from the candidate |
| `--fail-on-conflicts` | off | Fail when any source-backed cell conflicts exist |

### Evidence boundary

- The report pairs same-named component Markdown files and uses
  `lib/architecture_baseline.py` comparison semantics (stable-row
  recall, required-section loss, cell conflicts).
- Per-component evidence is included in both text and JSON output.
- **This is a structural/provisional regression report — not human
  adjudication.** It detects document-surface and stable-row
  regressions only; it does not measure semantic quality.
- The JSON output includes an explicit
  `meta.adjudication: "structural/provisional — not human adjudication"`
  marker.
- No models are run, no human labels are filled, and no architecture
  facts, overlays, or generated documents are modified.

### Implementation

- Core logic: `lib/snapshot_regression.py`
- CLI entry point: `scripts/compare_snapshot_regression.py`
- Tests: `tests/test_snapshot_regression.py` (13 focused tests covering
  identical trees, missing/additional components, conflicts,
  deterministic ordering, skip-file exclusion, threshold violations,
  and provisional markers)

## Status

This is a durable decision note. It does not modify application code,
schemas, corpus, generated output, or external state. All human-data
fields remain null. The plan's full rollout gates and success criteria
remain authoritative.
