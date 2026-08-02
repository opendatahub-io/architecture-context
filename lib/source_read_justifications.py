"""Validation for agent source-read justification sidecars."""

from __future__ import annotations

import json
import posixpath
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
    "fips_compliance",
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


def _normalize_observed_path(value: object) -> str | None:
    if not isinstance(value, str):
        return None
    path = value.strip().replace("\\", "/")
    if not path:
        return None
    path = posixpath.normpath(path)
    if path == ".":
        return None
    if path.startswith("./"):
        path = path[2:]
    return path


def _normalize_ledger_path(value: object) -> str | None:
    path = _normalize_observed_path(value)
    if path is None:
        return None
    if path.startswith("/") or path == ".." or path.startswith("../"):
        return None
    return path


def _paths_match(observed: str, ledger: str) -> bool:
    return observed == ledger or observed.endswith(f"/{ledger}")


def _has_only_bounded_telemetry_ranges(
    telemetry: dict | None,
    source: str,
) -> bool:
    """Recognize a sidecar range that aggregates bounded tool reads."""
    ranges = (telemetry or {}).get("source_read_ranges", ())
    matching = []
    for item in ranges:
        if not isinstance(item, dict):
            continue
        item_path = _normalize_observed_path(item.get("path"))
        if item_path is None or not _paths_match(item_path, source):
            continue
        limit = item.get("limit")
        try:
            limit_value = int(limit)
        except (TypeError, ValueError):
            return False
        if limit_value <= 0 or limit_value > 400:
            return False
        matching.append(item)
    return bool(matching)


def _add_diagnostic(
    result: dict,
    *,
    category: str,
    owner: str,
    message: str,
    **fields,
) -> None:
    diagnostic = {
        "category": category,
        "owner": owner,
        "message": message,
    }
    diagnostic.update(fields)
    result["diagnostics"].append(diagnostic)


def _add_warning(
    result: dict,
    *,
    category: str,
    owner: str,
    message: str,
    **fields,
) -> None:
    _add_diagnostic(
        result,
        category=category,
        owner=owner,
        message=message,
        **fields,
    )
    result["warnings"].append(f"{category}: {message}")


def _repair_record(record: dict, index: int, result: dict) -> bool:
    repaired = False
    if "sections" not in record or not isinstance(record.get("sections"), list):
        record["sections"] = []
        result["repairs"].append(
            {
                "record": index,
                "field": "sections",
                "action": "defaulted-empty-array",
            }
        )
        repaired = True
    categories = record.get("gap_category")
    if isinstance(categories, str):
        repaired_categories = [
            item.strip() for item in categories.split(",") if item.strip()
        ]
        record["gap_category"] = repaired_categories
        result["repairs"].append(
            {
                "record": index,
                "field": "gap_category",
                "action": "split-legacy-string",
            }
        )
        repaired = True
    normalized_path = _normalize_ledger_path(record.get("path"))
    if normalized_path is not None and normalized_path != record.get("path"):
        record["path"] = normalized_path
        result["repairs"].append(
            {
                "record": index,
                "field": "path",
                "action": "normalized-relative-path",
            }
        )
        repaired = True
    return repaired


def _repair_gap_categories(
    gap_categories: tuple[str, ...] | list[str] | None,
) -> list[str]:
    categories = []
    for raw_category in gap_categories or ():
        if not isinstance(raw_category, str):
            continue
        category = raw_category.strip()
        if category in _KNOWN_CATEGORIES and category not in categories:
            categories.append(category)
    return categories or ["architecture_components"]


def _append_observed_read_repair(
    records: list,
    result: dict,
    *,
    source: str,
    gap_categories: list[str],
) -> None:
    index = len(records)
    records.append(
        {
            "path": source,
            "line_range": "unknown",
            "gap_category": gap_categories,
            "question": (
                "Orchestrator observed this source file read, but the agent "
                "omitted its read-justification metadata."
            ),
            "expected_signal": (
                "Original read intent was not recorded by the agent; preserve "
                "the source-read audit trail for follow-up."
            ),
            "outcome": "unhelpful",
            "sections": [],
            "repair": True,
            "repair_reason": "observed-source-read-missing-from-sidecar",
        }
    )
    result["repairs"].append(
        {
            "record": index,
            "field": "reads",
            "action": "append-observed-source-read",
            "path": source,
        }
    )
    _add_diagnostic(
        result,
        category="missing-justification-repaired",
        owner="orchestrator",
        message=(
            "observed source read was appended to the sidecar as a "
            "conservative repair"
        ),
        record=index,
        path=source,
    )


def _default_component_name(path: Path) -> str:
    if path.parent.name == ".generation" and path.parent.parent.name:
        return path.parent.parent.name
    return "unknown"


def validate_source_read_justifications(
    path: Path,
    telemetry: dict | None,
    *,
    repair_missing_observed: bool = False,
    component: str | None = None,
    gap_categories: tuple[str, ...] | list[str] | None = None,
) -> dict:
    """Return warning-only validation and coverage metrics for one sidecar."""
    observed = {
        normalized
        for raw in (telemetry or {}).get("source_files_read", ())
        if (normalized := _normalize_observed_path(raw)) is not None
    }
    result = {
        "present": path.is_file(),
        "record_count": 0,
        "observed_source_file_count": len(observed),
        "justified_source_file_count": 0,
        "justified_read_ratio": 1.0 if not observed else 0.0,
        "missing_paths": [],
        "extra_paths": [],
        "warnings": [],
        "diagnostics": [],
        "repairs": [],
        "category_counts": {},
        "oversized_read_count": 0,
        "oversized_read_category_counts": {},
        "oversized_reads": [],
    }
    if not path.is_file():
        if observed:
            if repair_missing_observed:
                repair_categories = _repair_gap_categories(gap_categories)
                records: list = []
                payload = {
                    "schema_version": 1,
                    "component": component or _default_component_name(path),
                    "reads": records,
                }
                for source in sorted(observed):
                    _append_observed_read_repair(
                        records,
                        result,
                        source=source,
                        gap_categories=repair_categories,
                    )
                result["record_count"] = len(records)
                result["justified_source_file_count"] = len(observed)
                result["justified_read_ratio"] = 1.0
                result["category_counts"] = {
                    category: len(records) for category in repair_categories
                }
                path.parent.mkdir(parents=True, exist_ok=True)
                path.write_text(json.dumps(payload, indent=2, sort_keys=True) + "\n")
                return result
            _add_warning(
                result,
                category="missing-sidecar",
                owner="agent",
                message="sidecar missing for observed source reads",
            )
        return result
    try:
        payload = json.loads(path.read_text())
    except (OSError, json.JSONDecodeError) as error:
        _add_warning(
            result,
            category="invalid-sidecar-json",
            owner="agent",
            message=f"sidecar is not valid JSON: {error}",
        )
        return result
    records = payload.get("reads") if isinstance(payload, dict) else None
    if not isinstance(records, list):
        _add_warning(
            result,
            category="invalid-sidecar-shape",
            owner="agent",
            message="sidecar must contain a reads array",
        )
        return result
    paths: set[str] = set()
    for index, record in enumerate(records):
        if not isinstance(record, dict):
            _add_warning(
                result,
                category="malformed-record",
                owner="agent",
                message=f"record {index} is not an object",
                record=index,
            )
            continue
        repaired = _repair_record(record, index, result)
        missing = sorted(_REQUIRED - set(record))
        forbidden = sorted(_FORBIDDEN & set(record))
        record_valid_for_coverage = True
        if missing:
            record_valid_for_coverage = False
            _add_warning(
                result,
                category="malformed-record",
                owner="agent",
                message=f"record {index} missing fields: {', '.join(missing)}",
                record=index,
                fields=missing,
            )
        if forbidden:
            _add_warning(
                result,
                category="forbidden-metadata",
                owner="agent",
                message=(
                    f"record {index} contains forbidden fields: "
                    f"{', '.join(forbidden)}"
                ),
                record=index,
                fields=forbidden,
            )
        source = _normalize_ledger_path(record.get("path"))
        if source is None:
            record_valid_for_coverage = False
            _add_warning(
                result,
                category="invalid-ledger-path",
                owner="agent",
                message=f"record {index} path must be relative to checkout",
                record=index,
            )
            continue
        if record.get("outcome") not in _OUTCOMES:
            record_valid_for_coverage = False
            _add_warning(
                result,
                category="malformed-record",
                owner="agent",
                message=f"record {index} has invalid outcome",
                record=index,
            )
        categories = record.get("gap_category")
        if (
            not isinstance(categories, list)
            or not categories
            or not all(
                isinstance(category, str) and category in _KNOWN_CATEGORIES
                for category in categories
            )
        ):
            record_valid_for_coverage = False
            _add_warning(
                result,
                category="malformed-record",
                owner="agent",
                message=f"record {index} has invalid gap_category values",
                record=index,
            )
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
            if (
                end >= start
                and end - start + 1 > 400
                and not _has_only_bounded_telemetry_ranges(telemetry, source)
            ):
                result["oversized_read_count"] += 1
                line_count = end - start + 1
                oversized_categories = (
                    categories
                    if isinstance(categories, list)
                    and all(isinstance(category, str) for category in categories)
                    else []
                )
                for category in oversized_categories:
                    result["oversized_read_category_counts"][category] = (
                        result["oversized_read_category_counts"].get(category, 0) + 1
                    )
                result["oversized_reads"].append(
                    {
                        "record": index,
                        "path": source,
                        "line_range": line_range,
                        "line_count": line_count,
                        "gap_category": oversized_categories,
                        "scope_reason_present": bool(record.get("scope_reason")),
                    }
                )
                if not record.get("scope_reason"):
                    record_valid_for_coverage = False
                    _add_warning(
                        result,
                        category="oversized-read-missing-scope-reason",
                        owner="agent",
                        message=(
                            f"record {index} has an oversized range "
                            "without scope_reason"
                        ),
                        record=index,
                        path=source,
                    )
        if record_valid_for_coverage:
            paths.add(source)
        if repaired:
            _add_diagnostic(
                result,
                category="record-repaired",
                owner="orchestrator",
                message=f"record {index} was repaired before validation",
                record=index,
            )
    matched_observed = {
        observed_path
        for observed_path in observed
        if any(_paths_match(observed_path, ledger_path) for ledger_path in paths)
    }
    matched_ledger = {
        ledger_path
        for ledger_path in paths
        if any(_paths_match(observed_path, ledger_path) for observed_path in observed)
    }
    missing_paths = sorted(observed - matched_observed)
    if missing_paths and repair_missing_observed:
        repair_categories = _repair_gap_categories(gap_categories)
        for source in missing_paths:
            _append_observed_read_repair(
                records,
                result,
                source=source,
                gap_categories=repair_categories,
            )
            paths.add(source)
            for category in repair_categories:
                result["category_counts"][category] = (
                    result["category_counts"].get(category, 0) + 1
                )
        matched_observed = {
            observed_path
            for observed_path in observed
            if any(_paths_match(observed_path, ledger_path) for ledger_path in paths)
        }
        matched_ledger = {
            ledger_path
            for ledger_path in paths
            if any(
                _paths_match(observed_path, ledger_path) for observed_path in observed
            )
        }
        missing_paths = sorted(observed - matched_observed)
    extra_paths = sorted(paths - matched_ledger)
    if result["repairs"] and isinstance(payload, dict):
        path.write_text(json.dumps(payload, indent=2, sort_keys=True) + "\n")
    result["record_count"] = len(records)
    result["missing_paths"] = missing_paths
    result["extra_paths"] = extra_paths
    result["justified_source_file_count"] = len(observed - set(missing_paths))
    result["justified_read_ratio"] = (
        result["justified_source_file_count"] / len(observed) if observed else 1.0
    )
    if missing_paths:
        _add_warning(
            result,
            category="missing-justification",
            owner="agent",
            message=(
                f"{len(missing_paths)} observed source file(s) "
                "lack a justification"
            ),
            paths=missing_paths,
        )
    if extra_paths:
        _add_warning(
            result,
            category="unobserved-ledger-path",
            owner="agent",
            message=(
                f"{len(extra_paths)} ledger path(s) "
                "were not observed by telemetry"
            ),
            paths=extra_paths,
        )
    return result
