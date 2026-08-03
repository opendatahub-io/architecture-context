import asyncio
import sys
from pathlib import Path
from types import SimpleNamespace

PROJECT_ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(PROJECT_ROOT))

from lib.phases import orchestration  # noqa: E402


def _component(key, repo_org, repo_name, repo_url=None):
    return SimpleNamespace(
        key=key,
        repo_org=repo_org,
        repo_name=repo_name,
        repo_url=repo_url or f"https://github.com/{repo_org}/{repo_name}",
    )


def test_resolve_pipeline_components_accepts_repo_selectors(monkeypatch):
    monkeypatch.setattr(
        orchestration,
        "read_component_map",
        lambda *args, **kwargs: {
            "models-as-a-service": _component(
                "models-as-a-service",
                "red-hat-data-services",
                "models-as-a-service",
            ),
            "llm-d-inference-scheduler": _component(
                "llm-d-inference-scheduler",
                "llm-d",
                "llm-d-inference-scheduler",
            ),
        },
    )
    args = SimpleNamespace(
        platform="rhoai.next",
        architecture_dir="architecture",
        component=["models-as-a-service"],
        repo=[
            "llm-d/llm-d-inference-scheduler",
            "models-as-a-service",
        ],
    )

    assert orchestration._resolve_pipeline_components(args) == [
        "models-as-a-service",
        "llm-d-inference-scheduler",
    ]


def test_pipeline_dispatches_component_scoped_phases_in_order(monkeypatch):
    calls = []

    async def fake_run_pipeline_phase(phase, phase_args):
        calls.append((phase, getattr(phase_args, "component", None)))

    monkeypatch.setattr(orchestration, "_run_pipeline_phase", fake_run_pipeline_phase)
    args = SimpleNamespace(
        platform="rhoai.next",
        phase=["static-analysis", "generate-architecture"],
        component=["models-as-a-service", "eval-hub"],
        repo=[],
        architecture_dir="architecture",
        checkouts_dir="checkouts",
        max_concurrent=1,
        force=True,
        skip_schemas=False,
        model="opus",
        log_dir="logs/pipeline/test/generate-architecture",
        version=None,
        evidence_gated_merge=True,
        tier="all",
        strace=False,
    )

    asyncio.run(orchestration.run_pipeline_phases(args))

    assert calls == [
        ("static-analysis", "models-as-a-service"),
        ("static-analysis", "eval-hub"),
        ("generate-architecture", "models-as-a-service"),
        ("generate-architecture", "eval-hub"),
    ]
