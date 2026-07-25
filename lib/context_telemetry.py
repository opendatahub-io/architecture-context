"""Versioned context-access telemetry for architecture agent evaluation.

Records reads, navigation, denials, query invocations, and context-quality
signals during agent execution.  Aggregates into the ``context_metrics``
shape defined by ``benchmark/analyzer-assisted-v1/result_schema.json``.

The exporter interface is OTel-compatible but uses a no-op fallback when the
OpenTelemetry SDK is not installed, so telemetry collection never blocks
agent execution.
"""

from __future__ import annotations

import json
from dataclasses import asdict, dataclass, field
from enum import Enum
from typing import Protocol, runtime_checkable

CONTRACT_VERSION = "1.0.0"


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


def _resolve_exporter() -> ContextExporter:
    """Return an OTel exporter if available, otherwise NoOpExporter."""
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
