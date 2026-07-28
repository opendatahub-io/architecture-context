# Task: Add Component Runtime Breakdown Reports

## Goal

Make partial-route runtime problems diagnosable from each component
`*.run.json` record without re-parsing raw Claude logs.

## Bug

- `docs/bugs/open/partial-route-component-runtime-remains-high.md`

## Scope

- Add durable agent activity counters for analyzer-context reads, targeted
  source reads, targeted discovery, architecture output edits, sidecar writes,
  and denied calls.
- Record orchestrator-side timings for analyzer preseed, merge, merged
  document validation, insight archive/validation, and source-read
  justification validation.
- Persist a compact `runtime_breakdown` object in each component run report.
- Do not claim the high-runtime bug is fully fixed until a follow-up
  full-platform run compares wall-clock and per-component runtime.

## Execution record

- Extended `_AgentExecutionGuard` telemetry with `tool_calls_by_activity`.
- Added `phase_timings` and `runtime_breakdown` to architecture generation run
  reports.
- Added focused regression coverage for guard activity categorization and run
  report persistence.

## Validation

```bash
uv run pytest tests/test_agent_runner.py tests/test_architecture_phase.py
```

Result: 39 passed.

## Status

Completed 2026-07-28.
