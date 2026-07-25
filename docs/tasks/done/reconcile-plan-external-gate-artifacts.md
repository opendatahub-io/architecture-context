# Task: Reconcile External-Gate Preparation Artifacts

## Goal

Make the analyzer-assisted plan and benchmark readiness documentation point
to the concrete local artifacts prepared for human calibration and failure
adjudication, while keeping all external gates unresolved.

## Scope and controls

- Read `AGENTS.md`, `PLAN.md`, `agent-driver.md`, the analyzer-assisted plan,
  benchmark README, calibration template, and adjudication template.
- Add exact artifact paths, counts, validation status, and explicit null-label
  state to the relevant gate/readiness tables.
- Do not mark human labeling/adjudication, MLflow registration, OTel producer
  integration, or user authorization complete; do not run models/evaluations.
- Do not modify corpus, raw/scored results, schemas, or production code.

## Acceptance criteria

- [x] Plan and readiness docs consistently link the 24-question calibration
  template and 35-proposal adjudication template.
- [x] External prerequisites, required authorization fields, and null-label state
  remain explicit.
- [x] Documentation checks and `git diff --check` pass; task is moved to `done/`
  only after review and an accepted scoped commit.

## Result

**Implemented** — plan, README, and evaluation contract note now link both artifacts.

### Changes

| File | Change |
|------|--------|
| `docs/plans/analyzer-assisted-agent-architecture.md` | Step 1: added calibration template and judge contract references. Step 5 gate table: added LLM-as-judge calibration gate; root-cause gate updated with adjudication template path, version, null-label count, and validator. Fixed stale "1 retired" references → 0 retired (all 40 now active). |
| `benchmark/analyzer-assisted-v1/README.md` | Remaining Blockers table: added LLM-as-judge calibration gate; root-cause gate updated with adjudication template details. Fixed stale "36 active" → "40 active". |
| `docs/notes/analyzer-assisted-evaluation-contract.md` | Experiment execution blockers table: added LLM-as-judge calibration gate; root-cause gate updated with adjudication template reference. |
| `PLAN.md` | Added reconcile task to recently completed. |
| `docs/notes/session-log.md` | Session entry added. |

### Linked artifacts

| Artifact | Path | Version | Count | Labels |
|----------|------|---------|-------|--------|
| Calibration template | `benchmark/consumer-v1/calibration_template.json` | v0.1.0 | 24 questions (6/tier, 4 gap) | all `human_label: null` |
| Adjudication template | `benchmark/consumer-v1/adjudication_template.json` | v0.1.0 | 35 proposals | all `human_category: null`, all `proposed_category: "unresolved"` |

### External gates (explicitly incomplete)

- Human labeling of calibration template
- Human adjudication of failure proposals
- MLflow external server registration
- External-fetch OTel producer integration
- User authorization for paid/full-corpus evaluation

## Status

Done — 2026-07-25.
