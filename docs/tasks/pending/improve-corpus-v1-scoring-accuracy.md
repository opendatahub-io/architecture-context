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
   docs/bugs/open/report-generator-misses-source-citation-regressions.md).

### Phase 2: Structural improvement (v2)

5. Add an LLM-as-judge scoring dimension that evaluates semantic equivalence
   between the agent response and expected answer. Run it alongside exact
   match, not as a replacement, so the benchmark has both deterministic and
   semantic signals.

## Acceptance Criteria

- [ ] Phase 1: Re-scoring the existing v1 raw results with the updated
  scorer and corpus produces exact-match >= 25% (from current 15%).
- [ ] Phase 1: No question that currently passes exact match regresses.
- [ ] Phase 2: Semantic judge agrees with manual classification on >= 90%
  of questions.

## Priority

MEDIUM — improves signal quality but doesn't change the underlying document
quality. Phase 1 is low-cost; phase 2 is higher cost.

## Status

Pending.
