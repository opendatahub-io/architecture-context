"""Phase 5: Generate platform-level architecture documents."""

import re
from pathlib import Path

from lib.component_discovery import get_component_map_metadata
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

    # Determine which directories to scan
    if args.platform:
        candidate = architecture_dir / args.platform
        if not candidate.is_dir():
            print(f"No directory found: {candidate}")
            available = [p.name for p in sorted(architecture_dir.iterdir()) if p.is_dir()]
            print(f"Available: {', '.join(available)}")
            return
        scan_dirs = [candidate]
    else:
        scan_dirs = sorted(d for d in architecture_dir.iterdir() if d.is_dir())

    if args.version:
        scan_dirs = [d for d in scan_dirs if args.version in d.name]
        if not scan_dirs:
            print(f"No directories found matching version: {args.version}")
            return

    # Check each directory for component files and staleness
    platform_dirs = []
    for item in scan_dirs:
        component_files = [
            f for f in item.glob("*.md")
            if f.name not in ("README.md", "PLATFORM.md")
        ]
        if not component_files:
            continue

        platform_md = item / "PLATFORM.md"
        has_platform_md = platform_md.exists()

        needs_generation = not has_platform_md
        if has_platform_md:
            platform_mtime = platform_md.stat().st_mtime
            for comp_file in component_files:
                if comp_file.stat().st_mtime > platform_mtime:
                    needs_generation = True
                    print(f"  Deleting stale PLATFORM.md for {item.name} (component files updated)")
                    platform_md.unlink()
                    has_platform_md = False
                    break

        platform_dirs.append({
            'name': item.name,
            'path': item,
            'has_platform_md': has_platform_md,
            'component_count': len(component_files),
            'needs_generation': needs_generation,
        })

    if not platform_dirs:
        print(f"No platform directories with component files found")
        return

    needs_generation = [p for p in platform_dirs if p['needs_generation']]
    already_has = [p for p in platform_dirs if p['has_platform_md']]

    print(f"Found {len(platform_dirs)} platform director(ies):")
    print(f"  Already has PLATFORM.md: {len(already_has)}")
    print(f"  Needs PLATFORM.md: {len(needs_generation)}")
    print()

    if already_has:
        print("Platforms with PLATFORM.md:")
        for p in already_has:
            print(f"  + {p['name']} ({p['component_count']} components)")
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

    instructions_match = re.search(r'## Instructions\n\n(.+)', skill_content, re.DOTALL)
    if not instructions_match:
        print("ERROR: Could not extract instructions from skill file")
        return

    instructions = instructions_match.group(1).strip()

    # Prepare agent jobs
    jobs = []
    for p in sorted(needs_generation, key=lambda x: x['name']):
        # Try to get build context from component-map metadata
        build_context = ""
        metadata = get_component_map_metadata(p['name'], architecture_dir=str(architecture_dir))
        if metadata:
            checkouts_dir_str = metadata.get("checkouts_dir", "")
            if checkouts_dir_str:
                first_dir = Path(checkouts_dir_str.split(",")[0])
                if first_dir.exists():
                    platform_build_info = get_build_info(first_dir)
                    if platform_build_info:
                        build_context = format_build_info_context(platform_build_info) + "\n"

        model_display = get_model_display_name(args.model)

        # Derive distribution from directory name
        distribution = p['name'].split("-")[0] if "-" in p['name'] else p['name']
        version = metadata.get("version", "unknown") if metadata else "unknown"

        prompt = f"""Aggregate component architecture summaries into a platform-level architecture document.

Distribution: {distribution}
Version: {version}
Architecture directory: . (current working directory)
{build_context}
This directory contains {p['component_count']} component architecture file(s).
Read all *.md files in the current directory (excluding README.md) to aggregate into PLATFORM.md.

IMPORTANT: The supported OCP versions dictate which OpenShift/Kubernetes APIs and platform
features are available to or required by this release. The total shipped container image count
reflects the full scope of the product deployment via OLM relatedImages.
Factor this into the architecture analysis.

IMPORTANT: For the "Generated By" metadata field, use exactly: {model_display}

{instructions}
"""

        job = {
            "name": p['name'],
            "cwd": str(p['path']),
            "prompt": prompt,
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
