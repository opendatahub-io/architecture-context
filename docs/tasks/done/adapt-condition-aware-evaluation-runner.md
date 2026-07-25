# Task: Adapt the Evaluation Runner to the Condition Contract

## Goal

Connect the analyzer-assisted experiment manifest to a deterministic,
condition-aware evaluation planning layer without running paid or full-corpus
agent evaluations.

## Scope

- Add a small manifest loader/planner under `benchmark/analyzer-assisted-v1/`
  that validates condition IDs, availability, access boundaries, artifact
  identity requirements, and requested question subset.
- Adapt or wrap `benchmark/consumer-v1/run_evaluation.py` so a condition can be
  selected explicitly and unavailable conditions produce an explicit
  `condition_unavailable` plan/result rather than silently falling back.
- Preserve existing consumer-v1 invocation and result compatibility; do not
  change existing raw results or launch agents by default.
- Add a deterministic `--dry-run`/plan output recording condition, corpus
  subset, artifact provenance requirements, access boundary, and reason for
  unavailable conditions.
- Add focused tests for available baseline planning, pending index/query/
  combined conditions, unknown conditions, stable ordering, and no fallback.

## Negative controls

- Do not run paid, full-corpus, or external-agent evaluations.
- Do not fabricate artifact revisions, scores, telemetry, or condition results.
- Do not generate INDEX.md, alter arch-query behavior, modify generated
  architecture output, or change analyzer facts/overlays.

## Acceptance criteria

- [x] Manifest-driven planning is deterministic and validates requested
  condition/subset/provenance inputs.
- [x] Pending conditions are explicit and cannot silently execute as baseline.
- [x] Baseline planning remains compatible with the existing consumer-v1
  runner, while execution is opt-in and dry-run is safe.
- [x] Focused tests, lint, task note, session log, PLAN, and accepted scoped
  commit are recorded.

## Status

Implementation complete; accepted after focused review and validation.
