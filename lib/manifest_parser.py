"""Phase 2: Parse opendatahub-operator get_all_manifests.sh script."""

import re
import json
from pathlib import Path
from typing import Dict, Optional, Any
from dataclasses import dataclass, asdict


@dataclass
class ComponentInfo:
    """Component repository information extracted from get_all_manifests.sh."""

    key: str  # Key in manifest array (e.g., "kserve", "dashboard")
    repo_org: str  # GitHub org (e.g., "opendatahub-io")
    repo_name: str  # Repo name (e.g., "kserve", "odh-dashboard")
    ref: str  # Branch/tag/commit
    source_folder: str  # Folder within repo
    checkout_path: Optional[Path] = None  # Path to local checkout
    has_architecture: bool = False  # Whether GENERATED_ARCHITECTURE.md exists


def parse_manifest_array(content: str, array_name: str) -> Dict[str, ComponentInfo]:
    """
    Parse a bash associative array from get_all_manifests.sh.

    Example format:
    declare -A ODH_COMPONENT_MANIFESTS=(
        ["dashboard"]="opendatahub-io:odh-dashboard:main@abc123:manifests"
        ["kserve"]="opendatahub-io:kserve:release-v0.15@def456:config"
    )

    Args:
        content: Content of get_all_manifests.sh script
        array_name: Name of array to parse (ODH_COMPONENT_MANIFESTS or RHOAI_COMPONENT_MANIFESTS)

    Returns:
        Dict mapping component key to ComponentInfo
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
    components: Dict[str, ComponentInfo],
    checkouts_dir: Path
) -> Dict[str, ComponentInfo]:
    """
    Map components to their checkout directories and filter for existing checkouts.

    Also checks for GENERATED_ARCHITECTURE.md existence.

    Args:
        components: Dict of parsed components
        checkouts_dir: Base directory containing checkouts (should include org directory)

    Returns:
        Dict of only components that have a matching checkout directory
    """
    found_components = {}

    for key, component in components.items():
        # Construct expected checkout path
        # checkouts_dir is like: checkouts/opendatahub-io or checkouts/red-hat-data-services.rhoai-2.14
        # We just append the repo name
        checkout_path = checkouts_dir / component.repo_name

        if checkout_path.exists() and checkout_path.is_dir():
            component.checkout_path = checkout_path

            # Check if GENERATED_ARCHITECTURE.md exists
            arch_file = checkout_path / "GENERATED_ARCHITECTURE.md"
            component.has_architecture = arch_file.exists()

            found_components[key] = component

    return found_components


async def process_manifest_script(
    script_path: str,
    platform: str = "odh",
    checkouts_dir: Optional[str] = None
) -> Dict[str, ComponentInfo]:
    """
    Process the get_all_manifests.sh script to extract component information.

    This function is silent - it only processes data and returns structured results.
    Use display_component_summary() for human-readable output.

    Args:
        script_path: Path to the get_all_manifests.sh script
                    Examples:
                    - checkouts/opendatahub-io/opendatahub-operator/get_all_manifests.sh
                    - checkouts/red-hat-data-services.rhoai-2.14/opendatahub-operator/get_all_manifests.sh
        platform: Platform type - "odh" or "rhoai"
        checkouts_dir: Base checkouts directory (auto-detected from script_path if not provided)

    Returns:
        Dict of component key -> ComponentInfo (only for components with existing checkouts)

    Raises:
        FileNotFoundError: If script_path does not exist
    """
    path = Path(script_path)

    if not path.exists():
        raise FileNotFoundError(
            f"Manifest script not found: {path}\n"
            "Make sure the operator repository is cloned."
        )

    # Auto-detect checkouts directory from script path if not provided
    if checkouts_dir is None:
        # script_path is like: checkouts/opendatahub-io/opendatahub-operator/get_all_manifests.sh
        # or: checkouts/red-hat-data-services.rhoai-2.14/opendatahub-operator/get_all_manifests.sh
        parts = path.parts
        if "checkouts" in parts:
            checkouts_idx = parts.index("checkouts")
            # Get up to and including the org directory (one level after checkouts)
            checkouts_dir = Path(*parts[:checkouts_idx+2])
        else:
            # Fallback: go up 2 levels from operator dir
            checkouts_dir = path.parent.parent
    else:
        checkouts_dir = Path(checkouts_dir)

    content = path.read_text()

    # Determine which array to parse
    array_name = "ODH_COMPONENT_MANIFESTS" if platform == "odh" else "RHOAI_COMPONENT_MANIFESTS"

    # Parse the array
    components = parse_manifest_array(content, array_name)

    if not components:
        return {}

    # Map to checkout directories (filter for existing only)
    found_components = find_component_checkouts(components, checkouts_dir)

    return found_components


def components_to_dict(components: Dict[str, ComponentInfo]) -> Dict[str, Any]:
    """
    Convert ComponentInfo objects to a JSON-serializable dictionary.

    Args:
        components: Dict of component key -> ComponentInfo

    Returns:
        Dict suitable for JSON serialization
    """
    result = {}
    for key, component in components.items():
        comp_dict = asdict(component)
        # Convert Path to string
        if comp_dict.get('checkout_path'):
            comp_dict['checkout_path'] = str(comp_dict['checkout_path'])
        result[key] = comp_dict
    return result


def components_to_json(components: Dict[str, ComponentInfo], indent: int = 2) -> str:
    """
    Convert ComponentInfo objects to JSON string.

    Args:
        components: Dict of component key -> ComponentInfo
        indent: JSON indentation level

    Returns:
        JSON string
    """
    return json.dumps(components_to_dict(components), indent=indent)


def display_component_summary(
    components: Dict[str, ComponentInfo],
    script_path: str,
    platform: str,
    checkouts_dir: Path
) -> None:
    """
    Display human-readable summary of parsed components.

    Args:
        components: Dict of components returned from process_manifest_script
        script_path: Path to the manifest script that was parsed
        platform: Platform type (odh or rhoai)
        checkouts_dir: Base checkouts directory used
    """
    print(f"Processing manifest script: {script_path}")
    print(f"Using checkouts directory: {checkouts_dir}")
    print(f"Parsing array: {'ODH_COMPONENT_MANIFESTS' if platform == 'odh' else 'RHOAI_COMPONENT_MANIFESTS'}")
    print()

    if not components:
        print(f"No components found with checkouts")
        return

    # Count components by architecture status
    analyzed = sum(1 for c in components.values() if c.has_architecture)
    missing = len(components) - analyzed

    print(f"Found {len(components)} components with checkouts:")
    print(f"  Analyzed: {analyzed}, Missing analysis: {missing}")
    print()

    for key, component in sorted(components.items()):
        status = "✓" if component.has_architecture else "✗"
        print(f"  {status} {key:25s} {component.repo_org}/{component.repo_name}")
        print(f"     ref: {component.ref}")
        print(f"     path: {component.checkout_path}")
        if component.source_folder:
            print(f"     source: {component.source_folder}")
        print()
