# Task: Pin an INDEX.md Artifact for the Experiment

## Goal

Materialize one reproducible `INDEX.md` artifact from the current architecture
snapshot and enable only the `index-md` experiment condition against that
explicit artifact.

## Scope

- Build/use the existing `arch-query index` command and
  `benchmark/analyzer-assisted-v1/materialize_index.py` to create a committed,
  versioned benchmark artifact with source and format provenance.
- Update the experiment manifest, planner tests, README, and canary expectations
  so `index-md` is available only with the pinned artifact identity/path.
- Keep `combined` pending until index plus query are explicitly paired; preserve
  baseline/arch-query behavior and no-silent-fallback rules.
- Add focused validation, ledger note, and scoped commit; do not run evaluation.

## Negative controls

- Do not hand-edit architecture facts, overlays, query implementation, or run
  paid/full-corpus/external evaluations.
- Do not claim an artifact is current without recording its source revision.

## Acceptance criteria

- [x] A committed deterministic INDEX.md artifact validates and records source,
  architecture, query-format, and materializer provenance.
- [x] Only `index-md` becomes available with an explicit artifact identity/path;
  combined remains pending and no condition falls back silently.
- [x] Focused tests/validators/docs/ledger updates pass and a scoped commit is
  created without evaluation execution.

## Implementation notes

- INDEX.md artifact: `benchmark/analyzer-assisted-v1/INDEX.md` (69 components,
  rhoai-3.5, source revision `56eb7ab0`, format_version=1,
  arch_query_format_version=2)
- Determinism verified: two sequential generations produce identical output
- Manifest version: 1.1.0 → 1.2.0
- Condition status: 3 available (baseline, index-md, arch-query), 1 pending (combined)
- Artifact metadata in separate `index_artifact` section (not in `artifact_identity`)
  to avoid requiring callers to supply metadata fields
- 344 focused tests pass; 3 pre-existing failures unrelated to changes:
  - `tests/test_architecture_baseline.py::test_rhoai_next_kueue_is_a_valid_baseline_fixture`
  - `tests/test_distribution.py::test_static_analysis_uses_shared_distribution_resolver`
  - `tests/test_validate_architecture.py::test_validator_rejects_incomplete_crd_identity`
- Manifest validation: PASS (3 available, 1 pending)
- Canary validation: PASS (no violations)
- Ruff lint: PASS
- `git diff --check`: PASS
- Go tests: PASS (diff, index, overlay, query)
- Artifact/materializer determinism: PASS (two sequential generations produce identical output)

## Status

Accepted in scoped commit `b526ef4c`. All acceptance criteria met; no
evaluation executed. Ledger note:
`docs/notes/pin-index-experiment-artifact.md`.
