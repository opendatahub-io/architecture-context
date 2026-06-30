#!/usr/bin/env python3
"""Validate generated component architecture Markdown files under architecture/."""

import sys
from pathlib import Path

ARCHITECTURE_DIR = Path(__file__).resolve().parent.parent / "architecture"

SKIP_NAMES = {"PLATFORM.md", "README.md"}

REQUIRED_SECTIONS = [
    "Metadata",
    "Purpose",
    "Architecture Components",
    "APIs Exposed",
    "Dependencies",
    "Network Architecture",
    "Security",
    "Data Flows",
    "Integration Points",
    "Recent Changes",
]


def find_sections(text: str) -> set[str]:
    sections: set[str] = set()
    for line in text.splitlines():
        if line.startswith("## "):
            sections.add(line[3:].strip())
    return sections


def validate_component_doc(path: Path) -> list[str]:
    errors: list[str] = []
    sections = find_sections(path.read_text())
    for section in REQUIRED_SECTIONS:
        if section not in sections:
            errors.append(f"missing required section: ## {section}")
    return errors


def main() -> int:
    arch_dir = ARCHITECTURE_DIR
    if not arch_dir.is_dir():
        print(f"architecture directory not found: {arch_dir}")
        return 1

    seen: set[Path] = set()
    files: list[Path] = []
    for path in sorted(arch_dir.glob("*/*.md")):
        real = path.resolve()
        if real in seen:
            continue
        seen.add(real)
        if path.name in SKIP_NAMES:
            continue
        files.append(path)

    if not files:
        print("No component architecture files found.")
        return 0

    total_errors = 0
    for path in files:
        for error in validate_component_doc(path):
            print(f"{path.relative_to(arch_dir.parent)}: {error}")
            total_errors += 1

    if total_errors:
        print(f"\n{total_errors} error(s) found in {len(files)} file(s)")
        return 1

    print(f"All {len(files)} component architecture file(s) passed validation.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
