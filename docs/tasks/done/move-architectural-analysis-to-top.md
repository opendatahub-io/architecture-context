# Task: Move Architectural Analysis to the Top

## Goal

Make `Architectural Analysis` the first substantive section in component
architecture summaries so readers see the synthesized interpretation before
provenance and detailed inventories.

## Implementation

- Moved `## Architectural Analysis` in the repo-to-architecture template to
  immediately after `## Metadata` and before `## Provenance`.
- Updated the template validator to enforce `Provenance` after
  `Architectural Analysis` when both sections are present.
- Updated the arch-analyzer Markdown renderer so analyzer-preseeded baselines
  follow the same section order.

## Validation

```bash
uv run ruff check .claude/skills/repo-to-architecture-summary/scripts/validate_architecture.py
uv run pytest tests/test_architecture_baseline.py tests/test_architecture_merge.py tests/test_architecture_phase.py tests/test_architecture_output_paths.py
go test ./internal/renderer
```

All checks passed on 2026-07-28.

## Status

Complete.
