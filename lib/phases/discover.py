"""Phase 2b: Discover components via breadcrumb exploration."""

import json
import re
import subprocess
import sys
from datetime import datetime, timezone
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


def _parse_sync_config(sync_config_path: Path) -> dict | None:
    """Run parse_sync_config.py and return parsed JSON, or None on error."""
    script = (
        Path(__file__).resolve().parents[1].parent
        / ".claude" / "skills" / "discover-components"
        / "scripts" / "parse_sync_config.py"
    )
    if not script.exists():
        print(f"  Sync config parser not found: {script}")
        return None

    try:
        result = subprocess.run(
            [sys.executable, str(script), str(sync_config_path)],
            capture_output=True, text=True, timeout=30,
        )
    except subprocess.TimeoutExpired:
        print("  WARNING: Sync config parser timed out")
        return None

    if result.returncode != 0:
        print(f"  WARNING: Sync config parser failed (exit {result.returncode})")
        if result.stderr:
            for line in result.stderr.strip().splitlines()[-3:]:
                print(f"    {line}")
        return None

    try:
        return json.loads(result.stdout)
    except json.JSONDecodeError as e:
        print(f"  WARNING: Could not parse sync config output: {e}")
        return None


def _get_synced_repo_names(
    sync_config_data: dict, checkouts_dirs: list[str],
) -> set[str]:
    """Return repo names that appear in the sync config and in our checkouts."""
    repo_index = sync_config_data.get("repo_index", {})
    synced_names = set()

    for cdir in checkouts_dirs:
        cdir_path = Path(cdir)
        if not cdir_path.is_dir():
            continue
        org = cdir_path.name.split(".")[0]
        for d in cdir_path.iterdir():
            if d.is_dir() and not d.name.startswith("."):
                key = f"{org}/{d.name}"
                if key in repo_index:
                    synced_names.add(d.name)

    return synced_names


def _infer_type(repo_name: str) -> str:
    """Infer component type from repo name patterns."""
    lower = repo_name.lower()
    if lower.endswith("-operator"):
        return "operator"
    if lower.endswith("-controller"):
        return "controller"
    if "dashboard" in lower:
        return "ui"
    if lower.endswith("-sdk"):
        return "shared_library"
    return "service"


def _apply_sync_config_components(
    map_file: Path,
    sync_config_data: dict,
    checkouts_dirs: list[str],
    suffix: str,
) -> None:
    """Add sync-config repos as components in the component map."""
    repo_index = sync_config_data.get("repo_index", {})
    if not repo_index:
        return

    data = json.loads(map_file.read_text())
    components = data.get("components", {})
    excluded = data.get("excluded", {})
    changed = False
    added = 0
    promoted = 0

    for cdir in checkouts_dirs:
        cdir_path = Path(cdir)
        if not cdir_path.is_dir():
            continue
        org = cdir_path.name.split(".")[0]
        for d in sorted(cdir_path.iterdir()):
            if not d.is_dir() or d.name.startswith("."):
                continue
            key = f"{org}/{d.name}"
            if key not in repo_index:
                continue

            repo_name = d.name
            if repo_name in components:
                continue

            checkout_path = str(d.resolve())
            has_arch = (d / "GENERATED_ARCHITECTURE.md").exists()

            entry = {
                "key": repo_name,
                "repo_org": org,
                "repo_name": repo_name,
                "repo_url": f"https://github.com/{org}/{repo_name}",
                "checkout_path": checkout_path,
                "has_architecture": has_arch,
                "type": _infer_type(repo_name),
                "tier": "payload_component",
                "shipped": True,
                "architecturally_significant": True,
                "discovered_via": "sync_config",
                "confidence": "high",
            }

            if repo_name in excluded:
                del excluded[repo_name]
                promoted += 1
                print(f"  Sync config: promoted {repo_name} from excluded")
            else:
                added += 1

            components[repo_name] = entry
            changed = True

    if changed:
        data["components"] = components
        data["excluded"] = excluded
        data["metadata"]["components_discovered"] = len(components)
        data["metadata"]["components_excluded"] = len(excluded)
        map_file.write_text(json.dumps(data, indent=2) + "\n")
        total = added + promoted
        print(
            f"  Sync config: {total} repos added"
            f" ({added} new, {promoted} promoted from excluded)"
        )


def _add_provenance(
    map_file: Path,
    checkouts_dirs: list[str],
    sync_config_data: dict | None = None,
) -> None:
    """Run parse_repo_provenance.py and merge results into component-map.json."""
    script = (
        Path(__file__).resolve().parents[1].parent
        / ".claude" / "skills" / "discover-components"
        / "scripts" / "parse_repo_provenance.py"
    )
    if not script.exists():
        print(f"  Provenance script not found: {script}")
        return

    existing_dirs = [d for d in checkouts_dirs if Path(d).is_dir()]
    if not existing_dirs:
        print("  No checkout directories found, skipping provenance")
        return

    # Include downstream org for cross-org provenance if available
    rh_ds = Path("checkouts/red-hat-data-services.next").resolve()
    if rh_ds.is_dir() and str(rh_ds) not in existing_dirs:
        existing_dirs.append(str(rh_ds))

    print("  Running repo provenance analysis...")
    try:
        result = subprocess.run(
            [sys.executable, str(script)] + existing_dirs,
            capture_output=True, text=True, timeout=300,
        )
    except subprocess.TimeoutExpired:
        print("  WARNING: Provenance script timed out, skipping")
        return

    if result.returncode != 0:
        print(f"  WARNING: Provenance script failed (exit {result.returncode})")
        if result.stderr:
            for line in result.stderr.strip().splitlines()[-3:]:
                print(f"    {line}")
        return

    try:
        provenance = json.loads(result.stdout)
    except json.JSONDecodeError as e:
        print(f"  WARNING: Could not parse provenance output: {e}")
        return

    if "metadata" in provenance:
        provenance["metadata"]["generated_at"] = (
            datetime.now(timezone.utc).isoformat()
        )

    # Overlay sync config data onto provenance
    if sync_config_data:
        repo_index = sync_config_data.get("repo_index", {})
        prov_repos = provenance.get("repos", {})
        enriched = 0
        for repo_key, sc_info in repo_index.items():
            if repo_key in prov_repos:
                pr = prov_repos[repo_key]
                pr["sync_mechanism"] = sc_info["sync_mechanism"]
                if sc_info.get("sync_branch"):
                    pr["sync_branch"] = sc_info["sync_branch"]
                if sc_info.get("upstream") and not pr.get("upstream"):
                    pr["upstream"] = sc_info["upstream"]
                    pr["upstream_detection"] = "sync_config"
                    pr["is_fork"] = True
                if sc_info.get("downstream"):
                    existing_ds = set(pr.get("downstream", []))
                    for ds in sc_info["downstream"]:
                        if ds not in existing_ds:
                            pr.setdefault("downstream", []).append(ds)
                    if pr.get("downstream"):
                        pr["downstream_detection"] = "sync_config"
                enriched += 1
            else:
                sc_org, _, sc_repo = repo_key.partition("/")
                prov_repos[repo_key] = {
                    "org": sc_org,
                    "repo": sc_repo,
                    "is_fork": bool(sc_info.get("upstream")),
                    "upstream": sc_info.get("upstream"),
                    "upstream_detection": "sync_config" if sc_info.get("upstream") else None,
                    "downstream": sc_info.get("downstream", []),
                    "downstream_detection": "sync_config" if sc_info.get("downstream") else None,
                    "sync_mechanism": sc_info["sync_mechanism"],
                    "sync_branch": sc_info.get("sync_branch"),
                    "sync_workflows": [],
                }
                enriched += 1
        provenance["repos"] = prov_repos
        if enriched:
            print(f"  Sync config enriched {enriched} provenance entries")

    data = json.loads(map_file.read_text())
    data["provenance"] = provenance
    map_file.write_text(json.dumps(data, indent=2) + "\n")

    repos_total = provenance.get("metadata", {}).get("total_repos", 0)
    with_upstream = provenance.get("metadata", {}).get("repos_with_upstream", 0)
    with_downstream = provenance.get("metadata", {}).get(
        "repos_with_downstream", 0,
    )
    print(
        f"  Provenance added: {repos_total} repos"
        f" ({with_upstream} with upstream,"
        f" {with_downstream} with downstream)"
    )


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

    # Validate and parse sync config if declared
    sync_config_path = None
    sync_config_data = None
    if platform_config:
        sync_config = platform_config.get("sync_config")
        if sync_config:
            sc_suffix = platform_config.get("suffix", "head")
            sc_org = sync_config["org"]
            sc_repo = sync_config["repo"]
            sc_map = sync_config["upstream_map"]
            sync_config_path = (
                Path("checkouts")
                / f"{sc_org}.{sc_suffix}"
                / sc_repo
                / sc_map
            )
            if not sync_config_path.exists():
                print(
                    f"Error: sync config not found: {sync_config_path}\n"
                    f"Run 'python -m lib.main fetch --platform={args.platform}'"
                    " to clone the sync config repo first."
                )
                return

            sync_config_data = _parse_sync_config(sync_config_path)
            if sync_config_data:
                meta = sync_config_data.get("metadata", {})
                print(
                    f"Sync config: {sync_config_path}"
                    f" ({meta.get('total_sync_rules', 0)} rules,"
                    f" {meta.get('auto_merge_count', 0)} auto-merge)"
                )
            else:
                print(f"Sync config: {sync_config_path} (parse failed, continuing without)")

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

    # Exclude sync-config repos from agent — they'll be added in post-processing
    if sync_config_data:
        synced_names = _get_synced_repo_names(sync_config_data, checkouts_dirs)
        if synced_names:
            synced_csv = ",".join(sorted(synced_names))
            exclude_patterns = (
                f"{exclude_patterns},{synced_csv}"
                if exclude_patterns
                else synced_csv
            )
            print(f"Excluding {len(synced_names)} sync-config repos from agent classification")

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

    strace_dir = None
    if getattr(args, 'strace', False):
        safe_platform = re.sub(r"[^a-zA-Z0-9._-]", "_", args.platform)
        strace_dir = (
            Path("logs/strace")
            / f"{safe_platform}-discover-components-discover-{safe_platform}"
        )

    result = await run_agent(
        name=f"discover-{args.platform}",
        cwd=".",
        prompt=prompt,
        log_dir=log_dir,
        model=model,
        enable_skills=True,
        strace_dir=strace_dir,
    )

    print("\n" + "=" * 60)
    if result.get("success"):
        print("COMPONENT DISCOVERY COMPLETE")
        print("=" * 60)

        map_file = Path(architecture_dir) / args.platform / "component-map.json"
        if map_file.exists():
            print(f"Component map written: {map_file}")

            # Add sync-config repos as components
            if sync_config_data:
                sc_suffix = platform_config.get("suffix", "head") if platform_config else "head"
                _apply_sync_config_components(
                    map_file, sync_config_data, checkouts_dirs, sc_suffix,
                )

            # Apply include_components / exclude_components from platforms.yaml
            if platform_config:
                _apply_map_overrides(map_file, platform_config)

            # Add repo provenance (upstream/downstream/sync relationships)
            _add_provenance(map_file, checkouts_dirs, sync_config_data)

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
