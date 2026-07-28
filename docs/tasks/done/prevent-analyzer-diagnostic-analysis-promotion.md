# Task: Prevent Analyzer Diagnostic Analysis Promotion

## Goal

Ensure final component `Architectural Analysis` sections are authored synthesis,
not copied analyzer diagnostics or unchanged preseed inventory bullets.

## Implementation

- Replaced arch-analyzer's final Markdown `Architectural Analysis` diagnostic
  bullets with a clear pending analyzer-assisted synthesis placeholder.
- Kept analyzer diagnostics in support artifacts such as
  `analyzer_synthesis_context.md` rather than the final Markdown baseline.
- Updated the repo-to-architecture skill and template to require authored
  narrative synthesis and forbid analyzer-internal diagnostics in final
  `Architectural Analysis`.
- Updated the architecture validator to fail final documents that retain
  analyzer placeholders or internal markers such as `Analyzer coverage`,
  `Category coverage`, `Coverage Findings`, `Deterministic Cross-References`,
  `Bounded Synthesis Evidence`, or deterministic inventory bullets.
- Changed restricted-route merge failure handling so analyzer baselines are
  retained only as generation diagnostics and are not promoted as successful
  final component Markdown.
- Restored missing CRD identity validation while extending validator coverage.

## Validation

```bash
uv run ruff check .claude/skills/repo-to-architecture-summary/scripts/validate_architecture.py tests/test_validate_architecture.py tests/test_architecture_phase.py lib/phases/architecture.py
uv run pytest tests/test_validate_architecture.py tests/test_architecture_phase.py tests/test_architecture_output_paths.py
uv run pytest tests/test_validate_architecture.py tests/test_architecture_phase.py tests/test_architecture_output_paths.py tests/test_agent_runner.py tests/test_architecture_merge.py
uv run pytest tests/test_architecture_baseline.py -k 'not test_rhoai_next_kueue_is_a_valid_baseline_fixture'
cd src/arch-analyzer && go test ./...
```

All implementation-focused checks passed on 2026-07-28. The excluded baseline
fixture test depends on `architecture/rhoai.next/kueue.md`, which is absent
during the active regeneration run.

## Status

Complete.
