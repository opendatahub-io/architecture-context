# Task: Re-author Retired Consumer-v1 Questions

## Goal

Restore the two retired Tier-1 questions `INV-005` and `INV-009` from exact,
repository-backed evidence. This is the first incremental slice toward the
40-question contract; other retired IDs are out of scope.

## Work

- Read the corpus manifest, consumer-v1 corpus/schema/validator, v1-ab raw and
  scored results, audit notes, and the architecture source files referenced by
  surviving questions.
- For `INV-005` and `INV-009`, either author a source-backed question/expected
  answer with exact evidence, or record it as unresolved with a concrete reason
  and leave the corpus unchanged for that ID.
- Update only `benchmark/consumer-v1/corpus.json` and its related durable
  notes/manifest/tests when every added entry is source-backed and validated.
- Preserve the 40-question schema and validator; do not change existing
  question IDs, answers, scores, or source revisions.

## Negative Controls

- Do not invent question text, answers, source lines, or evidence.
- Do not weaken schema/validator requirements or alter existing results.
- Do not run paid, full-corpus, or four-condition evaluations.
- Do not claim the 94-question/79-of-94 plan baseline is recovered.

## Acceptance Criteria

- [ ] Every restored entry has exact source evidence and passes schema/validator.
- [ ] The Tier-1 slice has 10 questions, or unresolved IDs are explicitly
  documented without weakening the contract.
- [x] Focused tests and the manifest validator pass; the consumer-v1
  validator reports only the documented out-of-scope Tier-3/Tier-4 gaps, and
  existing result artifacts are intact.
- [ ] Manifest, validation note, session log, and PLAN are reconciled.
- [x] Task is moved to `docs/tasks/done/` only after review and an accepted
  commit is created.

## Status

Done — 2026-07-24. INV-005 and INV-009 restored with verified evidence. Tier-1 slice has
10 questions. 9 retired IDs remain (all in Tier 3 and Tier 4).
