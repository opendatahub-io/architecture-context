# Analyzer-Assisted Evaluation Contract — Validation Note

**Date**: 2026-07-24 (reconciled 2026-07-25)
**Task**: `docs/tasks/done/define-analyzer-assisted-evaluation-contract.md`
**Reconciliation task**: `docs/tasks/current/reconcile-evaluation-contract-readiness-docs.md`
**Status**: Complete (infrastructure implemented; experiment execution blocked)

## What was defined

The evaluation contract for the four-condition analyzer-assisted experiment,
as specified in `docs/plans/analyzer-assisted-agent-architecture.md` Step 1.

### Deliverables

1. **Experiment manifest** (`benchmark/analyzer-assisted-v1/experiment.json`):
   defines four conditions (baseline, index-md, arch-query, combined) with
   stable IDs, access boundaries, artifact identity requirements, and
   explicit unavailable-condition handling for the three pending conditions.

2. **Result schema** (`benchmark/analyzer-assisted-v1/result_schema.json`):
   extends the v1 result format with condition identity, artifact provenance,
   question metadata (category, difficulty, scope), telemetry, context fetch
   metrics, and failure classification vocabulary.

3. **Validation module** (`benchmark/analyzer-assisted-v1/validate.py`):
   deterministic validation for manifest and result records. Rejects unknown
   condition IDs, missing provenance, invalid failure classifications,
   negative telemetry, and unavailable conditions claiming success.

4. **Focused tests** (`tests/test_analyzer_assisted_evaluation.py`):
   52 tests covering manifest validation, result validation, all four
   conditions, unavailable condition fixtures, classified failure fixtures,
   v1 compatibility, and constant consistency.

### Design decisions

- The new evaluation infrastructure lives in `benchmark/analyzer-assisted-v1/`
  alongside the existing `benchmark/consumer-v1/` harness, preserving the v1
  harness untouched.
- Unavailable conditions are explicitly represented with `available: false`,
  `status: "pending"`, and `unavailable_reason` — they cannot silently fall
  back to baseline.
- Six failure classifications are defined: `stale-context`, `missing-context`,
  `retrieval-failure`, `unsupported-inference`, `scoring-defect`, and
  `infrastructure-failure`.
- Context metrics (useful reads, navigation reads, queries issued) default to
  null until OTel instrumentation is wired.
- The result schema requires provenance (architecture SHA, corpus version,
  manifest version) for every result.

## What has been implemented since this contract was defined

The following concerns from the original handoff boundary have been
resolved by subsequent tasks:

| Concern | Evidence |
|---------|----------|
| Adapt `run_evaluation.py` for multi-condition execution | `consumer-v1/run_evaluation.py` now imports `planner.py` and supports condition-aware execution with per-condition tool permissions and artifact paths |
| Generate INDEX.md | `benchmark/analyzer-assisted-v1/INDEX.md` materialized from arch-query JSON (69 components, format v1, validated provenance) |
| Implement arch-query queries | `arch-query` CLI built with approved subcommands; evaluator guard constrains Bash transport |
| Context telemetry collection | `lib/context_telemetry.py` (CONTRACT_VERSION 1.0.0) records reads, queries, denials, and context-quality signals; `result_schema.json` declares `context_provenance` |
| All four conditions available | `experiment.json` manifest v1.3.0; all conditions `status: "available"` |
| Canary readiness validation | `canary_report.py` validates telemetry attachment, no-fallback, and provenance requirements |

## What remains NOT done (experiment execution blockers)

The following are required before any paid or full-corpus evaluation is
launched. These are infrastructure-readiness and authorization gates, not
implementation gaps in the evaluation contract itself.

| Concern | Status | Dependency |
|---------|--------|------------|
| MLflow experiment tracking | Local validated; external server pending | `lib/mlflow_tracking.py` and `benchmark/analyzer-assisted-v1/track_experiment.py` provide versioned REST and local file-backed tracking. Local `MLFLOW_RUNS_DIR` mode validated end-to-end (preflight, dry-run, live tracking with read-back of experiment/run identity, tags, metrics, artifact refs, write confinement; 94 tests pass with `mlflow==2.22.0`). External server registration still requires `MLFLOW_TRACKING_URI` and a running MLflow server. |
| Root-cause / explanation classification | Proposal pipeline ready | `lib/failure_proposals.py` generates pending proposals from direct signals; human adjudication is required before promotion to authoritative classifications |
| External-fetch OTel span instrumentation | Local export ready; external producer pending | `JsonlFileExporter` provides opt-in OTel-compatible local event export; `fetch-architecture-context.sh` is not in this repository, so end-to-end fetch spans remain unavailable |
| Populate context metrics from OTel spans | Blocked | Depends on external-fetch OTel instrumentation above |
| Run a full-corpus paid evaluation | Blocked | Requires MLflow, explanation pipeline, OTel instrumentation, and explicit user authorization stating expected cost and duration |

## Validation results

- Experiment manifest v1.3.0: all four conditions available, six failure
  classifications, no validation errors.
- Result schema declares `context_provenance` (CONTRACT_VERSION 1.0.0)
  and `context_metrics` with per-event telemetry.
- Context telemetry collector (`lib/context_telemetry.py`) implemented;
  canary report (`canary_report.py`) validates telemetry attachment and
  provenance requirements.
- Pinned INDEX.md artifact: 69 components, format v1, validated provenance.
- Existing v1 corpus, schema, raw results, and scored results: untouched
  and still parseable.
- No paid or full-corpus evaluation was run.
- No artifacts, metrics, or scores were fabricated.

### Known gap: corpus below minimum question count

The v1 corpus currently contains 37 questions (Tier 1: 10, Tier 2: 10,
Tier 3: 9, Tier 4: 8). The v1 schema requires `minItems: 40` and
`validate.py` requires exactly 10 per tier. Running
`python3 benchmark/consumer-v1/validate.py` reports 3 errors (schema minItems,
Tier 3, Tier 4, and total count).

This is a pre-existing condition — the 3 missing questions (INTG-006,
NAV-003, NAV-006) were removed or never authored during ground-truth auditing
after the v1-ab evaluation run. The schema and validator intentionally
preserve the 40-question / 10-per-tier contract; the corpus will pass
validation once the missing questions are authored against verified evidence.
