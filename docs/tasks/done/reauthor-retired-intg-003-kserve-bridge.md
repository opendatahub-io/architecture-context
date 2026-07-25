# Task: Re-author Retired Integration Question INTG-003

## Outcome

Accepted on 2026-07-25. INTG-003 was restored with a narrow question about
the infrastructure `odh-model-controller` creates while watching KServe CRs,
backed by clean `architecture/rhoai.next/PLATFORM.md:121`. The original
overlay-precedence question was not restored.

The corpus now has 37 active and 3 retired questions: Tier 3 has 9 and Tier 4
has 8. Remaining gaps are INTG-006, NAV-003, and NAV-006.

## Validation

- `benchmark/analyzer-assisted-v1/validate_corpus.py`: PASS (37 active, 3 retired)
- Focused planner, runner, and manifest tests: 169 passed
- Consumer validator: expected failure until the 40-question minimum is restored
- `git diff --check`: PASS

No evaluation or benchmark was run.
