# Task: Prepare Semantic-Judge Calibration Set Template

## Goal

Prepare a versioned, stratified question template for human semantic-match
labels without inventing labels or running a judge model.

## Scope and controls

- Read `AGENTS.md`, `PLAN.md`, `agent-driver.md`, the analyzer-assisted plan,
  the judge contract, and the verified 40-question corpus.
- Select a deterministic 20–30 question subset covering all four tiers and
  both answerable and answerable-as-gap cases; preserve question IDs, question
  text, expected answer, source evidence, and selection rationale.
- Emit a template with `human_label: null` and explicit instructions for a
  human reviewer to label semantic equivalence and abstention handling.
- Do not infer or fill labels, call any model, run evaluation, modify corpus or
  raw/scored results, or claim agreement.

## Acceptance criteria

- [x] Template format and selection metadata are versioned and documented.
- [x] Every selected ID exists in the canonical corpus and the selection is
  deterministic, stratified, and independently auditable.
- [x] Validators/tests and `git diff --check` pass.
- [x] Record that human labeling and user authorization remain external gates.

## Result

**Implemented** — 24-question stratified calibration template v0.1.0.

### Selection

| Metric | Value |
|--------|-------|
| Algorithm | all-gap-plus-first-by-id |
| Total selected | 24 |
| Tier 1 (Inventory) | 6 |
| Tier 2 (Component Facts) | 6 |
| Tier 3 (Integration) | 6 |
| Tier 4 (Navigation) | 6 |
| Answerable | 20 |
| Answerable-as-gap | 4 (INV-002, INV-006, INV-007, FACT-008) |
| Deterministic | yes |

### Selection strategy

Include all 4 answerable-as-gap questions (gap handling is a distinct semantic
judgment case), then fill each tier to 6 with the first answerable questions
by ID order. This ensures deterministic reproducibility and equal tier
representation.

### Deliverables

| File | Purpose |
|------|---------|
| `benchmark/consumer-v1/calibration_template.json` | 24-question template with `human_label: null` |
| `benchmark/consumer-v1/calibration_schema.json` | JSON Schema 2020-12 for the template format |
| `benchmark/consumer-v1/validate_calibration.py` | Deterministic validator with corpus cross-check |
| `tests/test_calibration_template.py` | 49 focused tests |

### Validation results

| Check | Result |
|-------|--------|
| `python3 benchmark/consumer-v1/validate_calibration.py calibration_template.json corpus.json` | PASS: 24 questions, corpus cross-check yes |
| `pytest tests/test_calibration_template.py` | 49 passed |
| `git diff --check` | Clean |

### External gates

- **Human labeling**: All `human_label` values are null. A human reviewer must
  label each question before the calibration set is usable.
- **User authorization**: Judge execution requires explicit user authorization
  stating model, question count, estimated cost, and duration.

No model was called. No labels were inferred. No evaluation or benchmark ran.

## Status

Done — 2026-07-25 (template only; human labeling and authorization remain external gates).
