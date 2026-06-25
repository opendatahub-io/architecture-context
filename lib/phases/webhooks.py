"""Phase 4b: Webhook inventory and cross-cutting analysis."""

from pathlib import Path

from lib.component_discovery import read_component_map
from lib.fetch import load_platform_config
from lib.webhook_analyzer import (
    assign_go_handlers,
    assign_overlays,
    build_cross_cutting_map,
    build_webhook_ref_maps,
    collect_webhooks,
    discover_conversion_webhooks,
    discover_webhooks_from_go,
    enrich_component_json,
    enrich_component_markdown,
    extract_go_patterns,
    load_component_crds,
    map_go_handlers,
    merge_discovered_webhooks,
    resolve_overlays,
    run_webhook_agent_analysis,
    write_platform_webhooks,
)


def _resolve_version_dir(
    architecture_dir: str, platform: str, version: str | None = None,
) -> str | None:
    """Find the versioned directory for this platform."""
    arch_path = Path(architecture_dir)

    if version:
        candidate = arch_path / f"{platform}-{version}"
        if candidate.exists():
            return candidate.name
        candidate = arch_path / version
        if candidate.exists():
            return candidate.name

    # Prefer exact match first
    exact = arch_path / platform
    if exact.is_dir() and any(exact.glob("*.json")):
        return exact.name

    # Fall back to latest matching directory
    for d in sorted(arch_path.iterdir(), reverse=True):
        if d.is_dir() and d.name.startswith(platform):
            has_json = any(d.glob("*.json"))
            if has_json:
                return d.name

    return None


def _find_operator_checkout(
    platform: str,
    checkouts_dir: str = "checkouts",
) -> Path | None:
    """Find the operator checkout directory for this platform."""
    checkouts = Path(checkouts_dir)
    if not checkouts.exists():
        return None

    if platform.startswith("odh"):
        operator_name = "opendatahub-operator"
    else:
        operator_name = "rhods-operator"

    for org_dir in sorted(checkouts.iterdir()):
        if not org_dir.is_dir():
            continue
        match = (
            platform.replace("rhoai", "") in org_dir.name
            or "red-hat-data-services" in org_dir.name
        )
        if match:
            candidate = org_dir / operator_name
            if candidate.exists():
                return candidate

    for org_dir in sorted(checkouts.iterdir()):
        if not org_dir.is_dir():
            continue
        candidate = org_dir / operator_name
        if candidate.exists():
            return candidate

    return None


def _build_component_repos(
    components: dict,
    checkouts_dir: str = "checkouts",
) -> dict[str, Path]:
    """Build {component_key: checkout_path} for components that have checkouts."""
    repos = {}
    for key, comp in components.items():
        path = getattr(comp, 'checkout_path', None)
        if not path:
            continue
        p = Path(path)
        if p.exists():
            repos[key] = p
            continue
        # Component map may have absolute paths from a different machine.
        # Try to re-root under the local checkouts directory.
        parts = p.parts
        for i, part in enumerate(parts):
            if part == "checkouts" and i + 1 < len(parts):
                local = Path(checkouts_dir) / "/".join(parts[i + 1:])
                if local.exists():
                    repos[key] = local
                    break
    return repos


async def run_webhook_inventory_phase(args) -> None:
    """Run Phase 4b: Webhook inventory and cross-cutting analysis."""
    print("\n" + "=" * 60)
    print("PHASE 4b: Webhook inventory")
    print("=" * 60 + "\n")

    architecture_dir = getattr(args, 'architecture_dir', 'architecture')
    checkouts_dir = getattr(args, 'checkouts_dir', 'checkouts')
    force = getattr(args, 'force', False)

    platform_version = _resolve_version_dir(
        architecture_dir, args.platform,
        version=getattr(args, 'version', None),
    )
    if not platform_version:
        print(f"ERROR: No architecture directory found for platform '{args.platform}'")
        return

    version_dir = Path(architecture_dir) / platform_version
    output_path = version_dir / "webhooks.json"
    if output_path.exists() and not force:
        print(f"webhooks.json already exists: {output_path}")
        print("Use --force to regenerate")
        return

    print(f"Platform version: {platform_version}")
    print(f"Architecture dir: {version_dir}")

    # Step 1: Collect webhooks from architecture JSON files
    print("\n--- Step 1: Collecting webhooks from component JSONs ---")
    webhooks = collect_webhooks(architecture_dir, platform_version)
    comp_count = len({w.component for w in webhooks})
    print(f"Found {len(webhooks)} webhooks across {comp_count} components")

    if not webhooks:
        print("No webhooks found. Skipping remaining steps.")
        return

    # Step 1b: Load component map for checkout paths (needed for Go discovery)
    components = read_component_map(args.platform, architecture_dir=architecture_dir)
    component_repos = {}
    if components:
        platform_config = load_platform_config(args.platform)
        if platform_config:
            from lib.component_discovery import apply_platform_overrides
            components = apply_platform_overrides(
                components, platform_config, checkouts_base=checkouts_dir,
            )
        component_repos = _build_component_repos(components, checkouts_dir)
        print(f"Component checkouts available: {len(component_repos)}")

    # Step 2: Discover webhooks from Go kubebuilder markers (fills arch-analyzer gaps)
    print("\n--- Step 2: Discovering webhooks from Go source ---")
    if component_repos:
        discovered = discover_webhooks_from_go(component_repos)
        before = len(webhooks)
        webhooks = merge_discovered_webhooks(webhooks, discovered)
        added = len(webhooks) - before
        print(
            f"Discovered {len(discovered)} webhooks from Go markers,"
            f" {added} new (not in arch-analyzer)"
        )
        comp_count = len({w.component for w in webhooks})
        print(f"Total webhooks: {len(webhooks)} across {comp_count} components")
    else:
        print("WARNING: No component checkouts, skipping Go discovery")

    # Step 2b: Discover conversion webhooks from CRD patches and Go source
    if component_repos:
        conversion = discover_conversion_webhooks(component_repos)
        before = len(webhooks)
        webhooks = merge_discovered_webhooks(webhooks, conversion)
        conv_added = len(webhooks) - before
        print(f"Discovered {len(conversion)} conversion webhooks, {conv_added} new")
        comp_count = len({w.component for w in webhooks})
        print(f"Total webhooks: {len(webhooks)} across {comp_count} components")

    # Step 3: Resolve overlay membership
    print("\n--- Step 3: Resolving kustomize overlays ---")
    operator_checkout = _find_operator_checkout(args.platform, checkouts_dir)
    overlay_map: dict[str, list[str]] = {}
    if operator_checkout:
        print(f"Operator checkout: {operator_checkout}")
        overlay_map = resolve_overlays(operator_checkout)
        assign_overlays(webhooks, overlay_map)
        overlays_found = [
            f"{name} ({len(files)} files)"
            for name, files in overlay_map.items()
        ]
        found = ", ".join(overlays_found) if overlays_found else "none"
        print(f"Overlays found: {found}")
    else:
        print("WARNING: No operator checkout found, skipping overlay resolution")

    # Step 4: Map webhook paths to Go handler files
    print("\n--- Step 4: Mapping Go handlers ---")
    if component_repos:
        handler_map = map_go_handlers(Path(checkouts_dir), component_repos)
        assign_go_handlers(webhooks, handler_map)
        mapped_count = sum(
            1 for wh in webhooks
            if any(s.get("type") == "go_handler" for s in wh.sources)
        )
        print(f"Mapped {mapped_count}/{len(webhooks)} webhooks to Go handlers")
    else:
        print("WARNING: No component checkouts, skipping Go handler mapping")

    # Step 5: Extract Go code patterns
    print("\n--- Step 5: Extracting Go patterns ---")
    if component_repos:
        extract_go_patterns(webhooks, component_repos)
        with_deps = sum(1 for wh in webhooks if wh.data_read)
        with_conditions = sum(1 for wh in webhooks if wh.enable_condition)
        print(f"Data dependencies found: {with_deps} webhooks")
        print(f"Enable conditions found: {with_conditions} webhooks")
    else:
        print("WARNING: No component checkouts, skipping Go pattern extraction")

    # Step 6: Agent analysis of Go webhook handlers
    print("\n--- Step 6: Agent analysis of webhook handlers ---")
    model = getattr(args, 'model', 'sonnet')
    max_concurrent = getattr(args, 'max_concurrent', 5)
    if component_repos:
        wh_strace_prefix = (
            f"{args.platform}-webhook-inventory"
            if getattr(args, 'strace', False) else None
        )
        await run_webhook_agent_analysis(
            webhooks, component_repos,
            model=model, max_concurrent=max_concurrent,
            strace_prefix=wh_strace_prefix,
        )
        with_purpose = sum(1 for wh in webhooks if wh.purpose)
        print(f"Webhooks with purpose: {with_purpose}/{len(webhooks)}")
    else:
        print("WARNING: No component checkouts, skipping agent analysis")

    # Step 7: Build cross-cutting concern map
    print("\n--- Step 7: Building cross-cutting concern map ---")
    cross_cutting = build_cross_cutting_map(webhooks)
    for cc in cross_cutting:
        print(f"  {cc['name']}: {len(cc['webhooks'])} webhooks, "
              f"affects {', '.join(cc['affected_types'][:5])}")

    # Step 8: Build platform + external webhooks maps
    print("\n--- Step 8: Building webhook reference maps ---")
    component_crds = load_component_crds(architecture_dir, platform_version, webhooks)
    platform_map, external_map = build_webhook_ref_maps(webhooks, component_crds)
    for comp, refs in sorted(platform_map.items()):
        print(f"  {comp}: {len(refs)} platform webhooks")
    for comp, refs in sorted(external_map.items()):
        print(f"  {comp}: {len(refs)} external webhooks (peer)")

    # Step 9: Write per-component enrichment
    print("\n--- Step 9: Enriching component JSONs ---")
    enriched_count = 0
    for json_file in sorted(version_dir.glob("*.json")):
        if json_file.name in ("component-map.json", "build-info.json", "webhooks.json"):
            continue
        component = json_file.stem
        comp_webhooks = [w for w in webhooks if w.component == component]
        plat_refs = platform_map.get(component, [])
        ext_refs = external_map.get(component, [])
        if comp_webhooks or plat_refs or ext_refs:
            enrich_component_json(json_file, webhooks, plat_refs, ext_refs)
            md_file = json_file.with_suffix(".md")
            if md_file.exists():
                enrich_component_markdown(md_file, webhooks, plat_refs, ext_refs)
            enriched_count += 1

    print(f"Enriched {enriched_count} component JSON files")

    # Step 10: Write platform-wide webhooks.json
    print("\n--- Step 10: Writing webhooks.json ---")
    output = write_platform_webhooks(
        architecture_dir, platform_version,
        webhooks, cross_cutting,
        overlays_analyzed=list(overlay_map.keys()),
    )
    print(f"Written: {output}")

    # Summary
    print("\n" + "=" * 60)
    print("WEBHOOK INVENTORY COMPLETE")
    print("=" * 60)
    print(f"Total webhooks: {len(webhooks)}")
    print(f"  Mutating: {sum(1 for w in webhooks if w.type == 'mutating')}")
    print(f"  Validating: {sum(1 for w in webhooks if w.type == 'validating')}")
    print(f"Components with webhooks: {len({w.component for w in webhooks})}")
    print(f"Cross-cutting concerns: {len(cross_cutting)}")
    print(f"Components with platform webhooks: {len(platform_map)}")
    print(f"Components with external webhooks: {len(external_map)}")
    print(f"Output: {output}")
    print("=" * 60)
