# Task: Move Purpose Below Architectural Analysis

## Goal

Make component summaries lead with synthesis by placing `Purpose` immediately
after `Architectural Analysis` and before provenance/inventory detail.

## Implementation

- Moved `## Purpose` in the repo-to-architecture template to directly follow
  `## Architectural Analysis`.
- Updated the validator so `Architectural Analysis` must appear before
  `Purpose`, and `Provenance` must appear after `Purpose` and before
  `Architecture Components`.
- Updated the arch-analyzer Markdown renderer so analyzer-preseeded baselines
  use the same order.
- Updated the generated fixture table-count assertion to account for the
  removed source-reference tables.

## Validation

```bash
uv run ruff check .claude/skills/repo-to-architecture-summary/scripts/validate_architecture.py
uv run pytest tests/test_architecture_baseline.py tests/test_architecture_merge.py tests/test_architecture_phase.py tests/test_architecture_output_paths.py
go test ./internal/renderer
```

All checks passed on 2026-07-28.

## Status

Complete.
