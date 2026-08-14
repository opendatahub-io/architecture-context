"""Tests for glob branch resolution in lib/fetch.py."""

import sys
from pathlib import Path
from unittest.mock import AsyncMock, patch

import pytest

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

from lib.fetch import _resolve_branch_glob, _version_sort_key  # noqa: E402


class TestVersionSortKey:
    def test_single_segment(self):
        assert _version_sort_key("release-2") == (2,)

    def test_two_segments(self):
        assert _version_sort_key("release-1.10") == (1, 10)

    def test_three_segments(self):
        assert _version_sort_key("release-1.10.3") == (1, 10, 3)

    def test_non_numeric_suffix(self):
        assert _version_sort_key("release-main") == ()

    def test_numeric_sorts_correctly(self):
        branches = ["release-1.2", "release-1.10", "release-1.9"]
        result = sorted(branches, key=_version_sort_key)
        assert result == ["release-1.2", "release-1.9", "release-1.10"]

    def test_mixed_numeric_and_non_numeric(self):
        branches = ["release-1.2", "release-main", "release-1.10"]
        result = sorted(branches, key=_version_sort_key)
        assert result[0] == "release-main"
        assert result[-1] == "release-1.10"


class TestResolveBranchGlob:
    @pytest.fixture(autouse=True)
    def _patch_log(self):
        with patch("lib.fetch._log"):
            yield

    def _make_ls_remote_output(self, branches: list[str]) -> bytes:
        lines = []
        for branch in branches:
            lines.append(f"abc123\trefs/heads/{branch}")
        return "\n".join(lines).encode()

    @pytest.mark.asyncio
    async def test_resolves_latest_branch(self):
        output = self._make_ls_remote_output(
            ["release-1.2", "release-1.10", "release-1.9"]
        )
        mock_proc = AsyncMock()
        mock_proc.communicate.return_value = (output, b"")
        mock_proc.returncode = 0

        with patch("asyncio.create_subprocess_exec", return_value=mock_proc):
            result = await _resolve_branch_glob("org", "repo", "release-*")

        assert result == "release-1.10"

    @pytest.mark.asyncio
    async def test_filters_nested_branch_paths(self):
        output = self._make_ls_remote_output([
            "konflux/mintmaker/release-1.1/registry.access.redhat.com-ubi9-ubi-minimal-9.x",
            "konflux/references/release-1.1",
            "release-1.1",
            "release-1.4",
        ])
        mock_proc = AsyncMock()
        mock_proc.communicate.return_value = (output, b"")
        mock_proc.returncode = 0

        with patch("asyncio.create_subprocess_exec", return_value=mock_proc):
            result = await _resolve_branch_glob("org", "repo", "release-*")

        assert result == "release-1.4"

    @pytest.mark.asyncio
    async def test_returns_none_on_no_matches(self):
        mock_proc = AsyncMock()
        mock_proc.communicate.return_value = (b"", b"")
        mock_proc.returncode = 0

        with patch("asyncio.create_subprocess_exec", return_value=mock_proc):
            result = await _resolve_branch_glob("org", "repo", "release-*")

        assert result is None

    @pytest.mark.asyncio
    async def test_returns_none_on_git_failure(self):
        mock_proc = AsyncMock()
        mock_proc.communicate.return_value = (b"", b"error")
        mock_proc.returncode = 128

        with patch("asyncio.create_subprocess_exec", return_value=mock_proc):
            result = await _resolve_branch_glob("org", "repo", "release-*")

        assert result is None

    @pytest.mark.asyncio
    async def test_uses_ssh_url_for_ssh_protocol(self):
        mock_proc = AsyncMock()
        mock_proc.communicate.return_value = (b"", b"")
        mock_proc.returncode = 0

        with patch(
            "asyncio.create_subprocess_exec", return_value=mock_proc
        ) as mock_exec:
            await _resolve_branch_glob(
                "org", "repo", "release-*", protocol="ssh"
            )

        call_args = mock_exec.call_args[0]
        assert "git@github.com:org/repo.git" in call_args
