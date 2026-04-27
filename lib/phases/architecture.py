"""Phase 3: Generate component architecture documentation."""

import re
import sys
from pathlib import Path

from lib.manifest_parser import (
    ComponentInfo,
    process_manifest_script,
    discover_adjacent_components,
)
from lib.build_info import get_build_info, format_build_info_context
from lib.kustomize_context import get_component_kustomize_context, format_kustomize_context
from lib.agent_runner import run_agents_concurrently, get_model_display_name, format_duration
from lib.cli import resolve_script_path

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
        suffix=getattr(args, 'suffix', None),
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

        # Pre-gather git metadata so the agent doesn't have to
        git_context = _format_git_context(component.checkout_path)
        if git_context:
            git_context += "\n"

        prompt = f"""Generate a comprehensive architecture summary for this component repository.

Distribution: {distribution}
Repository: {component.repo_org}/{component.repo_name}
Manifests folder: {component.source_folder}
{build_context}
{kustomize_context_str}
{git_context}
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

    results = await run_agents_concurrently(jobs, log_dir, args.model, args.max_concurrent)

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
