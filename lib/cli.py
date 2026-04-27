"""Command-line argument parsing for the architecture tool."""

import argparse


def resolve_org_dir(org: str, suffix: str = None, branch: str = None) -> str:
    """Return the org directory name, applying suffix or branch if provided."""
    label = suffix or branch
    if label:
        return f"{org}.{label}"
    return org


def resolve_script_path(platform: str, org: str = None, branch: str = None,
                        suffix: str = None,
                        checkouts_dir: str = "checkouts", script_path: str = None) -> str:
    """
    Resolve the path to get_all_manifests.sh.

    Args:
        platform: Platform type (odh or rhoai)
        org: GitHub org (auto-detected if None)
        branch: Branch name (optional, used as directory suffix fallback)
        suffix: Explicit directory suffix (takes precedence over branch)
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
    org_dir = resolve_org_dir(org, suffix=suffix, branch=branch)

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
        nargs="?",
        help="GitHub organization name to clone (alternative to --platform)"
    )
    fetch_parser.add_argument(
        "--platform",
        help="Platform name from platforms.yaml (e.g., rhoai, rhoai-3.4, odh)"
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
    fetch_parser.add_argument(
        "--suffix",
        help="Suffix for the org directory (e.g., --suffix=head -> <org>.head/). Defaults to branch name when --branch is set."
    )
    fetch_parser.add_argument(
        "--exclude",
        help="Comma-separated glob patterns to exclude repos (merged with platforms.yaml excludes)"
    )

    # Phase 2: Parse manifests
    manifest_parser = subparsers.add_parser(
        "parse-manifests",
        help="Parse get_all_manifests.sh to extract component info"
    )
    manifest_parser.add_argument(
        "--platform",
        required=True,
        help="Platform identifier from platforms.yaml (e.g., 'odh', 'rhoai-3.4')"
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
        "--suffix",
        help="Directory suffix for the org checkout (e.g., --suffix=head -> <org>.head/). Defaults to branch name when --branch is set."
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
        "--version",
        help="Explicit version label (e.g., 2.14). Overrides auto-detection from branch name or Makefile."
    )
    manifest_parser.add_argument(
        "--format",
        choices=["summary", "json"],
        default="summary",
        help="Output format: summary (human-readable) or json (structured data)"
    )

    # Phase 2b: Discover components
    discover_parser = subparsers.add_parser(
        "discover-components",
        help="Discover components by exploring breadcrumbs (installers, operators, dependencies)"
    )
    discover_parser.add_argument(
        "--platform",
        required=True,
        help="Platform identifier from platforms.yaml (e.g., 'odh', 'rhoai-3.4')"
    )
    discover_parser.add_argument(
        "--checkouts-dir",
        help="Directory containing cloned repositories (auto-detected from platforms.yaml if not set)"
    )
    discover_parser.add_argument(
        "--entry-repo",
        help="Starting point repository (e.g., 'opendatahub-operator', 'rhods-operator')"
    )
    discover_parser.add_argument(
        "--architecture-dir",
        default="architecture",
        help="Output directory for component-map.json (default: architecture)"
    )
    discover_parser.add_argument(
        "--exclude",
        help="Additional repos to exclude (comma-separated patterns)"
    )
    discover_parser.add_argument(
        "--model",
        choices=["sonnet", "opus", "haiku"],
        default="sonnet",
        help="Claude model to use for discovery (default: sonnet)"
    )

    # Phase 3: Generate architecture
    generate_arch_parser = subparsers.add_parser(
        "generate-architecture",
        help="Check component repos for GENERATED_ARCHITECTURE.md files"
    )
    generate_arch_parser.add_argument(
        "--platform",
        required=True,
        help="Platform identifier from platforms.yaml (e.g., 'odh', 'rhoai-3.4')"
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
        "--suffix",
        help="Directory suffix for the org checkout (e.g., --suffix=head -> <org>.head/). Defaults to branch name when --branch is set."
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
        "--version",
        help="Explicit version label (e.g., 2.14). Overrides auto-detection from branch name or Makefile."
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
        default="all",
        help="Platform to collect, or 'all' (default: all)"
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
        default="odh",
        help="Platform identifier from platforms.yaml (default: odh)"
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
        "--suffix",
        help="Directory suffix for the org checkout (e.g., --suffix=head -> <org>.head/). Defaults to branch name when --branch is set."
    )
    all_parser.add_argument(
        "--max-concurrent",
        type=int,
        default=5,
        help="Maximum number of agents to run concurrently (default: 5)"
    )
    all_parser.add_argument(
        "--version",
        help="Explicit version label (e.g., 2.14). Overrides auto-detection from branch name or Makefile."
    )
    all_parser.add_argument(
        "--model",
        choices=["sonnet", "opus", "haiku"],
        default="sonnet",
        help="Claude model to use for all agent tasks (default: sonnet)"
    )

    return parser.parse_args()
