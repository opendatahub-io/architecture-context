# Integrate Evaluation Context Telemetry

Task: `docs/tasks/done/integrate-evaluation-context-telemetry.md`
Date: 2026-07-25

## Summary

Wired the existing versioned `ContextTelemetryCollector` into the consumer-v1
evaluation guard (`_EvalGuard`) so reads, denials, searches, and queries
populate deterministic `context_metrics` in per-tree telemetry and result
provenance. The collector uses condition-aware route labeling
(baseline/index/query/combined) for all instrumented events.

## Collector Integration

- `_EvalGuard.__init__` instantiates a `ContextTelemetryCollector` with the
  guard's condition label as the route.
- `_check_read` records useful reads, INDEX.md navigation reads, and denied
  reads as distinct event kinds.
- `_check_search` records navigation reads and denied search operations.
- `_check_query` records `query.issued` and `query.denied` events.
- `pre_tool_use` records denied tool calls.

## Route and Event Classification

Events use the existing `EventKind` values: `read.useful`, `read.navigation`,
`read.denied`, `query.issued`, and `query.denied`. Searches and denied tools
are recorded through the existing read-denial/navigation event categories.
Routes map to the four experiment conditions: `baseline`, `index`, `query`,
`combined`.

## Per-Tree context_metrics and context_provenance

- `guard.telemetry()` includes a `context_metrics` dict with deterministic
  event counts keyed by event kind.
- `guard.context_provenance()` returns serialized event data with contract
  version and event list for attachment to per-tree results.
- `run_question_against_tree()` attaches `context_provenance` to both success
  and error return dicts.

## Condition-Level Provenance

`run_evaluation()` adds a `context_provenance` block to condition-level
`raw_results["provenance"]` containing `context_telemetry_version` and
`events_attached_per_tree: True`.

## Optional OTel / No-Op Behavior

The collector resolves an OTel-compatible exporter when the SDK is available;
tests can inject `InMemoryExporter`. When the SDK is unavailable, the no-op
exporter is used — no runtime dependency is required.
Export is non-blocking in all paths.

## Tests

40 focused tests in `tests/test_eval_guard_telemetry.py` across 9 classes:

| Class | Count | Coverage |
|-------|-------|----------|
| TestBaselineContextMetrics | 5 | Baseline condition event recording |
| TestIndexContextMetrics | 4 | INDEX.md navigation vs useful reads |
| TestQueryContextMetrics | 4 | Query issued/denied events |
| TestCombinedContextMetrics | 4 | Combined condition event recording |
| TestExporterIntegration | 4 | InMemory and no-op exporter behavior |
| TestSerializationAndProvenance | 5 | JSON serialization, version, provenance |
| TestBackwardCompatibility | 3 | Schema compat without telemetry fields |
| TestSearchDenialTracking | 4 | Search denial event classification |
| TestContextProvenanceInResults | 7 | Per-tree and condition-level provenance |

## Validation

- 287 related focused tests passed, including 40 telemetry-integration tests
- Ruff lint: PASS
- `git diff --check`: PASS
- Result schema compatibility preserved
- No evaluation, agent, or paid call was run

## No-Evaluation Evidence

No `run_evaluation()` call was executed. No agent was launched. No paid API
call was made. The task is pure instrumentation and test coverage. Estimated
cost: $0.00.
