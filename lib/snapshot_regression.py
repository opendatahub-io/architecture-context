"""Deterministic bulk comparison of architecture snapshot directories.

Pairs same-named component Markdown files from a baseline and candidate
root, computes per-component structural comparisons using
architecture_baseline semantics, and aggregates into a machine-readable
report with configurable regression thresholds.

This is a structural regression report only.  Prior snapshots are not
human labels or semantic quality ground truth.  All metrics measure
document-surface and stable-row recall — not semantic equivalence.
"""

from __future__ import annotations

import json
from dataclasses import dataclass, field
from pathlib import Path

from lib.architecture_baseline import (
    ComparisonReport,
    compare_component_documents,
    parse_component_markdown,
)

_SKIP_FILES = frozenset({"PLATFORM.md", "README.md"})

DEFAULT_BASELINE = "architecture/rhoai.next.bak"
DEFAULT_CANDIDATE = "architecture/rhoai.next"


@dataclass(frozen=True)
class RegressionThresholds:
    min_row_recall: float = 0.0
    min_structured_recall: float = 0.0
    max_missing_components: int | None = None
    fail_on_conflicts: bool = False


@dataclass
class ComponentResult:
    component: str
    baseline_path: str
    candidate_path: str
    report: ComparisonReport

    def to_dict(self) -> dict:
        return {
            "component": self.component,
            "baseline_path": self.baseline_path,
            "candidate_path": self.candidate_path,
            **self.report.to_dict(),
        }


@dataclass
class SnapshotRegressionReport:
    baseline_root: str
    candidate_root: str
    baseline_component_count: int
    candidate_component_count: int
    paired_count: int
    missing_components: list[str]
    additional_components: list[str]
    component_results: list[ComponentResult] = field(default_factory=list)

    @property
    def aggregate_baseline_rows(self) -> int:
        return sum(r.report.baseline_rows for r in self.component_results)

    @property
    def aggregate_matched_rows(self) -> int:
        return sum(r.report.matched_rows for r in self.component_results)

    @property
    def aggregate_row_recall(self) -> float:
        total = self.aggregate_baseline_rows
        if total == 0:
            return 1.0
        return self.aggregate_matched_rows / total

    @property
    def aggregate_structured_baseline_rows(self) -> int:
        return sum(r.report.structured_baseline_rows for r in self.component_results)

    @property
    def aggregate_structured_matched_rows(self) -> int:
        return sum(r.report.structured_matched_rows for r in self.component_results)

    @property
    def aggregate_structured_row_recall(self) -> float:
        total = self.aggregate_structured_baseline_rows
        if total == 0:
            return 1.0
        return self.aggregate_structured_matched_rows / total

    @property
    def aggregate_conflict_count(self) -> int:
        return sum(r.report.conflict_count for r in self.component_results)

    @property
    def aggregate_missing_required_sections(self) -> int:
        return sum(
            len(r.report.missing_required_sections) for r in self.component_results
        )

    def to_dict(self) -> dict:
        return {
            "meta": {
                "type": "snapshot_regression_report",
                "version": "1.0.0",
                "adjudication": "structural/provisional — not human adjudication",
            },
            "baseline_root": self.baseline_root,
            "candidate_root": self.candidate_root,
            "baseline_component_count": self.baseline_component_count,
            "candidate_component_count": self.candidate_component_count,
            "paired_count": self.paired_count,
            "missing_components": self.missing_components,
            "additional_components": self.additional_components,
            "aggregate": {
                "baseline_rows": self.aggregate_baseline_rows,
                "matched_rows": self.aggregate_matched_rows,
                "row_recall": self.aggregate_row_recall,
                "structured_baseline_rows": self.aggregate_structured_baseline_rows,
                "structured_matched_rows": self.aggregate_structured_matched_rows,
                "structured_row_recall": self.aggregate_structured_row_recall,
                "conflict_count": self.aggregate_conflict_count,
                "missing_required_sections": self.aggregate_missing_required_sections,
            },
            "components": [r.to_dict() for r in self.component_results],
        }

    def to_json(self) -> str:
        return json.dumps(self.to_dict(), indent=2)


def _component_md_files(root: Path) -> dict[str, Path]:
    """Return {filename: path} for component Markdown files in *root*."""
    result: dict[str, Path] = {}
    if not root.is_dir():
        return result
    for path in sorted(root.iterdir()):
        if path.suffix == ".md" and path.name not in _SKIP_FILES:
            result[path.name] = path
    return result


def compare_snapshots(
    baseline_root: str | Path,
    candidate_root: str | Path,
) -> SnapshotRegressionReport:
    """Compare all paired component Markdown between two architecture trees."""
    baseline_root = Path(baseline_root)
    candidate_root = Path(candidate_root)

    baseline_files = _component_md_files(baseline_root)
    candidate_files = _component_md_files(candidate_root)

    baseline_names = set(baseline_files)
    candidate_names = set(candidate_files)
    paired_names = sorted(baseline_names & candidate_names)
    missing = sorted(baseline_names - candidate_names)
    additional = sorted(candidate_names - baseline_names)

    results: list[ComponentResult] = []
    for name in paired_names:
        baseline_doc = parse_component_markdown(baseline_files[name])
        candidate_doc = parse_component_markdown(candidate_files[name])
        report = compare_component_documents(baseline_doc, candidate_doc)
        results.append(
            ComponentResult(
                component=name,
                baseline_path=str(baseline_files[name]),
                candidate_path=str(candidate_files[name]),
                report=report,
            )
        )

    return SnapshotRegressionReport(
        baseline_root=str(baseline_root),
        candidate_root=str(candidate_root),
        baseline_component_count=len(baseline_files),
        candidate_component_count=len(candidate_files),
        paired_count=len(paired_names),
        missing_components=missing,
        additional_components=additional,
        component_results=results,
    )


def check_thresholds(
    report: SnapshotRegressionReport,
    thresholds: RegressionThresholds,
) -> list[str]:
    """Return a list of threshold violations (empty if all pass)."""
    violations: list[str] = []

    if report.aggregate_row_recall < thresholds.min_row_recall:
        violations.append(
            f"row_recall {report.aggregate_row_recall:.4f} "
            f"< threshold {thresholds.min_row_recall}"
        )

    if report.aggregate_structured_row_recall < thresholds.min_structured_recall:
        violations.append(
            f"structured_row_recall {report.aggregate_structured_row_recall:.4f} "
            f"< threshold {thresholds.min_structured_recall}"
        )

    if (
        thresholds.max_missing_components is not None
        and len(report.missing_components) > thresholds.max_missing_components
    ):
        violations.append(
            f"missing_components {len(report.missing_components)} "
            f"> threshold {thresholds.max_missing_components}"
        )

    if thresholds.fail_on_conflicts and report.aggregate_conflict_count > 0:
        violations.append(
            f"conflict_count {report.aggregate_conflict_count} > 0"
        )

    return violations


def format_snapshot_report(report: SnapshotRegressionReport) -> str:
    """Render a human-readable snapshot regression summary."""
    lines = [
        "Snapshot regression report (structural/provisional — not human adjudication)",
        "",
        f"Baseline:  {report.baseline_root}",
        f"Candidate: {report.candidate_root}",
        "",
        f"Baseline components:   {report.baseline_component_count}",
        f"Candidate components:  {report.candidate_component_count}",
        f"Paired components:     {report.paired_count}",
        f"Missing components:    {len(report.missing_components)}",
        f"Additional components: {len(report.additional_components)}",
        "",
        f"Aggregate row recall:        "
        f"{report.aggregate_matched_rows}/{report.aggregate_baseline_rows} "
        f"({report.aggregate_row_recall:.1%})",
        f"Aggregate structured recall: "
        f"{report.aggregate_structured_matched_rows}/"
        f"{report.aggregate_structured_baseline_rows} "
        f"({report.aggregate_structured_row_recall:.1%})",
        f"Aggregate conflicts:         {report.aggregate_conflict_count}",
        f"Missing required sections:   {report.aggregate_missing_required_sections}",
    ]

    if report.missing_components:
        lines.extend(["", "Missing components (in baseline, not in candidate):"])
        for name in report.missing_components:
            lines.append(f"  - {name}")

    if report.additional_components:
        lines.extend(["", "Additional components (in candidate, not in baseline):"])
        for name in report.additional_components:
            lines.append(f"  + {name}")

    components_with_regressions = [
        r
        for r in report.component_results
        if r.report.row_recall < 1.0
        or r.report.conflict_count > 0
        or r.report.missing_required_sections
    ]
    if components_with_regressions:
        lines.extend(["", "Per-component evidence (regressions only):"])
        lines.append(
            "  Component                              "
            "Recall   Conflicts  Missing-Sections"
        )
        lines.append(
            "  ---------------------------------------"
            "-------  ---------  ----------------"
        )
        for r in components_with_regressions:
            recall_str = (
                f"{r.report.matched_rows}/{r.report.baseline_rows}"
                if r.report.baseline_rows
                else "—"
            )
            lines.append(
                f"  {r.component:40s} {recall_str:>7s}  "
                f"{r.report.conflict_count:9d}  "
                f"{len(r.report.missing_required_sections):16d}"
            )

    return "\n".join(lines) + "\n"
