# Task: Reconcile Analyzer-Assisted Corpus Baseline

## Goal

Create a canonical, machine-readable corpus manifest for the
analyzer-assisted evaluation plan that reconciles the plan's cited 94-question
baseline with the current 29-question consumer-v1 corpus.

## Context

`docs/plans/analyzer-assisted-agent-architecture.md` cites a 94-question
retrieval baseline of 79/94 (84%) and requires stratification by category and
difficulty. The current checkout contains only 29 audited questions in
`benchmark/consumer-v1/corpus.json`; its schema intentionally requires 40
questions and the validator reports the shortfall. The old benchmark design
describes broader tier estimates but does not provide a canonical 94-question
artifact.

This task establishes the evaluation source of truth and gap accounting. It
does not invent missing questions, alter consumer-v1, or run agents.

## Inputs

- `docs/plans/analyzer-assisted-agent-architecture.md`
- `docs/plans/architecture-context-benchmark.md`
- `benchmark/consumer-v1/corpus.json`
- `benchmark/consumer-v1/schema.json`
- `benchmark/consumer-v1/results/v1-ab/`
- `docs/notes/analyzer-migration-v1-baseline-2026-07-20.md`
- `docs/bugs/open/corpus-v1-below-minimum-question-count.md`
- any repository history or durable notes that substantiate the 94-question
  figure and 79/94 score

## Work

### 1. Establish corpus identities

Document separate identities for:

- the current audited consumer-v1 corpus and its 29 active questions;
- the historical 94-question baseline, if reproducible evidence exists;
- any retired, missing, or unverified questions needed to reconcile the two.

If the 94-question artifact cannot be recovered from repository evidence, record
that fact explicitly and preserve 94/79 as an unverified plan claim rather than
manufacturing a replacement.

### 2. Add a canonical manifest

Create `benchmark/analyzer-assisted-v1/corpus_manifest.json` (or an equivalent
path justified by the repository layout) with:

- corpus and manifest versions;
- source artifact paths, revisions, and verification status;
- per-question identity for every active question;
- category, difficulty, required scope, answerability status, and source
  evidence for active questions;
- aggregate counts by category, difficulty, scope, and status;
- explicit gap records for missing or unrecovered questions;
- baseline score fields only when backed by a durable result artifact.

The manifest must distinguish `active`, `retired`, `missing`, and
`unverified` entries and must not treat missing entries as incorrect answers.

### 3. Add deterministic validation and tests

Add a schema/validator and focused tests for duplicate IDs, invalid statuses,
missing provenance, inconsistent aggregates, unsupported baseline claims, and
the current 29-question manifest fixture. Preserve compatibility with existing
consumer-v1 corpus, schema, raw results, and scored results.

### 4. Record the baseline decision

Add a validation note describing what is verified, what remains unverified, the
exact gap to the plan's 94-question target, and the next task required to
author or recover missing source-backed questions. Append the session activity
and reconcile `PLAN.md`.

## Negative Controls

- Do not modify `benchmark/consumer-v1/corpus.json` or its 40-question schema
  contract.
- Do not weaken `benchmark/consumer-v1/validate.py`.
- Do not fabricate question text, expected answers, source evidence, scores,
  or the missing 94-question artifact.
- Do not infer the 79/94 score from the 29-question v1 results.
- Do not run paid, full-corpus, or four-condition agent evaluations.
- Do not silently promote plan prose into verified measurement.

## Likely Files

- `benchmark/analyzer-assisted-v1/corpus_manifest.json`
- `benchmark/analyzer-assisted-v1/corpus_schema.json`
- `benchmark/analyzer-assisted-v1/validate_corpus.py`
- focused tests under `tests/`
- `docs/notes/analyzer-assisted-corpus-baseline.md`
- `docs/notes/session-log.md`
- `PLAN.md`

## Acceptance Criteria

- [x] Current v1, historical 94-question baseline, and unrecovered gaps have
  separate identities and verification statuses.
- [x] A canonical manifest records active questions, provenance, stratification,
  aggregate counts, and explicit missing/unverified entries.
- [x] The manifest validator rejects invalid statuses, duplicate IDs, missing
  provenance, inconsistent counts, and unsupported scores.
- [x] The current 29-question corpus validates through the new manifest without
  changing consumer-v1 files or scores.
- [x] Tests cover active, missing, retired, and unverified entries plus negative
  controls.
- [x] A validation note and session-log entry record the baseline decision and
  next corpus-authoring/recovery task.
- [x] No paid or full-corpus evaluation is run.
- [x] The task is moved to `docs/tasks/done/`, `PLAN.md` is reconciled, and an
  accepted-work commit is created.

## Status

Done — 2026-07-24.
Manifest v1.1.0 includes per-question `answerability_status` and
`source_evidence` for all 29 active questions (derived from consumer-v1 corpus),
`undetermined` for 11 retired questions. Schema enforces conditional
requirement. Validator checks 13 rules. 70 tests pass including 10
answerability negative controls.
