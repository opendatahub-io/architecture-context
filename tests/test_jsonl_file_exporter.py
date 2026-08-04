"""Tests for JsonlFileExporter — serialization, opt-in, failure tolerance."""

from __future__ import annotations

import json
import sys
from pathlib import Path

PROJECT_ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(PROJECT_ROOT))

from lib.context_telemetry import (  # noqa: E402
    CONTRACT_VERSION,
    EXPORT_VERSION,
    ContextEvent,
    ContextExporter,
    ContextTelemetryCollector,
    EventKind,
    JsonlFileExporter,
    NoOpExporter,
)

# ---------------------------------------------------------------------------
# Serialization format
# ---------------------------------------------------------------------------


class TestJsonlSerialization:
    """Each exported line is valid JSON with the documented fields."""

    def test_single_event_produces_one_json_line(self, tmp_path):
        out = tmp_path / "events.jsonl"
        exporter = JsonlFileExporter(out)
        event = ContextEvent(
            kind=EventKind.READ_USEFUL, file="src/main.py",
            component="dashboard", route="synthesis",
        )
        exporter.export(event)
        exporter.shutdown()
        lines = out.read_text().strip().splitlines()
        assert len(lines) == 1
        record = json.loads(lines[0])
        assert record["export_version"] == EXPORT_VERSION
        assert record["contract_version"] == CONTRACT_VERSION
        assert record["event_kind"] == "read.useful"
        assert record["file"] == "src/main.py"
        assert record["component"] == "dashboard"
        assert record["route"] == "synthesis"

    def test_timestamp_is_iso8601_utc(self, tmp_path):
        out = tmp_path / "events.jsonl"
        exporter = JsonlFileExporter(out)
        exporter.export(ContextEvent(kind=EventKind.READ_USEFUL))
        exporter.shutdown()
        record = json.loads(out.read_text().strip())
        ts = record["timestamp"]
        assert "T" in ts
        assert ts.endswith("+00:00") or ts.endswith("Z")

    def test_trace_and_span_correlation(self, tmp_path):
        out = tmp_path / "events.jsonl"
        exporter = JsonlFileExporter(
            out, trace_id="abc123", span_id="span456",
        )
        exporter.export(ContextEvent(kind=EventKind.QUERY_ISSUED))
        exporter.shutdown()
        record = json.loads(out.read_text().strip())
        assert record["trace_id"] == "abc123"
        assert record["span_id"] == "span456"

    def test_default_trace_span_are_empty_strings(self, tmp_path):
        out = tmp_path / "events.jsonl"
        exporter = JsonlFileExporter(out)
        exporter.export(ContextEvent(kind=EventKind.READ_NAVIGATION))
        exporter.shutdown()
        record = json.loads(out.read_text().strip())
        assert record["trace_id"] == ""
        assert record["span_id"] == ""

    def test_multiple_events_produce_multiple_lines(self, tmp_path):
        out = tmp_path / "events.jsonl"
        exporter = JsonlFileExporter(out)
        kinds = (EventKind.READ_USEFUL, EventKind.READ_DENIED, EventKind.QUERY_ISSUED)
        for kind in kinds:
            exporter.export(ContextEvent(kind=kind))
        exporter.shutdown()
        lines = out.read_text().strip().splitlines()
        assert len(lines) == 3
        kinds = [json.loads(line)["event_kind"] for line in lines]
        assert kinds == ["read.useful", "read.denied", "query.issued"]

    def test_all_event_kinds_serializable(self, tmp_path):
        out = tmp_path / "events.jsonl"
        exporter = JsonlFileExporter(out)
        for kind in EventKind:
            exporter.export(ContextEvent(kind=kind))
        exporter.shutdown()
        lines = out.read_text().strip().splitlines()
        assert len(lines) == len(EventKind)
        for line in lines:
            record = json.loads(line)
            assert "event_kind" in record
            assert "export_version" in record

    def test_null_fields_serialized_explicitly(self, tmp_path):
        out = tmp_path / "events.jsonl"
        exporter = JsonlFileExporter(out)
        exporter.export(ContextEvent(kind=EventKind.SIGNAL_MISSING_CONTEXT))
        exporter.shutdown()
        record = json.loads(out.read_text().strip())
        assert record["file"] is None
        assert record["component"] is None
        assert record["route"] is None
        assert record["detail"] is None

    def test_records_sorted_keys_for_determinism(self, tmp_path):
        out = tmp_path / "events.jsonl"
        exporter = JsonlFileExporter(out)
        exporter.export(ContextEvent(kind=EventKind.READ_USEFUL, file="a.py"))
        exporter.shutdown()
        line = out.read_text().strip()
        record = json.loads(line)
        re_encoded = json.dumps(record, sort_keys=True)
        assert line == re_encoded


# ---------------------------------------------------------------------------
# Opt-in / default behavior
# ---------------------------------------------------------------------------


class TestOptInBehavior:
    """Export is opt-in; default collector uses NoOpExporter."""

    def test_default_collector_does_not_create_files(self, tmp_path, monkeypatch):
        monkeypatch.delenv("CONTEXT_TELEMETRY_JSONL_PATH", raising=False)
        collector = ContextTelemetryCollector()
        collector.record_useful_read("test.py")
        assert len(collector.events) == 1
        assert not any(tmp_path.iterdir())

    def test_explicit_exporter_injection(self, tmp_path):
        out = tmp_path / "explicit.jsonl"
        exporter = JsonlFileExporter(out)
        collector = ContextTelemetryCollector(exporter=exporter)
        collector.record_useful_read("src/app.py")
        collector.record_denied_read(file="secret.py", detail="denied")
        exporter.shutdown()
        lines = out.read_text().strip().splitlines()
        assert len(lines) == 2

    def test_env_var_activates_file_exporter(self, tmp_path, monkeypatch):
        out = tmp_path / "env-activated.jsonl"
        monkeypatch.setenv("CONTEXT_TELEMETRY_JSONL_PATH", str(out))
        monkeypatch.setenv("CONTEXT_TELEMETRY_TRACE_ID", "trace-env")
        monkeypatch.setenv("CONTEXT_TELEMETRY_SPAN_ID", "span-env")
        collector = ContextTelemetryCollector()
        collector.record_useful_read("env.py")
        collector._exporter.shutdown()
        assert out.exists()
        record = json.loads(out.read_text().strip())
        assert record["trace_id"] == "trace-env"
        assert record["span_id"] == "span-env"

    def test_env_var_unset_uses_noop(self, monkeypatch):
        monkeypatch.delenv("CONTEXT_TELEMETRY_JSONL_PATH", raising=False)
        collector = ContextTelemetryCollector()
        assert isinstance(collector._exporter, NoOpExporter)

    def test_records_written_property(self, tmp_path):
        out = tmp_path / "count.jsonl"
        exporter = JsonlFileExporter(out)
        assert exporter.records_written == 0
        exporter.export(ContextEvent(kind=EventKind.READ_USEFUL))
        assert exporter.records_written == 1
        exporter.export(ContextEvent(kind=EventKind.QUERY_ISSUED))
        assert exporter.records_written == 2
        exporter.shutdown()


# ---------------------------------------------------------------------------
# Failure tolerance
# ---------------------------------------------------------------------------


class TestFailureTolerance:
    """Unwritable paths and I/O failures do not raise or block."""

    def test_unwritable_path_does_not_raise(self, tmp_path):
        bad_path = Path("/nonexistent-root-dir/impossible/events.jsonl")
        exporter = JsonlFileExporter(bad_path)
        exporter.export(ContextEvent(kind=EventKind.READ_USEFUL, file="x.py"))
        exporter.shutdown()
        assert exporter.records_written == 0

    def test_shutdown_on_never_opened_is_safe(self):
        exporter = JsonlFileExporter(Path("/no/such/path/events.jsonl"))
        exporter.shutdown()
        exporter.shutdown()

    def test_export_after_shutdown_is_silent(self, tmp_path):
        out = tmp_path / "events.jsonl"
        exporter = JsonlFileExporter(out)
        exporter.export(ContextEvent(kind=EventKind.READ_USEFUL))
        exporter.shutdown()
        exporter.export(ContextEvent(kind=EventKind.QUERY_ISSUED))
        lines = out.read_text().strip().splitlines()
        assert len(lines) == 1

    def test_collector_with_broken_exporter_still_records_events(self, tmp_path):
        exporter = JsonlFileExporter(Path("/no/such/path/events.jsonl"))
        collector = ContextTelemetryCollector(exporter=exporter)
        collector.record_useful_read("test.py")
        collector.record_navigation_read("nav.md")
        assert len(collector.events) == 2
        agg = collector.aggregate()
        assert agg.useful_reads == 1
        assert agg.navigation_reads == 1


# ---------------------------------------------------------------------------
# Event limit / bounding
# ---------------------------------------------------------------------------


class TestEventBounding:
    """max_events parameter bounds the number of records written."""

    def test_max_events_respected(self, tmp_path):
        out = tmp_path / "bounded.jsonl"
        exporter = JsonlFileExporter(out, max_events=3)
        for _ in range(5):
            exporter.export(ContextEvent(kind=EventKind.READ_USEFUL))
        exporter.shutdown()
        lines = out.read_text().strip().splitlines()
        assert len(lines) == 3
        assert exporter.records_written == 3

    def test_zero_max_events_writes_nothing(self, tmp_path):
        out = tmp_path / "zero.jsonl"
        exporter = JsonlFileExporter(out, max_events=0)
        exporter.export(ContextEvent(kind=EventKind.READ_USEFUL))
        exporter.shutdown()
        content = out.read_text() if out.exists() else ""
        assert content == ""


# ---------------------------------------------------------------------------
# Protocol compliance and compatibility
# ---------------------------------------------------------------------------


class TestProtocolCompliance:
    """JsonlFileExporter satisfies the ContextExporter protocol."""

    def test_satisfies_context_exporter_protocol(self, tmp_path):
        out = tmp_path / "proto.jsonl"
        exporter = JsonlFileExporter(out)
        assert isinstance(exporter, ContextExporter)
        exporter.shutdown()

    def test_existing_collector_aggregate_unaffected(self, tmp_path):
        out = tmp_path / "compat.jsonl"
        exporter = JsonlFileExporter(out)
        collector = ContextTelemetryCollector(
            component="test-comp", route="synthesis", exporter=exporter,
        )
        collector.record_useful_read("a.py")
        collector.record_useful_read("b.py")
        collector.record_navigation_read("INDEX.md")
        collector.record_query()
        collector.record_denied_read(file="secret.py", detail="denied")
        collector.record_missing_context(detail="no CRD data")
        agg = collector.aggregate()
        assert agg.useful_reads == 2
        assert agg.navigation_reads == 1
        assert agg.queries_issued == 1
        assert agg.denied_reads == 1
        assert agg.context_fetches == 4
        assert agg.missing_context_detected is True
        exporter.shutdown()
        lines = out.read_text().strip().splitlines()
        assert len(lines) == 6

    def test_context_metrics_keys_unchanged(self, tmp_path):
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
        out = tmp_path / "schema-check.jsonl"
        exporter = JsonlFileExporter(out)
        collector = ContextTelemetryCollector(exporter=exporter)
        collector.record_useful_read("x.py")
        actual_keys = set(collector.context_metrics().keys())
        assert actual_keys == expected_keys
        exporter.shutdown()

    def test_serialize_compatibility_with_file_exporter(self, tmp_path):
        out = tmp_path / "serialize.jsonl"
        exporter = JsonlFileExporter(out, trace_id="t1", span_id="s1")
        collector = ContextTelemetryCollector(
            component="comp", route="partial", exporter=exporter,
        )
        collector.record_useful_read("main.py")
        collector.record_denied_query(detail="not allowed")
        serialized = json.loads(collector.serialize())
        assert serialized["contract_version"] == CONTRACT_VERSION
        assert serialized["component"] == "comp"
        assert serialized["route"] == "partial"
        assert len(serialized["events"]) == 2
        exporter.shutdown()


# ---------------------------------------------------------------------------
# Subdirectory creation
# ---------------------------------------------------------------------------


class TestSubdirectoryCreation:
    """Exporter creates parent directories when they don't exist."""

    def test_creates_nested_directories(self, tmp_path):
        out = tmp_path / "deep" / "nested" / "dir" / "events.jsonl"
        exporter = JsonlFileExporter(out)
        exporter.export(ContextEvent(kind=EventKind.READ_USEFUL, file="x.py"))
        exporter.shutdown()
        assert out.exists()
        lines = out.read_text().strip().splitlines()
        assert len(lines) == 1
