import json
import sys
from pathlib import Path

PROJECT_ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(PROJECT_ROOT))

from scripts.analyze_analyzer_only_eligibility import classify_run  # noqa: E402


def _write_json(path: Path, payload: dict) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(payload))


def test_classification_uses_fresh_analyzer_readiness(tmp_path: Path) -> None:
    run = tmp_path / "run"
    logs = run / "logs" / "agents"
    analyzer = run / "analyzer" / "rhoai.next"
    generated = run / "architecture" / "rhoai.next"
    for directory in (logs, analyzer, generated):
        directory.mkdir(parents=True)

    _write_json(run / "run.json", {"workers": 10})
    _write_json(
        logs / "widget.run.json",
        {
            "component": "widget",
            "routing": {"readiness": "partial"},
            "duration_seconds": 12,
            "telemetry": {"usage": {}, "total_cost_usd": 0},
        },
    )
    _write_json(
        analyzer / "widget.json",
        {
            "data_coverage": {
                "agent_baseline": "sufficient: fresh source facts are complete"
            }
        },
    )
    markdown = """# Widget

## Architecture Components

| Component | Type | Technology | Purpose |
|---|---|---|---|
| widget | Service | Go | Serve widgets |

## Authentication & Authorization

| Endpoint | Methods | Auth Mechanism | Enforcement Point | Policy |
|---|---|---|---|---|
| /widgets | GET | None | N/A | Public endpoint |

## Integration Points

| Component | Interaction Type | Port | Protocol | Encryption | Purpose |
|---|---|---|---|---|---|
| database | Client | 5432 | PostgreSQL | TLS | Store widgets |

## Internal Platform Dependencies

| Component | Interaction | Purpose |
|---|---|---|
| platform | API client | Discover widgets |

## Architectural Analysis

The fresh analyzer provides the complete structured baseline for this component.
"""
    (analyzer / "widget.md").write_text(markdown)
    (generated / "widget.md").write_text(markdown)

    report = classify_run(run)

    assert report["summary"]["sufficient_components"] == 1
    assert report["components"][0]["component"] == "widget"
    assert report["components"][0]["analyzer_only_candidate"] is True
