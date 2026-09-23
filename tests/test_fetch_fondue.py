"""Regression tests for the update-fondue-overlays fetch script.

Each test runs the real script against isolated Git fixtures. A `git` wrapper
on PATH rewrites the Fondue remote to a local bare repository for the commands
that talk to it (fetch, clone, pull, ls-remote) only, so `git remote get-url
origin` still reports the allowlisted URL and no test touches the network.
"""

import shutil
import subprocess
from pathlib import Path

import pytest

SCRIPT = (
    Path(__file__).resolve().parent.parent
    / ".claude/skills/update-fondue-overlays/scripts/fetch-fondue.sh"
)
REMOTE_URL = "https://gitlab.com/redhat/rhel-ai/wheels/fondue.git"
LAYOUT = ("images/base", "images/builder", "builder", "rhai-pipeline", "releases")
REAL_GIT = shutil.which("git")

pytestmark = pytest.mark.skipif(
    REAL_GIT is None or shutil.which("bash") is None,
    reason="requires git and bash",
)

GIT_WRAPPER = """#!/usr/bin/env bash
set -euo pipefail
for arg in "$@"; do
    case "${{arg}}" in
        fetch|clone|pull|ls-remote)
            exec "{real_git}" \\
                -c "url.file://${{FAKE_FONDUE_UPSTREAM}}.insteadOf={remote}" "$@"
            ;;
    esac
done
exec "{real_git}" "$@"
"""


class Fixture:
    """An upstream Fondue repository and a working directory for the script."""

    def __init__(self, root: Path):
        self.root = root
        self.upstream = root / "upstream.git"
        self.seed = root / "seed"
        self.workdir = root / "architecture-context"
        self.cache = self.workdir / "tmp" / "fondue"
        home = root / "home"
        home.mkdir()
        gitconfig = root / "gitconfig"
        gitconfig.write_text(
            "[user]\n\tname = Test\n\temail = test@example.com\n"
            "[init]\n\tdefaultBranch = main\n"
            "[pull]\n\trebase = false\n"
        )
        bin_dir = root / "bin"
        bin_dir.mkdir()
        wrapper = bin_dir / "git"
        wrapper.write_text(GIT_WRAPPER.format(real_git=REAL_GIT, remote=REMOTE_URL))
        wrapper.chmod(0o755)
        self.env = {
            "HOME": str(home),
            "PATH": f"{bin_dir}:/usr/bin:/bin",
            "GIT_CONFIG_GLOBAL": str(gitconfig),
            "GIT_CONFIG_NOSYSTEM": "1",
            "GIT_TERMINAL_PROMPT": "0",
            "FAKE_FONDUE_UPSTREAM": str(self.upstream),
        }
        self.workdir.mkdir()
        self.git("init", "--quiet", str(self.seed))
        for sub in LAYOUT:
            (self.seed / sub).mkdir(parents=True)
            (self.seed / sub / "README").write_text(f"{sub}\n")
        self.git("add", ".", cwd=self.seed)
        self.git("commit", "--quiet", "-m", "initial", cwd=self.seed)
        self.git("clone", "--quiet", "--bare", str(self.seed), str(self.upstream))

    def git(self, *args: str, cwd: Path | None = None) -> str:
        result = subprocess.run(
            [REAL_GIT, *args],
            cwd=cwd or self.root,
            env=self.env,
            check=True,
            capture_output=True,
            text=True,
        )
        return result.stdout.strip()

    def upstream_commit(self, message: str = "upstream change") -> str:
        """Adds a commit to upstream main and returns its id."""
        readme = self.seed / "builder" / "README"
        readme.write_text(readme.read_text() + f"{message}\n")
        self.git("commit", "--quiet", "-am", message, cwd=self.seed)
        self.git("push", "--quiet", str(self.upstream), "main", cwd=self.seed)
        return self.upstream_head()

    def upstream_head(self) -> str:
        return self.git("rev-parse", "main", cwd=self.upstream)

    def clone(self, dest: Path, origin: str = REMOTE_URL) -> Path:
        """Clones upstream main to dest and points its origin at `origin`."""
        dest.parent.mkdir(parents=True, exist_ok=True)
        self.git("clone", "--quiet", "--branch", "main", str(self.upstream), str(dest))
        self.git("remote", "set-url", "origin", origin, cwd=dest)
        return dest

    def head(self, repo: Path) -> str:
        return self.git("rev-parse", "HEAD", cwd=repo)

    def branch(self, repo: Path) -> str:
        return self.git("rev-parse", "--abbrev-ref", "HEAD", cwd=repo)

    def run(self, **extra_env: str) -> subprocess.CompletedProcess:
        return subprocess.run(
            ["bash", str(SCRIPT)],
            cwd=self.workdir,
            env={**self.env, **extra_env},
            capture_output=True,
            text=True,
            timeout=120,
        )


@pytest.fixture
def fondue(tmp_path: Path) -> Fixture:
    return Fixture(tmp_path)


def assert_returned(result: subprocess.CompletedProcess, path: Path) -> None:
    assert result.returncode == 0, result.stderr
    assert result.stdout == f"{path.resolve()}\n"


def assert_rejected(result: subprocess.CompletedProcess) -> None:
    assert result.returncode != 0
    assert result.stdout == ""


def test_fresh_clone_is_validated_and_returned(fondue: Fixture):
    result = fondue.run()

    assert_returned(result, fondue.cache)
    assert fondue.head(fondue.cache) == fondue.upstream_head()
    assert fondue.branch(fondue.cache) == "main"


def test_current_cache_is_returned_unchanged(fondue: Fixture):
    fondue.clone(fondue.cache)
    before = fondue.head(fondue.cache)

    result = fondue.run()

    assert_returned(result, fondue.cache)
    assert fondue.head(fondue.cache) == before


def test_behind_cache_is_fast_forwarded_to_fetched_main(fondue: Fixture):
    fondue.clone(fondue.cache)
    new_main = fondue.upstream_commit()

    result = fondue.run()

    assert_returned(result, fondue.cache)
    assert fondue.head(fondue.cache) == new_main


def make_dirty(fondue: Fixture) -> None:
    (fondue.cache / "builder" / "README").write_text("local edit\n")


def make_untracked(fondue: Fixture) -> None:
    (fondue.cache / "builder" / "local.txt").write_text("local file\n")


def make_other_branch(fondue: Fixture) -> None:
    fondue.git("checkout", "--quiet", "-b", "feature", cwd=fondue.cache)


def make_other_branch_dirty(fondue: Fixture) -> None:
    # The reported bypass: an allowlisted origin, a non-main branch tracking
    # origin/main and a modified tracked file that upstream does not touch, so
    # `git pull --ff-only` (pull.rebase=false) succeeds and the old script
    # returned this checkout.
    fondue.git("checkout", "--quiet", "-b", "feature", cwd=fondue.cache)
    fondue.git("branch", "--quiet", "--set-upstream-to=origin/main", cwd=fondue.cache)
    (fondue.cache / "images" / "base" / "README").write_text("local edit\n")
    fondue.upstream_commit()


def make_detached(fondue: Fixture) -> None:
    fondue.git("checkout", "--quiet", "--detach", cwd=fondue.cache)


def make_ahead(fondue: Fixture) -> None:
    (fondue.cache / "builder" / "local.txt").write_text("local commit\n")
    fondue.git("add", ".", cwd=fondue.cache)
    fondue.git("commit", "--quiet", "-m", "local", cwd=fondue.cache)


def make_diverged(fondue: Fixture) -> None:
    make_ahead(fondue)
    fondue.upstream_commit()


@pytest.mark.parametrize(
    "corrupt",
    [
        make_dirty,
        make_untracked,
        make_other_branch,
        make_other_branch_dirty,
        make_detached,
        make_ahead,
        make_diverged,
    ],
)
def test_unacceptable_cache_is_rejected_and_left_untouched(fondue: Fixture, corrupt):
    fondue.clone(fondue.cache)
    corrupt(fondue)
    head, branch = fondue.head(fondue.cache), fondue.branch(fondue.cache)
    status = fondue.git("status", "--porcelain", cwd=fondue.cache)

    result = fondue.run()

    assert_rejected(result)
    assert fondue.head(fondue.cache) == head
    assert fondue.branch(fondue.cache) == branch
    assert fondue.git("status", "--porcelain", cwd=fondue.cache) == status


def test_cache_with_wrong_origin_is_rejected_without_leaking_credentials(
    fondue: Fixture,
):
    fondue.clone(fondue.cache, origin="https://user:s3cret@example.com/fondue.git")

    result = fondue.run()

    assert_rejected(result)
    assert "s3cret" not in result.stderr
    assert "https://example.com/fondue.git" in result.stderr


def test_cache_that_is_not_a_repository_is_rejected(fondue: Fixture):
    fondue.cache.mkdir(parents=True)
    (fondue.cache / "README").write_text("not a clone\n")

    result = fondue.run()

    assert_rejected(result)
    assert not (fondue.cache / ".git").exists()


def test_cache_fetch_failure_fails_closed(fondue: Fixture):
    fondue.clone(fondue.cache)

    result = fondue.run(FAKE_FONDUE_UPSTREAM=str(fondue.root / "missing.git"))

    assert_rejected(result)
    assert "could not fetch" in result.stderr


def test_clone_failure_fails_closed(fondue: Fixture):
    result = fondue.run(FAKE_FONDUE_UPSTREAM=str(fondue.root / "missing.git"))

    assert_rejected(result)


def test_clone_missing_layout_is_rejected(fondue: Fixture):
    fondue.git("rm", "-r", "--quiet", "releases", cwd=fondue.seed)
    fondue.git("commit", "--quiet", "-m", "drop releases", cwd=fondue.seed)
    fondue.git("push", "--quiet", str(fondue.upstream), "main", cwd=fondue.seed)

    result = fondue.run()

    assert_rejected(result)
    assert "missing part of the fondue layout" in result.stderr


def test_current_fondue_path_is_returned(fondue: Fixture):
    checkout = fondue.clone(fondue.root / "my-fondue")

    result = fondue.run(FONDUE_PATH=str(checkout))

    assert_returned(result, checkout)


def test_behind_fondue_path_is_rejected_not_updated(fondue: Fixture):
    checkout = fondue.clone(fondue.root / "my-fondue")
    before = fondue.head(checkout)
    fondue.upstream_commit()

    result = fondue.run(FONDUE_PATH=str(checkout))

    assert_rejected(result)
    assert fondue.head(checkout) == before
    assert not fondue.cache.exists()
