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
        (Path(cwd) / "analyzer_architecture.md").write_text("# Component\n")
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
        "--output", "analyzer_architecture.md",
        "--distribution", "RHOAI",
    )


@pytest.mark.asyncio
async def test_static_outputs_can_be_written_outside_checkout(
    tmp_path: Path, monkeypatch: pytest.MonkeyPatch,
):
    checkout = tmp_path / "checkout"
    output_dir = tmp_path / "architecture" / "rhoai.next" / "example" / ".analyzer"
    checkout.mkdir()
    calls = []

    async def fake_subprocess(*args, cwd, **kwargs):
        calls.append(args)
        if args[1] == "extract":
            Path(args[4]).write_text("{}\n")
        elif args[1] == "render":
            Path(args[5]).write_text("# Component\n")
        elif args[1] == "extract-schema":
            schema_dir = Path(args[4])
            schema_dir.mkdir(parents=True, exist_ok=True)
            (schema_dir / "example.v1.json").write_text("{}\n")
        return FakeProcess()

    monkeypatch.setattr(
        static_analysis.asyncio, "create_subprocess_exec", fake_subprocess,
    )
    extract = await static_analysis._run_extract(
        "/bin/arch-analyzer", "example", checkout, "rhoai", True,
        output_dir=output_dir,
    )
    render = await static_analysis._run_render(
        "/bin/arch-analyzer", "example", checkout, "rhoai", True,
        output_dir=output_dir,
    )
    schemas = await static_analysis._run_extract_schema(
        "/bin/arch-analyzer", "example", checkout, True,
        output_dir=output_dir,
    )

    assert extract["success"] is True
    assert render["success"] is True
    assert schemas["success"] is True
    assert (output_dir / "component-architecture.json").is_file()
    assert (output_dir / "analyzer_architecture.md").is_file()
    assert (output_dir / "contracts" / "schemas" / "example.v1.json").is_file()
    assert not (checkout / "component-architecture.json").exists()
    assert not (checkout / "analyzer_architecture.md").exists()
    assert calls[0][4] == str(output_dir / "component-architecture.json")
    assert calls[1][5] == str(output_dir / "analyzer_architecture.md")
    assert calls[2][4] == str(output_dir / "contracts" / "schemas")


def test_analyzer_output_dir_is_platform_scoped(tmp_path: Path):
    assert static_analysis.analyzer_output_dir(
        tmp_path, "rhoai.next", "example",
    ) == (tmp_path / "rhoai.next" / "example" / ".analyzer").resolve()


def test_render_cache_valid_without_component_map(tmp_path: Path):
    assert static_analysis._render_cache_valid(tmp_path, None) is True


def test_render_cache_invalid_when_component_map_introduced(tmp_path: Path):
    cmap = tmp_path / "component-map.json"
    cmap.write_text('{"components": {}}')
    assert static_analysis._render_cache_valid(tmp_path, cmap) is False


def test_render_cache_valid_after_write(tmp_path: Path):
    cmap = tmp_path / "component-map.json"
    cmap.write_text('{"components": {}}')
    static_analysis._write_render_meta(tmp_path, cmap)
    assert static_analysis._render_cache_valid(tmp_path, cmap) is True


def test_render_cache_invalid_when_component_map_changes(tmp_path: Path):
    cmap = tmp_path / "component-map.json"
    cmap.write_text('{"components": {}}')
    static_analysis._write_render_meta(tmp_path, cmap)
    cmap.write_text('{"components": {}, "provenance": {"repos": {}}}')
    assert static_analysis._render_cache_valid(tmp_path, cmap) is False


def test_render_cache_invalid_when_component_map_removed(tmp_path: Path):
    cmap = tmp_path / "component-map.json"
    cmap.write_text('{"components": {}}')
    static_analysis._write_render_meta(tmp_path, cmap)
    cmap.unlink()
    assert static_analysis._render_cache_valid(tmp_path, cmap) is False


@pytest.mark.asyncio
async def test_run_render_invalidates_cache_on_component_map_change(
    tmp_path: Path, monkeypatch: pytest.MonkeyPatch,
):
    (tmp_path / "component-architecture.json").write_text("{}\n")
    (tmp_path / "analyzer_architecture.md").write_text("# stale\n")
    cmap = tmp_path / "component-map.json"
    cmap.write_text('{"components": {}}')
    calls = []

    async def fake_subprocess(*args, cwd, **kwargs):
        calls.append(args)
        (Path(cwd) / "analyzer_architecture.md").write_text("# fresh\n")
        return FakeProcess()

    monkeypatch.setattr(
        static_analysis.asyncio, "create_subprocess_exec", fake_subprocess,
    )
    result = await static_analysis._run_render(
        "/bin/arch-analyzer", "example", tmp_path, force=False,
        component_map_path=cmap,
    )
    assert result["success"] is True
    assert len(calls) == 1
    assert (tmp_path / ".render_meta.json").is_file()
