"""Orchestration: run_all_phases and main dispatch."""

import re
import sys
from argparse import Namespace
from pathlib import Path

from lib.cli import resolve_org_dir

from lib.phases.fetch import run_fetch_phase
from lib.phases.manifest import run_manifest_phase
from lib.phases.discover import run_discover_components_phase
from lib.phases.architecture import run_generate_architecture_phase
from lib.phases.collect import run_collect_architectures_phase
from lib.phases.platform import run_generate_platform_architecture_phase
from lib.phases.diagrams import run_generate_diagrams_phase


async def run_all_phases(args) -> None:
    """Run all phases in sequence."""
    # Auto-detect org if not provided
    org = args.org
    if not org:
        org = "opendatahub-io" if args.platform == "odh" else "red-hat-data-services"

    # Determine target version: explicit --version > extracted from --branch > auto-detect
    target_version = getattr(args, 'version', None)
    if not target_version and args.platform == "rhoai" and args.branch:
        version_match = re.search(r'rhoai-([0-9][0-9a-zA-Z._-]*)', args.branch)
        if version_match:
            target_version = version_match.group(1)

    print("\n" + "=" * 80)
    print("RUNNING ALL PHASES")
    print(f"Platform: {args.platform}")
    print(f"Organization: {org}")
    if args.branch:
        print(f"Branch: {args.branch}")
    if target_version:
        print(f"Target Version: {target_version}")
    print(f"Model: {getattr(args, 'model', 'sonnet')}")
    print("=" * 80 + "\n")

    # Phase 1: Fetch repositories
    fetch_args = Namespace(
        org=getattr(args, 'org', None),
        platform=args.platform,
        checkouts_dir="checkouts",
        branch=getattr(args, 'branch', None),
        suffix=getattr(args, 'suffix', None),
        exclude=None,
    )
    await run_fetch_phase(fetch_args)

    # Phase 2: Parse manifests (not needed for display, but validates checkouts)
    manifest_args = Namespace(
        platform=args.platform,
        org=org,
        branch=getattr(args, 'branch', None),
        suffix=getattr(args, 'suffix', None),
        checkouts_dir="checkouts",
        script_path=None,
        format="summary"
    )
    await run_manifest_phase(manifest_args)

    # Phase 3: Generate component architectures
    max_concurrent = getattr(args, 'max_concurrent', 5)
    generate_arch_args = Namespace(
        platform=args.platform,
        org=org,
        branch=getattr(args, 'branch', None),
        suffix=getattr(args, 'suffix', None),
        checkouts_dir="checkouts",
        script_path=None,
        max_concurrent=max_concurrent,
        limit=None,
        component=None,
        force=False,
        model=getattr(args, 'model', 'sonnet')
    )
    await run_generate_architecture_phase(generate_arch_args)

    # Pre-create architecture directory structure before collect phase
    # This ensures the directory exists even if collect hasn't run yet
    if target_version:
        arch_dir = Path("architecture") / f"{args.platform}-{target_version}"
        arch_dir.mkdir(parents=True, exist_ok=True)
        print(f"\nPre-created architecture directory: {arch_dir}\n")
    else:
        # For ODH or when no specific version, try to detect from operator Makefile
        sys.path.insert(0, str(Path(__file__).resolve().parent.parent.parent / "scripts"))
        from collect_architectures import get_version_from_makefile
        operator_name = "opendatahub-operator" if args.platform == "odh" else "rhods-operator"
        org_dir = resolve_org_dir(org, suffix=getattr(args, 'suffix', None), branch=args.branch)
        operator_dir = Path("checkouts") / org_dir / operator_name
        if operator_dir.exists():
            makefile_path = operator_dir / "Makefile"
            version = get_version_from_makefile(makefile_path)
            if version:
                arch_dir = Path("architecture") / f"{args.platform}-{version}"
                arch_dir.mkdir(parents=True, exist_ok=True)
                print(f"\nPre-created architecture directory: {arch_dir}\n")

    # Phase 4: Collect architectures into organized structure
    # Filter to specific version if branch was provided
    collect_args = Namespace(
        checkouts_dir="checkouts",
        output_dir="architecture",
        platform=args.platform,  # Filter to only this platform
        version=target_version  # Filter to specific version from branch
    )
    await run_collect_architectures_phase(collect_args)

    # Phase 5: Generate platform-level architecture
    # Use target_version to filter to specific version if branch was provided
    platform_arch_args = Namespace(
        architecture_dir="architecture",
        checkouts_dir="checkouts",
        platform=args.platform,
        version=target_version,  # Filter to specific version from branch
        max_concurrent=max_concurrent,
        limit=None,
        model=getattr(args, 'model', 'sonnet')
    )
    await run_generate_platform_architecture_phase(platform_arch_args)

    # Phase 6: Generate diagrams
    # Use target_version to filter to specific version if branch was provided
    diagrams_args = Namespace(
        architecture_dir="architecture",
        platform=args.platform,
        version=target_version,  # Filter to specific version from branch
        max_concurrent=max_concurrent,
        limit=None,
        force_regenerate=False,
        model=getattr(args, 'model', 'sonnet')
    )
    await run_generate_diagrams_phase(diagrams_args)

    print("\n" + "=" * 80)
    print("ALL PHASES COMPLETED SUCCESSFULLY!")
    print("=" * 80)
    print(f"\nResults:")
    print(f"  - Component architectures: checkouts/{resolve_org_dir(org, suffix=getattr(args, 'suffix', None), branch=args.branch)}/*/GENERATED_ARCHITECTURE.md")
    print(f"  - Organized architectures: architecture/{args.platform}-*/")
    print(f"  - Platform documents: architecture/{args.platform}-*/PLATFORM.md")
    print(f"  - Diagrams: architecture/{args.platform}-*/diagrams/")
    print("=" * 80 + "\n")


async def main(args) -> None:
    """Main entry point - dispatch to appropriate phase."""
    if args.command == "fetch":
        await run_fetch_phase(args)
    elif args.command == "parse-manifests":
        await run_manifest_phase(args)
    elif args.command == "discover-components":
        await run_discover_components_phase(args)
    elif args.command == "generate-architecture":
        await run_generate_architecture_phase(args)
    elif args.command == "collect-architectures":
        await run_collect_architectures_phase(args)
    elif args.command == "generate-platform-architecture":
        await run_generate_platform_architecture_phase(args)
    elif args.command == "generate-diagrams":
        await run_generate_diagrams_phase(args)
    elif args.command == "all":
        await run_all_phases(args)
    else:
        print("Error: No command specified. Use --help for usage information.")
        sys.exit(1)
