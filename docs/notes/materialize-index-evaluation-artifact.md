# Materialize the INDEX.md Evaluation Artifact

## Summary

Deterministic INDEX.md materialization from `arch-query index` JSON output,
with provenance validation and planner/evaluator path boundary enforcement
for the `index-md` experiment condition.

## Materializer

`benchmark/analyzer-assisted-v1/materialize_index.py` renders a
provenance-carrying Markdown artifact with stable alphabetical ordering.
The machine-readable header contains `format_version`,
`arch_query_format_version`, `version`, `source_revision`, and
`component_count`. CLI supports `--input`, `--output`, `--source-revision`,
and `--validate` modes. Validation rejects missing headers, wrong format
versions, and component count mismatches.

## Provenance Header and Validation

Every materialized INDEX.md carries a provenance header that records the
exact format version, architecture version, source revision, and component
count at generation time. The `--validate` mode re-parses and checks all
header fields against the document body, ensuring determinism:
re-generation from identical input produces byte-identical output.

## Planner/Evaluator Path Boundary

- **Planner** (`benchmark/analyzer-assisted-v1/planner.py`):
  `plan_condition()` accepts `index_artifact_path`. Available `index-md`
  and `combined` conditions require, locate, and validate the artifact.
  Pending conditions skip validation. CLI gains `--index-artifact-path`.

- **Evaluator** (`benchmark/consumer-v1/run_evaluation.py`):
  `_EvalGuard` accepts `index_path` and allows reads of the configured
  INDEX.md alongside the architecture tree. Telemetry records
  `index_artifact_path`. Runner CLI gains `--index-artifact-path` and
  passes it through to the planner.

Unavailable artifacts never fall back silently to baseline; the planner
raises an explicit error if a required artifact is missing or invalid.

## Pending Conditions

`index-md` and `combined` remain pending because no INDEX.md artifact is
staged in the experiment manifest. The materializer and validation
infrastructure are in place, but the condition cannot become available
until a validated artifact is committed and referenced from the manifest.

## Validation Results

- 341 focused tests passed (64 new + 277 existing)
- Experiment manifest validation: PASS
- Canary report: PASS
- Ruff lint: all checks passed
- `git diff --check`: passed

## No-Evaluation Evidence

No evaluation, agent, or paid call was run. No existing results were
modified. Baseline and `arch-query` conditions remain unchanged.
Estimated cost: $0.00.
