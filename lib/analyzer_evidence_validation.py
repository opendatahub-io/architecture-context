"""Validation for analyzer evidence quality contracts."""

from __future__ import annotations

import json
from pathlib import Path

_STATUSES = {
    "literal",
    "dependency-signal",
    "not-extracted",
    "observed",
    "inferred",
    "unresolved",
    "confirmed-empty",
}
_TOPICS = {
    "security",
    "ingress",
    "supply_chain",
    "disconnected_deployment",
    "high_availability",
    "deployment_topology",
}


def validate_analyzer_evidence(path: Path) -> dict[str, object]:
    """Return deterministic errors and warnings for analyzer evidence fields."""
    result: dict[str, object] = {
        "valid": True,
        "security_evidence_count": 0,
        "cross_cutting_count": 0,
        "errors": [],
        "warnings": [],
    }
    errors: list[str] = result["errors"]  # type: ignore[assignment]
    warnings: list[str] = result["warnings"]  # type: ignore[assignment]
    try:
        payload = json.loads(path.read_text())
    except (OSError, json.JSONDecodeError) as exc:
        errors.append(f"unable to read analyzer JSON: {exc}")
        result["valid"] = False
        return result

    security = payload.get("security_evidence", [])
    if not isinstance(security, list):
        errors.append("security_evidence must be an array")
        security = []
    result["security_evidence_count"] = len(security)
    identities: set[tuple[str, str, str, str]] = set()
    for index, record in enumerate(security):
        if not isinstance(record, dict):
            errors.append(f"security evidence {index} is not an object")
            continue
        identity = tuple(
            str(record.get(key, "")) for key in ("kind", "target", "detail", "status")
        )
        if identity in identities:
            errors.append(f"duplicate security evidence identity at index {index}")
        identities.add(identity)
        if record.get("status") not in _STATUSES:
            errors.append(f"security evidence {index} has invalid status")
        sources = record.get("sources") or (
            [record.get("source")] if record.get("source") else []
        )
        if not isinstance(sources, list) or not sources:
            errors.append(f"security evidence {index} has no provenance")

    cross_cutting = payload.get("cross_cutting_evidence", {})
    if not isinstance(cross_cutting, dict):
        errors.append("cross_cutting_evidence must be an object")
        cross_cutting = {}
    result["cross_cutting_count"] = sum(
        len(records) for records in cross_cutting.values() if isinstance(records, list)
    )
    for topic, records in cross_cutting.items():
        if topic not in _TOPICS:
            errors.append(f"unknown cross-cutting topic: {topic}")
        if not isinstance(records, list):
            errors.append(f"cross-cutting topic {topic} must contain an array")
            continue
        for index, record in enumerate(records):
            if not isinstance(record, dict):
                errors.append(
                    f"cross-cutting evidence {topic}[{index}] is not an object"
                )
                continue
            if record.get("status") not in _STATUSES:
                errors.append(
                    f"cross-cutting evidence {topic}[{index}] has invalid status"
                )
            if (
                not record.get("claim")
                or not isinstance(record.get("sources"), list)
                or not record["sources"]
            ):
                errors.append(
                    f"cross-cutting evidence {topic}[{index}] lacks claim or provenance"
                )
    if not cross_cutting:
        warnings.append("no cross-cutting evidence was emitted")
    result["valid"] = not errors
    return result
