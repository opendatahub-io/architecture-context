"""Phase 1: Fetch/clone repositories using gh-org-clone."""

import asyncio
import os
import shutil
from pathlib import Path

import yaml


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


def load_platform_config(platform: str, config_path: str = "platforms.yaml") -> dict:
    """
    Load platform configuration from platforms.yaml.

    Args:
        platform: Platform name (e.g., 'odh', 'rhoai')
        config_path: Path to the platforms.yaml file

    Returns:
        Platform config dict

    Raises:
        FileNotFoundError: If platforms.yaml doesn't exist
        KeyError: If platform isn't defined in the config
    """
    config_file = Path(config_path)
    if not config_file.exists():
        raise FileNotFoundError(f"Platform config not found: {config_path}")

    with open(config_file) as f:
        config = yaml.safe_load(f)

    if platform not in config:
        available = ", ".join(sorted(config.keys()))
        raise KeyError(
            f"Platform '{platform}' not found in"
            f" {config_path}. Available: {available}"
        )

    return config[platform]


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
        raise RuntimeError(
            f"Build succeeded but binary not found"
            f" at {local_gh_org_clone}"
        )

    print(f"Successfully built and installed gh-org-clone to {local_gh_org_clone}")

    # Add to PATH for this session
    os.environ["PATH"] = f"{local_bin}:{os.environ.get('PATH', '')}"

    return str(local_gh_org_clone)


async def _pull_one_repo(repo_path: Path, env: dict) -> str:
    """Pull a single repo. Returns a status line."""
    proc = await asyncio.create_subprocess_exec(
        "git", "pull", "--ff-only",
        cwd=str(repo_path),
        stdout=asyncio.subprocess.PIPE,
        stderr=asyncio.subprocess.PIPE,
        env=env,
    )
    stdout, stderr = await proc.communicate()
    name = repo_path.name
    if proc.returncode == 0:
        out = stdout.decode().strip()
        if "Already up to date" in out:
            return f"  {name}: up to date"
        return f"  {name}: updated"
    return f"  {name}: pull failed ({stderr.decode().strip()})"


async def _pull_existing_repos(checkouts_dir: Path, org: str, suffix: str = None,
                               max_concurrent: int = 10) -> None:
    """Pull latest changes in all existing repos for an org, concurrently."""
    org_dir = f"{org}.{suffix}" if suffix else org
    org_path = checkouts_dir / org_dir

    if not org_path.exists():
        return

    env = _prepare_env()
    repos = sorted(
        p for p in org_path.iterdir()
        if p.is_dir() and (p / ".git").exists()
    )

    if not repos:
        return

    total = len(repos)
    print(
        f"\nPulling {total} existing repos in"
        f" {org_dir} ({max_concurrent} concurrent)..."
    )

    sem = asyncio.Semaphore(max_concurrent)
    done = 0

    async def _limited_pull(repo_path):
        nonlocal done
        async with sem:
            result = await _pull_one_repo(repo_path, env)
        done += 1
        print(f"  [{done}/{total}] {result.strip()}")
        return result

    await asyncio.gather(*[_limited_pull(r) for r in repos])


async def _clone_org(
    gh_org_clone_cmd: str,
    org: str,
    checkouts_dir: Path,
    branch: str = None,
    suffix: str = None,
    exclude: str = None,
) -> None:
    """Clone all repositories from a single GitHub org.

    Args:
        gh_org_clone_cmd: Path to gh-org-clone binary
        org: GitHub org name
        checkouts_dir: Base checkouts directory
        branch: Optional branch to clone
        suffix: Optional directory suffix (e.g., org.suffix/)
        exclude: Comma-separated glob patterns to exclude
    """
    if suffix:
        print(f"\nFetching repositories from organization: {org}")
        print(f"Target directory: {checkouts_dir}/{org}.{suffix}")
    else:
        print(f"\nFetching repositories from organization: {org}")
        print(f"Target directory: {checkouts_dir}/{org}")
    if branch:
        print(f"Branch filter: {branch}")
    if exclude:
        print(f"Exclude patterns: {exclude}")

    cmd = [gh_org_clone_cmd, "-path", str(checkouts_dir)]

    if branch:
        cmd.extend(["-branch", branch])
    if suffix:
        cmd.extend(["-suffix", suffix])
    if exclude:
        cmd.extend(["-exclude", exclude])

    cmd.append(org)

    print(f"Running: {' '.join(cmd)}")

    env = _prepare_env()

    proc = await asyncio.create_subprocess_exec(
        *cmd,
        stdout=None,
        stderr=None,
        env=env,
    )

    returncode = await proc.wait()

    if returncode != 0:
        raise RuntimeError(
            f"gh-org-clone failed with exit code"
            f" {returncode} for org {org}"
        )

    print(f"Successfully cloned repositories from {org}")


async def _clone_repo(
    checkouts_dir: Path,
    org: str,
    repo: str,
    branch: str = None,
    suffix: str = None,
    pull: bool = False,
) -> None:
    """Clone an individual repository."""
    org_dir = f"{org}.{suffix}" if suffix else org
    repo_path = checkouts_dir / org_dir / repo

    if repo_path.exists():
        if pull and (repo_path / ".git").exists():
            env = _prepare_env()
            proc = await asyncio.create_subprocess_exec(
                "git", "pull", "--ff-only",
                cwd=str(repo_path),
                stdout=asyncio.subprocess.PIPE,
                stderr=asyncio.subprocess.PIPE,
                env=env,
            )
            stdout, stderr = await proc.communicate()
            if proc.returncode == 0:
                out = stdout.decode().strip()
                if "Already up to date" in out:
                    print(f"  {org}/{repo}: up to date")
                else:
                    print(f"  {org}/{repo}: updated")
            else:
                print(f"  {org}/{repo}: pull failed ({stderr.decode().strip()})")
        else:
            print(f"  Skipped {org}/{repo} (already exists)")
        return

    clone_url = f"https://github.com/{org}/{repo}.git"
    print(f"  Cloning {org}/{repo}...")

    repo_path.parent.mkdir(parents=True, exist_ok=True)

    cmd = ["git", "clone"]
    if branch:
        cmd.extend(["-b", branch])
    cmd.extend([clone_url, str(repo_path)])

    env = _prepare_env()

    proc = await asyncio.create_subprocess_exec(
        *cmd,
        stdout=None,
        stderr=None,
        env=env,
    )

    returncode = await proc.wait()

    if returncode != 0:
        if branch:
            print(f"  Skipped {org}/{repo} (branch '{branch}' not found)")
        else:
            print(f"  Failed to clone {org}/{repo}")


async def fetch_repositories(
    org: str = None,
    checkouts_dir: str = "checkouts",
    branch: str = None,
    suffix: str = None,
    exclude: str = None,
    platform: str = None,
    pull: bool = False,
) -> None:
    """
    Clone repositories using gh-org-clone.

    Can be called with either a single org name, or a platform name
    which loads orgs/extras/exclusions from platforms.yaml.

    Args:
        org: GitHub organization name (used when platform is not set)
        checkouts_dir: Base directory for cloning repositories
        branch: Optional specific branch to clone (skips repos without this branch)
        suffix: Optional suffix for the org directory (e.g., "head" -> <org>.head/).
                When branch is set but suffix is not, suffix defaults to branch.
        exclude: Comma-separated glob patterns to exclude repos
        platform: Platform name to load config from platforms.yaml
        pull: If True, pull latest changes in existing repos
    """
    gh_org_clone_cmd = await _ensure_gh_org_clone()

    checkouts_path = Path(checkouts_dir).absolute()
    checkouts_path.mkdir(parents=True, exist_ok=True)

    if platform:
        config = load_platform_config(platform)

        # Branch precedence: CLI --branch > config branch
        if not branch:
            branch = config.get("branch")

        # Suffix precedence: CLI --suffix > config suffix > branch fallback
        if not suffix:
            suffix = config.get("suffix")
            if not suffix and branch:
                suffix = branch

        # Merge exclude patterns from config and CLI
        config_excludes = config.get("exclude_repos", [])
        all_excludes = list(config_excludes)
        if exclude:
            all_excludes.extend(exclude.split(","))
        exclude_str = ",".join(all_excludes) if all_excludes else None

        # Clone primary orgs (with branch + suffix)
        orgs = config.get("orgs", [])
        for cfg_org in orgs:
            await _clone_org(gh_org_clone_cmd, cfg_org, checkouts_path,
                             branch=branch, suffix=suffix, exclude=exclude_str)
            if pull:
                await _pull_existing_repos(checkouts_path, cfg_org, suffix=suffix)

        # Clone extra orgs — per-entry overrides, falling back to platform suffix
        extra_orgs = config.get("extra_orgs", [])
        for entry in extra_orgs:
            org_name = entry.get("org") if isinstance(entry, dict) else entry
            org_branch = entry.get("branch") if isinstance(entry, dict) else None
            org_suffix = (
                entry.get("suffix")
                if isinstance(entry, dict)
                else None
            ) or suffix
            await _clone_org(gh_org_clone_cmd, org_name, checkouts_path,
                             branch=org_branch, suffix=org_suffix, exclude=exclude_str)
            if pull:
                await _pull_existing_repos(checkouts_path, org_name, suffix=org_suffix)

        # Clone individual extra repos -- per-entry overrides,
        # falling back to platform suffix
        extra_repos = config.get("extra_repos", [])
        if extra_repos:
            print(f"\nCloning {len(extra_repos)} extra repo(s)...")
            for entry in extra_repos:
                repo_branch = entry.get("branch")
                repo_suffix = entry.get("suffix") or suffix
                await _clone_repo(checkouts_path, entry["org"], entry["repo"],
                                  branch=repo_branch, suffix=repo_suffix, pull=pull)

    elif org:
        # Direct org mode (original behavior)
        if branch and not suffix:
            suffix = branch

        await _clone_org(gh_org_clone_cmd, org, checkouts_path,
                         branch=branch, suffix=suffix, exclude=exclude)
        if pull:
            await _pull_existing_repos(checkouts_path, org, suffix=suffix)

    else:
        raise ValueError("Either 'org' or '--platform' must be specified")
