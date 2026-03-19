"""Phase orchestrators for the architecture tool pipeline."""

import re
import sys
import asyncio
import subprocess
from pathlib import Path

from lib.fetch import fetch_repositories
from lib.manifest_parser import (
    ComponentInfo,
    process_manifest_script,
    display_component_summary,
    components_to_json,
    discover_adjacent_components,
)
from lib.build_info import get_build_info, format_build_info_context
from lib.kustomize_context import get_component_kustomize_context, format_kustomize_context
from lib.agent_runner import run_agent, get_model_display_name, format_duration
from lib.cli import resolve_script_path

# Import collection script as module
sys.path.insert(0, str(Path(__file__).resolve().parent.parent / "scripts"))
from collect_architectures import collect_architectures, print_summary


async def run_fetch_phase(args) -> None:
    """Run Phase 1: Fetch repositories."""
    print("\n" + "=" * 60)
    print("PHASE 1: Fetching repositories")
    print("=" * 60 + "\n")

    await fetch_repositories(
        args.org,
        args.checkouts_dir,
        branch=getattr(args, 'branch', None)
    )


async def run_manifest_phase(args) -> None:
    """Run Phase 2: Parse manifests."""
    # Only show header for summary format
    output_format = getattr(args, 'format', 'summary')

    if output_format == 'summary':
        print("\n" + "=" * 60)
        print("PHASE 2: Parsing component manifests")
        print("=" * 60 + "\n")

    # Resolve script path
    script_path = resolve_script_path(
        platform=args.platform,
        org=args.org,
        branch=args.branch,
        checkouts_dir=args.checkouts_dir,
        script_path=args.script_path,
    )

    # Process manifests (silent - returns structured data)
    components = process_manifest_script(
        script_path,
        platform=args.platform,
        checkouts_dir=None  # Auto-detect from script_path
    )

    # Output based on format
    if output_format == 'json':
        # Just print JSON to stdout
        print(components_to_json(components))
    else:
        # Display human-readable output
        script_path_obj = Path(script_path)
        parts = script_path_obj.parts
        if "checkouts" in parts:
            checkouts_idx = parts.index("checkouts")
            checkouts_dir = Path(*parts[:checkouts_idx+2])
        else:
            checkouts_dir = script_path_obj.parent.parent

        display_component_summary(
            components,
            script_path,
            args.platform,
            checkouts_dir
        )

        print(f"\n{'=' * 60}")
        print(f"Processed {len(components)} components successfully")
        print(f"{'=' * 60}")


async def run_generate_architecture_phase(args) -> None:
    """Run Phase 3: Generate architecture documentation."""
    print("\n" + "=" * 60)
    print("PHASE 3: Generating component architectures")
    print("=" * 60 + "\n")

    # Auto-detect org if not provided
    org = args.org
    if not org:
        org = "opendatahub-io" if args.platform == "odh" else "red-hat-data-services"

    # Auto-detect operator name
    operator_name = "opendatahub-operator" if args.platform == "odh" else "rhods-operator"

    # Resolve script path
    script_path = resolve_script_path(
        platform=args.platform,
        org=org,
        branch=args.branch,
        checkouts_dir=args.checkouts_dir,
        script_path=args.script_path,
    )

    # Process manifests to get component info
    components = process_manifest_script(
        script_path,
        platform=args.platform,
        checkouts_dir=None  # Auto-detect from script_path
    )

    # Also check the operator repository itself (it's not in COMPONENT_MANIFESTS)
    # The operator is the central component that manages all other components
    script_path_obj = Path(script_path)
    operator_path = script_path_obj.parent

    # Determine checkouts_dir from script path (needed for operator + adjacent discovery)
    parts = script_path_obj.parts
    if "checkouts" in parts:
        checkouts_idx = parts.index("checkouts")
        checkouts_dir = Path(*parts[:checkouts_idx+2])
    else:
        checkouts_dir = script_path_obj.parent.parent

    if operator_path.exists():
        # Check if operator has architecture file
        operator_arch_file = operator_path / "GENERATED_ARCHITECTURE.md"
        has_operator_arch = operator_arch_file.exists()

        # Create ComponentInfo for the operator
        operator_component = ComponentInfo(
            key="operator",  # Special key for the operator
            repo_org=org,
            repo_name=operator_name,
            ref="N/A",  # Not from manifest
            source_folder="config",  # Standard operator config location
            checkout_path=operator_path,
            has_architecture=has_operator_arch
        )

        # Add operator to components dict
        components["operator"] = operator_component

    # Discover adjacent components from the checkout directory
    # Only for RHOAI (red-hat-data-services) with a branch specified,
    # since opendatahub-io has too many irrelevant repos
    if args.platform == "rhoai" and args.branch:
        adjacent = discover_adjacent_components(checkouts_dir, components, org)
        if adjacent:
            print(f"Discovered {len(adjacent)} adjacent component(s) beyond manifests")
            components.update(adjacent)

    # Extract build metadata from RHOAI-Build-Config (RHOAI only)
    build_info = get_build_info(checkouts_dir)
    if build_info:
        info = format_build_info_context(build_info)
        if info:
            print(info)

    if not components:
        print("No components found with checkouts")
        return

    # Apply component filter if specified
    if args.component:
        # Create alias mapping for operator
        component_aliases = {
            'rhods-operator': 'operator',
            'opendatahub-operator': 'operator',
        }

        # Resolve alias to actual key
        target_key = component_aliases.get(args.component, args.component)

        if target_key in components:
            components = {target_key: components[target_key]}
            if target_key != args.component:
                print(f"Using alias: {args.component} -> {target_key}")
            print(f"Filtered to single component: {target_key}\n")
        else:
            print(f"ERROR: Component '{args.component}' not found")
            print(f"Available components: {', '.join(sorted(components.keys()))}")
            print(f"Available aliases: {', '.join(sorted(component_aliases.keys()))}")
            return

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

    # Read the skill prompt template
    skill_path = Path(".claude/skills/repo-to-architecture-summary/SKILL.md")
    if not skill_path.exists():
        print(f"ERROR: Skill file not found: {skill_path}")
        return

    skill_content = skill_path.read_text()

    # Extract the instructions section (everything after "## Instructions")
    instructions_match = re.search(r'## Instructions\n\n(.+)', skill_content, re.DOTALL)
    if not instructions_match:
        print("ERROR: Could not extract instructions from skill file")
        return

    instructions = instructions_match.group(1).strip()

    # Prepare agent jobs
    jobs = []
    for component in sorted(missing_arch, key=lambda c: c.key):
        # Determine distribution
        distribution = args.platform  # "odh" or "rhoai"

        # Build prompt from skill instructions
        model_display = get_model_display_name(args.model)
        build_context = ""
        if build_info:
            build_context = format_build_info_context(build_info) + "\n"

        # Get RHOAI kustomize overlay context for this component
        kustomize_context_str = ""
        kustomize_ctx = get_component_kustomize_context(
            component.key, operator_path
        )
        if kustomize_ctx:
            kustomize_context_str = format_kustomize_context(
                kustomize_ctx, component.source_folder
            ) + "\n"

        prompt = f"""Generate a comprehensive architecture summary for this component repository.

Distribution: {distribution}
Repository: {component.repo_org}/{component.repo_name}
Manifests folder: {component.source_folder}
{build_context}
{kustomize_context_str}
IMPORTANT: The manifests folder location shows where kustomize deployment manifests are located.
This is critical for understanding how this component is deployed in production.

IMPORTANT: For the "Generated By" metadata field, use exactly: {model_display}

{instructions}
"""

        # Write the prompt to GENERATED_ARCHITECTURE_PROMPT.md alongside
        # where GENERATED_ARCHITECTURE.md will be created
        prompt_file = component.checkout_path / "GENERATED_ARCHITECTURE_PROMPT.md"
        prompt_file.write_text(prompt)

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

    # Run agents with concurrency limit
    semaphore = asyncio.Semaphore(args.max_concurrent)

    async def run_agent_with_semaphore(job):
        async with semaphore:
            return await run_agent(job["name"], job["cwd"], job["prompt"], log_dir, args.model)

    print("Starting agent execution...\n")
    results = await asyncio.gather(
        *(run_agent_with_semaphore(job) for job in jobs),
        return_exceptions=True
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

        # Parse directory name: <platform>-<version>
        match = re.match(r'^(odh|rhoai)-(.+)$', platform_dir.name)
        if not match:
            continue

        platform = match.group(1)
        version = match.group(2)

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
            print(f"  + {j['platform']}-{j['version']}/{j['component_name']}.md")
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
    for j in sorted(needs_generation, key=lambda x: (x['platform'], x['version'], x['component_name'])):
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
            "name": f"{j['platform']}-{j['version']}/{j['component_name']}",
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

    # Run agents with concurrency limit
    semaphore = asyncio.Semaphore(args.max_concurrent)

    async def run_agent_with_semaphore(job):
        async with semaphore:
            return await run_agent(job["name"], job["cwd"], job["prompt"], log_dir, args.model)

    print("Starting agent execution...\n")
    results = await asyncio.gather(
        *(run_agent_with_semaphore(job) for job in jobs),
        return_exceptions=True
    )

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

    # Discover platform-version directories
    # Pattern: architecture/odh-3.3.0, architecture/rhoai-2.25.0
    platform_dirs = []
    for item in architecture_dir.iterdir():
        if item.is_dir():
            # Parse directory name: <platform>-<version>
            match = re.match(r'^(odh|rhoai)-(.+)$', item.name)
            if match:
                platform = match.group(1)
                version = match.group(2)

                # Check if PLATFORM.md already exists
                platform_md = item / "PLATFORM.md"
                has_platform_md = platform_md.exists()

                # Check if there are component architecture files
                component_files = [
                    f for f in item.glob("*.md")
                    if f.name not in ["README.md", "PLATFORM.md"]
                ]

                # Check if any component files are newer than PLATFORM.md
                needs_generation = False
                if not has_platform_md and len(component_files) > 0:
                    needs_generation = True
                elif has_platform_md and len(component_files) > 0:
                    # Check if any component file is newer than PLATFORM.md
                    platform_mtime = platform_md.stat().st_mtime
                    for comp_file in component_files:
                        if comp_file.stat().st_mtime > platform_mtime:
                            needs_generation = True
                            # Delete stale PLATFORM.md (agents are bad at editing)
                            print(f"  Deleting stale PLATFORM.md for {platform}-{version} (component files updated)")
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
        print(f"No platform-version directories found in {architecture_dir}")
        print(f"Expected format: {architecture_dir}/odh-3.3.0, {architecture_dir}/rhoai-2.25.0")
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

    print(f"Found {len(platform_dirs)} platform-version director(ies):")
    print(f"  Already has PLATFORM.md: {len(already_has)}")
    print(f"  Needs PLATFORM.md: {len(needs_generation)}")
    print(f"  No components: {len(no_components)}")
    print()

    if already_has:
        print("Platforms with PLATFORM.md:")
        for p in already_has:
            print(f"  + {p['platform']}-{p['version']} ({p['component_count']} components)")
        print()

    if no_components:
        print("Platforms with no components:")
        for p in no_components:
            print(f"  ! {p['platform']}-{p['version']}")
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
    for p in sorted(needs_generation, key=lambda x: (x['platform'], x['version'])):
        # Look up supported OCP versions from build-config in checkouts
        build_context = ""
        if p['platform'] == 'rhoai':
            org = "red-hat-data-services"
            org_dir = checkouts_base / f"{org}.rhoai-{p['version']}"
            platform_build_info = get_build_info(org_dir)
            if platform_build_info:
                build_context = format_build_info_context(platform_build_info) + "\n"

        # Build prompt from skill instructions
        model_display = get_model_display_name(args.model)
        prompt = f"""Aggregate component architecture summaries into a platform-level architecture document.

Distribution: {p['platform']}
Version: {p['version']}
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
            "name": f"{p['platform']}-{p['version']}",
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

    # Run agents with concurrency limit
    semaphore = asyncio.Semaphore(args.max_concurrent)

    async def run_agent_with_semaphore(job):
        async with semaphore:
            return await run_agent(job["name"], job["cwd"], job["prompt"], log_dir, args.model)

    print("Starting agent execution...\n")
    results = await asyncio.gather(
        *(run_agent_with_semaphore(job) for job in jobs),
        return_exceptions=True
    )

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


async def run_collect_architectures_phase(args) -> None:
    """Run Phase 4: Collect and organize architecture files."""
    print("\n" + "=" * 60)
    print("PHASE 4: Collecting component architectures")
    print("=" * 60 + "\n")

    checkouts_dir = Path(args.checkouts_dir)
    output_dir = Path(args.output_dir)

    # Validate checkouts directory
    if not checkouts_dir.exists():
        print(f"Error: Checkouts directory does not exist: {checkouts_dir}")
        return

    # Determine platform filter
    platform_filter = None if args.platform == "all" else args.platform

    # Determine version filter
    version_filter = getattr(args, 'version', None)

    # Run collection
    summary = collect_architectures(checkouts_dir, output_dir, platform_filter, version_filter)

    # Print summary
    print_summary(summary, checkouts_dir, output_dir)


async def run_all_phases(args) -> None:
    """Run all phases in sequence."""
    from argparse import Namespace

    # Auto-detect org if not provided
    org = args.org
    if not org:
        org = "opendatahub-io" if args.platform == "odh" else "red-hat-data-services"

    # Extract version from branch name for filtering later phases
    # For RHOAI: branch name is authoritative (e.g., rhoai-2.25 -> version 2.25)
    # For ODH: no version in branch name, use None to auto-detect
    target_version = None
    if args.platform == "rhoai" and args.branch:
        # Extract version from branch name pattern: rhoai-X.Y
        version_match = re.search(r'rhoai-([0-9][0-9a-zA-Z._-]*)', args.branch)
        if version_match:
            target_version = version_match.group(1)

    print("\n" + "=" * 80)
    print("RUNNING ALL PHASES")
    print(f"Platform: {args.platform}")
    print(f"Organization: {org}")
    if args.branch:
        print(f"Branch: {args.branch}")
    if target_version:
        print(f"Target Version: {target_version}")
    print(f"Model: {getattr(args, 'model', 'sonnet')}")
    print("=" * 80 + "\n")

    # Phase 1: Fetch repositories
    fetch_args = Namespace(
        org=org,
        checkouts_dir="checkouts",
        branch=getattr(args, 'branch', None)
    )
    await run_fetch_phase(fetch_args)

    # Phase 2: Parse manifests (not needed for display, but validates checkouts)
    manifest_args = Namespace(
        platform=args.platform,
        org=org,
        branch=getattr(args, 'branch', None),
        checkouts_dir="checkouts",
        script_path=None,
        format="summary"
    )
    await run_manifest_phase(manifest_args)

    # Phase 3: Generate component architectures
    max_concurrent = getattr(args, 'max_concurrent', 5)
    generate_arch_args = Namespace(
        platform=args.platform,
        org=org,
        branch=getattr(args, 'branch', None),
        checkouts_dir="checkouts",
        script_path=None,
        max_concurrent=max_concurrent,
        limit=None,
        component=None,
        force=False,
        model=getattr(args, 'model', 'sonnet')
    )
    await run_generate_architecture_phase(generate_arch_args)

    # Pre-create architecture directory structure before collect phase
    # This ensures the directory exists even if collect hasn't run yet
    if target_version:
        arch_dir = Path("architecture") / f"{args.platform}-{target_version}"
        arch_dir.mkdir(parents=True, exist_ok=True)
        print(f"\nPre-created architecture directory: {arch_dir}\n")
    else:
        # For ODH or when no specific version, try to detect from operator Makefile
        from collect_architectures import get_version_from_makefile
        operator_name = "opendatahub-operator" if args.platform == "odh" else "rhods-operator"
        if args.branch:
            org_dir = f"{org}.{args.branch}"
        else:
            org_dir = org

        operator_dir = Path("checkouts") / org_dir / operator_name
        if operator_dir.exists():
            makefile_path = operator_dir / "Makefile"
            version = get_version_from_makefile(makefile_path)
            if version:
                arch_dir = Path("architecture") / f"{args.platform}-{version}"
                arch_dir.mkdir(parents=True, exist_ok=True)
                print(f"\nPre-created architecture directory: {arch_dir}\n")

    # Phase 4: Collect architectures into organized structure
    # Filter to specific version if branch was provided
    collect_args = Namespace(
        checkouts_dir="checkouts",
        output_dir="architecture",
        platform=args.platform,  # Filter to only this platform
        version=target_version  # Filter to specific version from branch
    )
    await run_collect_architectures_phase(collect_args)

    # Phase 5: Generate platform-level architecture
    # Use target_version to filter to specific version if branch was provided
    platform_arch_args = Namespace(
        architecture_dir="architecture",
        checkouts_dir="checkouts",
        platform=args.platform,
        version=target_version,  # Filter to specific version from branch
        max_concurrent=max_concurrent,
        limit=None,
        model=getattr(args, 'model', 'sonnet')
    )
    await run_generate_platform_architecture_phase(platform_arch_args)

    # Phase 6: Generate diagrams
    # Use target_version to filter to specific version if branch was provided
    diagrams_args = Namespace(
        architecture_dir="architecture",
        platform=args.platform,
        version=target_version,  # Filter to specific version from branch
        max_concurrent=max_concurrent,
        limit=None,
        force_regenerate=False,
        model=getattr(args, 'model', 'sonnet')
    )
    await run_generate_diagrams_phase(diagrams_args)

    print("\n" + "=" * 80)
    print("ALL PHASES COMPLETED SUCCESSFULLY!")
    print("=" * 80)
    print(f"\nResults:")
    print(f"  - Component architectures: checkouts/{org}.{args.branch if args.branch else ''}/*/GENERATED_ARCHITECTURE.md")
    print(f"  - Organized architectures: architecture/{args.platform}-*/")
    print(f"  - Platform documents: architecture/{args.platform}-*/PLATFORM.md")
    print(f"  - Diagrams: architecture/{args.platform}-*/diagrams/")
    print("=" * 80 + "\n")


async def main(args) -> None:
    """Main entry point - dispatch to appropriate phase."""
    if args.command == "fetch":
        await run_fetch_phase(args)
    elif args.command == "parse-manifests":
        await run_manifest_phase(args)
    elif args.command == "generate-architecture":
        await run_generate_architecture_phase(args)
    elif args.command == "collect-architectures":
        await run_collect_architectures_phase(args)
    elif args.command == "generate-platform-architecture":
        await run_generate_platform_architecture_phase(args)
    elif args.command == "generate-diagrams":
        await run_generate_diagrams_phase(args)
    elif args.command == "all":
        await run_all_phases(args)
    else:
        print("Error: No command specified. Use --help for usage information.")
        sys.exit(1)
