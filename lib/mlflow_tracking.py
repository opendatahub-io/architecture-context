"""Versioned MLflow tracking adapter for experiment result recording.

Supports two backends:

1. **REST mode** (``MLFLOW_TRACKING_URI``): uses stdlib ``urllib`` to talk
   to an external MLflow tracking server.  No MLflow SDK required.
2. **Local file-backed mode** (``MLFLOW_RUNS_DIR``): uses the MLflow SDK
   ``FileStore`` so runs persist to a local directory without any server.
   The SDK is an optional dependency — it is pinned only in the task
   container (``scripts/Dockerfile.claude``).

When both ``MLFLOW_TRACKING_URI`` and ``MLFLOW_RUNS_DIR`` are set, the
local file-backed mode takes precedence.

The adapter enforces:
- Deterministic experiment/run metadata derived from the experiment manifest.
- Condition identity, provenance, and telemetry as run tags.
- Scored metrics mapped from validated result records.
- Artifact references (not uploads) logged as run tags.
- Safe path sanitization for ``MLFLOW_RUNS_DIR`` (no traversal, resolved
  symlinks, writable target).
- A no-network dry-run/preflight mode that reports configuration status
  without creating any external state.

Missing tracking configuration or an unreachable endpoint is an explicit
preflight failure, never a silent success.
"""

from __future__ import annotations

import json
import os
import urllib.error
import urllib.request
from dataclasses import asdict, dataclass, field
from pathlib import Path
from typing import Any

TRACKING_CONTRACT_VERSION = "1.0.0"

_CONNECT_TIMEOUT_SECONDS = 5


@dataclass(frozen=True)
class TrackingConfig:
    """Resolved MLflow tracking configuration."""

    tracking_uri: str | None = None
    runs_dir: str | None = None
    experiment_name: str = "analyzer-assisted-retrieval-v1"
    dry_run: bool = False

    @classmethod
    def from_env(cls, *, dry_run: bool = False) -> TrackingConfig:
        return cls(
            tracking_uri=os.environ.get("MLFLOW_TRACKING_URI"),
            runs_dir=os.environ.get("MLFLOW_RUNS_DIR"),
            experiment_name=os.environ.get(
                "MLFLOW_EXPERIMENT_NAME",
                "analyzer-assisted-retrieval-v1",
            ),
            dry_run=dry_run,
        )

    @property
    def is_local(self) -> bool:
        return self.runs_dir is not None


@dataclass
class PreflightResult:
    """Result of a tracking preflight check."""

    configured: bool
    reachable: bool
    tracking_uri: str | None
    experiment_name: str
    required_fields: list[str]
    errors: list[str] = field(default_factory=list)
    dry_run: bool = False
    mode: str = "rest"
    runs_dir: str | None = None

    def to_dict(self) -> dict[str, Any]:
        return asdict(self)

    @property
    def ok(self) -> bool:
        return self.configured and self.reachable and not self.errors


REQUIRED_RESULT_FIELDS = [
    "experiment_id",
    "condition_id",
    "question_id",
    "model",
    "runner_version",
    "timestamp",
    "provenance",
]


@dataclass
class TrackingResult:
    """Outcome of a tracking operation."""

    success: bool
    run_id: str | None = None
    experiment_id: str | None = None
    dry_run: bool = False
    error: str | None = None
    tags_logged: dict[str, str] = field(default_factory=dict)
    metrics_logged: dict[str, float] = field(default_factory=dict)
    artifacts_referenced: list[str] = field(default_factory=list)

    def to_dict(self) -> dict[str, Any]:
        return asdict(self)


def _build_tags(result: dict) -> dict[str, str]:
    """Extract deterministic tags from a validated result record."""
    tags: dict[str, str] = {}
    tags["tracking_contract_version"] = TRACKING_CONTRACT_VERSION

    for key in ("experiment_id", "condition_id", "question_id",
                "model", "runner_version", "timestamp"):
        val = result.get(key)
        if val is not None:
            tags[key] = str(val)

    for key in ("question_category", "question_difficulty", "question_scope"):
        val = result.get(key)
        if val is not None:
            tags[key] = str(val)

    if result.get("schema_version"):
        tags["schema_version"] = str(result["schema_version"])
    if result.get("condition_available") is not None:
        tags["condition_available"] = str(result["condition_available"]).lower()
    if result.get("seed") is not None:
        tags["seed"] = str(result["seed"])

    provenance = result.get("provenance", {})
    if isinstance(provenance, dict):
        for pkey in ("architecture_context_sha", "corpus_version",
                     "experiment_manifest_version", "index_generation_sha",
                     "query_binary_version", "context_telemetry_version"):
            val = provenance.get(pkey)
            if val is not None:
                tags[f"provenance.{pkey}"] = str(val)

    fc = result.get("failure_classifications", [])
    if isinstance(fc, list) and fc:
        tags["failure_classifications"] = ",".join(fc)

    return tags


def _build_metrics(result: dict) -> dict[str, float]:
    """Extract numeric metrics from a validated result record."""
    metrics: dict[str, float] = {}

    response = result.get("response", {})
    if isinstance(response, dict):
        if response.get("success") is not None:
            metrics["response.success"] = 1.0 if response["success"] else 0.0

    telemetry = result.get("telemetry", {})
    if isinstance(telemetry, dict):
        for tkey in ("duration_seconds", "input_tokens", "output_tokens",
                     "total_cost_usd", "num_turns"):
            val = telemetry.get(tkey)
            if val is not None and isinstance(val, (int, float)):
                metrics[f"telemetry.{tkey}"] = float(val)

        tool_calls = telemetry.get("tool_calls", {})
        if isinstance(tool_calls, dict):
            for tool_name, count in tool_calls.items():
                if isinstance(count, (int, float)):
                    metrics[f"telemetry.tool_calls.{tool_name}"] = float(count)

    ctx = result.get("context_metrics", {})
    if isinstance(ctx, dict):
        for ckey in ("context_fetches", "useful_reads", "navigation_reads",
                     "queries_issued"):
            val = ctx.get(ckey)
            if val is not None and isinstance(val, (int, float)):
                metrics[f"context_metrics.{ckey}"] = float(val)

    return metrics


def _build_artifact_refs(result: dict) -> list[str]:
    """Extract artifact reference paths from a validated result record."""
    refs: list[str] = []

    provenance = result.get("provenance", {})
    if isinstance(provenance, dict):
        sha = provenance.get("architecture_context_sha")
        if sha:
            refs.append(f"architecture-context:{sha}")
        idx_sha = provenance.get("index_generation_sha")
        if idx_sha:
            refs.append(f"index-generation:{idx_sha}")
        qbv = provenance.get("query_binary_version")
        if qbv:
            refs.append(f"query-binary:{qbv}")

    response = result.get("response", {})
    if isinstance(response, dict):
        citations = response.get("source_citations", [])
        if isinstance(citations, list):
            for cite in citations:
                if isinstance(cite, dict) and cite.get("file"):
                    refs.append(f"source-citation:{cite['file']}")

    return refs


def _validate_required_fields(result: dict) -> list[str]:
    """Check that required fields are present in a result record."""
    errors: list[str] = []
    for fld in REQUIRED_RESULT_FIELDS:
        if fld not in result:
            errors.append(f"missing required field: {fld}")
        elif result[fld] is None:
            errors.append(f"required field is null: {fld}")
        elif isinstance(result[fld], str) and not result[fld].strip():
            errors.append(f"required field is empty: {fld}")

    provenance = result.get("provenance")
    if isinstance(provenance, dict):
        sha = provenance.get("architecture_context_sha")
        if not sha or (isinstance(sha, str) and not sha.strip()):
            errors.append(
                "provenance.architecture_context_sha is required and non-empty"
            )
    return errors


class MLflowRESTClient:
    """Minimal MLflow REST API client using stdlib HTTP."""

    def __init__(self, tracking_uri: str, *, timeout: int = _CONNECT_TIMEOUT_SECONDS):
        self._base_url = tracking_uri.rstrip("/")
        self._timeout = timeout

    def ping(self) -> bool:
        """Check connectivity to the MLflow tracking server."""
        try:
            body = json.dumps({"max_results": 1}).encode("utf-8")
            req = urllib.request.Request(
                f"{self._base_url}/api/2.0/mlflow/experiments/search",
                data=body,
                method="POST",
                headers={"Content-Type": "application/json"},
            )
            urllib.request.urlopen(req, timeout=self._timeout)
            return True
        except (urllib.error.URLError, OSError):
            return False

    def get_or_create_experiment(self, name: str) -> str:
        """Get or create an MLflow experiment by name. Returns experiment ID."""
        search_body = json.dumps(
            {"filter": f"name = '{name}'", "max_results": 10}
        ).encode("utf-8")
        req = urllib.request.Request(
            f"{self._base_url}/api/2.0/mlflow/experiments/search",
            data=search_body,
            method="POST",
            headers={"Content-Type": "application/json"},
        )
        resp = urllib.request.urlopen(req, timeout=self._timeout)
        data = json.loads(resp.read())
        experiments = data.get("experiments", [])
        if experiments:
            return experiments[0]["experiment_id"]

        create_body = json.dumps({"name": name}).encode("utf-8")
        req = urllib.request.Request(
            f"{self._base_url}/api/2.0/mlflow/experiments/create",
            data=create_body,
            method="POST",
            headers={"Content-Type": "application/json"},
        )
        resp = urllib.request.urlopen(req, timeout=self._timeout)
        data = json.loads(resp.read())
        return data["experiment_id"]

    def create_run(self, experiment_id: str, *, run_name: str,
                   tags: dict[str, str]) -> str:
        """Create an MLflow run. Returns run ID."""
        tag_list = [{"key": k, "value": v} for k, v in sorted(tags.items())]
        body = json.dumps({
            "experiment_id": experiment_id,
            "run_name": run_name,
            "tags": tag_list,
        }).encode("utf-8")
        req = urllib.request.Request(
            f"{self._base_url}/api/2.0/mlflow/runs/create",
            data=body,
            method="POST",
            headers={"Content-Type": "application/json"},
        )
        resp = urllib.request.urlopen(req, timeout=self._timeout)
        data = json.loads(resp.read())
        return data["run"]["info"]["run_id"]

    def log_metrics(self, run_id: str, metrics: dict[str, float],
                    timestamp_ms: int = 0) -> None:
        """Log a batch of metrics to a run."""
        if not metrics:
            return
        metric_list = [
            {"key": k, "value": v, "timestamp": timestamp_ms, "step": 0}
            for k, v in sorted(metrics.items())
        ]
        body = json.dumps({
            "run_id": run_id,
            "metrics": metric_list,
        }).encode("utf-8")
        req = urllib.request.Request(
            f"{self._base_url}/api/2.0/mlflow/runs/log-batch",
            data=body,
            method="POST",
            headers={"Content-Type": "application/json"},
        )
        urllib.request.urlopen(req, timeout=self._timeout)

    def set_tags(self, run_id: str, tags: dict[str, str]) -> None:
        """Set tags on a run (for artifact references and overflow tags)."""
        for key, value in sorted(tags.items()):
            body = json.dumps({
                "run_id": run_id,
                "key": key,
                "value": value,
            }).encode("utf-8")
            req = urllib.request.Request(
                f"{self._base_url}/api/2.0/mlflow/runs/set-tag",
                data=body,
                method="POST",
                headers={"Content-Type": "application/json"},
            )
            urllib.request.urlopen(req, timeout=self._timeout)

    def set_terminated(self, run_id: str, status: str = "FINISHED") -> None:
        """Mark a run as terminated."""
        body = json.dumps({
            "run_id": run_id,
            "status": status,
        }).encode("utf-8")
        req = urllib.request.Request(
            f"{self._base_url}/api/2.0/mlflow/runs/update",
            data=body,
            method="POST",
            headers={"Content-Type": "application/json"},
        )
        urllib.request.urlopen(req, timeout=self._timeout)


def _validate_runs_dir(raw_path: str) -> tuple[Path, list[str]]:
    """Validate and resolve MLFLOW_RUNS_DIR with path safety checks.

    Returns (resolved_path, errors).  An empty error list means the path
    is safe to use.
    """
    errors: list[str] = []
    p = Path(raw_path)

    if ".." in p.parts:
        errors.append(
            f"MLFLOW_RUNS_DIR contains path traversal component: {raw_path}"
        )
        return p, errors

    try:
        resolved = p.resolve(strict=False)
    except (OSError, ValueError) as exc:
        errors.append(f"MLFLOW_RUNS_DIR cannot be resolved: {exc}")
        return p, errors

    raw_resolved = Path(raw_path).resolve(strict=False)
    if p.is_symlink():
        if not str(resolved).startswith(str(raw_resolved.parent)):
            errors.append(
                f"MLFLOW_RUNS_DIR symlink resolves outside its parent: "
                f"{raw_path} -> {resolved}"
            )
            return resolved, errors

    if resolved.exists() and not resolved.is_dir():
        errors.append(
            f"MLFLOW_RUNS_DIR exists but is not a directory: {resolved}"
        )
        return resolved, errors

    if resolved.exists() and not os.access(resolved, os.W_OK):
        errors.append(
            f"MLFLOW_RUNS_DIR is not writable: {resolved}"
        )
        return resolved, errors

    return resolved, errors


class MLflowLocalClient:
    """Local file-backed MLflow client using the MLflow SDK's MlflowClient."""

    def __init__(self, runs_dir: Path):
        self._runs_dir = runs_dir
        self._mlflow = _import_mlflow()
        self._client = None

    def _get_client(self):
        if self._client is None:
            tracking_uri = self._runs_dir.as_uri()
            self._client = self._mlflow.tracking.MlflowClient(tracking_uri)
        return self._client

    def ready(self) -> bool:
        """Check that the MLflow SDK is available and the directory is usable."""
        if self._mlflow is None:
            return False
        try:
            self._runs_dir.mkdir(parents=True, exist_ok=True)
            return self._runs_dir.is_dir() and os.access(self._runs_dir, os.W_OK)
        except OSError:
            return False

    def get_or_create_experiment(self, name: str) -> str:
        client = self._get_client()
        exp = client.get_experiment_by_name(name)
        if exp is not None:
            return exp.experiment_id
        return client.create_experiment(name)

    def create_run(
        self, experiment_id: str, *, run_name: str, tags: dict[str, str],
    ) -> str:
        client = self._get_client()
        all_tags = dict(tags)
        all_tags["mlflow.runName"] = run_name
        run = client.create_run(experiment_id, tags=all_tags)
        return run.info.run_id

    def log_metrics(self, run_id: str, metrics: dict[str, float]) -> None:
        if not metrics:
            return
        client = self._get_client()
        for key, value in sorted(metrics.items()):
            client.log_metric(run_id, key, value)

    def set_terminated(self, run_id: str, status: str = "FINISHED") -> None:
        client = self._get_client()
        client.set_terminated(run_id, status=status)


def _import_mlflow():
    """Import mlflow if available, return None otherwise."""
    try:
        import mlflow
        return mlflow
    except ImportError:
        return None


def preflight(config: TrackingConfig | None = None) -> PreflightResult:
    """Run a preflight check for tracking configuration.

    Reports the tracking mode, URI/directory, experiment name, required
    fields, and any configuration or connectivity errors. Never creates
    external state.
    """
    if config is None:
        config = TrackingConfig.from_env()

    errors: list[str] = []

    if config.is_local:
        resolved, path_errors = _validate_runs_dir(config.runs_dir)
        if path_errors:
            return PreflightResult(
                configured=True,
                reachable=False,
                tracking_uri=None,
                experiment_name=config.experiment_name,
                required_fields=list(REQUIRED_RESULT_FIELDS),
                errors=path_errors,
                dry_run=config.dry_run,
                mode="local",
                runs_dir=str(resolved),
            )

        if config.dry_run:
            errors.append("dry-run mode: local store check skipped")
        elif _import_mlflow() is None:
            errors.append(
                "mlflow package is not installed. "
                "Install it to enable local file-backed tracking."
            )
            return PreflightResult(
                configured=True,
                reachable=False,
                tracking_uri=None,
                experiment_name=config.experiment_name,
                required_fields=list(REQUIRED_RESULT_FIELDS),
                errors=errors,
                dry_run=config.dry_run,
                mode="local",
                runs_dir=str(resolved),
            )
        else:
            client = MLflowLocalClient(resolved)
            reachable = client.ready()
            if not reachable:
                errors.append(
                    f"MLFLOW_RUNS_DIR is not usable: {resolved}"
                )

        return PreflightResult(
            configured=True,
            reachable=not errors or config.dry_run,
            tracking_uri=None,
            experiment_name=config.experiment_name,
            required_fields=list(REQUIRED_RESULT_FIELDS),
            errors=errors,
            dry_run=config.dry_run,
            mode="local",
            runs_dir=str(resolved),
        )

    configured = config.tracking_uri is not None
    reachable = False

    if not configured:
        errors.append(
            "MLFLOW_TRACKING_URI is not set. "
            "Set it to the MLflow tracking server URL "
            "(e.g. http://localhost:5000) to enable experiment tracking. "
            "Alternatively, set MLFLOW_RUNS_DIR for local file-backed tracking."
        )
    elif config.dry_run:
        errors.append(
            "dry-run mode: connectivity check skipped"
        )
    else:
        client = MLflowRESTClient(config.tracking_uri)
        reachable = client.ping()
        if not reachable:
            errors.append(
                f"MLflow tracking server at {config.tracking_uri} "
                f"is not reachable. Verify the server is running and "
                f"the URI is correct."
            )

    return PreflightResult(
        configured=configured,
        reachable=reachable,
        tracking_uri=config.tracking_uri,
        experiment_name=config.experiment_name,
        required_fields=list(REQUIRED_RESULT_FIELDS),
        errors=errors,
        dry_run=config.dry_run,
        mode="rest",
    )


def track_result(
    result: dict,
    config: TrackingConfig | None = None,
) -> TrackingResult:
    """Log a validated experiment result to MLflow.

    In dry-run mode, returns the tags, metrics, and artifact references
    that *would* be logged without making any network requests. When
    ``MLFLOW_TRACKING_URI`` is not set or the server is unreachable,
    returns an explicit error — never silently succeeds.
    """
    if config is None:
        config = TrackingConfig.from_env()

    field_errors = _validate_required_fields(result)
    if field_errors:
        return TrackingResult(
            success=False,
            dry_run=config.dry_run,
            error=f"result validation failed: {'; '.join(field_errors)}",
        )

    tags = _build_tags(result)
    metrics = _build_metrics(result)
    artifact_refs = _build_artifact_refs(result)

    for i, ref in enumerate(artifact_refs):
        tags[f"artifact_ref.{i}"] = ref

    if config.dry_run:
        return TrackingResult(
            success=True,
            dry_run=True,
            tags_logged=tags,
            metrics_logged=metrics,
            artifacts_referenced=artifact_refs,
        )

    if config.is_local:
        return _track_result_local(result, config, tags, metrics, artifact_refs)

    if not config.tracking_uri:
        return TrackingResult(
            success=False,
            error=(
                "MLFLOW_TRACKING_URI is not set. "
                "Cannot track results without a configured tracking server. "
                "Alternatively, set MLFLOW_RUNS_DIR for local file-backed tracking."
            ),
        )

    try:
        client = MLflowRESTClient(config.tracking_uri)

        experiment_id = client.get_or_create_experiment(config.experiment_name)

        condition_id = result.get("condition_id", "unknown")
        question_id = result.get("question_id", "unknown")
        run_name = f"{condition_id}/{question_id}"

        run_id = client.create_run(
            experiment_id, run_name=run_name, tags=tags,
        )

        if metrics:
            client.log_metrics(run_id, metrics)

        client.set_terminated(run_id, status="FINISHED")

        return TrackingResult(
            success=True,
            run_id=run_id,
            experiment_id=experiment_id,
            tags_logged=tags,
            metrics_logged=metrics,
            artifacts_referenced=artifact_refs,
        )

    except (urllib.error.URLError, OSError) as exc:
        return TrackingResult(
            success=False,
            error=f"MLflow tracking server error: {exc}",
        )
    except (json.JSONDecodeError, KeyError, TypeError) as exc:
        return TrackingResult(
            success=False,
            error=f"MLflow response parsing error: {exc}",
        )


def _track_result_local(
    result: dict,
    config: TrackingConfig,
    tags: dict[str, str],
    metrics: dict[str, float],
    artifact_refs: list[str],
) -> TrackingResult:
    """Log a result using the local file-backed MLflow store."""
    resolved, path_errors = _validate_runs_dir(config.runs_dir)
    if path_errors:
        return TrackingResult(
            success=False,
            error=f"MLFLOW_RUNS_DIR validation failed: {'; '.join(path_errors)}",
        )

    mlflow = _import_mlflow()
    if mlflow is None:
        return TrackingResult(
            success=False,
            error=(
                "mlflow package is not installed. "
                "Install it to enable local file-backed tracking."
            ),
        )

    try:
        client = MLflowLocalClient(resolved)
        if not client.ready():
            return TrackingResult(
                success=False,
                error=f"MLFLOW_RUNS_DIR is not usable: {resolved}",
            )

        experiment_id = client.get_or_create_experiment(config.experiment_name)

        condition_id = result.get("condition_id", "unknown")
        question_id = result.get("question_id", "unknown")
        run_name = f"{condition_id}/{question_id}"

        run_id = client.create_run(
            experiment_id, run_name=run_name, tags=tags,
        )

        if metrics:
            client.log_metrics(run_id, metrics)

        client.set_terminated(run_id, status="FINISHED")

        return TrackingResult(
            success=True,
            run_id=run_id,
            experiment_id=experiment_id,
            tags_logged=tags,
            metrics_logged=metrics,
            artifacts_referenced=artifact_refs,
        )

    except Exception as exc:
        return TrackingResult(
            success=False,
            error=f"MLflow local tracking error: {exc}",
        )
