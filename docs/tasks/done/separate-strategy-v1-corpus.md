# Task: Separate Strategy v1 Corpus

## Goal

Keep strategy-pipeline and SME-context evaluation questions separate from the
architecture-only consumer benchmark while preserving the compiled corpus.

## Changes

- Moved `benchmark/consumer-v1/corpus-2.json` to
  `benchmark/strategy-v1/corpus.json`.
- Added per-question `domain` labels for architecture, pipeline, and
  SME-context questions.
- Added provenance and reproducibility requirements in the strategy corpus
  README.
- Left `benchmark/consumer-v1/corpus.json` unchanged.

## Status

Accepted 2026-07-30. The strategy corpus remains a source artifact until a
strategy-specific runner, validator, and pinned external skill/Jira inputs
are available.
