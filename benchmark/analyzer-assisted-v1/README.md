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
corpus (40 active questions across 4 tiers; contract target met):

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

## Failure-Classification Proposals

The proposal pipeline (`lib/failure_proposals.py`) generates reviewable,
non-authoritative proposals from validated result records. Proposals are
**not** authoritative classifications — they require human adjudication
before any recorded `failure_classifications` field is changed.

Key distinctions:

| Concept                     | Source                          | Authority  |
|-----------------------------|---------------------------------|------------|
| `failure_classifications`   | `result_schema.json` field      | Authoritative (after human review) |
| Proposal `proposed_category`| `proposal_schema.json` artifact | Pending — never auto-promoted |
| Recorded classifications    | Preserved as proposal annotations | Unchanged by proposals |

Classification rules (direct signals only):

- `response.success=false` or `response.error` → `infrastructure-failure`
- Explicit `stale_context_detected` telemetry/event → `stale-context`
- Explicit `missing_context_detected` telemetry/event → `missing-context`
- Explicit `unsupported_inference_detected` telemetry/event → `unsupported-inference`
- No direct signal → `unresolved` (never infers retrieval-failure or scoring-defect)

```bash
# Generate proposals from result records
python3 -m lib.failure_proposals results.json -o proposals.json

# Generate and validate against schema
python3 -m lib.failure_proposals results.json --validate
```

Schema: `proposal_schema.json` (version 1.0.0).

## Validation

```bash
# Validate the experiment manifest
python3 benchmark/analyzer-assisted-v1/validate.py

# Run focused tests
uv run pytest tests/test_analyzer_assisted_evaluation.py tests/test_failure_proposals.py -v
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
| OTel-compatible local event export | `JsonlFileExporter` with `CONTEXT_TELEMETRY_JSONL_PATH`; opt-in, bounded, failure-tolerant JSONL |
| Result schema with provenance     | `result_schema.json` declares `context_provenance` and `context_metrics` |
| Canary readiness validator        | `canary_report.py` validates telemetry, no-fallback, and provenance |
| Condition-aware planning          | `planner.py` resolves artifact paths and access boundaries per condition |
| MLflow tracking adapter           | `lib/mlflow_tracking.py` (TRACKING_CONTRACT_VERSION 1.0.0); maps results to MLflow runs via stdlib REST or local file-backed `MLFLOW_RUNS_DIR` |
| MLflow tracking CLI               | `track_experiment.py` supports `--dry-run`, `--preflight`, and live tracking |
| Local file-backed tracking        | Validated: `MLFLOW_RUNS_DIR` preflight, dry-run (no writes), live tracking with read-back of experiment/run identity, tags, metrics, artifact references, and write confinement |

### Remaining Blockers — Experiment Execution

The infrastructure above is necessary but not sufficient to run the
experiment. The following gates must be satisfied before any paid or
full-corpus evaluation is launched:

| Blocker                                   | Status           | Detail                                              |
|-------------------------------------------|------------------|------------------------------------------------------|
| MLflow experiment tracking                | Local validated; external server pending | Tracking adapter and CLI implemented (`lib/mlflow_tracking.py`, `track_experiment.py`). Local file-backed mode (`MLFLOW_RUNS_DIR`) validated end-to-end: preflight, dry-run (no writes), live tracking, read-back, and write confinement. No external MLflow experiment has been registered — requires `MLFLOW_TRACKING_URI` and a running server. See **MLflow Tracking Integration** below. |
| Root-cause / explanation classification   | Adjudication template ready; human adjudication pending | `lib/failure_proposals.py` generates pending proposals from direct signals. `benchmark/consumer-v1/adjudication_template.json` v0.1.0: 35 proposals, all `human_category: null`, all `proposed_category: "unresolved"`. Validator: `validate_adjudication.py` (44 tests). Human adjudication required before promotion to authoritative classifications. |
| LLM-as-judge calibration                  | Calibration template ready; human labeling pending | `benchmark/consumer-v1/calibration_template.json` v0.1.0: 24 questions (6/tier, 4 answerable-as-gap), all `human_label: null`. Validator: `validate_calibration.py` (49 tests). Human semantic-match labeling and user authorization required for judge execution. |
| External-fetch OTel span instrumentation  | Local export ready; external producer pending | `JsonlFileExporter` exports local events; `fetch-architecture-context.sh` is not in this repository, so end-to-end fetch spans remain unavailable |
| User authorization                        | Required         | No paid or full-corpus evaluation may be launched without explicit user authorization, stating expected cost and duration |

## MLflow Tracking Integration

The tracking adapter (`lib/mlflow_tracking.py`) and CLI
(`track_experiment.py`) implement the integration boundary for
recording experiment results in MLflow. Two backends are supported:

1. **REST mode** (`MLFLOW_TRACKING_URI`): uses stdlib HTTP to talk to
   an external MLflow tracking server. No `mlflow` SDK dependency.
2. **Local file-backed mode** (`MLFLOW_RUNS_DIR`): uses the MLflow SDK
   `MlflowClient` to write experiments and runs to a local directory.
   No external server required. The SDK (`mlflow==2.22.0`) is pinned
   only in the task container (`scripts/Dockerfile.claude`).

When both `MLFLOW_RUNS_DIR` and `MLFLOW_TRACKING_URI` are set, local
mode takes precedence.

This is distinct from the external registration step (creating an
MLflow experiment on a running server) and the authorization gate
(user approval for paid evaluation).

### What is implemented

- **Adapter**: Maps validated result records to MLflow experiment/run
  metadata via stdlib REST or the local file-backed `MlflowClient`.
- **Deterministic tags**: Condition identity, provenance SHAs, corpus
  version, failure classifications, and tracking contract version.
- **Metrics**: Telemetry (duration, tokens, cost, turns), tool call
  counts, context metrics (fetches, useful reads, navigation reads,
  queries).
- **Artifact references**: Logged as run tags referencing architecture
  context SHA, index generation SHA, query binary version, and source
  citations. No artifact uploads.
- **Dry-run mode**: `--dry-run` reports exact tags, metrics, and
  artifact references that would be logged without any writes.
- **Preflight**: `--preflight` checks configuration, directory
  validity (local) or server reachability (REST), reports required
  fields, and never creates external state.
- **Path safety**: `MLFLOW_RUNS_DIR` rejects path traversal, symlinks
  outside the parent, non-directory targets, and non-writable paths.
- **Local tracking validated**: Preflight, dry-run (no local-store
  writes), live tracking, and read-back of experiment/run identity,
  tags (9 verified), metrics (12 verified), artifact references (4
  verified), and write confinement all pass with `mlflow==2.22.0`.

### What is NOT implemented

- No MLflow experiment has been created on any external server.
- No evaluation results have been logged.
- External server registration requires `MLFLOW_TRACKING_URI` and a
  running MLflow server.
- **User authorization is still required** before launching any paid
  or full-corpus evaluation.

### Usage

```bash
# Preflight check (no network required with --dry-run)
python3 benchmark/analyzer-assisted-v1/track_experiment.py --preflight --dry-run

# Dry-run: show what would be logged
python3 benchmark/analyzer-assisted-v1/track_experiment.py \
    --dry-run --result-file path/to/result.json

# Live local tracking (no server required)
MLFLOW_RUNS_DIR=/tmp/mlflow-runs \
python3 benchmark/analyzer-assisted-v1/track_experiment.py \
    --result-file path/to/result.json

# Live tracking via external server
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
