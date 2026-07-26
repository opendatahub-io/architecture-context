# Task: Define the No-New-Human-Data Rollout Track

## Goal

Adapt the analyzer-assisted architecture plan to the documented reality that
additional human adjudication/calibration data is unlikely, while preserving
honest evidence boundaries and enabling provisional evaluation.

## Scope and controls

- Read `AGENTS.md`, `PLAN.md`, `agent-driver.md`, the architecture plan,
  `docs/notes/historical-feedback-provenance.md`, and the existing evaluation
  contract/readiness notes.
- Do not relabel the existing feedback package, fill human fields, run models,
  launch paid/full-corpus evaluation, or modify application code.
- Prior architecture snapshots may be used only for deterministic regression;
  they are not semantic human labels.

## Acceptance criteria

- Add a durable decision/note defining a provisional no-new-human-data track:
  existing feedback is directional only; snapshot 1:1 comparisons cover
  deterministic regressions; automated root-cause signals remain provisional;
  LLM-judge calibration and human-review claims are not asserted.
- Update the architecture plan and evaluation readiness documentation with
  explicit provisional success criteria, limitations, and the retained legacy
  route; do not silently declare the full rollout gates passed.
- Preserve the canonical 40-question corpus and v1-ab baseline, file-backed
  MLflow workflow, external cost/authorization gate, and external OTel caveat.
- Reconcile `PLAN.md` and the session ledger; run relevant validators and
  `git diff --check`; do not commit.

## Status

Done — 2026-07-26.

## Implementation summary

### Durable provisional track note created

`docs/notes/no-human-data-provisional-rollout-track.md` defines the
provisional rollout track with:

- **Permitted activities**: deterministic regression testing, automated
  root-cause signal generation (directional only), exact-match scoring
  against canonical corpus, file-backed MLflow tracking, context telemetry
  collection (local export)
- **Prohibited claims**: LLM-as-judge semantic scores, human-review quality
  assertions, authoritative failure classifications, full rollout gate
  satisfaction, historical 84% baseline comparison
- **Provisional success criteria**: maps each full criterion (S1–S8) to
  what is measurable without human data and its evidence boundary
- **Directional signal from historical feedback**: category weakness
  patterns, semantic gap distribution, and staff-correction frequency are
  acknowledged as plan-design inputs, not evaluation evidence
- **Relationship to full track**: provisional is a subset; when human data
  arrives, calibration template → semantic scoring, adjudication template →
  authoritative classifications

### Plan updated

`docs/plans/analyzer-assisted-agent-architecture.md` — added a
"Provisional track (no new human data)" subsection under Success criteria.
References the provisional track note and enumerates what each criterion
can and cannot measure without human labels.

### Evaluation readiness updated

`docs/notes/analyzer-assisted-evaluation-contract.md` — added a
"Provisional evaluation track" section before Validation results.
Lists permitted and prohibited activities under the provisional track.

### What was NOT changed

- Application code, schemas, corpus, generated output, or external state
- Human adjudication/calibration labels (all remain null)
- The canonical 40-question corpus (`benchmark/consumer-v1/corpus.json`)
- The v1-ab baseline results
- The plan's full rollout gates and success criteria (remain authoritative)
- The legacy route (preserved; retirement requires full gate satisfaction)
- The 94-question feedback package (remains git-ignored directional signal)

### Validators run

- `benchmark/consumer-v1/validate.py`: PASS (40 questions)
- `benchmark/analyzer-assisted-v1/validate.py`: PASS (manifest v1.3.0,
  4 conditions)
- `benchmark/analyzer-assisted-v1/validate_corpus.py`: PASS (40 active)
- `git diff --check`: PASS (no whitespace errors)

### Changed files

- `docs/notes/no-human-data-provisional-rollout-track.md` (new: durable
  provisional track note)
- `docs/plans/analyzer-assisted-agent-architecture.md` (provisional track
  subsection added to Success criteria)
- `docs/notes/analyzer-assisted-evaluation-contract.md` (provisional
  evaluation track section added; stale `current/` task reference corrected)
- `docs/tasks/done/define-no-human-data-rollout-track.md` (moved from
  `current/`; status updated to done)
- `PLAN.md` (task added to recently completed)
- `docs/notes/session-log.md` (session entry added)
