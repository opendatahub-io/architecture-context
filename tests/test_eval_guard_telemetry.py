"""Tests for context telemetry integration in the evaluation guard.

Validates that _EvalGuard records context_metrics deterministically for
baseline, index-md, arch-query, and combined condition paths. Checks
denied operations, navigation reads, query events, and OTel no-op
behavior without launching agents or running evaluations.
"""

from __future__ import annotations

import importlib.util
import json
import sys
from pathlib import Path

import pytest

PROJECT_ROOT = Path(__file__).resolve().parent.parent
RUNNER_PATH = PROJECT_ROOT / "benchmark" / "consumer-v1" / "run_evaluation.py"

_spec = importlib.util.spec_from_file_location("run_evaluation", RUNNER_PATH)
_mod = importlib.util.module_from_spec(_spec)
sys.path.insert(0, str(PROJECT_ROOT))
_spec.loader.exec_module(_mod)

_EvalGuard = _mod._EvalGuard

from lib.context_telemetry import (  # noqa: E402
    CONTRACT_VERSION,
    EventKind,
    InMemoryExporter,
)

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------


def _make_guard(
    tmp_path: Path,
    *,
    query_enabled: bool = False,
    index_path: Path | None = None,
    context_exporter=None,
) -> _EvalGuard:
    tree = tmp_path / "arch-tree"
    tree.mkdir(exist_ok=True)
    return _EvalGuard(
        tree,
        query_enabled=query_enabled,
        index_path=index_path,
        context_exporter=context_exporter,
    )


async def _call(guard: _EvalGuard, tool_name: str, tool_input: dict):
    return await guard.pre_tool_use(
        {"tool_name": tool_name, "tool_input": tool_input},
        "test-id",
        None,
    )


# ---------------------------------------------------------------------------
# Baseline condition: context_metrics in telemetry
# ---------------------------------------------------------------------------


class TestBaselineContextMetrics:
    """Baseline guard produces deterministic context_metrics."""

    @pytest.mark.asyncio
    async def test_telemetry_includes_context_metrics(self, tmp_path):
        guard = _make_guard(tmp_path)
        tree = guard.tree
        f = tree / "doc.md"
        f.write_text("content")
        await _call(guard, "Read", {"file_path": str(f)})
        telem = guard.telemetry()
        assert "context_metrics" in telem

    @pytest.mark.asyncio
    async def test_useful_read_counted(self, tmp_path):
        guard = _make_guard(tmp_path)
        tree = guard.tree
        f = tree / "component.md"
        f.write_text("content")
        await _call(guard, "Read", {"file_path": str(f)})
        metrics = guard.telemetry()["context_metrics"]
        assert metrics["useful_reads"] == 1
        assert metrics["navigation_reads"] == 0
        assert metrics["context_fetches"] == 1

    @pytest.mark.asyncio
    async def test_search_counted_as_navigation(self, tmp_path):
        guard = _make_guard(tmp_path)
        await _call(guard, "Glob", {"path": str(guard.tree)})
        await _call(guard, "Grep", {"path": str(guard.tree)})
        metrics = guard.telemetry()["context_metrics"]
        assert metrics["navigation_reads"] == 2
        assert metrics["useful_reads"] == 0

    @pytest.mark.asyncio
    async def test_denied_tool_recorded(self, tmp_path):
        guard = _make_guard(tmp_path)
        await _call(guard, "Write", {"path": "/tmp/x"})
        agg = guard.ctx_telemetry.aggregate()
        assert agg.denied_reads == 1

    @pytest.mark.asyncio
    async def test_out_of_tree_read_denied(self, tmp_path):
        guard = _make_guard(tmp_path)
        await _call(guard, "Read", {"file_path": "/etc/passwd"})
        agg = guard.ctx_telemetry.aggregate()
        assert agg.denied_reads == 1
        assert agg.useful_reads == 0

    @pytest.mark.asyncio
    async def test_empty_guard_context_metrics_keys(self, tmp_path):
        guard = _make_guard(tmp_path)
        metrics = guard.telemetry()["context_metrics"]
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
        assert set(metrics.keys()) == expected_keys

    @pytest.mark.asyncio
    async def test_baseline_route_set(self, tmp_path):
        guard = _make_guard(tmp_path)
        assert guard.ctx_telemetry._route == "baseline"

    @pytest.mark.asyncio
    async def test_signals_remain_none_when_not_emitted(self, tmp_path):
        guard = _make_guard(tmp_path)
        f = guard.tree / "doc.md"
        f.write_text("data")
        await _call(guard, "Read", {"file_path": str(f)})
        metrics = guard.telemetry()["context_metrics"]
        assert metrics["missing_context_detected"] is None
        assert metrics["stale_context_detected"] is None
        assert metrics["unsupported_inference_detected"] is None


# ---------------------------------------------------------------------------
# Index condition: INDEX.md reads classified as navigation
# ---------------------------------------------------------------------------


class TestIndexContextMetrics:
    """Index guard classifies INDEX.md reads as navigation."""

    @pytest.mark.asyncio
    async def test_index_read_is_navigation(self, tmp_path):
        tree = tmp_path / "arch-tree"
        tree.mkdir()
        index = tmp_path / "INDEX.md"
        index.write_text("# Index\n")
        guard = _EvalGuard(tree, index_path=index)
        await _call(guard, "Read", {"file_path": str(index)})
        metrics = guard.telemetry()["context_metrics"]
        assert metrics["navigation_reads"] == 1
        assert metrics["useful_reads"] == 0
        assert metrics["context_fetches"] == 1

    @pytest.mark.asyncio
    async def test_non_index_read_is_useful(self, tmp_path):
        tree = tmp_path / "arch-tree"
        tree.mkdir()
        index = tmp_path / "INDEX.md"
        index.write_text("# Index\n")
        doc = tree / "component.md"
        doc.write_text("info")
        guard = _EvalGuard(tree, index_path=index)
        await _call(guard, "Read", {"file_path": str(doc)})
        metrics = guard.telemetry()["context_metrics"]
        assert metrics["useful_reads"] == 1
        assert metrics["navigation_reads"] == 0

    @pytest.mark.asyncio
    async def test_index_route_set(self, tmp_path):
        tree = tmp_path / "arch-tree"
        tree.mkdir()
        index = tmp_path / "INDEX.md"
        index.write_text("# Index\n")
        guard = _EvalGuard(tree, index_path=index)
        assert guard.ctx_telemetry._route == "index"

    @pytest.mark.asyncio
    async def test_mixed_index_and_doc_reads(self, tmp_path):
        tree = tmp_path / "arch-tree"
        tree.mkdir()
        index = tmp_path / "INDEX.md"
        index.write_text("# Index\n")
        doc = tree / "platform.md"
        doc.write_text("platform data")
        guard = _EvalGuard(tree, index_path=index)
        await _call(guard, "Read", {"file_path": str(index)})
        await _call(guard, "Read", {"file_path": str(doc)})
        await _call(guard, "Glob", {"path": str(tree)})
        metrics = guard.telemetry()["context_metrics"]
        assert metrics["useful_reads"] == 1
        assert metrics["navigation_reads"] == 2
        assert metrics["context_fetches"] == 3


# ---------------------------------------------------------------------------
# Query condition: query events recorded
# ---------------------------------------------------------------------------


class TestQueryContextMetrics:
    """Query-enabled guard records query.issued and query.denied events."""

    @pytest.mark.asyncio
    async def test_allowed_query_recorded(self, tmp_path):
        guard = _make_guard(tmp_path, query_enabled=True)
        tree_str = str(guard.tree)
        cmd = f"arch-query query crds --component foo --base-dir {tree_str} -o json"
        await _call(guard, "Bash", {"command": cmd})
        metrics = guard.telemetry()["context_metrics"]
        assert metrics["queries_issued"] == 1
        assert metrics["context_fetches"] == 1

    @pytest.mark.asyncio
    async def test_denied_query_recorded(self, tmp_path):
        guard = _make_guard(tmp_path, query_enabled=True)
        await _call(guard, "Bash", {"command": "ls -la"})
        agg = guard.ctx_telemetry.aggregate()
        assert agg.denied_queries == 1
        assert agg.queries_issued == 0

    @pytest.mark.asyncio
    async def test_base_dir_escape_recorded_as_denied_query(self, tmp_path):
        guard = _make_guard(tmp_path, query_enabled=True)
        await _call(guard, "Bash", {
            "command": "arch-query query crds --base-dir /tmp -o json"
        })
        agg = guard.ctx_telemetry.aggregate()
        assert agg.denied_queries == 1

    @pytest.mark.asyncio
    async def test_query_route_set(self, tmp_path):
        guard = _make_guard(tmp_path, query_enabled=True)
        assert guard.ctx_telemetry._route == "query"

    @pytest.mark.asyncio
    async def test_mixed_query_and_read_context_fetches(self, tmp_path):
        guard = _make_guard(tmp_path, query_enabled=True)
        tree = guard.tree
        doc = tree / "data.md"
        doc.write_text("data")
        tree_str = str(tree)
        await _call(guard, "Read", {"file_path": str(doc)})
        cmd = f"arch-query query crds --component x --base-dir {tree_str} -o json"
        await _call(guard, "Bash", {"command": cmd})
        metrics = guard.telemetry()["context_metrics"]
        assert metrics["useful_reads"] == 1
        assert metrics["queries_issued"] == 1
        assert metrics["context_fetches"] == 2

    @pytest.mark.asyncio
    async def test_queries_issued_zero_without_query_enabled(self, tmp_path):
        guard = _make_guard(tmp_path, query_enabled=False)
        metrics = guard.telemetry()["context_metrics"]
        assert metrics["queries_issued"] == 0


# ---------------------------------------------------------------------------
# Combined condition
# ---------------------------------------------------------------------------


class TestCombinedContextMetrics:
    """Combined guard (query + index) records all event types."""

    @pytest.mark.asyncio
    async def test_combined_route_set(self, tmp_path):
        tree = tmp_path / "arch-tree"
        tree.mkdir()
        index = tmp_path / "INDEX.md"
        index.write_text("# Index\n")
        guard = _EvalGuard(
            tree, query_enabled=True, index_path=index,
        )
        assert guard.ctx_telemetry._route == "combined"

    @pytest.mark.asyncio
    async def test_combined_all_event_types(self, tmp_path):
        tree = tmp_path / "arch-tree"
        tree.mkdir()
        index = tmp_path / "INDEX.md"
        index.write_text("# Index\n")
        doc = tree / "comp.md"
        doc.write_text("component data")
        guard = _EvalGuard(
            tree, query_enabled=True, index_path=index,
        )
        tree_str = str(tree)
        await _call(guard, "Read", {"file_path": str(doc)})
        await _call(guard, "Read", {"file_path": str(index)})
        await _call(guard, "Glob", {"path": str(tree)})
        cmd = f"arch-query query crds --component x --base-dir {tree_str} -o json"
        await _call(guard, "Bash", {"command": cmd})
        await _call(guard, "Bash", {"command": "ls"})
        await _call(guard, "Write", {"path": "/tmp/x"})
        metrics = guard.telemetry()["context_metrics"]
        assert metrics["useful_reads"] == 1
        assert metrics["navigation_reads"] == 2
        assert metrics["queries_issued"] == 1
        assert metrics["context_fetches"] == 4


# ---------------------------------------------------------------------------
# Exporter integration
# ---------------------------------------------------------------------------


class TestExporterIntegration:
    """InMemoryExporter receives events from the eval guard."""

    @pytest.mark.asyncio
    async def test_exporter_receives_events(self, tmp_path):
        exporter = InMemoryExporter()
        guard = _make_guard(tmp_path, context_exporter=exporter)
        tree = guard.tree
        doc = tree / "doc.md"
        doc.write_text("content")
        await _call(guard, "Read", {"file_path": str(doc)})
        await _call(guard, "Write", {"path": "/tmp/x"})
        assert len(exporter.exported) == 2
        assert exporter.exported[0].kind == EventKind.READ_USEFUL
        assert exporter.exported[1].kind == EventKind.READ_DENIED

    @pytest.mark.asyncio
    async def test_exporter_receives_query_events(self, tmp_path):
        exporter = InMemoryExporter()
        guard = _make_guard(
            tmp_path, query_enabled=True, context_exporter=exporter,
        )
        tree_str = str(guard.tree)
        cmd = f"arch-query query crds --component x --base-dir {tree_str} -o json"
        await _call(guard, "Bash", {"command": cmd})
        await _call(guard, "Bash", {"command": "ls"})
        assert len(exporter.exported) == 2
        assert exporter.exported[0].kind == EventKind.QUERY_ISSUED
        assert exporter.exported[1].kind == EventKind.QUERY_DENIED

    @pytest.mark.asyncio
    async def test_no_op_exporter_default(self, tmp_path):
        guard = _make_guard(tmp_path)
        doc = guard.tree / "doc.md"
        doc.write_text("ok")
        await _call(guard, "Read", {"file_path": str(doc)})
        assert len(guard.ctx_telemetry.events) == 1


# ---------------------------------------------------------------------------
# Deterministic serialization and provenance
# ---------------------------------------------------------------------------


class TestSerializationAndProvenance:
    """context_provenance produces deterministic, schema-compatible output."""

    @pytest.mark.asyncio
    async def test_context_provenance_includes_version(self, tmp_path):
        guard = _make_guard(tmp_path)
        prov = guard.context_provenance()
        assert prov["context_telemetry_version"] == CONTRACT_VERSION

    @pytest.mark.asyncio
    async def test_context_provenance_events_serializable(self, tmp_path):
        guard = _make_guard(tmp_path)
        doc = guard.tree / "doc.md"
        doc.write_text("ok")
        await _call(guard, "Read", {"file_path": str(doc)})
        prov = guard.context_provenance()
        events_data = prov["context_events"]
        assert events_data["contract_version"] == CONTRACT_VERSION
        assert len(events_data["events"]) == 1
        assert events_data["events"][0]["kind"] == "read.useful"

    @pytest.mark.asyncio
    async def test_serialization_is_deterministic(self, tmp_path):
        guards = []
        for _ in range(2):
            guard = _make_guard(tmp_path)
            doc = guard.tree / "doc.md"
            doc.write_text("ok")
            await _call(guard, "Read", {"file_path": str(doc)})
            guards.append(guard)
        s1 = guards[0].ctx_telemetry.serialize()
        s2 = guards[1].ctx_telemetry.serialize()
        assert s1 == s2

    @pytest.mark.asyncio
    async def test_context_metrics_round_trips(self, tmp_path):
        guard = _make_guard(tmp_path)
        doc = guard.tree / "doc.md"
        doc.write_text("ok")
        await _call(guard, "Read", {"file_path": str(doc)})
        raw = guard.ctx_telemetry.serialize()
        parsed = json.loads(raw)
        re_encoded = json.dumps(parsed, sort_keys=True)
        assert raw == re_encoded


# ---------------------------------------------------------------------------
# Backward compatibility: existing telemetry shape preserved
# ---------------------------------------------------------------------------


class TestBackwardCompatibility:
    """Existing telemetry shape is preserved with context_metrics added."""

    @pytest.mark.asyncio
    async def test_telemetry_still_has_tool_calls(self, tmp_path):
        guard = _make_guard(tmp_path)
        telem = guard.telemetry()
        assert "tool_calls" in telem
        assert "denied_tool_calls" in telem
        assert "files_read" in telem
        assert "file_count" in telem

    @pytest.mark.asyncio
    async def test_query_telemetry_preserved(self, tmp_path):
        guard = _make_guard(tmp_path, query_enabled=True)
        tree_str = str(guard.tree)
        cmd = f"arch-query query crds --component x --base-dir {tree_str} -o json"
        await _call(guard, "Bash", {"command": cmd})
        telem = guard.telemetry()
        assert "query_calls" in telem
        assert "query_allowed_count" in telem
        assert telem["query_allowed_count"] == 1

    @pytest.mark.asyncio
    async def test_index_path_in_telemetry_preserved(self, tmp_path):
        tree = tmp_path / "arch-tree"
        tree.mkdir()
        index = tmp_path / "INDEX.md"
        index.write_text("# Index\n")
        guard = _EvalGuard(tree, index_path=index)
        telem = guard.telemetry()
        assert "index_artifact_path" in telem

    @pytest.mark.asyncio
    async def test_no_query_telemetry_without_query_enabled(self, tmp_path):
        guard = _make_guard(tmp_path, query_enabled=False)
        telem = guard.telemetry()
        assert "query_calls" not in telem
        assert "context_metrics" in telem


# ---------------------------------------------------------------------------
# Search denial tracking
# ---------------------------------------------------------------------------


class TestSearchDenialTracking:
    """Denied search operations are recorded in context telemetry."""

    @pytest.mark.asyncio
    async def test_out_of_tree_search_denied_and_recorded(self, tmp_path):
        guard = _make_guard(tmp_path)
        await _call(guard, "Glob", {"path": "/etc"})
        agg = guard.ctx_telemetry.aggregate()
        assert agg.denied_reads >= 1

    @pytest.mark.asyncio
    async def test_missing_read_path_denied(self, tmp_path):
        guard = _make_guard(tmp_path)
        await _call(guard, "Read", {})
        agg = guard.ctx_telemetry.aggregate()
        assert agg.denied_reads == 1


# ---------------------------------------------------------------------------
# End-to-end: context_provenance attached to per-tree results after activity
# ---------------------------------------------------------------------------


class TestContextProvenanceInResults:
    """context_provenance is present in per-tree results after guard activity."""

    @pytest.mark.asyncio
    async def test_baseline_result_has_context_provenance(self, tmp_path):
        guard = _make_guard(tmp_path)
        doc = guard.tree / "doc.md"
        doc.write_text("content")
        await _call(guard, "Read", {"file_path": str(doc)})
        prov = guard.context_provenance()
        assert "context_telemetry_version" in prov
        assert prov["context_telemetry_version"] == CONTRACT_VERSION
        assert "context_events" in prov
        events = prov["context_events"]
        assert events["contract_version"] == CONTRACT_VERSION
        assert len(events["events"]) == 1
        assert events["events"][0]["kind"] == "read.useful"
        assert events["route"] == "baseline"

    @pytest.mark.asyncio
    async def test_index_result_has_context_provenance(self, tmp_path):
        tree = tmp_path / "arch-tree"
        tree.mkdir()
        index = tmp_path / "INDEX.md"
        index.write_text("# Index\n")
        doc = tree / "comp.md"
        doc.write_text("data")
        guard = _EvalGuard(tree, index_path=index)
        await _call(guard, "Read", {"file_path": str(index)})
        await _call(guard, "Read", {"file_path": str(doc)})
        prov = guard.context_provenance()
        events = prov["context_events"]
        assert events["route"] == "index"
        assert len(events["events"]) == 2
        kinds = [e["kind"] for e in events["events"]]
        assert kinds == ["read.navigation", "read.useful"]

    @pytest.mark.asyncio
    async def test_query_result_has_context_provenance(self, tmp_path):
        guard = _make_guard(tmp_path, query_enabled=True)
        tree_str = str(guard.tree)
        cmd = f"arch-query query crds --component x --base-dir {tree_str} -o json"
        await _call(guard, "Bash", {"command": cmd})
        prov = guard.context_provenance()
        events = prov["context_events"]
        assert events["route"] == "query"
        assert len(events["events"]) == 1
        assert events["events"][0]["kind"] == "query.issued"

    @pytest.mark.asyncio
    async def test_combined_result_has_context_provenance(self, tmp_path):
        tree = tmp_path / "arch-tree"
        tree.mkdir()
        index = tmp_path / "INDEX.md"
        index.write_text("# Index\n")
        doc = tree / "comp.md"
        doc.write_text("data")
        guard = _EvalGuard(tree, query_enabled=True, index_path=index)
        await _call(guard, "Read", {"file_path": str(doc)})
        await _call(guard, "Read", {"file_path": str(index)})
        tree_str = str(tree)
        cmd = f"arch-query query crds --component x --base-dir {tree_str} -o json"
        await _call(guard, "Bash", {"command": cmd})
        prov = guard.context_provenance()
        events = prov["context_events"]
        assert events["route"] == "combined"
        assert len(events["events"]) == 3
        kinds = [e["kind"] for e in events["events"]]
        assert "read.useful" in kinds
        assert "read.navigation" in kinds
        assert "query.issued" in kinds

    @pytest.mark.asyncio
    async def test_denied_activity_in_context_provenance(self, tmp_path):
        guard = _make_guard(tmp_path)
        await _call(guard, "Write", {"path": "/tmp/x"})
        await _call(guard, "Read", {"file_path": "/etc/passwd"})
        prov = guard.context_provenance()
        events = prov["context_events"]
        assert len(events["events"]) == 2
        kinds = [e["kind"] for e in events["events"]]
        assert all(k == "read.denied" for k in kinds)

    @pytest.mark.asyncio
    async def test_context_provenance_metrics_match_telemetry(self, tmp_path):
        guard = _make_guard(tmp_path)
        doc = guard.tree / "doc.md"
        doc.write_text("content")
        await _call(guard, "Read", {"file_path": str(doc)})
        await _call(guard, "Glob", {"path": str(guard.tree)})
        prov = guard.context_provenance()
        telem_metrics = guard.telemetry()["context_metrics"]
        prov_metrics = prov["context_events"]["context_metrics"]
        assert telem_metrics["useful_reads"] == prov_metrics["useful_reads"]
        assert telem_metrics["navigation_reads"] == prov_metrics["navigation_reads"]
        assert telem_metrics["context_fetches"] == prov_metrics["context_fetches"]

    @pytest.mark.asyncio
    async def test_empty_guard_has_context_provenance(self, tmp_path):
        guard = _make_guard(tmp_path)
        prov = guard.context_provenance()
        assert prov["context_telemetry_version"] == CONTRACT_VERSION
        assert prov["context_events"]["events"] == []
