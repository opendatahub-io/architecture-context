# Pin INDEX.md Experiment Artifact — Ledger Note

## Artifact

- **Path**: `benchmark/analyzer-assisted-v1/INDEX.md`
- **Platform/version**: rhoai-3.5
- **Components**: 69
- **Source revision**: `56eb7ab043e99c8e00f91f2903d2ed625e694049`
- **Format version**: 1
- **arch-query format version**: 2
- **Materializer**: `benchmark/analyzer-assisted-v1/materialize_index.py`
  (format version 1, deterministic — two sequential generations produce
  identical output)

## Manifest

- **Version**: 1.1.0 → 1.2.0
- **Experiment**: `analyzer-assisted-retrieval-v1`
- Artifact metadata in separate `index_artifact` section (not inside
  `artifact_identity`) to avoid requiring callers to supply metadata fields.

## Condition Status

| Condition | Status | Notes |
|-----------|--------|-------|
| baseline | available | Unchanged |
| index-md | available | Enabled with explicit artifact identity and path |
| arch-query | available | Unchanged |
| combined | pending | Requires explicit index+query pairing; not yet enabled |

Three conditions available, one pending. No condition falls back silently.

## Validation

- **Focused tests**: 344 passed
- **Pre-existing failures** (3, outside this task):
  - `tests/test_architecture_baseline.py::test_rhoai_next_kueue_is_a_valid_baseline_fixture`
  - `tests/test_distribution.py::test_static_analysis_uses_shared_distribution_resolver`
  - `tests/test_validate_architecture.py::test_validator_rejects_incomplete_crd_identity`
- **Manifest validation**: PASS (3 available, 1 pending)
- **Canary validation**: PASS (no violations)
- **Ruff lint**: PASS
- **`git diff --check`**: PASS
- **Go tests**: PASS (diff, index, overlay, query)
- **Determinism**: PASS (two sequential materializations produce byte-identical output)

## Evaluation Evidence

None. No evaluation, agent, or paid call was run. Estimated cost: $0.00.

## Task Reference

- Task: `docs/tasks/done/pin-index-experiment-artifact.md`
- Related: `docs/notes/materialize-index-evaluation-artifact.md`
