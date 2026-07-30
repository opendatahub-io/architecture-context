# Task: Fix Analyzer Snapshot Output Layout

## Goal

Allow the full `rhoai.next` architecture wrapper to proceed from successful
static analysis into component generation.

## Evidence

The run at
`tmp/architecture-corpus-runs/rhoai.next-20260730T192039Z-851562/` completed
static analysis for all 97 components, then exited during `snapshot-analyzers`.
The snapshot helper searched checkout roots for analyzer artifacts, while the
current static-analysis phase stores them under the candidate architecture
tree's per-component `.analyzer/` directory.

## Plan

1. Prefer candidate-tree analyzer artifacts during snapshot.
2. Retain checkout-root lookup for older run layouts.
3. Add regression coverage and validate the wrapper end to end.

## Acceptance Criteria

- A candidate-tree `.analyzer` artifact pair is copied into the run analyzer
  snapshot.
- The existing checkout-root compatibility behavior remains covered.
- The full wrapper reaches component generation after static analysis.

## Status

Accepted 2026-07-30 after the full wrapper run completed static analysis and
component generation for all 97 components.

## Validation

- `uv run pytest tests/test_architecture_corpus.py -q` passed with 26 tests.
- Ruff and Python compilation passed after formatting correction.
- Full run
  `tmp/architecture-corpus-runs/rhoai.next-20260730T194519Z-863253/` copied
  97/97 analyzer artifact pairs and completed component generation with zero
  phase failures.
