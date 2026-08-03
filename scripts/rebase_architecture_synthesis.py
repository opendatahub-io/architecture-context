#!/usr/bin/env python3
"""Rebase or evidence-gate agent synthesis onto analyzer Markdown."""

from __future__ import annotations

import argparse
import sys
from pathlib import Path

PROJECT_ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(PROJECT_ROOT))

from lib.arch_doc import assemble_architecture_sections  # noqa: E402
from lib.architecture_merge import (  # noqa: E402
    merge_architecture_files,
    rebase_synthesis,
    split_h2_sections,
)

__all__ = ["rebase_synthesis", "split_h2_sections"]


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("analyzer", type=Path)
    parser.add_argument("synthesis", type=Path)
    parser.add_argument("output", type=Path)
    parser.add_argument("--changes", type=Path)
    parser.add_argument("--report-json", type=Path)
    parser.add_argument("--report-markdown", type=Path)
    parser.add_argument("--component")
    parser.add_argument(
        "--evidence-gated",
        action="store_true",
        help="Apply only evidence-backed structured candidate changes",
    )
    parser.add_argument("--generated-by", required=True)
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    if args.evidence_gated:
        merge_architecture_files(
            args.analyzer,
            args.synthesis,
            args.output,
            changes=args.changes,
            report_json=args.report_json,
            report_markdown=args.report_markdown,
            generated_by=args.generated_by,
            component=args.component,
            section_assembler=assemble_architecture_sections,
        )
    else:
        output = rebase_synthesis(
            args.analyzer.read_text(),
            args.synthesis.read_text(),
            generated_by=args.generated_by,
        )
        args.output.write_text(output)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
