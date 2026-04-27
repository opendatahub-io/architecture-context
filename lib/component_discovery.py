"""Component discovery utilities for reading/writing component maps."""

import json
import fnmatch
import subprocess
from pathlib import Path
from typing import Dict, List, Optional, Any
from datetime import datetime

from lib.manifest_parser import ComponentInfo


def _detect_checkout_branch(checkout_path: Path) -> Optional[str]:
    """Read the current branch from a git checkout."""
    try:
        result = subprocess.run(
            ["git", "rev-parse", "--abbrev-ref", "HEAD"],
            cwd=checkout_path,
            capture_output=True, text=True, timeout=5,
        )
        if result.returncode == 0:
            return result.stdout.strip() or None
    except (subprocess.TimeoutExpired, FileNotFoundError, OSError):
        pass
    return None


def write_component_map(
    platform: str,
    components: Dict[str, ComponentInfo],
    metadata: Dict[str, Any],
    architecture_dir: str = "architecture"
) -> Path:
    """
    Write component map to architecture/<platform>/component-map.json.

    The discover-components skill writes additional fields beyond ComponentInfo
    (type, architecturally_significant, consumer_count, consumers, discovered_via,
    referenced_by, shipped). Those are preserved in JSON but not mapped to ComponentInfo.

    Args:
        platform: Platform name (e.g., "rhoai-3.4", "odh")
        components: Dict of component key -> ComponentInfo
        metadata: Discovery metadata (method, entry_point, stats, etc.)
        architecture_dir: Base architecture directory

    Returns:
        Path to written component-map.json
    """
    output_dir = Path(architecture_dir) / platform
    output_dir.mkdir(parents=True, exist_ok=True)

    output_file = output_dir / "component-map.json"

    component_data = {}
    for key, comp in components.items():
        repo_url = comp.repo_url
        if not repo_url and comp.repo_org and comp.repo_name:
            repo_url = f"https://github.com/{comp.repo_org}/{comp.repo_name}"

        checkout_branch = comp.checkout_branch
        if not checkout_branch and comp.checkout_path:
            checkout_branch = _detect_checkout_branch(comp.checkout_path)

        component_data[key] = {
            "key": comp.key,
            "repo_org": comp.repo_org,
            "repo_name": comp.repo_name,
            "repo_url": repo_url,
            "ref": comp.ref,
            "source_folder": comp.source_folder,
            "checkout_path": str(comp.checkout_path) if comp.checkout_path else None,
            "checkout_branch": checkout_branch,
            "has_architecture": comp.has_architecture,
        }

    if "discovered_at" not in metadata:
        metadata["discovered_at"] = datetime.now().isoformat()

    component_map = {
        "metadata": metadata,
        "components": component_data
    }

    output_file.write_text(json.dumps(component_map, indent=2))

    return output_file


def read_component_map(
    platform: str,
    architecture_dir: str = "architecture"
) -> Optional[Dict[str, ComponentInfo]]:
    """
    Read component map from architecture/<platform>/component-map.json.

    Args:
        platform: Platform name (e.g., "rhoai-3.4", "odh")
        architecture_dir: Base architecture directory

    Returns:
        Dict of component key -> ComponentInfo, or None if not found
    """
    map_file = Path(architecture_dir) / platform / "component-map.json"

    if not map_file.exists():
        return None

    data = json.loads(map_file.read_text())

    components = {}
    raw_components = data.get("components", {})

    # Handle both dict and list formats
    if isinstance(raw_components, list):
        items = [(comp.get("key", comp.get("repo_name", f"unknown-{i}")), comp) for i, comp in enumerate(raw_components)]
    else:
        items = raw_components.items()

    for key, comp_data in items:
        components[key] = ComponentInfo(
            key=comp_data.get("key", key),
            repo_org=comp_data.get("repo_org"),
            repo_name=comp_data.get("repo_name"),
            ref=comp_data.get("ref"),
            source_folder=comp_data.get("source_folder"),
            checkout_path=Path(comp_data["checkout_path"]) if comp_data.get("checkout_path") else None,
            has_architecture=comp_data.get("has_architecture", False),
            repo_url=comp_data.get("repo_url"),
            checkout_branch=comp_data.get("checkout_branch"),
        )

    return components


def get_component_map_metadata(
    platform: str,
    architecture_dir: str = "architecture"
) -> Optional[Dict[str, Any]]:
    """
    Read only the metadata from component-map.json.

    Args:
        platform: Platform name
        architecture_dir: Base architecture directory

    Returns:
        Metadata dict, or None if not found
    """
    map_file = Path(architecture_dir) / platform / "component-map.json"

    if not map_file.exists():
        return None

    data = json.loads(map_file.read_text())
    return data.get("metadata", {})


def apply_platform_overrides(
    components: Dict[str, ComponentInfo],
    platform_config: dict,
    checkouts_base: str = "checkouts",
) -> Dict[str, ComponentInfo]:
    """
    Apply overrides from platforms.yaml to a component map.

    Supports:
      - component_overrides: fix type, tier, or other fields on existing components
      - exclude_components: remove components by key (supports glob patterns)
      - include_components: add components not found by discovery

    Args:
        components: Dict of component key -> ComponentInfo
        platform_config: Platform config dict from platforms.yaml
        checkouts_base: Base checkouts directory for resolving paths

    Returns:
        Updated components dict
    """
    if not platform_config:
        return components

    # 1. Exclude components
    exclude_patterns = platform_config.get("exclude_components", [])
    if exclude_patterns:
        excluded = []
        for key in list(components.keys()):
            for pattern in exclude_patterns:
                if fnmatch.fnmatch(key, pattern):
                    excluded.append(key)
                    del components[key]
                    break
        if excluded:
            print(f"  Excluded {len(excluded)} component(s) via platforms.yaml: {', '.join(sorted(excluded))}")

    # 2. Apply overrides to existing components
    overrides = platform_config.get("component_overrides", {})
    if overrides:
        applied = 0
        for key, override_fields in overrides.items():
            if key in components:
                comp = components[key]
                for field, value in override_fields.items():
                    if hasattr(comp, field):
                        setattr(comp, field, value)
                applied += 1
        if applied:
            print(f"  Applied overrides to {applied} component(s) via platforms.yaml")

    # 3. Include additional components
    includes = platform_config.get("include_components", [])
    if includes:
        added = 0
        for entry in includes:
            key = entry["key"]
            if key in components:
                continue

            repo_org = entry.get("repo_org")
            repo_name = entry.get("repo_name", key)
            checkout_path = None
            if repo_org:
                candidate = Path(checkouts_base) / repo_org / repo_name
                if candidate.exists():
                    checkout_path = candidate

            components[key] = ComponentInfo(
                key=key,
                repo_org=repo_org,
                repo_name=repo_name,
                ref=entry.get("ref"),
                source_folder=entry.get("source_folder"),
                checkout_path=checkout_path,
                has_architecture=False,
            )
            added += 1
        if added:
            print(f"  Added {added} component(s) via platforms.yaml")

    return components
