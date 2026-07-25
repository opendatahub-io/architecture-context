"""Focused offline tests for the MLflow tracking adapter.

Covers dry-run, required metadata validation, result-to-metric mapping,
artifact references, and unavailable/error paths — all without network
access or external MLflow state.
"""

from __future__ import annotations

import json
import socket
import sys
from http.server import BaseHTTPRequestHandler, HTTPServer
from pathlib import Path
from threading import Thread
from unittest.mock import patch

import pytest

PROJECT_ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(PROJECT_ROOT))

from lib.mlflow_tracking import (  # noqa: E402
    MLflowRESTClient,
    REQUIRED_RESULT_FIELDS,
    TRACKING_CONTRACT_VERSION,
    TrackingConfig,
    TrackingResult,
    _build_artifact_refs,
    _build_metrics,
    _build_tags,
    _validate_required_fields,
    preflight,
    track_result,
)


def _minimal_result(**overrides) -> dict:
    """Build a minimal valid result record for tracking tests."""
    base = {
        "schema_version": "1.0.0",
        "experiment_id": "analyzer-assisted-retrieval-v1",
        "condition_id": "baseline",
        "question_id": "INV-001",
        "question_category": "inventory",
        "question_difficulty": "direct-lookup",
        "question_scope": "rhoai",
        "model": "claude-opus-4-6",
        "runner_version": "1.0.0",
        "timestamp": "2026-07-25T12:00:00Z",
        "seed": 42,
        "provenance": {
            "architecture_context_sha": "abc123def456",
            "corpus_version": "1.0.0",
            "experiment_manifest_version": "1.3.0",
        },
        "response": {
            "success": True,
            "text": "The component uses...",
        },
        "telemetry": {
            "duration_seconds": 12.5,
            "input_tokens": 5000,
            "output_tokens": 200,
            "total_cost_usd": 0.05,
            "num_turns": 3,
            "tool_calls": {"Read": 4, "Grep": 2},
            "files_read": ["comp-a/GENERATED_ARCHITECTURE.md"],
        },
        "context_metrics": {
            "context_fetches": 6,
            "useful_reads": 4,
            "navigation_reads": 2,
            "queries_issued": 0,
        },
        "failure_classifications": [],
    }
    base.update(overrides)
    return base


class TestDryRunMode:
    """Dry-run mode must report what would be logged without network access."""

    def test_dry_run_returns_success(self):
        config = TrackingConfig(dry_run=True)
        result = track_result(_minimal_result(), config)
        assert result.success is True
        assert result.dry_run is True

    def test_dry_run_includes_tags(self):
        config = TrackingConfig(dry_run=True)
        result = track_result(_minimal_result(), config)
        assert "condition_id" in result.tags_logged
        assert result.tags_logged["condition_id"] == "baseline"
        assert "experiment_id" in result.tags_logged

    def test_dry_run_includes_metrics(self):
        config = TrackingConfig(dry_run=True)
        result = track_result(_minimal_result(), config)
        assert "telemetry.duration_seconds" in result.metrics_logged
        assert result.metrics_logged["telemetry.duration_seconds"] == 12.5

    def test_dry_run_includes_artifact_refs(self):
        config = TrackingConfig(dry_run=True)
        result = track_result(_minimal_result(), config)
        assert any("architecture-context:" in r for r in result.artifacts_referenced)

    def test_dry_run_no_run_id(self):
        config = TrackingConfig(dry_run=True)
        result = track_result(_minimal_result(), config)
        assert result.run_id is None

    def test_dry_run_no_tracking_uri_still_succeeds(self):
        config = TrackingConfig(tracking_uri=None, dry_run=True)
        result = track_result(_minimal_result(), config)
        assert result.success is True
        assert result.dry_run is True


class TestPreflightCheck:
    """Preflight must report configuration status without creating state."""

    def test_preflight_missing_uri(self):
        config = TrackingConfig(tracking_uri=None)
        result = preflight(config)
        assert result.configured is False
        assert result.reachable is False
        assert result.ok is False
        assert any("MLFLOW_TRACKING_URI" in e for e in result.errors)

    def test_preflight_reports_experiment_name(self):
        config = TrackingConfig(tracking_uri=None)
        result = preflight(config)
        assert result.experiment_name == "analyzer-assisted-retrieval-v1"

    def test_preflight_reports_required_fields(self):
        config = TrackingConfig(tracking_uri=None)
        result = preflight(config)
        assert result.required_fields == REQUIRED_RESULT_FIELDS

    def test_preflight_dry_run_skips_connectivity(self):
        config = TrackingConfig(
            tracking_uri="http://nonexistent:5000",
            dry_run=True,
        )
        result = preflight(config)
        assert result.configured is True
        assert result.reachable is False
        assert any("dry-run" in e for e in result.errors)

    def test_preflight_unreachable_server(self):
        config = TrackingConfig(
            tracking_uri="http://127.0.0.1:19999",
            dry_run=False,
        )
        result = preflight(config)
        assert result.configured is True
        assert result.reachable is False
        assert result.ok is False
        assert any("not reachable" in e for e in result.errors)

    def test_preflight_to_dict(self):
        config = TrackingConfig(tracking_uri=None)
        result = preflight(config)
        d = result.to_dict()
        assert isinstance(d, dict)
        assert "configured" in d
        assert "errors" in d

    def test_preflight_from_env_no_env(self):
        with patch.dict("os.environ", {}, clear=True):
            config = TrackingConfig.from_env()
            assert config.tracking_uri is None
            assert config.experiment_name == "analyzer-assisted-retrieval-v1"

    def test_preflight_from_env_with_uri(self):
        env = {"MLFLOW_TRACKING_URI": "http://mlflow:5000"}
        with patch.dict("os.environ", env, clear=True):
            config = TrackingConfig.from_env()
            assert config.tracking_uri == "http://mlflow:5000"


class TestRequiredMetadata:
    """Required fields must be validated before tracking."""

    def test_missing_experiment_id(self):
        result = _minimal_result()
        del result["experiment_id"]
        errors = _validate_required_fields(result)
        assert any("experiment_id" in e for e in errors)

    def test_missing_condition_id(self):
        result = _minimal_result()
        del result["condition_id"]
        errors = _validate_required_fields(result)
        assert any("condition_id" in e for e in errors)

    def test_missing_provenance(self):
        result = _minimal_result()
        del result["provenance"]
        errors = _validate_required_fields(result)
        assert any("provenance" in e for e in errors)

    def test_empty_architecture_sha(self):
        result = _minimal_result()
        result["provenance"]["architecture_context_sha"] = ""
        errors = _validate_required_fields(result)
        assert any("architecture_context_sha" in e for e in errors)

    def test_null_model(self):
        result = _minimal_result()
        result["model"] = None
        errors = _validate_required_fields(result)
        assert any("model" in e for e in errors)

    def test_empty_string_timestamp(self):
        result = _minimal_result()
        result["timestamp"] = "   "
        errors = _validate_required_fields(result)
        assert any("timestamp" in e for e in errors)

    def test_all_required_present(self):
        result = _minimal_result()
        errors = _validate_required_fields(result)
        assert errors == []

    def test_tracking_rejects_invalid_result(self):
        result = _minimal_result()
        del result["experiment_id"]
        config = TrackingConfig(dry_run=True)
        tracking_result = track_result(result, config)
        assert tracking_result.success is False
        assert "validation failed" in tracking_result.error


class TestResultToMetricMapping:
    """Result fields must be correctly mapped to MLflow metrics."""

    def test_telemetry_metrics(self):
        result = _minimal_result()
        metrics = _build_metrics(result)
        assert metrics["telemetry.duration_seconds"] == 12.5
        assert metrics["telemetry.input_tokens"] == 5000.0
        assert metrics["telemetry.output_tokens"] == 200.0
        assert metrics["telemetry.total_cost_usd"] == 0.05
        assert metrics["telemetry.num_turns"] == 3.0

    def test_tool_call_metrics(self):
        result = _minimal_result()
        metrics = _build_metrics(result)
        assert metrics["telemetry.tool_calls.Read"] == 4.0
        assert metrics["telemetry.tool_calls.Grep"] == 2.0

    def test_context_metrics(self):
        result = _minimal_result()
        metrics = _build_metrics(result)
        assert metrics["context_metrics.context_fetches"] == 6.0
        assert metrics["context_metrics.useful_reads"] == 4.0
        assert metrics["context_metrics.navigation_reads"] == 2.0
        assert metrics["context_metrics.queries_issued"] == 0.0

    def test_response_success_metric(self):
        result = _minimal_result()
        metrics = _build_metrics(result)
        assert metrics["response.success"] == 1.0

    def test_response_failure_metric(self):
        result = _minimal_result()
        result["response"]["success"] = False
        metrics = _build_metrics(result)
        assert metrics["response.success"] == 0.0

    def test_null_telemetry_values_skipped(self):
        result = _minimal_result()
        result["telemetry"]["duration_seconds"] = None
        result["telemetry"]["input_tokens"] = None
        metrics = _build_metrics(result)
        assert "telemetry.duration_seconds" not in metrics
        assert "telemetry.input_tokens" not in metrics

    def test_empty_telemetry(self):
        result = _minimal_result()
        result["telemetry"] = {}
        metrics = _build_metrics(result)
        assert "telemetry.duration_seconds" not in metrics

    def test_missing_telemetry(self):
        result = _minimal_result()
        del result["telemetry"]
        metrics = _build_metrics(result)
        assert "telemetry.duration_seconds" not in metrics


class TestTagMapping:
    """Result fields must be correctly mapped to MLflow tags."""

    def test_core_identity_tags(self):
        result = _minimal_result()
        tags = _build_tags(result)
        assert tags["experiment_id"] == "analyzer-assisted-retrieval-v1"
        assert tags["condition_id"] == "baseline"
        assert tags["question_id"] == "INV-001"
        assert tags["model"] == "claude-opus-4-6"

    def test_provenance_tags(self):
        result = _minimal_result()
        tags = _build_tags(result)
        assert tags["provenance.architecture_context_sha"] == "abc123def456"
        assert tags["provenance.corpus_version"] == "1.0.0"
        assert tags["provenance.experiment_manifest_version"] == "1.3.0"

    def test_optional_provenance_tags(self):
        result = _minimal_result()
        result["provenance"]["index_generation_sha"] = "idx789"
        result["provenance"]["query_binary_version"] = "v0.5.0"
        tags = _build_tags(result)
        assert tags["provenance.index_generation_sha"] == "idx789"
        assert tags["provenance.query_binary_version"] == "v0.5.0"

    def test_failure_classification_tags(self):
        result = _minimal_result(
            failure_classifications=["stale-context", "retrieval-failure"],
        )
        tags = _build_tags(result)
        assert tags["failure_classifications"] == "stale-context,retrieval-failure"

    def test_no_failure_classifications_tag(self):
        result = _minimal_result(failure_classifications=[])
        tags = _build_tags(result)
        assert "failure_classifications" not in tags

    def test_contract_version_tag(self):
        result = _minimal_result()
        tags = _build_tags(result)
        assert tags["tracking_contract_version"] == TRACKING_CONTRACT_VERSION

    def test_condition_available_tag(self):
        result = _minimal_result(condition_available=False)
        tags = _build_tags(result)
        assert tags["condition_available"] == "false"

    def test_question_metadata_tags(self):
        result = _minimal_result()
        tags = _build_tags(result)
        assert tags["question_category"] == "inventory"
        assert tags["question_difficulty"] == "direct-lookup"
        assert tags["question_scope"] == "rhoai"


class TestArtifactReferences:
    """Artifact references must be extracted from provenance."""

    def test_architecture_context_ref(self):
        result = _minimal_result()
        refs = _build_artifact_refs(result)
        assert "architecture-context:abc123def456" in refs

    def test_index_generation_ref(self):
        result = _minimal_result()
        result["provenance"]["index_generation_sha"] = "idx789"
        refs = _build_artifact_refs(result)
        assert "index-generation:idx789" in refs

    def test_query_binary_ref(self):
        result = _minimal_result()
        result["provenance"]["query_binary_version"] = "v0.5.0"
        refs = _build_artifact_refs(result)
        assert "query-binary:v0.5.0" in refs

    def test_source_citation_refs(self):
        result = _minimal_result()
        result["response"]["source_citations"] = [
            {"file": "comp-a/GENERATED_ARCHITECTURE.md", "line": 42},
        ]
        refs = _build_artifact_refs(result)
        assert "source-citation:comp-a/GENERATED_ARCHITECTURE.md" in refs

    def test_no_provenance(self):
        result = _minimal_result()
        result["provenance"] = {}
        refs = _build_artifact_refs(result)
        assert not any(r.startswith("architecture-context:") for r in refs)

    def test_artifact_refs_in_dry_run_tags(self):
        config = TrackingConfig(dry_run=True)
        result = _minimal_result()
        result["provenance"]["index_generation_sha"] = "idx789"
        tracking = track_result(result, config)
        assert any(
            k.startswith("artifact_ref.") for k in tracking.tags_logged
        )


class TestUnavailableAndErrorPaths:
    """Missing URI, unreachable servers, and invalid data must fail explicitly."""

    def test_no_uri_not_dry_run(self):
        config = TrackingConfig(tracking_uri=None, dry_run=False)
        result = track_result(_minimal_result(), config)
        assert result.success is False
        assert "MLFLOW_TRACKING_URI" in result.error

    def test_unreachable_server_not_dry_run(self):
        config = TrackingConfig(
            tracking_uri="http://127.0.0.1:19999",
            dry_run=False,
        )
        result = track_result(_minimal_result(), config)
        assert result.success is False
        assert result.error is not None

    def test_tracking_result_to_dict(self):
        result = TrackingResult(success=False, error="test error")
        d = result.to_dict()
        assert isinstance(d, dict)
        assert d["success"] is False
        assert d["error"] == "test error"

    def test_missing_all_required_fields(self):
        config = TrackingConfig(dry_run=True)
        result = track_result({}, config)
        assert result.success is False
        assert "validation failed" in result.error

    def test_null_provenance_sha(self):
        result = _minimal_result()
        result["provenance"]["architecture_context_sha"] = None
        config = TrackingConfig(dry_run=True)
        tracking = track_result(result, config)
        assert tracking.success is False
        assert "architecture_context_sha" in tracking.error

    def test_socket_timeout_returns_tracking_error(self):
        """OSError (timeout/socket) during tracking produces explicit error."""
        config = TrackingConfig(
            tracking_uri="http://127.0.0.1:1", dry_run=False,
        )
        with patch(
            "lib.mlflow_tracking.urllib.request.urlopen",
            side_effect=socket.timeout("timed out"),
        ):
            result = track_result(_minimal_result(), config)
        assert result.success is False
        assert result.error is not None
        assert "timed out" in result.error

    def test_connection_refused_returns_tracking_error(self):
        """ConnectionRefusedError during tracking produces explicit error."""
        config = TrackingConfig(
            tracking_uri="http://127.0.0.1:1", dry_run=False,
        )
        with patch(
            "lib.mlflow_tracking.urllib.request.urlopen",
            side_effect=ConnectionRefusedError("Connection refused"),
        ):
            result = track_result(_minimal_result(), config)
        assert result.success is False
        assert result.error is not None
        assert "Connection refused" in result.error


class TestMockMLflowServer:
    """Test with a minimal mock HTTP server to verify REST call structure."""

    @pytest.fixture()
    def mock_server(self):
        calls = []

        class Handler(BaseHTTPRequestHandler):
            def do_GET(self):
                calls.append(("GET", self.path, None))
                self.send_response(200)
                self.send_header("Content-Type", "application/json")
                self.end_headers()
                self.wfile.write(json.dumps({"experiments": []}).encode())

            def do_POST(self):
                length = int(self.headers.get("Content-Length", 0))
                body = json.loads(self.rfile.read(length)) if length else {}
                calls.append(("POST", self.path, body))

                if "experiments/search" in self.path:
                    resp = {"experiments": []}
                elif "experiments/create" in self.path:
                    resp = {"experiment_id": "exp-123"}
                elif "runs/create" in self.path:
                    resp = {"run": {"info": {"run_id": "run-456"}}}
                elif "runs/log-batch" in self.path:
                    resp = {}
                elif "runs/set-tag" in self.path:
                    resp = {}
                elif "runs/update" in self.path:
                    resp = {}
                else:
                    self.send_response(404)
                    self.end_headers()
                    return

                self.send_response(200)
                self.send_header("Content-Type", "application/json")
                self.end_headers()
                self.wfile.write(json.dumps(resp).encode())

            def log_message(self, format, *args):
                pass

        server = HTTPServer(("127.0.0.1", 0), Handler)
        port = server.server_address[1]
        thread = Thread(target=server.serve_forever, daemon=True)
        thread.start()
        yield f"http://127.0.0.1:{port}", calls
        server.shutdown()

    def test_full_tracking_flow(self, mock_server):
        uri, calls = mock_server
        config = TrackingConfig(tracking_uri=uri, dry_run=False)
        result = track_result(_minimal_result(), config)

        assert result.success is True
        assert result.run_id == "run-456"
        assert result.experiment_id == "exp-123"

        paths = [c[1] for c in calls]
        assert any("experiments/search" in p for p in paths)
        assert any("experiments/create" in p for p in paths)
        assert any("runs/create" in p for p in paths)
        assert any("runs/log-batch" in p for p in paths)
        assert any("runs/update" in p for p in paths)

    def test_tags_sent_on_create(self, mock_server):
        uri, calls = mock_server
        config = TrackingConfig(tracking_uri=uri, dry_run=False)
        track_result(_minimal_result(), config)

        create_calls = [c for c in calls if "runs/create" in c[1]]
        assert len(create_calls) == 1
        body = create_calls[0][2]
        tag_keys = {t["key"] for t in body["tags"]}
        assert "condition_id" in tag_keys
        assert "experiment_id" in tag_keys
        assert "tracking_contract_version" in tag_keys

    def test_metrics_sent_in_batch(self, mock_server):
        uri, calls = mock_server
        config = TrackingConfig(tracking_uri=uri, dry_run=False)
        track_result(_minimal_result(), config)

        batch_calls = [c for c in calls if "runs/log-batch" in c[1]]
        assert len(batch_calls) == 1
        body = batch_calls[0][2]
        metric_keys = {m["key"] for m in body["metrics"]}
        assert "telemetry.duration_seconds" in metric_keys
        assert "response.success" in metric_keys

    def test_run_terminated(self, mock_server):
        uri, calls = mock_server
        config = TrackingConfig(tracking_uri=uri, dry_run=False)
        track_result(_minimal_result(), config)

        update_calls = [c for c in calls if "runs/update" in c[1]]
        assert len(update_calls) == 1
        assert update_calls[0][2]["status"] == "FINISHED"

    def test_ping_uses_post_with_json_body(self, mock_server):
        uri, calls = mock_server
        client = MLflowRESTClient(uri)
        assert client.ping() is True

        ping_calls = [
            c for c in calls if "experiments/search" in c[1]
        ]
        assert len(ping_calls) == 1
        method, _, body = ping_calls[0]
        assert method == "POST", (
            f"ping must use POST (MLflow experiments/search is a POST API), "
            f"got {method}"
        )
        assert isinstance(body, dict), "ping must send a valid JSON body"
        assert "max_results" in body

    def test_preflight_reachable(self, mock_server):
        uri, _ = mock_server
        config = TrackingConfig(tracking_uri=uri)
        result = preflight(config)
        assert result.configured is True
        assert result.reachable is True
        assert result.ok is True


class TestTrackingContractVersion:
    """Contract version must be consistent and present."""

    def test_version_is_semver(self):
        parts = TRACKING_CONTRACT_VERSION.split(".")
        assert len(parts) == 3
        assert all(p.isdigit() for p in parts)

    def test_version_in_tags(self):
        result = _minimal_result()
        tags = _build_tags(result)
        assert tags["tracking_contract_version"] == TRACKING_CONTRACT_VERSION


class TestConditionVariants:
    """Different condition types produce appropriate tags and refs."""

    def test_combined_condition_tags(self):
        result = _minimal_result(
            condition_id="combined",
            provenance={
                "architecture_context_sha": "abc123",
                "corpus_version": "1.0.0",
                "experiment_manifest_version": "1.3.0",
                "index_generation_sha": "idx789",
                "query_binary_version": "v0.5.0",
            },
        )
        tags = _build_tags(result)
        assert tags["condition_id"] == "combined"
        assert tags["provenance.index_generation_sha"] == "idx789"
        assert tags["provenance.query_binary_version"] == "v0.5.0"

    def test_combined_condition_artifact_refs(self):
        result = _minimal_result(
            condition_id="combined",
            provenance={
                "architecture_context_sha": "abc123",
                "corpus_version": "1.0.0",
                "experiment_manifest_version": "1.3.0",
                "index_generation_sha": "idx789",
                "query_binary_version": "v0.5.0",
            },
        )
        refs = _build_artifact_refs(result)
        assert "architecture-context:abc123" in refs
        assert "index-generation:idx789" in refs
        assert "query-binary:v0.5.0" in refs

    def test_baseline_no_index_or_query_refs(self):
        result = _minimal_result(condition_id="baseline")
        refs = _build_artifact_refs(result)
        assert not any(r.startswith("index-generation:") for r in refs)
        assert not any(r.startswith("query-binary:") for r in refs)
