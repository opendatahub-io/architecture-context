"""Orchestration: run_all_phases and main dispatch."""

import re
import shutil
import sys
from argparse import Namespace
from datetime import UTC, datetime
from pathlib import Path

from lib.component_discovery import read_component_map
from lib.fetch import load_platform_config
from lib.phases.architecture import run_generate_architecture_phase
from lib.phases.diagrams import run_generate_diagrams_phase
from lib.phases.discover import run_discover_components_phase
from lib.phases.fetch import run_fetch_phase
from lib.phases.manifest import run_manifest_phase
from lib.phases.platform import run_generate_platform_architecture_phase
from lib.phases.static_analysis import run_static_analysis_phase

COMPONENT_SCOPED_PHASES = frozenset({
    "static-analysis",
    "generate-architecture",
    "generate-diagrams",
})


def _clean_generated_outputs(
    platform: str,
    platform_config: dict,
    suffix: str,
) -> None:
    """Delete all generated artifacts so phases rebuild from scratch."""
    print("\n" + "=" * 60)
    print("CLEAN: removing generated outputs")
    print("=" * 60 + "\n")

    # Clean architecture directory for this platform
    arch_base = Path("architecture")
    arch_cleaned = 0
    for arch_dir in arch_base.iterdir():
        if not arch_dir.is_dir() or arch_dir.is_symlink():
            continue
        if not arch_dir.name.startswith(platform):
            continue
        remainder = arch_dir.name[len(platform):]
        if remainder and not remainder.startswith("-"):
            continue
        for item in list(arch_dir.iterdir()):
            if item.name == "README.md":
                continue
            if item.is_dir():
                shutil.rmtree(item)
            else:
                item.unlink()
            arch_cleaned += 1
    print(f"  Cleaned {arch_cleaned} file(s) from architecture/")
    print()


async def run_all_phases(args) -> None:
    """Run all phases in sequence."""
    # Load platform config for org/suffix/branch defaults
    platform_config = load_platform_config(args.platform)

    # Auto-detect org if not provided
    org = args.org
    if not org:
        orgs = platform_config.get("orgs", [])
        org = orgs[0] if orgs else (
            "opendatahub-io"
            if args.platform == "odh"
            else "red-hat-data-services"
        )

    # Resolve suffix: CLI --suffix > config suffix > branch fallback
    suffix = getattr(args, 'suffix', None)
    branch = getattr(args, 'branch', None)
    if not suffix:
        suffix = platform_config.get("suffix")
    if not branch:
        branch = platform_config.get("branch")
    if not suffix and branch:
        suffix = branch

    # Determine target version:
    # explicit --version > extracted from --branch > auto-detect
    # Skip extraction when the platform name already contains the version
    # (e.g., platform="rhoai-2.25" with branch="rhoai-2.25" would produce
    # a doubled directory like "rhoai-2.25-2.25")
    target_version = getattr(args, 'version', None)
    if not target_version and args.platform.startswith("rhoai") and branch:
        version_match = re.search(r'rhoai-([0-9][0-9a-zA-Z._-]*)', branch)
        if version_match:
            extracted = version_match.group(1)
            if not args.platform.endswith(f"-{extracted}"):
                target_version = extracted

    clean = getattr(args, 'clean', False)
    force = getattr(args, 'force', False) or clean

    if clean:
        _clean_generated_outputs(args.platform, platform_config, suffix)

    print("\n" + "=" * 80)
    print("RUNNING ALL PHASES")
    print(f"Platform: {args.platform}")
    print(f"Organization: {org}")
    print(f"Suffix: {suffix}")
    if branch:
        print(f"Branch: {branch}")
    if target_version:
        print(f"Target Version: {target_version}")
    print(f"Model: {getattr(args, 'model', 'opus')}")
    print("=" * 80 + "\n")

    # Phase 1: Fetch repositories
    fetch_args = Namespace(
        org=getattr(args, 'org', None),
        platform=args.platform,
        checkouts_dir="checkouts",
        branch=branch,
        suffix=suffix,
        exclude=None,
        pull=getattr(args, 'pull', False),
    )
    await run_fetch_phase(fetch_args)

    # Phase 2: Parse manifests (not needed for display, but validates checkouts)
    manifest_args = Namespace(
        platform=args.platform,
        org=org,
        branch=branch,
        suffix=suffix,
        checkouts_dir="checkouts",
        script_path=None,
        format="summary"
    )
    await run_manifest_phase(manifest_args)

    strace = getattr(args, 'strace', False)

    # Phase 2b: Discover components
    discover_args = Namespace(
        platform=args.platform,
        checkouts_dir=None,
        architecture_dir="architecture",
        entry_repo=None,
        exclude=None,
        model=getattr(args, 'model', 'opus'),
        force=force,
        strace=strace,
    )
    await run_discover_components_phase(discover_args)

    # Phase 2c: Static analysis (arch-analyzer)
    static_analysis_args = Namespace(
        platform=args.platform,
        architecture_dir="architecture",
        max_concurrent=10,
        component=None,
        force=force,
        skip_schemas=False,
    )
    await run_static_analysis_phase(static_analysis_args)

    # Phase 3: Generate component architectures
    max_concurrent = getattr(args, 'max_concurrent', 5)
    generate_arch_args = Namespace(
        platform=args.platform,
        architecture_dir="architecture",
        max_concurrent=max_concurrent,
        limit=None,
        component=None,
        force=force,
        version=target_version or args.platform,
        evidence_gated_merge=getattr(args, 'evidence_gated_merge', True),
        model=getattr(args, 'model', 'opus'),
        tier=getattr(args, 'tier', 'all'),
        strace=strace,
    )
    await run_generate_architecture_phase(generate_arch_args)

    # Phase 4: Generate platform-level architecture
    # Use target_version to filter to specific version if branch was provided
    platform_arch_args = Namespace(
        architecture_dir="architecture",
        platform=args.platform,
        version=target_version,
        max_concurrent=max_concurrent,
        limit=None,
        force=force,
        model=getattr(args, 'model', 'opus'),
        strace=strace,
    )
    await run_generate_platform_architecture_phase(platform_arch_args)

    # Phase 5: Generate diagrams
    if getattr(args, 'no_diagrams', False):
        print("\nSkipping Phase 5 (diagram generation) — --no-diagrams\n")
    else:
        diagrams_args = Namespace(
            architecture_dir="architecture",
            platform=args.platform,
            version=target_version,
            max_concurrent=max_concurrent,
            limit=None,
            component=None,
            force_regenerate=force,
            export_png=getattr(args, 'export_png', False),
            model=getattr(args, 'model', 'opus'),
            strace=strace,
        )
        await run_generate_diagrams_phase(diagrams_args)

    print("\n" + "=" * 80)
    print("ALL PHASES COMPLETED SUCCESSFULLY!")
    print("=" * 80)
    print("\nResults:")
    print(f"  - Component architectures: architecture/{args.platform}/*.md")
    print(f"  - Analyzer artifacts: architecture/{args.platform}/*/.analyzer/")
    print(f"  - Platform documents: architecture/{args.platform}/PLATFORM.md")
    print(f"  - Diagrams: architecture/{args.platform}/diagrams/")
    print("=" * 80 + "\n")


def _dedupe_preserving_order(values: list[str]) -> list[str]:
    seen = set()
    result = []
    for value in values:
        if value in seen:
            continue
        seen.add(value)
        result.append(value)
    return result


def _component_repo_selectors(component) -> set[str]:
    selectors = {component.key, component.repo_name}
    if component.repo_org and component.repo_name:
        selectors.add(f"{component.repo_org}/{component.repo_name}")
    if component.repo_url:
        repo_url = component.repo_url.rstrip("/")
        selectors.add(repo_url)
        parts = repo_url.split("/")
        if len(parts) >= 2:
            selectors.add("/".join(parts[-2:]))
            selectors.add(parts[-1])
    return {selector for selector in selectors if selector}


def _resolve_pipeline_components(args) -> list[str]:
    requested = list(getattr(args, "component", None) or [])
    repos = list(getattr(args, "repo", None) or [])
    if not repos:
        return _dedupe_preserving_order(requested)

    components = read_component_map(
        args.platform,
        architecture_dir=getattr(args, "architecture_dir", "architecture"),
    )
    if components is None:
        raise ValueError(
            f"cannot resolve --repo selectors without "
            f"{getattr(args, 'architecture_dir', 'architecture')}/"
            f"{args.platform}/component-map.json"
        )

    selector_map = {}
    for key, component in components.items():
        for selector in _component_repo_selectors(component):
            selector_map[selector] = key

    resolved = []
    missing = []
    for repo in repos:
        key = selector_map.get(repo)
        if key:
            resolved.append(key)
        else:
            missing.append(repo)
    if missing:
        available = ", ".join(sorted(selector_map)[:25])
        raise ValueError(
            "Unknown --repo selector(s): "
            + ", ".join(missing)
            + f". Available examples: {available}"
        )
    return _dedupe_preserving_order(requested + resolved)


def _pipeline_log_dir(args) -> str:
    base = getattr(args, "log_dir", None)
    if base:
        return base
    timestamp = datetime.now(UTC).strftime("%Y%m%dT%H%M%SZ")
    return f"logs/pipeline/{timestamp}/generate-architecture"


def _pipeline_phase_args(args, phase: str, component: str | None):
    common = {
        "platform": args.platform,
        "architecture_dir": getattr(args, "architecture_dir", "architecture"),
        "max_concurrent": getattr(args, "max_concurrent", 1),
        "force": getattr(args, "force", False),
        "model": getattr(args, "model", "opus"),
        "strace": getattr(args, "strace", False),
    }
    if phase == "fetch":
        return Namespace(
            org=getattr(args, "org", None),
            platform=args.platform,
            checkouts_dir=getattr(args, "checkouts_dir", "checkouts"),
            branch=getattr(args, "branch", None),
            suffix=getattr(args, "suffix", None),
            exclude=None,
            pull=getattr(args, "pull", False),
        )
    if phase == "parse-manifests":
        return Namespace(
            platform=args.platform,
            org=getattr(args, "org", None),
            branch=getattr(args, "branch", None),
            suffix=getattr(args, "suffix", None),
            checkouts_dir=getattr(args, "checkouts_dir", "checkouts"),
            script_path=None,
            version=getattr(args, "version", None),
            format="summary",
        )
    if phase == "discover-components":
        return Namespace(
            **common,
            checkouts_dir=getattr(args, "checkouts_dir", None),
            entry_repo=None,
            exclude=None,
        )
    if phase == "static-analysis":
        return Namespace(
            **common,
            component=component,
            skip_schemas=getattr(args, "skip_schemas", False),
        )
    if phase == "generate-architecture":
        return Namespace(
            **common,
            component=component,
            limit=None if component else getattr(args, "limit", None),
            log_dir=_pipeline_log_dir(args),
            version=getattr(args, "version", None) or args.platform,
            evidence_gated_merge=getattr(args, "evidence_gated_merge", True),
            tier=getattr(args, "tier", "all"),
        )
    if phase == "generate-platform-architecture":
        return Namespace(
            **common,
            version=getattr(args, "version", None),
            limit=getattr(args, "limit", None),
        )
    if phase == "generate-diagrams":
        return Namespace(
            **common,
            version=getattr(args, "version", None),
            limit=None if component else getattr(args, "limit", None),
            component=component,
            force_regenerate=getattr(args, "force", False),
            export_png=getattr(args, "export_png", False),
        )
    raise ValueError(f"unsupported pipeline phase: {phase}")


async def run_pipeline_phases(args) -> None:
    """Run selected phases, optionally scoped to multiple components/repos."""

    components = _resolve_pipeline_components(args)
    phases = getattr(args, "phase", None) or []
    if not phases:
        raise ValueError("pipeline requires at least one --phase")

    print("\n" + "=" * 80)
    print("RUNNING TARGETED PIPELINE")
    print(f"Platform: {args.platform}")
    print(f"Phases: {', '.join(phases)}")
    if components:
        print(f"Components: {', '.join(components)}")
    else:
        print("Components: all phase-selected items")
    print("=" * 80 + "\n")

    for phase in phases:
        if components and phase in COMPONENT_SCOPED_PHASES:
            for component in components:
                print("\n" + "-" * 80)
                print(f"PIPELINE PHASE: {phase} [{component}]")
                print("-" * 80)
                phase_args = _pipeline_phase_args(args, phase, component)
                await _run_pipeline_phase(phase, phase_args)
        else:
            print("\n" + "-" * 80)
            print(f"PIPELINE PHASE: {phase}")
            print("-" * 80)
            phase_args = _pipeline_phase_args(args, phase, None)
            await _run_pipeline_phase(phase, phase_args)

    print("\n" + "=" * 80)
    print("TARGETED PIPELINE COMPLETED")
    print("=" * 80 + "\n")


async def _run_pipeline_phase(phase: str, phase_args) -> None:
    if phase == "fetch":
        await run_fetch_phase(phase_args)
    elif phase == "parse-manifests":
        await run_manifest_phase(phase_args)
    elif phase == "discover-components":
        await run_discover_components_phase(phase_args)
    elif phase == "static-analysis":
        await run_static_analysis_phase(phase_args)
    elif phase == "generate-architecture":
        await run_generate_architecture_phase(phase_args)
    elif phase == "generate-platform-architecture":
        await run_generate_platform_architecture_phase(phase_args)
    elif phase == "generate-diagrams":
        await run_generate_diagrams_phase(phase_args)
    else:
        raise ValueError(f"unsupported pipeline phase: {phase}")


async def main(args) -> None:
    """Main entry point - dispatch to appropriate phase."""
    if args.command == "fetch":
        await run_fetch_phase(args)
    elif args.command == "parse-manifests":
        await run_manifest_phase(args)
    elif args.command == "discover-components":
        await run_discover_components_phase(args)
    elif args.command == "static-analysis":
        await run_static_analysis_phase(args)
    elif args.command == "generate-architecture":
        await run_generate_architecture_phase(args)
    elif args.command == "generate-platform-architecture":
        await run_generate_platform_architecture_phase(args)
    elif args.command == "generate-diagrams":
        await run_generate_diagrams_phase(args)
    elif args.command == "check-eligibility":
        from lib.phases.eligibility import run_check_eligibility
        await run_check_eligibility(args)
    elif args.command == "all":
        await run_all_phases(args)
    elif args.command == "pipeline":
        await run_pipeline_phases(args)
    else:
        print("Error: No command specified. Use --help for usage information.")
        sys.exit(1)
