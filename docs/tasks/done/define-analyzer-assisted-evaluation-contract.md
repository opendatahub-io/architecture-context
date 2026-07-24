# Task: Define Analyzer-Assisted Evaluation Contract

## Goal

Define a reproducible evaluation manifest and result schema for the
analyzer-assisted architecture experiment. This is the instrumentation
baseline for comparing the existing retrieval paths before implementing new
query or synthesis behavior.

## Context

`docs/plans/analyzer-assisted-agent-architecture.md` requires a four-condition
experiment:

1. baseline context;
2. generated `INDEX.md` context;
3. `arch-query` context;
4. combined index plus query context.

The repository already has a consumer benchmark harness under
`benchmark/consumer-v1/`, but its current model is a two-tree A/B comparison.
Extend the evaluation contract around that infrastructure without running a
full-corpus or paid experiment in this task.

## Inputs

- `docs/plans/analyzer-assisted-agent-architecture.md`
- `benchmark/consumer-v1/corpus.json`
- `benchmark/consumer-v1/schema.json`
- `benchmark/consumer-v1/run_evaluation.py`
- `benchmark/consumer-v1/score_results.py`
- `benchmark/consumer-v1/generate_report.py`
- Existing v1 baseline and evaluation notes in `docs/notes/`

## Work

### 1. Define the experiment manifest

Add a versioned, machine-readable manifest describing the four conditions and
their permitted context sources/tools. Each condition must have a stable ID,
human description, source revision or artifact identity, and explicit access
boundary. Do not claim that an index or query condition exists unless its
artifact is available; represent unavailable conditions as pending rather than
silently substituting another condition.

### 2. Define question and result metadata

Extend the benchmark schema or add a companion schema so each evaluation can
record, at minimum:

- question ID, category, difficulty, and required scope;
- condition ID and context/artifact revision;
- model, seed, timestamp, and runner version;
- response, source citations, files read, queries issued, and token/cost/time
  telemetry;
- context fetches, useful reads, navigation reads, missing/stale context, and
  unsupported-inference indicators when available;
- one or more failure classifications: `stale-context`, `missing-context`,
  `retrieval-failure`, `unsupported-inference`, `scoring-defect`, or
  `infrastructure-failure`.

Preserve compatibility with existing v1 raw and scored result files.

### 3. Add validation and fixtures

Add deterministic validation for manifest and result records, including rejection
of unknown condition IDs, missing provenance, invalid failure classes, and
negative telemetry values. Add a minimal fixture covering all four conditions,
an explicit unavailable condition, a successful result, and a classified
failure. Do not fabricate benchmark scores or telemetry.

### 4. Document the handoff boundary

Document which follow-on task will adapt the runner to execute conditions and
which task will add OTel spans. This task defines the contract; it does not
implement query retrieval, agent synthesis, source inspection, or full-corpus
execution.

## Negative Controls

- Do not run a paid or full-corpus production evaluation.
- Do not treat the existing tree-A/tree-B comparison as the four-condition
  experiment.
- Do not invent index/query artifacts, source revisions, measurements, or
  quality scores.
- Do not allow a missing condition to fall back silently to baseline.
- Do not weaken existing v1 schema validation or reinterpret existing scores.

## Likely Files

- `benchmark/analyzer-assisted-v1/experiment.json` or an equivalent manifest
  location justified by the repository layout;
- `benchmark/consumer-v1/schema.json` and/or a new result schema;
- `benchmark/consumer-v1/validate.py`;
- focused tests under `tests/` or `benchmark/consumer-v1/`;
- `benchmark/consumer-v1/README.md`;
- a validation note under `docs/notes/`.

## Acceptance Criteria

- [x] A versioned manifest defines all four condition IDs, access boundaries,
  provenance requirements, and unavailable-condition handling.
- [x] The result contract records question metadata, condition identity,
  artifact/context provenance, telemetry, and failure classification.
- [x] Existing v1 raw and scored results still validate and score unchanged.
- [x] Invalid condition IDs, missing provenance, invalid classifications, and
  negative telemetry are rejected deterministically.
- [x] Fixtures and tests cover all four conditions, unavailable conditions,
  successful results, and classified failures.
- [x] No query, synthesis, source-read, full-corpus, or paid run is performed.
- [x] README and a validation note document the contract and follow-on tasks.
- [x] The task is moved to `docs/tasks/done/` and `PLAN.md` is reconciled.

## Status

Done. Completed 2026-07-24.
