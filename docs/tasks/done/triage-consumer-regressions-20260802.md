# Triage Consumer Regressions After Full Run

## Goal

Resolve the one generated-document defect and correct the two consumer
benchmark contracts exposed by the 2026-08-02 full regeneration comparison.

## Plan

1. [x] Fix `FACT-003` dashboard language classification without a
   component-specific hardcode.
2. [x] Update `FACT-008` scoring to accept explicit server-level-versus-
   per-route authentication gap answers.
3. [x] Fix `NAV-005` by materializing symlink metadata in the agent context.
4. [x] Run focused checks for all three IDs.
5. [x] Regenerate the affected component or benchmark context as appropriate,
   then run the full consumer benchmark.
6. [x] Make exact scoring robust to equivalent wording and unordered fact
   tables.

## Evidence

The completed-tree benchmark at
`tmp/evaluations/consumer-v1-rhoai-next-20260802T234823Z/` scored Tree B
`0.6000` versus Tree A `0.5375` and flagged `FACT-003`, `FACT-008`, and
`NAV-005`. The candidate tree included `PLATFORM.md`; the comparison is now
valid.

Focused validation now passes:

- `go test ./internal/normalize`
- `47 passed` in `tests/test_scorer_variants.py`
- consumer corpus validation: 40 questions
- shell syntax and `git diff --check`

The full benchmark run at
`tmp/evaluations/consumer-v1-rhoai-next-20260803T001316Z/` reported no
regressions. Re-scoring its raw results with the structured exact-match
contract raises Tree B from `0.6333` to `0.6542`; `FACT-008` and `NAV-005` now
score `1.0`.

The next content-quality target is Tier 3 cross-component integration, where
the current run has `0%` exact matches in both trees.
