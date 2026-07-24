import sys
from pathlib import Path
from types import SimpleNamespace

import pytest

PROJECT_ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(PROJECT_ROOT))

from lib.cli import resolve_distribution  # noqa: E402
from lib.component_discovery import apply_component_selection  # noqa: E402
from lib.phases import architecture, static_analysis  # noqa: E402


@pytest.mark.parametrize(
    ("platform", "expected"),
    [
        ("rhoai", "rhoai"),
        ("rhoai.next", "rhoai"),
        ("rhoai-3.5-ea.2", "rhoai"),
        ("odh", "odh"),
        ("odh.next", "odh"),
        ("odh-2.4", "odh"),
        ("both", "both"),
        (" RHOAI.NEXT ", "rhoai"),
    ],
)
def test_resolve_distribution(platform: str, expected: str):
    assert resolve_distribution(platform) == expected


@pytest.mark.parametrize("platform", ["", "next", "custom-1.0"])
def test_resolve_distribution_rejects_unsupported_platform(platform: str):
    with pytest.raises(ValueError, match="Unsupported platform identifier"):
        resolve_distribution(platform)


def test_component_selection_removes_platform_additions_outside_matrix():
    components = {
        name: SimpleNamespace(key=name)
        for name in ("batch-gateway", "eval-hub", "odh-dashboard", "added")
    }

    selected = apply_component_selection(
        components,
        {
            "selected_components": [
                "batch-gateway",
                "eval-hub",
                "odh-dashboard",
            ]
        },
    )

    assert list(selected) == ["batch-gateway", "eval-hub", "odh-dashboard"]


@pytest.mark.asyncio
async def test_component_generation_uses_supported_distribution_in_prompt(
    tmp_path: Path, monkeypatch: pytest.MonkeyPatch,
):
    checkout = tmp_path / "example"
    checkout.mkdir()
    component = SimpleNamespace(
        key="example",
        repo_org="example-org",
        repo_name="example-repo",
        checkout_path=checkout,
        has_architecture=False,
        architecturally_significant=True,
        tier="core_platform",
    )
    captured_jobs = []

    async def fake_run_agents(jobs, *args, **kwargs):
        captured_jobs.extend(jobs)
        return [{"name": "example", "success": True, "duration_seconds": 0}]

    monkeypatch.chdir(tmp_path)
    monkeypatch.setattr(
        architecture,
        "read_component_map",
        lambda *args, **kwargs: {"example": component},
    )
    monkeypatch.setattr(architecture, "load_platform_config", lambda *args: {})
    monkeypatch.setattr(architecture, "run_agents_concurrently", fake_run_agents)
    monkeypatch.setattr(
        architecture, "get_model_display_name", lambda model: "Test Model",
    )

    args = SimpleNamespace(
        platform="rhoai.next",
        architecture_dir=str(tmp_path),
        component=None,
        tier="all",
        force=False,
        limit=None,
        model="opus",
        max_concurrent=1,
        strace=False,
    )
    await architecture.run_generate_architecture_phase(args)

    assert len(captured_jobs) == 1
    assert "--distribution=rhoai" in captured_jobs[0]["prompt"]
    assert "--distribution=rhoai.next" not in captured_jobs[0]["prompt"]


@pytest.mark.asyncio
async def test_static_analysis_uses_shared_distribution_resolver(
    tmp_path: Path, monkeypatch: pytest.MonkeyPatch,
):
    checkout = tmp_path / "example"
    checkout.mkdir()
    component = SimpleNamespace(checkout_path=checkout)
    captured_distributions = []

    async def fake_ensure_arch_analyzer():
        return "/bin/arch-analyzer"

    async def fake_analyze_component(
        command, key, path, semaphore, distribution, force, skip_schemas,
    ):
        captured_distributions.append(distribution)
        return {
            "name": key,
            "extract": {"success": True},
            "render": {"success": True},
            "schema": {"success": True, "schema_count": 0},
        }

    monkeypatch.setattr(
        static_analysis,
        "read_component_map",
        lambda *args, **kwargs: {"example": component},
    )
    monkeypatch.setattr(static_analysis, "load_platform_config", lambda *args: {})
    monkeypatch.setattr(
        static_analysis, "_ensure_arch_analyzer", fake_ensure_arch_analyzer,
    )
    monkeypatch.setattr(
        static_analysis, "_analyze_component", fake_analyze_component,
    )

    args = SimpleNamespace(
        platform="rhoai.next",
        architecture_dir=str(tmp_path),
        component=None,
        force=True,
        skip_schemas=False,
        max_concurrent=1,
    )
    await static_analysis.run_static_analysis_phase(args)

    assert captured_distributions == ["rhoai"]
