#!/usr/bin/env python3
"""Extract a redacted demand inventory from partial architecture-agent logs.

The input logs contain model transcripts and source/tool payloads. This script
intentionally emits only metadata, relative source paths, route declarations,
section/category names, and classified errors. It never copies transcript text,
source content, prompts, credentials, or API/OTel payloads to the output.
"""

from __future__ import annotations

import argparse
import json
import re
from collections import Counter
from pathlib import Path

KNOWN_ARTIFACTS = {
    "component-architecture.json",
    "analyzer_architecture.md",
    "GENERATED_ARCHITECTURE.md",
    "ARCHITECTURE_CHANGES.md",
    "INSIGHTS_ARTIFACT.json",
}
SECTIONS = (
    "Purpose",
    "Architecture Components",
    "APIs Exposed",
    "Dependencies",
    "Integration Points",
    "Deployment Manifests",
    "Network Architecture",
    "Security",
    "Data Flows",
    "Architectural Analysis",
)
GAP_CATEGORIES = (
    "architecture_components",
    "authentication",
    "integration_points",
    "internal_dependencies",
    "http_endpoints",
    "grpc_services",
    "services",
    "ingress",
    "egress",
    "crds",
    "rbac_cluster_roles",
    "rbac_role_bindings",
    "secrets",
    "external_dependencies",
)


def _int_match(pattern: str, text: str) -> int | None:
    match = re.search(pattern, text)
    return int(match.group(1)) if match else None


def _float_match(pattern: str, text: str) -> float | None:
    match = re.search(pattern, text)
    return float(match.group(1)) if match else None


def _first(pattern: str, text: str, default: str = "") -> str:
    match = re.search(pattern, text)
    return match.group(1) if match else default


def _relative_source(path: str) -> str | None:
    """Return only a checkout-relative source path, never host path/content."""

    marker = "/data/checkouts/"
    if marker not in path:
        return None
    relative = path.split(marker, 1)[1].split("/", 2)
    if len(relative) != 3:
        return None
    source = relative[2]
    if source in KNOWN_ARTIFACTS or source.endswith(".run.json"):
        return None
    if source.startswith(("/", "tmp/", ".env")):
        return None
    return source


def _tool_counts(text: str) -> dict[str, int]:
    return {
        tool: len(re.findall(rf"name='{re.escape(tool)}'", text))
        for tool in ("Read", "Edit", "Write", "Glob", "Grep", "Bash", "Task")
    }


def _prompt_field(name: str, text: str) -> str:
    return _first(rf"--{name}=([^\s]+)", text)


def _record(log_path: Path, run_path: Path | None) -> dict[str, object]:
    text = log_path.read_text(errors="replace")
    component = log_path.stem
    route = _prompt_field("analysis-route", text) or "unknown"
    readiness = _prompt_field("readiness", text) or "unknown"
    allowed = _prompt_field("allowed-source-files", text)
    allowed_files = allowed.split(",") if allowed else []
    source_paths = sorted(
        {
            source
            for raw in re.findall(r"file_path': '([^']+)", text)
            if (source := _relative_source(raw)) is not None
        }
    )
    gap_categories = [
        category
        for category in GAP_CATEGORIES
        if re.search(
            rf"(?:--gap-categories=|gap_categories[^\n]*?){re.escape(category)}", text
        )
    ]
    sections = {
        section: len(re.findall(re.escape(section), text))
        for section in SECTIONS
        if section in text
    }
    run_error = ""
    run_success: bool | None = None
    merge_counts: dict[str, int] = {}
    if run_path and run_path.is_file():
        try:
            payload = json.loads(run_path.read_text())
            run_success = bool(payload.get("success"))
            merge = payload.get("merge") or {}
            counts = merge.get("counts", {}) if isinstance(merge, dict) else {}
            if isinstance(counts, dict):
                merge_counts = {
                    str(key): int(value)
                    for key, value in counts.items()
                    if isinstance(value, int) and not isinstance(value, bool)
                }
            error = str(payload.get("error") or "")
            if "insight artifact" in error.lower():
                run_error = "insight_artifact_validation"
            elif error:
                run_error = "agent_run_error"
        except (OSError, json.JSONDecodeError):
            run_error = "run_record_unparseable"
    return {
        "component": component,
        "route": route,
        "readiness": readiness,
        "model": _first(r"^Model: ([^\n]+)", text, "unknown"),
        "duration_seconds": round(
            (_int_match(r"duration_ms=(\d+)", text) or 0) / 1000, 3
        ),
        "api_duration_seconds": round(
            (_int_match(r"duration_api_ms=(\d+)", text) or 0) / 1000, 3
        ),
        "turns": _int_match(r"num_turns=(\d+)", text),
        "cost_usd": _float_match(r"total_cost_usd=([0-9.]+)", text),
        "tool_counts": _tool_counts(text),
        "allowed_source_files": allowed_files,
        "source_paths_read": source_paths,
        "source_read_count": len(source_paths),
        "gap_categories": gap_categories,
        "section_mentions": sections,
        "validation_passed": "VALIDATION PASSED" in text,
        "run_success": run_success,
        "merge_counts": merge_counts,
        "run_error_class": run_error,
    }


def _summarize(records: list[dict[str, object]]) -> dict[str, object]:
    route_counts = Counter(str(record["route"]) for record in records)
    readiness_counts = Counter(str(record["readiness"]) for record in records)
    gap_counts = Counter(
        category for record in records for category in record["gap_categories"]
    )
    source_counts = Counter(
        source for record in records for source in record["source_paths_read"]
    )
    section_counts = Counter(
        section
        for record in records
        for section, count in record["section_mentions"].items()
        if count
    )
    tool_totals = Counter()
    for record in records:
        tool_totals.update(record["tool_counts"])
    durations = [
        float(record["duration_seconds"])
        for record in records
        if record["duration_seconds"]
    ]
    return {
        "record_count": len(records),
        "route_counts": dict(sorted(route_counts.items())),
        "readiness_counts": dict(sorted(readiness_counts.items())),
        "validation_passed_count": sum(bool(r["validation_passed"]) for r in records),
        "run_success_count": sum(r["run_success"] is True for r in records),
        "run_error_counts": dict(
            Counter(str(r["run_error_class"]) for r in records if r["run_error_class"])
        ),
        "tool_totals": dict(sorted(tool_totals.items())),
        "gap_category_counts": dict(gap_counts.most_common()),
        "source_path_counts": dict(source_counts.most_common(50)),
        "section_mention_counts": dict(section_counts.most_common()),
        "duration_seconds": {
            "average": round(sum(durations) / len(durations), 3) if durations else None,
            "max": max(durations) if durations else None,
        },
    }


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("log_dir", type=Path)
    parser.add_argument("--output", type=Path, required=True)
    args = parser.parse_args()
    records = []
    for log_path in sorted(args.log_dir.glob("*.log")):
        run_path = log_path.with_suffix(".run.json")
        records.append(_record(log_path, run_path))
    payload = {
        "schema_version": 1,
        "input": {"log_dir": str(args.log_dir), "raw_content_emitted": False},
        "summary": _summarize(records),
        "components": records,
    }
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(json.dumps(payload, indent=2) + "\n")
    print(json.dumps(payload["summary"], indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
