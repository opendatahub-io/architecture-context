"""Phase 4: Collect and organize architecture files."""

import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent.parent.parent / "scripts"))
from collect_architectures import collect_architectures, print_summary


async def run_collect_architectures_phase(args) -> None:
    """Run Phase 4: Collect and organize architecture files."""
    print("\n" + "=" * 60)
    print("PHASE 4: Collecting component architectures")
    print("=" * 60 + "\n")

    checkouts_dir = Path(args.checkouts_dir)
    output_dir = Path(args.output_dir)

    # Validate checkouts directory
    if not checkouts_dir.exists():
        print(f"Error: Checkouts directory does not exist: {checkouts_dir}")
        return

    # Determine platform filter
    platform_filter = None if args.platform == "all" else args.platform

    # Determine version filter
    version_filter = getattr(args, 'version', None)

    # Run collection
    summary = collect_architectures(checkouts_dir, output_dir, platform_filter, version_filter)

    # Print summary
    print_summary(summary, checkouts_dir, output_dir)
