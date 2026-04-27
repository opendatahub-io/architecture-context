"""Phase 5: Generate platform-level architecture documents."""

import re
from pathlib import Path

from lib.build_info import get_build_info, format_build_info_context
from lib.agent_runner import run_agents_concurrently, get_model_display_name


async def run_generate_platform_architecture_phase(args) -> None:
    """Run Phase 5: Generate platform-level architecture documents."""
    print("\n" + "=" * 60)
    print("PHASE 5: Generating platform architectures")
    print("=" * 60 + "\n")

    architecture_dir = Path(args.architecture_dir)

    if not architecture_dir.exists():
        print(f"Error: Architecture directory does not exist: {architecture_dir}")
        print(f"Run 'collect-architectures' first to organize component files")
        return

    # Discover platform directories
    platform_dirs = []
    for item in architecture_dir.iterdir():
        if not item.is_dir():
            continue

        # Parse directory name: <platform> or <platform>-<version>
        match = re.match(r'^(.+?)-(\d.*)$', item.name)
        if match:
            platform = match.group(1)
            version = match.group(2)
        else:
            platform = item.name
            version = None

        platform_md = item / "PLATFORM.md"
        has_platform_md = platform_md.exists()

        component_files = [
            f for f in item.glob("*.md")
            if f.name not in ["README.md", "PLATFORM.md"]
        ]

        needs_generation = False
        if not has_platform_md and len(component_files) > 0:
            needs_generation = True
        elif has_platform_md and len(component_files) > 0:
            platform_mtime = platform_md.stat().st_mtime
            for comp_file in component_files:
                if comp_file.stat().st_mtime > platform_mtime:
                    needs_generation = True
                    label = f"{platform}-{version}" if version else platform
                    print(f"  Deleting stale PLATFORM.md for {label} (component files updated)")
                    platform_md.unlink()
                    has_platform_md = False
                    break

        platform_dirs.append({
            'platform': platform,
            'version': version,
            'path': item,
            'has_platform_md': has_platform_md,
            'component_count': len(component_files),
            'needs_generation': needs_generation
        })

    if not platform_dirs:
        print(f"No platform directories found in {architecture_dir}")
        return

    # Apply platform/version filters if specified
    if args.platform:
        platform_dirs = [p for p in platform_dirs if p['platform'] == args.platform]
        if not platform_dirs:
            print(f"No directories found for platform: {args.platform}")
            return

    if args.version:
        platform_dirs = [p for p in platform_dirs if p['version'] == args.version]
        if not platform_dirs:
            print(f"No directories found for version: {args.version}")
            if args.platform:
                print(f"Looking for: {args.platform}-{args.version}")
            return

    # Filter to platforms that need PLATFORM.md generation
    needs_generation = [p for p in platform_dirs if p['needs_generation']]
    already_has = [p for p in platform_dirs if p['has_platform_md']]
    no_components = [p for p in platform_dirs if p['component_count'] == 0]

    def _label(p):
        return f"{p['platform']}-{p['version']}" if p['version'] else p['platform']

    print(f"Found {len(platform_dirs)} platform director(ies):")
    print(f"  Already has PLATFORM.md: {len(already_has)}")
    print(f"  Needs PLATFORM.md: {len(needs_generation)}")
    print(f"  No components: {len(no_components)}")
    print()

    if already_has:
        print("Platforms with PLATFORM.md:")
        for p in already_has:
            print(f"  + {_label(p)} ({p['component_count']} components)")
        print()

    if no_components:
        print("Platforms with no components:")
        for p in no_components:
            print(f"  ! {_label(p)}")
        print()

    if not needs_generation:
        print("All platforms already have PLATFORM.md!")
        return

    # Read the skill prompt template
    skill_path = Path(".claude/skills/aggregate-platform-architecture/SKILL.md")
    if not skill_path.exists():
        print(f"ERROR: Skill file not found: {skill_path}")
        return

    skill_content = skill_path.read_text()

    # Extract the instructions section
    instructions_match = re.search(r'## Instructions\n\n(.+)', skill_content, re.DOTALL)
    if not instructions_match:
        print("ERROR: Could not extract instructions from skill file")
        return

    instructions = instructions_match.group(1).strip()

    # Prepare agent jobs
    checkouts_base = Path(getattr(args, 'checkouts_dir', 'checkouts'))
    jobs = []
    for p in sorted(needs_generation, key=lambda x: (x['platform'], x['version'] or '')):
        # Look up supported OCP versions from build-config in checkouts
        build_context = ""
        if p['platform'] == 'rhoai' and p['version']:
            org = "red-hat-data-services"
            org_dir = checkouts_base / f"{org}.rhoai-{p['version']}"
            platform_build_info = get_build_info(org_dir)
            if platform_build_info:
                build_context = format_build_info_context(platform_build_info) + "\n"

        # Build prompt from skill instructions
        model_display = get_model_display_name(args.model)
        version_line = f"Version: {p['version']}" if p['version'] else "Version: head (latest)"
        prompt = f"""Aggregate component architecture summaries into a platform-level architecture document.

Distribution: {p['platform']}
{version_line}
Architecture directory: {p['path']}
{build_context}
This directory contains {p['component_count']} component architecture file(s).
Generate a comprehensive PLATFORM.md file by aggregating all component summaries.

IMPORTANT: The supported OCP versions dictate which OpenShift/Kubernetes APIs and platform
features are available to or required by this release. The total shipped container image count
reflects the full scope of the product deployment via OLM relatedImages.
Factor this into the architecture analysis.

IMPORTANT: For the "Generated By" metadata field, use exactly: {model_display}

{instructions}
"""

        job = {
            "name": _label(p),
            "cwd": str(p['path']),
            "prompt": prompt,
            "platform": p['platform'],
            "version": p['version'],
        }
        jobs.append(job)

    # Apply limit if specified
    if args.limit:
        jobs = jobs[:args.limit]
        print(f"Limited to first {args.limit} platform(s)\n")

    # Display prepared jobs
    print(f"Prepared {len(jobs)} agent job(s):\n")
    for i, job in enumerate(jobs, 1):
        print(f"{i:2d}. {job['name']:30s} ({job['cwd']})")
    print()

    # Create logs directory
    log_dir = Path("logs/generate-platform-architecture")
    log_dir.mkdir(parents=True, exist_ok=True)
    print(f"Logs will be written to: {log_dir}\n")

    print(f"{'=' * 60}")
    print(f"Ready to process {len(jobs)} platform(s)")
    print(f"Max concurrent agents: {args.max_concurrent}")
    print(f"Model: {args.model}")
    print(f"{'=' * 60}\n")

    results = await run_agents_concurrently(jobs, log_dir, args.model, args.max_concurrent)

    # Summary
    successful = [r for r in results if isinstance(r, dict) and r.get("success")]
    failed = [r for r in results if isinstance(r, dict) and not r.get("success")]
    exceptions = [r for r in results if isinstance(r, Exception)]

    print("\n" + "=" * 60)
    print("PLATFORM ARCHITECTURE GENERATION COMPLETE")
    print("=" * 60)
    print(f"Total platforms: {len(jobs)}")
    print(f"Successful: {len(successful)}")
    print(f"Failed: {len(failed)}")
    if exceptions:
        print(f"Exceptions: {len(exceptions)}")

    if failed:
        print("\nFailed platforms:")
        for r in failed:
            print(f"  x {r['name']}: {r.get('error', 'unknown error')}")
            if r.get('log_file'):
                print(f"    Log: {r['log_file']}")

    if exceptions:
        print("\nPlatforms with exceptions:")
        for i, exc in enumerate(exceptions):
            print(f"  x Exception {i+1}: {exc}")

    print(f"\nAll agent logs available in: {log_dir}")
    print("=" * 60)
