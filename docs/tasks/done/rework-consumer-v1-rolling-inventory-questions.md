# Task: Rework Consumer V1 Rolling Inventory Questions

## Goal

Remove or retarget consumer-v1 questions that depend on exact file counts in
the rolling `rhoai.next` architecture target.

## Context

`NAV-008` expected 94 Markdown files, but the clean `20260729T120959Z` eval
trees each contained 98 top-level Markdown files. Exact file-count questions
are brittle unless pinned to an immutable architecture snapshot.

Tracking bug:
`docs/bugs/fixed/consumer-v1-rolling-file-count-question-brittle.md`.

The clean `20260729T120959Z` Tree A and Tree B snapshots both had 98
top-level Markdown files, but the sets differed. Tree B was missing
`README.md`, `llm-d-batch-gateway.md`, `llm-d-model-service.md`, and
`llm-d-workload-variant-autoscaler.md` relative to Tree A; it added
`llama-stack-provider-ragas.md`, `models-perf-benchmark-data.md`,
`rhds-llama-stack-distribution.md`, and `training_hub.md`. That confirms the
problem is rolling inventory/name drift, not a stable missing-file defect.

## Plan

1. Decide whether `NAV-008` should be retired, pinned, or rewritten as a
   navigability question.
2. Update `benchmark/consumer-v1/corpus.json` and the analyzer-assisted corpus
   manifest consistently.
3. Validate corpus size, tier balance, and required-scope metadata.
4. Rerun or re-score the affected consumer-v1 slice. Because the prompt text
   changed, existing raw results for the old count question are not a valid
   semantic re-score for the new layout question; the next eval verification
   should be a focused `NAV-008` rerun.

## Acceptance Criteria

- Rolling `rhoai.next` file-count drift no longer appears as a quality
  regression.
- The corpus still has valid tier balance and source-backed expected answers.
- The change is documented in the evaluation notes or task record.

## Status

Done 2026-07-30. `NAV-008` now asks where component architecture documents
are stored in `rhoai.next` and which platform-level architecture file
accompanies them. The expected answer describes the flat top-level Markdown
layout and `PLATFORM.md` instead of asserting a fixed file count. The focused
`20260730T020654Z` re-evaluation showed both trees answered correctly and
cited sources, but exact-match failed because the accepted variants did not
cover the observed "individual Markdown files at/directly in the tree root"
phrasing. Added those narrow variants and regression tests.

Amended 2026-07-30 after the full `20260730T110242Z` evaluation flagged
`NAV-008` as a Tree B source-citation regression. Tree B answered the layout
question correctly and read/cited `PLATFORM.md`, but the corpus only allowed
`architecture/rhoai.next/` as the citation source. Added optional
`source_files` scoring support and declared `architecture/rhoai.next/PLATFORM.md`
as a secondary NAV-008 citation source. Rescoring the unchanged raw results
moved Tree B from 0.5458 to 0.5583 overall and removed the final flagged
regression.
