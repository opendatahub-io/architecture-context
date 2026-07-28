# Task: Promote Generation Artifacts Per Completed Agent

## Goal

Make `architecture/<platform>/<component>.md` appear as soon as that
component's agent output has passed post-processing, instead of waiting for all
parallel agents in the phase to finish.

## Implementation

- Added an optional per-job result callback to `run_agents_concurrently`.
- Moved component post-processing into that callback for the architecture
  phase: crash recovery, source-read justification validation, merge,
  validation, promotion, duration footer, and run-report writing now happen
  immediately after each agent result.
- Kept a compatibility pass for tests or alternate callers that replace
  `run_agents_concurrently` and do not invoke the callback.
- Added regression coverage proving the first completed component is promoted
  while a second component is still unpromoted.

## Validation

```bash
uv run ruff check lib/phases/architecture.py lib/agent_runner.py tests/test_architecture_output_paths.py
uv run pytest tests/test_architecture_phase.py tests/test_agent_runner.py tests/test_architecture_output_paths.py
uv run pytest tests/test_architecture_phase.py tests/test_agent_runner.py tests/test_architecture_output_paths.py tests/test_architecture_merge.py
uv run pytest tests/test_architecture_baseline.py -k 'not test_rhoai_next_kueue_is_a_valid_baseline_fixture'
```

All implementation-focused checks passed on 2026-07-28. The full adjacent
suite had one generated-fixture failure because
`architecture/rhoai.next/kueue.md` was absent from the active output tree during
an in-progress regeneration run.

## Status

Complete.
