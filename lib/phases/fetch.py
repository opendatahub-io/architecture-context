"""Phase 1: Fetch repositories."""

from lib.fetch import fetch_repositories


async def run_fetch_phase(args) -> None:
    """Run Phase 1: Fetch repositories."""
    print("\n" + "=" * 60)
    print("PHASE 1: Fetching repositories")
    print("=" * 60 + "\n")

    await fetch_repositories(
        org=getattr(args, 'org', None),
        checkouts_dir=args.checkouts_dir,
        branch=getattr(args, 'branch', None),
        suffix=getattr(args, 'suffix', None),
        exclude=getattr(args, 'exclude', None),
        platform=getattr(args, 'platform', None),
        pull=getattr(args, 'pull', False),
    )
