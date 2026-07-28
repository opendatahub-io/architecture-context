# Task: Remove Source References from Final Architecture Markdown

## Goal

Keep generated component architecture summaries focused on human-readable
architecture content while preserving detailed source-read audit data under each
component's `.generation` directory.

## Context

The `Source References` section duplicated data that is already better captured
as machine-readable generation metadata, especially
`.generation/SOURCE_READ_JUSTIFICATIONS.json`. Keeping file-read tables in the
final Markdown inflated the narrative template and encouraged agents to treat
audit bookkeeping as part of the architecture document.

## Implementation

- Removed `## Source References` and its files-read/search subsections from the
  repo-to-architecture summary template.
- Updated the skill contract to require inline citations for architecture
  claims and to place source-read audit metadata in the
  `SOURCE_READ_JUSTIFICATIONS.json` sidecar.
- Updated the template validator and architecture baseline section contract so
  final Markdown no longer requires the source-reference section.
- Stopped the arch-analyzer Markdown renderer from emitting final
  source-reference tables while retaining bounded inline provenance and
  analyzer evidence summaries.
- Updated merge tests so evidence-backed changes remain audited through merge
  decisions instead of rendered as final Markdown read tables.

## Validation

```bash
uv run pytest tests/test_architecture_merge.py tests/test_architecture_baseline.py tests/test_architecture_phase.py tests/test_architecture_output_paths.py tests/test_source_read_justifications.py
uv run ruff check .claude/skills/repo-to-architecture-summary/scripts/validate_architecture.py lib/architecture_baseline.py tests/test_architecture_merge.py
GOCACHE=/tmp/arch-analyzer-go-cache go test ./internal/renderer
```

All checks passed on 2026-07-28.

## Status

Complete.
