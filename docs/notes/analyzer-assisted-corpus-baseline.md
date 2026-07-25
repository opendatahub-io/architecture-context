# Analyzer-Assisted Corpus Baseline — Validation Note

**Date**: 2026-07-24
**Task**: `docs/tasks/done/reconcile-analyzer-assisted-corpus-baseline.md`
**Status**: Complete (v1.1.0 — answerability and source evidence added)

## What was reconciled

The plan (`docs/plans/analyzer-assisted-agent-architecture.md`, line 20) cites a
"94-question retrieval baseline" with 79/94 (84%) accuracy. This task
established the actual corpus state and recorded explicit gap accounting.

### Three corpus identities

| Identity | Questions | Verification | Source |
|----------|:---------:|--------------|--------|
| Consumer-v1 audited corpus | 32 active | Audited against on-disk evidence | `benchmark/consumer-v1/corpus.json` |
| V1-ab pre-audit corpus | 40 evaluated | 32 survived auditing; 8 retired | `benchmark/consumer-v1/results/v1-ab/raw-results.json` |
| Plan 94-question baseline | 94 claimed | **Unverified** — no artifact exists | `docs/plans/analyzer-assisted-agent-architecture.md` (see Baseline provenance) |

### What is verified

- **33 active questions** in the consumer-v1 corpus are audited against on-disk
  architecture documentation. The original 29 from commit `0920cf3b` were
  augmented by restoring INV-005, INV-009 (corrected expected answers),
  INTG-002, and INTG-004 (re-authored with clean-tree evidence).
- **40 question IDs** (INV-001..010, FACT-001..010, INTG-001..010, NAV-001..010)
  were evaluated in the v1-ab run. All 40 are accounted for in the manifest:
  33 active + 7 retired.
- **7 retired questions** (INTG-003, INTG-006,
  INTG-008, INTG-010, NAV-003, NAV-006, NAV-010) remain from the original 11
  removed during post-evaluation ground-truth auditing. INV-005, INV-009,
  INTG-002, and INTG-004 have been restored with corrected expected answers
  and verified source evidence.
- The v1-ab evaluation results (raw and scored) are durable artifacts.
  Existing consumer-v1 questions, schema, validator, and result artifacts are
  preserved; two corrected, source-backed entries were restored.

### Answerability status and source evidence (v1.1.0)

Every active question now carries explicit `answerability_status` and
`source_evidence` derived from the consumer-v1 corpus:

| Answerability Status | Count | Description |
|----------------------|:-----:|-------------|
| `answerable` | 30 | Answer is directly documented in source evidence |
| `answerable-as-gap` | 2 | Correct answer documents a known absence (INV-006, FACT-008) |
| `undetermined` | 8 | Retired; original evidence was invalidated during auditing |

Each active question's `source_evidence` records `source_file`, `source_line`,
and `not_documented_expected` — values taken verbatim from the consumer-v1
corpus. The validator enforces consistency: `answerable-as-gap` requires
`not_documented_expected: true`; `answerable` requires `not_documented_expected:
false`; retired questions must use `undetermined` with no `source_evidence`.

### What remains unverified

- **The 94-question figure** does not correspond to any artifact in the
  repository or git history. The plan cites "94-question retrieval baseline"
  but no 94-question corpus, result set, or evaluation log exists.
- **The 79/94 (84%) score** cannot be reproduced or verified. It is
  preserved in the manifest as an unverified plan claim with
  `verification_status: "unverified"`.
- The benchmark design (`docs/plans/architecture-context-benchmark.md`)
  estimates 190–215 questions across 4 tiers but those extraction queries
  were never executed and no artifact was produced.

### Evidence searched for the 94-question artifact

1. `git log --all --oneline --grep="94" -- benchmark/ docs/plans/` — no results
2. `grep -rn "94.question" docs/` — only the plan prose and this task
3. Repository file listing under `benchmark/` — no 94-question corpus file
4. All files in `docs/notes/*.md` — no reference to a 94-question evaluation run
5. `benchmark/consumer-v1/results/v1-ab/` — contains exactly 40 question
   results, not 94

### Exact gap to the plan's 94-question target

| Segment | Count | Status |
|---------|:-----:|--------|
| Active (audited, in consumer-v1) | 33 | Available |
| Retired (failed audit, in v1-ab results) | 7 | Need re-authoring with verified evidence |
| Unaccounted (94 − 40) | 54 | No artifact; must be authored or claim downgraded |
| **Total to reach plan target** | **94** | **62 questions missing** |

The plan's 94-question baseline is classified as unverified external
historical feedback (see the plan's Baseline provenance table). The
actionable gap to the contract minimum is 7 questions (40 − 33).

## Deliverables

1. **Canonical manifest**: `benchmark/analyzer-assisted-v1/corpus_manifest.json`
   (v1.1.0) — 40 entries (33 active, 7 retired), per-question
   answerability status and source evidence, aggregate breakdowns by
   status/tier/category/difficulty/scope/answerability, baseline score records
   with verification status.

2. **Manifest schema**: `benchmark/analyzer-assisted-v1/corpus_schema.json`
   — JSON Schema 2020-12 with conditional requirement: active questions must
   have `answerability_status` and `source_evidence`.

3. **Manifest validator**: `benchmark/analyzer-assisted-v1/validate_corpus.py`
   — validates IDs, statuses, provenance, answerability, aggregates, and
   baseline claims.

4. **Focused tests**: `tests/test_corpus_manifest.py` — 70 tests covering
   active/retired/missing/unverified entries, answerability status,
   source evidence cross-reference with consumer-v1 corpus, validator
   negative cases (duplicate IDs, invalid statuses, missing provenance,
   missing answerability, invalid answerability values,
   answerability/not_documented_expected mismatches, inconsistent
   aggregates), gap accounting, baseline scores, consumer-v1 compatibility,
   and negative controls.

## Next task

Re-author the 8 remaining retired questions with verified ground-truth answers
and source references. This will bring the consumer-v1 corpus to its 40-question
schema target and resolve `docs/bugs/open/corpus-v1-below-minimum-question-count.md`.

The plan's 94-question claim has been reclassified as unverified external
historical feedback in the plan's Baseline provenance table. The plan now
references the actual canonical corpus (32 active / 40 contract target).
