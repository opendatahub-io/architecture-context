# Task: Harvest Explicit Correction Proposals from Review Input

## Goal

Implement the correction-harvesting step in
`docs/plans/analyzer-assisted-agent-architecture.md` as a conservative,
source-preserving parser for caller-supplied Staff Engineer / SME review input.

## Scope

- Read the checked-in `tmp/feedback-data/corpus/extraction/staff-corrections.yaml`
  schema: records have `jira_key`, `correction_types`, `sme_content`,
  `human_review_type`, and explicit `components[].name` values.
- Add an opt-in command or library that accepts this YAML file path and emits
  proposal-contract-v1 pending records only for records with
  `human_review_type: sme_input` and non-empty SME content.
- Emit one proposal for each explicit record/component/correction-type tuple;
  preserve the component name exactly as supplied (do not map or slugify it).
- Use a documented deterministic mapping from source correction types to
  proposal categories; unsupported source types become explicit `unknown`
  categories rather than being guessed.
- Preserve exact source path, Jira key, YAML record identity, and YAML line
  provenance in each pending proposal. Reuse proposal contract v1; emitted
  records must never be treated as reviewed or authoritative.
- Define deterministic ordering, duplicate-ID behavior, and explicit
  unknown/not-extracted behavior with input/output examples.
- Add focused tests for the repository fixture, filtered review types, empty
  content, missing components, unsupported correction types, multiline content,
  duplicate records, and source provenance.

## Negative controls

- Do not infer or normalize component names; the YAML component name is copied
  verbatim and remains a review target if it is not a canonical architecture
  identifier.
- Do not infer correction categories from SME prose; use only the explicit
  `correction_types` values and the documented mapping.
- Do not read or modify generated architecture documents or overlays.
- Do not apply proposals, update authoritative data, or run paid evaluations.
- Do not invent a repository-wide Staff/SME source path; the input path is a
  required command argument.

## Acceptance criteria

- [x] The YAML input schema, correction-type mapping, and output are
  versioned/documented with concrete input
  and JSON examples.
- [x] Only qualifying explicit YAML records produce pending proposals with
  exact source provenance; unsupported/ambiguous input is skipped or rejected
  deterministically and visibly.
- [x] Existing proposal validation and CLI behavior remain compatible; focused
  tests cover normal, empty, malformed, duplicate, and provenance cases.
- [x] No generated architecture or overlay output changes.
- [x] Plan note, session log, and PLAN are reconciled.
- [x] Task is moved to `done/` only after review and an accepted commit.

## Status

Done — `arch-analyzer harvest-proposals` reads the repository Staff/SME
correction fixture and emits validated proposal-contract-v1 pending records
with deterministic IDs and exact source provenance.
