"""Check analyzer-only eligibility using ANALYZER_ARCHITECTURE.md from checkouts."""

import json
from pathlib import Path

from lib.architecture_routing import (
    READINESS_LEVELS,
    analyzer_only_eligibility,
    load_analyzer_only_approvals,
    load_source_audited_empty_categories,
    _baseline_inventory,
)
from lib.component_discovery import (
    apply_component_selection,
    apply_platform_overrides,
    get_component_map_metadata,
    read_component_map,
)
from lib.fetch import load_platform_config


async def run_check_eligibility(args) -> None:
    architecture_dir = getattr(args, "architecture_dir", "architecture")

    components = read_component_map(args.platform, architecture_dir=architecture_dir)
    if components is None:
        print(f"ERROR: No component-map.json found for platform '{args.platform}'")
        print(f"Expected: {architecture_dir}/{args.platform}/component-map.json")
        return

    platform_config = load_platform_config(args.platform)
    if platform_config:
        components = apply_platform_overrides(
            components,
            platform_config,
            checkouts_base=getattr(args, "checkouts_dir", "checkouts"),
        )
    components = apply_component_selection(
        components,
        get_component_map_metadata(args.platform, architecture_dir),
    )

    components = {
        k: v
        for k, v in components.items()
        if v.checkout_path and v.checkout_path.exists()
    }

    requested = getattr(args, "components", None)
    if requested:
        unknown = [c for c in requested if c not in components]
        if unknown:
            print(f"WARNING: Unknown components: {', '.join(unknown)}")
        components = {k: v for k, v in components.items() if k in requested}

    approvals = load_analyzer_only_approvals()
    source_audited_map = load_source_audited_empty_categories()

    total = 0
    eligible_count = 0
    approved_count = 0
    newly_eligible = []
    skipped = 0

    for name in sorted(components):
        comp = components[name]
        checkout = comp.checkout_path
        json_path = checkout / "component-architecture.json"
        markdown_path = checkout / "ANALYZER_ARCHITECTURE.md"

        if not json_path.is_file() or not markdown_path.is_file():
            skipped += 1
            continue

        try:
            analyzer = json.loads(json_path.read_text())
        except (json.JSONDecodeError, OSError):
            skipped += 1
            continue

        detail = str(
            analyzer.get("data_coverage", {}).get("agent_baseline", "")
        ).strip()
        readiness = detail.split(":", 1)[0].strip().casefold()
        if readiness not in READINESS_LEVELS or readiness != "sufficient":
            skipped += 1
            continue

        total += 1
        _, empty_categories = _baseline_inventory(markdown_path)
        component_name = str(analyzer.get("component") or checkout.name)
        source_audited = source_audited_map.get(component_name, frozenset())

        eligible, reason = analyzer_only_eligibility(
            readiness, analyzer, empty_categories, source_audited=source_audited,
        )
        approved = component_name in approvals

        if eligible:
            eligible_count += 1
            if approved:
                approved_count += 1
                print(f"{name}: eligible=True approved=True reason=\"{reason}\"")
            else:
                newly_eligible.append(name)
                print(f"{name}: eligible=True approved=False reason=\"{reason}\"")
        else:
            print(f"{name}: eligible=False reason=\"{reason}\"")

    print()
    print(
        f"Checked {total} sufficient components"
        f" (skipped {skipped} without analyzer data): "
        f"{eligible_count} eligible, {approved_count} approved, "
        f"{len(newly_eligible)} newly eligible (not yet approved)"
    )
    if newly_eligible:
        print(f"Newly eligible: {', '.join(newly_eligible)}")
