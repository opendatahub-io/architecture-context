# Task: Add Context Access Telemetry for Evaluation

## Goal

Implement the instrumentation baseline required by the analyzer-assisted plan:
record context fetches, navigation reads, useful source reads, query use,
missing/stale context signals, and unsupported-inference signals in a stable
telemetry contract that can populate the existing evaluation result schema.

## Scope

- Inspect the existing agent guard, query command boundary, evaluation result
  schema, and available telemetry dependencies before choosing the adapter.
- Add a small versioned telemetry/event model with deterministic serialization
  and explicit null/unknown values when a metric is unavailable.
- Instrument the existing Python agent execution boundary for tool reads,
  navigation, query invocations, denials, and route/readiness context; expose
  aggregate `context_metrics` without changing routing or fact ownership.
- If direct OTel SDK integration is unavailable, use an optional adapter with a
  documented no-op fallback and keep the event fields OTel-compatible.
- Add focused tests for event classification, aggregation, serialization,
  denied reads, and no-op behavior.

## Negative controls

- Do not run paid or full-corpus evaluations.
- Do not change route semantics, analyzer extraction, query result semantics,
  merge behavior, generated architecture output, or source permissions.
- Do not fabricate missing/stale/unsupported signals; represent unavailable
  metrics explicitly.

## Acceptance criteria

- [x] Versioned telemetry contract matches the existing evaluation schema's
  context metrics and provenance needs.
- [x] Agent reads, navigation, denials, and query/use events aggregate
  deterministically with route and component context.
- [x] Optional exporter/no-op behavior is tested and does not affect agent
  execution when telemetry is unavailable.
- [x] Focused tests, lint, task note, session log, PLAN, and accepted scoped
  commit are recorded.

## Status

Done. Accepted after review; focused tests and lint pass.

## Validation

- `.venv/bin/pytest -q tests/test_context_telemetry.py tests/test_agent_runner.py tests/test_architecture_routing.py tests/test_architecture_phase.py`: 65 passed
- `.venv/bin/ruff check lib/context_telemetry.py lib/agent_runner.py tests/test_context_telemetry.py tests/test_agent_runner.py tests/test_architecture_routing.py tests/test_architecture_phase.py`: passed
- `git diff --check`: passed
- No paid/full-corpus evaluation was run.

Accepted commit: `4627ce4b`.
