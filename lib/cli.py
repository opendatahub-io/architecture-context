"""Command-line argument parsing for the architecture tool."""

import argparse


def resolve_script_path(platform: str, org: str = None, branch: str = None,
                        checkouts_dir: str = "checkouts", script_path: str = None) -> str:
    """
    Resolve the path to get_all_manifests.sh.

    Args:
        platform: Platform type (odh or rhoai)
        org: GitHub org (auto-detected if None)
        branch: Branch name (optional)
        checkouts_dir: Base checkouts directory
        script_path: Explicit override path (returned as-is if provided)

    Returns:
        Path string to get_all_manifests.sh
    """
    if script_path:
        return script_path

    if not org:
        org = "opendatahub-io" if platform == "odh" else "red-hat-data-services"

    operator_name = "opendatahub-operator" if platform == "odh" else "rhods-operator"

    if branch:
        org_dir = f"{org}.{branch}"
    else:
        org_dir = org

    return f"{checkouts_dir}/{org_dir}/{operator_name}/get_all_manifests.sh"


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
        help="Platform/distribution type (e.g., odh, rhoai, aap, ansible, awx). Used for auto-detection and passed to agents as context."
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
        "--repo-path",
        help="Path to a single repository to process (bypasses manifest parsing). Use with --component to name it."
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
    generate_arch_parser.add_argument(
        "--component",
        help="Only process this specific component (e.g., 'operator', 'kserve', 'mlflow')"
    )
    generate_arch_parser.add_argument(
        "--force",
        action="store_true",
        help="Delete existing GENERATED_ARCHITECTURE.md and regenerate"
    )
    generate_arch_parser.add_argument(
        "--model",
        choices=["sonnet", "opus", "haiku"],
        default="sonnet",
        help="Claude model to use (default: sonnet)"
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
    collect_parser.add_argument(
        "--version",
        help="Only collect this specific version (default: all versions)"
    )

    # Phase 5: Generate platform architectures
    platform_arch_parser = subparsers.add_parser(
        "generate-platform-architecture",
        help="Generate PLATFORM.md files for architecture directories that need them"
    )
    platform_arch_parser.add_argument(
        "--architecture-dir",
        default="architecture",
        help="Base architecture directory (default: architecture)"
    )
    platform_arch_parser.add_argument(
        "--checkouts-dir",
        default="checkouts",
        help="Base directory containing cloned repositories (default: checkouts)"
    )
    platform_arch_parser.add_argument(
        "--platform",
        choices=["odh", "rhoai"],
        help="Only process this platform (default: all)"
    )
    platform_arch_parser.add_argument(
        "--version",
        help="Only process this version (default: all)"
    )
    platform_arch_parser.add_argument(
        "--max-concurrent",
        type=int,
        default=5,
        help="Maximum number of agents to run concurrently (default: 5)"
    )
    platform_arch_parser.add_argument(
        "--limit",
        type=int,
        help="Limit number of platforms to process (for testing)"
    )
    platform_arch_parser.add_argument(
        "--model",
        choices=["sonnet", "opus", "haiku"],
        default="sonnet",
        help="Claude model to use (default: sonnet)"
    )

    # Phase 6: Generate diagrams
    diagrams_parser = subparsers.add_parser(
        "generate-diagrams",
        help="Generate diagrams for architecture files that need them"
    )
    diagrams_parser.add_argument(
        "--architecture-dir",
        default="architecture",
        help="Base architecture directory (default: architecture)"
    )
    diagrams_parser.add_argument(
        "--platform",
        choices=["odh", "rhoai"],
        help="Only process this platform (default: all)"
    )
    diagrams_parser.add_argument(
        "--version",
        help="Only process this version (default: all)"
    )
    diagrams_parser.add_argument(
        "--max-concurrent",
        type=int,
        default=5,
        help="Maximum number of agents to run concurrently (default: 5)"
    )
    diagrams_parser.add_argument(
        "--limit",
        type=int,
        help="Limit number of files to process (for testing)"
    )
    diagrams_parser.add_argument(
        "--force-regenerate",
        action="store_true",
        help="Regenerate diagrams even if they already exist"
    )
    diagrams_parser.add_argument(
        "--model",
        choices=["sonnet", "opus", "haiku"],
        default="sonnet",
        help="Claude model to use (default: sonnet)"
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
    all_parser.add_argument(
        "--max-concurrent",
        type=int,
        default=5,
        help="Maximum number of agents to run concurrently (default: 5)"
    )
    all_parser.add_argument(
        "--model",
        choices=["sonnet", "opus", "haiku"],
        default="sonnet",
        help="Claude model to use for all agent tasks (default: sonnet)"
    )

    return parser.parse_args()
