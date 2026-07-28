"""Validation for agent source-read justification sidecars."""

from __future__ import annotations

import json
from pathlib import Path

_OUTCOMES = {"resolved", "partially-resolved", "contradicted", "unhelpful"}
_REQUIRED = {
    "path",
    "line_range",
    "gap_category",
    "question",
    "expected_signal",
    "outcome",
    "sections",
}
_FORBIDDEN = {"content", "excerpt", "secret", "prompt", "transcript"}
_KNOWN_CATEGORIES = {
    "architecture_components",
    "authentication",
    "authorization",
    "configuration_lifecycle",
    "egress",
    "grpc_services",
    "http_endpoints",
    "ingress",
    "integration_points",
    "internal_dependencies",
    "kubernetes_relationships",
    "rbac_cluster_roles",
    "services",
    "webhooks",
}


def validate_source_read_justifications(path: Path, telemetry: dict | None) -> dict:
    """Return warning-only validation and coverage metrics for one sidecar."""
    observed = set((telemetry or {}).get("source_files_read", ()))
    result = {
        "present": path.is_file(),
        "record_count": 0,
        "observed_source_file_count": len(observed),
        "justified_source_file_count": 0,
        "justified_read_ratio": 1.0 if not observed else 0.0,
        "missing_paths": [],
        "extra_paths": [],
        "warnings": [],
        "category_counts": {},
        "oversized_read_count": 0,
    }
    if not path.is_file():
        if observed:
            result["warnings"].append("sidecar missing for observed source reads")
        return result
    try:
        payload = json.loads(path.read_text())
    except (OSError, json.JSONDecodeError) as error:
        result["warnings"].append(f"sidecar is not valid JSON: {error}")
        return result
    records = payload.get("reads") if isinstance(payload, dict) else None
    if not isinstance(records, list):
        result["warnings"].append("sidecar must contain a reads array")
        return result
    paths: set[str] = set()
    for index, record in enumerate(records):
        if not isinstance(record, dict):
            result["warnings"].append(f"record {index} is not an object")
            continue
        missing = sorted(_REQUIRED - set(record))
        forbidden = sorted(_FORBIDDEN & set(record))
        if missing:
            result["warnings"].append(
                f"record {index} missing fields: {', '.join(missing)}"
            )
        if forbidden:
            result["warnings"].append(
                f"record {index} contains forbidden fields: {', '.join(forbidden)}"
            )
        source = record.get("path")
        if (
            not isinstance(source, str)
            or not source
            or Path(source).is_absolute()
            or ".." in Path(source).parts
        ):
            result["warnings"].append(
                f"record {index} path must be relative to checkout"
            )
            continue
        if record.get("outcome") not in _OUTCOMES:
            result["warnings"].append(f"record {index} has invalid outcome")
        if not isinstance(record.get("sections"), list):
            result["warnings"].append(f"record {index} sections must be an array")
        categories = record.get("gap_category")
        if isinstance(categories, str):
            categories = [
                item.strip() for item in categories.split(",") if item.strip()
            ]
            result["warnings"].append(
                f"record {index} uses legacy string gap_category; emit an array"
            )
        if (
            not isinstance(categories, list)
            or not categories
            or not all(
                isinstance(category, str) and category in _KNOWN_CATEGORIES
                for category in categories
            )
        ):
            result["warnings"].append(f"record {index} has invalid gap_category values")
        else:
            for category in categories:
                result["category_counts"][category] = (
                    result["category_counts"].get(category, 0) + 1
                )
        line_range = record.get("line_range")
        if isinstance(line_range, str) and "-" in line_range:
            try:
                start, end = (int(value) for value in line_range.split("-", 1))
            except ValueError:
                start = end = 0
            if end >= start and end - start + 1 > 400:
                result["oversized_read_count"] += 1
                if not record.get("scope_reason"):
                    result["warnings"].append(
                        f"record {index} has an oversized range without scope_reason"
                    )
        paths.add(source)
    result["record_count"] = len(records)
    missing_paths = sorted(observed - paths)
    extra_paths = sorted(paths - observed)
    result["missing_paths"] = missing_paths
    result["extra_paths"] = extra_paths
    result["justified_source_file_count"] = len(observed - set(missing_paths))
    result["justified_read_ratio"] = (
        result["justified_source_file_count"] / len(observed) if observed else 1.0
    )
    if missing_paths:
        result["warnings"].append(
            f"{len(missing_paths)} observed source file(s) lack a justification"
        )
    if extra_paths:
        result["warnings"].append(
            f"{len(extra_paths)} ledger path(s) were not observed by telemetry"
        )
    return result
