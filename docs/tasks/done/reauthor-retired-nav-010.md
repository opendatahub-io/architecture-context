# Task: Re-author Retired Navigation Question NAV-010

## Outcome

Accepted on 2026-07-25. NAV-010 was restored with the narrow question
“What name does the RHOAI platform component tree use for Llama Stack?” The
answer is directly supported by clean
`architecture/rhoai.next/PLATFORM.md:101` (`OGX (Llama Stack)`). Overlay-only
rename details were intentionally excluded.

The corpus now has 35 active and 5 retired questions: Tier 3 has 7 and Tier 4
has 8. Remaining gaps are INTG-003, INTG-006, INTG-008, NAV-003, and NAV-006.

## Validation

- `benchmark/analyzer-assisted-v1/validate_corpus.py`: PASS (35 active, 5 retired)
- Focused manifest and planner tests: 140 passed
- MLflow tracking tests: 89 passed, 5 skipped where the SDK was unavailable
- `git diff --check`: PASS

No evaluation or benchmark was run.
