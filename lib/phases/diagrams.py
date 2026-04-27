"""Phase 6: Generate architecture diagrams."""

import re
import subprocess
from pathlib import Path

from lib.agent_runner import run_agents_concurrently, get_model_display_name


async def run_generate_diagrams_phase(args) -> None:
    """Run Phase 6: Generate diagrams for architecture files."""
    print("\n" + "=" * 60)
    print("PHASE 6: Generating architecture diagrams")
    print("=" * 60 + "\n")

    architecture_dir = Path(args.architecture_dir)

    if not architecture_dir.exists():
        print(f"Error: Architecture directory does not exist: {architecture_dir}")
        return

    # Discover all .md files in all platform-version directories
    diagram_jobs = []

    for platform_dir in sorted(architecture_dir.iterdir()):
        if not platform_dir.is_dir():
            continue

        # Parse directory name: <platform> or <platform>-<version>
        match = re.match(r'^(.+?)-(\d.*)$', platform_dir.name)
        if match:
            platform = match.group(1)
            version = match.group(2)
        else:
            platform = platform_dir.name
            version = None

        # Find all .md files (excluding README.md)
        md_files = [
            f for f in platform_dir.glob("*.md")
            if f.name != "README.md"
        ]

        for md_file in md_files:
            component_name = md_file.stem.lower()
            diagrams_dir = platform_dir / "diagrams"

            # Check if diagrams already exist
            # Look for any diagram files (.mmd, .dsl, .txt) with this component's name
            has_diagrams = False
            all_diagram_files = []
            if diagrams_dir.exists():
                # Check for any of the expected diagram file types
                mmd_files = list(diagrams_dir.glob(f"{component_name}-*.mmd"))
                dsl_files = list(diagrams_dir.glob(f"{component_name}-*.dsl"))
                txt_files = list(diagrams_dir.glob(f"{component_name}-*.txt"))
                png_files = list(diagrams_dir.glob(f"{component_name}-*.png"))
                all_diagram_files = mmd_files + dsl_files + txt_files + png_files
                has_diagrams = len(mmd_files) > 0 or len(dsl_files) > 0 or len(txt_files) > 0

            needs_generation = False
            if not has_diagrams:
                needs_generation = True
            elif args.force_regenerate:
                # Force regeneration - delete existing diagrams
                print(f"  Deleting existing diagrams for {component_name} (--force-regenerate)")
                for diagram_file in all_diagram_files:
                    diagram_file.unlink()
                needs_generation = True
                has_diagrams = False
            elif has_diagrams:
                # Check if source .md file is newer than diagrams
                md_mtime = md_file.stat().st_mtime
                # Check oldest diagram file
                oldest_diagram_mtime = min(f.stat().st_mtime for f in all_diagram_files)
                if md_mtime > oldest_diagram_mtime:
                    # Source is newer - delete stale diagrams
                    print(f"  Deleting stale diagrams for {component_name} (source file updated)")
                    for diagram_file in all_diagram_files:
                        diagram_file.unlink()
                    needs_generation = True
                    has_diagrams = False

            diagram_jobs.append({
                'platform': platform,
                'version': version,
                'md_file': md_file,
                'component_name': component_name,
                'diagrams_dir': diagrams_dir,
                'has_diagrams': has_diagrams,
                'needs_generation': needs_generation,
            })

    if not diagram_jobs:
        print(f"No architecture files found in {architecture_dir}")
        return

    # Apply platform/version filters if specified
    if args.platform:
        diagram_jobs = [j for j in diagram_jobs if j['platform'] == args.platform]
        if not diagram_jobs:
            print(f"No files found for platform: {args.platform}")
            return

    if args.version:
        diagram_jobs = [j for j in diagram_jobs if j['version'] == args.version]
        if not diagram_jobs:
            print(f"No files found for version: {args.version}")
            if args.platform:
                print(f"Looking for: {args.platform}-{args.version}")
            return

    # Filter to files that need diagrams
    needs_generation = [j for j in diagram_jobs if j['needs_generation']]
    already_has = [j for j in diagram_jobs if j['has_diagrams'] and not args.force_regenerate]

    print(f"Found {len(diagram_jobs)} architecture file(s):")
    print(f"  Already has diagrams: {len(already_has)}")
    print(f"  Needs diagrams: {len(needs_generation)}")
    print()

    if already_has:
        print("Files with diagrams (skipping):")
        for j in already_has:
            label = f"{j['platform']}-{j['version']}" if j['version'] else j['platform']
            print(f"  + {label}/{j['component_name']}.md")
        print()

    if not needs_generation:
        print("All files already have diagrams!")
        if not args.force_regenerate:
            print("Use --force-regenerate to regenerate existing diagrams")
        return

    # Read the skill prompt template for generate-architecture-diagrams
    skill_path = Path(".claude/skills/generate-architecture-diagrams/SKILL.md")
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
    jobs = []
    for j in sorted(needs_generation, key=lambda x: (x['platform'], x['version'] or '', x['component_name'])):
        # Build prompt from skill instructions
        model_display = get_model_display_name(args.model)
        prompt = f"""Generate architecture diagrams from the architecture markdown file.

Architecture file: {j['md_file']}
Component name: {j['component_name']}
Output directory: {j['diagrams_dir']}

Generate all diagram formats:
- Mermaid diagrams (.mmd)
- C4 diagrams (.dsl)
- Security network diagrams (.txt and .mmd)
- PNG files from Mermaid diagrams

IMPORTANT: For any "Generated by" fields in output files, use exactly: {model_display}

{instructions}
"""

        job = {
            "name": f"{j['platform']}-{j['version']}/{j['component_name']}" if j['version'] else f"{j['platform']}/{j['component_name']}",
            "cwd": str(j['md_file'].parent),
            "prompt": prompt,
            "component_name": j['component_name'],
            "diagrams_dir": j['diagrams_dir'],
        }
        jobs.append(job)

    # Apply limit if specified
    if args.limit:
        jobs = jobs[:args.limit]
        print(f"Limited to first {args.limit} file(s)\n")

    # Display prepared jobs
    print(f"Prepared {len(jobs)} agent job(s):\n")
    for i, job in enumerate(jobs, 1):
        print(f"{i:2d}. {job['name']}")
    print()

    # Create logs directory
    log_dir = Path("logs/generate-diagrams")
    log_dir.mkdir(parents=True, exist_ok=True)
    print(f"Logs will be written to: {log_dir}\n")

    print(f"{'=' * 60}")
    print(f"Ready to process {len(jobs)} file(s)")
    print(f"Max concurrent agents: {args.max_concurrent}")
    print(f"Model: {args.model}")
    print(f"{'=' * 60}\n")

    results = await run_agents_concurrently(jobs, log_dir, args.model, args.max_concurrent)

    # Summary
    successful = [r for r in results if isinstance(r, dict) and r.get("success")]
    failed = [r for r in results if isinstance(r, dict) and not r.get("success")]
    exceptions = [r for r in results if isinstance(r, Exception)]

    print("\n" + "=" * 60)
    print("DIAGRAM GENERATION COMPLETE")
    print("=" * 60)
    print(f"Total files: {len(jobs)}")
    print(f"Successful: {len(successful)}")
    print(f"Failed: {len(failed)}")
    if exceptions:
        print(f"Exceptions: {len(exceptions)}")

    if failed:
        print("\nFailed files:")
        for r in failed:
            print(f"  x {r['name']}: {r.get('error', 'unknown error')}")
            if r.get('log_file'):
                print(f"    Log: {r['log_file']}")

    if exceptions:
        print("\nFiles with exceptions:")
        for i, exc in enumerate(exceptions):
            print(f"  x Exception {i+1}: {exc}")

    # Generate PNGs once at the end for all successful jobs
    if successful:
        print("\n" + "=" * 60)
        print("GENERATING PNG FILES")
        print("=" * 60 + "\n")

        # Get unique diagrams directories from successful jobs
        unique_dirs = set()
        for job, result in zip(jobs, results):
            if isinstance(result, dict) and result.get("success"):
                if job["diagrams_dir"].exists():
                    unique_dirs.add(job["diagrams_dir"])

        if unique_dirs:
            for diagrams_dir in sorted(unique_dirs):
                print(f"Generating PNGs in: {diagrams_dir}")
                try:
                    subprocess.run(
                        [
                            "python", "scripts/generate_diagram_pngs.py",
                            str(diagrams_dir),
                            "--width=10000"
                        ],
                        check=True
                    )
                    print(f"PNG generation complete for {diagrams_dir}\n")
                except subprocess.CalledProcessError as e:
                    print(f"PNG generation failed for {diagrams_dir}: {e}\n")
        else:
            print("No diagrams directories to process\n")

    print(f"All agent logs available in: {log_dir}")
    print("=" * 60)
