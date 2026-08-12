"""Command-line argument parsing for the architecture tool."""

import argparse

SUPPORTED_DISTRIBUTIONS = frozenset({"both", "odh", "rhoai"})
PIPELINE_PHASES = (
    "fetch",
    "parse-manifests",
    "discover-components",
    "static-analysis",
    "generate-architecture",
    "generate-platform-architecture",
    "generate-diagrams",
)


def resolve_distribution(platform: str) -> str:
    """Resolve a platform key to a supported architecture distribution."""
    normalized = platform.strip().lower()
    distribution = normalized.split(".", 1)[0].split("-", 1)[0]
    if distribution not in SUPPORTED_DISTRIBUTIONS:
        supported = ", ".join(sorted(SUPPORTED_DISTRIBUTIONS))
        raise ValueError(
            f"Unsupported platform identifier {platform!r}; "
            f"expected a platform rooted in one of: {supported}"
        )
    return distribution


def resolve_org_dir(org: str, suffix: str = None, branch: str = None) -> str:
    """Return the org directory name, applying suffix or branch if provided."""
    label = suffix or branch
    if label:
        return f"{org}.{label}"
    return org


def resolve_script_path(
    platform: str,
    org: str = None,
    branch: str = None,
    suffix: str = None,
    checkouts_dir: str = "checkouts",
    script_path: str = None,
) -> str:
    """
    Resolve the path to the operator manifest source.

    Returns the path to get_all_manifests.sh if it exists, otherwise
    manifests-config.yaml. If neither exists, returns the shell script
    path so the caller produces the familiar error message.

    Args:
        platform: Platform type (odh or rhoai)
        org: GitHub org (auto-detected if None)
        branch: Branch name (optional, used as directory suffix fallback)
        suffix: Explicit directory suffix (takes precedence over branch)
        checkouts_dir: Base checkouts directory
        script_path: Explicit override path (returned as-is if provided)

    Returns:
        Path string to get_all_manifests.sh or manifests-config.yaml
    """
    if script_path:
        return script_path

    if not org:
        org = "opendatahub-io" if platform == "odh" else "red-hat-data-services"

    operator_name = "opendatahub-operator" if platform == "odh" else "rhods-operator"
    org_dir = resolve_org_dir(org, suffix=suffix, branch=branch)

    operator_dir = f"{checkouts_dir}/{org_dir}/{operator_name}"
    shell_script = f"{operator_dir}/get_all_manifests.sh"
    yaml_config = f"{operator_dir}/manifests-config.yaml"

    from pathlib import Path
    if Path(shell_script).exists():
        return shell_script
    if Path(yaml_config).exists():
        return yaml_config
    return shell_script


def _add_strace_flag(parser):
    """Add --strace flag to a subparser."""
    parser.add_argument(
        "--strace",
        action="store_true",
        default=False,
        help="Run agents under strace (output to logs/strace/)",
    )


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
        help=(
            "Suffix for the org directory"
            " (e.g., --suffix=head -> <org>.head/)."
            " Defaults to branch name when --branch is set."
        ),
    )
    fetch_parser.add_argument(
        "--exclude",
        help=(
            "Comma-separated glob patterns to exclude"
            " repos (merged with platforms.yaml excludes)"
        ),
    )
    fetch_parser.add_argument(
        "--pull",
        action="store_true",
        help="Pull latest changes in existing repos instead of skipping them"
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
        help=(
            "Directory suffix for the org checkout"
            " (e.g., --suffix=head -> <org>.head/)."
            " Defaults to branch name when"
            " --branch is set."
        ),
    )
    manifest_parser.add_argument(
        "--checkouts-dir",
        default="checkouts",
        help=(
            "Base directory containing cloned"
            " repositories (default: checkouts)"
        ),
    )
    manifest_parser.add_argument(
        "--script-path",
        help=(
            "Override path to get_all_manifests.sh"
            " script (auto-detected if not provided)"
        ),
    )
    manifest_parser.add_argument(
        "--version",
        help=(
            "Explicit version label (e.g., 2.14)."
            " Overrides auto-detection from branch"
            " name or Makefile."
        ),
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
        help=(
            "Discover components by exploring"
            " breadcrumbs (installers, operators,"
            " dependencies)"
        ),
    )
    discover_parser.add_argument(
        "--platform",
        required=True,
        help=(
            "Platform identifier from platforms.yaml"
            " (e.g., 'odh', 'rhoai-3.4')"
        ),
    )
    discover_parser.add_argument(
        "--checkouts-dir",
        help=(
            "Directory containing cloned repositories"
            " (auto-detected from platforms.yaml"
            " if not set)"
        ),
    )
    discover_parser.add_argument(
        "--entry-repo",
        help=(
            "Starting point repository"
            " (e.g., 'opendatahub-operator',"
            " 'rhods-operator')"
        ),
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
        "--force",
        action="store_true",
        help="Re-run discovery even if component-map.json already exists"
    )
    discover_parser.add_argument(
        "--model",
        choices=["sonnet", "opus", "haiku"],
        default="opus",
        help=(
            "Claude model to use for discovery"
            " (default: opus -- discovery explores"
            " many repos and needs large context)"
        ),
    )
    _add_strace_flag(discover_parser)

    # Phase 2c: Static analysis (arch-analyzer)
    static_analysis_parser = subparsers.add_parser(
        "static-analysis",
        help="Run arch-analyzer static analysis on component repositories"
    )
    static_analysis_parser.add_argument(
        "--platform",
        required=True,
        help=(
            "Platform identifier matching"
            " architecture/<platform>/"
            "component-map.json"
        ),
    )
    static_analysis_parser.add_argument(
        "--architecture-dir",
        default="architecture",
        help="Base architecture directory (default: architecture)"
    )
    static_analysis_parser.add_argument(
        "--max-concurrent",
        type=int,
        default=10,
        help="Maximum concurrent analyses (default: 10)"
    )
    static_analysis_parser.add_argument(
        "--component",
        help="Only analyze this specific component"
    )
    static_analysis_parser.add_argument(
        "--force",
        action="store_true",
        help="Re-analyze even if output already exists"
    )
    static_analysis_parser.add_argument(
        "--skip-schemas",
        action="store_true",
        help="Skip CRD schema extraction (run extract only)"
    )

    # Phase 3: Generate architecture
    generate_arch_parser = subparsers.add_parser(
        "generate-architecture",
        help="Generate component architecture files in the architecture tree"
    )
    generate_arch_parser.add_argument(
        "--platform",
        required=True,
        help=(
            "Platform identifier matching"
            " architecture/<platform>/"
            "component-map.json"
            " (e.g., 'rhoai', 'rhoai-3.4')"
        ),
    )
    generate_arch_parser.add_argument(
        "--architecture-dir",
        default="architecture",
        help=(
            "Base architecture directory containing"
            " component-map.json files"
            " (default: architecture)"
        ),
    )
    generate_arch_parser.add_argument(
        "--max-concurrent",
        type=int,
        default=5,
        help="Maximum number of agents to run concurrently (default: 5)"
    )
    generate_arch_parser.add_argument(
        "--log-dir",
        default="logs/generate-architecture",
        help=(
            "Directory for component agent logs "
            "(default: logs/generate-architecture)"
        ),
    )
    generate_arch_parser.add_argument(
        "--limit",
        type=int,
        help="Limit number of components to process (for testing)"
    )
    generate_arch_parser.add_argument(
        "--component",
        help=(
            "Only process this specific component"
            " (e.g., 'operator', 'kserve', 'mlflow')"
        ),
    )
    generate_arch_parser.add_argument(
        "--force",
        action="store_true",
        help="Delete existing architecture output and regenerate"
    )
    generate_arch_parser.add_argument(
        "--evidence-gated-merge",
        action=argparse.BooleanOptionalAction,
        default=True,
        help=(
            "Rebase agent synthesis onto analyzer Markdown and apply only "
            "evidence-backed structured changes (default: enabled; use "
            "--no-evidence-gated-merge for legacy generation)"
        ),
    )
    generate_arch_parser.add_argument(
        "--version",
        help=(
            "Explicit version label (e.g., 2.14)."
            " Overrides auto-detection from branch"
            " name or Makefile."
        ),
    )
    generate_arch_parser.add_argument(
        "--model",
        choices=["sonnet", "opus", "haiku"],
        default="opus",
        help="Claude model to use (default: opus)"
    )
    generate_arch_parser.add_argument(
        "--tier",
        choices=["all", "significant", "core"],
        default="all",
        help=(
            "Which components to process: all"
            " (default), significant"
            " (architecturally_significant only),"
            " core (core/optional platform"
            " tiers only)"
        ),
    )
    _add_strace_flag(generate_arch_parser)

    # Phase 4: Generate platform architectures
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
        "--platform",
        help="Only process this platform directory (e.g., 'rhoai'). Default: all"
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
        "--force",
        action="store_true",
        default=False,
        help="Force regeneration of PLATFORM.md even if up-to-date"
    )
    platform_arch_parser.add_argument(
        "--model",
        choices=["sonnet", "opus", "haiku"],
        default="opus",
        help=(
            "Claude model to use (default: opus --"
            " platform aggregation needs"
            " large context)"
        ),
    )
    _add_strace_flag(platform_arch_parser)

    # Phase 5: Generate diagrams
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
        help="Only process this platform directory (e.g., 'rhoai'). Default: all"
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
        "--component",
        help=(
            "Only process this specific component"
            " (e.g., 'kserve', 'odh-dashboard',"
            " 'platform' for PLATFORM.md)"
        ),
    )
    diagrams_parser.add_argument(
        "--force-regenerate",
        action="store_true",
        help="Regenerate diagrams even if they already exist"
    )
    diagrams_parser.add_argument(
        "--export-png",
        action="store_true",
        default=False,
        help="Export Mermaid diagrams to PNG (requires mmdc + Chrome; off by default)"
    )
    diagrams_parser.add_argument(
        "--model",
        choices=["sonnet", "opus", "haiku"],
        default="opus",
        help="Claude model to use (default: opus)"
    )
    _add_strace_flag(diagrams_parser)

    # Check eligibility
    eligibility_parser = subparsers.add_parser(
        "check-eligibility",
        help=(
            "Check analyzer-only eligibility for components using "
            "analyzer_architecture.md"
        )
    )
    eligibility_parser.add_argument(
        "--platform",
        required=True,
        help=(
            "Platform identifier matching"
            " architecture/<platform>/"
            "component-map.json"
        ),
    )
    eligibility_parser.add_argument(
        "--architecture-dir",
        default="architecture",
        help="Base architecture directory (default: architecture)"
    )
    eligibility_parser.add_argument(
        "components",
        nargs="*",
        help="Specific components to check (default: all)"
    )

    # Targeted pipeline
    pipeline_parser = subparsers.add_parser(
        "pipeline",
        help="Run selected phases in sequence, optionally scoped to components"
    )
    pipeline_parser.add_argument(
        "--platform",
        required=True,
        help="Platform identifier from platforms.yaml (e.g., rhoai.next)"
    )
    pipeline_parser.add_argument(
        "--phase",
        action="append",
        choices=PIPELINE_PHASES,
        required=True,
        help="Phase to run, repeatable and executed in the order provided"
    )
    pipeline_parser.add_argument(
        "--component",
        action="append",
        default=[],
        help="Component key to process, repeatable"
    )
    pipeline_parser.add_argument(
        "--repo",
        action="append",
        default=[],
        help=(
            "Repository selector to process, repeatable. Accepts component key, "
            "repo name, org/repo, or repo URL tail from component-map.json"
        )
    )
    pipeline_parser.add_argument(
        "--architecture-dir",
        default="architecture",
        help="Base architecture directory (default: architecture)"
    )
    pipeline_parser.add_argument(
        "--checkouts-dir",
        default="checkouts",
        help="Base checkout directory (default: checkouts)"
    )
    pipeline_parser.add_argument(
        "--org",
        help="GitHub organization for fetch/parse-manifests phases"
    )
    pipeline_parser.add_argument(
        "--branch",
        help="Branch name for fetch/parse-manifests phases"
    )
    pipeline_parser.add_argument(
        "--suffix",
        help="Directory suffix for fetch/parse-manifests phases"
    )
    pipeline_parser.add_argument(
        "--version",
        help="Explicit version label for generation phases"
    )
    pipeline_parser.add_argument(
        "--max-concurrent",
        type=int,
        default=1,
        help="Maximum concurrency for component phases (default: 1)"
    )
    pipeline_parser.add_argument(
        "--model",
        choices=["sonnet", "opus", "haiku"],
        default="opus",
        help="Claude model to use for agent phases (default: opus)"
    )
    pipeline_parser.add_argument(
        "--log-dir",
        help=(
            "Base log directory for pipeline generation logs. Defaults to "
            "logs/pipeline/<timestamp>/generate-architecture"
        )
    )
    pipeline_parser.add_argument(
        "--tier",
        choices=["all", "significant", "core"],
        default="all",
        help="Tier filter for generate-architecture when no component filter is set"
    )
    pipeline_parser.add_argument(
        "--force",
        action="store_true",
        default=False,
        help="Force selected phases for selected components"
    )
    pipeline_parser.add_argument(
        "--skip-schemas",
        action="store_true",
        help="Skip CRD schema extraction during static-analysis"
    )
    pipeline_parser.add_argument(
        "--limit",
        type=int,
        help="Limit items in unscoped platform/diagram phases"
    )
    pipeline_parser.add_argument(
        "--export-png",
        action="store_true",
        default=False,
        help="Export Mermaid diagrams to PNG during generate-diagrams"
    )
    pipeline_parser.add_argument(
        "--evidence-gated-merge",
        action=argparse.BooleanOptionalAction,
        default=True,
        help=(
            "Rebase agent synthesis onto analyzer Markdown and apply only "
            "evidence-backed structured changes (default: enabled)"
        ),
    )
    _add_strace_flag(pipeline_parser)

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
        help=(
            "Directory suffix for the org checkout"
            " (e.g., --suffix=head -> <org>.head/)."
            " Defaults to branch name when"
            " --branch is set."
        ),
    )
    all_parser.add_argument(
        "--max-concurrent",
        type=int,
        default=5,
        help="Maximum number of agents to run concurrently (default: 5)"
    )
    all_parser.add_argument(
        "--version",
        help=(
            "Explicit version label (e.g., 2.14)."
            " Overrides auto-detection from branch"
            " name or Makefile."
        ),
    )
    all_parser.add_argument(
        "--model",
        choices=["sonnet", "opus", "haiku"],
        default="opus",
        help="Claude model to use for all agent tasks (default: opus)"
    )
    all_parser.add_argument(
        "--tier",
        choices=["all", "significant", "core"],
        default="all",
        help=(
            "Which components to generate"
            " architecture for: all (default),"
            " significant, core"
        ),
    )
    all_parser.add_argument(
        "--pull",
        action="store_true",
        help="Pull latest changes in existing repos during fetch phase"
    )
    all_parser.add_argument(
        "--force",
        action="store_true",
        default=False,
        help=(
            "Force regeneration of all outputs"
            " (component maps, architectures,"
            " diagrams, etc.)"
        )
    )
    all_parser.add_argument(
        "--clean",
        action="store_true",
        default=False,
        help=(
            "Delete all generated outputs before"
            " running (implies --force)"
        )
    )
    all_parser.add_argument(
        "--no-diagrams",
        action="store_true",
        default=False,
        help="Skip diagram generation phase"
    )
    all_parser.add_argument(
        "--export-png",
        action="store_true",
        default=False,
        help="Export Mermaid diagrams to PNG (requires mmdc + Chrome; off by default)"
    )
    all_parser.add_argument(
        "--evidence-gated-merge",
        action=argparse.BooleanOptionalAction,
        default=True,
        help=(
            "Rebase agent synthesis onto analyzer Markdown and apply only "
            "evidence-backed structured changes (default: enabled; use "
            "--no-evidence-gated-merge for legacy generation)"
        ),
    )
    _add_strace_flag(all_parser)

    return parser.parse_args()
