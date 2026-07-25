# Task: Integrate Evaluation Context Telemetry

## Goal

Wire the existing versioned context telemetry collector into the consumer-v1
evaluation guard so reads, denials, and constrained queries populate the
experiment result’s `context_metrics` and remain OTel-exportable.

## Scope

- Add a collector to `_EvalGuard` and record useful/navigation/denied reads,
  allowed/denied queries, and index artifact access without changing tool
  permissions or agent behavior.
- Include deterministic `context_metrics` and serialized event/provenance data
  in per-tree telemetry and preserve baseline/query/index/combined compatibility.
- Use the existing optional OTel/no-op exporter; do not add mandatory runtime
  dependencies or run an evaluation.
- Add focused tests, docs/task note, session log, PLAN update, and scoped commit.

## Negative controls

- Do not alter condition availability, architecture facts, query semantics, or
  source-read boundaries; do not fabricate missing/stale/inference signals.
- Do not launch paid/full-corpus/external evaluations.

## Acceptance criteria

- [x] Guard events produce correct deterministic context metrics for baseline,
  index, query, and combined paths; denied operations are represented.
- [x] Optional OTel export remains non-blocking and no-op behavior works when
  the SDK is unavailable.
- [x] Existing focused tests/validators pass, telemetry schema compatibility is
  preserved, and ledger/commit evidence is recorded without evaluation.
- [x] Serialized context event/provenance data is attached to per-tree results
  via `context_provenance` key in both success and error return paths.
- [x] Condition-level `raw_results["provenance"]` includes `context_provenance`
  block with version and `events_attached_per_tree` flag.
- [x] End-to-end assertions verify `context_provenance` fields are present
  after guard activity for all four condition paths.

## Status

Accepted 2026-07-25. Implemented 2026-07-25. Refined 2026-07-25: wired
context_provenance into per-tree results and condition-level provenance.
Task note: `docs/notes/integrate-evaluation-context-telemetry.md`.

## Implementation Summary

Wired `ContextTelemetryCollector` into `_EvalGuard` with condition-aware
route labeling. Instrumented read/search/query/denial paths. Added
`context_metrics` to telemetry output and per-tree results. Added
`context_telemetry_version` to provenance. 40 focused tests in
`tests/test_eval_guard_telemetry.py`. 287 related focused tests passed,
Ruff clean, no evaluation run.

### Refinement: context_provenance wiring (2026-07-25)

Independent review found `context_provenance()` was implemented/tested but
never attached to actual per-tree results or raw-result provenance.

Changes:
- `run_question_against_tree()`: added `context_provenance: guard.context_provenance()`
  to both success (line ~581) and error (line ~555) return dicts.
- `run_evaluation()`: added `context_provenance` block to condition-level
  `raw_results["provenance"]` with `context_telemetry_version` and
  `events_attached_per_tree: True`.
- Added `TestContextProvenanceInResults` class (7 tests) covering baseline,
  index, query, combined, denied activity, metrics consistency, and empty guard.
- Total: 40 focused tests pass, ruff clean, result schema intact, no evaluation run.
