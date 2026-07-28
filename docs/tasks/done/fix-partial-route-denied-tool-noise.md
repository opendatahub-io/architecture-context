# Task: Fix Partial Route Denied Tool Noise

## Goal

Reduce avoidable denied tool calls during component generation and make
remaining denials easier to interpret in run reports.

## Bug

- `docs/bugs/fixed/generation-agents-attempt-denied-tools.md`

## Scope

- Explicitly tell component agents not to use `TodoWrite` on constrained
  routes.
- Verify restricted component runs exclude unnecessary planning/shell/sub-agent
  tools from SDK `allowed_tools`.
- Classify denied tool calls by diagnostic category in telemetry.
- Separate avoidable workflow noise from guardrail boundary denials.

## Execution record

- Updated the repo-to-architecture-summary partial and synthesis route
  contracts to prohibit `TodoWrite`.
- Added an explicit `TodoWrite` denial reason:
  `TodoWrite is disabled for component generation; keep any plan in prose and
  write only requested artifacts`.
- Added telemetry fields:
  - `denied_tool_calls_by_category`
  - `avoidable_workflow_denials`
- Classified avoidable workflow denials separately from guardrail/budget/input
  denials.
- Added tests proving restricted `run_agent` allowed-tools excludes
  `TodoWrite`, `Task`, and `Bash`, and that an attempted `TodoWrite` is
  categorized as `workflow-noise`.

## Validation

```bash
uv run ruff check lib/agent_runner.py tests/test_agent_runner.py
uv run pytest -q tests/test_agent_runner.py
uv run pytest -q tests/test_architecture_phase.py
uv run pytest -q tests/test_agent_runner.py tests/test_source_read_justifications.py tests/test_architecture_phase.py
```

Results:

- `tests/test_agent_runner.py`: `20 passed`
- `tests/test_architecture_phase.py`: `18 passed`
- combined focused suite: `46 passed`

The historical 97-component run is not rewritten; it remains the baseline with
97 `TodoWrite` denials. Future partial-route runs should eliminate those
denials by contract and continue to expose any attempted `TodoWrite` as
avoidable workflow noise if a model still attempts it.

## Status

Completed 2026-07-28.
