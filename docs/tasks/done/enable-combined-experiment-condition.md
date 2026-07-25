# Task: Enable the Combined INDEX.md + arch-query Condition

## Goal

Enable the combined analyzer-assisted experiment condition only when the
pinned INDEX.md artifact and the reviewed arch-query artifact are both
explicitly identified and validated.

## Scope

- Update `benchmark/analyzer-assisted-v1/experiment.json` and canary metadata
  so `combined` is available with separate index/query provenance requirements.
- Extend planner/runner tests and provenance output to require both artifact
  identities and the pinned index path; preserve the index-only and query-only
  boundaries and no-silent-fallback behavior.
- Document the combined read/query boundary and validate that Bash remains
  restricted to approved arch-query commands while INDEX.md is read-only.
- Add focused validation, ledger note, and scoped commit; do not run evaluation.

## Negative controls

- Do not run paid/full-corpus/external evaluations or modify architecture facts,
  overlays, query implementation, or generated component output.
- Do not broaden Bash/source access or claim combined scores/rollout success.

## Acceptance criteria

- [x] Combined requires and records both validated index and query provenance;
  missing either artifact is an explicit planning failure.
- [x] Baseline, index-md, and arch-query behavior remain compatible; no
  condition silently falls back, and combined canary accounting is accurate.
- [x] Focused tests, validators, docs, ledger updates, and scoped commit pass
  without evaluation execution.

## Status

Accepted. Combined condition enabled with both index and query provenance
requirements. Manifest version bumped to 1.3.0. All four conditions now
available. 353 focused tests passing. Manifest, canary, and artifact validators
PASS. No evaluation executed. Task note:
`docs/notes/enable-combined-experiment-condition.md`.
