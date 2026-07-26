#!/usr/bin/env python3
"""Compare two architecture snapshot directories component-by-component.

Default: architecture/rhoai.next.bak (baseline) vs architecture/rhoai.next
(candidate).  Exits non-zero when configured regression thresholds are
exceeded.

This is a structural/provisional regression report — not human
adjudication.  It detects document-surface and stable-row regressions
only; it does not measure semantic quality.
"""

from __future__ import annotations

import argparse
import sys
from pathlib import Path

PROJECT_ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(PROJECT_ROOT))

from lib.snapshot_regression import (  # noqa: E402
    DEFAULT_BASELINE,
    DEFAULT_CANDIDATE,
    RegressionThresholds,
    check_thresholds,
    compare_snapshots,
    format_snapshot_report,
)


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description=(
            "Deterministic bulk comparison of architecture snapshot directories. "
            "Pairs same-named component Markdown files, reports missing/additional "
            "components, required-section loss, structured row recall, and fact "
            "conflicts.  Exits non-zero when thresholds are exceeded."
        ),
    )
    parser.add_argument(
        "--baseline",
        default=str(PROJECT_ROOT / DEFAULT_BASELINE),
        help=f"Baseline architecture root (default: {DEFAULT_BASELINE})",
    )
    parser.add_argument(
        "--candidate",
        default=str(PROJECT_ROOT / DEFAULT_CANDIDATE),
        help=f"Candidate architecture root (default: {DEFAULT_CANDIDATE})",
    )
    parser.add_argument(
        "--format",
        choices=("text", "json", "both"),
        default="both",
        help="Output format (default: both — text to stderr, JSON to stdout)",
    )
    parser.add_argument(
        "--min-row-recall",
        type=float,
        default=0.0,
        help="Fail when aggregate row recall is below this value",
    )
    parser.add_argument(
        "--min-structured-recall",
        type=float,
        default=0.0,
        help="Fail when aggregate structured row recall is below this value",
    )
    parser.add_argument(
        "--max-missing-components",
        type=int,
        default=None,
        help="Fail when more than this many baseline components are absent",
    )
    parser.add_argument(
        "--fail-on-conflicts",
        action="store_true",
        help="Fail when any source-backed cell conflicts exist",
    )
    return parser.parse_args()


def main() -> int:
    args = parse_args()

    report = compare_snapshots(args.baseline, args.candidate)

    if args.format in ("text", "both"):
        output = sys.stderr if args.format == "both" else sys.stdout
        print(format_snapshot_report(report), end="", file=output)

    if args.format in ("json", "both"):
        print(report.to_json())

    thresholds = RegressionThresholds(
        min_row_recall=args.min_row_recall,
        min_structured_recall=args.min_structured_recall,
        max_missing_components=args.max_missing_components,
        fail_on_conflicts=args.fail_on_conflicts,
    )
    violations = check_thresholds(report, thresholds)
    if violations:
        print("\nThreshold violations:", file=sys.stderr)
        for violation in violations:
            print(f"  - {violation}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
