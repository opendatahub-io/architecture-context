"""Focused tests for lib/snapshot_regression bulk comparison."""

import json
import sys
from pathlib import Path

import pytest

PROJECT_ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(PROJECT_ROOT))

from lib.snapshot_regression import (  # noqa: E402
    RegressionThresholds,
    check_thresholds,
    compare_snapshots,
    format_snapshot_report,
)

_COMPONENT_TEMPLATE = """\
# Component: {name}

## Metadata
| Field | Value |
|-------|-------|
| Component | {name} |

## Purpose
Test component.

## Architecture Components
| Component | Type | Purpose |
|-----------|------|---------|
| main | service | Core |
{extra_row}

## APIs Exposed
### HTTP Endpoints
| Method | Path | Port | Protocol | Encryption | Auth |
|--------|------|------|----------|------------|------|
| GET | /healthz | 8080 | HTTP | None | None |

## Dependencies
### External Dependencies
| Component | Version | Required |
|-----------|---------|----------|
| kubernetes | 1.28+ | Yes |

### Internal Platform Dependencies
| Component | Interaction Type |
|-----------|-----------------|
| operator | REST API |

## Network Architecture
### Services
| Service Name | Type | Port | Protocol |
|--------------|------|------|----------|
| {name}-svc | ClusterIP | 8080 | TCP |

## Security
### RBAC - Cluster Roles
| Role Name | API Group | Resources | Verbs |
|-----------|-----------|-----------|-------|
| manager | apps | deployments | get, list |

## Data Flows
Data flows here.

## Integration Points
| Component | Interaction Type | Port | Protocol | Encryption |
|-----------|-----------------|------|----------|------------|
| operator | gRPC | 9090 | HTTP/2 | mTLS |

## Recent Changes
| Version | Date |
|---------|------|
| v1.0 | 2026-01-01 |

## Source References
### Files Analyzed
| File | Lines |
|------|-------|
| main.go | 1-100 |
"""


def _write_component(root: Path, name: str, *, extra_row: str = "") -> None:
    root.mkdir(parents=True, exist_ok=True)
    (root / f"{name}.md").write_text(
        _COMPONENT_TEMPLATE.format(name=name, extra_row=extra_row)
    )


def test_identical_trees_have_perfect_recall(tmp_path):
    baseline = tmp_path / "baseline"
    candidate = tmp_path / "candidate"
    for name in ["alpha", "beta", "gamma"]:
        _write_component(baseline, name)
        _write_component(candidate, name)

    report = compare_snapshots(baseline, candidate)

    assert report.baseline_component_count == 3
    assert report.candidate_component_count == 3
    assert report.paired_count == 3
    assert report.missing_components == []
    assert report.additional_components == []
    assert report.aggregate_row_recall == 1.0
    assert report.aggregate_structured_row_recall == 1.0
    assert report.aggregate_conflict_count == 0


def test_missing_components_detected(tmp_path):
    baseline = tmp_path / "baseline"
    candidate = tmp_path / "candidate"
    for name in ["alpha", "beta", "gamma"]:
        _write_component(baseline, name)
    _write_component(candidate, "alpha")
    _write_component(candidate, "gamma")

    report = compare_snapshots(baseline, candidate)

    assert report.missing_components == ["beta.md"]
    assert report.additional_components == []
    assert report.paired_count == 2
    assert report.baseline_component_count == 3
    assert report.candidate_component_count == 2


def test_additional_components_detected(tmp_path):
    baseline = tmp_path / "baseline"
    candidate = tmp_path / "candidate"
    _write_component(baseline, "alpha")
    _write_component(candidate, "alpha")
    _write_component(candidate, "delta")

    report = compare_snapshots(baseline, candidate)

    assert report.missing_components == []
    assert report.additional_components == ["delta.md"]
    assert report.paired_count == 1


def test_conflicts_detected_in_paired_components(tmp_path):
    baseline = tmp_path / "baseline"
    candidate = tmp_path / "candidate"
    _write_component(baseline, "alpha")
    _write_component(
        candidate,
        "alpha",
        extra_row="| extra | controller | Added |",
    )

    report = compare_snapshots(baseline, candidate)

    assert report.paired_count == 1
    result = report.component_results[0]
    assert result.component == "alpha.md"
    assert result.report.categories[0].additional_keys


def test_deterministic_output_ordering(tmp_path):
    baseline = tmp_path / "baseline"
    candidate = tmp_path / "candidate"
    names = ["zeta", "alpha", "mu", "beta"]
    for name in names:
        _write_component(baseline, name)
        _write_component(candidate, name)

    report = compare_snapshots(baseline, candidate)

    component_order = [r.component for r in report.component_results]
    assert component_order == sorted(component_order)

    data = json.loads(report.to_json())
    json_order = [c["component"] for c in data["components"]]
    assert json_order == sorted(json_order)


def test_skip_files_excluded(tmp_path):
    baseline = tmp_path / "baseline"
    candidate = tmp_path / "candidate"
    baseline.mkdir(parents=True)
    candidate.mkdir(parents=True)
    _write_component(baseline, "alpha")
    _write_component(candidate, "alpha")
    (baseline / "PLATFORM.md").write_text("# Platform\n")
    (candidate / "PLATFORM.md").write_text("# Platform\n")
    (baseline / "README.md").write_text("# README\n")
    (candidate / "README.md").write_text("# README\n")

    report = compare_snapshots(baseline, candidate)

    assert report.baseline_component_count == 1
    assert report.candidate_component_count == 1
    assert report.paired_count == 1


def test_json_output_contains_meta_marker(tmp_path):
    baseline = tmp_path / "baseline"
    candidate = tmp_path / "candidate"
    _write_component(baseline, "alpha")
    _write_component(candidate, "alpha")

    report = compare_snapshots(baseline, candidate)
    data = json.loads(report.to_json())

    assert data["meta"]["type"] == "snapshot_regression_report"
    assert "provisional" in data["meta"]["adjudication"]
    assert "not human" in data["meta"]["adjudication"]


def test_text_output_contains_provisional_marker(tmp_path):
    baseline = tmp_path / "baseline"
    candidate = tmp_path / "candidate"
    _write_component(baseline, "alpha")
    _write_component(candidate, "alpha")

    report = compare_snapshots(baseline, candidate)
    text = format_snapshot_report(report)

    assert "provisional" in text.lower()
    assert "not human adjudication" in text.lower()


def test_threshold_violations_row_recall(tmp_path):
    baseline = tmp_path / "baseline"
    candidate = tmp_path / "candidate"
    _write_component(baseline, "alpha")
    candidate.mkdir(parents=True)
    (candidate / "alpha.md").write_text("# Component: alpha\n\n## Purpose\nMinimal.\n")

    report = compare_snapshots(baseline, candidate)
    thresholds = RegressionThresholds(min_row_recall=0.5)
    violations = check_thresholds(report, thresholds)

    assert any("row_recall" in v for v in violations)


def test_threshold_violations_missing_components(tmp_path):
    baseline = tmp_path / "baseline"
    candidate = tmp_path / "candidate"
    _write_component(baseline, "alpha")
    _write_component(baseline, "beta")
    candidate.mkdir(parents=True)

    report = compare_snapshots(baseline, candidate)
    thresholds = RegressionThresholds(max_missing_components=1)
    violations = check_thresholds(report, thresholds)

    assert any("missing_components" in v for v in violations)


def test_threshold_passes_when_within_bounds(tmp_path):
    baseline = tmp_path / "baseline"
    candidate = tmp_path / "candidate"
    _write_component(baseline, "alpha")
    _write_component(candidate, "alpha")

    report = compare_snapshots(baseline, candidate)
    thresholds = RegressionThresholds(
        min_row_recall=0.5,
        min_structured_recall=0.5,
        max_missing_components=0,
        fail_on_conflicts=True,
    )
    violations = check_thresholds(report, thresholds)

    assert violations == []


def test_empty_directories_produce_clean_report(tmp_path):
    baseline = tmp_path / "baseline"
    candidate = tmp_path / "candidate"
    baseline.mkdir()
    candidate.mkdir()

    report = compare_snapshots(baseline, candidate)

    assert report.baseline_component_count == 0
    assert report.candidate_component_count == 0
    assert report.paired_count == 0
    assert report.aggregate_row_recall == 1.0


def test_default_snapshot_roots_exist():
    baseline = PROJECT_ROOT / "architecture" / "rhoai.next.bak"
    candidate = PROJECT_ROOT / "architecture" / "rhoai.next"
    if not baseline.is_dir():
        pytest.skip(f"Optional default baseline {baseline} is not present")
    assert baseline.is_dir(), f"Default baseline {baseline} does not exist"
    assert candidate.is_dir(), f"Default candidate {candidate} does not exist"
