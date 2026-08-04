import json
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))
from lib.analyzer_evidence_validation import validate_analyzer_evidence


def test_analyzer_evidence_validation_rejects_duplicates_and_unknown_topics(tmp_path):
    path = tmp_path / "component-architecture.json"
    path.write_text(
        json.dumps(
            {
                "security_evidence": [
                    {
                        "kind": "tls-config",
                        "target": "crypto/tls",
                        "detail": "import",
                        "status": "dependency-signal",
                        "source": "a.go",
                    },
                    {
                        "kind": "tls-config",
                        "target": "crypto/tls",
                        "detail": "import",
                        "status": "dependency-signal",
                        "source": "b.go",
                    },
                ],
                "cross_cutting_evidence": {"unknown": []},
            }
        )
    )
    result = validate_analyzer_evidence(path)
    assert not result["valid"]
    assert any("duplicate" in error for error in result["errors"])
    assert any("unknown" in error for error in result["errors"])


def test_analyzer_evidence_validation_accepts_source_linked_topics(tmp_path):
    path = tmp_path / "component-architecture.json"
    path.write_text(
        json.dumps(
            {
                "security_evidence": [
                    {
                        "kind": "tls-config",
                        "target": "crypto/tls",
                        "detail": "import",
                        "status": "dependency-signal",
                        "sources": ["a.go"],
                    }
                ],
                "cross_cutting_evidence": {
                    "security": [
                        {
                            "claim": "TLS import",
                            "status": "dependency-signal",
                            "sources": ["a.go"],
                        }
                    ]
                },
            }
        )
    )
    result = validate_analyzer_evidence(path)
    assert result["valid"]
