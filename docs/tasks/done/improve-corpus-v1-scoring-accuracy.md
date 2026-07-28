# Task: Improve Corpus V1 Scoring Accuracy

## Goal

Reduce false-negative exact-match failures in the consumer benchmark scorer
so that composite scores reflect actual quality rather than variant-list gaps.

## Motivation

The v1 A/B evaluation has a 15% exact-match rate on both trees, but manual
review shows at least 5 questions where the agent's answer is factually
correct and simply doesn't substring-match any `acceptable_variants` entry.
The low exact-match rate makes it hard to distinguish real quality problems
from scoring noise.

See: docs/bugs/open/corpus-v1-exact-match-variants-too-strict.md

## Work

### Phase 1: Quick fixes (corpus v1.1)

1. Make substring matching case-insensitive in `score_results.py`.
2. Review all 40 questions and expand `acceptable_variants` in `corpus.json`
   to cover common correct phrasings found in the v1 raw results.
3. Retarget INV-002, INV-007 expected sources to architecture files or mark
   as `not_documented_expected: true`.
4. Fix source_citation regression detection in `generate_report.py` (see
   docs/bugs/fixed/report-generator-misses-source-citation-regressions.md).

### Phase 2: Structural improvement (v2)

5. Add an LLM-as-judge scoring dimension that evaluates semantic equivalence
   between the agent response and expected answer. Run it alongside exact
   match, not as a replacement, so the benchmark has both deterministic and
   semantic signals.

## Acceptance Criteria

- [x] Phase 1: Re-scoring the existing v1 raw results with the updated
  scorer and corpus produces exact-match >= 25% (from current 15%).
  Verified: 42.5% (tree A) / 40.0% (tree B).
- [x] Phase 1: No question that currently passes exact match regresses.
  Verified: all 6 originally passing questions still pass.
- [ ] Phase 2: Semantic judge agrees with manual classification on >= 90%
  of questions.

## Priority

MEDIUM — improves signal quality but doesn't change the underlying document
quality. Phase 1 is low-cost; phase 2 is higher cost.

## Status

Done — Phase 1 implemented and verified (2026-07-25). Phase 2 deferred to
`docs/tasks/done/add-llm-judge-scoring-dimension.md`.

### Phase 1 progress

| Item | Status | Evidence |
|------|--------|----------|
| Case-insensitive matching | Already implemented | `score_results.py` `normalize()` lowercases; verified in `test_scorer_variants.py::TestNormalize` |
| Expand acceptable_variants | Done (pre-existing) | 17 questions pass exact match on tree A (42.5%, up from 15%); variants verified in `test_scorer_variants.py::TestExactMatchWithVariants` |
| Retarget INV-002/INV-007 | Done | Both marked `not_documented_expected: true`; source outside architecture evaluation scope; regression tests in `TestRetargetedGapQuestions` |
| Fix source_citation regression detection | Already implemented | `generate_report.py` lines 201-210; regression test in `TestSourceCitationRegressionDetection` |

### Re-scoring verification (offline, not a paid run)

Re-scoring v1-ab raw results with updated corpus:
- Tree A exact match: 42.5% (17/40), up from 15% (6/40)
- Tree B exact match: 40.0% (16/40), up from 15% (6/40)
- No regressions: all 6 originally passing questions still pass
- Target >= 25%: **met** on both trees

### Unverified gate

The 25% threshold is verified by offline re-scoring (deterministic, no paid
API calls). Full composite-score improvement requires an authorized rerun
with the updated corpus to produce new raw results — particularly for
re-authored questions where v1-ab raw responses answer different original
questions.

## Driver handoff constraints

Implement Phase 1 only in this run. Do not run a paid or full-corpus
evaluation, do not add an LLM judge, and do not modify raw/scored result
artifacts. Use the existing raw results only for offline scorer tests and
document any threshold that cannot be verified without an authorized rerun.

## Follow-up

Phase 1 is complete and checkpoint-ready. Phase 2 is tracked separately in
`docs/tasks/done/add-llm-judge-scoring-dimension.md` — contract/protocol
implemented (schema v0.1.0, validator, 65 tests, rationale required non-empty);
judge execution blocked on user authorization for model calls and a
human-labeled calibration set.
