import json
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

from lib.source_read_justifications import validate_source_read_justifications


def test_justifications_compare_with_telemetry(tmp_path: Path):
    sidecar = tmp_path / "SOURCE_READ_JUSTIFICATIONS.json"
    sidecar.write_text(json.dumps({
        "schema_version": 1,
        "component": "example",
        "reads": [{
            "path": "pkg/server.go", "line_range": "10-20",
            "gap_category": "http_endpoints", "question": "where?",
            "expected_signal": "handler", "outcome": "resolved",
            "sections": ["APIs Exposed"],
        }],
    }))
    result = validate_source_read_justifications(
        sidecar, {"source_files_read": ["pkg/server.go", "pkg/client.go"]},
    )
    assert result["justified_read_ratio"] == 0.5
    assert result["missing_paths"] == ["pkg/client.go"]
    assert result["warnings"]


def test_justifications_reject_secret_like_metadata_but_remain_warning_only(tmp_path: Path):
    sidecar = tmp_path / "ledger.json"
    sidecar.write_text(json.dumps({
        "reads": [{
            "path": "config.go", "line_range": "1", "gap_category": "egress",
            "question": "q", "expected_signal": "s", "outcome": "resolved",
            "sections": [], "excerpt": "secret",
        }],
    }))
    result = validate_source_read_justifications(sidecar, {"source_files_read": []})
    assert any("forbidden" in warning for warning in result["warnings"])
