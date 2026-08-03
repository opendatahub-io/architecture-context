"""Versioned context-access telemetry for architecture agent evaluation.

Records reads, navigation, denials, query invocations, and context-quality
signals during agent execution.  Aggregates into the ``context_metrics``
shape defined by ``benchmark/analyzer-assisted-v1/result_schema.json``.

The exporter interface is OTel-compatible but uses a no-op fallback when the
OpenTelemetry SDK is not installed, so telemetry collection never blocks
agent execution.

The ``JsonlFileExporter`` provides an opt-in, failure-tolerant file export
boundary that writes OTel-compatible JSONL records for local CI or external
ingestion.  It is never activated by default.
"""

from __future__ import annotations

import json
import os
from dataclasses import asdict, dataclass, field
from datetime import datetime, timezone
from enum import Enum
from pathlib import Path
from typing import Protocol, runtime_checkable

CONTRACT_VERSION = "1.0.0"
EXPORT_VERSION = "1.0.0"


class EventKind(str, Enum):
    """Context access event classification."""

    READ_USEFUL = "read.useful"
    READ_NAVIGATION = "read.navigation"
    READ_DENIED = "read.denied"
    QUERY_ISSUED = "query.issued"
    QUERY_DENIED = "query.denied"
    SIGNAL_MISSING_CONTEXT = "signal.missing_context"
    SIGNAL_STALE_CONTEXT = "signal.stale_context"
    SIGNAL_UNSUPPORTED_INFERENCE = "signal.unsupported_inference"


@dataclass(frozen=True)
class ContextEvent:
    """A single instrumented context-access event."""

    kind: EventKind
    file: str | None = None
    component: str | None = None
    route: str | None = None
    detail: str | None = None


@dataclass
class ContextMetricsAggregate:
    """Deterministic aggregate matching the result_schema context_metrics."""

    context_fetches: int = 0
    useful_reads: int = 0
    navigation_reads: int = 0
    queries_issued: int = 0
    denied_reads: int = 0
    denied_queries: int = 0
    missing_context_detected: bool | None = None
    stale_context_detected: bool | None = None
    unsupported_inference_detected: bool | None = None

    def to_dict(self) -> dict[str, int | bool | None]:
        return asdict(self)


class ContextTelemetryCollector:
    """Collects context-access events and aggregates into context_metrics."""

    def __init__(
        self,
        *,
        component: str | None = None,
        route: str | None = None,
        exporter: ContextExporter | None = None,
    ):
        self._component = component
        self._route = route
        self._events: list[ContextEvent] = []
        self._exporter = exporter or _resolve_exporter()

    @property
    def events(self) -> list[ContextEvent]:
        return list(self._events)

    def record(self, kind: EventKind, **kwargs: str | None) -> None:
        event = ContextEvent(
            kind=kind,
            component=kwargs.get("component", self._component),
            route=kwargs.get("route", self._route),
            file=kwargs.get("file"),
            detail=kwargs.get("detail"),
        )
        self._events.append(event)
        self._exporter.export(event)

    def record_useful_read(self, file: str) -> None:
        self.record(EventKind.READ_USEFUL, file=file)

    def record_navigation_read(self, file: str) -> None:
        self.record(EventKind.READ_NAVIGATION, file=file)

    def record_denied_read(self, file: str | None = None, *, detail: str = "") -> None:
        self.record(EventKind.READ_DENIED, file=file, detail=detail)

    def record_query(self) -> None:
        self.record(EventKind.QUERY_ISSUED)

    def record_denied_query(self, *, detail: str = "") -> None:
        self.record(EventKind.QUERY_DENIED, detail=detail)

    def record_missing_context(self, *, detail: str = "") -> None:
        self.record(EventKind.SIGNAL_MISSING_CONTEXT, detail=detail)

    def record_stale_context(self, *, detail: str = "") -> None:
        self.record(EventKind.SIGNAL_STALE_CONTEXT, detail=detail)

    def record_unsupported_inference(self, *, detail: str = "") -> None:
        self.record(EventKind.SIGNAL_UNSUPPORTED_INFERENCE, detail=detail)

    def aggregate(self) -> ContextMetricsAggregate:
        """Produce the deterministic context_metrics aggregate."""
        useful = 0
        navigation = 0
        denied_reads = 0
        queries = 0
        denied_queries = 0
        missing = False
        stale = False
        unsupported = False
        has_missing_signal = False
        has_stale_signal = False
        has_unsupported_signal = False

        for event in self._events:
            if event.kind == EventKind.READ_USEFUL:
                useful += 1
            elif event.kind == EventKind.READ_NAVIGATION:
                navigation += 1
            elif event.kind == EventKind.READ_DENIED:
                denied_reads += 1
            elif event.kind == EventKind.QUERY_ISSUED:
                queries += 1
            elif event.kind == EventKind.QUERY_DENIED:
                denied_queries += 1
            elif event.kind == EventKind.SIGNAL_MISSING_CONTEXT:
                missing = True
                has_missing_signal = True
            elif event.kind == EventKind.SIGNAL_STALE_CONTEXT:
                stale = True
                has_stale_signal = True
            elif event.kind == EventKind.SIGNAL_UNSUPPORTED_INFERENCE:
                unsupported = True
                has_unsupported_signal = True

        return ContextMetricsAggregate(
            context_fetches=useful + navigation + queries,
            useful_reads=useful,
            navigation_reads=navigation,
            queries_issued=queries,
            denied_reads=denied_reads,
            denied_queries=denied_queries,
            missing_context_detected=missing if has_missing_signal else None,
            stale_context_detected=stale if has_stale_signal else None,
            unsupported_inference_detected=(
                unsupported if has_unsupported_signal else None
            ),
        )

    def context_metrics(self) -> dict[str, int | bool | None]:
        """Return context_metrics compatible with result_schema.json."""
        agg = self.aggregate()
        return {
            "context_fetches": agg.context_fetches,
            "useful_reads": agg.useful_reads,
            "navigation_reads": agg.navigation_reads,
            "queries_issued": agg.queries_issued,
            "missing_context_detected": agg.missing_context_detected,
            "stale_context_detected": agg.stale_context_detected,
            "unsupported_inference_detected": agg.unsupported_inference_detected,
        }

    def serialize(self) -> str:
        """Deterministic JSON serialization of the full telemetry record."""
        return json.dumps(
            {
                "contract_version": CONTRACT_VERSION,
                "component": self._component,
                "route": self._route,
                "events": [
                    {
                        "kind": e.kind.value,
                        "file": e.file,
                        "component": e.component,
                        "route": e.route,
                        "detail": e.detail,
                    }
                    for e in self._events
                ],
                "context_metrics": self.context_metrics(),
            },
            sort_keys=True,
        )


@runtime_checkable
class ContextExporter(Protocol):
    """Interface for exporting context events (OTel-compatible)."""

    def export(self, event: ContextEvent) -> None: ...

    def shutdown(self) -> None: ...


class NoOpExporter:
    """No-op exporter used when OTel SDK is unavailable."""

    def export(self, event: ContextEvent) -> None:
        pass

    def shutdown(self) -> None:
        pass


@dataclass
class InMemoryExporter:
    """Test exporter that captures events in memory."""

    exported: list[ContextEvent] = field(default_factory=list)

    def export(self, event: ContextEvent) -> None:
        self.exported.append(event)

    def shutdown(self) -> None:
        pass


class JsonlFileExporter:
    """Opt-in, failure-tolerant JSONL file exporter for local context events.

    Each exported event is written as one JSON line with versioned, parseable
    OTel-compatible fields: export_version, contract_version, event kind,
    route, source (component), timestamp, trace_id, and span_id.

    Activated only when explicitly constructed with a file path.  All I/O
    errors are caught silently so export never blocks agent execution.

    The optional ``max_events`` parameter bounds the number of records
    written; further events are silently dropped.
    """

    def __init__(
        self,
        path: str | Path,
        *,
        max_events: int = 10_000,
        trace_id: str | None = None,
        span_id: str | None = None,
    ):
        self._path = Path(path)
        self._max_events = max_events
        self._trace_id = trace_id or ""
        self._span_id = span_id or ""
        self._count = 0
        self._file = None
        try:
            self._path.parent.mkdir(parents=True, exist_ok=True)
            self._file = open(self._path, "a")  # noqa: SIM115
        except OSError:
            self._file = None

    def export(self, event: ContextEvent) -> None:
        if self._file is None or self._count >= self._max_events:
            return
        record = {
            "export_version": EXPORT_VERSION,
            "contract_version": CONTRACT_VERSION,
            "timestamp": datetime.now(timezone.utc).isoformat(),
            "trace_id": self._trace_id,
            "span_id": self._span_id,
            "event_kind": event.kind.value,
            "file": event.file,
            "component": event.component,
            "route": event.route,
            "detail": event.detail,
        }
        try:
            self._file.write(json.dumps(record, sort_keys=True) + "\n")
            self._file.flush()
            self._count += 1
        except OSError:
            pass

    def shutdown(self) -> None:
        if self._file is not None:
            try:
                self._file.close()
            except OSError:
                pass
            self._file = None

    @property
    def records_written(self) -> int:
        return self._count


def _resolve_exporter() -> ContextExporter:
    """Return an OTel exporter if available, otherwise NoOpExporter.

    When ``CONTEXT_TELEMETRY_JSONL_PATH`` is set, a ``JsonlFileExporter``
    is returned instead of the OTel or no-op default.  This provides an
    opt-in local export boundary without requiring the OTel SDK.
    """
    jsonl_path = os.environ.get("CONTEXT_TELEMETRY_JSONL_PATH")
    if jsonl_path:
        trace_id = os.environ.get("CONTEXT_TELEMETRY_TRACE_ID", "")
        span_id = os.environ.get("CONTEXT_TELEMETRY_SPAN_ID", "")
        return JsonlFileExporter(
            jsonl_path, trace_id=trace_id, span_id=span_id,
        )
    try:
        from opentelemetry import trace  # noqa: F401

        return _OTelSpanExporter()
    except ImportError:
        return NoOpExporter()


class _OTelSpanExporter:
    """Thin adapter that records context events as OTel span events."""

    def __init__(self) -> None:
        from opentelemetry import trace

        self._tracer = trace.get_tracer("context_telemetry", CONTRACT_VERSION)

    def export(self, event: ContextEvent) -> None:
        from opentelemetry import trace

        span = trace.get_current_span()
        if span.is_recording():
            attrs = {
                "context.event.kind": event.kind.value,
            }
            if event.file:
                attrs["context.event.file"] = event.file
            if event.component:
                attrs["context.event.component"] = event.component
            if event.route:
                attrs["context.event.route"] = event.route
            if event.detail:
                attrs["context.event.detail"] = event.detail
            span.add_event("context_access", attributes=attrs)

    def shutdown(self) -> None:
        pass
