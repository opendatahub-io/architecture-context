# Bug: Corpus V1 Below Minimum Question Count

## Summary

`benchmark/consumer-v1/corpus.json` contains 29 questions. The v1 contract
(`schema.json` `minItems: 40`, `validate.py` 10-per-tier) requires at least
40 questions with exactly 10 per tier. The corpus fails its own schema
validation and `validate.py` checks.

## Current State

| Tier | Name                         | Have | Need | Gap |
|------|------------------------------|------|------|-----|
| 1    | Inventory                    | 8    | 10   | -2  |
| 2    | Component Facts              | 10   | 10   | 0   |
| 3    | Cross-Component Integration  | 4    | 10   | -6  |
| 4    | Navigation/Structure         | 7    | 10   | -3  |
| **Total** |                         | **29** | **40** | **-11** |

Missing IDs by tier:
- Tier 1 (INV): INV-005, INV-009 never authored
- Tier 3 (INTG): INTG-002, INTG-003, INTG-004, INTG-006, INTG-008, INTG-010
  never authored
- Tier 4 (NAV): NAV-003, NAV-006, NAV-010 never authored

## Validation Output

```
$ python3 benchmark/consumer-v1/validate.py

FAIL: 5 error(s) found:

  - Schema: questions: ... is too short
  - Tier 1: expected 10 questions, found 8
  - Tier 3: expected 10 questions, found 4
  - Tier 4: expected 10 questions, found 7
  - Total questions: expected >= 40, found 29
```

## Impact

HIGH — the corpus cannot pass its own published schema and validator. The
v1-ab evaluation run used 40 questions (20 per tree), but the current
corpus.json only contains the 29 that survived ground-truth auditing. The
11 removed questions were stripped after the evaluation run because their
expected answers or source references were incorrect.

## Constraints

- The schema and validator must NOT be weakened (the 40/10 targets represent
  the intended corpus size for statistical coverage).
- Missing questions must NOT be fabricated — each must be authored against
  verified on-disk evidence.
- The existing 29 questions and the v1-ab results are correct and must be
  preserved.

## Resolution Path

Author the 11 missing questions with verified ground-truth answers and
source references. The existing task
`docs/tasks/done/improve-corpus-v1-scoring-accuracy.md` or a new task
should cover this work. Until then, `validate.py` will report 5 errors.

## Status

Open.
