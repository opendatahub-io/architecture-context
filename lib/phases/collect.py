"""Phase 4: Collect and organize architecture files using component-map.json."""

import shutil
import subprocess
from pathlib import Path

from lib.component_discovery import read_component_map, get_component_map_metadata


def _discover_platform_maps(architecture_dir: Path) -> list[tuple[str, Path]]:
    """Find all component-map.json files under architecture/.

    Returns list of (platform_key, map_file_path) tuples.
    """
    platforms = []
    for map_file in sorted(architecture_dir.glob("*/component-map.json")):
        platform_key = map_file.parent.name
        platforms.append((platform_key, map_file))
    return platforms


def _create_index_readme(
    output_dir: Path, platform: str, version: str, components: list[str],
    source_map: str,
) -> None:
    """Create README.md index file for a platform-version directory."""
    date = subprocess.run(
        ["date", "+%Y-%m-%d"], capture_output=True, text=True,
    ).stdout.strip()

    content = f"""# {platform.upper()} {version} - Component Architectures

Source: {source_map}
Date: {date}

## Components

| Component | Architecture File |
|-----------|-------------------|
"""
    for component in sorted(components):
        content += f"| {component} | [{component}.md](./{component}.md) |\n"

    content += f"""
## Summary

- **Platform**: {platform.upper()}
- **Version**: {version}
- **Components**: {len(components)}
"""
    (output_dir / "README.md").write_text(content)


async def run_collect_architectures_phase(args) -> None:
    """Run Phase 4: Collect and organize architecture files."""
    print("\n" + "=" * 60)
    print("PHASE 4: Collecting component architectures")
    print("=" * 60 + "\n")

    architecture_dir = Path(getattr(args, "architecture_dir", "architecture"))

    if not architecture_dir.exists():
        print(f"Error: Architecture directory does not exist: {architecture_dir}")
        return

    platform_filter = None if args.platform == "all" else args.platform
    version_filter = getattr(args, "version", None)

    # Discover platform component maps
    platform_maps = _discover_platform_maps(architecture_dir)

    if platform_filter:
        platform_maps = [
            (k, p) for k, p in platform_maps if k == platform_filter
        ]

    if not platform_maps:
        print(f"No component-map.json files found in {architecture_dir}/")
        if platform_filter:
            print(f"  (filtered to platform: {platform_filter})")
        print(f"\nRun discover-components first:")
        print(f"  uv run main.py discover-components --platform=<platform>")
        return

    print(f"Found {len(platform_maps)} platform(s) with component maps:")
    for platform_key, _ in platform_maps:
        print(f"  - {platform_key}")

    total_collected = 0

    for platform_key, map_file in platform_maps:
        metadata = get_component_map_metadata(platform_key, architecture_dir=str(architecture_dir)) or {}
        version = version_filter or metadata.get("version", "unknown")
        platform_name = platform_key.split("-")[0] if "-" in platform_key else platform_key

        print(f"\nProcessing {platform_key} (version {version})...")

        components = read_component_map(platform_key, architecture_dir=str(architecture_dir))
        if not components:
            print(f"  No components in {map_file}")
            continue

        # Find components with architecture files
        # Check both canonical and legacy filenames
        arch_filenames = ["GENERATED_ARCHITECTURE.md", "ARCHITECTURE_SUMMARY.md"]
        found = []
        for key, comp in sorted(components.items()):
            if not comp.checkout_path:
                continue
            for fname in arch_filenames:
                arch_file = comp.checkout_path / fname
                if arch_file.exists():
                    found.append((key, arch_file))
                    break

        if not found:
            print(f"  No GENERATED_ARCHITECTURE.md files found")
            print(f"  Run: uv run main.py generate-architecture --platform={platform_key}")
            continue

        print(f"  Found {len(found)} architecture file(s)")

        # Collect into the same directory as the component-map
        output_dir = architecture_dir / platform_key

        # Copy files
        collected_names = []
        for comp_key, arch_file in found:
            target = output_dir / f"{comp_key}.md"
            shutil.copy2(arch_file, target)
            collected_names.append(comp_key)
            print(f"    {comp_key}.md")

        # Create index
        _create_index_readme(
            output_dir, platform_key, version, collected_names,
            source_map=str(map_file),
        )
        print(f"  Created: {output_dir}/README.md")

        total_collected += len(collected_names)

    print("\n" + "=" * 60)
    if total_collected:
        print(f"Collected {total_collected} architecture file(s)")
    else:
        print("No architecture files collected. See warnings above.")
    print("=" * 60)
