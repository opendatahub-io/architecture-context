# Bug: Corpus V1 Below Minimum Question Count

## Summary

`benchmark/consumer-v1/corpus.json` now contains 40 questions. The v1 contract
(`schema.json` `minItems: 40`, `validate.py` 10-per-tier) requires at least
40 questions with exactly 10 per tier. The corpus passes its own schema
validation and `validate.py` checks.

## Current State

| Tier | Name                         | Have | Need | Gap |
|------|------------------------------|------|------|-----|
| 1    | Inventory                    | 10   | 10   | 0   |
| 2    | Component Facts              | 10   | 10   | 0   |
| 3    | Cross-Component Integration  | 10   | 10   | 0   |
| 4    | Navigation/Structure         | 10   | 10   | 0   |
| **Total** |                         | **40** | **40** | **0** |

All previously missing IDs have been restored:
INV-005, INV-009 (corrected expected answers),
INTG-002 and INTG-004 (re-authored with clean-tree evidence),
INTG-003 (re-authored with PLATFORM.md:121 odh-model-controller/KServe integration),
INTG-006 (re-authored with PLATFORM.md:119 rhods-operator lifecycle management),
INTG-008 (re-authored with PLATFORM.md distributed training workflow),
INTG-010 (re-authored with ModelMesh serving-role question),
NAV-003 (re-authored with PLATFORM.md:22 dependency graph navigation),
NAV-006 (re-authored with PLATFORM.md:253 deployment topology navigation),
NAV-010 (re-authored with PLATFORM.md OGX naming question).

## Validation Output

```
$ python3 benchmark/consumer-v1/validate.py

OK: 0 error(s) found.
```

## Status

Resolved — 2026-07-25. NAV-006 was the last missing question; re-authored as
a deployment-topology navigation question backed by
`architecture/rhoai.next/PLATFORM.md` lines 253-257.
