#!/usr/bin/env python3
"""
Repository processing and analysis tool.

Supports multiple phases:
1. Fetch repositories from GitHub organizations
2. Parse component manifests from scripts
"""

import os
import sys
import asyncio
import argparse
from pathlib import Path

from dotenv import load_dotenv

# Import phase modules
from lib.fetch import fetch_repositories
from lib.manifest_parser import (
    process_manifest_script,
    display_component_summary,
    components_to_json
)

# Load environment variables from .env file
load_dotenv()


def parse_args():
    """Parse command line arguments with subcommands for each phase."""
    parser = argparse.ArgumentParser(
        description="Repository processing and analysis tool",
        formatter_class=argparse.RawDescriptionHelpFormatter,
    )

    subparsers = parser.add_subparsers(dest="command", help="Phase to run")

    # Phase 1: Fetch repositories
    fetch_parser = subparsers.add_parser(
        "fetch",
        help="Fetch/clone repositories using gh-org-clone"
    )
    fetch_parser.add_argument(
        "org",
        help="GitHub organization name to clone"
    )
    fetch_parser.add_argument(
        "--checkouts-dir",
        default="checkouts",
        help="Directory to clone repositories into (default: checkouts)"
    )
    fetch_parser.add_argument(
        "--branch",
        help="Specific branch to clone (skips repos without this branch)"
    )

    # Phase 2: Parse manifests
    manifest_parser = subparsers.add_parser(
        "parse-manifests",
        help="Parse get_all_manifests.sh to extract component info"
    )
    manifest_parser.add_argument(
        "--platform",
        choices=["odh", "rhoai"],
        required=True,
        help="Platform to parse (odh or rhoai)"
    )
    manifest_parser.add_argument(
        "--org",
        help="GitHub organization name (auto-detected if not provided)"
    )
    manifest_parser.add_argument(
        "--branch",
        help="Branch name if using versioned checkout (e.g., rhoai-2.14)"
    )
    manifest_parser.add_argument(
        "--checkouts-dir",
        default="checkouts",
        help="Base directory containing cloned repositories (default: checkouts)"
    )
    manifest_parser.add_argument(
        "--script-path",
        help="Override path to get_all_manifests.sh script (auto-detected if not provided)"
    )
    manifest_parser.add_argument(
        "--format",
        choices=["summary", "json"],
        default="summary",
        help="Output format: summary (human-readable) or json (structured data)"
    )

    # Phase 3: Generate architecture
    generate_arch_parser = subparsers.add_parser(
        "generate-architecture",
        help="Check component repos for GENERATED_ARCHITECTURE.md files"
    )
    generate_arch_parser.add_argument(
        "--platform",
        choices=["odh", "rhoai"],
        required=True,
        help="Platform to process (odh or rhoai)"
    )
    generate_arch_parser.add_argument(
        "--org",
        help="GitHub organization name (auto-detected if not provided)"
    )
    generate_arch_parser.add_argument(
        "--branch",
        help="Branch name if using versioned checkout (e.g., rhoai-2.14)"
    )
    generate_arch_parser.add_argument(
        "--checkouts-dir",
        default="checkouts",
        help="Base directory containing cloned repositories (default: checkouts)"
    )
    generate_arch_parser.add_argument(
        "--script-path",
        help="Override path to get_all_manifests.sh script (auto-detected if not provided)"
    )

    # All phases
    all_parser = subparsers.add_parser(
        "all",
        help="Run all phases in sequence"
    )
    all_parser.add_argument(
        "--platform",
        choices=["odh", "rhoai"],
        default="odh",
        help="Platform to process (default: odh)"
    )
    all_parser.add_argument(
        "--org",
        help="GitHub organization to clone (auto-detected if not provided)"
    )
    all_parser.add_argument(
        "--branch",
        help="Specific branch to clone (e.g., rhoai-2.14 for RHOAI versions)"
    )

    return parser.parse_args()


async def run_fetch_phase(args) -> None:
    """Run Phase 1: Fetch repositories."""
    print("\n" + "=" * 60)
    print("PHASE 1: Fetching repositories")
    print("=" * 60 + "\n")

    await fetch_repositories(
        args.org,
        args.checkouts_dir,
        branch=getattr(args, 'branch', None)
    )


async def run_manifest_phase(args) -> None:
    """Run Phase 2: Parse manifests."""
    # Only show header for summary format
    output_format = getattr(args, 'format', 'summary')

    if output_format == 'summary':
        print("\n" + "=" * 60)
        print("PHASE 2: Parsing component manifests")
        print("=" * 60 + "\n")

    # Auto-detect org if not provided
    org = args.org
    if not org:
        org = "opendatahub-io" if args.platform == "odh" else "red-hat-data-services"

    # Auto-detect operator name
    operator_name = "opendatahub-operator" if args.platform == "odh" else "rhods-operator"

    # Determine script path
    if args.script_path:
        script_path = args.script_path
    else:
        # Construct path based on org and branch
        if args.branch:
            org_dir = f"{org}.{args.branch}"
        else:
            org_dir = org

        script_path = f"{args.checkouts_dir}/{org_dir}/{operator_name}/get_all_manifests.sh"

    # Process manifests (silent - returns structured data)
    components = await process_manifest_script(
        script_path,
        platform=args.platform,
        checkouts_dir=None  # Auto-detect from script_path
    )

    # Output based on format
    if output_format == 'json':
        # Just print JSON to stdout
        print(components_to_json(components))
    else:
        # Display human-readable output
        from pathlib import Path
        script_path_obj = Path(script_path)
        parts = script_path_obj.parts
        if "checkouts" in parts:
            checkouts_idx = parts.index("checkouts")
            checkouts_dir = Path(*parts[:checkouts_idx+2])
        else:
            checkouts_dir = script_path_obj.parent.parent

        display_component_summary(
            components,
            script_path,
            args.platform,
            checkouts_dir
        )

        print(f"\n{'=' * 60}")
        print(f"Processed {len(components)} components successfully")
        print(f"{'=' * 60}")


async def run_generate_architecture_phase(args) -> None:
    """Run Phase 3: Generate architecture documentation."""
    print("\n" + "=" * 60)
    print("PHASE 3: Checking component architectures")
    print("=" * 60 + "\n")

    # Auto-detect org if not provided
    org = args.org
    if not org:
        org = "opendatahub-io" if args.platform == "odh" else "red-hat-data-services"

    # Auto-detect operator name
    operator_name = "opendatahub-operator" if args.platform == "odh" else "rhods-operator"

    # Determine script path
    if args.script_path:
        script_path = args.script_path
    else:
        # Construct path based on org and branch
        if args.branch:
            org_dir = f"{org}.{args.branch}"
        else:
            org_dir = org

        script_path = f"{args.checkouts_dir}/{org_dir}/{operator_name}/get_all_manifests.sh"

    # Process manifests to get component info
    components = await process_manifest_script(
        script_path,
        platform=args.platform,
        checkouts_dir=None  # Auto-detect from script_path
    )

    if not components:
        print("No components found with checkouts")
        return

    # Count by status
    has_arch = [c for c in components.values() if c.has_architecture]
    missing_arch = [c for c in components.values() if not c.has_architecture]

    print(f"Found {len(components)} components:")
    print(f"  With GENERATED_ARCHITECTURE.md: {len(has_arch)}")
    print(f"  Missing GENERATED_ARCHITECTURE.md: {len(missing_arch)}")
    print()

    # Display components with architecture
    if has_arch:
        print("Components with architecture documentation:")
        for component in sorted(has_arch, key=lambda c: c.key):
            print(f"  ✓ {component.key:25s} {component.repo_org}/{component.repo_name}")
            print(f"     {component.checkout_path / 'GENERATED_ARCHITECTURE.md'}")
        print()

    # Display components missing architecture
    if missing_arch:
        print("Components missing architecture documentation:")
        for component in sorted(missing_arch, key=lambda c: c.key):
            print(f"  ✗ {component.key:25s} {component.repo_org}/{component.repo_name}")
            print(f"     {component.checkout_path}")
        print()

    print(f"{'=' * 60}")
    print(f"Architecture check complete: {len(has_arch)}/{len(components)} documented")
    print(f"{'=' * 60}")


async def run_all_phases(args) -> None:
    """Run all phases in sequence."""
    # Auto-detect org if not provided
    org = args.org
    if not org:
        org = "opendatahub-io" if args.platform == "odh" else "red-hat-data-services"

    # Create a namespace-like object for each phase
    class FetchArgs:
        org = org
        checkouts_dir = "checkouts"
        branch = getattr(args, 'branch', None)

    class ManifestArgs:
        platform = args.platform
        org = org
        branch = getattr(args, 'branch', None)
        checkouts_dir = "checkouts"
        script_path = None

    await run_fetch_phase(FetchArgs())
    await run_manifest_phase(ManifestArgs())

    print("\n" + "=" * 60)
    print("All phases completed successfully!")
    print("=" * 60 + "\n")


async def main(args) -> None:
    """Main entry point - dispatch to appropriate phase."""
    if args.command == "fetch":
        await run_fetch_phase(args)
    elif args.command == "parse-manifests":
        await run_manifest_phase(args)
    elif args.command == "generate-architecture":
        await run_generate_architecture_phase(args)
    elif args.command == "all":
        await run_all_phases(args)
    else:
        print("Error: No command specified. Use --help for usage information.")
        sys.exit(1)


if __name__ == "__main__":
    args = parse_args()
    try:
        asyncio.run(main(args))
    except KeyboardInterrupt:
        print("\n\nInterrupted by user")
        sys.exit(130)
    except Exception as e:
        print(f"\nError: {e}", file=sys.stderr)
        sys.exit(1)
