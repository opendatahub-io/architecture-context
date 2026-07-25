# Analyzer-Assisted Evaluation Contract v1

Defines the experiment manifest and result schema for comparing retrieval
paths in the analyzer-assisted architecture experiment. This is the
instrumentation baseline — it defines what to measure and how to record it,
without implementing query retrieval, synthesis, or full-corpus execution.

## Structure

```
benchmark/analyzer-assisted-v1/
├── README.md               # This file
├── experiment.json          # Four-condition experiment manifest
├── INDEX.md                 # Pinned index artifact for index-md condition
├── materialize_index.py     # INDEX.md materializer from arch-query JSON
├── result_schema.json       # JSON Schema for individual result records
├── track_experiment.py      # MLflow tracking CLI (dry-run / preflight / log)
└── validate.py              # Manifest and result validation
```

## Four-Condition Experiment

The experiment compares four retrieval conditions against the consumer-v1
corpus (32 active questions across 4 tiers; contract target is 40):

| Condition ID  | Status    | Context Sources                          |
|---------------|-----------|------------------------------------------|
| `baseline`    | Available | Architecture docs only (Read/Glob/Grep)  |
| `index-md`    | Available | Docs + generated INDEX.md                |
| `arch-query`  | Available | Docs + constrained arch-query CLI via Bash |
| `combined`    | Available | Docs + INDEX.md + arch-query             |

All four conditions are available. The `index-md` condition uses a pinned
INDEX.md artifact at `benchmark/analyzer-assisted-v1/INDEX.md` with
validated provenance (source revision, architecture version, format
version, component count). The `arch-query` condition uses Bash as a
transport but constrains it to the bare `arch-query query` command with
approved subcommands, explicit JSON output, and base-dir anchoring inside
the evaluated tree. Arbitrary shell commands, source file reads, and
writes are denied by the evaluator guard.

The `combined` condition requires both a validated pinned INDEX.md path
with provenance and explicit arch-query binary provenance. Missing either
artifact is a planning failure — the condition never silently falls back
to baseline or a partial retrieval path.

## Experiment Manifest

`experiment.json` defines:

- **Condition IDs**: stable identifiers for each retrieval condition.
- **Access boundaries**: which tools and files are permitted per condition.
- **Artifact identity**: what revisions (git SHA, index generation, query
  binary version) must be recorded for reproducibility.
- **Availability status**: whether each condition's artifacts exist.
- **Failure classifications**: the vocabulary for classifying incorrect
  answers (`stale-context`, `missing-context`, `retrieval-failure`,
  `unsupported-inference`, `scoring-defect`, `infrastructure-failure`).
- **Design constraints**: no silent fallback, provenance required, v1
  compatibility, no fabrication.

## Result Schema

`result_schema.json` extends the consumer-v1 raw result format with:

| Field                    | Description                                          |
|--------------------------|------------------------------------------------------|
| `condition_id`           | Which condition produced this result                 |
| `condition_available`    | Whether the condition was available for evaluation   |
| `question_category`      | Tier-derived category (inventory, component-facts…)  |
| `question_difficulty`    | Difficulty classification                            |
| `question_scope`         | Product/version scope                                |
| `provenance`             | Architecture SHA, index SHA, query version, corpus   |
| `telemetry`              | Duration, tokens, cost, turns, tool calls            |
| `context_metrics`        | Fetches, useful reads, navigation reads, queries     |
| `failure_classifications`| Zero or more from the defined vocabulary             |

All telemetry and context metric values must be non-negative when present;
null indicates the metric was not collected.

## Validation

```bash
# Validate the experiment manifest
python3 benchmark/analyzer-assisted-v1/validate.py

# Run focused tests
uv run pytest tests/test_analyzer_assisted_evaluation.py -v
```

The validation module (`validate.py`) rejects:

- Unknown condition IDs
- Missing provenance fields
- Invalid failure classifications
- Negative telemetry values
- Unavailable conditions that claim successful results
- Malformed question IDs
- Missing required manifest fields
- Duplicate condition IDs

## V1 Compatibility

The baseline condition is designed to produce results scoreable by the
existing `consumer-v1/score_results.py` pipeline without modification.
The v1 corpus, schema, raw results, and scored results are untouched by
this contract.

## Infrastructure Status

This contract defines **what to measure** and **how to record it**. The
following table distinguishes implemented infrastructure from remaining
blockers. No paid or full-corpus evaluation has been run.

### Implemented

| Capability                        | Evidence                                        |
|-----------------------------------|-------------------------------------------------|
| Four-condition experiment runner  | `consumer-v1/run_evaluation.py` supports condition-aware execution via `planner.py` |
| All four conditions available     | `experiment.json` manifest v1.3.0; all conditions `status: "available"` |
| Pinned INDEX.md artifact          | `benchmark/analyzer-assisted-v1/INDEX.md` with validated provenance (69 components, format v1) |
| arch-query CLI with evaluator guard | Constrained Bash transport; approved subcommands only |
| Context telemetry collector       | `lib/context_telemetry.py` (CONTRACT_VERSION 1.0.0); records reads, queries, denials, signals |
| Result schema with provenance     | `result_schema.json` declares `context_provenance` and `context_metrics` |
| Canary readiness validator        | `canary_report.py` validates telemetry, no-fallback, and provenance |
| Condition-aware planning          | `planner.py` resolves artifact paths and access boundaries per condition |
| MLflow tracking adapter           | `lib/mlflow_tracking.py` (TRACKING_CONTRACT_VERSION 1.0.0); maps results to MLflow runs via stdlib REST |
| MLflow tracking CLI               | `track_experiment.py` supports `--dry-run`, `--preflight`, and live tracking |

### Remaining Blockers — Experiment Execution

The infrastructure above is necessary but not sufficient to run the
experiment. The following gates must be satisfied before any paid or
full-corpus evaluation is launched:

| Blocker                                   | Status           | Detail                                              |
|-------------------------------------------|------------------|------------------------------------------------------|
| MLflow experiment tracking                | Adapter ready    | Tracking adapter and CLI implemented (`lib/mlflow_tracking.py`, `track_experiment.py`). No external MLflow experiment has been registered — requires `MLFLOW_TRACKING_URI` and a running server. See **MLflow Tracking Integration** below. |
| Root-cause / explanation classification   | Not configured   | No explanation pipeline; cannot attribute failures to stale context vs. hallucination vs. retrieval |
| External-fetch OTel span instrumentation  | Partial          | Context telemetry records reads/queries locally; no OTel spans on `fetch-architecture-context.sh` calls (cannot measure navigation-vs-content ratio across CI) |
| User authorization                        | Required         | No paid or full-corpus evaluation may be launched without explicit user authorization, stating expected cost and duration |

## MLflow Tracking Integration

The tracking adapter (`lib/mlflow_tracking.py`) and CLI
(`track_experiment.py`) implement the local integration boundary for
recording experiment results in MLflow. This is distinct from the
external registration step (creating an MLflow experiment on a running
server) and the authorization gate (user approval for paid evaluation).

### What is implemented

- **Adapter**: Maps validated result records to MLflow experiment/run
  metadata using stdlib HTTP only. No `mlflow` SDK dependency.
- **Deterministic tags**: Condition identity, provenance SHAs, corpus
  version, failure classifications, and tracking contract version.
- **Metrics**: Telemetry (duration, tokens, cost, turns), tool call
  counts, context metrics (fetches, useful reads, navigation reads,
  queries).
- **Artifact references**: Logged as run tags referencing architecture
  context SHA, index generation SHA, query binary version, and source
  citations. No artifact uploads.
- **Dry-run mode**: `--dry-run` reports exact tags, metrics, and
  artifact references that would be logged without any network access.
- **Preflight**: `--preflight` checks `MLFLOW_TRACKING_URI` presence
  and server reachability, reports required fields, and never creates
  external state.

### What is NOT implemented

- No MLflow experiment has been created on any external server.
- No evaluation results have been logged.
- `MLFLOW_TRACKING_URI` must be set and the server must be reachable
  before any tracking operation succeeds.
- **User authorization is still required** before launching any paid
  or full-corpus evaluation.

### Usage

```bash
# Preflight check (no network required with --dry-run)
python3 benchmark/analyzer-assisted-v1/track_experiment.py --preflight --dry-run

# Dry-run: show what would be logged
python3 benchmark/analyzer-assisted-v1/track_experiment.py \
    --dry-run --result-file path/to/result.json

# Live tracking (requires MLFLOW_TRACKING_URI and running server)
MLFLOW_TRACKING_URI=http://localhost:5000 \
python3 benchmark/analyzer-assisted-v1/track_experiment.py \
    --result-file path/to/result.json
```

## Versioning

The manifest uses `manifest_version` (semver):

- **Patch**: fix a description or metadata field
- **Minor**: add a failure classification or context metric
- **Major**: add/remove/rename a condition ID or change the result schema
  in a backward-incompatible way

The result schema uses `schema_version` (semver), tracked separately.
