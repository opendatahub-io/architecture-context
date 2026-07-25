"""Tests for lib.context_telemetry — event model, aggregation, and export."""

from __future__ import annotations

import json
import sys
from pathlib import Path

import pytest

PROJECT_ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(PROJECT_ROOT))

from lib.context_telemetry import (  # noqa: E402
    CONTRACT_VERSION,
    ContextEvent,
    ContextMetricsAggregate,
    ContextTelemetryCollector,
    EventKind,
    InMemoryExporter,
    NoOpExporter,
)

# ---------------------------------------------------------------------------
# Event classification
# ---------------------------------------------------------------------------


def test_event_kinds_are_string_enum_values():
    assert EventKind.READ_USEFUL.value == "read.useful"
    assert EventKind.READ_NAVIGATION.value == "read.navigation"
    assert EventKind.READ_DENIED.value == "read.denied"
    assert EventKind.QUERY_ISSUED.value == "query.issued"
    assert EventKind.SIGNAL_MISSING_CONTEXT.value == "signal.missing_context"
    assert EventKind.SIGNAL_STALE_CONTEXT.value == "signal.stale_context"
    assert EventKind.SIGNAL_UNSUPPORTED_INFERENCE.value == (
        "signal.unsupported_inference"
    )


def test_context_event_defaults():
    event = ContextEvent(kind=EventKind.READ_USEFUL)
    assert event.file is None
    assert event.component is None
    assert event.route is None
    assert event.detail is None


# ---------------------------------------------------------------------------
# Aggregation
# ---------------------------------------------------------------------------


def test_empty_collector_aggregates_to_zeros():
    collector = ContextTelemetryCollector()
    agg = collector.aggregate()
    assert agg.context_fetches == 0
    assert agg.useful_reads == 0
    assert agg.navigation_reads == 0
    assert agg.queries_issued == 0
    assert agg.denied_reads == 0
    assert agg.missing_context_detected is None
    assert agg.stale_context_detected is None
    assert agg.unsupported_inference_detected is None


def test_useful_and_navigation_reads_aggregate():
    collector = ContextTelemetryCollector(component="test", route="synthesis")
    collector.record_useful_read("src/main.py")
    collector.record_useful_read("src/util.py")
    collector.record_navigation_read("ANALYZER_ARCHITECTURE.md")
    agg = collector.aggregate()
    assert agg.useful_reads == 2
    assert agg.navigation_reads == 1
    assert agg.context_fetches == 3


def test_denied_reads_counted_separately_from_context_fetches():
    collector = ContextTelemetryCollector(route="synthesis")
    collector.record_useful_read("src/allowed.py")
    collector.record_denied_read(file="src/denied.py", detail="budget exhausted")
    agg = collector.aggregate()
    assert agg.useful_reads == 1
    assert agg.denied_reads == 1
    assert agg.context_fetches == 1


def test_queries_aggregate():
    collector = ContextTelemetryCollector(route="combined")
    collector.record_query()
    collector.record_query()
    collector.record_denied_query(detail="tool denied")
    agg = collector.aggregate()
    assert agg.queries_issued == 2
    assert agg.denied_queries == 1
    assert agg.context_fetches == 2


def test_signal_flags_set_on_detection():
    collector = ContextTelemetryCollector()
    assert collector.aggregate().missing_context_detected is None
    collector.record_missing_context(detail="no CRD data")
    assert collector.aggregate().missing_context_detected is True

    collector.record_stale_context(detail="version outdated")
    assert collector.aggregate().stale_context_detected is True

    collector.record_unsupported_inference(detail="threshold inferred")
    assert collector.aggregate().unsupported_inference_detected is True


def test_signals_remain_none_when_never_recorded():
    collector = ContextTelemetryCollector()
    collector.record_useful_read("src/app.py")
    agg = collector.aggregate()
    assert agg.missing_context_detected is None
    assert agg.stale_context_detected is None
    assert agg.unsupported_inference_detected is None


# ---------------------------------------------------------------------------
# context_metrics schema compatibility
# ---------------------------------------------------------------------------


def test_context_metrics_matches_result_schema_keys():
    schema_path = (
        PROJECT_ROOT
        / "benchmark"
        / "analyzer-assisted-v1"
        / "result_schema.json"
    )
    schema = json.loads(schema_path.read_text())
    expected_keys = set(
        schema["properties"]["context_metrics"]["properties"].keys()
    )
    collector = ContextTelemetryCollector()
    actual_keys = set(collector.context_metrics().keys())
    assert actual_keys == expected_keys


def test_context_metrics_values_satisfy_schema_types():
    collector = ContextTelemetryCollector()
    collector.record_useful_read("src/a.py")
    collector.record_navigation_read("ANALYZER_ARCHITECTURE.md")
    collector.record_query()
    metrics = collector.context_metrics()
    assert isinstance(metrics["context_fetches"], int)
    assert isinstance(metrics["useful_reads"], int)
    assert isinstance(metrics["navigation_reads"], int)
    assert isinstance(metrics["queries_issued"], int)
    assert metrics["missing_context_detected"] is None
    assert metrics["stale_context_detected"] is None
    assert metrics["unsupported_inference_detected"] is None


# ---------------------------------------------------------------------------
# Deterministic serialization
# ---------------------------------------------------------------------------


def test_serialize_is_deterministic():
    c1 = ContextTelemetryCollector(component="example", route="synthesis")
    c2 = ContextTelemetryCollector(component="example", route="synthesis")
    for c in (c1, c2):
        c.record_useful_read("src/main.py")
        c.record_navigation_read("ANALYZER_ARCHITECTURE.md")
        c.record_denied_read(file="secret.env", detail="budget exhausted")
    assert c1.serialize() == c2.serialize()


def test_serialize_includes_contract_version():
    collector = ContextTelemetryCollector(component="test", route="partial")
    data = json.loads(collector.serialize())
    assert data["contract_version"] == CONTRACT_VERSION
    assert data["component"] == "test"
    assert data["route"] == "partial"


def test_serialize_round_trips_through_json():
    collector = ContextTelemetryCollector()
    collector.record_useful_read("a.py")
    collector.record_missing_context(detail="no auth")
    raw = collector.serialize()
    parsed = json.loads(raw)
    re_encoded = json.dumps(parsed, sort_keys=True)
    assert raw == re_encoded


# ---------------------------------------------------------------------------
# Exporter behavior
# ---------------------------------------------------------------------------


def test_no_op_exporter_does_not_raise():
    exporter = NoOpExporter()
    event = ContextEvent(kind=EventKind.READ_USEFUL, file="test.py")
    exporter.export(event)
    exporter.shutdown()


def test_in_memory_exporter_captures_events():
    exporter = InMemoryExporter()
    collector = ContextTelemetryCollector(exporter=exporter)
    collector.record_useful_read("src/app.py")
    collector.record_denied_read(file="secret.py", detail="denied")
    assert len(exporter.exported) == 2
    assert exporter.exported[0].kind == EventKind.READ_USEFUL
    assert exporter.exported[1].kind == EventKind.READ_DENIED


def test_collector_uses_no_op_when_otel_unavailable():
    collector = ContextTelemetryCollector()
    collector.record_useful_read("src/app.py")
    assert len(collector.events) == 1


# ---------------------------------------------------------------------------
# ContextMetricsAggregate.to_dict
# ---------------------------------------------------------------------------


def test_aggregate_to_dict():
    agg = ContextMetricsAggregate(
        context_fetches=5,
        useful_reads=3,
        navigation_reads=2,
        queries_issued=0,
        denied_reads=1,
        denied_queries=0,
        missing_context_detected=True,
        stale_context_detected=None,
        unsupported_inference_detected=None,
    )
    d = agg.to_dict()
    assert d["context_fetches"] == 5
    assert d["useful_reads"] == 3
    assert d["missing_context_detected"] is True
    assert d["stale_context_detected"] is None


# ---------------------------------------------------------------------------
# Guard integration: context_metrics in telemetry output
# ---------------------------------------------------------------------------


@pytest.mark.asyncio
async def test_guard_telemetry_includes_context_metrics(tmp_path: Path):
    from lib.agent_runner import _AgentExecutionGuard

    checkout = tmp_path / "checkout"
    source = checkout / "src" / "app.py"
    source.parent.mkdir(parents=True)
    source.write_text("print('ok')\n")
    guard = _AgentExecutionGuard({"route": "legacy"}, checkout)

    await guard.pre_tool_use(
        {"tool_name": "Read", "tool_input": {"file_path": str(source)}},
        None,
        {},
    )

    telemetry = guard.telemetry()
    assert "context_metrics" in telemetry
    metrics = telemetry["context_metrics"]
    assert metrics["useful_reads"] == 1
    assert metrics["navigation_reads"] == 0


@pytest.mark.asyncio
async def test_guard_classifies_architecture_doc_reads_as_navigation(tmp_path: Path):
    from lib.agent_runner import _AgentExecutionGuard

    checkout = tmp_path / "checkout"
    checkout.mkdir()
    arch = checkout / "ANALYZER_ARCHITECTURE.md"
    arch.write_text("# Component\n")
    guard = _AgentExecutionGuard({"route": "legacy"}, checkout)

    await guard.pre_tool_use(
        {"tool_name": "Read", "tool_input": {"file_path": str(arch)}},
        None,
        {},
    )

    metrics = guard.telemetry()["context_metrics"]
    assert metrics["navigation_reads"] == 1
    assert metrics["useful_reads"] == 0


@pytest.mark.asyncio
async def test_guard_records_denied_reads_in_context_metrics(tmp_path: Path):
    from lib.agent_runner import _AgentExecutionGuard

    checkout = tmp_path / "checkout"
    checkout.mkdir()
    denied = checkout / "denied.py"
    denied.write_text("denied\n")
    guard = _AgentExecutionGuard(
        {
            "route": "synthesis",
            "readiness": "sufficient",
            "source_files": [],
            "discovery_tools": [],
        },
        checkout,
    )

    await guard.pre_tool_use(
        {"tool_name": "Read", "tool_input": {"file_path": str(denied)}},
        None,
        {},
    )

    agg = guard.ctx_telemetry.aggregate()
    assert agg.denied_reads == 1
    assert agg.useful_reads == 0


@pytest.mark.asyncio
async def test_guard_context_exporter_receives_events(tmp_path: Path):
    from lib.agent_runner import _AgentExecutionGuard
    from lib.context_telemetry import InMemoryExporter

    checkout = tmp_path / "checkout"
    source = checkout / "src" / "app.py"
    source.parent.mkdir(parents=True)
    source.write_text("ok\n")
    exporter = InMemoryExporter()
    guard = _AgentExecutionGuard(
        {"route": "legacy"}, checkout, context_exporter=exporter,
    )

    await guard.pre_tool_use(
        {"tool_name": "Read", "tool_input": {"file_path": str(source)}},
        None,
        {},
    )

    assert len(exporter.exported) == 1
    assert exporter.exported[0].kind == EventKind.READ_USEFUL


@pytest.mark.asyncio
async def test_partial_guard_denied_read_recorded_in_telemetry(tmp_path: Path):
    from lib.agent_runner import _AgentExecutionGuard

    checkout = tmp_path / "checkout"
    checkout.mkdir()
    first = checkout / "first.py"
    second = checkout / "second.py"
    first.write_text("first\n")
    second.write_text("second\n")
    guard = _AgentExecutionGuard(
        {
            "route": "partial",
            "readiness": "partial",
            "gap_categories": ["http_endpoints"],
            "source_files": [],
            "file_budget": 1,
            "discovery_tools": ["Glob", "Grep"],
        },
        checkout,
    )

    await guard.pre_tool_use(
        {"tool_name": "Read", "tool_input": {"file_path": str(first)}},
        None,
        {},
    )
    await guard.pre_tool_use(
        {"tool_name": "Read", "tool_input": {"file_path": str(second)}},
        None,
        {},
    )

    agg = guard.ctx_telemetry.aggregate()
    assert agg.useful_reads == 1
    assert agg.denied_reads == 1
    assert agg.context_fetches == 1
