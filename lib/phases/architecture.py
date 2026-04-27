"""Phase 3: Generate component architecture documentation."""

import sys
from pathlib import Path

from lib.component_discovery import read_component_map, get_component_map_metadata
from lib.build_info import get_build_info, format_build_info_context
from lib.kustomize_context import get_component_kustomize_context, format_kustomize_context
from lib.agent_runner import run_agents_concurrently, get_model_display_name, format_duration

sys.path.insert(0, str(Path(__file__).resolve().parent.parent.parent / "scripts"))
from get_git_changes import get_metadata as get_git_metadata


def _format_git_context(checkout_path: Path) -> str:
    """Gather git metadata from a checkout and format as prompt context.

    This runs the same logic as ``scripts/get_git_changes.py --format=metadata``
    but directly in the orchestrator so the agent doesn't need to run it.

    Returns an empty string if the path is not a git repository.
    """
    git_dir = checkout_path / ".git"
    if not git_dir.exists():
        return ""

    meta = get_git_metadata(checkout_path, since="3 months ago", limit=20)

    lines = [
        "## Pre-gathered Git Metadata",
        "",
        f"Version: {meta['version']}",
        f"Branch: {meta['branch']}",
        f"Remote: {meta['remote_url']}",
        "",
    ]

    commits = meta.get("recent_commits", [])
    if commits:
        lines.append(f"Recent commits ({len(commits)}):")
        for c in commits:
            lines.append(f"  {c}")
    else:
        lines.append("Recent commits: (none in last 3 months)")

    return "\n".join(lines)


async def run_generate_architecture_phase(args) -> None:
    """Run Phase 3: Generate architecture documentation."""
    print("\n" + "=" * 60)
    print("PHASE 3: Generating component architectures")
    print("=" * 60 + "\n")

    architecture_dir = getattr(args, 'architecture_dir', 'architecture')

    # Load components from component-map.json
    components = read_component_map(args.platform, architecture_dir=architecture_dir)
    if components is None:
        print(f"ERROR: No component-map.json found for platform '{args.platform}'")
        print(f"Expected: {architecture_dir}/{args.platform}/component-map.json")
        print(f"\nRun discover-components first:")
        print(f"  uv run main.py discover-components --platform={args.platform}")
        return

    # Load metadata for checkouts_dir and version info
    metadata = get_component_map_metadata(args.platform, architecture_dir=architecture_dir) or {}

    # Derive distribution from platform (strip version suffix)
    distribution = args.platform.split("-")[0] if "-" in args.platform else args.platform

    # Find the operator component for kustomize context
    operator_path = None
    for key in ("rhods-operator", "opendatahub-operator"):
        if key in components and components[key].checkout_path:
            operator_path = components[key].checkout_path
            break

    # Derive checkouts_dir from metadata (first entry if comma-separated)
    checkouts_dir_str = metadata.get("checkouts_dir", "")
    checkouts_dir = Path(checkouts_dir_str.split(",")[0]) if checkouts_dir_str else None

    # Extract build metadata from RHOAI-Build-Config (RHOAI only)
    build_info = get_build_info(checkouts_dir) if checkouts_dir and checkouts_dir.exists() else None
    if build_info:
        info = format_build_info_context(build_info)
        if info:
            print(info)

    if not components:
        print("No components found with checkouts")
        return

    # Apply component filter if specified
    if args.component:
        if args.component in components:
            components = {args.component: components[args.component]}
            print(f"Filtered to single component: {args.component}\n")
        else:
            print(f"ERROR: Component '{args.component}' not found")
            print(f"Available components: {', '.join(sorted(components.keys()))}")
            return

    # Filter to components with actual checkouts on disk
    components = {
        k: v for k, v in components.items()
        if v.checkout_path and v.checkout_path.exists()
    }

    # Refresh has_architecture from filesystem (component-map may be stale)
    for component in components.values():
        arch_file = component.checkout_path / "GENERATED_ARCHITECTURE.md"
        component.has_architecture = arch_file.exists()

    # Handle --force: delete existing GENERATED_ARCHITECTURE.md files
    if args.force:
        print("Force mode: Deleting existing GENERATED_ARCHITECTURE.md files...\n")
        for component in components.values():
            arch_file = component.checkout_path / "GENERATED_ARCHITECTURE.md"
            if arch_file.exists():
                arch_file.unlink()
                print(f"  Deleted: {component.key}/GENERATED_ARCHITECTURE.md")
                component.has_architecture = False  # Update status
        print()

    # Filter to components missing architecture (unless --force, which already deleted them)
    missing_arch = [c for c in components.values() if not c.has_architecture]
    has_arch = [c for c in components.values() if c.has_architecture]

    print(f"Found {len(components)} components:")
    print(f"  Already documented: {len(has_arch)}")
    print(f"  Need architecture: {len(missing_arch)}")
    print()

    if not missing_arch:
        print("All components already have architecture documentation!")
        return

    # Prepare agent jobs
    jobs = []
    for component in sorted(missing_arch, key=lambda c: c.key):
        model_display = get_model_display_name(args.model)

        # Build context preamble with pre-gathered metadata
        context_parts = []

        if build_info:
            ctx = format_build_info_context(build_info)
            if ctx:
                context_parts.append(ctx)

        kustomize_ctx = get_component_kustomize_context(
            component.key, operator_path
        )
        if kustomize_ctx:
            ctx = format_kustomize_context(kustomize_ctx, component.source_folder)
            if ctx:
                context_parts.append(ctx)

        git_context = _format_git_context(component.checkout_path)
        if git_context:
            context_parts.append(git_context)

        context_block = "\n\n".join(context_parts)
        if context_block:
            context_block = f"\n\n{context_block}\n"

        prompt = f"""The following context has been pre-gathered for this component:

Distribution: {distribution}
Repository: {component.repo_org}/{component.repo_name}
Manifests folder: {component.source_folder}
Generated By (use this exact string in Metadata): {model_display}
{context_block}
/repo-to-architecture-summary . --distribution={distribution}"""

        job = {
            "name": f"{component.key}",
            "cwd": str(component.checkout_path),
            "prompt": prompt,
            "repo": f"{component.repo_org}/{component.repo_name}",
        }
        jobs.append(job)

    # Apply limit if specified
    if args.limit:
        jobs = jobs[:args.limit]
        print(f"Limited to first {args.limit} component(s)\n")

    # Display prepared jobs
    print(f"Prepared {len(jobs)} agent job(s):\n")
    for i, job in enumerate(jobs, 1):
        print(f"{i:2d}. {job['name']:30s} {job['repo']}")
        print(f"    cwd: {job['cwd']}")
        print()

    # Create logs directory
    log_dir = Path("logs/generate-architecture")
    log_dir.mkdir(parents=True, exist_ok=True)
    print(f"Logs will be written to: {log_dir}\n")

    print(f"{'=' * 60}")
    print(f"Ready to process {len(jobs)} component(s)")
    print(f"Max concurrent agents: {args.max_concurrent}")
    print(f"Model: {args.model}")
    print(f"{'=' * 60}\n")

    results = await run_agents_concurrently(
        jobs, log_dir, args.model, args.max_concurrent, enable_skills=True,
    )

    # Summary
    successful = [r for r in results if isinstance(r, dict) and r.get("success")]
    failed = [r for r in results if isinstance(r, dict) and not r.get("success")]
    exceptions = [r for r in results if isinstance(r, Exception)]

    print("\n" + "=" * 60)
    print("ARCHITECTURE GENERATION COMPLETE")
    print("=" * 60)
    print(f"Total components: {len(jobs)}")
    print(f"Successful: {len(successful)}")
    print(f"Failed: {len(failed)}")
    if exceptions:
        print(f"Exceptions: {len(exceptions)}")

    if failed:
        print("\nFailed components:")
        for r in failed:
            print(f"  x {r['name']}: {r.get('error', 'unknown error')}")
            if r.get('log_file'):
                print(f"    Log: {r['log_file']}")

    if exceptions:
        print("\nComponents with exceptions:")
        for i, exc in enumerate(exceptions):
            print(f"  x Exception {i+1}: {exc}")

    # Inject generation duration into each successful component's architecture file
    for job, result in zip(jobs, results):
        if not isinstance(result, dict) or not result.get("success"):
            continue
        arch_file = Path(job["cwd"]) / "GENERATED_ARCHITECTURE.md"
        if not arch_file.exists():
            continue
        elapsed = result.get("duration_seconds", 0)
        duration_line = f"\n---\n*Generated in {format_duration(elapsed)} ({elapsed:.0f}s total)*\n"
        with open(arch_file, 'a') as f:
            f.write(duration_line)

    print(f"\nAll agent logs available in: {log_dir}")
    print("=" * 60)
