# Task: Rework Consumer V1 Rolling Inventory Questions

## Goal

Remove or retarget consumer-v1 questions that depend on exact file counts in
the rolling `rhoai.next` architecture target.

## Context

`NAV-008` expected 94 Markdown files, but the clean `20260729T120959Z` eval
trees each contained 98 top-level Markdown files. Exact file-count questions
are brittle unless pinned to an immutable architecture snapshot.

Tracking bug:
`docs/bugs/open/consumer-v1-rolling-file-count-question-brittle.md`.

## Plan

1. Decide whether `NAV-008` should be retired, pinned, or rewritten as a
   navigability question.
2. Update `benchmark/consumer-v1/corpus.json` and the analyzer-assisted corpus
   manifest consistently.
3. Validate corpus size, tier balance, and required-scope metadata.
4. Rerun or re-score the affected consumer-v1 slice.

## Acceptance Criteria

- Rolling `rhoai.next` file-count drift no longer appears as a quality
  regression.
- The corpus still has valid tier balance and source-backed expected answers.
- The change is documented in the evaluation notes or task record.

## Status

Pending.
