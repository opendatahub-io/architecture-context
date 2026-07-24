import sys
from pathlib import Path

import pytest

PROJECT_ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(PROJECT_ROOT))

from lib.phases import static_analysis  # noqa: E402


class FakeProcess:
    def __init__(self, returncode=0, stderr=b""):
        self.returncode = returncode
        self._stderr = stderr

    async def communicate(self):
        return b"", self._stderr


@pytest.mark.asyncio
async def test_run_extract_uses_explicit_output_and_distribution_fallback(
    tmp_path: Path, monkeypatch: pytest.MonkeyPatch,
):
    calls = []

    async def fake_subprocess(*args, cwd, **kwargs):
        calls.append(args)
        if "--distribution" in args:
            return FakeProcess(
                returncode=1,
                stderr=b'no kustomization matches distribution "rhoai"',
            )
        (Path(cwd) / "component-architecture.json").write_text("{}\n")
        return FakeProcess()

    monkeypatch.setattr(
        static_analysis.asyncio, "create_subprocess_exec", fake_subprocess,
    )
    result = await static_analysis._run_extract(
        "/bin/arch-analyzer", "example", tmp_path, "rhoai", True,
    )

    assert result["success"] is True
    assert len(calls) == 2
    assert calls[0][-2:] == ("--distribution", "rhoai")
    assert calls[1] == (
        "/bin/arch-analyzer", "extract", ".",
        "--output", "component-architecture.json",
    )


@pytest.mark.asyncio
async def test_run_render_creates_agent_markdown_baseline(
    tmp_path: Path, monkeypatch: pytest.MonkeyPatch,
):
    (tmp_path / "component-architecture.json").write_text("{}\n")
    calls = []

    async def fake_subprocess(*args, cwd, **kwargs):
        calls.append(args)
        (Path(cwd) / "ANALYZER_ARCHITECTURE.md").write_text("# Component\n")
        return FakeProcess()

    monkeypatch.setattr(
        static_analysis.asyncio, "create_subprocess_exec", fake_subprocess,
    )
    result = await static_analysis._run_render(
        "/bin/arch-analyzer", "example", tmp_path, "rhoai", True,
    )

    assert result["success"] is True
    assert calls[0] == (
        "/bin/arch-analyzer", "render",
        "--input", "component-architecture.json",
        "--output", "ANALYZER_ARCHITECTURE.md",
        "--distribution", "RHOAI",
    )
