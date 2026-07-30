# Bug: Corpus V1 Meta Questions Outside Architecture Tree

## Summary

3 questions expect answers from files outside the architecture document tree:
`docs/notes/` (analyzer baseline notes) and `docs/plans/` (benchmark design).
These test knowledge about the analyzer process itself, not about the
platform architecture the consumer agent is asked to navigate.

## Affected Questions

| ID | Expected Source | What It Tests |
|----|----------------|---------------|
| INV-002 | docs/notes/analyzer-migration-v1-baseline-2026-07-20.md | "How many components approved for analyzer-only generation?" |
| INV-007 | docs/notes/analyzer-migration-v1-baseline-2026-07-20.md | "What routing decision does the analyzer make for mlflow?" |
| NAV-004 | docs/plans/architecture-context-benchmark.md | Source citation points to benchmark plan, not architecture docs |

INV-002 and INV-007 ask meta-questions about the analyzer's own decisions.
These facts are not documented in any architecture file and the agents
correctly report them as undocumented. NAV-004's answer is correct but
its expected source citation is a planning document.

## Impact

LOW — the agents behave correctly (gap acknowledgment passes on all three).
The 0% composite scores are scoring artifacts, not quality failures.

## Recommendation

For corpus v1.1, either remove these questions or retarget their expected
sources to architecture files where the relevant facts can be derived. Do
not add `docs/notes/` to the evaluation scope — it conflates analyzer
process metadata with architecture document quality.

## Status

Fixed 2026-07-30 by keeping the rows in `required_scope: full-repo` and making
the scoring/reporting boundary explicit. `score_results.py` now emits
`primary_overall` for `required_scope: architecture`, and `generate_report.py`
uses that as the primary architecture quality summary. Regressions for
`full-repo` rows are reported separately as non-primary diagnostics, so these
process/meta questions no longer obscure architecture-tree quality.

Follow-up completed in
`docs/tasks/done/finish-consumer-v1-scoring-scope-cleanup.md`.
