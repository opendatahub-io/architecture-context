# Task: Add Phase Context to Concurrent Progress Bars

## Goal

Make every multi-process agent progress panel self-describing by showing the
current pipeline phase alongside completion, running jobs, elapsed time, and
ETA.

## Scope

- Add an optional phase label/context field to `AgentProgress` and
  `run_agents_concurrently`.
- Render the phase context as a stable header inside the live progress panel;
  optionally log a one-time phase-start message.
- Pass explicit labels from component architecture, platform architecture, and
  platform/component diagram callers, including phase numbers where applicable.
- Preserve single-job behavior, non-TTY/captured-output handling, progress
  counts, ETA, failure reporting, and existing output compatibility.
- Add focused tests for rendering and propagation; do not modify generated
  architecture outputs.

## Execution record

- Added optional `phase_label` propagation through `AgentProgress` and
  `run_agents_concurrently`.
- Added stable live-panel labels for Phase 3, Phase 5, Phase 6a, and Phase 6b.
- Added five focused tests covering rendering, defaults, propagation, and the
  single-job path.
- Validation: `PYTHONPATH=. ./.venv/bin/pytest -q tests/test_agent_runner.py`
  (13 passed), Python compilation passed, and scoped `git diff --check` passed.
- Delegated run log: `/tmp/claude-task-runs/agent-driver.jsonl`; reported cost
  `$2.4691055`; generated architecture outputs were untouched.

## Status

Completed and accepted 2026-07-27.
