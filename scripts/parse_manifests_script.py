#!/usr/bin/env python3
"""
Parse get_all_manifests.sh to extract component repository information.

Extracts component names and repository mappings from ODH/RHOAI manifest arrays.
"""

import argparse
import re
from dataclasses import dataclass
from pathlib import Path
from typing import Optional


@dataclass
class ComponentInfo:
    """Component repository information"""
    key: str  # Key in manifest array (e.g., "kserve", "dashboard")
    repo_org: str  # GitHub org (e.g., "opendatahub-io")
    repo_name: str  # Repo name (e.g., "kserve", "odh-dashboard")
    ref: str  # Branch/tag/commit
    source_folder: str  # Folder within repo
    checkout_path: Optional[Path] = None  # Path to local checkout
    has_architecture: bool = False  # Whether GENERATED_ARCHITECTURE.md exists


def parse_manifest_array(content: str, array_name: str) -> dict[str, ComponentInfo]:
    """
    Parse a bash associative array from get_all_manifests.sh

    Example format:
    declare -A ODH_COMPONENT_MANIFESTS=(
        ["dashboard"]="opendatahub-io:odh-dashboard:main@abc123:manifests"
        ["kserve"]="opendatahub-io:kserve:release-v0.15@def456:config"
    )
    """
    components = {}

    # Match the array declaration block
    array_pattern = rf'declare -A {array_name}=\((.*?)\)'
    array_match = re.search(array_pattern, content, re.DOTALL)

    if not array_match:
        return components

    array_body = array_match.group(1)

    # Match each line: ["key"]="org:repo:ref:folder"
    line_pattern = r'\["([^"]+)"\]="([^:]+):([^:]+):([^:]+):([^"]+)"'

    for match in re.finditer(line_pattern, array_body):
        key = match.group(1)
        repo_org = match.group(2)
        repo_name = match.group(3)
        ref = match.group(4)
        source_folder = match.group(5)

        components[key] = ComponentInfo(
            key=key,
            repo_org=repo_org,
            repo_name=repo_name,
            ref=ref,
            source_folder=source_folder
        )

    return components


def find_component_checkouts(
    components: dict[str, ComponentInfo],
    checkouts_dir: Path
) -> dict[str, ComponentInfo]:
    """
    Map components to their checkout directories and filter for existing checkouts.

    Also checks for GENERATED_ARCHITECTURE.md existence.

    Returns only components that have a matching checkout directory.
    """
    found_components = {}

    for key, component in components.items():
        # Construct expected checkout path
        checkout_path = checkouts_dir / component.repo_org / component.repo_name

        if checkout_path.exists() and checkout_path.is_dir():
            component.checkout_path = checkout_path

            # Check if GENERATED_ARCHITECTURE.md exists
            arch_file = checkout_path / "GENERATED_ARCHITECTURE.md"
            component.has_architecture = arch_file.exists()

            found_components[key] = component

    return found_components


def parse_manifests_script(
    script_path: Path,
    platform: str,
    checkouts_dir: Path
) -> dict[str, ComponentInfo]:
    """
    Parse get_all_manifests.sh and return component info.

    Args:
        script_path: Path to get_all_manifests.sh
        platform: "odh" or "rhoai"
        checkouts_dir: Base checkouts directory

    Returns:
        Dict of component key -> ComponentInfo (only for components with checkouts)
    """
    if not script_path.exists():
        raise FileNotFoundError(f"Manifest script not found: {script_path}")

    content = script_path.read_text()

    # Determine which array to parse
    array_name = "ODH_COMPONENT_MANIFESTS" if platform == "odh" else "RHOAI_COMPONENT_MANIFESTS"

    # Parse the array
    components = parse_manifest_array(content, array_name)

    # Map to checkout directories (filter for existing only)
    found_components = find_component_checkouts(components, checkouts_dir)

    return found_components


def main():
    parser = argparse.ArgumentParser(
        description='Parse get_all_manifests.sh to extract component information'
    )
    parser.add_argument(
        '--platform',
        choices=['odh', 'rhoai'],
        required=True,
        help='Platform to parse (odh or rhoai)'
    )
    parser.add_argument(
        '--manifest-script',
        type=Path,
        help='Path to get_all_manifests.sh (default: auto-detect from checkouts)'
    )
    parser.add_argument(
        '--checkouts-dir',
        type=Path,
        default=Path('./checkouts'),
        help='Checkouts directory (default: ./checkouts)'
    )
    parser.add_argument(
        '--format',
        choices=['list', 'paths', 'json'],
        default='list',
        help='Output format (default: list)'
    )
    parser.add_argument(
        '--filter-missing',
        action='store_true',
        help='Only show components without GENERATED_ARCHITECTURE.md'
    )

    args = parser.parse_args()

    # Auto-detect manifest script if not provided
    if args.manifest_script is None:
        operator_name = "opendatahub-operator" if args.platform == "odh" else "rhods-operator"
        repo_org = "opendatahub-io" if args.platform == "odh" else "red-hat-data-services"
        args.manifest_script = args.checkouts_dir / repo_org / operator_name / "get_all_manifests.sh"

    # Parse the script
    try:
        components = parse_manifests_script(
            args.manifest_script,
            args.platform,
            args.checkouts_dir
        )
    except FileNotFoundError as e:
        print(f"Error: {e}")
        return 1

    if not components:
        print(f"No component checkouts found for {args.platform.upper()}")
        print(f"Expected in: {args.checkouts_dir}")
        return 1

    # Apply filter if requested
    if args.filter_missing:
        components = {k: v for k, v in components.items() if not v.has_architecture}

    if not components:
        if args.filter_missing:
            print(f"No components need analysis - all have GENERATED_ARCHITECTURE.md")
        else:
            print(f"No component checkouts found for {args.platform.upper()}")
            print(f"Expected in: {args.checkouts_dir}")
        return 0

    # Output based on format
    if args.format == 'list':
        # Count components by status
        analyzed = sum(1 for c in components.values() if c.has_architecture)
        missing = len(components) - analyzed

        print(f"Found {len(components)} {args.platform.upper()} component(s) with checkouts:")
        print(f"  Analyzed: {analyzed}, Missing: {missing}\n")

        for key, component in sorted(components.items()):
            status = "✓" if component.has_architecture else "✗"
            print(f"  {status} {key:25s} {component.repo_name:40s} ({component.checkout_path})")

    elif args.format == 'paths':
        # Just output checkout paths (for use in scripts)
        for component in sorted(components.values(), key=lambda c: c.key):
            print(component.checkout_path)

    elif args.format == 'json':
        import json
        output = {
            key: {
                'repo_org': c.repo_org,
                'repo_name': c.repo_name,
                'ref': c.ref,
                'source_folder': c.source_folder,
                'checkout_path': str(c.checkout_path),
                'has_architecture': c.has_architecture
            }
            for key, c in components.items()
        }
        print(json.dumps(output, indent=2))

    return 0


if __name__ == '__main__':
    exit(main())
