# Bug: Corpus V1 Below Minimum Question Count

## Summary

`benchmark/consumer-v1/corpus.json` contains 35 questions. The v1 contract
(`schema.json` `minItems: 40`, `validate.py` 10-per-tier) requires at least
40 questions with exactly 10 per tier. The corpus fails its own schema
validation and `validate.py` checks.

## Current State

| Tier | Name                         | Have | Need | Gap |
|------|------------------------------|------|------|-----|
| 1    | Inventory                    | 10   | 10   | 0   |
| 2    | Component Facts              | 10   | 10   | 0   |
| 3    | Cross-Component Integration  | 7    | 10   | -3  |
| 4    | Navigation/Structure         | 8    | 10   | -2  |
| **Total** |                         | **35** | **40** | **-5** |

Missing IDs by tier:
- Tier 3 (INTG): INTG-003, INTG-006, INTG-008
- Tier 4 (NAV): NAV-003, NAV-006

Previously restored: INV-005, INV-009 (corrected expected answers),
INTG-002 and INTG-004 (re-authored with clean-tree evidence),
INTG-010 (re-authored with ModelMesh serving-role question),
NAV-010 (re-authored with PLATFORM.md OGX naming question).

## Validation Output

```
$ python3 benchmark/consumer-v1/validate.py

FAIL: 4 error(s) found:

  - Schema: questions: ... is too short
  - Tier 3: expected 10 questions, found 7
  - Tier 4: expected 10 questions, found 8
  - Total questions: expected >= 40, found 35
```

## Impact

HIGH — the corpus cannot pass its own published schema and validator. The
v1-ab evaluation run used 40 questions (20 per tree), but the current
corpus.json only contains the 35 that survived ground-truth auditing and
subsequent re-authoring. The 5 remaining retired questions were stripped
after the evaluation run because their expected answers or source references
were incorrect.

## Constraints

- The schema and validator must NOT be weakened (the 40/10 targets represent
  the intended corpus size for statistical coverage).
- Missing questions must NOT be fabricated — each must be authored against
  verified on-disk evidence.
- The existing 35 questions and the v1-ab results are correct and must be
  preserved.

## Resolution Path

Author the 5 missing questions with verified ground-truth answers and
source references. Until then, `validate.py` will report errors for the
Tier 3 and Tier 4 shortfalls and the total count.

## Status

Open.
