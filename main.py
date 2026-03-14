#!/usr/bin/env python3
"""
Repository processing and analysis tool.

Supports multiple phases:
1. Fetch repositories from GitHub organizations
2. Parse component manifests from scripts
"""

import os
import sys
import re
import asyncio
import argparse
from pathlib import Path

from dotenv import load_dotenv
from claude_agent_sdk import ClaudeSDKClient, ClaudeAgentOptions

# Import phase modules
from lib.fetch import fetch_repositories
from lib.manifest_parser import (
    process_manifest_script,
    display_component_summary,
    components_to_json
)

# Import collection script as module
import sys
sys.path.insert(0, str(Path(__file__).parent / "scripts"))
from collect_architectures import collect_architectures, print_summary

# Load environment variables from .env file
load_dotenv()


def parse_args():
    """Parse command line arguments with subcommands for each phase."""
    parser = argparse.ArgumentParser(
        description="Repository processing and analysis tool",
        formatter_class=argparse.RawDescriptionHelpFormatter,
    )

    subparsers = parser.add_subparsers(dest="command", help="Phase to run")

    # Phase 1: Fetch repositories
    fetch_parser = subparsers.add_parser(
        "fetch",
        help="Fetch/clone repositories using gh-org-clone"
    )
    fetch_parser.add_argument(
        "org",
        help="GitHub organization name to clone"
    )
    fetch_parser.add_argument(
        "--checkouts-dir",
        default="checkouts",
        help="Directory to clone repositories into (default: checkouts)"
    )
    fetch_parser.add_argument(
        "--branch",
        help="Specific branch to clone (skips repos without this branch)"
    )

    # Phase 2: Parse manifests
    manifest_parser = subparsers.add_parser(
        "parse-manifests",
        help="Parse get_all_manifests.sh to extract component info"
    )
    manifest_parser.add_argument(
        "--platform",
        choices=["odh", "rhoai"],
        required=True,
        help="Platform to parse (odh or rhoai)"
    )
    manifest_parser.add_argument(
        "--org",
        help="GitHub organization name (auto-detected if not provided)"
    )
    manifest_parser.add_argument(
        "--branch",
        help="Branch name if using versioned checkout (e.g., rhoai-2.14)"
    )
    manifest_parser.add_argument(
        "--checkouts-dir",
        default="checkouts",
        help="Base directory containing cloned repositories (default: checkouts)"
    )
    manifest_parser.add_argument(
        "--script-path",
        help="Override path to get_all_manifests.sh script (auto-detected if not provided)"
    )
    manifest_parser.add_argument(
        "--format",
        choices=["summary", "json"],
        default="summary",
        help="Output format: summary (human-readable) or json (structured data)"
    )

    # Phase 3: Generate architecture
    generate_arch_parser = subparsers.add_parser(
        "generate-architecture",
        help="Check component repos for GENERATED_ARCHITECTURE.md files"
    )
    generate_arch_parser.add_argument(
        "--platform",
        choices=["odh", "rhoai"],
        required=True,
        help="Platform to process (odh or rhoai)"
    )
    generate_arch_parser.add_argument(
        "--org",
        help="GitHub organization name (auto-detected if not provided)"
    )
    generate_arch_parser.add_argument(
        "--branch",
        help="Branch name if using versioned checkout (e.g., rhoai-2.14)"
    )
    generate_arch_parser.add_argument(
        "--checkouts-dir",
        default="checkouts",
        help="Base directory containing cloned repositories (default: checkouts)"
    )
    generate_arch_parser.add_argument(
        "--script-path",
        help="Override path to get_all_manifests.sh script (auto-detected if not provided)"
    )
    generate_arch_parser.add_argument(
        "--max-concurrent",
        type=int,
        default=5,
        help="Maximum number of agents to run concurrently (default: 5)"
    )
    generate_arch_parser.add_argument(
        "--limit",
        type=int,
        help="Limit number of components to process (for testing)"
    )

    # Phase 4: Collect architectures
    collect_parser = subparsers.add_parser(
        "collect-architectures",
        help="Collect and organize GENERATED_ARCHITECTURE.md files into architecture/ directory"
    )
    collect_parser.add_argument(
        "--checkouts-dir",
        default="checkouts",
        help="Directory containing platform checkouts (default: checkouts)"
    )
    collect_parser.add_argument(
        "--output-dir",
        default="architecture",
        help="Output directory for organized architectures (default: architecture)"
    )
    collect_parser.add_argument(
        "--platform",
        choices=["odh", "rhoai", "all"],
        default="all",
        help="Which platform to collect (default: all)"
    )

    # All phases
    all_parser = subparsers.add_parser(
        "all",
        help="Run all phases in sequence"
    )
    all_parser.add_argument(
        "--platform",
        choices=["odh", "rhoai"],
        default="odh",
        help="Platform to process (default: odh)"
    )
    all_parser.add_argument(
        "--org",
        help="GitHub organization to clone (auto-detected if not provided)"
    )
    all_parser.add_argument(
        "--branch",
        help="Specific branch to clone (e.g., rhoai-2.14 for RHOAI versions)"
    )

    return parser.parse_args()


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

    # Auto-detect org if not provided
    org = args.org
    if not org:
        org = "opendatahub-io" if args.platform == "odh" else "red-hat-data-services"

    # Auto-detect operator name
    operator_name = "opendatahub-operator" if args.platform == "odh" else "rhods-operator"

    # Determine script path
    if args.script_path:
        script_path = args.script_path
    else:
        # Construct path based on org and branch
        if args.branch:
            org_dir = f"{org}.{args.branch}"
        else:
            org_dir = org

        script_path = f"{args.checkouts_dir}/{org_dir}/{operator_name}/get_all_manifests.sh"

    # Process manifests (silent - returns structured data)
    components = await process_manifest_script(
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
        from pathlib import Path
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


async def run_agent(name: str, cwd: str, prompt: str, log_dir: Path) -> dict:
    """
    Launch one independent Claude agent session to generate architecture.

    Args:
        name: Component name for identification
        cwd: Working directory for the agent
        prompt: Prompt to send to the agent
        log_dir: Directory to write log files

    Returns:
        dict with 'name', 'success', 'log_file', and optional 'error' keys
    """
    # Create log file for this agent
    log_file = log_dir / f"{name.replace('/', '_')}.log"

    options = ClaudeAgentOptions(
        cwd=cwd,
        allowed_tools=["Read", "Write", "Edit", "Bash", "Glob", "Grep"],
        permission_mode="bypassPermissions",
        # No max_turns - let agent run as long as needed for thorough analysis
    )

    print(f"\n{'=' * 60}")
    print(f"Starting agent: {name}")
    print(f"Working directory: {cwd}")
    print(f"Log file: {log_file}")
    print(f"{'=' * 60}")

    try:
        with open(log_file, 'w') as log:
            # Write header
            log.write(f"Agent: {name}\n")
            log.write(f"Working directory: {cwd}\n")
            log.write(f"{'=' * 60}\n\n")
            log.write("PROMPT:\n")
            log.write(prompt)
            log.write(f"\n\n{'=' * 60}\n")
            log.write("AGENT OUTPUT:\n\n")
            log.flush()

            async with ClaudeSDKClient(options=options) as client:
                await client.query(prompt)

                async for msg in client.receive_response():
                    # Print to console with component name prefix
                    print(f"[{name}] {msg}")
                    # Also write to log file
                    log.write(f"{msg}\n")
                    log.flush()

        print(f"\n{'=' * 60}")
        print(f"✓ Completed: {name}")
        print(f"{'=' * 60}")

        return {"name": name, "success": True, "log_file": str(log_file)}

    except Exception as e:
        print(f"\n{'=' * 60}")
        print(f"✗ Failed: {name}")
        print(f"Error: {e}")
        print(f"{'=' * 60}")

        # Log the error
        with open(log_file, 'a') as log:
            log.write(f"\n\n{'=' * 60}\n")
            log.write(f"ERROR: {e}\n")

        return {"name": name, "success": False, "error": str(e), "log_file": str(log_file)}


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

    # Determine script path
    if args.script_path:
        script_path = args.script_path
    else:
        # Construct path based on org and branch
        if args.branch:
            org_dir = f"{org}.{args.branch}"
        else:
            org_dir = org

        script_path = f"{args.checkouts_dir}/{org_dir}/{operator_name}/get_all_manifests.sh"

    # Process manifests to get component info
    components = await process_manifest_script(
        script_path,
        platform=args.platform,
        checkouts_dir=None  # Auto-detect from script_path
    )

    if not components:
        print("No components found with checkouts")
        return

    # Filter to components missing architecture
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
        prompt = f"""Generate a comprehensive architecture summary for this component repository.

Distribution: {distribution}
Repository: {component.repo_org}/{component.repo_name}
Manifests folder: {component.source_folder}

IMPORTANT: The manifests folder location shows where kustomize deployment manifests are located.
This is critical for understanding how this component is deployed in production.

{instructions}
"""

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
    print(f"{'=' * 60}\n")

    # Run agents with concurrency limit
    semaphore = asyncio.Semaphore(args.max_concurrent)

    async def run_agent_with_semaphore(job):
        async with semaphore:
            return await run_agent(job["name"], job["cwd"], job["prompt"], log_dir)

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
            print(f"  ✗ {r['name']}: {r.get('error', 'unknown error')}")
            if r.get('log_file'):
                print(f"    Log: {r['log_file']}")

    if exceptions:
        print("\nComponents with exceptions:")
        for i, exc in enumerate(exceptions):
            print(f"  ✗ Exception {i+1}: {exc}")

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

    # Run collection
    summary = collect_architectures(checkouts_dir, output_dir, platform_filter)

    # Print summary
    print_summary(summary, checkouts_dir, output_dir)


async def run_all_phases(args) -> None:
    """Run all phases in sequence."""
    # Auto-detect org if not provided
    org = args.org
    if not org:
        org = "opendatahub-io" if args.platform == "odh" else "red-hat-data-services"

    # Create a namespace-like object for each phase
    class FetchArgs:
        org = org
        checkouts_dir = "checkouts"
        branch = getattr(args, 'branch', None)

    class ManifestArgs:
        platform = args.platform
        org = org
        branch = getattr(args, 'branch', None)
        checkouts_dir = "checkouts"
        script_path = None

    await run_fetch_phase(FetchArgs())
    await run_manifest_phase(ManifestArgs())

    print("\n" + "=" * 60)
    print("All phases completed successfully!")
    print("=" * 60 + "\n")


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
    elif args.command == "all":
        await run_all_phases(args)
    else:
        print("Error: No command specified. Use --help for usage information.")
        sys.exit(1)


if __name__ == "__main__":
    args = parse_args()
    try:
        asyncio.run(main(args))
    except KeyboardInterrupt:
        print("\n\nInterrupted by user")
        sys.exit(130)
    except Exception as e:
        print(f"\nError: {e}", file=sys.stderr)
        sys.exit(1)
