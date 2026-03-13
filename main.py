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
from lib.manifest_parser import process_manifest_script

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
        "--script-path",
        default="checkouts/opendatahub-operator/get_all_manifests.sh",
        help="Path to get_all_manifests.sh script"
    )

    # All phases
    all_parser = subparsers.add_parser(
        "all",
        help="Run all phases in sequence"
    )
    all_parser.add_argument(
        "--org",
        default="red-hat-data-services",
        help="GitHub organization to clone (default: red-hat-data-services)"
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
    print("\n" + "=" * 60)
    print("PHASE 2: Parsing component manifests")
    print("=" * 60 + "\n")

    components = await process_manifest_script(args.script_path)
    print(f"\nProcessed {len(components)} components successfully")


async def run_all_phases(args) -> None:
    """Run all phases in sequence."""
    # Create a namespace-like object for each phase
    class FetchArgs:
        org = args.org
        checkouts_dir = "checkouts"
        branch = None

    class ManifestArgs:
        script_path = "checkouts/opendatahub-operator/get_all_manifests.sh"

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
