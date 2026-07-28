# Task: Stage Generation Artifacts Before Final Promotion

## Goal

Prevent preseeded analyzer baselines and in-progress agent candidates from
appearing as completed top-level component architecture documents.

## Implementation

- Changed component generation so agents write to
  `architecture/<platform>/<component>/.generation/candidate.md`.
- Changed preseed behavior so analyzer baselines are copied to
  `.generation/preseed.md` and then used to initialize the candidate working
  document.
- Changed evidence-gated merge output so the merged document is written to
  `.generation/merged.md` and atomically promoted to
  `architecture/<platform>/<component>.md` only after validation.
- Added promotion for successful non-merged/legacy candidates so those also
  validate before replacing the top-level component Markdown.
- Updated agent guard telemetry/write classification to treat the configured
  primary output path as the architecture candidate instead of relying on the
  old `GENERATED_ARCHITECTURE.md` filename.
- Added regression coverage that the final top-level component file does not
  exist while an agent is still operating on a preseeded candidate.

## 2026-07-28 Amendment

Promotion now happens per completed agent rather than after the entire
concurrent batch finishes. The same staged artifact contract applies, but a
component's top-level Markdown appears as soon as its candidate has been
post-processed successfully.

## Validation

```bash
uv run ruff check lib/phases/architecture.py lib/agent_runner.py tests/test_architecture_phase.py tests/test_architecture_output_paths.py
uv run pytest tests/test_architecture_phase.py tests/test_agent_runner.py tests/test_architecture_output_paths.py tests/test_architecture_merge.py tests/test_architecture_baseline.py
```

All checks passed on 2026-07-28.

## Status

Complete.
