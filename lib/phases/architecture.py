"""Phase 3: Generate component architecture documentation."""

from pathlib import Path

from lib.agent_runner import (
    format_duration,
    get_model_display_name,
    run_agents_concurrently,
)
from lib.component_discovery import apply_platform_overrides, read_component_map
from lib.fetch import load_platform_config


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
        print("\nRun discover-components first:")
        print(f"  uv run main.py discover-components --platform={args.platform}")
        return

    # Apply platform overrides (exclude_components, include_components, etc.)
    platform_config = load_platform_config(args.platform)
    if platform_config:
        checkouts_dir = getattr(args, 'checkouts_dir', 'checkouts')
        components = apply_platform_overrides(
            components, platform_config, checkouts_base=checkouts_dir,
        )

    # Derive distribution from platform (strip version suffix)
    distribution = (
        args.platform.split("-")[0]
        if "-" in args.platform
        else args.platform
    )

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

    # Apply tier filter
    tier_filter = getattr(args, 'tier', 'all')
    if tier_filter == 'significant':
        before = len(components)
        components = {
            k: v for k, v in components.items()
            if v.architecturally_significant
        }
        print(
            f"Tier filter 'significant': "
            f"{before} -> {len(components)} components"
        )
    elif tier_filter == 'core':
        before = len(components)
        components = {
            k: v for k, v in components.items()
            if v.tier in ('core_platform', 'optional_platform')
        }
        print(
            f"Tier filter 'core': "
            f"{before} -> {len(components)} components"
        )

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

    # Filter to components missing architecture
    # (unless --force, which already deleted them)
    missing_arch = [c for c in components.values() if not c.has_architecture]
    has_arch = [c for c in components.values() if c.has_architecture]

    print(f"Found {len(components)} components:")
    print(f"  Already documented: {len(has_arch)}")
    print(f"  Need architecture: {len(missing_arch)}")
    print()

    if not missing_arch:
        print("All components already have architecture documentation!")
        return

    # Prepare agent jobs — pure skill invocation, no context preamble
    model_display = get_model_display_name(args.model)
    jobs = []
    for component in sorted(missing_arch, key=lambda c: c.key):
        checkout_path = str(component.checkout_path.resolve())
        prompt = (
            f"/repo-to-architecture-summary {checkout_path}"
            f" --distribution={distribution}"
            f" --output=GENERATED_ARCHITECTURE.md"
            f" --generated-by={model_display}"
        )

        job = {
            "name": f"{component.key}",
            "cwd": ".",
            "prompt": prompt,
            "repo": f"{component.repo_org}/{component.repo_name}",
            "checkout_path": component.checkout_path,
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

    # Recover crashed agents that still produced output.
    # The CLI subprocess can crash on benign text patterns (e.g., [/path])
    # after the agent has already written the architecture file.
    # Handles both failed dicts (from run_agent's except block) and raw
    # Exception objects (from asyncio.gather return_exceptions=True).
    recovered = []
    for i, (job, result) in enumerate(zip(jobs, results)):
        if isinstance(result, dict) and result.get("success"):
            continue
        arch_file = job["checkout_path"] / "GENERATED_ARCHITECTURE.md"
        if arch_file.exists() and arch_file.stat().st_size > 1000:
            if isinstance(result, Exception):
                results[i] = {
                    "name": job["name"],
                    "success": True,
                    "recovered": True,
                    "error": str(result),
                    "log_file": str(log_dir / f"{job['name'].replace('/', '_')}.log"),
                    "duration_seconds": 0,
                }
            else:
                result["success"] = True
                result["recovered"] = True
            recovered.append(results[i])

    if recovered:
        print(
            f"\nRecovered {len(recovered)} agent(s)"
            " that crashed after writing output:"
        )
        for r in recovered:
            err = r.get('error', '')[:80]
            print(
                f"  ~ {r['name']}: crashed ({err})"
                " but output file exists"
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
        arch_file = job["checkout_path"] / "GENERATED_ARCHITECTURE.md"
        if not arch_file.exists():
            continue
        elapsed = result.get("duration_seconds", 0)
        duration_line = (
            f"\n---\n*Generated in {format_duration(elapsed)}"
            f" ({elapsed:.0f}s total)*\n"
        )
        with open(arch_file, 'a') as f:
            f.write(duration_line)

    print(f"\nAll agent logs available in: {log_dir}")
    print("=" * 60)
