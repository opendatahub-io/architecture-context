import json
from argparse import Namespace
from unittest.mock import patch

import pytest

from lib.webhook_analyzer import (
    WebhookEntry,
    build_cross_cutting_map,
    collect_webhooks,
    enrich_component_json,
)


def test_cross_cutting_map_tolerates_null_optional_webhook_fields():
    webhooks = [
        WebhookEntry(
            name="first",
            component="component-a",
            type="mutating",
            path="/validate",
            rules=None,
            sources=None,
        ),
        WebhookEntry(
            name="second",
            component="component-b",
            type="validating",
            path="/validate",
            rules=[{"resources": None}],
            sources=[None],
        ),
    ]

    concerns = build_cross_cutting_map(webhooks)

    assert concerns == [{
        "name": "validate",
        "webhooks": ["first", "second"],
        "affected_types": [],
        "affected_components": ["component-a", "component-b"],
    }]


def test_collect_webhooks_normalizes_null_lists(tmp_path):
    version_dir = tmp_path / "rhoai.next"
    version_dir.mkdir()
    (version_dir / "component.json").write_text(json.dumps({
        "webhooks": [{
            "name": "null-fields",
            "type": "mutating",
            "path": "/validate",
            "rules": None,
            "sources": None,
        }],
    }))

    collected = collect_webhooks(str(tmp_path), "rhoai.next")

    assert len(collected) == 1
    assert collected[0].rules == []
    assert collected[0].sources == []


def test_enrich_component_json_tolerates_null_webhooks(tmp_path):
    path = tmp_path / "component.json"
    path.write_text(json.dumps({"webhooks": None}))
    webhook = WebhookEntry(
        name="discovered",
        component="component",
        type="mutating",
        path="/validate",
    )

    enrich_component_json(path, [webhook], [], [])

    data = json.loads(path.read_text())
    assert data["webhooks"][0]["name"] == "discovered"


def test_webhook_phase_consumes_analyzer_inventory_without_source_scan(tmp_path):
    version_dir = tmp_path / "rhoai.next"
    version_dir.mkdir()
    (version_dir / "component.json").write_text(json.dumps({
        "webhooks": [
            {
                "name": "widget-mutator",
                "type": "mutating",
                "path": "/mutate",
                "rules": [{"resources": ["widgets"]}],
                "sources": [{"type": "kubebuilder_marker", "file": "webhook.go", "line": 3}],
            },
            {
                "name": "gadgets.example.io",
                "type": "conversion",
                "path": "/convert",
                "rules": [{"resources": ["gadgets"], "operations": ["CONVERT"]}],
                "sources": [{"type": "crd_conversion", "file": "crd.yaml", "line": 1}],
            },
        ],
    }))

    collected = collect_webhooks(str(tmp_path), "rhoai.next")

    assert [webhook.name for webhook in collected] == [
        "widget-mutator", "gadgets.example.io",
    ]
    assert all(webhook.sources for webhook in collected)


@pytest.mark.asyncio(loop_scope="function")
async def test_webhook_phase_skips_agent_analysis(tmp_path):
    """The webhook phase no longer spawns agents for semantic analysis."""
    arch_dir = tmp_path / "architecture"
    version_dir = arch_dir / "rhoai.next"
    version_dir.mkdir(parents=True)
    (version_dir / "component.json").write_text(json.dumps({
        "webhooks": [{
            "name": "test-wh",
            "type": "mutating",
            "path": "/mutate",
            "rules": [{"resources": ["widgets"]}],
            "sources": [{"type": "webhook_manifest", "file": "wh.yaml", "line": 1}],
        }],
    }))

    args = Namespace(
        platform="rhoai",
        architecture_dir=str(arch_dir),
        checkouts_dir=str(tmp_path / "checkouts"),
        version=None,
        force=True,
        model="sonnet",
        max_concurrent=1,
        strace=False,
    )

    with patch("lib.phases.webhooks.read_component_map", return_value={}):
        from lib.phases.webhooks import run_webhook_inventory_phase
        await run_webhook_inventory_phase(args)

    output = version_dir / "webhooks.json"
    assert output.exists()
    data = json.loads(output.read_text())
    assert data["summary"]["total"] == 1
    assert data["webhooks"][0]["name"] == "test-wh"


def test_webhook_phase_does_not_import_agent_runner():
    """Verify webhook phase no longer imports or calls agent analysis."""
    import ast
    from pathlib import Path

    source = Path("lib/phases/webhooks.py").read_text()
    tree = ast.parse(source)

    imported_names = set()
    for node in ast.walk(tree):
        if isinstance(node, ast.ImportFrom):
            for alias in node.names:
                imported_names.add(alias.name)

    assert "run_webhook_agent_analysis" not in imported_names
