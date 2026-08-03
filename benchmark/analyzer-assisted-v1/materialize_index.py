#!/usr/bin/env python3
"""Materialize a deterministic INDEX.md from arch-query index JSON output.

Renders a Markdown artifact with stable ordering, provenance, and format
version that the evaluator can expose for the ``index-md`` condition.

Usage as library:
    from materialize_index import materialize, validate_index_artifact
    md = materialize(index_json, source_revision="abc123")
    errors = validate_index_artifact(md)

Usage as CLI:
    # From arch-query JSON on stdin:
    arch-query index --version rhoai-3.5 -o json | python materialize_index.py \\
        --source-revision abc123 --output architecture/rhoai-3.5/INDEX.md

    # From a saved JSON file:
    python materialize_index.py --input index.json \\
        --source-revision abc123 --output INDEX.md

    # Validate an existing INDEX.md:
    python materialize_index.py --validate INDEX.md
"""

from __future__ import annotations

import argparse
import json
import re
import sys
from pathlib import Path

INDEX_FORMAT_VERSION = "1"

_HEADER_RE = re.compile(
    r"^<!-- INDEX\.md format_version=(\S+)"
    r" arch_query_format_version=(\S+)"
    r" version=(\S+)"
    r" source_revision=(\S+)"
    r" component_count=(\d+) -->$",
)


class MaterializeError(Exception):
    """Raised when materialization inputs are missing or incompatible."""


def materialize(
    index_json: dict,
    *,
    source_revision: str,
) -> str:
    """Render a deterministic INDEX.md from arch-query index JSON.

    Parameters
    ----------
    index_json:
        Parsed output of ``arch-query index --output json``.
    source_revision:
        Git SHA or identifier of the architecture data used to generate
        the index.  Recorded in the provenance header.

    Returns
    -------
    str
        The rendered INDEX.md content with a machine-readable provenance
        header.

    Raises
    ------
    MaterializeError
        If required fields are missing or the input format is incompatible.
    """
    if not isinstance(index_json, dict):
        raise MaterializeError(
            f"Expected dict from arch-query index JSON, got {type(index_json).__name__}"
        )

    format_version = index_json.get("format_version")
    if not format_version:
        raise MaterializeError(
            "Missing 'format_version' in arch-query index JSON"
        )

    version = index_json.get("version")
    if not version:
        raise MaterializeError(
            "Missing 'version' in arch-query index JSON"
        )

    components = index_json.get("components")
    if components is None:
        raise MaterializeError(
            "Missing 'components' in arch-query index JSON"
        )
    if not isinstance(components, list):
        raise MaterializeError(
            f"'components' must be a list, got {type(components).__name__}"
        )

    if not source_revision or not source_revision.strip():
        raise MaterializeError("source_revision must be non-empty")

    category_mappings = index_json.get("category_mappings", {})

    lines: list[str] = []

    lines.append(
        f"<!-- INDEX.md format_version={INDEX_FORMAT_VERSION}"
        f" arch_query_format_version={format_version}"
        f" version={version}"
        f" source_revision={source_revision}"
        f" component_count={len(components)} -->"
    )
    lines.append("")
    lines.append(f"# Architecture Context Index — {version}")
    lines.append("")
    lines.append(f"**Format version**: {INDEX_FORMAT_VERSION}<br>")
    lines.append(f"**Architecture version**: {version}<br>")
    lines.append(f"**Source revision**: `{source_revision}`<br>")
    lines.append(f"**Components**: {len(components)}<br>")
    lines.append(f"**arch-query format**: v{format_version}")
    lines.append("")

    if category_mappings:
        lines.append("## Category Mappings")
        lines.append("")
        lines.append("| Category | Sections |")
        lines.append("|----------|----------|")
        for cat in sorted(category_mappings.keys()):
            sections = category_mappings[cat]
            section_str = ", ".join(sorted(sections)) if sections else "*(field)*"
            lines.append(f"| {cat} | {section_str} |")
        lines.append("")

    lines.append("## Components")
    lines.append("")
    lines.append(
        "| Component | Purpose | Deploy Type | Sections | Source |"
    )
    lines.append(
        "|-----------|---------|-------------|----------|--------|"
    )

    def _comp_key(c):
        return (c.get("name", ""), c.get("deploy_type", ""))

    for comp in sorted(components, key=_comp_key):
        name = comp.get("name", "")
        purpose = comp.get("purpose", "")
        deploy_type = comp.get("deploy_type", "")
        sections = comp.get("sections", {})
        source_path = comp.get("source_path", "")

        section_parts = []
        for s in sorted(sections.keys()):
            section_parts.append(f"{s}({sections[s]})")
        section_str = ", ".join(section_parts) if section_parts else "*(empty)*"

        source_str = source_path if source_path else ""

        lines.append(
            f"| {name} | {purpose} | {deploy_type} | {section_str} | {source_str} |"
        )

    lines.append("")
    return "\n".join(lines)


def validate_index_artifact(content: str) -> list[str]:
    """Validate an INDEX.md artifact for schema and provenance.

    Returns a list of error strings.  Empty list means valid.
    """
    errors: list[str] = []

    if not content or not content.strip():
        errors.append("INDEX.md is empty")
        return errors

    first_line = content.split("\n", 1)[0]
    m = _HEADER_RE.match(first_line)
    if not m:
        errors.append(
            "Missing or malformed provenance header "
            "(expected <!-- INDEX.md format_version=... -->)"
        )
        return errors

    fmt_ver = m.group(1)
    aq_fmt_ver = m.group(2)
    version = m.group(3)
    source_rev = m.group(4)
    comp_count_str = m.group(5)

    if fmt_ver != INDEX_FORMAT_VERSION:
        errors.append(
            f"Unsupported format_version '{fmt_ver}' "
            f"(expected '{INDEX_FORMAT_VERSION}')"
        )

    if not aq_fmt_ver:
        errors.append("Missing arch_query_format_version in header")

    if not version:
        errors.append("Missing version in header")

    if not source_rev:
        errors.append("Missing source_revision in header")

    try:
        comp_count = int(comp_count_str)
    except ValueError:
        errors.append(f"Invalid component_count in header: {comp_count_str}")
        return errors

    table_rows = 0
    in_components = False
    for line in content.split("\n"):
        if line.startswith("## Components"):
            in_components = True
            continue
        if in_components and line.startswith("## "):
            in_components = False
        if in_components and line.startswith("|") and not line.startswith("|-"):
            stripped = line.strip()
            if stripped.startswith("| Component"):
                continue
            table_rows += 1

    if table_rows != comp_count:
        errors.append(
            f"Header declares {comp_count} components but table has "
            f"{table_rows} rows"
        )

    return errors


def parse_header(content: str) -> dict | None:
    """Parse the provenance header from an INDEX.md artifact.

    Returns a dict with keys: format_version, arch_query_format_version,
    version, source_revision, component_count.  Returns None if the header
    is missing or malformed.
    """
    if not content:
        return None
    first_line = content.split("\n", 1)[0]
    m = _HEADER_RE.match(first_line)
    if not m:
        return None
    return {
        "format_version": m.group(1),
        "arch_query_format_version": m.group(2),
        "version": m.group(3),
        "source_revision": m.group(4),
        "component_count": int(m.group(5)),
    }


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(
        description="Materialize INDEX.md from arch-query index JSON.",
    )
    parser.add_argument(
        "--input",
        type=Path,
        default=None,
        help="Path to arch-query index JSON file (default: stdin).",
    )
    parser.add_argument(
        "--output",
        type=Path,
        default=None,
        help="Output path for INDEX.md (default: stdout).",
    )
    parser.add_argument(
        "--source-revision",
        type=str,
        default=None,
        help="Git SHA or revision identifier for provenance.",
    )
    parser.add_argument(
        "--validate",
        type=Path,
        default=None,
        help="Validate an existing INDEX.md instead of materializing.",
    )

    args = parser.parse_args(argv)

    if args.validate is not None:
        if not args.validate.exists():
            print(f"File not found: {args.validate}", file=sys.stderr)
            return 1
        content = args.validate.read_text()
        errors = validate_index_artifact(content)
        if errors:
            print(f"FAIL: {len(errors)} error(s):", file=sys.stderr)
            for e in errors:
                print(f"  - {e}", file=sys.stderr)
            return 1
        header = parse_header(content)
        print("PASS: INDEX.md validated")
        if header:
            print(f"  Format version: {header['format_version']}")
            print(f"  Architecture version: {header['version']}")
            print(f"  Source revision: {header['source_revision']}")
            print(f"  Components: {header['component_count']}")
        return 0

    if args.source_revision is None:
        print("error: --source-revision is required", file=sys.stderr)
        return 1

    try:
        if args.input is not None:
            with open(args.input) as f:
                index_json = json.load(f)
        else:
            index_json = json.load(sys.stdin)
    except (json.JSONDecodeError, OSError) as exc:
        print(f"Error reading index JSON: {exc}", file=sys.stderr)
        return 1

    try:
        content = materialize(
            index_json, source_revision=args.source_revision
        )
    except MaterializeError as exc:
        print(f"Materialization error: {exc}", file=sys.stderr)
        return 1

    if args.output is not None:
        args.output.parent.mkdir(parents=True, exist_ok=True)
        args.output.write_text(content)
        print(f"Wrote {args.output}")
    else:
        sys.stdout.write(content)

    return 0


if __name__ == "__main__":
    sys.exit(main())
