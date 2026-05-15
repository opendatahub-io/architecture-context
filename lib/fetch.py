"""Phase 1: Fetch/clone repositories using gh-org-clone."""

import asyncio
import fnmatch
import os
import shutil
from datetime import datetime, timezone
from pathlib import Path

import yaml

_log_file = None


def _log(msg: str) -> None:
    print(msg)
    if _log_file is not None:
        _log_file.write(msg + "\n")
        _log_file.flush()


def _prepare_env() -> dict:
    """
    Prepare environment variables for subprocess calls.

    Includes GITHUB_TOKEN if set in environment (e.g., from .env file).
    Sets GIT_TERMINAL_PROMPT=0 so git never blocks waiting for
    credentials — failed auth surfaces as a clone error instead.

    Returns:
        Dictionary of environment variables to pass to subprocess
    """
    env = os.environ.copy()
    env["GIT_TERMINAL_PROMPT"] = "0"
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
        _log(f"Found gh-org-clone in PATH: {gh_org_clone_path}")
        return "gh-org-clone"

    # Check if it's already installed in ./bin
    local_bin = Path("bin").absolute()
    local_gh_org_clone = local_bin / "gh-org-clone"
    if local_gh_org_clone.exists():
        _log(f"Found gh-org-clone in ./bin: {local_gh_org_clone}")
        # Add to PATH for this session
        os.environ["PATH"] = f"{local_bin}:{os.environ.get('PATH', '')}"
        return str(local_gh_org_clone)

    # Not found - need to clone and build
    _log("gh-org-clone not found in PATH or ./bin")
    _log("Installing gh-org-clone from https://github.com/jctanner/gh-org-clone")

    tmp_dir = Path("tmp").absolute()
    tmp_dir.mkdir(parents=True, exist_ok=True)

    clone_dir = tmp_dir / "gh-org-clone"

    # Prepare environment with GITHUB_TOKEN if available
    env = _prepare_env()

    # Clone the repository if not already present
    if not clone_dir.exists():
        _log(f"Cloning to {clone_dir}...")
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
        _log("Clone successful")
    else:
        _log(f"Using existing clone at {clone_dir}")

    # Build the project (assuming it's a Go project)
    _log("Building gh-org-clone...")
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

    _log(f"Successfully built and installed gh-org-clone to {local_gh_org_clone}")

    # Add to PATH for this session
    os.environ["PATH"] = f"{local_bin}:{os.environ.get('PATH', '')}"

    return str(local_gh_org_clone)


async def _ensure_arch_analyzer() -> str:
    """
    Ensure arch-analyzer is available, installing it if necessary.

    Returns:
        Path to the arch-analyzer executable
    """
    arch_analyzer_name = "arch-analyzer"

    # First check if it's already in PATH
    arch_analyzer_path = shutil.which(arch_analyzer_name)
    if arch_analyzer_path:
        _log(f"Found {arch_analyzer_name} in PATH: {arch_analyzer_path}")
        return arch_analyzer_name

    # Check if it's already installed in ./bin
    local_bin = Path("bin").absolute()
    local_arch_analyzer = local_bin / arch_analyzer_name
    if local_arch_analyzer.exists():
        _log(f"Found {arch_analyzer_name} in ./bin: {local_arch_analyzer}")
        os.environ["PATH"] = f"{local_bin}:{os.environ.get('PATH', '')}"
        return str(local_arch_analyzer)

    # Not found - need to clone and build
    _log(f"{arch_analyzer_name} not found in PATH or ./bin")
    _log("Installing arch-analyzer from https://github.com/ugiordan/architecture-analyzer")

    tmp_dir = Path("tmp").absolute()
    tmp_dir.mkdir(parents=True, exist_ok=True)

    clone_dir = tmp_dir / "architecture-analyzer"

    env = _prepare_env()

    # Clone the repository if not already present
    if not clone_dir.exists():
        _log(f"Cloning to {clone_dir}...")
        proc = await asyncio.create_subprocess_exec(
            "git", "clone",
            "https://github.com/ugiordan/architecture-analyzer",
            str(clone_dir),
            stdout=asyncio.subprocess.PIPE,
            stderr=asyncio.subprocess.PIPE,
            env=env,
        )
        stdout, stderr = await proc.communicate()
        if proc.returncode != 0:
            raise RuntimeError(
                "Failed to clone architecture-analyzer:"
                f" {stderr.decode()}"
            )
        _log("Clone successful")
    else:
        _log(f"Using existing clone at {clone_dir}")

    # Build the project
    _log("Building arch-analyzer...")
    local_bin.mkdir(parents=True, exist_ok=True)
    proc = await asyncio.create_subprocess_exec(
        "go", "build", "-o", str(local_arch_analyzer), "./cmd/arch-analyzer",
        cwd=str(clone_dir),
        stdout=asyncio.subprocess.PIPE,
        stderr=asyncio.subprocess.PIPE,
        env=env,
    )
    stdout, stderr = await proc.communicate()
    if proc.returncode != 0:
        raise RuntimeError(f"Failed to build arch-analyzer: {stderr.decode()}")

    if not local_arch_analyzer.exists():
        raise RuntimeError(
            f"Build succeeded but binary not found"
            f" at {local_arch_analyzer}"
        )

    _log(f"Successfully built and installed arch-analyzer to {local_arch_analyzer}")

    os.environ["PATH"] = f"{local_bin}:{os.environ.get('PATH', '')}"

    return str(local_arch_analyzer)


async def _ensure_arch_query() -> str:
    """
    Ensure arch-query is available, building from in-repo source if necessary.

    Returns:
        Path to the arch-query executable
    """
    name = "arch-query"

    path = shutil.which(name)
    if path:
        _log(f"Found {name} in PATH: {path}")
        return name

    local_bin = Path("bin").absolute()
    local_binary = local_bin / name
    if local_binary.exists():
        _log(f"Found {name} in ./bin: {local_binary}")
        os.environ["PATH"] = f"{local_bin}:{os.environ.get('PATH', '')}"
        return str(local_binary)

    _log(f"{name} not found in PATH or ./bin — building from src/arch-query")
    src_dir = Path("src/arch-query").absolute()
    if not src_dir.exists():
        raise RuntimeError(f"Source directory not found: {src_dir}")

    local_bin.mkdir(parents=True, exist_ok=True)
    env = _prepare_env()
    proc = await asyncio.create_subprocess_exec(
        "go", "build", "-o", str(local_binary), ".",
        cwd=str(src_dir),
        stdout=asyncio.subprocess.PIPE,
        stderr=asyncio.subprocess.PIPE,
        env=env,
    )
    _, stderr = await proc.communicate()
    if proc.returncode != 0:
        raise RuntimeError(f"Failed to build {name}: {stderr.decode()}")

    if not local_binary.exists():
        raise RuntimeError(
            f"Build succeeded but binary not found at {local_binary}"
        )

    _log(f"Successfully built {name} to {local_binary}")
    os.environ["PATH"] = f"{local_bin}:{os.environ.get('PATH', '')}"
    return str(local_binary)


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
    _log(
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
        _log(f"  [{done}/{total}] {result.strip()}")
        return result

    await asyncio.gather(*[_limited_pull(r) for r in repos])


async def _clone_org(
    gh_org_clone_cmd: str,
    org: str,
    checkouts_dir: Path,
    branch: str = None,
    suffix: str = None,
    exclude: str = None,
    ssh: bool = False,
) -> None:
    """Clone all repositories from a single GitHub org.

    Args:
        gh_org_clone_cmd: Path to gh-org-clone binary
        org: GitHub org name
        checkouts_dir: Base checkouts directory
        branch: Optional branch to clone
        suffix: Optional directory suffix (e.g., org.suffix/)
        exclude: Comma-separated glob patterns to exclude
        ssh: If True, pass -ssh to gh-org-clone
    """
    if suffix:
        _log(f"\nFetching repositories from organization: {org}")
        _log(f"Target directory: {checkouts_dir}/{org}.{suffix}")
    else:
        _log(f"\nFetching repositories from organization: {org}")
        _log(f"Target directory: {checkouts_dir}/{org}")
    if branch:
        _log(f"Branch filter: {branch}")
    if exclude:
        _log(f"Exclude patterns: {exclude}")

    cmd = [gh_org_clone_cmd, "-path", str(checkouts_dir)]

    if branch:
        cmd.extend(["-branch", branch])
    if suffix:
        cmd.extend(["-suffix", suffix])
    if exclude:
        cmd.extend(["-exclude", exclude])
    if ssh:
        cmd.append("-ssh")

    cmd.append(org)

    _log(f"Running: {' '.join(cmd)}")

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

    _log(f"Successfully cloned repositories from {org}")


def _apply_exclude_files(repo_path: Path, patterns: list, repo_name: str) -> None:
    """Remove files/directories matching glob patterns from a cloned repo."""
    if repo_path.is_symlink():
        raise ValueError(
            f"exclude_files for {repo_name}: repo path is a symlink"
        )
    if not (repo_path / ".git").is_dir():
        raise ValueError(
            f"exclude_files for {repo_name}: not a git checkout"
        )
    if isinstance(patterns, str) or not isinstance(patterns, list):
        raise ValueError(
            f"exclude_files for {repo_name} must be a list of"
            " glob patterns, not a bare string"
        )
    resolved_root = repo_path.resolve()
    for pattern in patterns:
        if ".." in pattern or pattern.startswith("/"):
            _log(f"  exclude_files [{repo_name}]: REJECTED unsafe pattern: {pattern}")
            continue
        matches = sorted(repo_path.glob(pattern))
        if not matches:
            continue
        for match in matches:
            resolved = match.resolve()
            if resolved != resolved_root and not str(resolved).startswith(
                str(resolved_root) + os.sep
            ):
                _log(
                    f"  exclude_files [{repo_name}]:"
                    f" SKIPPED {match} (escapes repo root)"
                )
                continue
            rel = match.relative_to(repo_path)
            if match.is_dir():
                shutil.rmtree(match)
                _log(f"  exclude_files [{repo_name}]: removed directory {rel}/")
            elif match.exists():
                match.unlink()
                _log(f"  exclude_files [{repo_name}]: removed {rel}")


async def _clone_repo(
    checkouts_dir: Path,
    org: str,
    repo: str,
    branch: str = None,
    suffix: str = None,
    pull: bool = False,
    exclude_files: list = None,
    protocol: str = "https",
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
                    _log(f"  {org}/{repo}: up to date")
                else:
                    _log(f"  {org}/{repo}: updated")
            else:
                _log(f"  {org}/{repo}: pull failed ({stderr.decode().strip()})")
        else:
            _log(f"  Skipped {org}/{repo} (already exists)")
        if exclude_files:
            _apply_exclude_files(repo_path, exclude_files, repo)
        return

    if protocol == "ssh":
        clone_url = f"git@github.com:{org}/{repo}.git"
    elif protocol == "https":
        clone_url = f"https://github.com/{org}/{repo}.git"
    else:
        raise ValueError(
            f"Unknown protocol '{protocol}' for {org}/{repo}"
        )
    _log(f"  Cloning {org}/{repo}...")

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
            _log(f"  Skipped {org}/{repo} (branch '{branch}' not found)")
        else:
            _log(f"  Failed to clone {org}/{repo}")
    elif exclude_files:
        _apply_exclude_files(repo_path, exclude_files, repo)


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
    global _log_file
    checkouts_path = Path(checkouts_dir).absolute()
    checkouts_path.mkdir(parents=True, exist_ok=True)
    log_dir = Path("logs").absolute()
    log_dir.mkdir(parents=True, exist_ok=True)
    log_path = log_dir / "fetch.log"
    _log_file = open(log_path, "w")  # noqa: SIM115
    try:
        _log(f"fetch started at {datetime.now(timezone.utc).isoformat()}")

        # Warn-only, not a hard gate: GITHUB_TOKEN improves API rate
        # limits but does not grant visibility to private repos —
        # SSH keys handle that (see extra_repos protocol: ssh).
        if "GITHUB_TOKEN" not in os.environ:
            _log(
                "WARNING: GITHUB_TOKEN is not set. API rate limits"
                " will be restricted to 60 requests/hour."
            )

        gh_org_clone_cmd = await _ensure_gh_org_clone()

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

            platform_org_dirs = set()

            # Clone primary orgs (with branch + suffix)
            orgs = config.get("orgs", [])
            platform_protocol = config.get("protocol", "https")
            use_ssh = platform_protocol == "ssh"
            for cfg_org in orgs:
                org_dir_name = f"{cfg_org}.{suffix}" if suffix else cfg_org
                platform_org_dirs.add(org_dir_name)
                await _clone_org(gh_org_clone_cmd, cfg_org, checkouts_path,
                                 branch=branch, suffix=suffix,
                                 exclude=exclude_str, ssh=use_ssh)
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
                org_protocol = (
                    entry.get("protocol")
                    if isinstance(entry, dict)
                    else None
                ) or platform_protocol
                org_dir_name = f"{org_name}.{org_suffix}" if org_suffix else org_name
                platform_org_dirs.add(org_dir_name)
                await _clone_org(gh_org_clone_cmd, org_name, checkouts_path,
                                 branch=org_branch, suffix=org_suffix,
                                 exclude=exclude_str,
                                 ssh=org_protocol == "ssh")
                if pull:
                    await _pull_existing_repos(
                        checkouts_path, org_name, suffix=org_suffix,
                    )

            # Clone individual extra repos -- per-entry overrides,
            # falling back to platform suffix
            extra_repos = config.get("extra_repos", [])
            if extra_repos:
                _log(f"\nCloning {len(extra_repos)} extra repo(s)...")
                for entry in extra_repos:
                    repo_branch = entry.get("branch")
                    repo_suffix = entry.get("suffix") or suffix
                    org_dir_name = (
                        f"{entry['org']}.{repo_suffix}"
                        if repo_suffix
                        else entry["org"]
                    )
                    platform_org_dirs.add(org_dir_name)
                    await _clone_repo(
                        checkouts_path, entry["org"], entry["repo"],
                        branch=repo_branch, suffix=repo_suffix, pull=pull,
                        exclude_files=entry.get("exclude_files"),
                        protocol=entry.get("protocol", "https"),
                    )

            # Apply platform-wide post_checkout exclude_files rules
            post_checkout = config.get("post_checkout", [])
            if post_checkout:
                for i, rule in enumerate(post_checkout):
                    if "repo" not in rule or "exclude_files" not in rule:
                        raise ValueError(
                            f"post_checkout[{i}]: each entry must have"
                            " 'repo' and 'exclude_files' keys"
                        )
                for org_dir_name in sorted(platform_org_dirs):
                    org_dir = checkouts_path / org_dir_name
                    if not org_dir.is_dir():
                        continue
                    for repo_dir in sorted(org_dir.iterdir()):
                        if not repo_dir.is_dir():
                            continue
                        for rule in post_checkout:
                            if fnmatch.fnmatch(repo_dir.name, rule["repo"]):
                                _apply_exclude_files(
                                    repo_dir, rule["exclude_files"],
                                    repo_dir.name,
                                )

        elif org:
            # Direct org mode (original behavior)
            if branch and not suffix:
                suffix = branch

            await _clone_org(gh_org_clone_cmd, org, checkouts_path,
                             branch=branch, suffix=suffix, exclude=exclude)
            if pull:
                await _pull_existing_repos(checkouts_path, org, suffix=suffix)

        else:
            raise ValueError(
                "Either 'org' or '--platform' must be specified"
            )

        _log(f"fetch finished at {datetime.now(timezone.utc).isoformat()}")
        _log(f"log written to {log_path}")
    finally:
        _log_file.close()
        _log_file = None
