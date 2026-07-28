import json
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

from lib.source_read_justifications import validate_source_read_justifications


def _write_sidecar(path: Path, reads: list[dict]) -> None:
    path.write_text(json.dumps({
        "schema_version": 1,
        "component": "example",
        "reads": reads,
    }))


def _read_record(path: str = "pkg/server.go", **updates) -> dict:
    record = {
        "path": path,
        "line_range": "10-20",
        "gap_category": ["http_endpoints"],
        "question": "where?",
        "expected_signal": "handler",
        "outcome": "resolved",
        "sections": ["APIs Exposed"],
    }
    record.update(updates)
    return record


def test_justifications_compare_with_telemetry(tmp_path: Path):
    sidecar = tmp_path / "SOURCE_READ_JUSTIFICATIONS.json"
    _write_sidecar(sidecar, [_read_record()])
    result = validate_source_read_justifications(
        sidecar, {"source_files_read": ["pkg/server.go", "pkg/client.go"]},
    )
    assert result["justified_read_ratio"] == 0.5
    assert result["missing_paths"] == ["pkg/client.go"]
    assert result["warnings"]


def test_justifications_reject_secret_like_metadata_but_remain_warning_only(
    tmp_path: Path,
):
    sidecar = tmp_path / "ledger.json"
    _write_sidecar(
        sidecar,
        [
            _read_record(
                path="config.go",
                line_range="1",
                gap_category=["egress"],
                excerpt="secret",
            )
        ],
    )
    result = validate_source_read_justifications(sidecar, {"source_files_read": []})
    assert any("forbidden" in warning for warning in result["warnings"])


def test_justifications_match_absolute_telemetry_suffix(tmp_path: Path):
    sidecar = tmp_path / "ledger.json"
    _write_sidecar(sidecar, [_read_record(path="./pkg/server.go")])

    result = validate_source_read_justifications(
        sidecar,
        {
            "source_files_read": [
                "/data/checkouts/example/pkg/server.go",
            ]
        },
    )

    assert result["missing_paths"] == []
    assert result["extra_paths"] == []
    assert result["justified_read_ratio"] == 1.0
    assert result["warnings"] == []
    repaired = json.loads(sidecar.read_text())
    assert repaired["reads"][0]["path"] == "pkg/server.go"


def test_missing_sections_is_repaired_not_counted_as_warning(tmp_path: Path):
    sidecar = tmp_path / "ledger.json"
    record = _read_record(path="pkg/server.go")
    del record["sections"]
    _write_sidecar(sidecar, [record])

    result = validate_source_read_justifications(
        sidecar, {"source_files_read": ["pkg/server.go"]},
    )

    assert result["warnings"] == []
    assert result["repairs"] == [
        {
            "record": 0,
            "field": "sections",
            "action": "defaulted-empty-array",
        }
    ]
    assert result["diagnostics"][0]["category"] == "record-repaired"
    repaired = json.loads(sidecar.read_text())
    assert repaired["reads"][0]["sections"] == []


def test_malformed_record_does_not_justify_observed_path(tmp_path: Path):
    sidecar = tmp_path / "ledger.json"
    _write_sidecar(
        sidecar,
        [
            _read_record(
                path="pkg/server.go",
                outcome="not-real",
            )
        ],
    )

    result = validate_source_read_justifications(
        sidecar, {"source_files_read": ["pkg/server.go"]},
    )

    assert result["justified_source_file_count"] == 0
    assert result["missing_paths"] == ["pkg/server.go"]
    assert any(
        diagnostic["category"] == "malformed-record"
        for diagnostic in result["diagnostics"]
    )
    assert any(
        diagnostic["category"] == "missing-justification"
        for diagnostic in result["diagnostics"]
    )


def test_extra_ledger_path_has_diagnostic_category(tmp_path: Path):
    sidecar = tmp_path / "ledger.json"
    _write_sidecar(sidecar, [_read_record(path="pkg/unused.go")])

    result = validate_source_read_justifications(
        sidecar, {"source_files_read": ["pkg/server.go"]},
    )

    assert result["missing_paths"] == ["pkg/server.go"]
    assert result["extra_paths"] == ["pkg/unused.go"]
    assert any(
        diagnostic["category"] == "unobserved-ledger-path"
        and diagnostic["owner"] == "agent"
        for diagnostic in result["diagnostics"]
    )
