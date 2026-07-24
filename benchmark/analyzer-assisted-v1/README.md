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
├── result_schema.json       # JSON Schema for individual result records
└── validate.py              # Manifest and result validation
```

## Four-Condition Experiment

The experiment compares four retrieval conditions against the consumer-v1
corpus (40 questions, 4 tiers):

| Condition ID  | Status    | Context Sources                          |
|---------------|-----------|------------------------------------------|
| `baseline`    | Available | Architecture docs only (Read/Glob/Grep)  |
| `index-md`    | Pending   | Docs + generated INDEX.md                |
| `arch-query`  | Pending   | Docs + arch-query CLI queries            |
| `combined`    | Pending   | Docs + INDEX.md + arch-query             |

Only `baseline` is currently available. The other three conditions are
explicitly recorded as pending with their blocking dependencies documented
in the manifest. Unavailable conditions must not be silently substituted
with baseline.

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

## Handoff Boundary

This contract defines **what to measure** and **how to record it**. The
following are explicitly out of scope and belong to follow-on tasks:

| Concern                          | Follow-on Task                                  |
|----------------------------------|------------------------------------------------|
| Runner execution of conditions   | Adapt `run_evaluation.py` for multi-condition  |
| INDEX.md generation              | Phase 2 of analyzer-assisted architecture plan |
| arch-query query interface       | Phase 3 of analyzer-assisted architecture plan |
| OTel span instrumentation        | Instrument context fetches/reads with OTel     |
| Full-corpus or paid evaluation   | Run after conditions become available          |
| Context metric population        | After OTel instrumentation is wired            |

## Versioning

The manifest uses `manifest_version` (semver):

- **Patch**: fix a description or metadata field
- **Minor**: add a failure classification or context metric
- **Major**: add/remove/rename a condition ID or change the result schema
  in a backward-incompatible way

The result schema uses `schema_version` (semver), tracked separately.
