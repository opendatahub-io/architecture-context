#!/usr/bin/env python3
"""Validate overlay files against the format spec in overlays/README.md."""

import re
import sys
from datetime import datetime
from pathlib import Path

import yaml

OVERLAYS_DIR = Path(__file__).resolve().parent.parent / "overlays"

FILENAME_RE = re.compile(r"^\d{4}-[a-z0-9.]+(?:-[a-z0-9.]+)*\.md$")
ID_RE = re.compile(r"^\d{4}$")
URL_RE = re.compile(r"^https?://")
VALID_STATUSES = {"active", "superseded"}
REQUIRED_SECTIONS = ["Fact", "Impact on Strategies", "Context"]


def parse_frontmatter(text: str):
    if not text.startswith("---"):
        return None, text
    end = text.find("---", 3)
    if end == -1:
        return None, text
    fm_text = text[3:end].strip()
    body = text[end + 3 :].strip()
    try:
        fm = yaml.safe_load(fm_text)
    except yaml.YAMLError:
        return None, text
    return fm, body


def find_sections(body: str) -> dict[str, str]:
    sections: dict[str, str] = {}
    current = None
    lines: list[str] = []
    for line in body.split("\n"):
        if line.startswith("## "):
            if current is not None:
                sections[current] = "\n".join(lines).strip()
            current = line[3:].strip()
            lines = []
        else:
            lines.append(line)
    if current is not None:
        sections[current] = "\n".join(lines).strip()
    return sections


def validate_overlay(path: Path) -> list[str]:
    errors: list[str] = []
    filename = path.name

    if not FILENAME_RE.match(filename):
        errors.append(
            f"filename must match NNNN-kebab-case.md, "
            f"got '{filename}'"
        )

    text = path.read_text()
    fm, body = parse_frontmatter(text)

    if fm is None:
        errors.append("missing or invalid YAML frontmatter")
        return errors

    if not isinstance(fm, dict):
        errors.append("frontmatter is not a YAML mapping")
        return errors

    file_id = filename[:4]
    fm_id = str(fm.get("id", ""))
    if not ID_RE.match(fm_id):
        errors.append(
            f"id must be a zero-padded 4-digit string, "
            f"got '{fm_id}'"
        )
    elif fm_id != file_id:
        errors.append(
            f"id '{fm_id}' does not match "
            f"filename prefix '{file_id}'"
        )

    for field in ("title", "author"):
        val = fm.get(field)
        if not val or not isinstance(val, str):
            errors.append(f"'{field}' is required and must be a string")

    status = fm.get("status")
    if status not in VALID_STATUSES:
        errors.append(
            f"status must be 'active' or 'superseded', "
            f"got '{status}'"
        )

    created = fm.get("created")
    if created is None:
        errors.append("'created' is required")
    else:
        created_str = str(created)
        try:
            datetime.strptime(created_str, "%Y-%m-%d")
        except ValueError:
            errors.append(
                f"created must be YYYY-MM-DD, got '{created_str}'"
            )

    for field in ("affects", "release"):
        val = fm.get(field)
        if not isinstance(val, list) or len(val) == 0:
            errors.append(f"'{field}' must be a non-empty list")

    provenance = fm.get("provenance")
    if not isinstance(provenance, list) or len(provenance) == 0:
        errors.append("'provenance' must be a non-empty list")
    elif not all(URL_RE.match(str(u)) for u in provenance):
        errors.append(
            "all provenance entries must be URLs (http/https)"
        )

    if status == "superseded" and not fm.get("superseded_by"):
        errors.append(
            "status is 'superseded' but "
            "'superseded_by' is not set"
        )

    sections = find_sections(body)
    for section in REQUIRED_SECTIONS:
        if section not in sections:
            errors.append(f"missing required section '## {section}'")
        elif not sections[section]:
            errors.append(f"section '## {section}' is empty")

    return errors


def main() -> int:
    overlay_dir = OVERLAYS_DIR
    if not overlay_dir.is_dir():
        print(f"overlays directory not found: {overlay_dir}")
        return 1

    files = sorted(
        f
        for f in overlay_dir.glob("*.md")
        if f.name != "README.md"
    )

    if not files:
        print("No overlay files found.")
        return 0

    total_errors = 0
    for path in files:
        errors = validate_overlay(path)
        if errors:
            print(f"{path.relative_to(overlay_dir.parent)}:")
            for e in errors:
                print(f"  - {e}")
            total_errors += len(errors)

    if total_errors:
        print(f"\n{total_errors} error(s) in {len(files)} overlay(s)")
        return 1

    print(f"All {len(files)} overlay(s) passed validation.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
