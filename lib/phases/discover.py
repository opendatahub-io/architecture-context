"""Phase 2b: Discover components via breadcrumb exploration."""

import json
from pathlib import Path

from lib.agent_runner import run_agent
from lib.component_discovery import get_component_map_metadata
from lib.fetch import load_platform_config


def _apply_map_overrides(map_file: Path, platform_config: dict) -> None:
    """Move include_components entries from excluded to components in the JSON."""
    includes = platform_config.get("include_components", [])
    excludes = platform_config.get("exclude_components", [])
    if not includes and not excludes:
        return

    data = json.loads(map_file.read_text())
    components = data.get("components", {})
    excluded = data.get("excluded", {})
    changed = False

    # Pull include_components out of excluded into components
    for entry in includes:
        key = entry["key"]
        if key in excluded and key not in components:
            del excluded[key]
            suffix = platform_config.get("suffix")
            repo_org = entry.get("repo_org")
            repo_name = entry.get("repo_name", key)
            org_dir = f"{repo_org}.{suffix}" if suffix and repo_org else repo_org
            checkout_path = None
            if org_dir:
                for candidate_dir in [org_dir, repo_org]:
                    candidate = Path("checkouts") / candidate_dir / repo_name
                    if candidate.exists():
                        checkout_path = str(candidate.resolve())
                        break
            components[key] = {
                "key": key,
                "repo_org": repo_org,
                "repo_name": repo_name,
                "checkout_path": checkout_path,
                "type": entry.get("type"),
                "tier": "payload_component",
                "has_architecture": False,
            }
            print(f"  Promoted from excluded to components: {key}")
            changed = True

    # Remove exclude_components from components
    import fnmatch
    for key in list(components.keys()):
        for pattern in excludes:
            if fnmatch.fnmatch(key, pattern):
                del components[key]
                excluded[key] = "excluded_via_platforms_yaml"
                print(f"  Demoted from components to excluded: {key}")
                changed = True
                break

    if changed:
        data["components"] = components
        data["excluded"] = excluded
        data["metadata"]["components_discovered"] = len(components)
        data["metadata"]["components_excluded"] = len(excluded)
        map_file.write_text(json.dumps(data, indent=2) + "\n")
        print(f"  Updated {map_file}")


async def run_discover_components_phase(args) -> None:
    """Run Phase 2b: Discover components via breadcrumb exploration."""
    print("\n" + "=" * 60)
    print("PHASE 2B: Discovering platform components")
    print("=" * 60 + "\n")

    architecture_dir = str(
        Path(getattr(args, 'architecture_dir', 'architecture')).resolve()
    )
    map_file = Path(architecture_dir) / args.platform / "component-map.json"
    force = getattr(args, 'force', False)

    if map_file.exists() and not force:
        print(f"Component map already exists: {map_file}")
        print("Skipping discovery (use --force to re-run)\n")
        print("=" * 60)
        return

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
                org_suffix = (
                    entry.get("suffix")
                    if isinstance(entry, dict)
                    else None
                ) or suffix
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
                print(
                    f"Error: no orgs defined for platform"
                    f" '{args.platform}' in platforms.yaml"
                )
                return
        except (FileNotFoundError, KeyError) as e:
            print(
                f"Error: --checkouts-dir is required"
                f" (could not resolve from platforms.yaml: {e})"
            )
            return

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
            exclude_patterns = (
                f"{exclude_patterns},{combined}"
                if exclude_patterns
                else combined
            )

    exclude_part = (
        f" --exclude={exclude_patterns}"
        if exclude_patterns else ""
    )
    entry_part = (
        f" --entry-repo={args.entry_repo}"
        if getattr(args, 'entry_repo', None) else ""
    )
    checkouts_parts = " ".join(
        f"--checkouts-dir={d}" for d in checkouts_dirs
    )

    prompt = (
        f"/discover-components --platform={args.platform}"
        f" {checkouts_parts}{entry_part}{exclude_part}"
        f" --architecture-dir={architecture_dir}"
    )

    log_dir = Path("logs/discover-components")
    log_dir.mkdir(parents=True, exist_ok=True)

    model = getattr(args, 'model', 'opus')
    print("Running component discovery with Skills enabled (SDK)...")
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

            # Apply include_components / exclude_components from platforms.yaml
            if platform_config:
                _apply_map_overrides(map_file, platform_config)

            metadata = get_component_map_metadata(args.platform, architecture_dir)
            if metadata:
                print("\nDiscovery summary:")
                print(f"  Method: {metadata.get('discovery_method', 'N/A')}")
                repos = metadata.get('total_repos_scanned', 'N/A')
                discovered = metadata.get(
                    'components_discovered', 'N/A',
                )
                excluded = metadata.get(
                    'components_excluded', 'N/A',
                )
                print(f"  Total repos scanned: {repos}")
                print(f"  Components discovered: {discovered}")
                print(f"  Components excluded: {excluded}")
        else:
            print("Component map not found (agent may have failed)")
    else:
        print("COMPONENT DISCOVERY FAILED")
        print("=" * 60)
        print(f"Error: {result.get('error', 'Unknown error')}")

    if result.get('log_file'):
        print(f"\nAgent log: {result['log_file']}")

    print("=" * 60)
