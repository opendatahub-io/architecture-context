import json
import sys
from pathlib import Path

import pytest

PROJECT_ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(PROJECT_ROOT))

from scripts.analyze_analyzer_only_eligibility import (  # noqa: E402
    _correction_resolution,
    _scheduled_wall_seconds,
)
from scripts.compare_architecture_corpus import (  # noqa: E402
    compare_corpus,
    format_corpus_report,
    initialize_run,
    load_merge_artifacts,
    record_phase,
    snapshot_analyzers,
    write_corpus_reports,
)


def architecture_document(
    components: list[tuple[str, str]],
    *,
    include_analysis: bool = True,
    version: str = "v1.0.0-1-gabcdef1",
) -> str:
    rows = "\n".join(
        f"| {name} | {component_type} | Source-backed purpose |"
        for name, component_type in components
    )
    analysis = (
        "\n## Architectural Analysis\n\nSource-backed analysis.\n"
        if include_analysis else ""
    )
    return f"""# Component: example

## Metadata

- **Version**: {version}

## Purpose

Example component.

## Architecture Components

| Component | Type | Purpose |
|-----------|------|---------|
{rows}

## APIs Exposed

No APIs exposed.

## Dependencies

No dependencies.

## Network Architecture

No network surface.

## Security

No security surface.

## Data Flows

No data flows.

## Integration Points

No integration points.

## Recent Changes

| Version | Date | Changes |
|---------|------|---------|
| abcdef1 | 2026-07-17 | Test change |

## Source References

### Files Analyzed

| File | Lines | Sections Informed |
|------|-------|-------------------|
| main.go | 1-10 | Architecture Components |
{analysis}"""


def write_document(
    directory: Path,
    name: str,
    components: list[tuple[str, str]],
    *,
    include_analysis: bool = True,
) -> Path:
    directory.mkdir(parents=True, exist_ok=True)
    path = directory / f"{name}.md"
    path.write_text(
        architecture_document(components, include_analysis=include_analysis)
    )
    return path


def write_analyzer_json(
    directory: Path,
    name: str,
    readiness: str = "sufficient",
) -> None:
    (directory / f"{name}.json").write_text(
        json.dumps(
            {
                "commit_sha": "abcdef1234567890",
                "data_coverage": {
                    "agent_baseline": f"{readiness}: source-backed facts",
                },
            }
        )
    )


def test_compare_corpus_aggregates_fidelity_preservation_and_readiness(
    tmp_path: Path,
):
    baseline = tmp_path / "baseline"
    candidate = tmp_path / "candidate"
    analyzer = tmp_path / "analyzer"
    for name, component in (("alpha", "api"), ("beta", "worker")):
        rows = [(component, "Service")]
        write_document(baseline, name, rows)
        write_document(candidate, name, rows)
        write_document(analyzer, name, rows)
        write_analyzer_json(analyzer, name)

    report = compare_corpus(baseline, candidate, analyzer)

    fixture = report["fixture_comparison"]
    assert fixture["structured_matched_rows"] == 2
    assert fixture["structured_baseline_rows"] == 2
    assert fixture["structured_row_recall"] == 1.0
    assert fixture["median_component_structured_recall"] == 1.0
    assert fixture["non_architecture_categories"]["recent_changes"][
        "baseline_rows"
    ] == 2
    assert fixture["non_architecture_categories"]["source_files"][
        "baseline_rows"
    ] == 2
    assert report["analyzer_preservation"]["passed"] is True
    assert report["readiness"]["counts"] == {"sufficient": 2}
    assert report["structural_validation"]["passed"] is True
    assert report["gates"]["passed"] is True


def test_analyzer_only_projection_uses_fifo_worker_schedule():
    runs = [
        {"component": "alpha", "duration_seconds": 10},
        {"component": "beta", "duration_seconds": 8},
        {"component": "gamma", "duration_seconds": 5},
    ]

    assert _scheduled_wall_seconds(runs, 2) == 13
    assert _scheduled_wall_seconds(runs, 2, excluded={"beta"}) == 10


def test_correction_resolution_accepts_precise_probe_expansion(tmp_path: Path):
    analyzer = tmp_path / "analyzer.md"
    analyzer.write_text(
        """# Component: operator

## Security

### Authentication & Authorization

| Endpoint | Methods | Auth Mechanism | Enforcement Point | Policy |
|----------|---------|----------------|-------------------|--------|
| :8081/healthz | GET | None | N/A | probe |
| :8081/readyz | GET | None | N/A | probe |
| :8080/metrics | GET | None | N/A | metrics |
"""
    )
    merge = tmp_path / "merge.json"
    merge.write_text(
        json.dumps(
            {
                "decisions": [
                    {
                        "status": "applied",
                        "action": "add",
                        "category": "authentication",
                        "key": [
                            "operator health probes (/healthz, /readyz)",
                            "get",
                        ],
                    },
                    {
                        "status": "applied",
                        "action": "add",
                        "category": "authentication",
                        "key": [":8080/metrics", "get"],
                    },
                    {
                        "status": "applied",
                        "action": "add",
                        "category": "authentication",
                        "key": ["Kubernetes API", "REST"],
                    },
                ]
            }
        )
    )

    resolved, unresolved, details = _correction_resolution(merge, analyzer)

    assert resolved == 2
    assert unresolved == 1
    assert details[0]["key"] == ["Kubernetes API", "REST"]


def test_correction_resolution_accepts_reviewed_analyzer_absence(
    tmp_path: Path,
):
    analyzer = tmp_path / "analyzer.md"
    analyzer.write_text(
        """# Component: operator

## Security

### Authentication & Authorization

| Endpoint | Methods | Auth Mechanism | Enforcement Point | Policy |
|----------|---------|----------------|-------------------|--------|
"""
    )
    merge = tmp_path / "operator.merge.json"
    merge.write_text(
        json.dumps(
            {
                "decisions": [
                    {
                        "status": "applied",
                        "action": "add",
                        "category": "authentication",
                        "key": ["orphaned metrics (port 8443)", "get"],
                    }
                ]
            }
        )
    )
    adjudications = tmp_path / "adjudications.json"
    adjudications.write_text(
        json.dumps(
            {
                "accepted_analyzer_absences": [
                    {
                        "component": "operator",
                        "category": "authentication",
                        "key": ["orphaned metrics (port 8443)", "get"],
                        "reason": "No deployed listener targets the retained Service.",
                        "evidence": ["manager.yaml:20-40"],
                    }
                ]
            }
        )
    )

    resolved, unresolved, details = _correction_resolution(
        merge,
        analyzer,
        adjudications_path=adjudications,
    )

    assert resolved == 1
    assert unresolved == 0
    assert details == []


def test_correction_resolution_normalizes_shared_epp_identities(tmp_path: Path):
    merge = tmp_path / "llm-d-router.merge.json"
    analyzer = tmp_path / "llm-d-router.md"
    merge.write_text(
        json.dumps(
            {
                "decisions": [
                    {
                        "status": "applied",
                        "action": "add",
                        "category": "architecture_components",
                        "key": ["epp (endpoint picker process)"],
                    },
                    {
                        "status": "applied",
                        "action": "add",
                        "category": "internal_dependencies",
                        "key": ["gateway api inferencepool"],
                    },
                    {
                        "status": "applied",
                        "action": "add",
                        "category": "internal_dependencies",
                        "key": ["model-serving endpoints (vllm)"],
                    },
                    {
                        "status": "applied",
                        "action": "add",
                        "category": "authentication",
                        "key": ["extproc grpc", "grpc streaming"],
                    },
                ]
            }
        )
    )
    analyzer.write_text(
        """# Component: llm-d-router

## Architecture Components

| Component | Type | Purpose |
|---|---|---|
| Endpoint Picker (EPP) | Go gRPC Service | Runtime endpoint picker |

## Dependencies

### Internal Platform Dependencies

| Component | Interaction Type | Purpose |
|---|---|---|
| gateway-api-inference-extension | Controller watch | Watch InferencePool resources |
| Model-serving endpoints | HTTP metrics scrape | Scrape model server metrics |

## Security

### Authentication & Authorization

| Endpoint | Methods | Auth Mechanism | Enforcement Point | Policy |
|---|---|---|---|---|
| External Processor gRPC | gRPC | None | N/A | No application authentication |
"""
    )

    resolved, unresolved, details = _correction_resolution(merge, analyzer)

    assert resolved == 4
    assert unresolved == 0
    assert details == []


def test_compare_corpus_reports_missing_and_extra_documents(tmp_path: Path):
    baseline = tmp_path / "baseline"
    candidate = tmp_path / "candidate"
    analyzer = tmp_path / "analyzer"
    write_document(baseline, "alpha", [("api", "Service")])
    write_document(baseline, "beta", [("worker", "Service")])
    for name in ("alpha", "gamma"):
        write_document(candidate, name, [(name, "Service")])
        write_document(analyzer, name, [(name, "Service")])
        write_analyzer_json(analyzer, name)

    report = compare_corpus(baseline, candidate, analyzer)

    assert report["fixture_comparison"]["missing_documents"] == ["beta"]
    assert report["fixture_comparison"]["extra_documents"] == ["gamma"]
    assert report["analyzer_preservation"]["passed"] is True
    assert report["gates"]["passed"] is True


def test_compare_corpus_reports_components_below_threshold(tmp_path: Path):
    baseline = tmp_path / "baseline"
    candidate = tmp_path / "candidate"
    analyzer = tmp_path / "analyzer"
    write_document(
        baseline,
        "alpha",
        [("api", "Service"), ("worker", "Service")],
    )
    for directory in (candidate, analyzer):
        write_document(directory, "alpha", [("api", "Service")])
    write_analyzer_json(analyzer, "alpha", "partial")

    report = compare_corpus(
        baseline, candidate, analyzer, component_threshold=0.95,
    )

    fixture = report["fixture_comparison"]
    assert fixture["structured_row_recall"] == 0.5
    assert fixture["components_below_threshold"] == ["alpha"]
    assert "alpha" in format_corpus_report(report)
    assert report["gates"]["passed"] is True


def test_compare_corpus_fails_when_generated_document_loses_analyzer_fact(
    tmp_path: Path,
):
    baseline = tmp_path / "baseline"
    candidate = tmp_path / "candidate"
    analyzer = tmp_path / "analyzer"
    write_document(baseline, "alpha", [("api", "Service")])
    write_document(candidate, "alpha", [("api", "Service")])
    write_document(
        analyzer,
        "alpha",
        [("api", "Service"), ("worker", "Service")],
    )
    write_analyzer_json(analyzer, "alpha")

    report = compare_corpus(baseline, candidate, analyzer)

    preservation = report["analyzer_preservation"]
    assert preservation["structured_row_recall"] == 0.5
    assert preservation["failed_components"] == ["alpha"]
    assert preservation["passed"] is False
    assert report["gates"]["passed"] is False


def test_compare_corpus_fails_on_analyzer_cell_conflict(tmp_path: Path):
    baseline = tmp_path / "baseline"
    candidate = tmp_path / "candidate"
    analyzer = tmp_path / "analyzer"
    write_document(baseline, "alpha", [("api", "Library")])
    write_document(candidate, "alpha", [("api", "Library")])
    write_document(analyzer, "alpha", [("api", "Service")])
    write_analyzer_json(analyzer, "alpha")

    report = compare_corpus(baseline, candidate, analyzer)

    preservation = report["analyzer_preservation"]
    assert preservation["structured_row_recall"] == 1.0
    assert preservation["conflict_count"] == 1
    assert preservation["failed_components"] == ["alpha"]
    assert report["gates"]["passed"] is False


def test_compare_corpus_accepts_exact_evidence_backed_cell_adjudication(
    tmp_path: Path,
):
    baseline = tmp_path / "baseline"
    candidate = tmp_path / "candidate"
    analyzer = tmp_path / "analyzer"
    write_document(baseline, "alpha", [("api", "Library")])
    write_document(candidate, "alpha", [("api", "Library")])
    write_document(analyzer, "alpha", [("api", "Service")])
    write_analyzer_json(analyzer, "alpha")
    adjudications = {
        "accepted_conflicts": [
            {
                "component": "alpha",
                "category": "architecture_components",
                "key": ["api"],
                "column": "type",
                "analyzer": "Service",
                "generated": "Library",
                "reason": "Targeted source inspection refined the component type.",
                "evidence": ["src/api.go:10"],
            }
        ]
    }

    report = compare_corpus(
        baseline,
        candidate,
        analyzer,
        preservation_adjudications=adjudications,
    )

    preservation = report["analyzer_preservation"]
    assert len(preservation["accepted_conflicts"]) == 1
    assert preservation["unexplained_conflicts"] == []
    assert preservation["failed_components"] == []
    assert preservation["passed"] is True
    assert report["gates"]["passed"] is True


def test_compare_corpus_accepts_adjudication_for_empty_analyzer_cell(
    tmp_path: Path,
):
    baseline = tmp_path / "baseline"
    candidate = tmp_path / "candidate"
    analyzer = tmp_path / "analyzer"
    write_document(baseline, "alpha", [("api", "Library")])
    write_document(candidate, "alpha", [("api", "Library")])
    write_document(analyzer, "alpha", [("api", "")])
    write_analyzer_json(analyzer, "alpha")
    adjudications = {
        "accepted_conflicts": [
            {
                "component": "alpha",
                "category": "architecture_components",
                "key": ["api"],
                "column": "type",
                "analyzer": "",
                "generated": "Library",
                "reason": "The source identifies the API as a reusable library.",
                "evidence": ["src/api.go:10"],
            }
        ]
    }

    report = compare_corpus(
        baseline,
        candidate,
        analyzer,
        preservation_adjudications=adjudications,
    )

    preservation = report["analyzer_preservation"]
    # Empty-to-populated cells are valid merge records, but the preservation
    # comparator does not classify them as conflicts because the analyzer cell
    # had no meaningful value to preserve.
    assert preservation["accepted_conflicts"] == []
    assert preservation["invalid_adjudications"] == []
    assert preservation["unexplained_conflicts"] == []
    assert preservation["passed"] is True
    assert report["gates"]["passed"] is True


def test_compare_corpus_accepts_exact_evidence_backed_row_deletion(tmp_path: Path):
    baseline = tmp_path / "baseline"
    candidate = tmp_path / "candidate"
    analyzer = tmp_path / "analyzer"
    write_document(baseline, "alpha", [])
    write_document(candidate, "alpha", [])
    write_document(analyzer, "alpha", [("api", "Service")])
    write_analyzer_json(analyzer, "alpha")
    adjudications = {
        "accepted_deletions": [
            {
                "component": "alpha",
                "category": "architecture_components",
                "key": ["api"],
                "reason": "Source only defines a client.",
                "evidence": ["src/client.py:10"],
            }
        ]
    }

    report = compare_corpus(
        baseline,
        candidate,
        analyzer,
        preservation_adjudications=adjudications,
    )

    preservation = report["analyzer_preservation"]
    assert preservation["structured_row_recall"] == 0.0
    assert preservation["accepted_deletions"][0]["key"] == ["api"]
    assert preservation["unexplained_missing_rows"] == []
    assert preservation["failed_components"] == []
    assert preservation["passed"] is True
    assert report["gates"]["passed"] is True


def test_compare_corpus_loads_merge_adjudications_and_agent_metrics(
    tmp_path: Path,
):
    baseline = tmp_path / "baseline"
    candidate = tmp_path / "candidate"
    analyzer = tmp_path / "analyzer"
    reports = tmp_path / "reports"
    reports.mkdir()
    write_document(baseline, "alpha", [("api", "Library")])
    write_document(candidate, "alpha", [("api", "Library")])
    write_document(analyzer, "alpha", [("api", "Service")])
    write_analyzer_json(analyzer, "alpha")
    accepted = {
        "component": "alpha",
        "category": "architecture_components",
        "key": ["api"],
        "column": "type",
        "analyzer": "Service",
        "generated": "Library",
        "reason": "Source identifies a reusable library.",
        "evidence": ["src/api.py:10"],
    }
    (reports / "alpha.merge.json").write_text(
        json.dumps(
            {
                "counts": {"applied": 1},
                "parse_errors": [],
                "accepted_conflicts": [accepted],
            }
        )
    )
    (reports / "alpha.run.json").write_text(
        json.dumps(
            {
                "component": "alpha",
                "success": True,
                "duration_seconds": 12.5,
                "routing": {
                    "readiness": "partial",
                    "route": "evidence-gated",
                },
                "telemetry": {
                    "tool_calls": 5,
                    "read_calls": 3,
                    "source_file_count": 2,
                    "total_cost_usd": 0.25,
                    "usage": {"input_tokens": 100, "output_tokens": 200},
                },
                "merge": {"duration_seconds": 0.05},
            }
        )
    )

    artifacts = load_merge_artifacts(reports)
    report = compare_corpus(
        baseline,
        candidate,
        analyzer,
        merge_artifacts=artifacts,
    )

    preservation = report["analyzer_preservation"]
    assert preservation["accepted_conflicts"][0]["component"] == "alpha"
    assert preservation["merge_adjudications"] == [accepted]
    assert preservation["passed"] is True
    execution = report["agent_execution"]
    assert execution["component_count"] == 1
    assert execution["agent_invocation_count"] == 1
    assert execution["analyzer_only_count"] == 0
    assert execution["tool_calls"] == 5
    assert execution["output_tokens"] == 200
    assert execution["cost_usd"] == 0.25
    assert "## Agent Execution" in format_corpus_report(report)


def test_load_merge_artifacts_recovers_deletions_from_older_report(tmp_path: Path):
    reports = tmp_path / "reports"
    reports.mkdir()
    (reports / "alpha.merge.json").write_text(
        json.dumps(
            {
                "counts": {"applied": 1},
                "parse_errors": [],
                "accepted_conflicts": [],
                "decisions": [
                    {
                        "status": "applied",
                        "action": "delete",
                        "category": "grpc_services",
                        "key": ["api.v1/query"],
                        "reason": "The generated stub is only used as a client.",
                        "evidence": ["src/client.py:10"],
                    }
                ],
            }
        )
    )

    artifacts = load_merge_artifacts(reports)

    assert artifacts["accepted_deletions"] == [
        {
            "component": "alpha",
            "category": "grpc_services",
            "key": ["api.v1/query"],
            "reason": "The generated stub is only used as a client.",
            "evidence": ["src/client.py:10"],
        }
    ]


def test_compare_corpus_fails_structural_validation(tmp_path: Path):
    baseline = tmp_path / "baseline"
    candidate = tmp_path / "candidate"
    analyzer = tmp_path / "analyzer"
    write_document(baseline, "alpha", [("api", "Service")])
    write_document(
        candidate, "alpha", [("api", "Service")], include_analysis=False,
    )
    write_document(
        analyzer, "alpha", [("api", "Service")], include_analysis=False,
    )
    write_analyzer_json(analyzer, "alpha")

    report = compare_corpus(baseline, candidate, analyzer)

    structural = report["structural_validation"]
    assert structural["failed_documents"] == ["alpha"]
    assert structural["passed"] is False
    assert report["gates"]["passed"] is False


def test_compare_corpus_rejects_incomplete_crd_identity(tmp_path: Path):
    baseline = tmp_path / "baseline"
    candidate = tmp_path / "candidate"
    analyzer = tmp_path / "analyzer"
    write_document(baseline, "alpha", [("api", "Service")])
    candidate_path = write_document(candidate, "alpha", [("api", "Service")])
    analyzer_path = write_document(analyzer, "alpha", [("api", "Service")])
    invalid_crd = """### Custom Resource Definitions (CRDs)

| Group | Version | Kind | Scope | Purpose |
|-------|---------|------|-------|---------|
|  |  |  |  | Patch-derived row |

"""
    for path in (candidate_path, analyzer_path):
        path.write_text(
            path.read_text().replace(
                "## APIs Exposed\n\n",
                "## APIs Exposed\n\n" + invalid_crd,
            )
        )
    write_analyzer_json(analyzer, "alpha")

    report = compare_corpus(baseline, candidate, analyzer)

    structural = report["structural_validation"]
    assert structural["failed_documents"] == ["alpha"]
    assert "incomplete CRD identity" in structural["errors"]["alpha"][0]
    assert report["gates"]["passed"] is False


def test_compare_corpus_rejects_detailed_synthesis_with_sparse_core_tables(
    tmp_path: Path,
):
    baseline = tmp_path / "baseline"
    candidate = tmp_path / "candidate"
    analyzer = tmp_path / "analyzer"
    write_document(baseline, "alpha", [])
    candidate_path = write_document(candidate, "alpha", [])
    analyzer_path = write_document(analyzer, "alpha", [])
    detailed = " ".join(["source-backed architecture behavior"] * 30)
    for path in (candidate_path, analyzer_path):
        path.write_text(path.read_text().replace("Example component.", detailed))
    write_analyzer_json(analyzer, "alpha")

    report = compare_corpus(baseline, candidate, analyzer)

    quality = report["synthesis_structure_quality"]
    assert quality["failed_components"] == ["alpha"]
    assert quality["components"]["alpha"]["empty_high_value_categories"] == [
        "architecture_components",
        "authentication",
        "integration_points",
        "internal_dependencies",
    ]
    assert report["gates"]["passed"] is False
    assert "Sparse High-Value Structure" in format_corpus_report(report)


@pytest.mark.parametrize(
    ("replacement", "expected_reason"),
    [
        (
            "Brief source-backed summary.",
            "analyzer-only synthesis is below the minimum word count",
        ),
        (
            "Pending constrained synthesis from source-backed facts. "
            + "Source backed architecture evidence. " * 70,
            "analyzer-only synthesis contains a pending placeholder",
        ),
    ],
)
def test_compare_corpus_enforces_analyzer_only_synthesis_quality(
    tmp_path: Path,
    replacement: str,
    expected_reason: str,
):
    baseline = tmp_path / "baseline"
    candidate = tmp_path / "candidate"
    analyzer = tmp_path / "analyzer"
    rows = [("api", "Service")]
    write_document(baseline, "alpha", rows)
    candidate_path = write_document(candidate, "alpha", rows)
    analyzer_path = write_document(analyzer, "alpha", rows)
    for path in (candidate_path, analyzer_path):
        path.write_text(path.read_text().replace("Example component.", replacement))
    write_analyzer_json(analyzer, "alpha")

    report = compare_corpus(
        baseline,
        candidate,
        analyzer,
        merge_artifacts={
            "runs": {"alpha": {"routing": {"route": "analyzer-only"}}}
        },
    )

    quality = report["synthesis_structure_quality"]
    assert quality["failed_components"] == ["alpha"]
    assert expected_reason in quality["components"]["alpha"]["failure_reasons"]
    assert report["gates"]["passed"] is False


def test_compare_corpus_rejects_overlapping_directories(tmp_path: Path):
    baseline = tmp_path / "baseline"
    analyzer = tmp_path / "analyzer"
    baseline.mkdir()
    analyzer.mkdir()

    with pytest.raises(ValueError, match="overlap"):
        compare_corpus(baseline, baseline / "candidate", analyzer)


def test_initialize_run_creates_isolated_tree_and_captures_config(tmp_path: Path):
    source = tmp_path / "source"
    platform_dir = source / "rhoai.next"
    platform_dir.mkdir(parents=True)
    (platform_dir / "component-map.json").write_text(
        json.dumps({"metadata": {}, "components": {}})
    )
    baseline = tmp_path / "baseline"
    baseline.mkdir()
    platforms_file = tmp_path / "platforms.yaml"
    platforms_file.write_text("rhoai.next:\n  suffix: next\n")
    run_dir = tmp_path / "run"

    manifest = initialize_run(
        repo_root=tmp_path,
        source_architecture_dir=source,
        platform="rhoai.next",
        platforms_file=platforms_file,
        baseline_dir=baseline,
        run_dir=run_dir,
        model="opus",
        workers=10,
        prior_wall_seconds=3600,
    )

    assert manifest["platform_config"] == {"suffix": "next"}
    assert manifest["model"] == "opus"
    assert manifest["workers"] == 10
    assert (run_dir / "architecture/rhoai.next/component-map.json").is_file()
    assert (run_dir / "analyzer/rhoai.next").is_dir()
    assert json.loads(
        (run_dir / "preservation-adjudications.json").read_text()
    ) == {"schema_version": 1, "accepted_conflicts": []}
    assert baseline.exists()

    with pytest.raises(ValueError, match="already exists"):
        initialize_run(
            repo_root=tmp_path,
            source_architecture_dir=source,
            platform="rhoai.next",
            platforms_file=platforms_file,
            baseline_dir=baseline,
            run_dir=run_dir,
            model="opus",
            workers=10,
            prior_wall_seconds=3600,
        )


def test_initialize_run_filters_a_bounded_component_matrix(tmp_path: Path):
    source = tmp_path / "source"
    platform_dir = source / "rhoai.next"
    platform_dir.mkdir(parents=True)
    (platform_dir / "component-map.json").write_text(
        json.dumps(
            {
                "metadata": {"platform": "rhoai.next"},
                "components": {
                    name: {
                        "key": name,
                        "repo_org": "example",
                        "repo_name": name,
                        "checkout_path": str(tmp_path / name),
                    }
                    for name in ("alpha", "beta", "gamma")
                },
            }
        )
    )
    baseline = tmp_path / "baseline"
    baseline.mkdir()
    platforms_file = tmp_path / "platforms.yaml"
    platforms_file.write_text("rhoai.next:\n  suffix: next\n")
    run_dir = tmp_path / "run"

    manifest = initialize_run(
        repo_root=tmp_path,
        source_architecture_dir=source,
        platform="rhoai.next",
        platforms_file=platforms_file,
        baseline_dir=baseline,
        run_dir=run_dir,
        model="opus",
        workers=3,
        prior_wall_seconds=3600,
        component_names=("alpha", "gamma"),
    )

    filtered = json.loads(
        (run_dir / "architecture/rhoai.next/component-map.json").read_text()
    )
    assert list(filtered["components"]) == ["alpha", "gamma"]
    assert filtered["metadata"]["components_selected"] == 2
    assert filtered["metadata"]["selected_components"] == ["alpha", "gamma"]
    assert manifest["components"] == ["alpha", "gamma"]
    assert list(manifest["repositories"]) == ["alpha", "gamma"]


def test_initialize_run_rejects_baseline_candidate_overlap(tmp_path: Path):
    source = tmp_path / "source"
    platform_dir = source / "rhoai.next"
    platform_dir.mkdir(parents=True)
    (platform_dir / "component-map.json").write_text(
        json.dumps({"metadata": {}, "components": {}})
    )
    platforms_file = tmp_path / "platforms.yaml"
    platforms_file.write_text("rhoai.next:\n  suffix: next\n")

    with pytest.raises(ValueError, match="overlap"):
        initialize_run(
            repo_root=tmp_path,
            source_architecture_dir=source,
            platform="rhoai.next",
            platforms_file=platforms_file,
            baseline_dir=tmp_path,
            run_dir=tmp_path / "nested-run",
            model="opus",
            workers=10,
            prior_wall_seconds=3600,
        )


def test_snapshot_analyzers_copies_complete_inputs_and_reports_missing(
    tmp_path: Path,
):
    complete = tmp_path / "complete"
    incomplete = tmp_path / "incomplete"
    complete.mkdir()
    incomplete.mkdir()
    (complete / "analyzer_architecture.md").write_text("# Complete\n")
    (complete / "component-architecture.json").write_text("{}\n")
    analyzer_dir = tmp_path / "run/analyzer/rhoai.next"
    reports_dir = tmp_path / "run/reports"
    manifest_path = tmp_path / "run/run.json"
    manifest_path.parent.mkdir(parents=True)
    manifest_path.write_text(
        json.dumps(
            {
                "paths": {
                    "analyzer_dir": str(analyzer_dir),
                    "reports_dir": str(reports_dir),
                },
                "repositories": {
                    "complete": {
                        "available": True,
                        "checkout_path": str(complete),
                    },
                    "incomplete": {
                        "available": True,
                        "checkout_path": str(incomplete),
                    },
                },
            }
        )
    )

    snapshot = snapshot_analyzers(manifest_path)

    assert snapshot["copied"] == 1
    assert snapshot["missing"] == {
        "incomplete": ["analyzer_architecture.md", "component-architecture.json"]
    }
    assert (analyzer_dir / "complete.md").is_file()
    assert (analyzer_dir / "complete.json").is_file()
    assert (reports_dir / "analyzer-snapshot.json").is_file()
    assert json.loads(manifest_path.read_text())["status"] == (
        "analyzer_snapshot_failed"
    )


def test_snapshot_analyzers_prefers_candidate_architecture_artifacts(
    tmp_path: Path,
):
    candidate = tmp_path / "run/architecture/rhoai.next/complete/.analyzer"
    candidate.mkdir(parents=True)
    (candidate / "analyzer_architecture.md").write_text("# Candidate\n")
    (candidate / "component-architecture.json").write_text('{"source": "candidate"}\n')
    analyzer_dir = tmp_path / "run/analyzer/rhoai.next"
    reports_dir = tmp_path / "run/reports"
    manifest_path = tmp_path / "run/run.json"
    manifest_path.write_text(
        json.dumps(
            {
                "paths": {
                    "analyzer_dir": str(analyzer_dir),
                    "candidate_dir": str(tmp_path / "run/architecture/rhoai.next"),
                    "reports_dir": str(reports_dir),
                },
                "repositories": {
                    "complete": {
                        "available": True,
                        "checkout_path": str(tmp_path / "missing-checkout"),
                    }
                },
            }
        )
    )

    snapshot = snapshot_analyzers(manifest_path)

    assert snapshot["copied"] == 1
    assert snapshot["missing"] == {}
    assert (analyzer_dir / "complete.md").read_text() == "# Candidate\n"
    assert json.loads((analyzer_dir / "complete.json").read_text()) == {
        "source": "candidate"
    }


def test_record_phase_captures_timing_command_log_and_failures(tmp_path: Path):
    manifest_path = tmp_path / "run.json"
    manifest_path.write_text(json.dumps({"phases": {}}))
    log = tmp_path / "static.log"
    log.write_text("Static output\nFailed: 2\n")

    manifest = record_phase(
        manifest_path,
        phase="static_analysis",
        started_at="2026-07-17T10:00:00Z",
        ended_at="2026-07-17T10:00:03Z",
        started_epoch=100.0,
        ended_epoch=103.0,
        wall_seconds=3.0,
        exit_code=0,
        command="uv run main.py static-analysis",
        log_path=str(log),
    )

    phase = manifest["phases"]["static_analysis"]
    assert phase["wall_seconds"] == 3.0
    assert phase["reported_failures"] == 2
    assert phase["command"] == "uv run main.py static-analysis"
    assert phase["log_path"] == str(log.resolve())


def test_corpus_reports_include_timing_and_write_json_and_markdown(tmp_path: Path):
    baseline = tmp_path / "baseline"
    candidate = tmp_path / "candidate"
    analyzer = tmp_path / "analyzer"
    for directory in (baseline, candidate, analyzer):
        write_document(directory, "alpha", [("api", "Service")])
    write_analyzer_json(analyzer, "alpha")
    run_manifest = {
        "prior_wall_seconds": 100.0,
        "phases": {
            "static_analysis": {
                "started_epoch": 100.0,
                "ended_epoch": 102.0,
                "wall_seconds": 2.0,
                "exit_code": 0,
                "reported_failures": 0,
                "started_at": "start",
                "ended_at": "static-end",
                "log_path": "static.log",
            },
            "component_generation": {
                "started_epoch": 102.0,
                "ended_epoch": 110.0,
                "wall_seconds": 8.0,
                "exit_code": 0,
                "reported_failures": 0,
                "started_at": "static-end",
                "ended_at": "agent-end",
                "log_path": "agent.log",
            },
            "collection": {
                "started_epoch": 110.0,
                "ended_epoch": 111.0,
                "wall_seconds": 1.0,
                "exit_code": 0,
                "reported_failures": None,
                "started_at": "agent-end",
                "ended_at": "collection-end",
                "log_path": "collection.log",
            },
        },
    }

    report = compare_corpus(
        baseline, candidate, analyzer, run_manifest=run_manifest,
    )
    json_path = tmp_path / "reports/comparison.json"
    markdown_path = tmp_path / "reports/comparison.md"
    write_corpus_reports(report, json_path, markdown_path)

    assert report["timing"]["static_analysis_seconds"] == 2.0
    assert report["timing"]["bounded_agent_seconds"] == 8.0
    assert report["timing"]["workflow_wall_seconds"] == 11.0
    assert report["timing"]["wall_time_reduction"] == pytest.approx(0.89)
    assert json.loads(json_path.read_text())["gates"]["passed"] is True
    markdown = markdown_path.read_text()
    assert "## History And Source Inventory" in markdown
    assert "Wall-time reduction from prior reference: 89.00%." in markdown
