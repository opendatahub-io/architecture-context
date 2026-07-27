import json

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
