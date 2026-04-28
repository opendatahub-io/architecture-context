"""Phase 2b: Discover components via breadcrumb exploration."""

from pathlib import Path

from lib.fetch import load_platform_config
from lib.component_discovery import get_component_map_metadata
from lib.agent_runner import run_agent


async def run_discover_components_phase(args) -> None:
    """Run Phase 2b: Discover components via breadcrumb exploration."""
    print("\n" + "=" * 60)
    print("PHASE 2B: Discovering platform components")
    print("=" * 60 + "\n")

    platform_config = None
    checkouts_dirs = []

    if getattr(args, 'checkouts_dir', None):
        checkouts_dirs = [args.checkouts_dir]
    else:
        try:
            platform_config = load_platform_config(args.platform)
            suffix = platform_config.get("suffix", "head")

            for org in platform_config.get("orgs", []):
                checkouts_dirs.append(f"checkouts/{org}.{suffix}")

            for entry in platform_config.get("extra_orgs", []):
                org_name = entry.get("org") if isinstance(entry, dict) else entry
                org_suffix = (entry.get("suffix") if isinstance(entry, dict) else None) or suffix
                checkouts_dirs.append(f"checkouts/{org_name}.{org_suffix}")

            for entry in platform_config.get("extra_repos", []):
                repo_suffix = entry.get("suffix") or suffix
                org_dir = f"checkouts/{entry['org']}.{repo_suffix}"
                if org_dir not in checkouts_dirs:
                    checkouts_dirs.append(org_dir)

            if checkouts_dirs:
                print("Resolved checkout directories from platforms.yaml:")
                for d in checkouts_dirs:
                    print(f"  - {d}")
            else:
                print(f"Error: no orgs defined for platform '{args.platform}' in platforms.yaml")
                return
        except (FileNotFoundError, KeyError) as e:
            print(f"Error: --checkouts-dir is required (could not resolve from platforms.yaml: {e})")
            return

    architecture_dir = str(Path(getattr(args, 'architecture_dir', 'architecture')).resolve())

    print(f"Platform: {args.platform}")
    if getattr(args, 'entry_repo', None):
        print(f"Entry point: {args.entry_repo}")
    print()

    checkouts_dirs = [str(Path(d).resolve()) for d in checkouts_dirs]

    exclude_patterns = getattr(args, 'exclude', '') or ''
    if platform_config:
        config_excludes = platform_config.get("exclude_repos", [])
        if config_excludes:
            combined = ",".join(config_excludes)
            exclude_patterns = f"{exclude_patterns},{combined}" if exclude_patterns else combined

    exclude_part = f" --exclude={exclude_patterns}" if exclude_patterns else ""
    entry_part = f" --entry-repo={args.entry_repo}" if getattr(args, 'entry_repo', None) else ""
    checkouts_parts = " ".join(f"--checkouts-dir={d}" for d in checkouts_dirs)

    prompt = f"/discover-components --platform={args.platform} {checkouts_parts}{entry_part}{exclude_part} --architecture-dir={architecture_dir}"

    log_dir = Path("logs/discover-components")
    log_dir.mkdir(parents=True, exist_ok=True)

    model = getattr(args, 'model', 'opus')
    print(f"Running component discovery with Skills enabled (SDK)...")
    print(f"Model: {model}")
    print(f"Log directory: {log_dir}\n")

    result = await run_agent(
        name=f"discover-{args.platform}",
        cwd=".",
        prompt=prompt,
        log_dir=log_dir,
        model=model,
        enable_skills=True,
    )

    print("\n" + "=" * 60)
    if result.get("success"):
        print("COMPONENT DISCOVERY COMPLETE")
        print("=" * 60)

        map_file = Path(architecture_dir) / args.platform / "component-map.json"
        if map_file.exists():
            print(f"Component map written: {map_file}")

            metadata = get_component_map_metadata(args.platform, architecture_dir)
            if metadata:
                print(f"\nDiscovery summary:")
                print(f"  Method: {metadata.get('discovery_method', 'N/A')}")
                print(f"  Total repos scanned: {metadata.get('total_repos_scanned', 'N/A')}")
                print(f"  Components discovered: {metadata.get('components_discovered', 'N/A')}")
                print(f"  Components excluded: {metadata.get('components_excluded', 'N/A')}")
        else:
            print("Component map not found (agent may have failed)")
    else:
        print("COMPONENT DISCOVERY FAILED")
        print("=" * 60)
        print(f"Error: {result.get('error', 'Unknown error')}")

    if result.get('log_file'):
        print(f"\nAgent log: {result['log_file']}")

    print("=" * 60)
