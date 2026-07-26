# Audit Existing Feedback Against Analyzer-Assisted Rollout Gates

Date: 2026-07-26

## Result

The git-ignored `tmp/feedback-data/` package is useful local evidence, but it
does not satisfy the analyzer-assisted human-data gates.

The package contains a historical 94-question corpus plus staff corrections,
dimension-level strategy-review feedback, and review scores. Its review
records concern RHAISTRAT strategy outputs (for example, 63 dimension-level
feedback entries and 36 trace score entries), whereas the rollout templates
are tied to the analyzer-assisted v1-ab corpus:

- 35 v1-ab failure proposals require `human_category` values.
- 24 v1-ab calibration questions require `human_label` values.

The package has no verified 1:1 mapping from those strategy-review records to
the v1-ab agent responses, calibration questions, or failure proposals. Its
known provenance inconsistencies are recorded in
`docs/notes/historical-feedback-provenance.md`. Therefore it may inform
directional regression priorities and correction harvesting, but it must not
be used to populate the human fields or claim semantic judge calibration.

## Validation

- `benchmark/consumer-v1/adjudication_template.json`: 35 entries, 35 null
  `human_category` values.
- `benchmark/consumer-v1/calibration_template.json`: 24 entries, 24 null
  `human_label` values.
- `tmp/feedback-data/corpus/extraction/review-feedbacks.yaml`: 63 strategy
  review entries.
- `tmp/feedback-data/corpus/extraction/trace-review-scores.yaml`: 36 strategy
  score entries.
- `tmp/feedback-data/corpus/extraction/staff-corrections.yaml`: 169 staff
  correction records, already used only as a proposal-harvesting input.

The provisional track remains the correct operating mode. Full rollout still
requires authoritative v1-ab labels/adjudication, judge authorization,
external-fetch OTel evidence, and approved external MLflow registration.
