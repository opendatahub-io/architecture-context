"""Tests for run_claude_container.sh conditional /data/checkouts mount."""

import os
import subprocess
import tempfile
from pathlib import Path

SCRIPT = Path(__file__).resolve().parent.parent / "scripts" / "run_claude_container.sh"


def _dry_run_output(env_override: dict[str, str] | None = None) -> str:
    env = {**os.environ, **(env_override or {})}
    env.setdefault("ANTHROPIC_API_KEY", "test-key")
    result = subprocess.run(
        [str(SCRIPT), "--dry-run", "test prompt"],
        capture_output=True,
        text=True,
        env=env,
    )
    return result.stdout + result.stderr


def _run_patched_script(fake_checkouts_path: str) -> str:
    patched = SCRIPT.read_text().replace("/data/checkouts", fake_checkouts_path)
    script_path = Path(tempfile.mktemp(suffix=".sh"))
    script_path.write_text(patched)
    script_path.chmod(0o755)
    env = {**os.environ, "ANTHROPIC_API_KEY": "test-key"}
    result = subprocess.run(
        [str(script_path), "--dry-run", "test prompt"],
        capture_output=True,
        text=True,
        env=env,
    )
    script_path.unlink()
    return result.stdout + result.stderr


def test_dry_run_reports_checkouts_absent_when_dir_missing():
    combined = _run_patched_script("/tmp/.nonexistent-checkouts-path-for-test")
    assert "not mounted (host dir absent)" in combined


def test_dry_run_includes_checkouts_volume_when_dir_exists():
    with tempfile.TemporaryDirectory() as tmpdir:
        fake_checkouts = Path(tmpdir) / "checkouts"
        fake_checkouts.mkdir()
        combined = _run_patched_script(str(fake_checkouts))
    assert "(ro)" in combined


def test_dry_run_podman_command_contains_volume_flag_when_dir_exists():
    with tempfile.TemporaryDirectory() as tmpdir:
        fake_checkouts = Path(tmpdir) / "checkouts"
        fake_checkouts.mkdir()
        combined = _run_patched_script(str(fake_checkouts))
    assert f"--volume {fake_checkouts}:{fake_checkouts}:ro" in combined


def test_dry_run_podman_command_omits_volume_flag_when_dir_absent():
    combined = _run_patched_script("/tmp/.nonexistent-checkouts-path-for-test")
    assert "--volume /tmp/.nonexistent-checkouts-path-for-test" not in combined


def test_launcher_uses_env_file_without_shell_sourcing():
    source = SCRIPT.read_text()
    assert 'source "$ROOT_DIR/.env"' not in source
    combined = _dry_run_output()
    if (SCRIPT.parent.parent / ".env").is_file():
        assert "--env-file" in combined
