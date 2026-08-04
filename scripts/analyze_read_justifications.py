#!/usr/bin/env python3
"""Summarize source-read justification sidecars without exposing transcripts."""

from __future__ import annotations

import argparse
import json
from collections import Counter
from pathlib import Path


def _line_count(value: object) -> int:
    if not isinstance(value, str):
        return 0
    try:
        if "-" in value:
            start, end = (int(part) for part in value.split("-", 1))
            return max(0, end - start + 1)
        return 1 if value.isdigit() else 0
    except ValueError:
        return 0


def summarize(root: Path) -> str:
    records: list[dict] = []
    for sidecar in sorted(root.glob("*/.generation/SOURCE_READ_JUSTIFICATIONS.json")):
        payload = json.loads(sidecar.read_text())
        component = sidecar.parent.parent.name
        for record in payload.get("reads", []):
            categories = record.get("gap_category", [])
            if isinstance(categories, str):
                categories = [
                    item.strip() for item in categories.split(",") if item.strip()
                ]
            records.append({**record, "component": component, "categories": categories})

    outcomes = Counter(record.get("outcome", "unknown") for record in records)
    categories = Counter(
        category for record in records for category in record["categories"]
    )
    oversized = sorted(
        records, key=lambda record: _line_count(record.get("line_range")), reverse=True
    )
    low_value = [record for record in records if record.get("outcome") != "resolved"]

    lines = [
        "# Analyzer Source-Read Justification Baseline",
        "",
        f"- Sidecar root: `{root}`",
        f"- Components: {len({record['component'] for record in records})}",
        f"- Justification records: {len(records)}",
        "",
        "## Outcomes",
        "",
    ]
    lines.extend(f"- `{key}`: {value}" for key, value in outcomes.most_common())
    lines.extend(["", "## Categories", ""])
    lines.extend(f"- `{key}`: {value}" for key, value in categories.most_common())
    lines.extend(["", "## Largest Read Ranges", ""])
    for record in oversized[:20]:
        lines.append(
            f"- `{record['component']}` `{record.get('path')}` "
            f"({record.get('line_range', 'unknown')}, "
            f"{_line_count(record.get('line_range'))} lines) — "
            f"{', '.join(record['categories'])}"
        )
    lines.extend(["", "## Non-Resolved Reads", ""])
    for record in low_value:
        lines.append(
            f"- `{record['component']}` `{record.get('path')}` "
            f"— `{record.get('outcome')}`, {', '.join(record['categories'])}"
        )
    return "\n".join(lines) + "\n"


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("root", type=Path)
    args = parser.parse_args()
    print(summarize(args.root), end="")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
