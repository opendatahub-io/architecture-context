# Task: Swap Purpose and Architectural Analysis

## Goal

Use `Purpose` as the first narrative section after metadata, followed by
`Architectural Analysis`, then provenance and detailed inventories.

## Implementation

- Reordered the component architecture template to start
  `Metadata`, `Purpose`, `Architectural Analysis`, `Provenance`.
- Updated the validator so `Architectural Analysis` must appear after
  `Purpose`, and `Provenance` must still appear after both narrative sections.
- Updated the arch-analyzer Markdown renderer so analyzer-preseeded baselines
  follow the same order.

## Validation

```bash
uv run ruff check .claude/skills/repo-to-architecture-summary/scripts/validate_architecture.py
uv run pytest tests/test_architecture_baseline.py tests/test_architecture_merge.py tests/test_architecture_phase.py tests/test_architecture_output_paths.py
go test ./internal/renderer
```

All checks passed on 2026-07-28.

## Status

Complete.
