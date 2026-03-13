"""Phase 1: Fetch/clone repositories using gh-org-clone."""

import os
import asyncio
from pathlib import Path


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
    checkouts_path = Path(checkouts_dir).absolute()
    checkouts_path.mkdir(parents=True, exist_ok=True)

    print(f"Fetching repositories from organization: {org}")
    print(f"Target directory: {checkouts_path}")
    if branch:
        print(f"Branch filter: {branch}")

    cmd = ["gh-org-clone", "-path", str(checkouts_path)]

    if branch:
        cmd.extend(["-branch", branch])

    cmd.append(org)

    print(f"Running: {' '.join(cmd)}")

    proc = await asyncio.create_subprocess_exec(
        *cmd,
        stdout=asyncio.subprocess.PIPE,
        stderr=asyncio.subprocess.PIPE,
    )

    stdout, stderr = await proc.communicate()

    if proc.returncode != 0:
        print(f"Error cloning repositories: {stderr.decode()}")
        raise RuntimeError(f"gh-org-clone failed with exit code {proc.returncode}")

    print(f"Successfully cloned repositories from {org}")
    if stdout:
        print(stdout.decode())
