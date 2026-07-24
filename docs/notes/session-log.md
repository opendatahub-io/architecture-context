# Session Log

## 2026-07-24 — Reconcile Analyzer-Assisted Corpus Baseline

**Task**: `docs/tasks/done/reconcile-analyzer-assisted-corpus-baseline.md`

### Summary

Created a canonical corpus manifest that reconciles the plan's cited 94-question
baseline with the actual 29-question consumer-v1 corpus. Established separate
identities for active (29), retired (11), and unrecovered (54) questions. The
94-question figure and 79/94 score are recorded as unverified plan claims — no
artifact exists in the repository.

### Artifacts created

| File | Purpose |
|------|---------|
| `benchmark/analyzer-assisted-v1/corpus_manifest.json` | Canonical manifest with 40 entries, 3 gaps, aggregate counts |
| `benchmark/analyzer-assisted-v1/corpus_schema.json` | JSON Schema for the manifest format |
| `benchmark/analyzer-assisted-v1/validate_corpus.py` | Deterministic validator for the manifest |
| `tests/test_corpus_manifest.py` | 47 focused tests |
| `docs/notes/analyzer-assisted-corpus-baseline.md` | Validation note with gap accounting |

### Artifacts preserved (not modified)

- `benchmark/consumer-v1/corpus.json` (29 questions)
- `benchmark/consumer-v1/schema.json` (40-question minItems contract)
- `benchmark/consumer-v1/validate.py` (10-per-tier requirement)
- `benchmark/consumer-v1/results/v1-ab/` (raw and scored results)

### Validation results

- Manifest validator: PASS (40 entries, 29 active, 11 retired, 3 gaps)
- New tests: 47 passed
- Existing evaluation tests: 52 passed
- Consumer-v1 validator: unchanged, still reports 5 expected errors (29 < 40)
- No paid or full-corpus evaluation was run

### Next steps

1. Re-author 11 retired questions to reach the 40-question v1 schema target
2. Decide whether to author 54 additional questions or downgrade the plan's 94-question claim

## 2026-07-24 — Answerability Status and Source Evidence (v1.1.0)

**Task**: `docs/tasks/current/reconcile-analyzer-assisted-corpus-baseline.md`

### Summary

Addressed the rejection of the first pass: each active question now carries
explicit `answerability_status` and `source_evidence` fields, with values
derived from the consumer-v1 corpus (`source_file`, `source_line`,
`not_documented_expected`). Extended the schema, validator, and tests to
require and validate these fields.

### Changes

| File | Change |
|------|--------|
| `benchmark/analyzer-assisted-v1/corpus_manifest.json` | v1.0.0 → v1.1.0: added `answerability_status` (all 40 questions) and `source_evidence` (29 active); added `by_answerability_status` aggregate |
| `benchmark/analyzer-assisted-v1/corpus_schema.json` | Added `answerability_status` enum, `source_evidence` object, conditional requirement for active questions, `by_answerability_status` in aggregates |
| `benchmark/analyzer-assisted-v1/validate_corpus.py` | Added `validate_answerability()` (11 checks); added `by_answerability_status` aggregate validation |
| `tests/test_corpus_manifest.py` | 47 → 70 tests: added `TestAnswerabilityStatus` (8 tests), `TestSourceEvidenceCrossReference` (1 test), `TestValidatorAnswerability` (10 negative controls), answerability aggregate test, negative control tests |
| `docs/notes/analyzer-assisted-corpus-baseline.md` | Updated to reflect v1.1.0 deliverables |

### Validation results

- Manifest validator: PASS (40 entries, 29 active, 11 retired, 3 gaps)
- Tests: 70 passed
- Consumer-v1 validator: unchanged, still reports 5 expected errors (29 < 40)
- No consumer-v1 files modified
- No paid or full-corpus evaluation run

## 2026-07-24 — Re-author Retired Consumer-v1 Questions (INV-005, INV-009)

**Task**: `docs/tasks/done/reauthor-retired-consumer-v1-questions.md`

### Summary

Restored INV-005 and INV-009 with corrected expected answers and verified source
evidence. Both questions were retired during ground-truth auditing because their
original expected answers were factually wrong (contradicted by on-disk evidence).

### Evidence

| ID | Original Expected Answer (wrong) | Corrected Answer | Source Evidence |
|----|----------------------------------|------------------|----------------|
| INV-005 | "CodeFlare SDK is not listed in PLATFORM.md component inventory" | "Yes, codeflare-sdk is listed in README.md and has a dedicated architecture doc" | `architecture/rhoai.next/README.md:27` |
| INV-009 | "No. Triton is a Tested & Verified runtime only, not out-of-the-box" | "Yes, Triton is a default ServingRuntime in ModelMesh Serving" | `architecture/rhoai.next/modelmesh-serving.md:182` |

### Changes

| File | Change |
|------|--------|
| `benchmark/consumer-v1/corpus.json` | Added INV-005 and INV-009 entries (29 → 31 questions) |
| `benchmark/analyzer-assisted-v1/corpus_manifest.json` | INV-005 and INV-009: retired → active; aggregates updated (31 active, 9 retired) |
| `tests/test_corpus_manifest.py` | Updated 3 count assertions (29→31, 11→9) |
| `docs/notes/analyzer-assisted-corpus-baseline.md` | Updated counts throughout |

### Validation results

- Manifest validator: PASS (40 entries, 31 active, 9 retired, 3 gaps)
- Tests: 70 passed
- Consumer-v1 validator: 4 expected errors (31 < 40, Tier 3: 4/10, Tier 4: 7/10)
- No evaluation run; no existing results modified
