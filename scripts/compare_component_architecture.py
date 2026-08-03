#!/usr/bin/env python3
"""Compare candidate component Markdown against an existing baseline."""

from __future__ import annotations

import argparse
import sys
from pathlib import Path

PROJECT_ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(PROJECT_ROOT))

from lib.architecture_baseline import (  # noqa: E402
    compare_component_documents,
    format_comparison_report,
    parse_component_markdown,
)


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description=(
            "Compare stable tables and required sections in candidate component "
            "architecture Markdown against a baseline."
        )
    )
    parser.add_argument("baseline", help="Existing component Markdown baseline")
    parser.add_argument("candidate", help="Candidate generated Markdown")
    parser.add_argument(
        "--format",
        choices=("text", "json"),
        default="text",
        help="Report format (default: text)",
    )
    parser.add_argument(
        "--min-row-recall",
        type=float,
        default=0.0,
        help="Exit 1 when stable row recall is below this value",
    )
    parser.add_argument(
        "--min-structured-recall",
        type=float,
        default=0.0,
        help=(
            "Exit 1 when architecture-table recall, excluding source inventory "
            "and recent history, is below this value"
        ),
    )
    parser.add_argument(
        "--fail-on-conflict",
        action="store_true",
        help="Exit 1 when source-backed cells conflict",
    )
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    baseline = parse_component_markdown(args.baseline)
    candidate = parse_component_markdown(args.candidate)
    report = compare_component_documents(baseline, candidate)

    if args.format == "json":
        print(report.to_json())
    else:
        print(format_comparison_report(report), end="")

    if report.row_recall < args.min_row_recall:
        return 1
    if report.structured_row_recall < args.min_structured_recall:
        return 1
    if args.fail_on_conflict and report.conflict_count:
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
