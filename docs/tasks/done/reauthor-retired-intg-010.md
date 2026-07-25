# Task: Re-author Retired Integration Question INTG-010

## Outcome

Accepted on 2026-07-25. INTG-010 was restored with a narrowed question about
the three documented RHOAI serving paths and ModelMesh's role, replacing the
unsupported archive/deprecation claim. The complete expected answer is a
direct paraphrase of clean `architecture/rhoai.next/PLATFORM.md:353`.

The corpus now has 34 active and 6 retired questions. Remaining gaps are
INTG-003, INTG-006, INTG-008, NAV-003, NAV-006, and NAV-010.

## Validation

- `benchmark/analyzer-assisted-v1/validate_corpus.py`: PASS (40 entries, 34 active, 6 retired)
- Focused container tests: 70 passed
- Consumer validator: expected failure until the 40-question minimum is restored
- `git diff --check`: PASS

No evaluation or benchmark was run.
