#!/usr/bin/env python3
"""Classify sufficient corpus components for analyzer-only generation."""

from __future__ import annotations

import argparse
import heapq
import json
import re
import sys
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

PROJECT_ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(PROJECT_ROOT))

from lib.architecture_baseline import (  # noqa: E402
    NON_ARCHITECTURE_CATEGORIES,
    SYNTHESIS_SECTIONS,
    _normalize_row_key,
    parse_component_markdown,
)
from lib.architecture_merge import (  # noqa: E402
    _document_table_rows,
    _rows_by_category,
)
from lib.architecture_routing import (  # noqa: E402
    _baseline_inventory,
    _complete_empty_categories,
    analyzer_only_eligibility,
    load_analyzer_only_approvals,
    load_source_audited_empty_categories,
)

WORD_RE = re.compile(r"\b[\w][\w'-]*\b")
CORRECTION_ADJUDICATIONS_PATH = (
    PROJECT_ROOT / "lib" / "analyzer_correction_adjudications.json"
)


def _read_json(path: Path) -> dict[str, Any]:
    return json.loads(path.read_text())


def _synthesis_words(path: Path) -> int:
    document = parse_component_markdown(path)
    names = {name.casefold() for name in SYNTHESIS_SECTIONS}
    text = "\n".join(
        value
        for section, value in document.section_text.items()
        if section and section[-1].casefold() in names
    )
    return len(WORD_RE.findall(text))


def _structured_corrections(path: Path) -> list[dict[str, Any]]:
    if not path.is_file():
        return []
    report = _read_json(path)
    decisions = report.get("decisions", [])
    return [
        decision
        for decision in decisions
        if isinstance(decision, dict)
        and decision.get("status") == "applied"
        and decision.get("category") not in NON_ARCHITECTURE_CATEGORIES
    ]


def _structured_mutations(path: Path) -> int:
    return len(_structured_corrections(path))


def _correction_resolution(
    merge_path: Path,
    analyzer_markdown_path: Path,
    *,
    adjudications_path: Path = CORRECTION_ADJUDICATIONS_PATH,
) -> tuple[int, int, list[dict[str, Any]]]:
    """Classify accepted architecture corrections against fresh analyzer rows."""

    corrections = _structured_corrections(merge_path)
    document = parse_component_markdown(analyzer_markdown_path)
    rows = _rows_by_category(_document_table_rows(document.tables))
    adjudications = _load_correction_adjudications(adjudications_path)
    component = merge_path.name.removesuffix(".merge.json")
    unresolved = []
    resolved = 0
    for correction in corrections:
        category = str(correction.get("category") or "")
        key = _normalize_row_key(
            category, tuple(str(value) for value in correction.get("key") or ())
        )
        action = str(correction.get("action") or "")
        category_rows = rows.get(category, {})
        present = key in category_rows or _covered_authentication_key(
            category,
            key,
            set(category_rows),
        )
        # Adds and deletes can be adjudicated by normalized row identity alone.
        # Updates remain unresolved until cell-level candidate-value matching is
        # implemented; this is deliberately conservative.
        correction_resolved = (
            (action == "add" and present)
            or (action == "delete" and not present)
            or _accepted_analyzer_absence(
                adjudications,
                component=component,
                category=category,
                key=key,
                action=action,
                present=present,
            )
        )
        if correction_resolved:
            resolved += 1
        else:
            unresolved.append(correction)
    return resolved, len(unresolved), unresolved


def _load_correction_adjudications(path: Path) -> set[tuple[str, str, tuple[str, ...]]]:
    try:
        payload = _read_json(path)
    except (OSError, json.JSONDecodeError):
        return set()
    result = set()
    for entry in payload.get("accepted_analyzer_absences", []):
        if not isinstance(entry, dict):
            continue
        component = str(entry.get("component") or "").strip()
        category = str(entry.get("category") or "").strip()
        key = _normalize_row_key(
            category, tuple(str(value) for value in entry.get("key") or ())
        )
        reason = str(entry.get("reason") or "").strip()
        evidence = entry.get("evidence") or []
        if component and category and key and reason and evidence:
            result.add((component, category, key))
    return result


def _accepted_analyzer_absence(
    adjudications: set[tuple[str, str, tuple[str, ...]]],
    *,
    component: str,
    category: str,
    key: tuple[str, ...],
    action: str,
    present: bool,
) -> bool:
    """Accept a reviewed analyzer correction to a historical agent add."""

    return (
        action == "add" and not present and (component, category, key) in adjudications
    )


def _covered_authentication_key(
    category: str,
    key: tuple[str, ...],
    analyzer_keys: set[tuple[str, ...]],
) -> bool:
    """Recognize precise probe rows that cover a coarser accepted probe row."""

    if category != "authentication" or len(key) != 2 or key[1] != "get":
        return False
    paths = set(re.findall(r"/(?:healthz|readyz)\b", key[0]))
    if not paths:
        return False
    return all(
        any(
            method == "get"
            and (endpoint.endswith(path) or endpoint.startswith(path + " "))
            for endpoint, method in analyzer_keys
        )
        for path in paths
    )


def _scheduled_wall_seconds(
    runs: list[dict[str, Any]],
    workers: int,
    *,
    excluded: set[str] | None = None,
) -> float:
    """Estimate FIFO concurrent wall time from recorded component durations."""

    excluded = excluded or set()
    durations = [
        float(run.get("duration_seconds") or 0)
        for run in sorted(runs, key=lambda item: str(item.get("component", "")))
        if str(run.get("component", "")) not in excluded
    ]
    if not durations:
        return 0.0
    slots = [0.0] * min(max(workers, 1), len(durations))
    heapq.heapify(slots)
    for duration in durations:
        available = heapq.heappop(slots)
        heapq.heappush(slots, available + duration)
    return max(slots)


def classify_run(
    run_dir: str | Path,
    *,
    analyzer_dir: str | Path | None = None,
) -> dict[str, Any]:
    """Classify all sufficient components in one completed corpus run."""

    root = Path(run_dir).resolve()
    logs = root / "logs" / "agents"
    analyzer_root = (
        Path(analyzer_dir).resolve()
        if analyzer_dir is not None
        else root / "analyzer" / "rhoai.next"
    )
    generated_dir = root / "architecture" / "rhoai.next"
    if not logs.is_dir() or not analyzer_root.is_dir() or not generated_dir.is_dir():
        raise ValueError(f"incomplete corpus run: {root}")

    approvals = load_analyzer_only_approvals()
    source_audited_map = load_source_audited_empty_categories()
    all_runs = [_read_json(path) for path in sorted(logs.glob("*.run.json"))]
    components = []
    for run in all_runs:
        component = str(run.get("component") or "")
        if not component:
            raise ValueError("generation run report is missing its component name")
        analyzer_json_path = analyzer_root / f"{component}.json"
        analyzer_markdown_path = analyzer_root / f"{component}.md"
        generated_path = generated_dir / f"{component}.md"
        if not all(
            path.is_file()
            for path in (analyzer_json_path, analyzer_markdown_path, generated_path)
        ):
            raise ValueError(f"missing artifacts for sufficient component {component}")
        analyzer = _read_json(analyzer_json_path)
        readiness_detail = str(
            analyzer.get("data_coverage", {}).get("agent_baseline", "")
        )
        readiness = readiness_detail.split(":", 1)[0].strip().casefold()
        if readiness != "sufficient":
            continue
        _, empty_categories = _baseline_inventory(analyzer_markdown_path)
        source_audited = source_audited_map.get(component, frozenset())
        candidate, reason = analyzer_only_eligibility(
            readiness,
            analyzer,
            empty_categories,
            source_audited=source_audited,
        )
        merge_path = logs / f"{component}.merge.json"
        mutations = _structured_mutations(merge_path)
        resolved, unresolved, unresolved_details = _correction_resolution(
            merge_path,
            analyzer_markdown_path,
        )
        approved = component in approvals
        eligible = candidate and approved
        if candidate and not approved:
            reason += "; awaiting corpus-validated rollout approval"
        complete_empty = _complete_empty_categories(analyzer, empty_categories)
        telemetry = run.get("telemetry", {})
        usage = telemetry.get("usage", {})
        components.append(
            {
                "component": component,
                "analyzer_only_candidate": candidate,
                "analyzer_only_approved": approved,
                "eligible": eligible,
                "eligibility_reason": reason,
                "empty_high_value_categories": sorted(
                    set(empty_categories)
                    & {
                        "architecture_components",
                        "authentication",
                        "integration_points",
                        "internal_dependencies",
                    }
                ),
                "contract_complete_empty_categories": list(complete_empty),
                "structured_mutations": mutations,
                "resolved_structured_mutations": resolved,
                "unresolved_structured_mutations": unresolved,
                "unresolved_corrections": unresolved_details,
                "synthesis_words": _synthesis_words(generated_path),
                "read_calls": int(telemetry.get("read_calls") or 0),
                "source_file_count": int(telemetry.get("source_file_count") or 0),
                "duration_seconds": float(run.get("duration_seconds") or 0),
                "input_tokens": int(usage.get("input_tokens") or 0),
                "cache_creation_input_tokens": int(
                    usage.get("cache_creation_input_tokens") or 0
                ),
                "cache_read_input_tokens": int(
                    usage.get("cache_read_input_tokens") or 0
                ),
                "output_tokens": int(usage.get("output_tokens") or 0),
                "cost_usd": float(telemetry.get("total_cost_usd") or 0),
            }
        )

    eligible = [component for component in components if component["eligible"]]
    zero_mutation = [
        component for component in components if component["structured_mutations"] == 0
    ]
    zero_unresolved = [
        component
        for component in components
        if component["unresolved_structured_mutations"] == 0
    ]
    false_nominations = [
        component["component"]
        for component in eligible
        if component["unresolved_structured_mutations"] > 0
    ]
    true_nominations = [
        component["component"]
        for component in eligible
        if component["unresolved_structured_mutations"] == 0
    ]
    savings_fields = (
        "read_calls",
        "source_file_count",
        "duration_seconds",
        "input_tokens",
        "cache_creation_input_tokens",
        "cache_read_input_tokens",
        "output_tokens",
        "cost_usd",
    )
    projected_savings = {
        field: sum(component[field] for component in eligible)
        for field in savings_fields
    }
    projected_savings["agent_invocations"] = len(eligible)
    manifest = _read_json(root / "run.json")
    workers = int(manifest.get("workers") or 1)
    eligible_names = {component["component"] for component in eligible}
    estimated_wall_before = _scheduled_wall_seconds(all_runs, workers)
    estimated_wall_after = _scheduled_wall_seconds(
        all_runs,
        workers,
        excluded=eligible_names,
    )
    projected_savings.update(
        {
            "workers": workers,
            "estimated_agent_wall_seconds_before": estimated_wall_before,
            "estimated_agent_wall_seconds_after": estimated_wall_after,
            "estimated_agent_wall_seconds_avoided": (
                estimated_wall_before - estimated_wall_after
            ),
            "estimated_agent_wall_reduction": (
                (estimated_wall_before - estimated_wall_after) / estimated_wall_before
                if estimated_wall_before
                else 0
            ),
        }
    )

    return {
        "schema_version": 1,
        "generated_at": datetime.now(timezone.utc).isoformat(),
        "run_dir": str(root),
        "analyzer_dir": str(analyzer_root),
        "policy": (
            "readiness is sufficient, all four high-value structured categories "
            "are populated or contract-complete empty, and no bounded correction "
            "category is nominated"
        ),
        "summary": {
            "sufficient_components": len(components),
            "zero_mutation_components": len(zero_mutation),
            "zero_unresolved_correction_components": len(zero_unresolved),
            "eligible_components": len(eligible),
            "true_nominations": len(true_nominations),
            "false_nominations": len(false_nominations),
            "zero_mutation_recall": (
                len(true_nominations) / len(zero_unresolved) if zero_unresolved else 0
            ),
            "projected_savings": projected_savings,
        },
        "false_nominations": false_nominations,
        "components": components,
    }


def format_report(report: dict[str, Any]) -> str:
    """Render a reviewable Markdown eligibility report."""

    summary = report["summary"]
    savings = summary["projected_savings"]
    lines = [
        "# Analyzer-Only Eligibility Classification",
        "",
        "## Summary",
        "",
        "| Measure | Result |",
        "|---------|-------:|",
        f"| Sufficient components | {summary['sufficient_components']} |",
        (
            "| Zero structured-mutation components | "
            f"{summary['zero_mutation_components']} |"
        ),
        (
            "| Zero unresolved-correction components | "
            f"{summary['zero_unresolved_correction_components']} |"
        ),
        f"| Analyzer-only nominations | {summary['eligible_components']} |",
        f"| False nominations | {summary['false_nominations']} |",
        f"| Zero-mutation recall | {summary['zero_mutation_recall']:.2%} |",
        f"| Projected agent invocations avoided | {savings['agent_invocations']} |",
        f"| Historical cost avoided | ${savings['cost_usd']:.4f} |",
        (
            "| Historical summed agent time avoided | "
            f"{savings['duration_seconds']:.2f}s |"
        ),
        f"| Historical reads avoided | {savings['read_calls']} |",
        f"| Historical source files avoided | {savings['source_file_count']} |",
        f"| Historical output tokens avoided | {int(savings['output_tokens']):,} |",
        (
            f"| Estimated {savings['workers']}-worker agent wall reduction | "
            f"{savings['estimated_agent_wall_seconds_avoided']:.2f}s "
            f"({savings['estimated_agent_wall_reduction']:.2%}) |"
        ),
        "",
        "Policy: " + report["policy"] + ".",
        "",
        "## Components",
        "",
        (
            "| Component | Candidate | Approved | Eligible | "
            "Corrections (resolved/total) | Synthesis words | Reads | "
            "Source files | Agent time | Output tokens | Cost |"
        ),
        (
            "|-----------|-----------|----------|----------|-----------------------------:|----------------:|------:|"
            "-------------:|-----------:|--------------:|-----:|"
        ),
    ]
    for component in report["components"]:
        lines.append(
            f"| {component['component']} | "
            f"{'yes' if component['analyzer_only_candidate'] else 'no'} | "
            f"{'yes' if component['analyzer_only_approved'] else 'no'} | "
            f"{'yes' if component['eligible'] else 'no'} | "
            f"{component['resolved_structured_mutations']}/"
            f"{component['structured_mutations']} | "
            f"{component['synthesis_words']} | "
            f"{component['read_calls']} | "
            f"{component['source_file_count']} | "
            f"{component['duration_seconds']:.2f}s | "
            f"{component['output_tokens']} | "
            f"${component['cost_usd']:.4f} |"
        )
    lines.extend(
        [
            "",
            (
                "Historical savings are projections from the accepted run, not a "
                "wall-time claim. The bounded treatment matrix measures actual "
                "workflow behavior."
            ),
            "",
        ]
    )
    return "\n".join(lines)


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("run_dir")
    parser.add_argument(
        "--analyzer-dir",
        help="Optional fresh analyzer snapshot evaluated against the reference run",
    )
    parser.add_argument("--output-json")
    parser.add_argument("--output-markdown")
    args = parser.parse_args()

    try:
        report = classify_run(args.run_dir, analyzer_dir=args.analyzer_dir)
    except (OSError, ValueError, json.JSONDecodeError) as error:
        print(f"ERROR: {error}", file=sys.stderr)
        return 2
    markdown = format_report(report)
    if args.output_json:
        path = Path(args.output_json)
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(json.dumps(report, indent=2, sort_keys=True) + "\n")
    if args.output_markdown:
        path = Path(args.output_markdown)
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(markdown)
    print(markdown)
    return 1 if report["false_nominations"] else 0


if __name__ == "__main__":
    raise SystemExit(main())
