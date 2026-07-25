# Context Access Telemetry

Added `lib/context_telemetry.py`, a versioned (`1.0.0`) deterministic event
contract aligned with `benchmark/analyzer-assisted-v1/result_schema.json`.
It aggregates useful reads, navigation reads, denials, query events, and
explicit missing/stale/unsupported signals into `context_metrics`.

`_AgentExecutionGuard` records navigation and source-read outcomes, exports
through an optional OTel-compatible adapter or no-op fallback, and includes
the aggregate in agent telemetry. `run_agent` copies the policy and supplies
the component name without mutating the caller's policy.

Validation: 65 focused tests passed; ruff and `git diff --check` passed. Query
events are available through the collector API; no query subprocess boundary
was changed because query execution remains in the separate Go CLI.
