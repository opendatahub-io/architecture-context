"""Phase 1: Fetch/clone repositories using gh-org-clone."""

import os
import shutil
import asyncio
from pathlib import Path


def _prepare_env() -> dict:
    """
    Prepare environment variables for subprocess calls.

    Includes GITHUB_TOKEN if set in environment (e.g., from .env file).

    Returns:
        Dictionary of environment variables to pass to subprocess
    """
    env = os.environ.copy()

    # GITHUB_TOKEN is already in env if loaded from .env file
    # Just ensure it's present for subprocess calls
    if "GITHUB_TOKEN" in env:
        print("Using GITHUB_TOKEN from environment")

    return env


async def _ensure_gh_org_clone() -> str:
    """
    Ensure gh-org-clone is available, installing it if necessary.

    Returns:
        Path to the gh-org-clone executable
    """
    # First check if it's already in PATH
    gh_org_clone_path = shutil.which("gh-org-clone")
    if gh_org_clone_path:
        print(f"Found gh-org-clone in PATH: {gh_org_clone_path}")
        return "gh-org-clone"

    # Check if it's already installed in ./bin
    local_bin = Path("bin").absolute()
    local_gh_org_clone = local_bin / "gh-org-clone"
    if local_gh_org_clone.exists():
        print(f"Found gh-org-clone in ./bin: {local_gh_org_clone}")
        # Add to PATH for this session
        os.environ["PATH"] = f"{local_bin}:{os.environ.get('PATH', '')}"
        return str(local_gh_org_clone)

    # Not found - need to clone and build
    print("gh-org-clone not found in PATH or ./bin")
    print("Installing gh-org-clone from https://github.com/jctanner/gh-org-clone")

    tmp_dir = Path("tmp").absolute()
    tmp_dir.mkdir(parents=True, exist_ok=True)

    clone_dir = tmp_dir / "gh-org-clone"

    # Prepare environment with GITHUB_TOKEN if available
    env = _prepare_env()

    # Clone the repository if not already present
    if not clone_dir.exists():
        print(f"Cloning to {clone_dir}...")
        proc = await asyncio.create_subprocess_exec(
            "git", "clone",
            "https://github.com/jctanner/gh-org-clone",
            str(clone_dir),
            stdout=asyncio.subprocess.PIPE,
            stderr=asyncio.subprocess.PIPE,
            env=env,
        )
        stdout, stderr = await proc.communicate()
        if proc.returncode != 0:
            raise RuntimeError(f"Failed to clone gh-org-clone: {stderr.decode()}")
        print("Clone successful")
    else:
        print(f"Using existing clone at {clone_dir}")

    # Build the project (assuming it's a Go project)
    print("Building gh-org-clone...")
    local_bin.mkdir(parents=True, exist_ok=True)
    proc = await asyncio.create_subprocess_exec(
        "go", "build", "-o", str(local_gh_org_clone),
        cwd=str(clone_dir),
        stdout=asyncio.subprocess.PIPE,
        stderr=asyncio.subprocess.PIPE,
        env=env,
    )
    stdout, stderr = await proc.communicate()
    if proc.returncode != 0:
        raise RuntimeError(f"Failed to build gh-org-clone: {stderr.decode()}")

    if not local_gh_org_clone.exists():
        raise RuntimeError(f"Build succeeded but binary not found at {local_gh_org_clone}")

    print(f"Successfully built and installed gh-org-clone to {local_gh_org_clone}")

    # Add to PATH for this session
    os.environ["PATH"] = f"{local_bin}:{os.environ.get('PATH', '')}"

    return str(local_gh_org_clone)


async def fetch_repositories(
    org: str,
    checkouts_dir: str = "checkouts",
    branch: str = None
) -> None:
    """
    Clone all repositories from a GitHub organization using gh-org-clone.

    Args:
        org: GitHub organization name
        checkouts_dir: Base directory for cloning repositories
        branch: Optional specific branch to clone (skips repos without this branch)

    Note:
        When branch is specified, gh-org-clone automatically creates a directory
        named <org>.<branch> inside checkouts_dir. For example:
        - Without branch: checkouts/red-hat-data-services/
        - With branch:    checkouts/red-hat-data-services.rhoai-2.14/
    """
    # Ensure gh-org-clone is available
    gh_org_clone_cmd = await _ensure_gh_org_clone()

    checkouts_path = Path(checkouts_dir).absolute()
    checkouts_path.mkdir(parents=True, exist_ok=True)

    print(f"Fetching repositories from organization: {org}")
    print(f"Target directory: {checkouts_path}")
    if branch:
        print(f"Branch filter: {branch}")

    cmd = [gh_org_clone_cmd, "-path", str(checkouts_path)]

    if branch:
        cmd.extend(["-branch", branch])

    cmd.append(org)

    print(f"Running: {' '.join(cmd)}")

    # Prepare environment with GITHUB_TOKEN if available
    env = _prepare_env()

    proc = await asyncio.create_subprocess_exec(
        *cmd,
        stdout=asyncio.subprocess.PIPE,
        stderr=asyncio.subprocess.PIPE,
        env=env,
    )

    stdout, stderr = await proc.communicate()

    if proc.returncode != 0:
        print(f"Error cloning repositories: {stderr.decode()}")
        raise RuntimeError(f"gh-org-clone failed with exit code {proc.returncode}")

    print(f"Successfully cloned repositories from {org}")
    if stdout:
        print(stdout.decode())
