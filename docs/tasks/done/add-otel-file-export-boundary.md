# Task: Add the OTel-Compatible File Export Boundary

## Goal

Make local analyzer-assisted context reads, queries, denials, and signals
exportable as opt-in OTel-compatible JSONL while preserving the no-op default;
do not claim to instrument the external fetch script that is not in this repo.

## Context

The architecture plan requires OTel spans to distinguish navigation, useful
reads, query use, missing context, stale context, and unsupported inference.
`lib/context_telemetry.py` had an optional SDK adapter, but no durable file
export boundary for CI or external ingestion.

## Scope and controls

- Add an opt-in injected/file exporter with versioned, parseable event records.
- Preserve no-op default, failure tolerance, bounded output, and existing
  metrics/result semantics.
- Do not modify or fabricate `fetch-architecture-context.sh`, add mandatory
  OTel dependencies, run evaluations/benchmarks, or change raw result/schema
  semantics.

## Acceptance criteria

- [x] Exported records have a documented version and fields sufficient to
  classify navigation/useful/query/denied/signal events without prose parsing.
- [x] Export is opt-in, bounded, and failure-tolerant; existing telemetry output
  remains compatible.
- [x] Documentation says the local export boundary is ready while the external
  fetch-script producer remains an explicit blocker.
- [x] Focused tests, validators, and `git diff --check` pass; no evaluation or
  benchmark is run.

## Implementation

Added `JsonlFileExporter` and `EXPORT_VERSION = "1.0.0"` to
`lib/context_telemetry.py`, plus 24 focused tests. Each JSONL record contains
the export and telemetry contract versions, UTC timestamp, trace/span IDs,
event kind, file, component, route, and detail. Export is available through
explicit exporter injection or `CONTEXT_TELEMETRY_JSONL_PATH` with optional
trace/span environment values. I/O failures are non-blocking and
`max_events` defaults to 10,000.

The local export boundary is ready. The external producer
(`fetch-architecture-context.sh`) is not present in this repository and remains
an explicit end-to-end instrumentation blocker.

## Validation

- 86 telemetry tests passed in the task container (24 new plus existing
  context-telemetry and evaluator-guard telemetry tests).
- Ruff passed; experiment/telemetry validation passed; `git diff --check`
  passed.
- No mandatory OTel dependency, evaluation, or benchmark was introduced/run.

## Status

Validated. External fetch-script instrumentation remains pending outside this
checkout.
