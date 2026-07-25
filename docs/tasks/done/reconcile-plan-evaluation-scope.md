# Task: Reconcile Plan Evaluation Scope

## Goal

Make `docs/plans/analyzer-assisted-agent-architecture.md` accurately
distinguish externally reported feedback baselines from repository-backed
evaluation artifacts and current rollout gates.

## Scope

- Audit every numeric baseline and corpus claim in the architecture plan
  against durable repository artifacts.
- Clarify that the 94-question/84% figures are external historical feedback
  with no repository artifact; identify the canonical 32-active/40-contract
  corpus and unavailable execution evidence.
- Preserve plan goals, four-condition design, rollout gates, and external
  authorization requirements; do not invent scores or run evaluation.

## Acceptance criteria

- [x] Every baseline/corpus number in the architecture plan has an explicit
  source and status (repository artifact, external feedback, or unavailable).
- [x] The implementation sequence and success criteria remain actionable and
  state which gates cannot be evaluated until authorization/external inputs.
- [x] PLAN/session ledger and affected readiness documentation are consistent.
- [x] Documentation/link checks, manifest validation, and `git diff --check`
  pass; no evaluation or benchmark runs.

## Implementation

Added a Baseline provenance table to the plan classifying the unverified
external 94/84% claim, stale design-time 63/90 coverage claim, verified
32-active/8-retired corpus, verified 40-question v1-ab artifact, and 40-question
contract target. Updated Steps 1 and 5 and success criteria to reference the
canonical corpus and explicit external-input gates.

Reconciled current counts and gap accounting in
`docs/notes/analyzer-assisted-corpus-baseline.md` and
`docs/bugs/open/corpus-v1-below-minimum-question-count.md` (32 questions, 8
remaining IDs, four known validator errors). No corpus, result, code, generated
architecture output, experiment manifest, schema, or validator was changed.

## Validation

- `python3 benchmark/analyzer-assisted-v1/validate.py` — PASS, v1.3.0 and four
  available conditions.
- Architecture documentation lint — PASS, 845 files.
- Internal link verification — PASS.
- `git diff --check` — PASS.
- Overlay/platform lint could not run because host `yaml` is unavailable; this
  is an infrastructure limitation and outside the documentation task.
- No evaluation or benchmark ran. Delegated run cost `$2.93340575`.

## Status

Validated. MLflow registration, human root-cause adjudication, external-fetch
OTel producer, eight missing corpus questions, and user authorization remain
explicit rollout gates.
