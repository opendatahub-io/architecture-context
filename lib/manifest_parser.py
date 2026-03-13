"""Phase 3: Parse opendatahub-operator get_all_manifests.sh script."""

import re
import asyncio
from pathlib import Path
from typing import List, Dict, Optional
from dataclasses import dataclass


@dataclass
class ComponentManifest:
    """Represents a component from get_all_manifests.sh."""

    name: str
    repo: str
    branch: Optional[str] = None
    commit: Optional[str] = None
    path: Optional[str] = None


async def read_manifest_script(script_path: Path) -> str:
    """Read the get_all_manifests.sh script content."""
    if not script_path.exists():
        raise FileNotFoundError(f"Script not found: {script_path}")

    return script_path.read_text()


def parse_git_clone_commands(script_content: str) -> List[ComponentManifest]:
    """
    Parse git clone commands from get_all_manifests.sh script.

    Extracts repository URLs, branches, and commits from git clone/checkout commands.

    Args:
        script_content: Content of the get_all_manifests.sh script

    Returns:
        List of ComponentManifest objects
    """
    components = []

    # Pattern to match git clone commands
    # Example: git clone -b branch_name https://github.com/org/repo.git
    clone_pattern = re.compile(
        r'git\s+clone\s+(?:-b\s+(\S+)\s+)?(?:--single-branch\s+)?(\S+)',
        re.MULTILINE
    )

    # Pattern to match git checkout commands
    # Example: git checkout commit_hash
    checkout_pattern = re.compile(
        r'git\s+checkout\s+([a-f0-9]{7,40})',
        re.MULTILINE
    )

    lines = script_content.splitlines()

    current_component = None

    for i, line in enumerate(lines):
        line = line.strip()

        # Check for git clone
        clone_match = clone_pattern.search(line)
        if clone_match:
            branch = clone_match.group(1)
            repo_url = clone_match.group(2)

            # Extract repo name from URL
            repo_name = repo_url.rstrip('/').split('/')[-1].replace('.git', '')

            current_component = ComponentManifest(
                name=repo_name,
                repo=repo_url,
                branch=branch
            )

        # Check for git checkout (usually follows clone)
        checkout_match = checkout_pattern.search(line)
        if checkout_match and current_component:
            current_component.commit = checkout_match.group(1)
            components.append(current_component)
            current_component = None
        elif current_component and i == len(lines) - 1:
            # Last line, add if pending
            components.append(current_component)

    return components


async def process_manifest_script(
    script_path: str = "checkouts/opendatahub-operator/get_all_manifests.sh",
) -> List[ComponentManifest]:
    """
    Process the get_all_manifests.sh script to extract component information.

    Args:
        script_path: Path to the get_all_manifests.sh script

    Returns:
        List of ComponentManifest objects containing repo/branch/commit info
    """
    path = Path(script_path)

    print(f"Processing manifest script: {path}")

    if not path.exists():
        raise FileNotFoundError(
            f"Manifest script not found: {path}\n"
            "Make sure opendatahub-operator repository is cloned."
        )

    content = await read_manifest_script(path)
    components = parse_git_clone_commands(content)

    print(f"\nFound {len(components)} components:")
    for comp in components:
        print(f"  - {comp.name}")
        print(f"    Repo: {comp.repo}")
        if comp.branch:
            print(f"    Branch: {comp.branch}")
        if comp.commit:
            print(f"    Commit: {comp.commit}")
        print()

    return components
