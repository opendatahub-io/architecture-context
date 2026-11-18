"""Tests for clone-failure diagnostics in lib/fetch.py.

A failed `git clone` with a pinned branch used to be logged as
"branch '<name>' not found" regardless of the real reason. The
2026-11-10 pipeline run hit SSH host-key failures on the runner and
the misleading message produced a false "dead branch" report for
rhods-devops-infra's main branch. These tests pin the corrected
reporting: the true git error is surfaced unless the remote really
is missing the branch.
"""

import sys
from pathlib import Path
from unittest.mock import AsyncMock, patch

import pytest

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

from lib.fetch import _clone_repo, _summarize_clone_error  # noqa: E402


class TestSummarizeCloneError:
    def test_remote_branch_not_found(self):
        stderr = (
            b"Cloning into 'repo'...\n"
            b"fatal: Remote branch rhoai-9.9 not found in upstream origin\n"
        )
        assert (
            _summarize_clone_error(stderr.decode())
            == "branch not found on remote"
        )

    def test_host_key_verification_failure(self):
        stderr = (
            b"Cloning into 'repo'...\n"
            b"Host key verification failed.\n"
            b"fatal: Could not read from remote repository.\n"
        )
        assert (
            _summarize_clone_error(stderr.decode())
            == "Host key verification failed."
        )

    def test_permission_denied(self):
        stderr = (
            b"git@github.com: Permission denied (publickey).\n"
            b"fatal: Could not read from remote repository.\n"
        )
        assert (
            _summarize_clone_error(stderr.decode())
            == "git@github.com: Permission denied (publickey)."
        )

    def test_repository_not_found(self):
        stderr = b"fatal: Repository not found\n"
        assert _summarize_clone_error(stderr.decode()) == "fatal: Repository not found"

    def test_empty_stderr(self):
        assert _summarize_clone_error("") is None

    def test_noise_only_stderr(self):
        assert _summarize_clone_error("Cloning into 'repo'...\n\n") is None

    def test_host_key_warning_does_not_hide_auth_error(self):
        stderr = (
            b"Warning: Permanently added 'github.com' (ED25519) to the "
            b"list of known hosts.\n"
            b"git@github.com: Permission denied (publickey).\n"
            b"fatal: Could not read from remote repository.\n"
        )
        assert (
            _summarize_clone_error(stderr.decode())
            == "git@github.com: Permission denied (publickey)."
        )


def _failed_proc(stderr: bytes, returncode: int = 128) -> AsyncMock:
    proc = AsyncMock()
    proc.communicate.return_value = (b"", stderr)
    proc.returncode = returncode
    return proc


class TestCloneRepoFailureMessages:
    @pytest.fixture(autouse=True)
    def _patch_log(self):
        with patch("lib.fetch._log") as mock_log:
            self.mock_log = mock_log
            yield

    async def _run(self, checkouts_dir, proc, branch="main"):
        with patch("asyncio.create_subprocess_exec", return_value=proc):
            await _clone_repo(
                checkouts_dir,
                "red-hat-data-services",
                "rhods-devops-infra",
                branch=branch,
                suffix="test",
                protocol="ssh",
            )

    @pytest.fixture
    def checkouts(self, tmp_path):
        return tmp_path / "checkouts"

    @pytest.mark.asyncio
    async def test_missing_branch_keeps_skip_wording(self, checkouts):
        stderr = b"fatal: Remote branch main not found in upstream origin\n"
        await self._run(checkouts, _failed_proc(stderr))
        msg = self.mock_log.call_args[0][0]
        assert "branch 'main' not found" in msg
        assert "clone failed" not in msg

    @pytest.mark.asyncio
    async def test_host_key_failure_reports_real_reason(self, checkouts):
        stderr = (
            b"Host key verification failed.\n"
            b"fatal: Could not read from remote repository.\n"
        )
        await self._run(checkouts, _failed_proc(stderr))
        msg = self.mock_log.call_args[0][0]
        assert "clone failed" in msg
        assert "Host key verification failed" in msg
        # The failure must not be misattributed to the branch.
        assert "not found" not in msg

    @pytest.mark.asyncio
    async def test_auth_failure_reports_real_reason(self, checkouts):
        stderr = (
            b"git@github.com: Permission denied (publickey).\n"
            b"fatal: Could not read from remote repository.\n"
        )
        await self._run(checkouts, _failed_proc(stderr))
        msg = self.mock_log.call_args[0][0]
        assert "clone failed" in msg
        assert "Permission denied" in msg
        assert "not found" not in msg

    @pytest.mark.asyncio
    async def test_host_key_warning_does_not_hide_auth_error(self, checkouts):
        stderr = (
            b"Warning: Permanently added 'github.com' (ED25519) to the "
            b"list of known hosts.\n"
            b"git@github.com: Permission denied (publickey).\n"
            b"fatal: Could not read from remote repository.\n"
        )
        await self._run(checkouts, _failed_proc(stderr))
        msg = self.mock_log.call_args[0][0]
        assert "clone failed" in msg
        assert "Permission denied" in msg
        assert "not found" not in msg

    @pytest.mark.asyncio
    async def test_no_stderr_reports_exit_code(self, checkouts):
        await self._run(checkouts, _failed_proc(b""))
        msg = self.mock_log.call_args[0][0]
        assert "clone failed" in msg
        assert "git exited 128" in msg
