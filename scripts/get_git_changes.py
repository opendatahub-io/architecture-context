#!/usr/bin/env python3
"""
Extract git information from a repository.

Usage:
    python scripts/get_git_changes.py /path/to/repo [--since="3 months ago"]
    python scripts/get_git_changes.py /path/to/repo --format=metadata
"""

import argparse
import json
import re
import subprocess
import sys
from pathlib import Path
from typing import Optional


def get_version_from_makefile(makefile_path: Path) -> Optional[str]:
    """Extract VERSION from Makefile"""
    if not makefile_path.exists():
        return None

    try:
        content = makefile_path.read_text()
        # Match: VERSION = 3.3.0, VERSION ?= 3.3.0, VERSION := 3.3.0
        # Allow leading whitespace (for indented blocks like ifeq)
        # Capture version number (non-whitespace, non-comment) and ignore trailing comments
        match = re.search(r'^\s*VERSION\s*[\?:]?=\s*([^\s#]+)', content, re.MULTILINE)
        if match:
            version = match.group(1).strip()
            # Remove common quote characters if present
            version = version.strip('"').strip("'")
            # Also remove potential parentheses or other wrapper characters
            version = version.strip('(').strip(')')
            if version:  # Make sure we still have something after stripping
                return version
    except Exception:
        pass

    return None


def get_version_from_version_file(repo_path: Path) -> Optional[str]:
    """Extract version from VERSION or version.txt file"""
    for filename in ['VERSION', 'version.txt']:
        version_file = repo_path / filename
        if version_file.exists():
            try:
                return version_file.read_text().strip()
            except Exception:
                pass

    return None


def get_version_from_git_describe(repo_path: Path) -> Optional[str]:
    """Extract version from git describe (fallback only)"""
    try:
        result = subprocess.run(
            ['git', '-C', str(repo_path), 'describe', '--tags', '--always'],
            capture_output=True,
            text=True,
            check=False
        )
        if result.returncode == 0:
            version = result.stdout.strip()
            # Strip 'v' prefix if present
            if version.startswith('v'):
                version = version[1:]
            return version
    except Exception:
        pass

    return None


def get_git_version(repo_path: Path) -> str:
    """
    Get version from repository with correct priority.

    Priority:
    1. Makefile VERSION (primary - developer's intended version)
    2. VERSION or version.txt file
    3. git describe --tags --always (fallback)
    4. "unknown"

    Returns:
        Version string or "unknown" if unavailable
    """
    # Try Makefile first (primary source)
    makefile_path = repo_path / 'Makefile'
    version = get_version_from_makefile(makefile_path)
    if version:
        return version

    # Try VERSION file
    version = get_version_from_version_file(repo_path)
    if version:
        return version

    # Try git describe (fallback)
    version = get_version_from_git_describe(repo_path)
    if version:
        return version

    return "unknown"


def get_current_branch(repo_path: Path) -> str:
    """Get current git branch name."""
    try:
        result = subprocess.run(
            ['git', '-C', str(repo_path), 'rev-parse', '--abbrev-ref', 'HEAD'],
            capture_output=True,
            text=True,
            check=True
        )
        return result.stdout.strip()
    except subprocess.CalledProcessError:
        return "unknown"


def get_remote_url(repo_path: Path) -> str:
    """Get git remote URL."""
    try:
        result = subprocess.run(
            ['git', '-C', str(repo_path), 'config', '--get', 'remote.origin.url'],
            capture_output=True,
            text=True,
            check=True
        )
        return result.stdout.strip()
    except subprocess.CalledProcessError:
        return "unknown"


def get_recent_commits(repo_path: Path, since: str = "3 months ago", limit: int = 20) -> list[str]:
    """
    Get recent commit messages from a git repository.

    Args:
        repo_path: Path to the git repository
        since: Time period to look back (e.g., "3 months ago", "2024-01-01")
        limit: Maximum number of commits to return

    Returns:
        List of commit messages in format "hash subject"
    """
    try:
        result = subprocess.run(
            [
                'git',
                '-C', str(repo_path),
                'log',
                f'--since={since}',
                '--pretty=format:%h %s',
                '--no-merges'
            ],
            capture_output=True,
            text=True,
            check=True
        )

        commits = result.stdout.strip().split('\n')
        # Filter out empty lines and limit
        commits = [c for c in commits if c.strip()][:limit]

        return commits

    except subprocess.CalledProcessError as e:
        print(f"Error: Failed to get git log from {repo_path}", file=sys.stderr)
        print(f"Error message: {e.stderr}", file=sys.stderr)
        return []
    except Exception as e:
        print(f"Error: {e}", file=sys.stderr)
        return []


def get_metadata(repo_path: Path, since: str = "3 months ago", limit: int = 20) -> dict:
    """
    Get comprehensive git metadata for a repository.

    Returns:
        Dictionary with version, branch, remote_url, and recent commits
    """
    return {
        'version': get_git_version(repo_path),
        'branch': get_current_branch(repo_path),
        'remote_url': get_remote_url(repo_path),
        'recent_commits': get_recent_commits(repo_path, since, limit),
        'commit_count': len(get_recent_commits(repo_path, since, limit))
    }


def main():
    parser = argparse.ArgumentParser(
        description='Extract git information from a repository'
    )
    parser.add_argument(
        'repo_path',
        type=Path,
        help='Path to the git repository'
    )
    parser.add_argument(
        '--since',
        default='3 months ago',
        help='Time period to look back (default: "3 months ago")'
    )
    parser.add_argument(
        '--limit',
        type=int,
        default=20,
        help='Maximum number of commits to return (default: 20)'
    )
    parser.add_argument(
        '--format',
        choices=['text', 'count', 'metadata', 'json'],
        default='text',
        help='Output format: text (commit list), count (number only), metadata (human-readable), or json (JSON output)'
    )

    args = parser.parse_args()

    if not args.repo_path.exists():
        print(f"Error: Repository path does not exist: {args.repo_path}", file=sys.stderr)
        return 1

    if not (args.repo_path / '.git').exists():
        print(f"Error: Not a git repository: {args.repo_path}", file=sys.stderr)
        return 1

    if args.format == 'metadata':
        # Comprehensive metadata output
        metadata = get_metadata(args.repo_path, args.since, args.limit)
        print(f"Repository: {args.repo_path}")
        print(f"Version: {metadata['version']}")
        print(f"Branch: {metadata['branch']}")
        print(f"Remote: {metadata['remote_url']}")
        print(f"\nRecent commits ({metadata['commit_count']}):")
        for commit in metadata['recent_commits']:
            print(f"  {commit}")
    elif args.format == 'json':
        # JSON output with all metadata
        metadata = get_metadata(args.repo_path, args.since, args.limit)
        metadata['repo_path'] = str(args.repo_path)
        print(json.dumps(metadata, indent=2))
    elif args.format == 'count':
        commits = get_recent_commits(args.repo_path, args.since, args.limit)
        print(len(commits))
    else:
        # Text format - just commit list
        commits = get_recent_commits(args.repo_path, args.since, args.limit)
        for commit in commits:
            print(commit)

    return 0


if __name__ == '__main__':
    exit(main())
