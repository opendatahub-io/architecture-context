"""Phase 2: Parse component manifests."""

from pathlib import Path

from lib.cli import resolve_script_path
from lib.manifest_parser import (
    components_to_json,
    display_component_summary,
    process_manifest_script,
)


async def run_manifest_phase(args) -> None:
    """Run Phase 2: Parse manifests."""
    # Only show header for summary format
    output_format = getattr(args, 'format', 'summary')

    if output_format == 'summary':
        print("\n" + "=" * 60)
        print("PHASE 2: Parsing component manifests")
        print("=" * 60 + "\n")

    # Resolve script path
    script_path = resolve_script_path(
        platform=args.platform,
        org=args.org,
        branch=args.branch,
        suffix=getattr(args, 'suffix', None),
        checkouts_dir=args.checkouts_dir,
        script_path=args.script_path,
    )

    # Process manifests (silent - returns structured data)
    components = process_manifest_script(
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
