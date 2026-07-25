# Task: Materialize the INDEX.md Evaluation Artifact

## Goal

Complete the next safe Phase 2 step by producing a deterministic, provenance-
carrying `INDEX.md` artifact that the analyzer-assisted evaluator can expose
only for the opt-in `index-md` condition.

## Scope

- Inspect the existing `arch-query index` contract and evaluator condition
  plumbing; choose the narrowest reproducible way to materialize an
  `INDEX.md` from available architecture data without hand-editing generated
  architecture facts.
- Add an explicit artifact-generation/validation path with stable ordering,
  source revision, format version, and applicable architecture version.
- Extend planner/dry-run provenance and the evaluator read boundary so
  `index-md` can be planned only with a valid in-tree or explicitly staged
  index artifact; do not silently fall back to baseline.
- Keep `combined` pending until this artifact and its query pairing are both
  proven; do not run an evaluation.
- Add focused tests, documentation, task note, session entry, and PLAN update.

## Negative controls

- Do not modify generated component facts, overlays, query implementation, or
  production architecture output; do not invent aliases or index contents.
- Do not mark `combined` available, launch agents, or run paid/full-corpus or
  external evaluations.
- Do not broaden source reads or permit arbitrary Bash; preserve the existing
  guarded baseline/query boundaries.

## Acceptance criteria

- [x] Deterministic `INDEX.md` materialization and schema/provenance validation
  are implemented with missing/incompatible input outcomes explicit.
- [x] `index-md` dry-run/planner/evaluator boundaries require and record the
  index artifact identity; unavailable artifacts never fall back silently.
- [x] Existing baseline and arch-query behavior remains compatible; combined
  remains pending.
- [x] Focused tests, validators, docs, ledger updates, and scoped commit are
  recorded without running an evaluation.

## Status

Accepted.

## Implementation Notes

### Deliverables

1. **Materializer** (`benchmark/analyzer-assisted-v1/materialize_index.py`):
   renders deterministic INDEX.md from `arch-query index` JSON with
   machine-readable provenance header (format_version, arch_query_format_version,
   version, source_revision, component_count). CLI supports `--input`,
   `--output`, `--source-revision`, and `--validate` modes.

2. **Planner extension** (`benchmark/analyzer-assisted-v1/planner.py`):
   `plan_condition()` now accepts `index_artifact_path`. Available `index-md`
   and `combined` conditions require, locate, and validate the artifact.
   Pending conditions skip validation. CLI gains `--index-artifact-path`.

3. **Evaluator extension** (`benchmark/consumer-v1/run_evaluation.py`):
   `_EvalGuard` accepts `index_path` and allows reads of the configured
   INDEX.md alongside the architecture tree. Telemetry records
   `index_artifact_path`. Runner CLI gains `--index-artifact-path` and
   passes it through to the planner.

4. **Focused tests** (`tests/test_materialize_index.py`): 64 tests covering
   materialization (rendering, determinism, errors), validation, header
   parsing, CLI, planner integration (path required, missing file, invalid
   artifact, valid artifact, baseline/arch-query unchanged), evaluator guard
   (index read allowed, outside denied, telemetry), runner CLI dry-run, and
   real manifest integration.

5. **Existing test update** (`tests/test_analyzer_assisted_planner.py`):
   `test_accept_complete_index_md_identity` updated to supply a valid
   INDEX.md artifact when making `index-md` available.

### Validation evidence

- 341 focused tests passed (64 new + 277 existing)
- ruff lint: all checks passed
- Baseline and arch-query conditions unchanged
- Combined remains pending
- No evaluation, agent, or paid call was run
