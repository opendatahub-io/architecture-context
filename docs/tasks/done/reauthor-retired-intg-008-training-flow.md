# Task: Re-author Retired Integration Question INTG-008

## Outcome

Accepted on 2026-07-25. INTG-008 was restored with a narrowed question about
the RHOAI distributed-training workflow, backed by clean
`architecture/rhoai.next/PLATFORM.md:246-249`. The conflicted fine-tuning and
training-hub documents and all overlays were excluded.

The corpus now has 36 active and 4 retired questions: Tier 3 has 8 and Tier 4
has 8. Remaining gaps are INTG-003, INTG-006, NAV-003, and NAV-006.

## Validation

- `benchmark/analyzer-assisted-v1/validate_corpus.py`: PASS (36 active, 4 retired)
- Focused corpus-manifest tests: 70 passed
- Consumer validator: expected failure until the 40-question minimum is restored
- `git diff --check`: PASS

No evaluation or benchmark was run.
