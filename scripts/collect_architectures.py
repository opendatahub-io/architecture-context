#!/usr/bin/env python3
"""
Collect and organize GENERATED_ARCHITECTURE.md files from repository checkouts
into a structured architecture directory by platform, version, and component.

Usage:
    python collect_architectures.py [--checkouts-dir=<path>] [--output-dir=<path>]
    python collect_architectures.py --test-version  # Test version detection only

Version Detection Priority:
    1. Makefile VERSION variable (primary - developer intent)
    2. VERSION or version.txt file
    3. git describe --tags --always (fallback)
    4. "unknown" if all fail
"""

import argparse
import re
import shutil
import subprocess
from dataclasses import dataclass
from pathlib import Path
from typing import Optional


@dataclass
class Platform:
    """Platform information"""
    name: str  # "odh" or "rhoai"
    version: str
    checkout_dir: Path
    operator_dir: Path


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
    except Exception as e:
        print(f"    Warning: Could not read Makefile at {makefile_path}: {e}")

    return None


def get_version_from_version_file(operator_dir: Path) -> Optional[str]:
    """Extract version from VERSION or version.txt file"""
    for filename in ['VERSION', 'version.txt']:
        version_file = operator_dir / filename
        if version_file.exists():
            try:
                return version_file.read_text().strip()
            except Exception as e:
                print(f"Warning: Could not read {version_file}: {e}")

    return None


def get_version_from_git(operator_dir: Path) -> Optional[str]:
    """Extract version from git describe"""
    try:
        result = subprocess.run(
            ['git', 'describe', '--tags', '--always'],
            cwd=operator_dir,
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
    except Exception as e:
        print(f"Warning: Could not run git describe in {operator_dir}: {e}")

    return None


def detect_platform_version(platform_name: str, checkout_dir: Path, operator_name: str) -> Optional[str]:
    """
    Detect platform version from operator repository.

    For RHOAI (red-hat-data-services):
      - Branch name is authoritative (e.g., rhoai-2.7 → version 2.7)
      - Extract from directory name: red-hat-data-services.rhoai-X.Y → X.Y

    For ODH (opendatahub-io):
      - Makefile VERSION is authoritative
      - Fallback to VERSION file or git describe
    """
    operator_dir = checkout_dir / operator_name

    if not operator_dir.exists():
        print(f"Warning: Operator directory not found: {operator_dir}")
        return None

    print(f"Detecting {platform_name.upper()} version from {operator_dir}")

    # SPECIAL CASE: For RHOAI, branch name is authoritative
    # Extract version from checkout directory name
    if platform_name == 'rhoai':
        # Directory name format: red-hat-data-services.rhoai-X.Y
        match = re.search(r'\.rhoai-([0-9.]+)', checkout_dir.name)
        if match:
            version = match.group(1)
            print(f"  ✓ Found version from branch name: {version}")
            return version
        # If no branch suffix, might be plain "red-hat-data-services"
        # Fall through to Makefile detection

    # For ODH (or RHOAI without branch suffix), use Makefile
    # Try Makefile first (primary source)
    makefile_path = operator_dir / 'Makefile'
    print(f"  Checking Makefile: {makefile_path}")
    version = get_version_from_makefile(makefile_path)
    if version:
        print(f"  ✓ Found version in Makefile: {version}")
        return version
    else:
        print(f"    (Makefile VERSION not found or not readable)")

    # Try VERSION file
    print(f"  Checking VERSION file in: {operator_dir}")
    version = get_version_from_version_file(operator_dir)
    if version:
        print(f"  ✓ Found version in VERSION file: {version}")
        return version
    else:
        print(f"    (VERSION file not found)")

    # Try git describe (fallback)
    print(f"  Checking git describe in: {operator_dir}")
    version = get_version_from_git(operator_dir)
    if version:
        print(f"  ✓ Found version from git describe: {version}")
        return version
    else:
        print(f"    (git describe failed)")

    print(f"  ⚠ Could not determine version, using 'unknown'")
    return "unknown"


def discover_platforms(checkouts_dir: Path) -> list[Platform]:
    """Discover available platform checkouts and their versions"""
    platforms = []

    # Check for ODH checkouts (opendatahub-io or opendatahub-io.*)
    for odh_dir in sorted(checkouts_dir.glob('opendatahub-io*')):
        if odh_dir.is_dir():
            version = detect_platform_version('odh', odh_dir, 'opendatahub-operator')
            if version:
                platforms.append(Platform(
                    name='odh',
                    version=version,
                    checkout_dir=odh_dir,
                    operator_dir=odh_dir / 'opendatahub-operator'
                ))

    # Check for RHOAI checkouts (red-hat-data-services or red-hat-data-services.*)
    for rhoai_dir in sorted(checkouts_dir.glob('red-hat-data-services*')):
        if rhoai_dir.is_dir():
            version = detect_platform_version('rhoai', rhoai_dir, 'rhods-operator')
            if version:
                platforms.append(Platform(
                    name='rhoai',
                    version=version,
                    checkout_dir=rhoai_dir,
                    operator_dir=rhoai_dir / 'rhods-operator'
                ))

    return platforms


def find_architecture_files(platform: Platform) -> list[tuple[Path, str]]:
    """
    Find all GENERATED_ARCHITECTURE.md files for a platform.

    Returns list of (file_path, component_name) tuples
    """
    architecture_files = []

    # Find all GENERATED_ARCHITECTURE.md files
    for arch_file in platform.checkout_dir.glob('*/GENERATED_ARCHITECTURE.md'):
        component_name = arch_file.parent.name
        architecture_files.append((arch_file, component_name))

    return architecture_files


def create_index_readme(output_dir: Path, platform: Platform, components: list[str]):
    """Create README.md index file for a platform-version directory"""
    readme_path = output_dir / 'README.md'

    content = f"""# {platform.name.upper()} {platform.version} - Component Architectures

Generated from: {platform.checkout_dir}
Platform version from: {platform.operator_dir}
Date: {subprocess.run(['date', '+%Y-%m-%d'], capture_output=True, text=True).stdout.strip()}

## Components

| Component Repository | Architecture File |
|----------------------|-------------------|
"""

    for component in sorted(components):
        content += f"| {component} | [{component}.md](./{component}.md) |\n"

    content += f"""
## Summary

- **Platform**: {platform.name.upper()}
- **Version**: {platform.version}
- **Components**: {len(components)}
- **Source**: {platform.checkout_dir}

## Using These Files

These are individual component architecture summaries. To create a platform-level view:

```bash
/aggregate-platform-architecture --distribution={platform.name} --version={platform.version}
```

To generate diagrams from a component:

```bash
/generate-architecture-diagrams --architecture=./{components[0] if components else 'COMPONENT'}.md
```
"""

    readme_path.write_text(content)
    print(f"  Created index: {readme_path}")


def collect_architectures(checkouts_dir: Path, output_dir: Path, platform_filter: Optional[str] = None, version_filter: Optional[str] = None) -> dict:
    """
    Main collection function.

    Args:
        checkouts_dir: Directory containing platform checkouts
        output_dir: Output directory for organized architectures
        platform_filter: Optional filter for 'odh', 'rhoai', or None for all
        version_filter: Optional version filter (e.g., '2.25', '3.3.0'), or None for all

    Returns summary dict with stats.
    """
    summary = {
        'platforms': [],
        'total_components': 0,
        'files_created': []
    }

    # Discover platforms
    platforms = discover_platforms(checkouts_dir)

    # Apply platform filter if specified
    if platform_filter:
        platforms = [p for p in platforms if p.name == platform_filter]

    # Apply version filter if specified
    if version_filter:
        platforms = [p for p in platforms if p.version == version_filter]

    if not platforms:
        print(f"\n⚠️  No platform checkout directories found in {checkouts_dir}\n")
        print("Expected:")
        print(f"  - {checkouts_dir}/opendatahub-io/ (for ODH components)")
        print(f"  - {checkouts_dir}/red-hat-data-services/ (for RHOAI components)")
        return summary

    print(f"\nFound {len(platforms)} platform(s):")
    for platform in platforms:
        print(f"  - {platform.name.upper()} {platform.version}")

    # Process each platform
    for platform in platforms:
        print(f"\nProcessing {platform.name.upper()} {platform.version}...")

        # Create output directory
        platform_output_dir = output_dir / f"{platform.name}-{platform.version}"
        platform_output_dir.mkdir(parents=True, exist_ok=True)
        print(f"  Output directory: {platform_output_dir}")

        # Find architecture files
        arch_files = find_architecture_files(platform)

        if not arch_files:
            print(f"  ⚠️  No GENERATED_ARCHITECTURE.md files found for {platform.name.upper()}")
            print(f"     Run /repo-to-architecture-summary on component repositories first")
            continue

        print(f"  Found {len(arch_files)} component(s)")

        # Copy files
        components = []
        for arch_file, component_name in arch_files:
            target_path = platform_output_dir / f"{component_name}.md"
            shutil.copy2(arch_file, target_path)
            components.append(component_name)
            summary['files_created'].append(str(target_path))
            print(f"    ✓ {component_name}.md")

        # Create index
        create_index_readme(platform_output_dir, platform, components)
        summary['files_created'].append(str(platform_output_dir / 'README.md'))

        # Update summary
        summary['platforms'].append({
            'name': platform.name,
            'version': platform.version,
            'component_count': len(components),
            'components': components,
            'output_dir': str(platform_output_dir)
        })
        summary['total_components'] += len(components)

    return summary


def print_summary(summary: dict, checkouts_dir: Path, output_dir: Path):
    """Print collection summary"""
    print("\n" + "="*80)
    print("✅ Component architectures collected!")
    print("="*80)

    print(f"\nCheckouts directory: {checkouts_dir}")
    print(f"Output directory: {output_dir}")

    if summary['platforms']:
        print("\nPlatform versions detected:")
        for platform_info in summary['platforms']:
            print(f"  - {platform_info['name'].upper()}: {platform_info['version']} "
                  f"({platform_info['component_count']} components)")

        print(f"\nComponents collected: {summary['total_components']}")

        print("\nDirectory structure created:")
        for platform_info in summary['platforms']:
            print(f"  - {platform_info['output_dir']}/")
            print(f"      README.md")
            for component in sorted(platform_info['components']):
                print(f"      {component}.md")

        print("\nNext steps:")
        print(f"  1. Review collected architectures in {output_dir}/")
        for platform_info in summary['platforms']:
            print(f"  2. Generate platform-level view: "
                  f"/aggregate-platform-architecture --distribution={platform_info['name']} "
                  f"--version={platform_info['version']}")
            break  # Just show one example
        for platform_info in summary['platforms']:
            if platform_info['components']:
                first_component = platform_info['components'][0]
                print(f"  3. Generate diagrams: "
                      f"/generate-architecture-diagrams "
                      f"--architecture={output_dir}/{platform_info['name']}-{platform_info['version']}/{first_component}.md")
                break
    else:
        print("\n⚠️  No platforms processed. See warnings above.")


def main():
    parser = argparse.ArgumentParser(
        description='Collect and organize component architecture files by platform and version'
    )
    parser.add_argument(
        '--checkouts-dir',
        type=Path,
        default=Path('./checkouts'),
        help='Directory containing platform checkouts (default: ./checkouts)'
    )
    parser.add_argument(
        '--output-dir',
        type=Path,
        default=Path('./architecture'),
        help='Output directory for organized architectures (default: ./architecture)'
    )
    parser.add_argument(
        '--test-version',
        action='store_true',
        help='Test version detection only (do not copy files)'
    )

    args = parser.parse_args()

    # Validate checkouts directory
    if not args.checkouts_dir.exists():
        print(f"Error: Checkouts directory does not exist: {args.checkouts_dir}")
        return 1

    # Test version detection only
    if args.test_version:
        print("Testing version detection...\n")
        platforms = discover_platforms(args.checkouts_dir)
        if not platforms:
            print("No platforms detected")
            return 1

        print("Detected platforms:")
        for platform in platforms:
            print(f"  - {platform.name.upper()}: {platform.version}")
            print(f"    Checkout dir: {platform.checkout_dir}")
            print(f"    Operator dir: {platform.operator_dir}")
        return 0

    # Run collection
    summary = collect_architectures(args.checkouts_dir, args.output_dir)

    # Print summary
    print_summary(summary, args.checkouts_dir, args.output_dir)

    return 0 if summary['platforms'] else 1


if __name__ == '__main__':
    exit(main())
