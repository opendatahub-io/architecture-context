# Enable the Combined INDEX.md + arch-query Condition

## Summary

Enabled the combined experiment condition in `benchmark/analyzer-assisted-v1/experiment.json`,
completing the four-condition analyzer-assisted evaluation design. The combined condition
requires both a validated pinned INDEX.md artifact and explicit arch-query binary provenance;
missing either artifact is an explicit planning failure with no silent fallback.

## Manifest

Experiment manifest version bumped from 1.2.0 to **1.3.0**. All four conditions
(baseline, index-md, arch-query, combined) are now `available: true`.

Canary manifest `experiment_ref.manifest_version` updated to 1.3.0. All four
`condition_ids` are present (40 planned cells: 10 questions × 4 conditions,
0 unavailable).

## Provenance Requirements

The combined condition requires **two** validated provenance identities:

| Identity | Field | Source |
|----------|-------|--------|
| Index generation | `index_revision_source` | `index_generation_sha` — pinned INDEX.md materializer commit |
| Query binary | `query_binary_version` | `git_sha` — arch-query binary build commit |

Both identities are recorded in `artifact_identity` with type
`architecture-tree-with-index-and-query`. The planner validates both are present;
a missing identity produces an explicit planning failure.

## Pinned INDEX.md Artifact

The combined condition carries an `index_artifact` section identical to the
index-md condition:

- **Path**: `benchmark/analyzer-assisted-v1/INDEX.md`
- **Format version**: 1
- **Architecture version**: rhoai-3.5
- **Source revision**: `56eb7ab0`
- **Component count**: 69

The evaluator guard validates the artifact path exists, headers parse, format
version matches, and component count is correct before allowing reads.

## Access Boundaries

| Boundary | Constraint |
|----------|------------|
| **Bash** | Permitted only as a transport for constrained `arch-query query` invocations. Guard validates: no shell metacharacters, bare `arch-query query <subcommand>`, approved subcommand set, explicit `-o json`, `--base-dir` inside the evaluated tree. All other Bash commands are denied. |
| **INDEX.md** | Read-only. Agent may read the pinned artifact path but may not write or modify it. |
| **Architecture tree** | Read-only via Read, Glob, Grep. No writes. |
| **Denied tools** | Write, Edit — same as arch-query condition. |

## Validation

### Test suite

353 focused tests across 5 test files:

- `tests/test_analyzer_assisted_evaluation.py` — evaluator boundary and guard behavior
- `tests/test_analyzer_assisted_planner.py` — planner provenance and artifact validation
- `tests/test_canary_report.py` — canary readiness and cell accounting
- `tests/test_condition_aware_runner.py` — runner no-fallback and condition dispatch
- `tests/test_materialize_index.py` — INDEX.md materialization and provenance headers

### Validators

| Validator | Result |
|-----------|--------|
| Manifest validation | PASS — 4 available, 0 pending |
| Canary report | PASS — 40 planned, 0 unavailable, no violations |
| Artifact provenance | PASS — both index and query identities validated |
| Ruff lint | PASS |
| `git diff --check` | PASS |
| Go tests | PASS |

### Explicit missing-artifact failures

- Combined plan with missing `index_revision_source` → explicit planning failure
- Combined plan with missing `query_binary_version` → explicit planning failure
- Combined plan with missing/invalid INDEX.md artifact → explicit planning failure
- No condition silently falls back to baseline

## Negative Controls

- No evaluation, agent, or paid call was executed
- No architecture facts, overlays, query implementation, or generated output modified
- No Bash/source access broadened
- No combined scores or rollout success claimed
- Baseline, index-md, and arch-query behavior preserved and independently tested

## Estimated Cost

$0.00 — bookkeeping and documentation only; no evaluation or paid calls.
