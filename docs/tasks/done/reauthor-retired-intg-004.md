# Task: Re-author Retired Integration Question INTG-004

## Goal

Restore only `INTG-004` with a source-backed clean-tree question and exact
evidence, or document it as unresolved if the architecture tree cannot support
one.

## Outcome

Accepted on 2026-07-25. INTG-004 was restored with the clean-tree question and
answer recorded in `benchmark/consumer-v1/corpus.json`, backed by
`architecture/rhoai.next/llm-d-inference-scheduler.md:370-374`.

The corpus now has 33 active and 7 retired questions. The remaining gap is
explicit: INTG-003, INTG-006, INTG-008, INTG-010, NAV-003, NAV-006, and NAV-010.

## Validation

- `benchmark/analyzer-assisted-v1/validate_corpus.py`: PASS (40 entries, 33 active, 7 retired)
- `benchmark/analyzer-assisted-v1/validate.py`: PASS
- `benchmark/consumer-v1/validate.py`: expected failure until the 40-question minimum is restored
- Focused container tests: 70 passed
- `git diff --check`: PASS

No evaluation or benchmark was run.
